package com.example.moneymanager

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"

        // UUID MethodChannel
        private const val METHOD_CHANNEL = "moneymanager/uuid"
        private const val PREFS_NAME = "moneymanager_prefs"
        private const val KEY_DEVICE_UUID = "device_uuid"

        // Notification EventChannel
        private const val EVENT_CHANNEL = "com.example.moneymanager/notifications"
        @JvmStatic
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate() called")
        // 알림 접근 권한 체크
        if (!isNotificationServiceEnabled(this)) {
            Log.d(TAG, "NotificationListenerService not enabled → open settings")
            startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "configureFlutterEngine() called")

        // --- UUID MethodChannel 설정 ---
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceUuid") {
                val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                var uuid = prefs.getString(KEY_DEVICE_UUID, null)
                if (uuid.isNullOrBlank()) {
                    uuid = UUID.randomUUID().toString()
                    prefs.edit().putString(KEY_DEVICE_UUID, uuid).apply()
                    Log.d(TAG, "Generated new UUID: $uuid")
                }
                result.success(uuid)
            } else {
                result.notImplemented()
            }
        }

        // --- Notification EventChannel 설정 ---
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                Log.d(TAG, "EventChannel onListen()")
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "EventChannel onCancel()")
                eventSink = null
            }
        })
    }

    private fun isNotificationServiceEnabled(context: Context): Boolean {
        val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(context)
        return enabledPackages.contains(context.packageName)
    }
}
