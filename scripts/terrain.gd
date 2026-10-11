class_name Terrain
extends StaticBody2D

## Terrain prosedural per stage: bukit dari noise + strip permukaan
## khusus (lumpur / es) yang membuat ban licin.
## Zona permukaan ditentukan deterministik dari seed stage.

enum Surface { NORMAL, MUD, ICE }

const WIDTH := 20000
const STEP := 16
const BASE_Y := 500.0
const BOTTOM_Y := 3200.0
const ZONE_START_X := 1800.0
const MUD_COLOR := Color("#6b4423")
const ICE_COLOR := Color("#a8ddf5")
## Kemiringan maksimum rata-rata yang boleh ditutup zona es.
## Es di atas tanjakan curam mustahil dilewati (grip 0.45 < tan 0.6+),
## jadi zona es di situ ditolak saat generate.
## Diukur pada terrain final (sudah diratakan), sehingga es landai tetap lolos.
const ICE_MAX_GRADE := 0.45

var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _amp := 1.0
var _rough := 1.0
var _grass := Color("#6ab04c")
var _dirt := Color("#8a5a3b")
var _back := Color("#8fbf7f")
## Seberapa kuat detail kasar diratakan di dalam zona es (0 = mati, 1 = datar total).
var _ice_flat := 0.65
## Zona permukaan khusus: [{ "x0": float, "x1": float, "s": Surface }]
var zones: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("terrain")


## Bangun terrain sesuai definisi stage.
## Panggil dari GameMain di _ready() SEBELUM memakai height_at().
## Alur: tebak zona -> ratakan terrain di bawah es -> tolak es yang masih
## curam -> build final. Dua pass agar grade diukur pada terrain final.
func build(stage: Dictionary) -> void:
	_noise.seed = int(stage.get("seed", randi()))
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = float(stage.get("freq", 0.0013))
	_detail.seed = int(stage.get("seed", 1)) + 1
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.frequency = float(stage.get("detail_freq", 0.004))
	_amp = float(stage.get("amp", 1.0))
	_rough = float(stage.get("rough", 1.0))
	_grass = stage.get("grass", Color("#6ab04c"))
	_dirt = stage.get("dirt", Color("#8a5a3b"))
	_back = stage.get("back", Color("#8fbf7f"))
	_ice_flat = float(stage.get("ice_flat", 0.65))
	zones = _gen_zones(stage)
	# Pass 2: tolak zona es yang MASIH curam setelah diratakan.
	var kept: Array[Dictionary] = []
	for z in zones:
		if int(z["s"]) == Surface.ICE \
				and _zone_grade(float(z["x0"]), float(z["x1"])) > ICE_MAX_GRADE:
			continue
		kept.append(z)
	zones = kept
	_build()


## Tinggi permukaan tanah (dalam koordinat lokal) pada posisi x.
## Hanya valid setelah build() dipanggil.
## Di dalam zona es, detail kasar dilembutkan agar es tetap bisa dilewati
## (fair play: tanjakan es curam tidak mungkin didaki dengan grip 0.45).
func height_at(x: float) -> float:
	var t := smoothstep(350.0, 1600.0, clampf(x, 0.0, float(WIDTH)))
	var elevation := (
		_noise.get_noise_2d(x, 0.0) * 165.0
		+ _detail.get_noise_2d(x, 37.0) * 38.0 * _rough * _detail_scale(x)
	) * _amp * t
	return BASE_Y - elevation


## Skala detail kasar: 0.35 di dalam zona es, 1.0 di luar (transisi halus).
func _detail_scale(x: float) -> float:
	if _ice_flat <= 0.0:
		return 1.0
	for z in zones:
		if int(z["s"]) != Surface.ICE:
			continue
		var x0 := float(z["x0"])
		var x1 := float(z["x1"])
		var edge := 120.0
		if x >= x0 - edge and x <= x1 + edge:
			var d := minf(absf(x - x0), absf(x - x1))
			var k := smoothstep(0.0, edge, d)
			# Di tengah zona es: detail tinggal 35%; di tepi: menyatu mulus.
			return lerpf(1.0 - _ice_flat, 1.0, k)
	return 1.0


## Jenis permukaan pada posisi x.
func surface_at(x: float) -> int:
	for z in zones:
		if x >= float(z["x0"]) and x <= float(z["x1"]):
			return int(z["s"])
	return Surface.NORMAL


