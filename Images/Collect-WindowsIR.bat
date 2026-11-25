@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Collect-WindowsIR.bat
rem Purpose: Windows incident response triage collection
rem Behavior: Read-only collection. Does not delete files, kill processes, or change settings.

set "SCRIPT_PATH=%~f0"
set "SCRIPT_DIR=%~dp0"

if "%~1"=="" (
  set "OUTPUT_ROOT=%SCRIPT_DIR%"
) else (
  set "OUTPUT_ROOT=%~1"
)

if "%~2"=="" (
  set "TOOL_ROOT=C:\IR\Tools\Sysinternals"
) else (
  set "TOOL_ROOT=%~2"
)

for %%I in ("%OUTPUT_ROOT%") do set "OUTPUT_ROOT=%%~fI"
for %%I in ("%TOOL_ROOT%") do set "TOOL_ROOT=%%~fI"
if "%OUTPUT_ROOT:~-1%"=="\" (
  if not "%OUTPUT_ROOT:~-2%"==":\" set "OUTPUT_ROOT=%OUTPUT_ROOT:~0,-1%"
)

if not exist "%TOOL_ROOT%\autorunsc64.exe" (
  if exist "%SCRIPT_DIR%Tools\Sysinternals\autorunsc64.exe" (
    set "TOOL_ROOT=%SCRIPT_DIR%Tools\Sysinternals"
  )
)
if not exist "%TOOL_ROOT%\autorunsc64.exe" (
  if exist "%SCRIPT_DIR%autorunsc64.exe" (
    set "TOOL_ROOT=%SCRIPT_DIR%"
  )
)
for %%I in ("%TOOL_ROOT%") do set "TOOL_ROOT=%%~fI"

