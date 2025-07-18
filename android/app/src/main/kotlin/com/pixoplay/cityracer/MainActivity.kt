package com.pixoplay.cityracer

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.android.installreferrer.api.ReferrerDetails

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pixoplay.cityracer"
    private var referrer: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // For Android 15+ (SDK 34 and above), use the new window insets APIs.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Prevent Flutter or plugins from using deprecated edge-to-edge APIs by delegating to AndroidX.
            WindowCompat.setDecorFitsSystemWindows(window, false)
            // Optionally, customize system bar appearance using window.insetsController.
            window.insetsController?.apply {
                // e.g. setSystemBarsAppearance(0, WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Set up the method channel to communicate with Dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getReferrer" -> result.success(referrer)
                else -> result.notImplemented()
            }
        }
        // Initialize the Install Referrer Client.
        initInstallReferrer()
    }

    private fun initInstallReferrer() {
        val referrerClient = InstallReferrerClient.newBuilder(this).build()
        referrerClient.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                if (responseCode == InstallReferrerClient.InstallReferrerResponse.OK) {
                    try {
                        val response: ReferrerDetails = referrerClient.installReferrer
                        referrer = response.installReferrer ?: ""
                    } catch (e: Exception) {
                        e.printStackTrace()
                    } finally {
                        referrerClient.endConnection()
                    }
                }
            }
            override fun onInstallReferrerServiceDisconnected() {
                // Optionally implement reconnection logic here.
            }
        })
    }
}