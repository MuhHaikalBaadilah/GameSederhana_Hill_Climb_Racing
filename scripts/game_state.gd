extends Node
## Data global game: definisi stage + simpanan progres (bintang & persen per stage).
## Menyimpan ke user://save.cfg lewat ConfigFile.

const SAVE_PATH := "user://save.cfg"
const STAR_2_AT := 0.75
const STAR_1_AT := 0.5

## Katalog upgrade mobil: 4 track, masing-masing 5 level (0 = standar).
## Harga per level dan efek dibaca oleh Car dan layar Garage.
const UPGRADE_MAX := 5
const UPGRADES: Array[Dictionary] = [
	{"id": "engine", "name": "Mesin", "desc": "+gaya dorong & top speed", "costs": [100, 200, 400, 800, 1500]},
	{"id": "tires", "name": "Ban", "desc": "+cengkeraman lumpur & es", "costs": [100, 200, 400, 800, 1500]},
	{"id": "suspension", "name": "Suspensi", "desc": "+pegas keras & stabil", "costs": [80, 160, 320, 640, 1200]},
	{"id": "fuel", "name": "Tangki", "desc": "+kapasitas bensin", "costs": [80, 160, 320, 640, 1200]},
]

## Definisi stage: 15 stage dalam 3 tier (easy/medium/hard), 5 stage tiap tier.
## "gravity_scale": 1.0 = bumi, <1.0 = gravitasi bulan (melayang, lompat jauh).
## Save lama (4 stage, indeks 0-3) tetap kompatibel: 4 stage easy pertama
## memakai definisi stage lama dengan nama/target sama.
const STAGES: Array[Dictionary] = [
	# ---------------- EASY (0-4) ----------------
	{
		"name": "Bukit Hijau", "tier": "easy",
		"target_m": 200.0,
		"seed": 10247,
		"amp": 1.25,
		"freq": 0.0013,
		"detail_freq": 0.0035,
		"rough": 1.0,
		"zone_mud": 0.25,
		"zone_ice": 0.0,
		"gravity_scale": 1.0,
		"sky": Color("#73c2fb"),
		"grass": Color("#6ab04c"),
		"dirt": Color("#8a5a3b"),
		"back": Color("#8fbf7f"),
	},
	{
		"name": "Padang Pasir", "tier": "easy",
		"target_m": 250.0,
		"seed": 88231,
		"amp": 1.5,
		"freq": 0.0014,
		"detail_freq": 0.004,
		"rough": 1.1,
		"zone_mud": 0.5,
		"zone_ice": 0.0,
		"gravity_scale": 1.0,
		"sky": Color("#f7c98b"),
		"grass": Color("#e0c083"),
		"dirt": Color("#c19a65"),
		"back": Color("#efc9a0"),
	},
	{
		"name": "Salju Abadi", "tier": "easy",
		"target_m": 300.0,
		"seed": 44590,
		"amp": 1.8,
		"freq": 0.0015,
		"detail_freq": 0.0045,
		"rough": 1.2,
		"zone_mud": 0.12,
		"zone_ice": 0.55,
		"ice_flat": 0.7,
		"ice_grip": 0.45,
		"gravity_scale": 1.0,
		"sky": Color("#b8d9ef"),
		"grass": Color("#ecf4f8"),
		"dirt": Color("#7f8fa6"),
		"back": Color("#cfe3f0"),
	},
	{
		"name": "Gunung Berapi", "tier": "easy",
		"target_m": 350.0,
		"seed": 99001,
		"amp": 2.1,
		"freq": 0.0016,
		"detail_freq": 0.0045,
		"rough": 1.3,
		"zone_mud": 0.4,
		"zone_ice": 0.35,
		"ice_flat": 0.6,
		"ice_grip": 0.45,
		"gravity_scale": 1.0,
		"sky": Color("#6b5566"),
		"grass": Color("#4a4a4a"),
		"dirt": Color("#6e3b2c"),
		"back": Color("#8a5348"),
	},
	{
		"name": "Bukit Bulan", "tier": "easy",
		"target_m": 220.0,
		"seed": 55011,
		"amp": 1.1,
		"freq": 0.0012,
		"detail_freq": 0.003,
		"rough": 0.9,
		"zone_mud": 0.15,
		"zone_ice": 0.0,
		"gravity_scale": 0.35,
		"sky": Color("#0b1026"),
		"grass": Color("#9aa3b2"),
		"dirt": Color("#5b5f6e"),
		"back": Color("#2a3350"),
	},
	# ---------------- MEDIUM (5-9) ----------------
	{
		"name": "Hutan Kabut", "tier": "medium",
		"target_m": 280.0,
		"seed": 31173,
		"amp": 1.5,
		"freq": 0.0015,
		"detail_freq": 0.0045,
		"rough": 1.25,
		"zone_mud": 0.55,
		"zone_ice": 0.05,
		"ice_flat": 0.6,
		"ice_grip": 0.45,
		"gravity_scale": 1.0,
		"sky": Color("#9fb8a8"),
		"grass": Color("#3e7d4f"),
		"dirt": Color("#5d4530"),
		"back": Color("#6e9983"),
	},
	{
		"name": "Ngarai Batu", "tier": "medium",
		"target_m": 300.0,
		"seed": 72845,
		"amp": 1.9,
		"freq": 0.0016,
		"detail_freq": 0.005,
		"rough": 1.4,
		"zone_mud": 0.2,
		"zone_ice": 0.0,
		"gravity_scale": 1.0,
		"sky": Color("#e8b06e"),
		"grass": Color("#b0713e"),
		"dirt": Color("#7d4f2e"),
		"back": Color("#d9a06b"),
	},
	{
		"name": "Pesisir Badai", "tier": "medium",
		"target_m": 320.0,
		"seed": 20918,
		"amp": 1.6,
		"freq": 0.0015,
		"detail_freq": 0.005,
		"rough": 1.35,
		"zone_mud": 0.45,
		"zone_ice": 0.2,
		"ice_flat": 0.6,
		"ice_grip": 0.42,
		"gravity_scale": 1.0,
		"sky": Color("#7fa8c9"),
		"grass": Color("#c2b280"),
		"dirt": Color("#8a6f4d"),
		"back": Color("#5f87a8"),
	},
	{
		"name": "Gurun Malam", "tier": "medium",
		"target_m": 340.0,
		"seed": 66402,
		"amp": 1.8,
		"freq": 0.0016,
		"detail_freq": 0.005,
		"rough": 1.4,
		"zone_mud": 0.35,
		"zone_ice": 0.3,
		"ice_flat": 0.6,
		"ice_grip": 0.42,
		"gravity_scale": 1.0,
		"sky": Color("#1d2440"),
		"grass": Color("#8a7a5c"),
		"dirt": Color("#6e5a3e"),
		"back": Color("#3a4666"),
	},
	{
		"name": "Kawah Bulan", "tier": "medium",
		"target_m": 300.0,
		"seed": 88120,
		"amp": 1.6,
		"freq": 0.0014,
		"detail_freq": 0.004,
		"rough": 1.2,
		"zone_mud": 0.25,
		"zone_ice": 0.25,
		"ice_flat": 0.65,
		"ice_grip": 0.42,
		"gravity_scale": 0.35,
		"sky": Color("#0b1026"),
		"grass": Color("#8e97a8"),
		"dirt": Color("#4e5260"),
		"back": Color("#232b45"),
	},
	# ---------------- HARD (10-14) ----------------
	{
		"name": "Tebing Terjal", "tier": "hard",
		"target_m": 350.0,
		"seed": 15027,
		"amp": 2.3,
		"freq": 0.0017,
		"detail_freq": 0.0055,
		"rough": 1.5,
		"zone_mud": 0.2,
		"zone_ice": 0.15,
		"ice_flat": 0.6,
		"ice_grip": 0.4,
		"gravity_scale": 1.0,
		"sky": Color("#a8c6e0"),
		"grass": Color("#5c7a4a"),
		"dirt": Color("#5f4a38"),
		"back": Color("#7d9bb5"),
	},
	{
		"name": "Rawa Lumpur", "tier": "hard",
		"target_m": 320.0,
		"seed": 43956,
		"amp": 1.7,
		"freq": 0.0015,
		"detail_freq": 0.005,
		"rough": 1.3,
		"zone_mud": 0.7,
		"zone_ice": 0.0,
		"gravity_scale": 1.0,
		"sky": Color("#6f8f6a"),
		"grass": Color("#2f5d33"),
		"dirt": Color("#4a3524"),
		"back": Color("#54704f"),
	},
	{
		"name": "Badai Es", "tier": "hard",
		"target_m": 380.0,
		"seed": 90234,
		"amp": 2.0,
		"freq": 0.0016,
		"detail_freq": 0.005,
		"rough": 1.35,
		"zone_mud": 0.05,
		"zone_ice": 0.65,
		"ice_flat": 0.75,
		"ice_grip": 0.4,
		"gravity_scale": 1.0,
		"sky": Color("#cfe8f5"),
		"grass": Color("#e8f4fa"),
		"dirt": Color("#6b7f95"),
		"back": Color("#a9cde3"),
	},
	{
		"name": "Kaldera Lava", "tier": "hard",
		"target_m": 400.0,
		"seed": 77701,
		"amp": 2.4,
		"freq": 0.0018,
		"detail_freq": 0.0055,
		"rough": 1.55,
		"zone_mud": 0.45,
		"zone_ice": 0.3,
		"ice_flat": 0.6,
		"ice_grip": 0.4,
		"gravity_scale": 1.0,
		"sky": Color("#3d1f1f"),
		"grass": Color("#3a3a3a"),
		"dirt": Color("#5e2b1e"),
		"back": Color("#7a3a2a"),
	},
	{
		"name": "Orbit Rendah", "tier": "hard",
		"target_m": 350.0,
		"seed": 31415,
		"amp": 2.2,
		"freq": 0.0016,
		"detail_freq": 0.0045,
		"rough": 1.4,
		"zone_mud": 0.2,
		"zone_ice": 0.4,
		"ice_flat": 0.7,
		"ice_grip": 0.42,
		"gravity_scale": 0.35,
		"sky": Color("#05070f"),
		"grass": Color("#7d8aa0"),
		"dirt": Color("#3f4350"),
		"back": Color("#1a2340"),
	},
]

