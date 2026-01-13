package com.ignacioaldama.egdata

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import com.bumptech.glide.Glide
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * Custom Firebase Messaging Service that intercepts FCM messages
 * and displays styled notifications for free games with gradient
 * backgrounds and custom CTAs.
 *
 * For free game notifications, it fetches offer data from the EGData API
 * to display rich notification content including game thumbnail and title.
 */
class CustomFirebaseMessagingService : FirebaseMessagingService() {

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    companion object {
        private const val TAG = "CustomFCMService"
        private const val CHANNEL_ID = "egdata_free_games"
        private const val CHANNEL_NAME = "Free Games"
        private const val CHANNEL_DESCRIPTION = "Notifications for free Epic Games Store games"
        private const val API_BASE_URL = "https://api.egdata.app"
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token: $token")
        // Token refresh is handled by Flutter's firebase_messaging plugin
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        Log.d(TAG, "Message received from: ${message.from}")
        Log.d(TAG, "Message data: ${message.data}")
        Log.d(TAG, "Message notification: ${message.notification?.title} - ${message.notification?.body}")

        // Check if this is a free-games topic message
        val isFreeGameNotification = message.from?.contains("free-games") == true ||
                message.data["topic"] == "free-games" ||
                message.data["type"] == "free_game"

        if (isFreeGameNotification) {
            handleFreeGameNotification(message)
        } else {
            // For other notifications, show standard notification
            showStandardNotification(message)
        }
    }

    private fun handleFreeGameNotification(message: RemoteMessage) {
        val offerId = message.data["offerId"]

        if (offerId != null) {
            // Fetch offer data from API and show rich notification
            serviceScope.launch {
                try {
                    val offerData = fetchOfferData(offerId)
                    if (offerData != null) {
                        showCustomFreeGameNotification(offerData)
                    } else {
                        // Fallback to basic notification if API fails
                        showFallbackNotification(message, offerId)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to fetch offer data", e)
                    showFallbackNotification(message, offerId)
                }
            }
        } else {
            // No offerId provided, show basic notification from message data
            showFallbackNotification(message, null)
        }
    }

    /**
     * Fetches offer data from the EGData API
     */
    private suspend fun fetchOfferData(offerId: String): OfferData? = withContext(Dispatchers.IO) {
        try {
            val url = URL("$API_BASE_URL/offers/$offerId")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000

            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                parseOfferResponse(response, offerId)
            } else {
                Log.e(TAG, "API request failed with code: ${connection.responseCode}")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch offer from API", e)
            null
        }
    }

    /**
     * Parses the offer JSON response into OfferData
     */
    private fun parseOfferResponse(jsonString: String, offerId: String): OfferData? {
        return try {
            val json = JSONObject(jsonString)

            val title = json.optString("title", "Free Game")
            val description = json.optString("description", "")
            val seller = json.optJSONObject("seller")?.optString("name", "") ?: ""

            val keyImages = json.optJSONArray("keyImages")
            var thumbnailUrl: String? = null
            var wideImageUrl: String? = null

            if (keyImages != null) {
                // Find wide image for background (prioritize wide formats)
                val wideTypes = listOf("DieselStoreFrontWide", "OfferImageWide", "featuredMedia", "DieselGameBoxWide")
                for (type in wideTypes) {
                    for (i in 0 until keyImages.length()) {
                        val image = keyImages.getJSONObject(i)
                        if (image.optString("type") == type) {
                            wideImageUrl = image.optString("url")
                            break
                        }
                    }
                    if (wideImageUrl != null) break
                }

                // Find thumbnail for collapsed view
                val thumbTypes = listOf("Thumbnail", "DieselStoreFrontTall", "OfferImageTall")
                for (type in thumbTypes) {
                    for (i in 0 until keyImages.length()) {
                        val image = keyImages.getJSONObject(i)
                        if (image.optString("type") == type) {
                            thumbnailUrl = image.optString("url")
                            break
                        }
                    }
                    if (thumbnailUrl != null) break
                }

                // Fallback to first image
                if (wideImageUrl == null && keyImages.length() > 0) {
                    wideImageUrl = keyImages.getJSONObject(0).optString("url")
                }
                if (thumbnailUrl == null) {
                    thumbnailUrl = wideImageUrl
                }
            }

            // Parse price info to check if really free
            val price = json.optJSONObject("price")
            val totalPrice = price?.optJSONObject("totalPrice")
            val discountPrice = totalPrice?.optInt("discountPrice", -1) ?: -1
            val isFree = discountPrice == 0

            // Get promotion end date if available
            var endDate: String? = null
            val promotions = json.optJSONObject("promotions")
            val promotionalOffers = promotions?.optJSONArray("promotionalOffers")
            if (promotionalOffers != null && promotionalOffers.length() > 0) {
                val firstPromo = promotionalOffers.getJSONObject(0)
                val offers = firstPromo.optJSONArray("promotionalOffers")
                if (offers != null && offers.length() > 0) {
                    val endDateStr = offers.getJSONObject(0).optString("endDate")
                    if (endDateStr.isNotEmpty()) {
                        endDate = formatEndDate(endDateStr)
                    }
                }
            }

            OfferData(
                id = offerId,
                title = title,
                description = description,
                seller = seller,
                thumbnailUrl = thumbnailUrl,
                wideImageUrl = wideImageUrl,
                isFree = isFree,
                endDate = endDate
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse offer JSON", e)
            null
        }
    }

    /**
     * Formats ISO date string to user-friendly format
     */
    private fun formatEndDate(isoDate: String): String {
        return try {
            val inputFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            val date = inputFormat.parse(isoDate) ?: return ""

            val now = Date()
            val diffMs = date.time - now.time
            val diffDays = TimeUnit.MILLISECONDS.toDays(diffMs)

            when {
                diffDays <= 0 -> "Ends today"
                diffDays == 1L -> "Ends tomorrow"
                diffDays <= 7 -> "Ends in $diffDays days"
                else -> {
                    val outputFormat = SimpleDateFormat("MMM d", Locale.US)
                    "Ends ${outputFormat.format(date)}"
                }
            }
        } catch (e: Exception) {
            ""
        }
    }

    /**
     * Shows the custom styled notification with API data
     */
    private suspend fun showCustomFreeGameNotification(offer: OfferData) {
        createNotificationChannel()

        // Load wide image for expanded notification background
        val wideImageBitmap: Bitmap? = if (!offer.wideImageUrl.isNullOrEmpty()) {
            withContext(Dispatchers.IO) {
                try {
                    Glide.with(applicationContext)
                        .asBitmap()
                        .load(offer.wideImageUrl)
                        .submit()
                        .get()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to load wide notification image", e)
                    null
                }
            }
        } else null

        // Load smaller thumbnail for collapsed view and large icon
        val thumbBitmap: Bitmap? = if (!offer.thumbnailUrl.isNullOrEmpty()) {
            withContext(Dispatchers.IO) {
                try {
                    Glide.with(applicationContext)
                        .asBitmap()
                        .load(offer.thumbnailUrl)
                        .override(256, 256)
                        .centerCrop()
                        .submit()
                        .get()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to load thumbnail", e)
                    null
                }
            }
        } else null

        val title = offer.title
        val body = "${offer.title} is now free on Epic Games Store"
        val summaryText = if (!offer.endDate.isNullOrEmpty()) offer.endDate else "Free on Epic Games Store"

        // Create intent for notification tap
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.ignacioaldama.egdata.ACTION_OPEN_OFFER"
            putExtra("offerId", offer.id)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            System.currentTimeMillis().toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification using standard styles
        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_PROMO)

        // Add large icon
        if (thumbBitmap != null) {
            notificationBuilder.setLargeIcon(thumbBitmap)
        }

        // Use DecoratedCustomViewStyle for a modern, blended look
        if (wideImageBitmap != null) {
            val customView = RemoteViews(packageName, R.layout.notification_free_game_modern).apply {
                setTextViewText(R.id.notification_title, title)
                setTextViewText(R.id.notification_text, summaryText)
                setImageViewBitmap(R.id.notification_image, wideImageBitmap)
                if (!offer.endDate.isNullOrEmpty()) {
                    setTextViewText(R.id.notification_end_date, offer.endDate)
                    setViewVisibility(R.id.notification_end_date, android.view.View.VISIBLE)
                } else {
                    setViewVisibility(R.id.notification_end_date, android.view.View.GONE)
                }
            }

            notificationBuilder
                .setCustomBigContentView(customView)
        } else {
            // Fallback to BigTextStyle if no image
            notificationBuilder.setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(body)
            )
        }

        // Show notification
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notificationId = offer.id.hashCode()
        notificationManager.notify(notificationId, notificationBuilder.build())

        Log.d(TAG, "Showed custom free game notification for: ${offer.title}")
    }

