extends Control
## Layar garasi: beli upgrade mobil (mesin, ban, suspensi, tangki) pakai koin.

var _coin_label: Label
var _rows: VBoxContainer


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#3d4b5c"))
	_coin_label = $Center/VBox/CoinLabel
	_rows = $Center/VBox/Rows
	$Center/VBox/BackButton.pressed.connect(_on_back)
	_refresh()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _refresh() -> void:
	_coin_label.text = "Koin: %d" % GameState.total_coins
	for c in _rows.get_children():
		c.queue_free()
	for u in GameState.UPGRADES:
		_rows.add_child(_make_row(u))


func _make_row(u: Dictionary) -> Control:
	var id := str(u["id"])
	var lvl := GameState.upgrade_level(id)
	var cost := GameState.upgrade_cost(id)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "%s  %s" % [str(u["name"]), _pips(lvl)]
	title.add_theme_font_size_override("font_size", 24)
	var desc := Label.new()
	desc.text = str(u["desc"])
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.85, 0.87, 0.9))
	info.add_child(title)
	info.add_child(desc)
	row.add_child(info)

	var buy := Button.new()
	buy.custom_minimum_size = Vector2(190, 56)
	buy.add_theme_font_size_override("font_size", 20)
	if cost < 0:
		buy.text = "MAX"
		buy.disabled = true
	else:
		buy.text = "BELI: %d" % cost
		buy.disabled = GameState.total_coins < cost
		buy.pressed.connect(_on_buy.bind(id))
	row.add_child(buy)
	return row


func _pips(lvl: int) -> String:
	var s := ""
	for i in GameState.UPGRADE_MAX:
		s += "●" if i < lvl else "○"
	return s


func _on_buy(id: String) -> void:
	if GameState.buy_upgrade(id):
		_refresh()
