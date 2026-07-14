"""Simple in-memory game state for the Telegram mini-game bot."""

from __future__ import annotations

import random
from dataclasses import dataclass, field
from typing import Literal

GameMode = Literal["guess", "rps"]


@dataclass
class GuessGame:
    secret: int
    attempts: int = 0
    min_value: int = 1
    max_value: int = 100


@dataclass
class PlayerStats:
    guess_wins: int = 0
    guess_total_attempts: int = 0
    rps_wins: int = 0
    rps_losses: int = 0
    rps_draws: int = 0


@dataclass
class PlayerState:
    mode: GameMode | None = None
    guess: GuessGame | None = None
    stats: PlayerStats = field(default_factory=PlayerStats)


class GameStore:
    def __init__(self) -> None:
        self._players: dict[int, PlayerState] = {}

    def get(self, user_id: int) -> PlayerState:
        if user_id not in self._players:
            self._players[user_id] = PlayerState()
        return self._players[user_id]

    def start_guess(self, user_id: int) -> GuessGame:
        state = self.get(user_id)
        game = GuessGame(secret=random.randint(1, 100))
        state.mode = "guess"
        state.guess = game
        return game

    def stop(self, user_id: int) -> None:
        state = self.get(user_id)
        state.mode = None
        state.guess = None

    def check_guess(self, user_id: int, value: int) -> tuple[str, bool]:
        state = self.get(user_id)
        if state.mode != "guess" or state.guess is None:
            return "Сначала начни игру: /guess", False

        game = state.guess
        game.attempts += 1

        if value < game.min_value or value > game.max_value:
            return f"Число должно быть от {game.min_value} до {game.max_value}.", False

        if value < game.secret:
            return "Больше!", False
        if value > game.secret:
            return "Меньше!", False

        state.stats.guess_wins += 1
        state.stats.guess_total_attempts += game.attempts
        self.stop(user_id)
        return f"Верно! Загаданное число — {game.secret}. Попыток: {game.attempts}.", True

    def play_rps(self, user_id: int, choice: str) -> str:
        choices = {"rock": "Камень", "paper": "Бумага", "scissors": "Ножницы"}
        if choice not in choices:
            return "Неверный выбор."

        bot_choice = random.choice(list(choices.keys()))
        state = self.get(user_id)
        state.mode = "rps"

        user = choice
        bot = bot_choice

        if user == bot:
            state.stats.rps_draws += 1
            result = "Ничья!"
        elif (user, bot) in {("rock", "scissors"), ("paper", "rock"), ("scissors", "paper")}:
            state.stats.rps_wins += 1
            result = "Ты победил!"
        else:
            state.stats.rps_losses += 1
            result = "Бот победил!"

        return (
            f"Ты: {choices[user]}\n"
            f"Бот: {choices[bot]}\n\n"
            f"{result}"
        )

    def stats_text(self, user_id: int) -> str:
        s = self.get(user_id).stats
        avg = (
            f"{s.guess_total_attempts / s.guess_wins:.1f}"
            if s.guess_wins
            else "—"
        )
        return (
            "Статистика:\n"
            f"Угадай число — побед: {s.guess_wins}, среднее попыток: {avg}\n"
            f"Камень-ножницы — W/D/L: {s.rps_wins}/{s.rps_draws}/{s.rps_losses}"
        )
