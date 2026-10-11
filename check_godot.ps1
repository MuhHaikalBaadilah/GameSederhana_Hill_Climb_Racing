Start-Sleep -Seconds 4
$p = Get-Process | Where-Object { $_.ProcessName -like 'Godot*' }
if ($p) {
	$p | ForEach-Object {
		Write-Output ("OK PID=" + $_.Id + " MEM=" + [math]::Round($_.WorkingSet64/1MB,1) + "MB TITLE='" + $_.MainWindowTitle + "' RESP=" + $_.Responding)
	}
} else {
	Write-Output 'MATI_TIDAK_ADA_PROSES'
}
