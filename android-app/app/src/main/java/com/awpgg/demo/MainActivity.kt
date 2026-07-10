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
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.NotificationManagerCompat
import com.awpgg.demo.ui.AwpColors
import com.awpgg.demo.ui.AwpTheme
import com.awpgg.demo.ui.DemoButton

class MainActivity : ComponentActivity() {

    private var permissionRequested by mutableStateOf(false)

    private val overlayPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        if (Settings.canDrawOverlays(this)) {
            startOverlay()
        } else {
            Toast.makeText(this, "Нужно разрешение «Поверх других приложений»", Toast.LENGTH_LONG).show()
        }
    }

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { _ ->
        requestOverlayPermissionIfNeeded()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        if (Settings.canDrawOverlays(this)) {
            startOverlay()
            return
        }

        setContent {
            AwpTheme {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color(0xFF0A0A0C))
                        .padding(24.dp),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text("awp.gg Demo", color = AwpColors.Text, fontSize = 22.sp)
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "Меню откроется поверх других приложений",
                        color = AwpColors.TextDim,
                        fontSize = 14.sp
                    )
                    Spacer(Modifier.height(24.dp))
                    DemoButton("Запустить меню") {
                        requestOverlayPermissionIfNeeded()
                    }
                    if (permissionRequested) {
                        Spacer(Modifier.height(12.dp))
                        Text(
                            "Включите «Разрешить поверх других приложений»",
                            color = AwpColors.TextMuted,
                            fontSize = 12.sp
                        )
                    }
                }
            }
        }
    }

    private fun requestOverlayPermissionIfNeeded() {
        permissionRequested = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !NotificationManagerCompat.from(this).areNotificationsEnabled()
        ) {
            notificationPermissionLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS)
            return
        }
        if (!Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            overlayPermissionLauncher.launch(intent)
            return
        }
        startOverlay()
    }

    private fun startOverlay() {
        OverlayService.start(this)
        Toast.makeText(this, "Меню запущено поверх экрана", Toast.LENGTH_SHORT).show()
        moveTaskToBack(true)
    }
}
