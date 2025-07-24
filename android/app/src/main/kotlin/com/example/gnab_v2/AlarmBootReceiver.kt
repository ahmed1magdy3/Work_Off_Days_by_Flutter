package com.example.gnab_v2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class AlarmBootReceiver : BroadcastReceiver() {

    private val CHANNEL = "com.example.gnab_v2/notifications"

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED && context != null) {

            val engine = FlutterEngine(context)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )

            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).invokeMethod(
                "rescheduleNotifications",
                null
            )
        }
    }
}
