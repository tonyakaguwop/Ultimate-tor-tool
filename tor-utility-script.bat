@echo off
setlocal EnableDelayedExpansion
title Ultimate Tor Tool

:: Check for Admin privileges
NET SESSION >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    pause
    exit /b 1
)

:: Set up directories
set "SCRIPT_DIR=%~dp0"
set "TOR_DIR=%SCRIPT_DIR%tor"
set "DOWNLOAD_DIR=%SCRIPT_DIR%downloads"
set "TOR_EXPERT_BUNDLE_URL=https://dist.torproject.org/torbrowser/13.0.4/tor-expert-bundle-13.0.4-windows-x86_64.tar.gz"
set "TOR_EXPERT_BUNDLE_FILE=tor-expert-bundle.tar.gz"
set "CURL_URL=https://curl.se/windows/dl-8.4.0_5/curl-8.4.0_5-win64-mingw.zip"
set "CURL_FILE=curl.zip"
set "7ZIP_URL=https://www.7-zip.org/a/7z2301-x64.exe"
set "7ZIP_FILE=7z-installer.exe"
set "TOR_SERVICE_NAME=tor"
set "TOR_EXE=%TOR_DIR%\Tor\tor.exe"
set "TORRC_FILE=%TOR_DIR%\Data\Tor\torrc"
set "HAS_CURL=0"
set "HAS_7ZIP=0"
set "TOR_RUNNING=0"

:: Create necessary directories if they don't exist
if not exist "%TOR_DIR%" mkdir "%TOR_DIR%"
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"

:: Check if required tools are available
where curl >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "HAS_CURL=1"
    echo Curl is already installed.
) else (
    echo Curl not found. Will download during setup.
)

where 7z >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "HAS_7ZIP=1"
    echo 7-Zip is already installed.
) else (
    echo 7-Zip not found. Will download during setup.
)

:: Function to download and install missing tools
:setup_tools
if %HAS_CURL% EQU 0 (
    echo Downloading curl...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('%CURL_URL%', '%DOWNLOAD_DIR%\%CURL_FILE%')"
    
    echo Extracting curl...
    powershell -Command "Expand-Archive -Path '%DOWNLOAD_DIR%\%CURL_FILE%' -DestinationPath '%DOWNLOAD_DIR%\curl' -Force"
    set "PATH=%PATH%;%DOWNLOAD_DIR%\curl\bin"
    set "HAS_CURL=1"
)

if %HAS_7ZIP% EQU 0 (
    echo Downloading 7-Zip...
    curl -L -o "%DOWNLOAD_DIR%\%7ZIP_FILE%" "%7ZIP_URL%"
    
    echo Installing 7-Zip...
    "%DOWNLOAD_DIR%\%7ZIP_FILE%" /S
    set "PATH=%PATH%;C:\Program Files\7-Zip"
    set "HAS_7ZIP=1"
)

:: Check if Tor is already installed
:check_tor
if not exist "%TOR_EXE%" (
    echo Tor is not installed. Starting installation...
    goto install_tor
) else (
    echo Tor is already installed.
    goto main_menu
)

:: Function to download and install Tor
:install_tor
echo Downloading Tor Expert Bundle...
curl -L -o "%DOWNLOAD_DIR%\%TOR_EXPERT_BUNDLE_FILE%" "%TOR_EXPERT_BUNDLE_URL%"

echo Extracting Tor...
cd "%DOWNLOAD_DIR%"
7z x "%TOR_EXPERT_BUNDLE_FILE%" -o"%DOWNLOAD_DIR%\tor_temp"

echo Moving Tor files to installation directory...
xcopy "%DOWNLOAD_DIR%\tor_temp\*" "%TOR_DIR%\" /E /I /H /Y

