extends Control
## Menu utama game.

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#73c2fb"))
	$Center/VBox/PlayButton.pressed.connect(_on_play)
	$Center/VBox/GarageButton.pressed.connect(_on_garage)
	$Center/VBox/QuitButton.pressed.connect(_on_quit)
	$Center/VBox/CoinLabel.text = "Koin: %d" % GameState.total_coins
	resized.connect(queue_redraw)
	queue_redraw()


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")


func _on_garage() -> void:
	get_tree().change_scene_to_file("res://scenes/garage.tscn")


func _on_quit() -> void:
	get_tree().quit()


func _draw() -> void:
	if size.x <= 0.0:
		return
	# Matahari
	draw_circle(Vector2(size.x - 150.0, 110.0), 46.0, Color("#ffeaa7"))
	# Bukit jauh & dekat
	_draw_hills(Color("#8fbf7f"), 470.0, 80.0, 0.0022, 0.0)
	_draw_hills(Color("#6ab04c"), 545.0, 55.0, 0.004, 1.7)
	# Tanah
	draw_rect(Rect2(0.0, 600.0, size.x, size.y - 600.0), Color("#8a5a3b"))
	draw_rect(Rect2(0.0, 600.0, size.x, 24.0), Color("#5e9c3f"))


func _draw_hills(color: Color, base: float, amp: float, freq: float, phase: float) -> void:
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= size.x + 16.0:
		var y := base - (sin(x * freq + phase) * amp + sin(x * freq * 2.7 + 1.3 + phase) * amp * 0.4)
		pts.append(Vector2(x, y))
		x += 16.0
	pts.append(Vector2(size.x + 16.0, size.y))
	pts.append(Vector2(0.0, size.y))
	draw_colored_polygon(pts, color)