var selected_stage := 0
## Tier yang sedang dibuka di layar daftar stage ("easy"/"medium"/"hard").
var selected_tier := "easy"
var _best: Dictionary = {}
var total_coins := 0
var _upgrades: Dictionary = {}


func _ready() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		for i in STAGES.size():
			_best[i] = float(cf.get_value("stages", "best_%d" % i, 0.0))
		total_coins = int(cf.get_value("wallet", "coins", 0))
		for u in UPGRADES:
			_upgrades[str(u["id"])] = int(cf.get_value("upgrades", str(u["id"]), 0))


func stage_count() -> int:
	return STAGES.size()


func stage_def(i: int) -> Dictionary:
	return STAGES[i]


## Daftar tier berurutan beserta judul tampilannya.
func tier_list() -> Array[Dictionary]:
	return [
		{"id": "easy", "title": "EASY"},
		{"id": "medium", "title": "MEDIUM"},
		{"id": "hard", "title": "HARD"},
	]


## Indeks stage dalam tier tertentu, berurutan sesuai STAGES.
func stages_in_tier(tier_id: String) -> Array[int]:
	var out: Array[int] = []
	for i in STAGES.size():
		if str(STAGES[i].get("tier", "easy")) == tier_id:
			out.append(i)
	return out


## Skala gravitasi stage (1.0 = bumi, 0.35 = bulan).
func gravity_scale(i: int) -> float:
	return float(STAGES[i].get("gravity_scale", 1.0))