echo Creating default torrc configuration...
if not exist "%TORRC_FILE%" (
    echo # Default torrc configuration file > "%TORRC_FILE%"
    echo DataDirectory %TOR_DIR%\Data\Tor >> "%TORRC_FILE%"
    echo GeoIPFile %TOR_DIR%\Data\Tor\geoip >> "%TORRC_FILE%"
    echo GeoIPv6File %TOR_DIR%\Data\Tor\geoip6 >> "%TORRC_FILE%"
    echo Log notice file %TOR_DIR%\Data\Tor\tor-log.txt >> "%TORRC_FILE%"
    echo ControlPort 9051 >> "%TORRC_FILE%"
    echo CookieAuthentication 1 >> "%TORRC_FILE%"
)

echo Tor has been successfully installed!
goto main_menu

:: Main Menu
:main_menu
cls
echo ===================================================
echo            ULTIMATE TOR TOOL v1.0
echo ===================================================
echo.
call :check_tor_status
echo.
echo   [1] Start Tor
echo   [2] Stop Tor
echo   [3] Restart Tor (New Identity)
echo   [4] Check Tor Connection
echo   [5] View Tor Status and Information
echo   [6] Configure Tor Settings
echo   [7] Check for Updates
echo   [8] Backup Configuration
echo   [9] Setup as Windows Service
echo   [0] Exit
echo.
echo ===================================================
set /p choice="Select an option: "

if "%choice%"=="1" goto start_tor
if "%choice%"=="2" goto stop_tor
if "%choice%"=="3" goto restart_tor
if "%choice%"=="4" goto check_connection
if "%choice%"=="5" goto view_status
if "%choice%"=="6" goto configure_tor
if "%choice%"=="7" goto check_updates
if "%choice%"=="8" goto backup_config
if "%choice%"=="9" goto setup_service
if "%choice%"=="0" goto exit_script
goto main_menu

:: Check if Tor is running
:check_tor_status
set "TOR_RUNNING=0"
tasklist /FI "IMAGENAME eq tor.exe" | find /i "tor.exe" >nul
if %ERRORLEVEL% EQU 0 (
    echo   STATUS: Tor is RUNNING
    set "TOR_RUNNING=1"
) else (
    echo   STATUS: Tor is NOT RUNNING
)
goto :eof

:: Start Tor
:start_tor
cls
echo ===================================================
echo                  STARTING TOR
echo ===================================================
echo.

if %TOR_RUNNING% EQU 1 (
    echo Tor is already running!
) else (
    echo Starting Tor...
    start "" /B "%TOR_EXE%" -f "%TORRC_FILE%"
    timeout /t 5 /nobreak >nul
    
    tasklist /FI "IMAGENAME eq tor.exe" | find /i "tor.exe" >nul
    if %ERRORLEVEL% EQU 0 (
        echo Tor has been successfully started!
        set "TOR_RUNNING=1"
    ) else (
        echo Failed to start Tor. Check the logs for more information.
    )
)

echo.
pause
goto main_menu

:: Stop Tor
:stop_tor
cls
echo ===================================================
echo                  STOPPING TOR
echo ===================================================
echo.

if %TOR_RUNNING% EQU 0 (
    echo Tor is not running!
) else (
    echo Stopping Tor...
    taskkill /IM tor.exe /F >nul 2>&1
    
    if %ERRORLEVEL% EQU 0 (
        echo Tor has been successfully stopped!
        set "TOR_RUNNING=0"
    ) else (
        echo Failed to stop Tor. It might require manual intervention.
    )
)

echo.
pause
goto main_menu

:: Restart Tor (get new identity)
:restart_tor
cls
echo ===================================================
echo           RESTARTING TOR (NEW IDENTITY)
echo ===================================================
echo.

if %TOR_RUNNING% EQU 1 (
    echo Stopping Tor...
    taskkill /IM tor.exe /F >nul 2>&1
    timeout /t 2 /nobreak >nul
)

echo Starting Tor with a new identity...
start "" /B "%TOR_EXE%" -f "%TORRC_FILE%"
timeout /t 5 /nobreak >nul

