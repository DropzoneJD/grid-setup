$ErrorActionPreference='Continue'
Write-Host '=== port 22 inbound rules BEFORE ==='
Get-NetFirewallPortFilter -EA 0 | Where-Object {$_.LocalPort -eq 22} | ForEach-Object { $r=$_|Get-NetFirewallRule -EA 0; if($r){ Write-Host ("$($r.DisplayName) | dir=$($r.Direction) act=$($r.Action) enabled=$($r.Enabled) profile=$($r.Profile)") } }
# drop any existing ssh-ish rule (could be disabled/mis-scoped) then add a clean allow
Get-NetFirewallRule -EA 0 | Where-Object {$_.DisplayName -match 'OpenSSH|sshd|SSH 22|TheGrid'} | Remove-NetFirewallRule -EA 0
New-NetFirewallRule -Name 'TheGrid-SSH-22' -DisplayName 'TheGrid SSH 22' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22 -Profile Any -Enabled True | Out-Null
Write-Host '=== port 22 inbound rules AFTER ==='
Get-NetFirewallPortFilter -EA 0 | Where-Object {$_.LocalPort -eq 22} | ForEach-Object { $r=$_|Get-NetFirewallRule -EA 0; if($r){ Write-Host ("$($r.DisplayName) | dir=$($r.Direction) act=$($r.Action) enabled=$($r.Enabled) profile=$($r.Profile)") } }
Write-Host ('sshd: '+(Get-Service sshd -EA 0).Status+' | listening22: '+[bool](Get-NetTCPConnection -LocalPort 22 -State Listen -EA 0))