## Zona lumpur/es digenerate deterministik (seed stage + 777).
func _gen_zones(stage: Dictionary) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(stage.get("seed", 1)) + 777
	var p_mud := float(stage.get("zone_mud", 0.0))
	var p_ice := float(stage.get("zone_ice", 0.0))
	var out: Array[Dictionary] = []
	var x := ZONE_START_X
	while x < WIDTH - 900.0:
		x += rng.randf_range(450.0, 1200.0)
		if x >= WIDTH - 900.0:
			break
		var roll := rng.randf()
		var s := Surface.NORMAL
		if p_mud > 0.0 and roll < p_mud:
			s = Surface.MUD
		elif p_ice > 0.0 and roll < p_mud + p_ice:
			s = Surface.ICE
		if s == Surface.NORMAL:
			continue
		var length := rng.randf_range(300.0, 720.0)
		var x1 := minf(x + length, float(WIDTH - 200))
		out.append({"x0": x, "x1": x1, "s": s})
		x += length
	return out


## Kemiringan rata-rata |dh/dx| terrain kasar pada rentang [x0, x1].
## Dipakai saat generate agar zona es tidak jatuh di tanjakan maut.
func _zone_grade(x0: float, x1: float) -> float:
	var prev := height_at(x0)
	var total := 0.0
	var n := 0
	var x := x0 + STEP
	while x <= x1:
		var h := height_at(x)
		total += absf(h - prev) / STEP
		prev = h
		n += 1
		x += STEP
	return total / maxf(n, 1)


func _build() -> void:
	var top := PackedVector2Array()
	var x := 0.0
	while x <= WIDTH:
		top.append(Vector2(x, height_at(x)))
		x += STEP

	var ground_poly := PackedVector2Array()
	ground_poly.append_array(top)
	ground_poly.append(Vector2(WIDTH, BOTTOM_Y))
	ground_poly.append(Vector2(0.0, BOTTOM_Y))

	# Bukit latar (parallax sederhana, tanpa fisika) - ikut skala ketinggian.
	var back := Polygon2D.new()
	back.name = "BackHills"
	back.z_index = -2
	back.color = _back
	var back_pts := PackedVector2Array()
	var back_amp := 130.0 * clampf(_amp, 1.0, 1.8)
	var bx := 0.0
	while bx <= WIDTH:
		back_pts.append(Vector2(bx, BASE_Y - 70.0 - _noise.get_noise_2d(bx * 0.5, 900.0) * back_amp))
		bx += 64.0
	back_pts.append(Vector2(WIDTH, BOTTOM_Y))
	back_pts.append(Vector2(0.0, BOTTOM_Y))
	back.polygon = back_pts
	add_child(back)

	var dirt := Polygon2D.new()
	dirt.name = "Ground"
	dirt.color = _dirt
	dirt.polygon = ground_poly
	add_child(dirt)

	# Strip permukaan: warna berbeda per jenis (rumput/lumpur/es).
	var surf: Array[int] = []
	for p in top:
		surf.append(surface_at(p.x))
	var run_start := 0
	for i in range(1, top.size() + 1):
		if i == top.size() or surf[i] != surf[run_start]:
			# Titik batas i-1 ikut run berikutnya agar tidak ada celah.
			_add_surface_strip(top, surf[run_start], run_start, mini(i, top.size() - 1))
			run_start = i

	var col := CollisionPolygon2D.new()
	col.name = "Collision"
	col.polygon = ground_poly
	add_child(col)


## Gambar strip permukaan untuk satu run indeks [from..to] (inklusif).
func _add_surface_strip(top: PackedVector2Array, s: int, from: int, to: int) -> void:
	if to <= from:
		return
	var thick := 30.0 if s == Surface.ICE else 24.0
	var color := _grass
	if s == Surface.MUD:
		color = MUD_COLOR
	elif s == Surface.ICE:
		color = ICE_COLOR
	var poly := PackedVector2Array()
	for k in range(from, to + 1):
		poly.append(top[k])
	for k in range(to, from - 1, -1):
		poly.append(top[k] + Vector2(0.0, thick))
	var strip := Polygon2D.new()
	strip.name = "Surface_%d_%d" % [from, to]
	strip.color = color
	strip.polygon = poly
	add_child(strip)

