# GameSederhana_Hill_Climb_Racing

Game 2D sederhana ala Hill Climb Racing dibuat dengan **Godot 4.7** (GL Compatibility).
Pemain mengendarai mobil melintasi medan bergelombang, mengumpulkan koin & bahan bakar,
dan membuka stage berdasarkan rating bintang.

## Fitur
- Fisika mobil 2D (RigidBody2D + suspensi spring)
- Terrain prosedural bergelombang (Line2D + StaticBody2D SegmentShape2D)
- Sistem koin, bahan bakar, dan GameState (save/load)
- Menu, Stage Select, Tier Stages, Garage (upgrade)
- Star rating per stage
- Export Windows Desktop + Android

## Struktur Project
```
scenes/    -> menu, main, stage_select, tier_stages, garage, car, coin, fuel_can
scripts/   -> car, terrain, main, menu, stage_select, tier_stages, garage,
              game_state (autoload), coin, fuel_can, star_rating
tests/     -> smoke test
project.godot
export_presets.cfg
```

## Cara Menjalankan (Godot Editor)
1. Install Godot 4.7.
2. Buka folder ini sebagai project (`project.godot`).
3. Main scene: `res://scenes/menu.tscn`.
4. Tekan F5 / Run.

## Kontrol
- Gas / Rem: tombol UI di layar (touch + mouse) atau aksi `gas` / `brake`
- Rotasi di udara: kiri / kanan

## Build / Export
Preset tersedia di `export_presets.cfg`:
- **Windows Desktop** -> `CloneHCR.exe` (+ `.pck`)
- **Android** -> `Hill Climb Racing.apk`

File build besar (`.exe`, `.pck`, `.apk`) dilacak dengan **Git LFS**.
Pastikan Git LFS terinstall sebelum clone:

```sh
git lfs install
git clone https://github.com/MuhHaikalBaadilah/GameSederhana_Hill_Climb_Racing.git
```

## Screenshot / Demo
(Tambahkan screenshot atau GIF gameplay di sini.)