net session >nul 2>&1
if not "%ERRORLEVEL%"=="0" (
  echo [!] Administrator privilege is required. Requesting UAC elevation...
  set "ELEVATE_CMD=%TEMP%\Collect-WindowsIR-elevate-%RANDOM%%RANDOM%.cmd"
  (
    echo @echo off
    echo cd /d "%OUTPUT_ROOT%"
    echo call "%SCRIPT_PATH%" "%OUTPUT_ROOT%" "%TOOL_ROOT%"
    echo del "%%~f0" ^>nul 2^>nul
  ) > "%ELEVATE_CMD%"
  mshta "vbscript:CreateObject(""Shell.Application"").ShellExecute(""%ELEVATE_CMD%"","""",""%OUTPUT_ROOT%"",""runas"",1)(window.close)"
  exit /b
)

pushd "%OUTPUT_ROOT%"

for /f %%I in ('wmic os get LocalDateTime ^| find "."') do set "LDT=%%I"
set "TS=%LDT:~0,8%_%LDT:~8,6%"
set "HOST=%COMPUTERNAME%"
set "OUT=%OUTPUT_ROOT%\IR_%HOST%_%TS%"
set "ERROR_LOG=%OUT%\errors.log"
set "RUN_LOG=%OUT%\00_collection_info\run_log.txt"

for %%D in (
  "00_collection_info"
  "01_system"
  "02_process"
  "03_network"
  "04_services"
  "05_persistence"
  "06_users"
  "07_artifacts"
  "08_logs"
  "09_files"
  "10_external_tools"
  "hashes"
) do mkdir "%OUT%\%%~D" 2>nul

type nul > "%ERROR_LOG%"
call :Log "Output directory: %OUT%"

rem 00. Collection info
(
  echo Collection started: %DATE% %TIME%
  echo Hostname: %COMPUTERNAME%
  echo User: %USERNAME%
  echo Working directory: %CD%
  echo Script path: %SCRIPT_PATH%
  echo Output root: %OUTPUT_ROOT%
  echo Output directory: %OUT%
  echo Tool root: %TOOL_ROOT%
  echo OS version:
  ver
  echo.
  echo whoami:
  whoami
  echo.
  echo whoami /all:
  whoami /all
) > "%OUT%\00_collection_info\collection_info.txt" 2>> "%ERROR_LOG%"

call :RunStep "00_collection_info\date_time.txt" "date /t && time /t"
call :RunStep "00_collection_info\whoami_all.txt" "whoami /all"

rem 01. System
call :RunStep "01_system\systeminfo.txt" "systeminfo"
call :RunStep "01_system\os_wmic.txt" "wmic os get Caption,Version,BuildNumber,OSArchitecture,InstallDate,LastBootUpTime /format:list"
call :RunStep "01_system\hotfix.txt" "wmic qfe get HotFixID,Description,InstalledBy,InstalledOn"
call :RunStep "01_system\environment.txt" "set"
call :RunStep "01_system\logical_disks.txt" "wmic logicaldisk get DeviceID,DriveType,FileSystem,FreeSpace,Size,VolumeName"

rem 02. Process
call :RunStep "02_process\tasklist_verbose.txt" "tasklist /v"
call :RunStep "02_process\process_cmdline.csv" "wmic process get ProcessId,ParentProcessId,Name,ExecutablePath,CommandLine,CreationDate /format:csv"

rem 03. Network
call :RunStep "03_network\netstat_ano.txt" "netstat -ano"
call :RunStep "03_network\ipconfig_all.txt" "ipconfig /all"
call :RunStep "03_network\route_print.txt" "route print"
call :RunStep "03_network\dns_cache.txt" "ipconfig /displaydns"
call :RunStep "03_network\firewall_profiles.txt" "netsh advfirewall show allprofiles"
call :RunStep "03_network\winhttp_proxy.txt" "netsh winhttp show proxy"

rem 04. Services
call :RunStep "04_services\sc_query_all.txt" "sc.exe query state= all"
call :RunStep "04_services\services.csv" "wmic service get Name,DisplayName,State,StartMode,StartName,PathName /format:csv"
call :RunStep "04_services\drivers.txt" "driverquery /v"

rem 05. Persistence
call :RunStep "05_persistence\scheduled_tasks.txt" "schtasks /query /fo LIST /v"
call :RunStep "05_persistence\hklm_run.txt" "reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run /s"
call :RunStep "05_persistence\hkcu_run.txt" "reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run /s"
call :RunStep "05_persistence\runonce.txt" "reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce /s && reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce /s"
call :Log "START 05_persistence\winlogon.txt"
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" > "%OUT%\05_persistence\winlogon.txt" 2>> "%ERROR_LOG%"
if errorlevel 1 (call :Log "WARN  05_persistence\winlogon.txt") else (call :Log "DONE  05_persistence\winlogon.txt")
call :Log "START 05_persistence\startup_folders.txt"
(
  echo ==== User Startup ====
  if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" (
    dir /a /s "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
  ) else (
    echo NOT_FOUND: %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
  )
  echo.
  echo ==== Common Startup ====
  if exist "%ProgramData%\Microsoft\Windows\Start Menu\Programs\StartUp" (
    dir /a /s "%ProgramData%\Microsoft\Windows\Start Menu\Programs\StartUp"
  ) else (
    echo NOT_FOUND: %ProgramData%\Microsoft\Windows\Start Menu\Programs\StartUp
  )
) > "%OUT%\05_persistence\startup_folders.txt" 2>> "%ERROR_LOG%"
call :Log "DONE  05_persistence\startup_folders.txt"
call :RunStep "05_persistence\wmi_event_filters.txt" "wmic /namespace:\\root\subscription PATH __EventFilter get Name,Query /format:list"
call :Log "START 05_persistence\wmi_consumers.txt"
wmic /namespace:\\root\subscription PATH CommandLineEventConsumer get Name,CommandLineTemplate /format:list > "%OUT%\05_persistence\wmi_consumers.txt" 2>&1
call :Log "DONE  05_persistence\wmi_consumers.txt"
call :RunStep "05_persistence\wmi_bindings.txt" "wmic /namespace:\\root\subscription PATH __FilterToConsumerBinding get Filter,Consumer /format:list"

rem 06. Users
call :RunStep "06_users\local_users.txt" "net user"
call :RunStep "06_users\local_groups.txt" "net localgroup"
call :RunStep "06_users\administrators.txt" "net localgroup administrators"
call :Log "START 06_users\logged_on_users.txt"
query user > "%OUT%\06_users\logged_on_users.txt" 2>> "%ERROR_LOG%"
if errorlevel 1 (
  quser > "%OUT%\06_users\logged_on_users.txt" 2>> "%ERROR_LOG%"
)
call :Log "DONE  06_users\logged_on_users.txt"

rem 07. Artifacts
call :RunStep "07_artifacts\artifact_paths.txt" "dir /a ""%SystemRoot%\Prefetch"" && dir /a ""%SystemRoot%\AppCompat\Programs\Amcache.hve"" && dir /a ""%APPDATA%\Microsoft\Windows\Recent"""
(
  echo AmCache path: %SystemRoot%\AppCompat\Programs\Amcache.hve
  if exist "%SystemRoot%\AppCompat\Programs\Amcache.hve" (
    echo Exists: True
    dir /a "%SystemRoot%\AppCompat\Programs\Amcache.hve"
  ) else (
    echo Exists: False
  )
  echo.
  echo Live collection note:
  echo Amcache.hve can be locked on a running system.
  echo If live copy fails, collect it from an offline image or a Volume Shadow Copy.
) > "%OUT%\07_artifacts\amcache_live_collection_note.txt" 2>> "%ERROR_LOG%"

call :RunStep "07_artifacts\prefetch_listing.txt" "dir /a ""%SystemRoot%\Prefetch"""
call :RunStep "07_artifacts\recent_lnk_listing.txt" "dir /a ""%APPDATA%\Microsoft\Windows\Recent\*.lnk"""
call :CopyPath "%APPDATA%\Microsoft\Windows\Recent" "%OUT%\07_artifacts\Recent"
call :CopyPath "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations" "%OUT%\07_artifacts\JumpLists\AutomaticDestinations"
call :CopyPath "%APPDATA%\Microsoft\Windows\Recent\CustomDestinations" "%OUT%\07_artifacts\JumpLists\CustomDestinations"

rem 08. Logs
call :RunStep "08_logs\system_recent.txt" "wevtutil qe System /c:500 /rd:true /f:text"
call :RunStep "08_logs\security_recent.txt" "wevtutil qe Security /c:500 /rd:true /f:text"
call :RunStep "08_logs\powershell_operational_recent.txt" "wevtutil qe Microsoft-Windows-PowerShell/Operational /c:500 /rd:true /f:text"
call :Log "START 08_logs\task_scheduler_recent.txt"
wevtutil qe Microsoft-Windows-TaskScheduler/Operational /c:500 /rd:true /f:text > "%OUT%\08_logs\task_scheduler_recent.txt" 2>&1
call :Log "DONE  08_logs\task_scheduler_recent.txt"
call :Log "START 08_logs\System.evtx"
wevtutil epl System "%OUT%\08_logs\System.evtx" 2>> "%ERROR_LOG%"
if errorlevel 1 (call :Log "WARN  08_logs\System.evtx") else (call :Log "DONE  08_logs\System.evtx")
call :Log "START 08_logs\Security.evtx"
wevtutil epl Security "%OUT%\08_logs\Security.evtx" 2>> "%ERROR_LOG%"
if errorlevel 1 (call :Log "WARN  08_logs\Security.evtx") else (call :Log "DONE  08_logs\Security.evtx")
call :Log "START 08_logs\PowerShell_Operational.evtx"
wevtutil epl Microsoft-Windows-PowerShell/Operational "%OUT%\08_logs\PowerShell_Operational.evtx" 2>> "%ERROR_LOG%"
if errorlevel 1 (call :Log "WARN  08_logs\PowerShell_Operational.evtx") else (call :Log "DONE  08_logs\PowerShell_Operational.evtx")

rem 09. Files
call :Log "START 09_files\recent_user_files_7d.txt"
robocopy "%USERPROFILE%" "%OUT%\09_files\_robocopy_null" *.* /L /S /FP /BYTES /TS /XJ /R:0 /W:0 /MAXAGE:7 /XD "%OUTPUT_ROOT%\IR_*" > "%OUT%\09_files\recent_user_files_7d.txt" 2>> "%ERROR_LOG%"
call :Log "DONE  09_files\recent_user_files_7d.txt"

call :Log "START 09_files\suspicious_extensions.txt"
(
  for %%R in ("%USERPROFILE%" "%PUBLIC%" "%ProgramData%" "%TEMP%" "%SystemRoot%\Temp") do (
    if exist "%%~R" (
      echo ==== Root: %%~R ====
      for %%E in (exe dll ps1 bat cmd vbs js) do (
        echo ---- *.%%E ----
        robocopy "%%~R" "%OUT%\09_files\_robocopy_null" *.%%E /L /S /FP /XJ /R:0 /W:0 /NJH /NJS /NDL /NP
      )
    ) else (
      echo ==== Root: %%~R ====
      echo NOT_FOUND
    )
  )
) > "%OUT%\09_files\suspicious_extensions.txt" 2>> "%ERROR_LOG%"
call :Log "DONE  09_files\suspicious_extensions.txt"

rem 10. External tools
call :Log "START 10_external_tools\tool_root_status.txt"
(
  echo Tool root: %TOOL_ROOT%
  if exist "%TOOL_ROOT%\" (
    echo Exists: True
  ) else (
    echo Exists: False
  )
) > "%OUT%\10_external_tools\tool_root_status.txt" 2>> "%ERROR_LOG%"
call :Log "DONE  10_external_tools\tool_root_status.txt"

