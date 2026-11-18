package com.dq.flutter0709.all_flutter0709

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.dq.flutter0709.all_flutter0709.bridge.NativeBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    companion object {
        private const val NAV_BAR_LIGHT = 0xFFFFFFFF.toInt()
    }

    // 浅色：白底深色图标。黑夜由 Flutter 改成黑底浅色图标。
    private var lightStatusBars = true
    private var lightNavigationBars = true
    private var navigationBarColor = NAV_BAR_LIGHT

    fun updateSystemBars(
        lightStatusBars: Boolean,
        lightNavigationBars: Boolean,
        navigationBarColor: Int,
    ) {
        this.lightStatusBars = lightStatusBars
        this.lightNavigationBars = lightNavigationBars
        this.navigationBarColor = navigationBarColor
        applyEdgeToEdge()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NativeBridge.register(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 12+：去掉系统 Splash 淡出动画，直接切到与之一致的 windowBackground，避免闪一下。
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                splashScreenView.remove()
            }
        }
        super.onCreate(savedInstanceState)
        applyEdgeToEdge()
        window.decorView.post {
            applyEdgeToEdge()
        }
    }

    override fun onPostResume() {
        super.onPostResume()
        applyEdgeToEdge()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            applyEdgeToEdge()
        }
    }

    private fun applyEdgeToEdge() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = navigationBarColor
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.navigationBarDividerColor = navigationBarColor
        }
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.isAppearanceLightStatusBars = lightStatusBars
        controller.isAppearanceLightNavigationBars = lightNavigationBars
    }
}
