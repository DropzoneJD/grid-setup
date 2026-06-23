Write-Host '=== sshd ==='; Get-Service sshd -EA 0 | Select-Object Status,StartType | Format-Table | Out-String | Write-Host
Write-Host '=== listening 22 ==='; (Get-NetTCPConnection -LocalPort 22 -State Listen -EA 0 | Select-Object LocalAddress | Format-Table | Out-String) | Write-Host
Write-Host '=== TheGrid.conf Address/AllowedIPs ==='; if(Test-Path "$env:ProgramData\TheGrid.conf"){ Get-Content "$env:ProgramData\TheGrid.conf" | Select-String 'Address|Allowed' | ForEach-Object { Write-Host $_ } } else { Write-Host 'no TheGrid.conf' }
Write-Host '=== WG adapter category ==='; Get-NetConnectionProfile -EA 0 | Select-Object InterfaceAlias,NetworkCategory | Format-Table | Out-String | Write-Host
Write-Host ('OpenSSH fw rule present: ' + [bool](Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -EA 0))
Write-Host '=== fw profiles ==='; Get-NetFirewallProfile | Select-Object Name,Enabled,DefaultInboundAction | Format-Table | Out-String | Write-Host
Write-Host ('PC->home mesh (192.168.68.72:7681): ' + (Test-NetConnection 192.168.68.72 -Port 7681 -InformationLevel Quiet))
Write-Host ('mesh IP: ' + ((Get-NetIPAddress -AddressFamily IPv4 -EA 0 | Where-Object {$_.IPAddress -like '10.99.99.*'}).IPAddress))