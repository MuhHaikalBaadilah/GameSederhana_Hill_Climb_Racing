extends Node

## Smoke test untuk game Hill Climb Racer.
## Jalankan dengan:
##   godot --headless --path . res://tests/smoke.tscn --quit-after 10000

const START_X := 200.0

var _frames := 0
var _main: GameMain
var _phase := 0
var _wait := 0
var _vx := 0.0
var _vx2 := 0.0
var _drive := {"moved": 0.0, "fuel": 100.0, "coins": 0}


func _ready() -> void:
	_main = load("res://scenes/main.tscn").instantiate() as GameMain
	add_child(_main)
	_press_gas()


func _process(_delta: float) -> void:
	_frames += 1
	var car := _main.car
	if _phase == 0:
		# Fase 1: berkendara normal sejauh mungkin.
		_press_gas()
		if _frames <= 72 and _frames % 6 == 0:
			print("FINE frame=%d y=%.1f rot=%.0f vy=%.0f w=%.1f fdist=%.1f rdist=%.1f grounded=%s" % [
				_frames, car.global_position.y, rad_to_deg(car.rotation),
				car.linear_velocity.y, car.angular_velocity,
				car._front_dist, car._rear_dist, car.grounded,
			])
		if _frames % 60 == 0:
			print("PROBE frame=%d x=%.1f y=%.1f rot=%.0f vel=(%.0f,%.0f) grounded=%s input=%.0f fuel=%.1f" % [
				_frames, car.global_position.x, car.global_position.y,
				rad_to_deg(car.rotation), car.linear_velocity.x, car.linear_velocity.y,
				car.grounded, car.input_axis, car.fuel,
			])
		var target_done := car.fuel <= 80.0 or car.global_position.x > 1300.0
		if target_done or _frames >= 2500:
			_drive = {
				"moved": car.global_position.x - START_X,
				"fuel": car.fuel,
				"coins": _main.coins_score,
			}
			# Fase 2: teleport mobil tepat melewati garis misi -> harus VICTORY.
			_phase = 1
			_wait = 0
			car.fuel = 100.0
			car.freeze = false
			var tx := START_X + _main.mission_target * GameMain.PX_PER_METER + 100.0
			car.global_position = Vector2(tx, _main.terrain.height_at(tx) - 120.0)
			car.linear_velocity = Vector2.ZERO
			car.angular_velocity = 0.0
			car.rotation = 0.0
	elif _phase == 1:
		# Tunggu _process GameMain mendeteksi garis finish (tanpa menekan gas).
		_wait += 1
		if _wait == 10:
			_vx = car.global_position.x
		elif _wait >= 30:
			_vx2 = car.global_position.x
			_report(car)
			get_tree().quit()


func _press_gas() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_D
	ev.physical_keycode = KEY_D
	ev.pressed = true
	Input.parse_input_event(ev)


