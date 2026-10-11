extends Control
## Layar daftar 5 stage dalam satu tier (dibuka dari layar pilih tingkat).
## Muat satu layar tanpa scroll: grid 3 kolom.


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#73c2fb"))
	$Center/VBox/BackButton.pressed.connect(_on_back)
	$Center/VBox/CoinLabel.text = "Koin: %d" % GameState.total_coins
	var tier_id := GameState.selected_tier
	for tier in GameState.tier_list():
		if str(tier["id"]) == tier_id:
			$Center/VBox/TitleLabel.text = "STAGE - " + str(tier["title"])
	_build_cards(tier_id)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")


func _on_stage(i: int) -> void:
	if not GameState.is_unlocked(i):
		return
	GameState.selected_stage = i
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _build_cards(tier_id: String) -> void:
	var grid: GridContainer = $Center/VBox/Grid
	for i in GameState.stages_in_tier(tier_id):
		grid.add_child(_make_card(i))


func _make_card(i: int) -> Control:
	var def := GameState.stage_def(i)
	var unlocked := GameState.is_unlocked(i)
	var best := GameState.best_distance(i)
	var pct := GameState.stage_percent(i)

	var card := Button.new()
	card.custom_minimum_size = Vector2(300, 160)
	card.disabled = not unlocked
	card.pressed.connect(_on_stage.bind(i))

	var title := Label.new()
	if GameState.is_moon(i):
		title.text = "🌙 " + str(def["name"])
	else:
		title.text = str(def["name"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)

	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var rating := StarRating.new()
	rating.stars = GameState.stage_stars(i)
	star_row.add_child(rating)

	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.value = pct * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 18)

	var info := Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if unlocked:
		info.text = "Terbaik: %d m / %d m   (%d%%)" % [
			int(best), int(GameState.target_m(i)), int(pct * 100.0),
		]
	else:
		info.text = "TERKUNCI - raih 1 bintang di stage sebelumnya"
		info.add_theme_font_size_override("font_size", 14)

	# Susun isi card (Button tidak punya layout otomatis untuk anak).
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)
	vbox.add_child(star_row)
	vbox.add_child(bar)
	vbox.add_child(info)
	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	pad.add_child(vbox)
	card.add_child(pad)

	if not unlocked:
		card.modulate = Color(1.0, 1.0, 1.0, 0.65)
	return card
