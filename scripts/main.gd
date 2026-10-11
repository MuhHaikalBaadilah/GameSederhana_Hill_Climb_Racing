class_name GameMain
extends Node2D

## Skenario utama: terrain + mobil + pickup + UI.

const START_X := 200.0
const PX_PER_METER := 50.0
const PICKUP_Y_OFFSET := 45.0

var coins_score := 0
var game_over := false
var victory := false
var stage_index := 0
var mission_target := 200.0
var mission_done := false
var _last_surface := -1

var _coin_scene: PackedScene = preload("res://scenes/coin.tscn")
var _fuel_scene: PackedScene = preload("res://scenes/fuel_can.tscn")

@onready var terrain: Terrain = $Terrain
@onready var car: Car = $Car
@onready var distance_label: Label = $UI/TopBar/DistanceLabel
@onready var coin_label: Label = $UI/TopBar/CoinLabel
@onready var fuel_bar: ProgressBar = $UI/FuelBar
@onready var warning_label: Label = $UI/WarningLabel
@onready var surface_label: Label = $UI/SurfaceLabel
@onready var mission_label: Label = $UI/MissionLabel
@onready var moon_label: Label = $UI/MoonLabel
@onready var game_over_panel: CenterContainer = $UI/GameOver
@onready var title_label: Label = $UI/GameOver/Panel/VBox/TitleLabel
@onready var stats_label: Label = $UI/GameOver/Panel/VBox/StatsLabel
@onready var star_rating: StarRating = $UI/GameOver/Panel/VBox/StarRating
@onready var restart_label: Label = $UI/GameOver/Panel/VBox/RestartLabel


func _ready() -> void:
	stage_index = GameState.selected_stage
	var def := GameState.stage_def(stage_index)
	# Ingat tier stage ini agar ESC kembali ke daftar yang benar.
	GameState.selected_tier = str(def.get("tier", "easy"))
	mission_target = GameState.target_m(stage_index)
	var sky: Color = def["sky"]
	RenderingServer.set_default_clear_color(sky)
	terrain.build(def)
	Car.ice_grip = float(def.get("ice_grip", 0.45))
	car.apply_upgrades()
	car.apply_gravity(GameState.gravity_scale(stage_index))
	car.fuel_changed.connect(_on_fuel_changed)
	car.out_of_fuel.connect(_on_out_of_fuel)
	car.died.connect(_on_car_died)
	_spawn_pickups()
	coin_label.text = "Koin: 0"
	star_rating.stars = 0
	moon_label.visible = GameState.is_moon(stage_index)
	restart_label.text = "R = Ulang   |   ESC = Daftar Stage"


func _process(_delta: float) -> void:
	if victory or game_over:
		return
	var meters := int(maxf(car.global_position.x - START_X, 0.0) / PX_PER_METER)
	distance_label.text = "%d m" % meters
	var pct := GameState.percent_of(stage_index, meters)
	mission_label.text = "MISI: %d m  -  %d%%" % [int(mission_target), int(pct * 100.0)]
	if not mission_done and pct >= 1.0:
		mission_done = true
		_on_victory(meters)
		return
	_update_surface_label()


func _update_surface_label() -> void:
	if car.surface == _last_surface:
		return
	_last_surface = car.surface
	match car.surface:
		Terrain.Surface.MUD:
			surface_label.text = "TANAH BERLUMPUR!"
			surface_label.add_theme_color_override("font_color", Color("#ffcf9e"))
			surface_label.visible = true
		Terrain.Surface.ICE:
			surface_label.text = "ES - BAN LICIN!"
			surface_label.add_theme_color_override("font_color", Color("#a8e4ff"))
			surface_label.visible = true
		_:
			surface_label.visible = false


func _on_victory(meters: int) -> void:
	# Misi selesai: stop mobil tepat di garis finish, lalu tampil panel VICTORY.
	victory = true
	car.stop_now()
	surface_label.visible = false
	moon_label.visible = false
	warning_label.visible = false
	GameState.submit_distance(stage_index, meters)
	title_label.text = "VICTORY"
	title_label.add_theme_color_override("font_color", Color("#ffe066"))
	stats_label.text = "Jarak: %d m  (100%%)\nKoin: %d" % [meters, coins_score]
	star_rating.stars = 3
	game_over_panel.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/tier_stages.tscn")


func _spawn_pickups() -> void:
	# Deretan koin di sepanjang terrain.
	var x := 700.0
	while x < Terrain.WIDTH - 500.0:
		var count := randi_range(3, 5)
		for i in count:
			var cx := x + i * 58.0
			var arc := sin(float(i) / maxf(count - 1, 1) * PI) * 30.0
			var coin := _coin_scene.instantiate() as Coin
			coin.position = Vector2(cx, terrain.height_at(cx) - PICKUP_Y_OFFSET - arc)
			coin.collected.connect(_on_coin_collected)
			add_child(coin)
		x += randf_range(450.0, 900.0)

	# Jerigen bahan bakar.
	var fx := 2400.0
	while fx < Terrain.WIDTH - 600.0:
		var can := _fuel_scene.instantiate() as FuelCan
		can.position = Vector2(fx, terrain.height_at(fx) - PICKUP_Y_OFFSET - 10.0)
		can.collected.connect(_on_fuel_collected)
		add_child(can)
		fx += randf_range(3500.0, 5000.0)


func _on_coin_collected(value: int) -> void:
	coins_score += value
	GameState.add_coins(value)
	coin_label.text = "Koin: %d" % coins_score


func _on_fuel_collected(amount: float) -> void:
	car.add_fuel(amount)


func _on_fuel_changed(ratio: float) -> void:
	fuel_bar.value = ratio * 100.0


func _on_out_of_fuel() -> void:
	warning_label.visible = true


func _on_car_died() -> void:
	if game_over or victory:
		return
	game_over = true
	warning_label.visible = false
	moon_label.visible = false
	var meters := int(maxf(car.global_position.x - START_X, 0.0) / PX_PER_METER)
	GameState.submit_distance(stage_index, meters)
	var pct := GameState.percent_of(stage_index, meters)
	stats_label.text = "Jarak: %d m  (%d%%)\nKoin: %d" % [
		meters, int(pct * 100.0), coins_score,
	]
	star_rating.stars = GameState.stars_from_percent(pct)
	game_over_panel.visible = true
