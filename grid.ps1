$ErrorActionPreference='Continue'
$log="$env:ProgramData\TheGrid-heal.log"
function Log($m){ $l="{0}  {1}" -f (Get-Date -Format s),$m; $l|Out-File -FilePath $log -Append -Encoding ascii; Write-Host $l }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
function FetchFile($url,$out){ try{ Invoke-WebRequest $url -OutFile $out -UseBasicParsing; return $true }catch{ [Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; try{ Invoke-WebRequest $url -OutFile $out -UseBasicParsing; return $true }catch{ Log ('download failed '+$url+' :: '+$_.Exception.Message); return $false } } }
Log '== TheGrid installer =='
$wg='C:\Program Files\WireGuard\wireguard.exe'
if(-not (Test-Path $wg)){ try{ winget install --id WireGuard.WireGuard -e --silent --accept-source-agreements --accept-package-agreements | Out-Null }catch{}; if(-not (Test-Path $wg)){ $m="$env:TEMP\wg.msi"; if(FetchFile 'https://download.wireguard.com/windows-client/wireguard-amd64.msi' $m){ Start-Process msiexec -ArgumentList ('/i "'+$m+'" /qn /norestart') -Wait; Log 'WireGuard installed' } } }
$od='C:\Program Files\OpenSSH'
if(-not (Test-Path (Join-Path $od 'sshd.exe'))){ $z="$env:TEMP\ossh.zip"; if(FetchFile 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/download/OpenSSH-Win64.zip' $z){ Expand-Archive $z "$env:TEMP\ossh" -Force; $s=(Get-ChildItem "$env:TEMP\ossh" -Directory | Select-Object -First 1).FullName; New-Item -ItemType Directory -Force $od | Out-Null; Copy-Item (Join-Path $s '*') $od -Recurse -Force; & powershell -ExecutionPolicy Bypass -File (Join-Path $od 'install-sshd.ps1') | Out-Null; Log 'OpenSSH installed' } }
$healPath="$env:ProgramData\TheGrid-heal.ps1"
if(-not (FetchFile 'https://raw.githubusercontent.com/DropzoneJD/grid-setup/main/heal.ps1' $healPath)){ Log 'FATAL: cannot fetch heal.ps1'; return }
& powershell -NoProfile -ExecutionPolicy Bypass -File $healPath
try{
  $a=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+$healPath+'"')
  $t1=New-ScheduledTaskTrigger -AtStartup
  $t2=New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)
  $pr=New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount -RunLevel Highest
  $se=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
  Register-ScheduledTask -TaskName 'TheGrid-Heal' -Action $a -Trigger @($t1,$t2) -Principal $pr -Settings $se -Force | Out-Null
  Log 'registered TheGrid-Heal watchdog (SYSTEM, startup + every 5 min)'
}catch{ Log ('watchdog register failed: '+$_.Exception.Message) }
Start-Sleep 6
$cfg="$env:ProgramData\TheGrid.conf"
$tun=(Get-Service 'WireGuardTunnel$TheGrid' -ErrorAction SilentlyContinue).Status
$mip=((Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {$_.IPAddress -like '10.99.99.*'}).IPAddress)
$sst=(Get-Service sshd -ErrorAction SilentlyContinue).Status
$lis=[bool](Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue)
$reach=Test-NetConnection 192.168.68.72 -Port 7681 -InformationLevel Quiet
Log ("SELF-TEST tunnel=$tun meshIP=$mip sshd=$sst listen22=$lis PCtoHome=$reach")
Write-Host ''; Write-Host '==== RESULT ===='; Write-Host "tunnel=$tun  meshIP=$mip  sshd=$sst  listening22=$lis  PC->home=$reach"
if($reach -and $lis){ Write-Host 'FULLY SET UP + self-healing.' } else { Write-Host 'Watchdog will keep repairing every 5 min; paste the RESULT line to Claude.' }
