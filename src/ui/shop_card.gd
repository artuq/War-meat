## ShopCard — karta przedmiotu w sklepie (Brotato-style)
## Używa card_template.tscn jako sceny bazowej.
class_name ShopCard
extends PanelContainer

signal purchased(card: ShopCard)
signal locked_toggled(card: ShopCard)
signal banished(card: ShopCard)
signal hovered(card: ShopCard)
signal unhovered(card: ShopCard)
signal preview_requested(card: ShopCard)

enum CardType { WEAPON, PASSIVE, CONSUMABLE, RECRUIT }

var card_type: CardType = CardType.WEAPON
var card_data: Variant = null
var weapon_tier: WeaponData.Tier = WeaponData.Tier.COMMON
var is_locked: bool = false
var is_owned: bool = false
var _border_color: Color = Color(0.3, 0.3, 0.3)

@onready var _bg_image: TextureRect     = $BgImage
@onready var _name_label: Label         = $Layout/NameLabel
@onready var _desc_label: RichTextLabel = $Layout/DescLabel
@onready var _buy_button: Button        = $Layout/BuyButton
@onready var _lock_button: Button       = $Layout/LockButton


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Gwarantuj że BgImage i Layout pokrywają całą kartę niezależnie od layout_mode w .tscn
	for child in [_bg_image, get_node("Layout")]:
		if child is Control:
			(child as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_buy_button.pressed.connect(_on_buy_pressed)
	_lock_button.pressed.connect(_on_lock_pressed)
	mouse_entered.connect(func(): hovered.emit(self))
	mouse_exited.connect(func(): unhovered.emit(self))
	gui_input.connect(_on_card_gui_input)
	_apply_style()


# ── Setup Methods ──

func setup_weapon(item: Dictionary, tier: WeaponData.Tier, owned: bool, gold: int, can_banish: bool = false) -> void:
	card_type = CardType.WEAPON
	card_data = item
	weapon_tier = tier
	is_owned = owned
	_border_color = WeaponData.TIER_COLORS.get(tier, Color(0.3, 0.3, 0.3))

	var tier_suffix := "" if tier == WeaponData.Tier.COMMON else " T%s" % WeaponData.TIER_NAMES[tier]
	_name_label.text = item.name + tier_suffix
	_name_label.add_theme_color_override("font_color", _border_color)

	var w := _create_weapon_for_preview(item.id, tier)
	_desc_label.text = _get_weapon_bbcode(w) if w else item.get("description", "")

	var final_cost := int(item.cost * WeaponData.TIER_MULTIPLIERS.get(tier, 1.0))
	if owned:
		_buy_button.text = "POSIADANY"
		_buy_button.disabled = true
	else:
		_buy_button.text = "$%d" % final_cost
		_buy_button.disabled = gold < final_cost

	_apply_style()


func setup_passive(item: PassiveItem, count: int, synergy_lvl: int, slots_full: bool, gold: int, can_banish: bool) -> void:
	card_type = CardType.PASSIVE
	card_data = item
	_border_color = item.icon_color

	_name_label.text = item.item_name
	_name_label.add_theme_color_override("font_color", item.icon_color)
	_desc_label.text = _get_passive_bbcode(item, count, synergy_lvl)
	_buy_button.text = "$%d" % item.cost
	_buy_button.disabled = gold < item.cost or slots_full
	_apply_style()


func setup_consumable(item: Dictionary, gold: int) -> void:
	card_type = CardType.CONSUMABLE
	card_data = item
	_border_color = Color(0.2, 0.7, 0.3)

	_name_label.text = item.name
	_name_label.add_theme_color_override("font_color", _border_color)
	_desc_label.text = "[color=green]%s[/color]" % item.description
	_buy_button.text = "$%d" % item.cost
	_buy_button.disabled = gold < item.cost
	_apply_style()


func setup_recruit(rc: Dictionary, cost: int, gold: int) -> void:
	card_type = CardType.RECRUIT
	card_data = rc
	_border_color = Color(0.3, 0.6, 1.0)

	_name_label.text = rc.name
	_name_label.add_theme_color_override("font_color", _border_color)
	_desc_label.text = "[color=cyan]%s[/color]" % rc.description
	_buy_button.text = "$%d" % cost
	_buy_button.disabled = gold < cost
	_apply_style()


func set_locked(locked: bool) -> void:
	is_locked = locked
	_lock_button.text = "🔒" if is_locked else "🔓"
	_apply_style()


# ── Texture ──

const _TIER_SLUG: Dictionary = {
	WeaponData.Tier.COMMON:    "common",
	WeaponData.Tier.UNCOMMON:  "uncommon",
	WeaponData.Tier.RARE:      "rare",
	WeaponData.Tier.EPIC:      "epic",
	WeaponData.Tier.LEGENDARY: "legendary",
}

func _get_card_texture() -> Texture2D:
	var path := ""
	match card_type:
		CardType.WEAPON:
			if card_data is Dictionary:
				var slug := (card_data.get("id", "") as String).replace("weapon_", "")
				var tier_slug: String = _TIER_SLUG.get(weapon_tier, "common")
				path = "res://assets/sprites/ui/cards/shop/%s_%s.png" % [slug, tier_slug]
		CardType.PASSIVE:
			if card_data is PassiveItem:
				path = "res://assets/sprites/ui/cards/shop/%s.png" % card_data.id
		CardType.RECRUIT:
			if card_data is Dictionary:
				# factory: "create_assault" → "recruit_assault.png"
				var factory: String = card_data.get("factory", "")
				var slug := factory.replace("create_", "recruit_")
				path = "res://assets/sprites/ui/cards/shop/%s.png" % slug
	if not path.is_empty() and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


# ── Style ──

func _apply_style() -> void:
	var card_tex := _get_card_texture()
	if card_tex:
		_bg_image.texture = card_tex
		_bg_image.modulate = Color(1.0, 0.85, 0.2) if is_locked else Color.WHITE
		# Przezroczysty panel — tło to BgImage
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.set_border_width_all(0)
		add_theme_stylebox_override("panel", sb)
	else:
		_bg_image.texture = null
		# Fallback — brak PNG → ciemne tło z kolorową ramką
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.12, 0.14)
		sb.border_color = Color(1.0, 0.85, 0.2) if is_locked else _border_color
		sb.set_border_width_all(2 if is_locked else 1)
		sb.set_corner_radius_all(3)
		sb.set_content_margin_all(6)
		add_theme_stylebox_override("panel", sb)


