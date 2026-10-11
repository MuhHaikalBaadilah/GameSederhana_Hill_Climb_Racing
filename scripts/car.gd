class_name Car
extends RigidBody2D

## Mobil dengan fisika suspensi raycast sederhana (mirip Hill Climb Racing).
## Kontrol: D/→ = gas, A/← = rem/mundur.

signal fuel_changed(ratio: float)
signal out_of_fuel
signal died

const REST_LENGTH := 55.0
const SPRING_K := 46.0
const SPRING_DAMPING := 6.5
const WHEEL_RADIUS := 22.0

const ENGINE_FORCE := 1200.0
const DRIVE_GAIN := 2.5
const MAX_SPEED := 1100.0
const REVERSE_SPEED := 500.0
const COAST_DRAG := 1.4
const WHEELIE_TORQUE := 1000.0
const AIR_TORQUE := 2600.0
## Bonus per level upgrade: mesin +12% gaya & +6% top speed,
## ban +0.08 grip lumpur & +0.06 es, suspensi +10% pegas & +12% damping,
## tangki +25 bensin per level.
const ENGINE_FORCE_STEP := 0.12
const TOP_SPEED_STEP := 0.06
const TIRE_MUD_STEP := 0.08
const TIRE_ICE_STEP := 0.06
const SUSP_SPRING_STEP := 0.10
const SUSP_DAMP_STEP := 0.12
const FUEL_TANK_STEP := 25.0

const FUEL_MAX := 100.0
const FUEL_DRAIN_IDLE := 0.9
const FUEL_DRAIN_THROTTLE := 2.4

const STALL_SPEED := 20.0
const STALL_TIME := 1.5
const FLIP_ANGLE := 2.4
const FLIP_SPEED := 40.0
const FLIP_TIME := 1.0

# Karakteristik permukaan: lumpur = grip turun + hambatan berat,
# es = grip sangat rendah (ban licin, sulit rem/akselerasi).
const MUD_GRIP := 0.65
const MUD_DRAG := 2.4
const ICE_DRAG := 0.0
## Grip es: bisa dioverride per stage lewat GameState.selected ice_grip.
static var ice_grip := 0.45

var fuel := FUEL_MAX
var input_axis := 0.0
var wheel_angle := 0.0
var grounded := false
var dead := false
## true = mobil dibekukan permanen (mis. saat VICTORY).
var frozen := false
## Permukaan dominan di bawah roda (Terrain.Surface).
var surface: int = Terrain.Surface.NORMAL

var _grip := 1.0
var _terrain: Terrain
var _front_dist := REST_LENGTH
var _rear_dist := REST_LENGTH
var _stall_timer := 0.0
var _flip_timer := 0.0
## Stat hasil upgrade (diisi apply_upgrades() saat scene main siap).
var _engine_force := ENGINE_FORCE
var _max_speed := MAX_SPEED
var _spring_k := SPRING_K
var _spring_damping := SPRING_DAMPING
var _fuel_max := FUEL_MAX
var _tire_mud_bonus := 0.0
var _tire_ice_bonus := 0.0

@onready var front_ray: RayCast2D = $FrontRay
@onready var rear_ray: RayCast2D = $RearRay
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("car")
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	fuel_changed.emit(fuel / FUEL_MAX)


## Terapkan stat dari level upgrade simpanan GameState.
## Dipanggil GameMain setelah terrain dibangun (sebelum balapan).
func apply_upgrades() -> void:
	var eng := GameState.upgrade_level("engine")
	var tir := GameState.upgrade_level("tires")
	var sus := GameState.upgrade_level("suspension")
	var tnk := GameState.upgrade_level("fuel")
	_engine_force = ENGINE_FORCE * (1.0 + ENGINE_FORCE_STEP * eng)
	_max_speed = MAX_SPEED * (1.0 + TOP_SPEED_STEP * eng)
	_spring_k = SPRING_K * (1.0 + SUSP_SPRING_STEP * sus)
	_spring_damping = SPRING_DAMPING * (1.0 + SUSP_DAMP_STEP * sus)
	_fuel_max = FUEL_MAX + FUEL_TANK_STEP * tnk
	_tire_mud_bonus = TIRE_MUD_STEP * tir
	_tire_ice_bonus = TIRE_ICE_STEP * tir
	fuel = _fuel_max
	fuel_changed.emit(fuel / FUEL_MAX)


## Terapkan skala gravitasi stage (1.0 = bumi, 0.35 = bulan).
## Dipanggil GameMain setelah apply_upgrades().
func apply_gravity(scale: float) -> void:
	gravity_scale = clampf(scale, 0.1, 2.0)


