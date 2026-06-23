$ErrorActionPreference='Continue'
Write-Host '== installing OpenSSH Server from GitHub =='
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$dst='C:\Program Files\OpenSSH'
if(-not (Test-Path (Join-Path $dst 'sshd.exe'))){
  $zip="$env:TEMP\osshg.zip"; $ex="$env:TEMP\osshg"
  try { Invoke-WebRequest 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/download/OpenSSH-Win64.zip' -OutFile $zip -UseBasicParsing } catch { Write-Host ('DOWNLOAD FAILED: '+$_.Exception.Message+' (likely wrong system clock/TLS)'); return }
  Expand-Archive $zip -DestinationPath $ex -Force
  $src=Get-ChildItem $ex -Directory | Select-Object -First 1
  New-Item -ItemType Directory -Force $dst | Out-Null
  Copy-Item (Join-Path $src.FullName '*') $dst -Recurse -Force
}
& powershell -ExecutionPolicy Bypass -File (Join-Path $dst 'install-sshd.ps1') | Out-Null
Set-Service sshd -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service sshd -ErrorAction SilentlyContinue
if(-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)){ New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null }
$ak="$env:ProgramData\ssh\administrators_authorized_keys"; $pub='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbUdUEUSPdjCc4DxvnR41nll0rB+rMNkYbANQ0TF8Wn pc_workpc'
if(-not (Test-Path $ak)){ New-Item -ItemType File -Path $ak -Force | Out-Null }
if(-not (Select-String -Path $ak -SimpleMatch 'pc_workpc' -Quiet)){ Add-Content $ak $pub }
icacls $ak /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null
Start-Sleep 5
Write-Host ('sshd: '+(Get-Service sshd -ErrorAction SilentlyContinue).Status+' | listening22: '+[bool](Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue))
