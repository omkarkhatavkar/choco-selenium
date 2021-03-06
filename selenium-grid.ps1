##
# Install Chocolatey - https://chocolatey.org
##

Set-ExecutionPolicy Bypass; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))


##
# Install Selenium-Grid Dependencies
##

choco install -y nssm --pre
choco install -y googlechrome --ignorechecksum
choco install -y jdk10 firefox selenium-gecko-driver selenium-chrome-driver selenium-ie-driver selenium-edge-driver


##
# Install Selenium-Grid
##

choco pack C:\vagrant\selenium.nuspec --outputdirectory C:\vagrant
choco install -y selenium --params "'/role:hub /service /port:4446 /autostart /log'" -d -s C:\vagrant --force
$capabilitiesJson = "C:\tools\selenium\tn8-capabilities.json"
@'
[
  {
    "browserName": "firefox",
    "maxInstances": 5,
    "version": "autoversion",
    "seleniumProtocol": "WebDriver"
  },
  {
    "browserName": "chrome",
    "maxInstances": 5,
    "version": "autoversion",
    "seleniumProtocol": "WebDriver"
  },
  {
    "browserName": "internet explorer",
    "maxInstances": 1,
    "version": "autoversion",
    "seleniumProtocol": "WebDriver"
  },
  {
    "browserName": "MicrosoftEdge",
    "maxInstances": 5,
    "version": "autoversion",
    "seleniumProtocol": "WebDriver"
  }
]
'@ | New-Item $capabilitiesJson -Type file -Force
choco install -y selenium --params "'/role:node /hub:http://localhost:4446 /capabilitiesJson:$capabilitiesJson /port:5557 /autostart /log'" -d -s C:\vagrant --force


##
# Configure Auto-Logon
##

choco install -y autologon
autologon $env:username $env:userdomain vagrant


##
# Disable autoupdate - updates during testing may cause test failure
##

If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
  New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 1


##
# Disable Windows Defender - defender may cause test failure (Windows 10/Windows 2016 Server only)
##

If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender")) {
  New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Type DWord -Value 1
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "SecurityHealth" -ErrorAction SilentlyContinue


##
# Disable Action Center - notifications may cause test failure (Windows 10/Windows 2016 Server only)
##

If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
  New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null
}
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0
