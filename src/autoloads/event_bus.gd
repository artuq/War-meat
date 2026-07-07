## EventBus — centralny system sygnałów globalnych
## Sygnały są deklarowane tutaj ale emitowane/odbierane w innych skryptach.
extends Node

# --- Wave signals ---
signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared

# --- Enemy signals ---
signal enemy_spawned(enemy: Node2D)
signal enemy_killed(enemy: Node2D, position: Vector2)

# --- Loot signals ---
signal loot_dropped(position: Vector2, value: int)
signal loot_collected(value: int)

# --- Shop signals ---
signal shop_opened
signal shop_closed
signal item_purchased(item_id: String, cost: int)

# --- Squad signals ---
signal soldier_died(soldier: Node2D)
signal soldier_damaged(soldier: Node2D)
signal squad_wiped

# --- XP signals ---
signal xp_gained(amount: int)
signal level_up(new_level: int)

# --- Game feel signals ---
signal enemy_killed_at(position: Vector2)
signal screen_shake_requested(intensity: float, duration: float)

# --- Crate signals ---
signal crate_dropped(position: Vector2)
signal crate_reward(text: String, position: Vector2)

# --- Game state signals ---
signal mission_started
signal mission_won
signal mission_lost

# --- Upgrade Panel (level-up rewards between waves) ---
signal upgrade_panel_requested
signal upgrade_panel_completed
