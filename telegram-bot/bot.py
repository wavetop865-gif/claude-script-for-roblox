"""Local Telegram bot with mini-games: guess-the-number and rock-paper-scissors."""

from __future__ import annotations

import logging
import os
import sys

from dotenv import load_dotenv
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.ext import (
    Application,
    CallbackQueryHandler,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

from game import GameStore

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)

store = GameStore()

WELCOME = (
    "Привет! Я бот с мини-играми.\n\n"
    "Команды:\n"
    "/guess — угадай число от 1 до 100\n"
    "/rps — камень, ножницы, бумага\n"
    "/stats — твоя статистика\n"
    "/stop — остановить текущую игру\n"
    "/help — справка"
)


def main_menu_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup(
        [
            [
                InlineKeyboardButton("Угадай число", callback_data="menu:guess"),
                InlineKeyboardButton("Камень-ножницы", callback_data="menu:rps"),
            ],
            [InlineKeyboardButton("Статистика", callback_data="menu:stats")],
        ]
    )


def rps_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup(
        [
            [
                InlineKeyboardButton("Камень", callback_data="rps:rock"),
                InlineKeyboardButton("Ножницы", callback_data="rps:scissors"),
                InlineKeyboardButton("Бумага", callback_data="rps:paper"),
            ]
        ]
    )


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(WELCOME, reply_markup=main_menu_keyboard())


async def help_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(WELCOME, reply_markup=main_menu_keyboard())


async def guess_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = update.effective_user.id
    store.start_guess(user_id)
    await update.message.reply_text(
        "Я загадал число от 1 до 100. Отправь своё число сообщением."
    )


async def rps_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text("Выбери:", reply_markup=rps_keyboard())


async def stats_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = update.effective_user.id
    await update.message.reply_text(store.stats_text(user_id))


async def stop_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = update.effective_user.id
    store.stop(user_id)
    await update.message.reply_text("Игра остановлена.")


async def on_number(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = update.effective_user.id
    state = store.get(user_id)
    if state.mode != "guess":
        return

    try:
        value = int(update.message.text.strip())
    except (TypeError, ValueError, AttributeError):
        await update.message.reply_text("Отправь целое число.")
        return

    message, won = store.check_guess(user_id, value)
    if won:
        await update.message.reply_text(
            f"{message}\n\nХочешь ещё раз?", reply_markup=main_menu_keyboard()
        )
    else:
        await update.message.reply_text(message)


async def on_callback(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    query = update.callback_query
    await query.answer()

    user_id = update.effective_user.id
    data = query.data or ""

    if data == "menu:guess":
        store.start_guess(user_id)
        await query.edit_message_text(
            "Я загадал число от 1 до 100. Отправь своё число сообщением."
        )
        return

    if data == "menu:rps":
        await query.edit_message_text("Выбери:", reply_markup=rps_keyboard())
        return

    if data == "menu:stats":
        await query.edit_message_text(store.stats_text(user_id))
        return

    if data.startswith("rps:"):
        choice = data.split(":", 1)[1]
        result = store.play_rps(user_id, choice)
        await query.edit_message_text(
            f"{result}\n\nЕщё раз?", reply_markup=rps_keyboard()
        )


def get_token() -> str:
    load_dotenv()
    token = os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
    if not token:
        print(
            "Ошибка: задай TELEGRAM_BOT_TOKEN в файле .env\n"
            "Скопируй .env.example в .env и вставь токен от @BotFather.",
            file=sys.stderr,
        )
        sys.exit(1)
    return token


def main() -> None:
    token = get_token()
    app = Application.builder().token(token).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("help", help_cmd))
    app.add_handler(CommandHandler("guess", guess_cmd))
    app.add_handler(CommandHandler("rps", rps_cmd))
    app.add_handler(CommandHandler("stats", stats_cmd))
    app.add_handler(CommandHandler("stop", stop_cmd))
    app.add_handler(CallbackQueryHandler(on_callback))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, on_number))

    logger.info("Bot started. Press Ctrl+C to stop.")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
