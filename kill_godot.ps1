Get-Process | Where-Object { $_.ProcessName -like 'Godot*' } |
	Stop-Process -Force -ErrorAction SilentlyContinue
Write-Output 'KILLED'
