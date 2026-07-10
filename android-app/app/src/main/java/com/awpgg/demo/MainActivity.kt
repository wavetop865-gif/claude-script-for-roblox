package com.awpgg.demo

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.awpgg.demo.ui.AwpTheme
import com.awpgg.demo.ui.MenuScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            AwpTheme {
                var menuVisible by remember { mutableStateOf(true) }
                var watermarkVisible by remember { mutableStateOf(false) }

                MenuScreen(
                    visible = menuVisible,
                    watermarkVisible = watermarkVisible,
                    onWatermarkChange = { watermarkVisible = it },
                    onMinimize = { menuVisible = false },
                    onClose = { finish() },
                    onShowMenu = { menuVisible = true },
                    onDemoAction = { message ->
                        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
                    }
                )
            }
        }
    }
}