call :Log "START 10_external_tools\tool_inventory.txt"
if exist "%TOOL_ROOT%\" (
  dir /a:-d "%TOOL_ROOT%" > "%OUT%\10_external_tools\tool_inventory.txt" 2>> "%ERROR_LOG%"
) else (
  echo TOOL_NOT_FOUND: %TOOL_ROOT% > "%OUT%\10_external_tools\tool_inventory.txt"
  echo [%DATE% %TIME%] TOOL_ROOT_NOT_FOUND %TOOL_ROOT%>> "%ERROR_LOG%"
)
call :Log "DONE  10_external_tools\tool_inventory.txt"

call :Log "START 10_external_tools\tool_hashes.txt"
if exist "%TOOL_ROOT%\" (
  for %%T in ("%TOOL_ROOT%\*.exe") do (
    echo Path: %%~fT>> "%OUT%\10_external_tools\tool_hashes.txt"
    certutil -hashfile "%%~fT" SHA256 >> "%OUT%\10_external_tools\tool_hashes.txt" 2>> "%ERROR_LOG%"
    echo(>> "%OUT%\10_external_tools\tool_hashes.txt"
  )
) else (
  echo TOOL_NOT_FOUND: %TOOL_ROOT% > "%OUT%\10_external_tools\tool_hashes.txt"
)
call :Log "DONE  10_external_tools\tool_hashes.txt"

