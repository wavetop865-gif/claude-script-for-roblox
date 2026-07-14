# Telegram Mini-Game Bot

Локальный Telegram-бот с двумя мини-играми:

- **Угадай число** — бот загадывает число от 1 до 100
- **Камень-ножницы-бумага** — игра через кнопки

## Безопасность

Никогда не публикуй токен бота в чатах, репозиториях и скриншотах.  
Если токен утёк — отзови его в [@BotFather](https://t.me/BotFather) и создай новый.

## Установка

```bash
cd telegram-bot
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
```

Открой `.env` и вставь новый токен:

```env
TELEGRAM_BOT_TOKEN=ваш_новый_токен
```

## Запуск

```bash
python bot.py
```

Открой бота в Telegram и отправь `/start`.

## Команды

| Команда | Описание |
|---------|----------|
| `/start` | Меню и приветствие |
| `/guess` | Начать «Угадай число» |
| `/rps` | Камень-ножницы-бумага |
| `/stats` | Статистика |
| `/stop` | Остановить текущую игру |
| `/help` | Справка |
