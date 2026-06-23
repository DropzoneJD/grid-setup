$ErrorActionPreference='Continue'
$cfg="$env:ProgramData\TheGrid.conf"
if(-not (Test-Path $cfg)){ Write-Host "NO $cfg found - this PC's tunnel was a manual import; tell Claude"; return }
$c = Get-Content $cfg -Raw
Write-Host '=== current AllowedIPs ==='; ($c -split "`n" | Select-String 'Allowed')
if($c -notmatch '192\.168\.68\.0/24'){ $c = $c -replace 'AllowedIPs = .*','AllowedIPs = 10.99.99.0/24, 192.168.68.0/24'; Set-Content $cfg $c.TrimEnd() -Encoding ASCII; Write-Host 'patched AllowedIPs' } else { Write-Host 'AllowedIPs already has home LAN' }
$wg='C:\Program Files\WireGuard\wireguard.exe'
foreach($t in 'TheGrid','EscondidoRegister'){ try { & $wg /uninstalltunnelservice $t 2>$null } catch {} }
Start-Sleep 2
& $wg /installtunnelservice $cfg
Start-Sleep 5
Write-Host '=== new AllowedIPs ==='; (Get-Content $cfg | Select-String 'Allowed')
Write-Host ('mesh IP: ' + ((Get-NetIPAddress -AddressFamily IPv4 -EA 0 | Where-Object {$_.IPAddress -like '10.99.99.*'}).IPAddress))
Write-Host ('PC->home (192.168.68.72:7681): ' + (Test-NetConnection 192.168.68.72 -Port 7681 -InformationLevel Quiet))