tasklist /FI "IMAGENAME eq tor.exe" | find /i "tor.exe" >nul
if %ERRORLEVEL% EQU 0 (
    echo Tor has been successfully restarted with a new identity!
    set "TOR_RUNNING=1"
) else (
    echo Failed to restart Tor. Check the logs for more information.
)

echo.
pause
goto main_menu

:: Check Tor Connection
:check_connection
cls
echo ===================================================
echo               CHECK TOR CONNECTION
echo ===================================================
echo.

if %TOR_RUNNING% EQU 0 (
    echo Tor is not running! Please start Tor first.
    echo.
    pause
    goto main_menu
)

echo Checking Tor connection...
echo.

:: Set up a temporary SOCKS proxy config for curl
set "CURL_SOCKS_CONF=%TEMP%\curl-torrc"
echo proxy=socks5h://localhost:9050 > "%CURL_SOCKS_CONF%"

:: Check if we can connect to the Tor check service
curl --config "%CURL_SOCKS_CONF%" --connect-timeout 30 -s https://check.torproject.org/ | findstr /C:"Congratulations" >nul

if %ERRORLEVEL% EQU 0 (
    echo SUCCESS: Connected to Tor network!
    echo.
    
    echo Fetching your Tor exit node information...
    echo.
    curl --config "%CURL_SOCKS_CONF%" -s https://check.torproject.org/api/ip
    echo.
) else (
    echo FAILED: Could not connect to Tor network!
    echo.
    echo Possible reasons:
    echo - Tor is not configured correctly
    echo - Network issues
    echo - The check.torproject.org site might be down
)

:: Clean up
del "%CURL_SOCKS_CONF%" >nul 2>&1

echo.
pause
goto main_menu

:: View Tor Status
:view_status
cls
echo ===================================================
echo             TOR STATUS AND INFORMATION
echo ===================================================
echo.

if %TOR_RUNNING% EQU 0 (
    echo Tor is not running! Please start Tor first.
    echo.
    pause
    goto main_menu
)

echo Tor Process Information:
echo -----------------------
tasklist /FI "IMAGENAME eq tor.exe" /FO LIST | findstr /V "MEMUSAGE"
echo.

echo Tor Configuration:
echo -----------------
type "%TORRC_FILE%"
echo.

echo Tor Log (last 10 entries):
echo -------------------------
if exist "%TOR_DIR%\Data\Tor\tor-log.txt" (
    powershell -Command "Get-Content '%TOR_DIR%\Data\Tor\tor-log.txt' -Tail 10"
) else (
    echo No log file found.
)

echo.
echo Network Connections:
echo ------------------
netstat -ano | findstr ":9050 :9051"
echo.

pause
goto main_menu

:: Configure Tor Settings
:configure_tor
cls
echo ===================================================
echo               CONFIGURE TOR SETTINGS
echo ===================================================
echo.

echo Current Configuration:
echo --------------------
type "%TORRC_FILE%"
echo.
echo.

echo Configuration Options:
echo --------------------
echo [1] Use Bridges (Censorship Circumvention)
echo [2] Change Control Port
echo [3] Enable/Disable Exit Node
echo [4] Set Specific Country Exit Nodes
echo [5] Edit torrc file directly
echo [B] Back to Main Menu
echo.
set /p config_choice="Select an option: "

if /i "%config_choice%"=="1" goto config_bridges
if /i "%config_choice%"=="2" goto config_control_port
if /i "%config_choice%"=="3" goto config_exit_node
if /i "%config_choice%"=="4" goto config_country_exit
if /i "%config_choice%"=="5" goto edit_torrc
if /i "%config_choice%"=="B" goto main_menu
goto configure_tor