call :RunTool "tcpvcon64.exe" "10_external_tools\tcpvcon_all.csv" "-a -c"
call :RunTool "autorunsc64.exe" "10_external_tools\autorunsc_all.csv" "-accepteula -a * -c -h -s"
call :RunTool "autorunsc64.exe" "10_external_tools\autorunsc_non_ms.csv" "-accepteula -a * -c -h -s -m"
call :RunTool "handle64.exe" "10_external_tools\handle_all.tsv" "-accepteula -a -u -vt"
call :RunTool "handle64.exe" "10_external_tools\handle_powershell.txt" "-accepteula -p powershell"
call :RunTool "listdlls64.exe" "10_external_tools\listdlls_all_verbose.txt" "-accepteula -v"
call :RunTool "listdlls64.exe" "10_external_tools\listdlls_unsigned.txt" "-accepteula -u"
call :RunTool "psloggedon64.exe" "10_external_tools\psloggedon_all.txt" "-accepteula"
call :RunTool "psloggedon64.exe" "10_external_tools\psloggedon_local.txt" "-accepteula -l"
call :RunTool "psinfo64.exe" "10_external_tools\psinfo_detail.txt" "-accepteula -h -s -d"
call :RunTool "pslist64.exe" "10_external_tools\pslist_tree.txt" "-accepteula -t"
call :RunTool "pslist64.exe" "10_external_tools\pslist_detail.txt" "-accepteula -x"
call :RunTool "psloglist64.exe" "10_external_tools\psloglist_system_50.txt" "-accepteula -n 50 system"
call :RunTool "psloglist64.exe" "10_external_tools\psloglist_security_50.txt" "-accepteula -n 50 security"

echo Collection finished: %DATE% %TIME%>> "%OUT%\00_collection_info\collection_info.txt"
call :Log "Collection finished"

