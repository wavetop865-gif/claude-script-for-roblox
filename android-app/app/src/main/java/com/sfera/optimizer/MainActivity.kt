package com.sfera.optimizer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.sfera.optimizer.ui.OptimizerApp
import com.sfera.optimizer.ui.SferaTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            SferaTheme {
                OptimizerApp()
            }
        }
    }
}