:config_bridges
cls
echo ===================================================
echo              CONFIGURE BRIDGES
echo ===================================================
echo.
echo This will configure Tor to use bridges to circumvent censorship.
echo You'll need bridge addresses which you can get from https://bridges.torproject.org/
echo.
echo [1] Use obfs4 bridges
echo [2] Use snowflake bridges
echo [3] Remove all bridges
echo [B] Back to configuration menu
echo.
set /p bridge_choice="Select an option: "

if /i "%bridge_choice%"=="1" (
    echo Add one or more obfs4 bridges below (press Enter on a blank line to finish):
    echo.
    
    set "bridges="
    :bridge_input_loop
    set /p bridge_line=""
    if not "!bridge_line!"=="" (
        set "bridges=!bridges!Bridge obfs4 !bridge_line!"
        goto bridge_input_loop
    )
    
    :: Update torrc with bridges
    powershell -Command "(Get-Content '%TORRC_FILE%') | Where-Object { $_ -notmatch '^Bridge ' -and $_ -notmatch '^UseBridges ' -and $_ -notmatch '^ClientTransportPlugin ' } | Set-Content '%TORRC_FILE%'"
    echo UseBridges 1 >> "%TORRC_FILE%"
    echo ClientTransportPlugin obfs4 exec %TOR_DIR%\Tor\PluggableTransports\obfs4proxy.exe >> "%TORRC_FILE%"
    echo !bridges! >> "%TORRC_FILE%"
    
    echo Bridges have been configured successfully!
    
) else if /i "%bridge_choice%"=="2" (
    :: Update torrc with snowflake
    powershell -Command "(Get-Content '%TORRC_FILE%') | Where-Object { $_ -notmatch '^Bridge ' -and $_ -notmatch '^UseBridges ' -and $_ -notmatch '^ClientTransportPlugin ' } | Set-Content '%TORRC_FILE%'"
    echo UseBridges 1 >> "%TORRC_FILE%"
    echo ClientTransportPlugin snowflake exec %TOR_DIR%\Tor\PluggableTransports\snowflake-client.exe >> "%TORRC_FILE%"
    echo Bridge snowflake 192.0.2.3:1 2B280B23E1107BB62ABFC40DDCC8824814F80A72 fingerprint=2B280B23E1107BB62ABFC40DDCC8824814F80A72 url=https://snowflake-broker.torproject.net.global.prod.fastly.net/ front=cdn.sstatic.net ice=stun:stun.l.google.com:19302,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478 >> "%TORRC_FILE%"
    
    echo Snowflake bridge has been configured!
    
) else if /i "%bridge_choice%"=="3" (
    :: Remove all bridge configurations
    powershell -Command "(Get-Content '%TORRC_FILE%') | Where-Object { $_ -notmatch '^Bridge ' -and $_ -notmatch '^UseBridges ' -and $_ -notmatch '^ClientTransportPlugin ' } | Set-Content '%TORRC_FILE%'"
    echo Bridges have been removed from configuration!
    
) else if /i "%bridge_choice%"=="B" (
    goto configure_tor
)

echo.
pause
goto configure_tor

:config_control_port
cls
echo ===================================================
echo              CHANGE CONTROL PORT
echo ===================================================
echo.
echo Current control port settings:
findstr /C:"ControlPort" "%TORRC_FILE%"
echo.
echo Enter new control port (default is 9051):
set /p new_port="Port: "

if "%new_port%"=="" set "new_port=9051"

:: Update the control port in torrc
powershell -Command "(Get-Content '%TORRC_FILE%') | ForEach-Object { $_ -replace '^ControlPort.*', 'ControlPort %new_port%' } | Set-Content '%TORRC_FILE%'"

:: Check if the setting exists, if not add it
findstr /C:"ControlPort" "%TORRC_FILE%" >nul
if %ERRORLEVEL% NEQ 0 (
    echo ControlPort %new_port% >> "%TORRC_FILE%"
)

echo Control port has been updated to %new_port%!
echo.
pause
goto configure_tor

