$ErrorActionPreference='Continue'
$Pub='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbUdUEUSPdjCc4DxvnR41nll0rB+rMNkYbANQ0TF8Wn pc_workpc'
$wg='C:\Program Files\WireGuard\wireguard.exe'
$cfg="$env:ProgramData\TheGrid.conf"
$log="$env:ProgramData\TheGrid-heal.log"
function Log($m){ "{0}  {1}" -f (Get-Date -Format s), $m | Out-File -FilePath $log -Append -Encoding ascii }
if(Test-Path $cfg){
  $c = Get-Content $cfg -Raw
  $want='AllowedIPs = 10.99.99.0/24, 192.168.68.0/24'
  $patched=$false
  if($c -notmatch '192\.168\.68\.0/24'){ $c=[regex]::Replace($c,'(?m)^\s*AllowedIPs\s*=.*$',$want); Set-Content $cfg ($c.TrimEnd()) -Encoding ascii; $patched=$true; Log 'patched AllowedIPs' }
  $svc = Get-Service 'WireGuardTunnel$TheGrid' -ErrorAction SilentlyContinue
  if(((-not $svc) -or $patched) -and (Test-Path $wg)){ & $wg /uninstalltunnelservice TheGrid 2>$null; Start-Sleep 2; & $wg /installtunnelservice $cfg; Log 'installed/reinstalled tunnel' }
  elseif($svc -and $svc.Status -ne 'Running'){ Start-Service $svc.Name -ErrorAction SilentlyContinue; Log 'started tunnel' }
} else { Log 'NO TheGrid.conf - needs initial provisioning' }
Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -match 'TheGrid|WireGuard' -and $_.NetworkCategory -ne 'Private' } | ForEach-Object { Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private -ErrorAction SilentlyContinue; Log 'adapter Private' }
$ssh = Get-Service sshd -ErrorAction SilentlyContinue
if($ssh){ if($ssh.StartType -ne 'Automatic'){ Set-Service sshd -StartupType Automatic -ErrorAction SilentlyContinue }; if($ssh.Status -ne 'Running'){ Start-Service sshd -ErrorAction SilentlyContinue; Log 'started sshd' } }
if(-not (Get-NetFirewallRule -Name 'TheGrid-SSH-22' -ErrorAction SilentlyContinue)){ Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'OpenSSH|sshd' } | Remove-NetFirewallRule -ErrorAction SilentlyContinue; New-NetFirewallRule -Name 'TheGrid-SSH-22' -DisplayName 'TheGrid SSH 22' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22 -Profile Any -Enabled True -ErrorAction SilentlyContinue | Out-Null; Log 'fw rule 22' }
$akDir="$env:ProgramData\ssh"; $ak="$akDir\administrators_authorized_keys"
if(-not (Test-Path $akDir)){ New-Item -ItemType Directory -Force $akDir | Out-Null }
if(-not (Test-Path $ak)){ New-Item -ItemType File -Path $ak -Force | Out-Null }
if(-not (Select-String -Path $ak -SimpleMatch 'pc_workpc' -Quiet -ErrorAction SilentlyContinue)){ Add-Content $ak $Pub; & icacls $ak /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null; Log 'authorized key' }