func _physics_process(delta: float) -> void:
	if frozen:
		# Dibekukan (VICTORY): berhenti total, tidak ada update fisika/bensin.
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		return
	_update_fuel_and_input(delta)

	var down := global_transform.y.normalized()
	var contacts: Array[Vector2] = []
	var contact_dists: Array[float] = []
	var wheel_dists: Array[float] = []

	for ray: RayCast2D in [front_ray, rear_ray]:
		var dist := REST_LENGTH
		var contact := Vector2.INF
		if ray.is_colliding():
			var hit := ray.get_collision_point()
			var d := (hit - ray.global_position).dot(down)
			if d >= 0.0 and d <= REST_LENGTH:
				dist = d
				contact = hit
		wheel_dists.append(dist)
		if contact != Vector2.INF:
			contacts.append(contact)
			contact_dists.append(dist)

	_front_dist = wheel_dists[0]
	_rear_dist = wheel_dists[1]
	grounded = not contacts.is_empty()

	# Traksi per kontak: roda paling licin yang menentukan grip,
	# hambatan permukaan paling berat yang menentukan drag.
	_grip = 1.0
	var surf_drag := 0.0
	var worst := Terrain.Surface.NORMAL
	if grounded:
		var g_min := 1.0
		for hit in contacts:
			var s := _surface_at(hit.x)
			g_min = minf(g_min, _grip_of(s))
			surf_drag = maxf(surf_drag, _drag_of(s))
			if s == Terrain.Surface.ICE:
				worst = Terrain.Surface.ICE
			elif s == Terrain.Surface.MUD and worst != Terrain.Surface.ICE:
				worst = Terrain.Surface.MUD
		_grip = g_min
	surface = worst

	# Gaya suspensi di titik kontak.
	for i in contacts.size():
		var hit := contacts[i]
		var compression := REST_LENGTH - contact_dists[i]
		var r := hit - global_position
		var point_vel := linear_velocity + Vector2(-angular_velocity * r.y, angular_velocity * r.x)
		var force := maxf(compression * _spring_k + point_vel.dot(down) * _spring_damping, 0.0)
		var push := -down * force
		apply_central_force(push)
		apply_torque(r.x * push.y - r.y * push.x)

	var fwd := global_transform.x.normalized()

	if grounded and fuel > 0.0 and input_axis != 0.0:
		# Dorongan mesin diarahkan ke depan, dibatasi kecepatan target.
		# Di lumpur/es traksi turun -> akselerasi lemah (ban slip).
		var along := 0.0
		for hit in contacts:
			var r := hit - global_position
			var point_vel := linear_velocity + Vector2(-angular_velocity * r.y, angular_velocity * r.x)
			along += point_vel.dot(fwd)
		along /= contacts.size()
		var desired := input_axis * (_max_speed if input_axis > 0.0 else REVERSE_SPEED)
		var drive := clampf((desired - along) * DRIVE_GAIN, -_engine_force, _engine_force) * _grip
		apply_central_force(fwd * drive)
		# Hambatan permukaan (lumpur) tetap melawan arah gerak saat digas.
		if surf_drag > 0.0:
			apply_central_force(fwd * (-along * surf_drag))
		# Wheelie kecil: gas = hidung naik, rem = hidung turun (dibatasi grip).
		apply_torque(-input_axis * WHEELIE_TORQUE * (0.5 + 0.5 * _grip))
	elif grounded:
		# Hambatan gulir saat tidak digas / bahan bakar habis.
		# Di es hambatan turun -> mobil meluncur jauh; di lumpur bertambah.
		var along := 0.0
		for hit in contacts:
			var r := hit - global_position
			var point_vel := linear_velocity + Vector2(-angular_velocity * r.y, angular_velocity * r.x)
			along += point_vel.dot(fwd)
		along /= contacts.size()
		apply_central_force(fwd * (-along * (COAST_DRAG * _grip + surf_drag)))

	if not grounded:
		# Kontrol udara: gas = backflip, rem = frontflip (mirip HCR).
		apply_torque(-input_axis * AIR_TORQUE)
		apply_torque(-angular_velocity * 80.0)

	angular_velocity = clampf(angular_velocity, -8.0, 8.0)

	_update_stall(delta)
	_update_flip(delta)
	_update_wheels(delta)
	queue_redraw()


func _update_fuel_and_input(delta: float) -> void:
	if dead:
		input_axis = 0.0
		return
	var gas := Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var brake := Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	input_axis = 1.0 if gas else (-1.0 if brake else 0.0)
	if fuel <= 0.0:
		fuel = 0.0
		input_axis = 0.0
		return
	var drain := FUEL_DRAIN_IDLE
	if input_axis != 0.0:
		drain += FUEL_DRAIN_THROTTLE
	fuel = maxf(fuel - drain * delta, 0.0)
	if fuel <= 0.0:
		out_of_fuel.emit()
	fuel_changed.emit(fuel / FUEL_MAX)


