$p = Join-Path $env:APPDATA 'Godot\app_userdata\Hill Climb Racer\save.cfg'
if (Test-Path $p) {
	Get-Content $p
} else {
	Write-Output 'SAVE_BELUM_ADA'
}
