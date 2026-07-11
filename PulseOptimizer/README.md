# Pulse Optimizer

Минималистичное Android-приложение для оптимизации телефона + **встроенный VPN**.

## Готовый APK

[`apk/PulseOptimizer-debug.apk`](apk/PulseOptimizer-debug.apk)

## Возможности

### Оптимизация
- Индекс здоровья устройства
- Быстрое ускорение / глубокая очистка / забота о батарее

### VPN (встроенный, без других приложений)
- Подключение прямо внутри Pulse Optimizer через Android `VpnService`
- Движок **WireGuard** + бесплатный **Cloudflare WARP**
- Выбор бесплатного edge-сервера (JP / SG / DE / NL / US / GB / AU / Auto)
- Кнопка «Подключить» / «Отключить» — сторонние VPN-клиенты не нужны

## Сборка

```bash
cd PulseOptimizer
./gradlew assembleDebug
```