## true jika stage memakai gravitasi bulan.
func is_moon(i: int) -> bool:
	return gravity_scale(i) < 0.9


## Total bintang tier (maks 15 = 5 stage x 3 bintang).
func tier_stars(tier_id: String) -> int:
	var total := 0
	for i in stages_in_tier(tier_id):
		total += stage_stars(i)
	return total


## Jumlah stage tier yang sudah tuntas (3 bintang).
func tier_cleared(tier_id: String) -> int:
	var n := 0
	for i in stages_in_tier(tier_id):
		if stage_stars(i) >= 3:
			n += 1
	return n


## Tier terbuka jika tier sebelumnya punya >= 1 bintang (easy selalu terbuka).
## Urutan tier mengikuti tier_list().
func is_tier_unlocked(tier_id: String) -> bool:
	var tiers := tier_list()
	for t in range(tiers.size()):
		if str(tiers[t]["id"]) == tier_id:
			if t == 0:
				return true
			var prev_id := str(tiers[t - 1]["id"])
			return tier_stars(prev_id) >= 1
	return false


func target_m(i: int) -> float:
	return float(STAGES[i]["target_m"])


func best_distance(i: int) -> float:
	return float(_best.get(i, 0.0))


func percent_of(i: int, dist_m: float) -> float:
	return clampf(dist_m / target_m(i), 0.0, 1.0)