:config_exit_node
cls
echo ===================================================
echo           ENABLE/DISABLE EXIT NODE
echo ===================================================
echo.
echo WARNING: Running an exit node can expose you to legal risks!
echo Only enable this if you understand the implications.
echo.
echo [1] Enable Exit Node
echo [2] Disable Exit Node (default)
echo [B] Back to configuration menu
echo.
set /p exit_choice="Select an option: "

if /i "%exit_choice%"=="1" (
    :: Remove existing ExitPolicy lines
    powershell -Command "(Get-Content '%TORRC_FILE%') | Where-Object { $_ -notmatch '^ExitPolicy ' } | Set-Content '%TORRC_FILE%'"
    
    :: Add Exit Node configuration
    echo ExitPolicy accept *:* >> "%TORRC_FILE%"
    echo ExitRelay 1 >> "%TORRC_FILE%"
    
    echo Exit node has been ENABLED!
    echo Please ensure you understand the legal implications in your country.
    
) else if /i "%exit_choice%"=="2" (
    :: Remove existing ExitPolicy lines
    powershell -Command "(Get-Content '%TORRC_FILE%') | Where-Object { $_ -notmatch '^ExitPolicy ' -and $_ -notmatch '^ExitRelay ' } | Set-Content '%TORRC_FILE%'"
    
    :: Add non-exit configuration
    echo ExitPolicy reject *:* >> "%TORRC_FILE%"
    echo ExitRelay 0 >> "%TORRC_FILE%"
    
    echo Exit node has been DISABLED!
    
) else if /i "%exit_choice%"=="B" (
    goto configure_tor
)

echo.
pause
goto configure_tor

:config_country_exit
cls
echo ===================================================
echo         SET SPECIFIC COUNTRY EXIT NODES
echo ===================================================
echo.
echo This will configure Tor to use exit nodes from specific countries.
echo Enter two-letter country codes separated by commas (e.g., US,GB,DE)
echo Or type "CLEAR" to remove country restrictions.
echo.
set /p countries="Country codes: "

if /i "%countries%"=="CLEAR" (
    :: Remove existing ExitNodes configuration
    powershell -Command "(Get-Content '%TORRC_FILE%') | Where-Object { $_ -notmatch '^ExitNodes ' -and $_ -notmatch '^StrictNodes ' } | Set-Content '%TORRC_FILE%'"
    echo Country exit node restrictions have been removed!
) else if not "%countries%"=="" (
    :: Remove existing ExitNodes configuration
    powershell -Command "(Get-Content '%TORRC_FILE%') | Where-Object { $_ -notmatch '^ExitNodes ' -and $_ -notmatch '^StrictNodes ' } | Set-Content '%TORRC_FILE%'"
    
    :: Add new country configurations
    echo ExitNodes {%countries%} >> "%TORRC_FILE%"
    echo StrictNodes 1 >> "%TORRC_FILE%"
    
    echo Exit nodes have been restricted to the following countries: %countries%
)

echo.
pause
goto configure_tor

:edit_torrc
cls
echo ===================================================
echo               EDIT TORRC FILE DIRECTLY
echo ===================================================
echo.
echo Opening torrc file in Notepad...
start notepad "%TORRC_FILE%"
echo.
echo After saving and closing Notepad, press any key to continue.
pause >nul
goto configure_tor

:: Check for Updates
:check_updates
cls
echo ===================================================
echo               CHECK FOR UPDATES
echo ===================================================
echo.

echo Checking for updates to Tor Expert Bundle...
curl -s -L -o "%TEMP%\tor_versions.html" "https://dist.torproject.org/torbrowser/"

