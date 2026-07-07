## AudioLibrary — wszystkie ścieżki audio w jednym miejscu.
## Edytuj w Inspektorze Godota: kliknij audio_library.tres w FileSystem.
class_name AudioLibrary
extends Resource

# ── Muzyka — Areny ───────────────────────────────────────────────────────────
@export_group("Muzyka — Areny")
@export_file("*.mp3","*.ogg") var music_menu: String = "res://assets/audio/music/menu/menu_theme.mp3"
@export_file("*.mp3","*.ogg") var music_hub: String = "res://assets/audio/music/hub_theme.mp3"
@export_file("*.mp3","*.ogg") var music_jungle_base: String = "res://assets/audio/music/arena_jungle/jungle_base.mp3"
@export_file("*.mp3","*.ogg") var music_jungle_intense: String = "res://assets/audio/music/arena_jungle/jungle_intense.mp3"
@export_file("*.mp3","*.ogg") var music_desert_base: String = "res://assets/audio/music/arena_desert/desert_base.mp3"
@export_file("*.mp3","*.ogg") var music_desert_intense: String = "res://assets/audio/music/arena_desert/desert_intense.mp3"
@export_file("*.mp3","*.ogg") var music_bunker_base: String = "res://assets/audio/music/arena_bunker/bunker_base.mp3"
@export_file("*.mp3","*.ogg") var music_bunker_intense: String = "res://assets/audio/music/arena_bunker/bunker_intense.mp3"
@export_file("*.mp3","*.ogg") var music_victory: String = "res://assets/audio/music/victory_stinger.mp3"

# ── Muzyka — Cutsceny ────────────────────────────────────────────────────────
@export_group("Muzyka — Cutsceny")
@export_file("*.mp3","*.ogg") var music_cutscene_cave: String = "res://assets/audio/music/cutscenes/cutscene_cave_ambient.mp3"
@export_file("*.mp3","*.ogg") var music_cutscene_tense: String = "res://assets/audio/music/cutscenes/cutscene_tense.mp3"
@export_file("*.mp3","*.ogg") var music_cutscene_march: String = "res://assets/audio/music/cutscenes/cutscene_march.mp3"
@export_file("*.mp3","*.ogg") var music_cutscene_victory: String = "res://assets/audio/music/cutscenes/cutscene_victory_end.mp3"

# ── SFX — Cutsceny ───────────────────────────────────────────────────────────
@export_group("SFX — Cutsceny")
@export_file("*.wav","*.mp3") var sfx_cutscene_alarm: String = "res://assets/audio/sfx/cutscene/cutscene_alarm.wav"
@export_file("*.wav","*.mp3") var sfx_cutscene_drill: String = "res://assets/audio/sfx/cutscene/cutscene_drill.wav"
@export_file("*.wav","*.mp3") var sfx_cutscene_rumble: String = "res://assets/audio/sfx/cutscene/cutscene_rumble.wav"
@export_file("*.wav","*.mp3") var sfx_cutscene_radio: String = "res://assets/audio/sfx/cutscene/cutscene_radio_static.wav"
@export_file("*.wav","*.mp3") var sfx_cutscene_leaves: String = "res://assets/audio/sfx/cutscene/cutscene_leaves.wav"
@export_file("*.wav","*.mp3") var sfx_cutscene_heartbeat: String = "res://assets/audio/sfx/cutscene/cutscene_heartbeat.wav"
@export_file("*.wav","*.mp3") var sfx_cutscene_march_drums: String = "res://assets/audio/sfx/cutscene/cutscene_march_drums.wav"

# ── SFX — Broń ───────────────────────────────────────────────────────────────
@export_group("SFX — Broń")
@export_file("*.wav","*.mp3") var sfx_rifle_1: String = "res://assets/audio/sfx/weapons/rifle_01.wav"
@export_file("*.wav","*.mp3") var sfx_rifle_2: String = "res://assets/audio/sfx/weapons/rifle_02.wav"
@export_file("*.wav","*.mp3") var sfx_rifle_3: String = "res://assets/audio/sfx/weapons/rifle_03.wav"
@export_file("*.wav","*.mp3") var sfx_shotgun_1: String = "res://assets/audio/sfx/weapons/shotgun_01.wav"
@export_file("*.wav","*.mp3") var sfx_shotgun_2: String = "res://assets/audio/sfx/weapons/shotgun_02.wav"
@export_file("*.wav","*.mp3") var sfx_pistol_1: String = "res://assets/audio/sfx/weapons/pistol_01.wav"
@export_file("*.wav","*.mp3") var sfx_pistol_2: String = "res://assets/audio/sfx/weapons/pistol_02.wav"
@export_file("*.wav","*.mp3") var sfx_smg_1: String = "res://assets/audio/sfx/weapons/smg_01.wav"
@export_file("*.wav","*.mp3") var sfx_smg_2: String = "res://assets/audio/sfx/weapons/smg_02.wav"
@export_file("*.wav","*.mp3") var sfx_sniper_1: String = "res://assets/audio/sfx/weapons/sniper_01.wav"
@export_file("*.wav","*.mp3") var sfx_melee_1: String = "res://assets/audio/sfx/weapons/melee_01.wav"
@export_file("*.wav","*.mp3") var sfx_melee_2: String = "res://assets/audio/sfx/weapons/melee_02.wav"
@export_file("*.wav","*.mp3") var sfx_grenade_1: String = "res://assets/audio/sfx/weapons/grenade_01.wav"
@export_file("*.wav","*.mp3") var sfx_grenade_2: String = "res://assets/audio/sfx/weapons/grenade_02.wav"

# ── SFX — UI ─────────────────────────────────────────────────────────────────
@export_group("SFX — UI")
@export_file("*.wav","*.mp3") var sfx_shop_buy: String = "res://assets/audio/sfx/ui/shop_buy.wav"
@export_file("*.wav","*.mp3") var sfx_shop_reroll: String = "res://assets/audio/sfx/ui/shop_reroll.wav"
@export_file("*.wav","*.mp3") var sfx_level_up: String = "res://assets/audio/sfx/ui/level_up.wav"
@export_file("*.wav","*.mp3") var sfx_upgrade_pick: String = "res://assets/audio/sfx/ui/upgrade_pick.wav"
@export_file("*.wav","*.mp3") var sfx_wave_start: String = "res://assets/audio/sfx/ui/wave_start.wav"
@export_file("*.wav","*.mp3") var sfx_wave_complete: String = "res://assets/audio/sfx/ui/wave_complete.wav"

# ── SFX — Wrogowie ───────────────────────────────────────────────────────────
@export_group("SFX — Wrogowie")
@export_file("*.wav","*.mp3") var sfx_enemy_death: String = "res://assets/audio/sfx/enemies/enemy_death.wav"
@export_file("*.wav","*.mp3") var sfx_enemy_hit: String = "res://assets/audio/sfx/enemies/enemy_hit.wav"
@export_file("*.wav","*.mp3") var sfx_boss_roar: String = "res://assets/audio/sfx/enemies/boss_roar.wav"
@export_file("*.wav","*.mp3") var sfx_boss_death: String = "res://assets/audio/sfx/enemies/boss_death.wav"
@export_file("*.wav","*.mp3") var sfx_boss_appear: String = "res://assets/audio/sfx/enemies/boss_appear.wav"