# ── BBCode ──

func _get_weapon_bbcode(w: WeaponData) -> String:
	var lines: PackedStringArray = []
	lines.append("[color=green]DMG: %d[/color]" % w.damage)
	lines.append("Ogień: %.1f/s" % w.fire_rate)
	lines.append("Zasięg: %.0f" % w.attack_range)
	if w.projectile_count > 1:
		lines.append("[color=cyan]×%d pocisków[/color]" % w.projectile_count)
	if w.spread_angle > 0.01:
		lines.append("Rozrzut: %.2f" % w.spread_angle)
	return "\n".join(lines)


func _get_passive_bbcode(item: PassiveItem, count: int, synergy_lvl: int) -> String:
	var lines: PackedStringArray = []
	lines.append("[color=green]%s[/color]" % item.description)
	if item.synergy_tag != PassiveItem.SynergyTag.NONE:
		var tag_name := ""
		match item.synergy_tag:
			PassiveItem.SynergyTag.SPEED: tag_name = "Szybkość"
			PassiveItem.SynergyTag.DEFENSE: tag_name = "Obrona"
			PassiveItem.SynergyTag.OFFENSE: tag_name = "Ofensywa"
		var syn_color := "green" if synergy_lvl >= 2 else "gray"
		lines.append("[color=%s][%s %d/3][/color]" % [syn_color, tag_name, synergy_lvl])
	if count > 0:
		lines.append("[color=yellow]Posiadasz: ×%d[/color]" % count)
	return "\n".join(lines)


func _create_weapon_for_preview(weapon_id: String, tier: WeaponData.Tier) -> WeaponData:
	var weapon_type: WeaponData.Type
	match weapon_id:
		"weapon_rifle":   weapon_type = WeaponData.Type.RIFLE
		"weapon_shotgun": weapon_type = WeaponData.Type.SHOTGUN
		"weapon_pistol":  weapon_type = WeaponData.Type.PISTOL
		"weapon_smg":     weapon_type = WeaponData.Type.SMG
		"weapon_sniper":  weapon_type = WeaponData.Type.SNIPER_RIFLE
		"weapon_melee":   weapon_type = WeaponData.Type.MELEE
		"weapon_grenade": weapon_type = WeaponData.Type.GRENADE
		_: return null
	return WeaponData.create_tiered(weapon_type, tier)


# ── Input ──

func _on_card_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		preview_requested.emit(self)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		preview_requested.emit(self)


func _on_buy_pressed() -> void:
	purchased.emit(self)


func _on_lock_pressed() -> void:
	set_locked(!is_locked)
	locked_toggled.emit(self)


func _on_banish_pressed() -> void:
	banished.emit(self)
