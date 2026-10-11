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
<img width="1317" height="743" alt="Cuplikan layar 2026-10-11 191738" src="https://github.com/user-attachments/assets/73b2f2d7-70f8-496d-89fd-41610d985694" />
<img width="1324" height="759" alt="Cuplikan layar 2026-10-11 191637" src="https://github.com/user-attachments/assets/cb0fd806-9ef7-4886-89f7-ff91deb332a2" />
<img width="1318" height="752" alt="Cuplikan layar 2026-10-11 191626" src="https://github.com/user-attachments/assets/135a3f14-444f-4f1e-bff5-7ec7d54f8277" />
<img width="1305" height="745" alt="Cuplikan layar 2026-10-11 191613" src="https://github.com/user-attachments/assets/d9867d3f-9fe9-4837-b6b0-dc8729c766d9" />

