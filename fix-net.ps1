$ErrorActionPreference='Continue'
$wg='C:\Program Files\WireGuard\wireguard.exe'
$f="$env:ProgramData\TheGrid.conf"
if(Test-Path $f){
  $c=Get-Content $f -Raw
  if($c -notmatch '192\.168\.68\.0/24'){
    Write-Host 'fixing AllowedIPs (adding home LAN) + reinstalling tunnel...'
    $c=$c -replace 'AllowedIPs\s*=.*','AllowedIPs = 10.99.99.0/24, 192.168.68.0/24'
    Set-Content $f $c -Encoding ASCII
    & $wg /uninstalltunnelservice TheGrid 2>$null; Start-Sleep 2
    & $wg /installtunnelservice $f; Start-Sleep 4
  } else { Write-Host 'AllowedIPs already includes home LAN' }
} else { Write-Host 'WARN: no C:\ProgramData\TheGrid.conf found - tell Claude' }
Get-NetConnectionProfile -EA 0 | Where-Object { $_.InterfaceAlias -match 'TheGrid|WireGuard|wg' } | ForEach-Object { Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private -EA 0 }
if(-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -EA 0)){ New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any | Out-Null }
Start-Sleep 2
Write-Host '--- STATE ---'
Write-Host ('AllowedIPs: ' + ((Get-Content $f -EA 0 | Select-String 'AllowedIPs')))
Write-Host ('WG adapter category: ' + ((Get-NetConnectionProfile -EA 0 | Where-Object {$_.InterfaceAlias -match 'TheGrid|WireGuard|wg'} | ForEach-Object {$_.NetworkCategory}) -join ','))
Write-Host ('mesh IP: ' + ((Get-NetIPAddress -AddressFamily IPv4 -EA 0|Where-Object{$_.IPAddress -like '10.99.99.*'}).IPAddress))
Write-Host ('sshd: ' + (Get-Service sshd -EA 0).Status)
Write-Host ('PC->home mesh 192.168.68.72:7681 = ' + (Test-NetConnection 192.168.68.72 -Port 7681 -InformationLevel Quiet))