func _update_stall(delta: float) -> void:
	if dead or fuel > 0.0:
		_stall_timer = 0.0
		return
	# Di gravitasi rendah mobil melayang lama: beri waktu stall lebih panjang.
	var limit := STALL_TIME / clampf(gravity_scale, 0.2, 1.0)
	if linear_velocity.length() < STALL_SPEED:
		_stall_timer += delta
		if _stall_timer >= limit:
			_die()
	else:
		_stall_timer = 0.0


func _update_flip(delta: float) -> void:
	# Mobil terbalik dan nyaris diam -> leher patah (game over), mirip HCR.
	if dead:
		return
	var upright := absf(wrapf(rotation, -PI, PI))
	if upright > FLIP_ANGLE and linear_velocity.length() < FLIP_SPEED:
		_flip_timer += delta
		if _flip_timer >= FLIP_TIME:
			_die()
	else:
		_flip_timer = 0.0


func _die() -> void:
	if dead:
		return
	dead = true
	input_axis = 0.0
	died.emit()


func _update_wheels(delta: float) -> void:
	var fwd := global_transform.x.normalized()
	var along := linear_velocity.dot(fwd)
	if grounded:
		wheel_angle += along / WHEEL_RADIUS * delta
		# Ban slip visual: putaran roda berlebih saat gas di permukaan licin.
		wheel_angle += input_axis * maxf(0.0, 1.0 - _grip) * 12.0 * delta
	else:
		wheel_angle += input_axis * 14.0 * delta
	# Kamera sedikit melihat ke depan sesuai kecepatan.
	camera.position = Vector2(
		clampf(linear_velocity.x * 0.16, -70.0, 150.0),
		clampf(linear_velocity.y * 0.08, -50.0, 70.0)
	)


func add_fuel(amount: float) -> void:
	if dead or frozen:
		return
	fuel = minf(fuel + amount, _fuel_max)
	fuel_changed.emit(fuel / FUEL_MAX)


## Hentikan mobil tepat di posisi sekarang (dipanggil saat VICTORY).
func stop_now() -> void:
	frozen = true
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	input_axis = 0.0


## Cari terrain lewat group (dipanggil saat physics, setelah scene siap).
func _surface_at(x: float) -> int:
	if _terrain == null or not is_instance_valid(_terrain):
		_terrain = get_tree().get_first_node_in_group("terrain") as Terrain
	if _terrain == null:
		return Terrain.Surface.NORMAL
	return _terrain.surface_at(x)


func _grip_of(s: int) -> float:
	if s == Terrain.Surface.MUD:
		return minf(MUD_GRIP + _tire_mud_bonus, 0.95)
	if s == Terrain.Surface.ICE:
		return minf(ice_grip + _tire_ice_bonus, 0.9)
	return 1.0


func _drag_of(s: int) -> float:
	if s == Terrain.Surface.MUD:
		return MUD_DRAG
	if s == Terrain.Surface.ICE:
		return ICE_DRAG
	return 0.0


func _draw() -> void:
	_draw_wheel(front_ray.position, _front_dist)
	_draw_wheel(rear_ray.position, _rear_dist)

	var body := PackedVector2Array([
		Vector2(-44, 8), Vector2(-36, -15), Vector2(-8, -29),
		Vector2(20, -29), Vector2(36, -13), Vector2(40, -1), Vector2(32, 8),
	])
	draw_colored_polygon(body, Color("#d64536"))
	draw_rect(Rect2(-38, 0, 70, 8), Color("#7d1f16"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-4, -25), Vector2(18, -25), Vector2(32, -12), Vector2(-4, -12),
		]),
		Color("#9fd8ef")
	)
	# Lampu depan + skid plate: hidung kini menengadah (anti-nyangkut).
	draw_circle(Vector2(36, -6), 4.5, Color("#ffeaa7"))
	draw_line(Vector2(32, 8), Vector2(40, -1), Color("#5c150e"), 4.0)


func _draw_wheel(mount: Vector2, dist: float) -> void:
	var center := mount + Vector2(0.0, dist - WHEEL_RADIUS)
	draw_circle(center, WHEEL_RADIUS, Color("#262626"))
	draw_circle(center, WHEEL_RADIUS * 0.52, Color("#b8b8b8"))
	for i in 4:
		var a := wheel_angle + TAU * i / 4.0
		draw_line(center, center + Vector2(cos(a), sin(a)) * WHEEL_RADIUS * 0.5, Color("#e8e8e8"), 3.0)
