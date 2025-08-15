package com.example.flexipay

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.flexipay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val phone = call.argument<String>("phone") ?: ""
            val message = call.argument<String>("message") ?: ""

            when (call.method) {
                "sendWhatsApp" -> sendWhatsApp(phone, message, result)
                "sendSMS" -> sendSMS(phone, message, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun sendWhatsApp(phone: String, message: String, result: MethodChannel.Result) {
        try {
            val encodedMessage = Uri.encode(message)
            val url = "https://api.whatsapp.com/send?phone=$phone&text=$encodedMessage"

            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse(url)
                setPackage("com.whatsapp") // Target WhatsApp only
            }

            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success("WhatsApp launched")
            } else {
                // Fallback to WhatsApp Business
                intent.setPackage("com.whatsapp.w4b")
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    result.success("WhatsApp Business launched")
                } else {
                    result.error("WHATSAPP_NOT_FOUND", "WhatsApp not installed", null)
                }
            }

        } catch (e: Exception) {
            result.error("WHATSAPP_ERROR", e.message, null)
        }
    }

    private fun sendSMS(phone: String, message: String, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse("smsto:$phone")
            val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
                putExtra("sms_body", message)
            }

            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success("SMS Launched")
            } else {
                result.error("SMS_NOT_FOUND", "No SMS app available", null)
            }
        } catch (e: Exception) {
            result.error("SMS_ERROR", e.message, null)
        }
    }
}
