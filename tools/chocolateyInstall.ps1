﻿$ErrorActionPreference = 'Stop'; # stop on all errors

$toolsDir = Split-Path $MyInvocation.MyCommand.Definition
. $toolsDir\helpers.ps1

$packageName   = $env:ChocolateyPackageName
$url           = 'https://selenium-release.storage.googleapis.com/3.5/selenium-server-standalone-3.5.3.jar'
$checksum      = '3dd4cad1d343f9d1cb1302ef1b3cec98'
$checksumType  = 'md5'
$toolsLocation = Get-ToolsLocation
$seleniumDir   = "$toolsLocation\selenium"
$seleniumPath  = "$seleniumDir\selenium-server-standalone.jar"
$pp            = Get-SeleniumConfigDefaults
$name          = "Selenium$((Get-Culture).TextInfo.ToTitleCase($pp["role"]))"

if (!(Test-Path $seleniumDir)) {
  New-Item $seleniumDir -ItemType directory
}

if ($pp["log"] -ne $null -and $pp["log"] -ne '' -and !(Test-Path $pp["log"])) {
  New-Item -ItemType "file" -Path $pp["log"]
}

# https://chocolatey.org/docs/helpers-get-chocolatey-web-file
Get-ChocolateyWebFile $packageName $seleniumPath $url -checksum $checksum -checksumType $checksumType

Write-Host -ForegroundColor Green Added selenium-server-standalone.jar to $seleniumDir

$config = Get-SeleniumConfig($pp)

Write-Debug "Selenium configuration: $config"

$configPath = "$seleniumDir/$($pp["role"])config.json"
if ($pp["role"] -ne 'standalone') {
  $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
}

if ($pp["role"] -eq 'hub') {
  $options = "-hubConfig ""$configPath"""
} elseif ($pp["role"] -eq 'node' ) {
  $options = "-nodeConfig ""$configPath"""
} else {
  $keys = $config.keys
  foreach ($key in $keys) {
    $options += " -$key "
    if ($config[$key] -is [String] -and $config[$key] -ne 'role') {
      $options += """$($config[$key])"" "
    } else {
      $options += "$config[$key] "
    }
  }
}

$cmd = "java $($pp["args"]) -jar ""$seleniumPath"" $options"
$cmdPath = "$seleniumDir/$($pp["role"]).cmd"
$cmd | Set-Content $cmdPath

Write-Debug "Selenium command: $cmd"

$rules = Get-NetFirewallRule
$par = @{
    DisplayName = "$name"
    LocalPort = $pp["port"]
    Direction="Inbound"
    Protocol ="TCP"
    Action = "Allow"
}
if (-not $rules.DisplayName.Contains($par.DisplayName)) {New-NetFirewallRule @par}

Write-Debug "Selenium firewall: $par"

$menuPrograms = [environment]::GetFolderPath([environment+specialfolder]::Programs)

$menuPrograms = [environment]::GetFolderPath([environment+specialfolder]::Programs)
$shortcutArgs = @{
  shortcutFilePath = "$menuPrograms\Selenium\Selenium $((Get-Culture).TextInfo.ToTitleCase($pp["role"])).lnk"
  targetPath       = $cmdPath
  iconLocation     = "$toolsDir\icon.ico"
}

Install-ChocolateyShortcut @shortcutArgs

if ($pp["autostart"] -eq $true) {
  # nssm set $name Start SERVICE_AUTO_START
}
