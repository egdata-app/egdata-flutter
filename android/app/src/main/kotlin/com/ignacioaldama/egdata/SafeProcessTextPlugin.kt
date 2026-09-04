package com.ignacioaldama.egdata

import io.flutter.embedding.engine.systemchannels.ProcessTextChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.text.ProcessTextPlugin
import java.util.concurrent.atomic.AtomicBoolean

/** Protects text actions whose launch fails before Android delivers a late result. */
class SafeProcessTextPlugin(channel: ProcessTextChannel) : ProcessTextPlugin(channel) {
    override fun processTextAction(
        id: String,
        text: String,
        readOnly: Boolean,
        result: MethodChannel.Result
    ) {
        val reply = SingleReplyResult(result)
        try {
            super.processTextAction(id, text, readOnly, reply)
        } catch (error: Exception) {
            // Reply through the same guard used by onActivityResult. Otherwise the
            // channel replies to this exception and a late result replies again.
            reply.error("process_text_failed", error.message, null)
        }
    }
}

internal class SingleReplyResult(private val delegate: MethodChannel.Result) : MethodChannel.Result {
    private val completed = AtomicBoolean(false)

    override fun success(result: Any?) {
        if (completed.compareAndSet(false, true)) delegate.success(result)
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        if (completed.compareAndSet(false, true)) {
            delegate.error(errorCode, errorMessage, errorDetails)
        }
    }

    override fun notImplemented() {
        if (completed.compareAndSet(false, true)) delegate.notImplemented()
    }
}
