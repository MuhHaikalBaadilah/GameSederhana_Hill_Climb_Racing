extends Control
## Layar pilih tingkat: 3 tombol besar EASY / MEDIUM / HARD.
## Klik tombol -> buka layar daftar 5 stage tier tersebut.

const TIER_DESC := {
	"easy": "Santail - cocok untuk pemanasan",
	"medium": "Menanjak - lumpur & es menanti",
	"hard": "Ekstrem - hanya untuk pemberani",
}


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#73c2fb"))
	$Center/VBox/BackButton.pressed.connect(_on_back)
	$Center/VBox/CoinLabel.text = "Koin: %d" % GameState.total_coins
	_build_tiers()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_tier(tier_id: String) -> void:
	if not GameState.is_tier_unlocked(tier_id):
		return
	GameState.selected_tier = tier_id
	get_tree().change_scene_to_file("res://scenes/tier_stages.tscn")


func _build_tiers() -> void:
	var box: VBoxContainer = $Center/VBox/TierBox
	for tier in GameState.tier_list():
		box.add_child(_make_tier_button(tier))


func _make_tier_button(tier: Dictionary) -> Control:
	var tier_id := str(tier["id"])
	var unlocked := GameState.is_tier_unlocked(tier_id)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(520, 120)
	btn.disabled = not unlocked
	btn.pressed.connect(_on_tier.bind(tier_id))

	var title := Label.new()
	title.text = str(tier["title"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)

	var stars := GameState.tier_stars(tier_id)
	var cleared := GameState.tier_cleared(tier_id)
	var info := Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 20)
	if unlocked:
		info.text = "%s\nBintang: %d/15   Tuntas: %d/5" % [
			str(TIER_DESC.get(tier_id, "")), stars, cleared,
		]
	else:
		info.text = "TERKUNCI - raih 1 bintang di tingkat sebelumnya"

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(info)
	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	pad.add_child(vbox)
	btn.add_child(pad)

	if not unlocked:
		btn.modulate = Color(1.0, 1.0, 1.0, 0.65)
	return btn

