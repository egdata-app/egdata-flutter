package com.ignacioaldama.egdata

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [30])
class SafeWidgetTrampolineActivityTest {
    @Test
    fun missingTargetOpensHomeAndFinishesWithoutCrashing() {
        val controller = Robolectric.buildActivity(SafeWidgetTrampolineActivity::class.java, Intent())
        val activity = controller.create().get()
        val launched = shadowOf(activity).nextStartedActivity
        assertEquals(MainActivity::class.java.name, launched.component!!.className)
        assertTrue(activity.isFinishing)
        controller.destroy()
    }

    @Test
    fun nullTargetOpensHomeWithoutCrashing() {
        val launch = Intent().putExtra("ACTION_INTENT", null as Intent?)
        val controller = Robolectric.buildActivity(SafeWidgetTrampolineActivity::class.java, launch)
        val activity = controller.create().get()
        assertEquals(MainActivity::class.java.name, shadowOf(activity).nextStartedActivity.component!!.className)
        controller.destroy()
    }

    @Test
    fun validWidgetClickPreservesTheRequestedOffer() {
        val context = RuntimeEnvironment.getApplication()
        val target = Intent(context, MainActivity::class.java).apply {
            action = "com.ignacioaldama.egdata.ACTION_OPEN_OFFER"
            putExtra("offerId", "test-offer")
        }
        val launch = Intent().apply {
            putExtra("ACTION_INTENT", target)
            putExtra("ACTION_TYPE", "ACTIVITY")
        }
        val controller = Robolectric.buildActivity(SafeWidgetTrampolineActivity::class.java, launch)
        val activity = controller.create().get()
        val launched = shadowOf(activity).nextStartedActivity
        assertEquals(target.action, launched.action)
        assertEquals("test-offer", launched.getStringExtra("offerId"))
        assertTrue(activity.isFinishing)
        controller.destroy()
    }

    @Test
    fun legacyComponentResolvesToTheGuardWithoutExportingIt() {
        val context = RuntimeEnvironment.getApplication()
        val component = ComponentName(context, "androidx.glance.appwidget.action.ActionTrampolineActivity")
        val info = context.packageManager.getActivityInfo(component, PackageManager.GET_META_DATA)
        assertEquals(SafeWidgetTrampolineActivity::class.java.name, info.targetActivity)
        assertFalse(info.exported)
    }
}
