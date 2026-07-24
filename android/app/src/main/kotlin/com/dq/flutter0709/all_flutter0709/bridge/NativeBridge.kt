package com.dq.flutter0709.all_flutter0709.bridge

import android.app.Activity
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android 侧原生 Bridge：注册 MethodChannel + EventChannel，处理 Flutter `call`。
 *
 * 通道名与 Dart [NativeChannels] 对齐：
 * - MethodChannel: com.dq.allflutter0709/bridge
 * - EventChannel:  com.dq.allflutter0709/events
 */
class NativeBridge private constructor(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methodChannel =
        MethodChannel(messenger, METHOD_CHANNEL_NAME)
    private val eventChannel =
        EventChannel(messenger, EVENT_CHANNEL_NAME)

    private var eventSink: EventChannel.EventSink? = null

    fun register() {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_CALL -> handleCall(call.arguments, result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun handleCall(arguments: Any?, result: MethodChannel.Result) {
        val payload = arguments as? Map<*, *>
        if (payload == null) {
            result.error("bad_args", "call 参数必须是 Map", null)
            return
        }
        val api = payload["api"]?.toString()
        when (api) {
            API_PING -> result.success("pong")
            API_GET_DEVICE_INFO -> result.success(buildDeviceInfo())
            API_EMIT_DEMO -> {
                emitDemo()
                result.success(true)
            }
            else -> result.error("unknown_api", "未知 api: $api", null)
        }
    }

    private fun buildDeviceInfo(): Map<String, Any?> {
        return mapOf(
            "platform" to "android",
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "sdkInt" to Build.VERSION.SDK_INT,
            "release" to Build.VERSION.RELEASE,
            "brand" to Build.BRAND,
            "activity" to activity.javaClass.simpleName,
        )
    }

    /**
     * 学习用：同一时刻走两条通道各推一条 demo.tick，方便对比。
     */
    private fun emitDemo() {
        val now = System.currentTimeMillis()
        methodChannel.invokeMethod(
            METHOD_EMIT,
            mapOf(
                "v" to 1,
                "event" to EVENT_DEMO_TICK,
                "data" to mapOf(
                    "via" to "method",
                    "ts" to now,
                    "platform" to "android",
                ),
            ),
        )
        eventSink?.success(
            mapOf(
                "v" to 1,
                "event" to EVENT_DEMO_TICK,
                "data" to mapOf(
                    "via" to "eventChannel",
                    "ts" to now,
                    "platform" to "android",
                ),
            ),
        )
    }

    companion object {
        const val METHOD_CHANNEL_NAME = "com.dq.allflutter0709/bridge"
        const val EVENT_CHANNEL_NAME = "com.dq.allflutter0709/events"

        private const val METHOD_CALL = "call"
        private const val METHOD_EMIT = "emit"

        private const val API_PING = "ping"
        private const val API_GET_DEVICE_INFO = "getDeviceInfo"
        private const val API_EMIT_DEMO = "emitDemo"

        private const val EVENT_DEMO_TICK = "demo.tick"

        fun register(activity: Activity, messenger: BinaryMessenger): NativeBridge {
            return NativeBridge(activity, messenger).also { it.register() }
        }
    }
}
