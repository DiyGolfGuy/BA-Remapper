$ErrorActionPreference = 'Stop'
# Upgrade verification seeds Documents and installs both versions. Never
# run that fixture on a user's simulator PC or development workstation.
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_OS -ne 'Windows') {
    throw 'Packaging with upgrade verification requires a disposable GitHub Windows runner. Do not run on a simulator PC.'
}
Set-Location (Split-Path $PSScriptRoot -Parent)
$version = (Get-Content release-version.txt -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid release version' }
if (!(Select-String -Path BARemapper.ahk -SimpleMatch ('AppVersion := "' + $version + '"') -Quiet)) { throw 'App version mismatch' }
if (!(Select-String -Path BARemapper_Setup.nsi -SimpleMatch ('!define VERSION "' + $version + '"') -Quiet)) { throw 'Installer version mismatch' }

$ahk = "$env:RUNNER_TEMP/ahk"
Invoke-WebRequest https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.1.37.02/AutoHotkey_1.1.37.02.zip -OutFile "$env:RUNNER_TEMP/ahk.zip"
Expand-Archive "$env:RUNNER_TEMP/ahk.zip" $ahk -Force
python tests/verify_remapper.py --ahk "$ahk/AutoHotkeyU64.exe"
if ($LASTEXITCODE -ne 0) { throw 'Regression checks failed' }

$compile = Start-Process "$ahk/Compiler/Ahk2Exe.exe" -ArgumentList "/in `"$pwd/BARemapper.ahk`" /out `"$pwd/BARemapper.exe`" /base `"$ahk/Compiler/Unicode 64-bit.bin`" /silent" -PassThru
if (!$compile.WaitForExit(60000)) { $compile.Kill(); throw 'Compiler timed out' }
if ($compile.ExitCode -ne 0 -or !(Test-Path BARemapper.exe)) { throw 'Compile failed' }
$info = (Get-Item BARemapper.exe).VersionInfo
if ($info.ProductName -ne 'BA Remapper' -or $info.ProductVersion -notlike "$version*") { throw 'Executable branding/version mismatch' }

$nsis = "${env:ProgramFiles(x86)}/NSIS/makensis.exe"
if (!(Test-Path $nsis)) {
    choco install nsis --version=3.11 -y --no-progress
    if ($LASTEXITCODE -ne 0) { throw 'NSIS installation failed' }
}
& $nsis /V3 BARemapper_Setup.nsi
if ($LASTEXITCODE -ne 0 -or !(Test-Path "BARemapper_Setup_v$version.exe")) { throw 'Installer compile failed' }

# Upgrade an actual v5.0.9 installation on this disposable Windows runner.
# Seed a custom profile and preferences; both must survive both installs.
$config = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'BA Custom Products/Remapper'
if (Test-Path $config) { throw 'Refusing to seed upgrade tests over an existing Remapper configuration' }
New-Item "$config/profiles" -ItemType Directory -Force | Out-Null
Set-Content "$config/settings.ini" "[App]`r`nActiveProfile=UpgradeTest`r`nStartupProfile=UpgradeTest`r`nScrambleAutoPick=0`r`nScrambleDelay=15`r`n" -Encoding unicode
Set-Content "$config/profiles/UpgradeTest.ini" "[Profile]`r`nFnButtonId=resetaim`r`nclubdown_Type=key`r`nclubdown_Value=b`r`n" -Encoding unicode
$beforeSettings = (Get-FileHash "$config/settings.ini").Hash
$beforeProfile = (Get-FileHash "$config/profiles/UpgradeTest.ini").Hash
Invoke-WebRequest https://github.com/DiyGolfGuy/BA-Remapper/releases/download/v5.0.9/BARemapper_Setup_v5.0.9.zip -OutFile "$env:RUNNER_TEMP/previous.zip"
Expand-Archive "$env:RUNNER_TEMP/previous.zip" "$env:RUNNER_TEMP/previous" -Force
$previous = Get-ChildItem "$env:RUNNER_TEMP/previous" -Recurse -Filter '*.exe' | Select-Object -First 1
if (!$previous) { throw 'Previous installer missing' }
$installDir = Join-Path $env:RUNNER_TEMP 'remapper-upgrade-test'
foreach ($installer in @($previous.FullName, (Join-Path $pwd "BARemapper_Setup_v$version.exe"))) {
    Write-Host "Verifying installer $installer into $installDir"
    # -Wait follows the full installer process tree, including an
    # elevation/relaunch child. WaitForExit follows only its parent.
    $process = Start-Process $installer -ArgumentList "/S /D=$installDir" -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Installer failed: $($process.ExitCode)" }
    if (!(Test-Path "$installDir/BARemapper.exe")) {
        Get-ItemProperty 'HKLM:/Software/WOW6432Node/Microsoft/Windows/CurrentVersion/Uninstall/BARemapper' -ErrorAction SilentlyContinue | Select-Object DisplayName,DisplayVersion,InstallLocation | Format-List
        throw "Installer did not create $installDir/BARemapper.exe"
    }
    if ((Get-FileHash "$config/settings.ini").Hash -ne $beforeSettings -or (Get-FileHash "$config/profiles/UpgradeTest.ini").Hash -ne $beforeProfile) { throw 'Installer changed existing settings/profile' }
}
if ((Get-FileHash "$installDir/BARemapper.exe").Hash -ne (Get-FileHash BARemapper.exe).Hash) { throw 'Upgrade did not install the new binary' }
if (!(Test-Path "$installDir/Uninstall.exe")) { throw 'Uninstaller missing after upgrade' }
Write-Host 'PASS: v5.0.9 to new-version installer upgrade preserved profiles/preferences and installed the exact new binary'

New-Item dist -ItemType Directory -Force | Out-Null
Compress-Archive -Path "BARemapper_Setup_v$version.exe" -DestinationPath "dist/BARemapper_Setup_v$version.zip" -Force
Copy-Item README.md "$env:RUNNER_TEMP/README.txt"
Compress-Archive -Path BARemapper.exe,"$env:RUNNER_TEMP/README.txt" -DestinationPath "dist/BARemapper_v${version}_portable.zip" -Force
$sums = Get-ChildItem dist -Filter '*.zip' | Sort-Object Name | ForEach-Object { "{0}  {1}" -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower(), $_.Name }
[IO.File]::WriteAllText((Join-Path $pwd 'dist/SHA256SUMS.txt'), ($sums -join "`n") + "`n", [Text.UTF8Encoding]::new($false))
Write-Host "PASS: release $version packaged with SHA-256 checksums"
