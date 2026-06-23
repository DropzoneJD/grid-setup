$ErrorActionPreference='Continue'
Write-Host '== OpenSSH install =='
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
$d='C:\Program Files\OpenSSH'
if(-not (Test-Path (Join-Path $d 'sshd.exe'))){
  $z="$env:TEMP\osshg.zip"
  try { Invoke-WebRequest 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/download/OpenSSH-Win64.zip' -OutFile $z -UseBasicParsing } catch { Write-Host ('DOWNLOAD FAILED: '+$_.Exception.Message); return }
  Expand-Archive $z "$env:TEMP\osshg" -Force
  $s=(Get-ChildItem "$env:TEMP\osshg" -Directory | Select-Object -First 1).FullName
  New-Item -ItemType Directory -Force $d | Out-Null
  Copy-Item (Join-Path $s '*') $d -Recurse -Force
}
& powershell -ExecutionPolicy Bypass -File (Join-Path $d 'install-sshd.ps1') | Out-Null
Set-Service sshd -StartupType Automatic -EA 0; Start-Service sshd -EA 0
if(-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -EA 0)){ New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any | Out-Null }
$ak="$env:ProgramData\ssh\administrators_authorized_keys"; $pub='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbUdUEUSPdjCc4DxvnR41nll0rB+rMNkYbANQ0TF8Wn pc_workpc'
if(-not (Test-Path $ak)){ New-Item -ItemType File -Path $ak -Force | Out-Null }
if(-not (Select-String -Path $ak -SimpleMatch 'pc_workpc' -Quiet)){ Add-Content $ak $pub }
icacls $ak /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null
Start-Sleep 5
Write-Host ('sshd: '+(Get-Service sshd -EA 0).Status+' | listening22: '+[bool](Get-NetTCPConnection -LocalPort 22 -State Listen -EA 0))