rem Hash collection outputs after collection_info.txt is finalized.
call :Log "START hashes\collection_hashes.txt"
set "HASH_FILE=%OUT%\hashes\collection_hashes.txt"
set "HASH_FAIL=%OUT%\hashes\hash_failures.txt"
set "HASH_TMP=%OUT%\hashes\_hash.tmp"
type nul > "%HASH_FILE%"
type nul > "%HASH_FAIL%"
for /r "%OUT%" %%F in (*) do (
  set "FILE_PATH=%%~fF"
  set "SKIP_HASH="
  if /i "!FILE_PATH!"=="%HASH_FILE%" set "SKIP_HASH=1"
  if /i "!FILE_PATH!"=="%HASH_FAIL%" set "SKIP_HASH=1"
  if /i "!FILE_PATH!"=="%HASH_TMP%" set "SKIP_HASH=1"
  if /i "!FILE_PATH!"=="%ERROR_LOG%" set "SKIP_HASH=1"
  if /i "!FILE_PATH!"=="%RUN_LOG%" set "SKIP_HASH=1"
  if not defined SKIP_HASH (
    >> "%HASH_FILE%" echo Path: !FILE_PATH!
    certutil -hashfile "!FILE_PATH!" SHA256 > "%HASH_TMP%" 2>&1
    if errorlevel 1 (
      >> "%HASH_FILE%" echo SHA256: HASH_FAILED
      >> "%HASH_FAIL%" echo Path: !FILE_PATH!
      type "%HASH_TMP%" >> "%HASH_FAIL%"
      >> "%HASH_FAIL%" echo(
    ) else (
      for /f "usebackq delims=" %%H in (`findstr /r "^[0-9A-Fa-f][0-9A-Fa-f]*$" "%HASH_TMP%"`) do (
        >> "%HASH_FILE%" echo SHA256: %%H
      )
    )
    >> "%HASH_FILE%" echo(
  )
)
del "%HASH_TMP%" >nul 2>nul
call :Log "DONE  hashes\collection_hashes.txt"

echo Output directory: %OUT%
exit /b 0

:RunStep
set "REL=%~1"
set "CMD=%~2"
call :Log "START %REL%"
cmd.exe /d /c "%CMD%" > "%OUT%\%REL%" 2>> "%ERROR_LOG%"
if errorlevel 1 (
  call :Log "WARN  %REL% exit=!ERRORLEVEL!"
) else (
  call :Log "DONE  %REL%"
)
exit /b 0

:RunTool
set "TOOL_EXE=%~1"
set "REL=%~2"
set "TOOL_ARGS=%~3"
set "TOOL_PATH=%TOOL_ROOT%\%TOOL_EXE%"
call :Log "START %REL%"
if not exist "%TOOL_PATH%" (
  echo TOOL_NOT_FOUND: %TOOL_PATH% > "%OUT%\%REL%"
  echo [%DATE% %TIME%] TOOL_NOT_FOUND %TOOL_PATH%>> "%ERROR_LOG%"
  call :Log "SKIP  %REL%"
  exit /b 0
)
(
  echo Command: "%TOOL_PATH%" %TOOL_ARGS%
  echo Started: %DATE% %TIME%
  echo.
  "%TOOL_PATH%" %TOOL_ARGS%
) > "%OUT%\%REL%" 2>&1
if errorlevel 1 (
  call :Log "WARN  %REL% exit=!ERRORLEVEL!"
) else (
  call :Log "DONE  %REL%"
)
exit /b 0

:CopyPath
set "SRC=%~1"
set "DST=%~2"
call :Log "START copy %SRC%"
if exist "%SRC%\" (
  robocopy "%SRC%" "%DST%" /E /R:1 /W:1 > "%OUT%\00_collection_info\copy_%~nx1.log" 2>> "%ERROR_LOG%"
  if !ERRORLEVEL! LEQ 7 (
    call :Log "DONE  copy %SRC%"
  ) else (
    call :Log "WARN  copy %SRC% exit=!ERRORLEVEL!"
  )
) else if exist "%SRC%" (
  mkdir "%DST%" 2>nul
  copy /y "%SRC%" "%DST%\" >nul 2>> "%ERROR_LOG%"
  call :Log "DONE  copy %SRC%"
) else (
  echo [%DATE% %TIME%] NOT_FOUND %SRC%>> "%ERROR_LOG%"
  call :Log "SKIP  copy %SRC%"
)
exit /b 0

:Log
echo [%DATE% %TIME%] [INFO] %~1
echo [%DATE% %TIME%] [INFO] %~1>> "%RUN_LOG%"
exit /b 0