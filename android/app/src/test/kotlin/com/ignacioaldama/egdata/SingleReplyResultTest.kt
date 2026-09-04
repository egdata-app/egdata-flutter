package com.ignacioaldama.egdata

import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Test

class SingleReplyResultTest {
    @Test
    fun launchFailureFollowedByCancelledActivityRepliesOnlyOnce() {
        val replies = mutableListOf<String>()
        val reply = SingleReplyResult(recordingResult(replies))
        reply.error("launch_failed", "Unavailable", null)
        reply.success(null)
        assertEquals(listOf("error:launch_failed"), replies)
    }

    @Test
    fun successfulResultIsPreservedWhenAnotherReplyArrives() {
        val replies = mutableListOf<String>()
        val reply = SingleReplyResult(recordingResult(replies))
        reply.success("processed text")
        reply.success(null)
        reply.error("late_error", null, null)
        assertEquals(listOf("success:processed text"), replies)
    }

    private fun recordingResult(replies: MutableList<String>) = object : MethodChannel.Result {
        override fun success(result: Any?) { replies.add("success:$result") }
        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            replies.add("error:$errorCode")
        }
        override fun notImplemented() { replies.add("notImplemented") }
    }
}
