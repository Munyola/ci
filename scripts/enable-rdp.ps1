# get current IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like 'ethernet*'}).IPAddress
$port = 3389

# get password or generate
$password = ''
if($env:appveyor_rdp_password) {
    # take from environment variable
    $password = $env:appveyor_rdp_password
    
    # change password
    $objUser = [ADSI]("WinNT://$($env:computername)/appveyor")
    $objUser.SetPassword($password)
    [Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", $password)
} else {
    # get existing password
    $password = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", '')
}

if($ip.StartsWith('172.24.')) {
    $port = 33800 + ($ip.split('.')[2] - 16) * 256 + $ip.split('.')[3]
} elseif ($ip.StartsWith('192.168.') -or $ip.StartsWith('10.240.')) {
    # new environment - behind NAT
    $port = 33800 + ($ip.split('.')[2] - 0) * 256 + $ip.split('.')[3]
}

# get external IP
$ip = (New-Object Net.WebClient).DownloadString('https://www.appveyor.com/tools/my-ip.aspx').Trim()

# allow RDP on firewall
Enable-NetFirewallRule -DisplayName 'Remote Desktop - User Mode (TCP-in)'

Write-Host "Remote Desktop connection details:" -ForegroundColor Yellow
Write-Host "  Server: $ip`:$port" -ForegroundColor Gray
Write-Host "  Username: appveyor" -ForegroundColor Gray
if(-not $env:appveyor_rdp_password) {
    Write-Host "  Password: $password" -ForegroundColor Gray
}

if($blockRdp) {
    # place "lock" file
    $path = "$($env:USERPROFILE)\Desktop\Delete me to continue build.txt"
    Set-Content -Path $path -Value ''    
    Write-Warning "There is 'Delete me to continue build.txt' file has been created on Desktop - delete it to continue the build."

    while($true) { if (-not (Test-Path $path)) { break; } else { Start-Sleep -Seconds 1 } }
}