for /F "tokens=*" %%a in ('powershell -Command "(Get-Content '%TEMP%\tor_versions.html' | Select-String -Pattern '<a href=\"[0-9]+\.[0-9]+\.[0-9]+/\">' | ForEach-Object { $_ -replace '<a href=\"([0-9]+\.[0-9]+\.[0-9]+)/\".*', '$1' } | Sort-Object -Descending)[0]"') do set "LATEST_VERSION=%%a"

echo Current version: 13.0.4
echo Latest version: %LATEST_VERSION%

if "%LATEST_VERSION%"=="13.0.4" (
    echo You have the latest version of Tor!
) else (
    echo A new version is available!
    echo.
    echo [1] Download and install the latest version
    echo [2] Skip update
    echo.
    set /p update_choice="Select an option: "
    
    if "%update_choice%"=="1" (
        echo Stopping Tor...
        taskkill /IM tor.exe /F >nul 2>&1
        
        echo Downloading Tor Expert Bundle version %LATEST_VERSION%...
        set "NEW_TOR_URL=https://dist.torproject.org/torbrowser/%LATEST_VERSION%/tor-expert-bundle-%LATEST_VERSION%-windows-x86_64.tar.gz"
        curl -L -o "%DOWNLOAD_DIR%\tor-expert-bundle-new.tar.gz" "%NEW_TOR_URL%"
        
        echo Backing up current configuration...
        copy "%TORRC_FILE%" "%TORRC_FILE%.backup"
        
        echo Extracting new version...
        7z x "%DOWNLOAD_DIR%\tor-expert-bundle-new.tar.gz" -o"%DOWNLOAD_DIR%\tor_temp"
        7z x "%DOWNLOAD_DIR%\tor_temp\tor-expert-bundle-new.tar" -o"%DOWNLOAD_DIR%\tor_extract"
        
        echo Installing new version...
        xcopy "%DOWNLOAD_DIR%\tor_extract\*" "%TOR_DIR%\" /E /I /H /Y
        
        echo Restoring configuration...
        copy "%TORRC_FILE%.backup" "%TORRC_FILE%"
        
        echo Cleaning up...
        rmdir /S /Q "%DOWNLOAD_DIR%\tor_temp"
        rmdir /S /Q "%DOWNLOAD_DIR%\tor_extract"
        
        echo Update completed successfully!
    )
)

echo.
pause
goto main_menu

:: Backup Configuration
:backup_config
cls
echo ===================================================
echo               BACKUP CONFIGURATION
echo ===================================================
echo.

echo [1] Create Backup
echo [2] Restore from Backup
echo [B] Back to Main Menu
echo.
set /p backup_choice="Select an option: "

if "%backup_choice%"=="1" (
    set "BACKUP_FILE=%SCRIPT_DIR%tor_backup_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%.zip"
    set "BACKUP_FILE=%BACKUP_FILE: =0%"
    
    echo Creating backup to %BACKUP_FILE%...
    
    if %TOR_RUNNING% EQU 1 (
        echo Stopping Tor temporarily...
        taskkill /IM tor.exe /F >nul 2>&1
        timeout /t 2 /nobreak >nul
    )
    
    7z a "%BACKUP_FILE%" "%TOR_DIR%\Data\Tor\*"
    
    if %TOR_RUNNING% EQU 1 (
        echo Restarting Tor...
        start "" /B "%TOR_EXE%" -f "%TORRC_FILE%"
    )
    
    echo Backup completed successfully!
    
) else if "%backup_choice%"=="2" (
    echo Available backups:
    echo.
    dir /B "%SCRIPT_DIR%tor_backup_*.zip"
    echo.
    echo Enter the backup filename to restore:
    set /p restore_file=""
    
    if exist "%SCRIPT_DIR%%restore_file%" (
        if %TOR_RUNNING% EQU 1 (
            echo Stopping Tor temporarily...
            taskkill /IM tor.exe /F >nul 2>&1
            timeout /t 2 /nobreak >nul
        )
        
        echo Restoring from backup...
        7z x "%SCRIPT_DIR%%restore_file%" -o"%TOR_DIR%\Data" -y
        
        if %TOR_RUNNING% EQU 1 (
            echo Restarting Tor...
            start "" /B "%TOR_EXE%" -f "%TORRC_FILE%"
        )
        
        echo Restore completed successfully!
    ) else (
        echo Backup file not found!
    )
) else if /i "%backup_choice%"=="B" (
    goto main_menu
)

echo.
pause
goto main_menu

:: Setup Tor as Windows Service
:setup_service
cls
echo ===================================================
echo             SETUP TOR AS WINDOWS SERVICE
echo ===================================================
echo.

sc query %TOR_SERVICE_NAME% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Tor is already installed as a service.
    echo.
    echo [1] Remove Tor service
    echo [2] Restart Tor service
    echo [B] Back to Main Menu
    echo.
    set /p service_choice="Select an option: "
    
    if "%service_choice%"=="1" (
        echo Stopping and removing Tor service...
        sc stop %TOR_SERVICE_NAME% >nul 2>&1
        sc delete %TOR_SERVICE_NAME% >nul 2>&1
        echo Tor service has been removed!
    ) else if "%service_choice%"=="2" (
        echo Restarting Tor service...
        sc stop %TOR_SERVICE_NAME% >nul 2>&1
        timeout /t 2 /nobreak >nul
        sc start %TOR_SERVICE_NAME% >nul 2>&1
        echo Tor service has been restarted!
    ) else if /i "%service_choice%"=="B" (
        goto main_menu
    )
) else (
    echo Installing Tor as a Windows service...
    
    :: Create a service wrapper batch file
    echo @echo off > "%TOR_DIR%\tor_service.bat"
    echo cd /D "%TOR_DIR%" >> "%TOR_DIR%\tor_service.bat"
    echo start /B "Tor Service" "%TOR_EXE%" -f "%TORRC_FILE%" >> "%TOR_DIR%\tor_service.bat"
    
    :: Download NSSM (Non-Sucking Service Manager) if not present
    if not exist "%DOWNLOAD_DIR%\nssm.exe" (
        echo Downloading NSSM service manager...
        curl -L -o "%DOWNLOAD_DIR%\nssm.zip" "https://nssm.cc/release/nssm-2.24.zip"
        7z e "%DOWNLOAD_DIR%\nssm.zip" -o"%DOWNLOAD_DIR%" "*/win64/nssm.exe" -r
    )
    
    :: Install service using NSSM
    echo Installing service with NSSM...
    "%DOWNLOAD_DIR%\nssm.exe" install %TOR_SERVICE_NAME% "%TOR_DIR%\tor_service.bat"
    "%DOWNLOAD_DIR%\nssm.exe" set %TOR_SERVICE_NAME% DisplayName "Tor Anonymity Service"
    "%DOWNLOAD_DIR%\nssm.exe" set %TOR_SERVICE_NAME% Description "Provides Tor anonymity network connectivity"
    "%DOWNLOAD_DIR%\nssm.exe" set %TOR_SERVICE_NAME% Start SERVICE_AUTO_START
    
    :: Start the service
    echo Starting Tor service...
    sc start %TOR_SERVICE_NAME% >nul 2>&1
    
    echo Tor has been installed as a Windows service!
)

echo.
pause
goto main_menu

:: Exit the script
:exit_script
cls
echo ===================================================
echo           EXITING ULTIMATE TOR TOOL
echo ===================================================
echo.

if %TOR_RUNNING% EQU 1 (
    echo Tor is still running. Do you want to stop it before exiting?
    echo [Y] Yes
    echo [N] No, leave it running
    echo.
    set /p exit_choice="Select an option: "
    
    if /i "%exit_choice%"=="Y" (
        echo Stopping Tor...
        taskkill /IM tor.exe /F >nul 2>&1
        echo Tor has been stopped.
    ) else (
        echo Tor will continue running in the background.
    )
)

echo Thank you for using Ultimate Tor Tool!
echo.
pause
exit /b 0