func _report(car: Car) -> void:
	print("SMOKE: frames=%d moved=%.1f fuel=%.1f coins=%d grounded=%s dead=%s" % [
		_frames, float(_drive["moved"]), float(_drive["fuel"]), int(_drive["coins"]), car.grounded, car.dead,
	])
	var victory_ok: bool = _main.victory and _main.game_over_panel.visible \
		and _main.title_label.text == "VICTORY" and car.frozen
	var stopped: bool = absf(_vx2 - _vx) < 1.0 and car.linear_velocity.length() < 5.0
	print("VICTORY: ok=%s stopped=%s frozen=%s dx=%.2f vel=%.1f title=%s stars=%d" % [
		victory_ok, stopped, car.frozen, _vx2 - _vx,
		car.linear_velocity.length(), _main.title_label.text, _main.star_rating.stars,
	])
	# Pastikan sinyal kematian tersambung ke UI game over (pada instance baru).
	var m2 := load("res://scenes/main.tscn").instantiate() as GameMain
	add_child(m2)
	m2.car._die()
	var ui_ok := m2.game_over and m2.game_over_panel.visible
	m2.queue_free()
	var t: Terrain = _main.terrain
	var first_mud := -1.0
	var first_ice := -1.0
	for z in t.zones:
		if int(z["s"]) == Terrain.Surface.MUD and first_mud < 0.0:
			first_mud = float(z["x0"])
		elif int(z["s"]) == Terrain.Surface.ICE and first_ice < 0.0:
			first_ice = float(z["x0"])
	print("ZONES=%d first_mud=%.0f first_ice=%.0f surf_at_first_mud=%d" % [
		t.zones.size(), first_mud, first_ice,
		t.surface_at(first_mud) if first_mud >= 0.0 else -1,
	])
	var ok := float(_drive["moved"]) > 400.0 and int(_drive["coins"]) > 0 \
		and float(_drive["fuel"]) < 100.0 and ui_ok and victory_ok and stopped \
		and GameState.best_distance(0) > 0.0
	print("SAVE_BEST=%.1f m" % GameState.best_distance(0))
	# Uji upgrade: backup dompet, beli mesin 1 level, pastikan stat naik, lalu kembalikan.
	var coins_before := GameState.total_coins
	var eng_before := GameState.upgrade_level("engine")
	GameState.add_coins(10000)
	var bought := GameState.buy_upgrade("engine")
	car.apply_upgrades()
	var expect_force := Car.ENGINE_FORCE * (1.0 + Car.ENGINE_FORCE_STEP * (eng_before + 1))
	var up_ok := bought and GameState.upgrade_level("engine") == eng_before + 1 \
		and absf(car._engine_force - expect_force) < 0.01
	print("UPGRADE: bought=%s lvl=%d->%d force=%.1f expect=%.1f ok=%s" % [
		bought, eng_before, GameState.upgrade_level("engine"),
		car._engine_force, expect_force, up_ok,
	])
	GameState.total_coins = coins_before
	GameState._upgrades["engine"] = eng_before
	GameState._save()
	# Uji scene garasi & menu bisa dibuka (tidak error).
	var g: Control = load("res://scenes/garage.tscn").instantiate()
	add_child(g)
	var rows: VBoxContainer = g.get_node("Center/VBox/Rows")
	var garage_ok := rows.get_child_count() == GameState.UPGRADES.size()
	print("GARAGE: rows=%d expect=%d ok=%s" % [rows.get_child_count(), GameState.UPGRADES.size(), garage_ok])
	g.queue_free()
	var mn: Control = load("res://scenes/menu.tscn").instantiate()
	add_child(mn)
	var has_btn := mn.has_node("Center/VBox/GarageButton")
	var has_coin := mn.has_node("Center/VBox/CoinLabel")
	var menu_ok := has_btn and has_coin
	print("MENU: garage_btn=%s coin_label=%s ok=%s" % [has_btn, has_coin, menu_ok])
	mn.queue_free()
	# Uji struktur stage: 15 stage, 5 per tier, tier berurutan, stage bulan ada.
	var tiers := GameState.tier_list()
	var counts: Array[int] = []
	for tier in tiers:
		counts.append(GameState.stages_in_tier(str(tier["id"])).size())
	var moons := 0
	for i in GameState.stage_count():
		if GameState.is_moon(i):
			moons += 1
	var tiers_ok := GameState.stage_count() == 15 and counts == [5, 5, 5] and moons >= 2
	print("TIERS: count=%d per_tier=%s moons=%d ok=%s" % [GameState.stage_count(), counts, moons, tiers_ok])
	# Uji gravitasi bulan: bangun stage bulan, mobil harus melayang (gravity_scale 0.35).
	var moon_idx := -1
	for i in GameState.stage_count():
		if GameState.is_moon(i):
			moon_idx = i
			break
	var moon_ok := false
	if moon_idx >= 0:
		var m3 := load("res://scenes/main.tscn").instantiate() as GameMain
		var keep := GameState.selected_stage
		GameState.selected_stage = moon_idx
		add_child(m3)
		GameState.selected_stage = keep
		moon_ok = absf(m3.car.gravity_scale - 0.35) < 0.01 and m3.moon_label.visible
		print("MOON: stage=%d gscale=%.2f label=%s ok=%s" % [
			moon_idx, m3.car.gravity_scale, m3.moon_label.visible, moon_ok,
		])
		m3.queue_free()
	# Uji layar pilih tingkat: 3 tombol tier (EASY/MEDIUM/HARD).
	var ss: Control = load("res://scenes/stage_select.tscn").instantiate()
	add_child(ss)
	var tier_box: VBoxContainer = ss.get_node("Center/VBox/TierBox")
	var select_ok := tier_box.get_child_count() == 3
	print("SELECT: tier_buttons=%d ok=%s" % [tier_box.get_child_count(), select_ok])
	ss.queue_free()
	# Uji layar daftar stage: buka tiap tier, pastikan 5 card & judul benar.
	var tiers_ok2 := true
	for tier in tiers:
		var tid := str(tier["id"])
		GameState.selected_tier = tid
		var ts: Control = load("res://scenes/tier_stages.tscn").instantiate()
		add_child(ts)
		var grid: GridContainer = ts.get_node("Center/VBox/Grid")
		var title: Label = ts.get_node("Center/VBox/TitleLabel")
		var cards_ok := grid.get_child_count() == 5
		var title_ok := str(title.text).ends_with(str(tier["title"]))
		print("TIERLIST: tier=%s cards=%d title='%s' ok=%s" % [tid, grid.get_child_count(), title.text, cards_ok and title_ok])
		tiers_ok2 = tiers_ok2 and cards_ok and title_ok
		ts.queue_free()
	ok = ok and up_ok and garage_ok and menu_ok and tiers_ok and moon_ok and select_ok and tiers_ok2
	print("SMOKE_PASS" if ok else "SMOKE_FAIL")