func stars_from_percent(p: float) -> int:
	if p >= 1.0:
		return 3
	if p >= STAR_2_AT:
		return 2
	if p >= STAR_1_AT:
		return 1
	return 0


func stage_percent(i: int) -> float:
	return percent_of(i, best_distance(i))


func stage_stars(i: int) -> int:
	return stars_from_percent(stage_percent(i))


func is_unlocked(i: int) -> bool:
	return i == 0 or stage_stars(i - 1) >= 1


## Simpan jarak terbaik stage; mengembalikan best terbaru.
func submit_distance(i: int, dist_m: float) -> float:
	if dist_m > best_distance(i):
		_best[i] = dist_m
		_save()
	return best_distance(i)


## Tambah koin ke dompet (dipanggil saat koin terkumpul di stage).
func add_coins(n: int) -> void:
	total_coins += n
	_save()


## Level upgrade 0..UPGRADE_MAX untuk id tertentu.
func upgrade_level(id: String) -> int:
	return clampi(int(_upgrades.get(id, 0)), 0, UPGRADE_MAX)


## Harga level berikutnya, -1 jika sudah maksimal.
func upgrade_cost(id: String) -> int:
	var lvl := upgrade_level(id)
	for u in UPGRADES:
		if str(u["id"]) == id:
			var costs: Array = u["costs"]
			return int(costs[lvl]) if lvl < costs.size() else -1
	return -1


## Beli satu level upgrade; true jika berhasil (koin cukup & belum max).
func buy_upgrade(id: String) -> bool:
	var cost := upgrade_cost(id)
	if cost < 0 or total_coins < cost:
		return false
	total_coins -= cost
	_upgrades[id] = upgrade_level(id) + 1
	_save()
	return true


func _save() -> void:
	var cf := ConfigFile.new()
	for k in _best:
		cf.set_value("stages", "best_%d" % int(k), float(_best[k]))
	cf.set_value("wallet", "coins", total_coins)
	for u in UPGRADES:
		var id := str(u["id"])
		cf.set_value("upgrades", id, upgrade_level(id))
	if cf.save(SAVE_PATH) != OK:
		push_warning("Gagal menyimpan progres ke " + SAVE_PATH)
