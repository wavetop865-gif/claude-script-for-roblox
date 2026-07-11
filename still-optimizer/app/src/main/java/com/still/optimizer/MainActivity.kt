package com.still.optimizer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.still.optimizer.ui.screens.HomeScreen
import com.still.optimizer.ui.theme.StillTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            StillTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = StillTheme.colors.mist,
                ) {
                    HomeScreen()
                }
            }
        }
    }
}
