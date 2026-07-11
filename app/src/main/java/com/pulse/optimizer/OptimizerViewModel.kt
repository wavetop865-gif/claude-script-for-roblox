package com.pulse.optimizer

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.pulse.optimizer.data.DeviceStats
import com.pulse.optimizer.data.DeviceStatsReader
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

enum class OptimizePhase { Idle, Scanning, Cleaning, Done }

data class UiState(
    val stats: DeviceStats = DeviceStats(),
    val phase: OptimizePhase = OptimizePhase.Idle,
    val progress: Float = 0f,
    val currentStep: String = "",
    val freedBytes: Long = 0,
)

class OptimizerViewModel(app: Application) : AndroidViewModel(app) {

    private val _state = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            val stats = withContext(Dispatchers.IO) {
                DeviceStatsReader.read(getApplication())
            }
            _state.update { it.copy(stats = stats) }
        }
    }

    fun optimize() {
        if (_state.value.phase == OptimizePhase.Scanning ||
            _state.value.phase == OptimizePhase.Cleaning
        ) return

        viewModelScope.launch {
            val scanSteps = listOf(
                "Анализ оперативной памяти",
                "Проверка накопителя",
                "Поиск временных файлов",
                "Оценка энергопотребления",
            )
            _state.update { it.copy(phase = OptimizePhase.Scanning, progress = 0f, freedBytes = 0) }
            scanSteps.forEachIndexed { i, step ->
                _state.update {
                    it.copy(currentStep = step, progress = (i + 1) / (scanSteps.size + 4f))
                }
                delay(550)
            }

            _state.update { it.copy(phase = OptimizePhase.Cleaning) }
            val cleanSteps = listOf(
                "Очистка кэша приложения",
                "Освобождение памяти",
                "Удаление временных файлов",
                "Финальная проверка",
            )
            var freed = 0L
            cleanSteps.forEachIndexed { i, step ->
                _state.update {
                    it.copy(
                        currentStep = step,
                        progress = (scanSteps.size + i + 1) / (scanSteps.size + cleanSteps.size).toFloat(),
                    )
                }
                if (i == 0) {
                    freed = withContext(Dispatchers.IO) {
                        DeviceStatsReader.clearOwnCache(getApplication())
                    }
                }
                delay(650)
            }

            val stats = withContext(Dispatchers.IO) {
                DeviceStatsReader.read(getApplication())
            }
            _state.update {
                it.copy(
                    phase = OptimizePhase.Done,
                    progress = 1f,
                    currentStep = "",
                    freedBytes = freed,
                    stats = stats,
                )
            }
        }
    }

    fun dismissResult() {
        _state.update { it.copy(phase = OptimizePhase.Idle, progress = 0f) }
    }
}