    /**
     * Shows a fallback notification when API fetch fails
     */
    private fun showFallbackNotification(message: RemoteMessage, offerId: String?) {
        val title = message.notification?.title
            ?: message.data["title"]
            ?: "Free Game Available!"

        val body = message.notification?.body
            ?: message.data["body"]
            ?: "A new game is free on Epic Games Store"

        createNotificationChannel()

        val intent = Intent(this, MainActivity::class.java).apply {
            if (offerId != null) {
                action = "com.ignacioaldama.egdata.ACTION_OPEN_OFFER"
                putExtra("offerId", offerId)
            }
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            System.currentTimeMillis().toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(offerId?.hashCode() ?: System.currentTimeMillis().toInt(), notification)
    }

    private fun showStandardNotification(message: RemoteMessage) {
        val title = message.notification?.title ?: message.data["title"] ?: "EGData"
        val body = message.notification?.body ?: message.data["body"] ?: ""
        val offerId = message.data["offerId"]

        createNotificationChannel()

        val intent = Intent(this, MainActivity::class.java).apply {
            if (offerId != null) {
                action = "com.ignacioaldama.egdata.ACTION_OPEN_OFFER"
                putExtra("offerId", offerId)
            }
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            System.currentTimeMillis().toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION
                enableLights(true)
                enableVibration(true)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}

/**
 * Data class to hold parsed offer information
 */
data class OfferData(
    val id: String,
    val title: String,
    val description: String,
    val seller: String,
    val thumbnailUrl: String?,
    val wideImageUrl: String? = null,
    val isFree: Boolean,
    val endDate: String?
)
