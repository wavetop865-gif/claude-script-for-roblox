package com.awpgg.demo

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import com.awpgg.demo.ui.AwpTheme
import com.awpgg.demo.ui.PermissionScreen

class MainActivity : ComponentActivity() {

    private var refreshTick by mutableIntStateOf(0)

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (!granted) {
            Toast.makeText(
                this,
                "Без уведомлений меню может закрыться системой",
                Toast.LENGTH_LONG
            ).show()
        }
        refreshPermissions()
        requestNextMissingPermission()
    }

    private val overlayPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        refreshPermissions()
        if (!Settings.canDrawOverlays(this)) {
            Toast.makeText(
                this,
                "Включите «Разрешить поверх других приложений»",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        renderPermissionScreen()
    }

    override fun onResume() {
        super.onResume()
        refreshPermissions()
    }

    private fun refreshPermissions() {
        refreshTick++
    }

    private fun renderPermissionScreen() {
        setContent {
            AwpTheme {
                val tick = refreshTick
                val status = Permissions.status(this@MainActivity)
                // tick forces re-read after returning from system settings
                @Suppress("UNUSED_VARIABLE")
                val forceRefresh = tick

                PermissionScreen(
                    status = status,
                    onRequestNotifications = { requestNotifications() },
                    onRequestOverlay = { requestOverlay() },
                    onStartMenu = { startOverlayIfReady() }
                )
            }
        }
    }

    private fun requestNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            notificationPermissionLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun requestOverlay() {
        if (Settings.canDrawOverlays(this)) {
            refreshPermissions()
            return
        }
        overlayPermissionLauncher.launch(
            Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
        )
    }

    private fun requestNextMissingPermission() {
        val status = Permissions.status(this)
        when {
            status.needsNotifications -> requestNotifications()
            !status.overlayGranted -> requestOverlay()
        }
    }

    private fun startOverlayIfReady() {
        val status = Permissions.status(this)
        if (!status.allGranted) {
            requestNextMissingPermission()
            Toast.makeText(this, "Сначала выдайте все разрешения", Toast.LENGTH_SHORT).show()
            return
        }
        OverlayService.start(this)
        Toast.makeText(this, "Меню запущено поверх экрана", Toast.LENGTH_SHORT).show()
        moveTaskToBack(true)
    }
}
