@echo off
setlocal enabledelayedexpansion

echo ========================================
echo  Nacos Config Import
echo ========================================

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "NACOS_URL=http://localhost:8848"
set "NACOS_USER=nacos"
set "NACOS_PASS=nacos"
set "GROUP=DEFAULT_GROUP"

echo.
echo [1/5] Waiting for Nacos...
set retries=0
:wait_nacos
curl -s "%NACOS_URL%/nacos/v1/ns/operator/metrics" -u "%NACOS_USER%:%NACOS_PASS%" | findstr "status" >nul 2>&1
if !errorlevel! equ 0 (
    echo       Nacos ready
    goto :nacos_ready
)
set /a retries+=1
if !retries! geq 30 (
    echo       ERROR: Nacos timeout
    pause
    exit /b 1
)
echo       waiting... (!retries!/30)
timeout /t 2 >nul
goto :wait_nacos

:nacos_ready
timeout /t 3 >nul

echo.
echo [2/5] Importing configs...

call :import_config "application-dev.yml"
call :import_config "pig-auth-dev.yml"
call :import_config "pig-gateway-dev.yml"
call :import_config "pig-upms-biz-dev.yml"
call :import_config "pig-codegen-dev.yml"
call :import_config "pig-monitor-dev.yml"
call :import_config "pig-quartz-dev.yml"

echo.
echo [3/5] Verifying configs...
timeout /t 2 >nul

call :verify_config "application-dev.yml"
call :verify_config "pig-auth-dev.yml"
call :verify_config "pig-gateway-dev.yml"
call :verify_config "pig-upms-biz-dev.yml"
call :verify_config "pig-codegen-dev.yml"
call :verify_config "pig-monitor-dev.yml"
call :verify_config "pig-quartz-dev.yml"

echo.
echo [4/5] Waiting for services...
timeout /t 5 >nul

echo [5/5] Checking services...
call :check_service "pig-upms-biz"
call :check_service "pig-auth"
call :check_service "pig-gateway"

echo.
echo ========================================
echo  Nacos config import done!
echo ========================================
echo.
echo  Console: %NACOS_URL%/nacos
echo  Account: %NACOS_USER% / %NACOS_PASS%
echo.
pause
exit /b 0

REM === Subroutines ===

:import_config
set "fname=%~1"
set "fpath=%SCRIPT_DIR%\%fname%"
if not exist "%fpath%" (
    echo       SKIP %fname%
    exit /b 0
)
echo       Importing: %fname%
curl -s -X POST "%NACOS_URL%/nacos/v1/cs/configs?dataId=%fname%&group=%GROUP%&username=%NACOS_USER%&password=%NACOS_PASS%&type=yaml" --data-urlencode "content@%fpath%" -o "%TEMP%\nacos-import-result.txt" 2>nul
set /p RESULT=<"%TEMP%\nacos-import-result.txt" 2>nul
if "!RESULT!"=="true" (
    echo       OK %fname%
) else (
    echo       FAIL %fname% - !RESULT!
)
del /q "%TEMP%\nacos-import-result.txt" 2>nul
exit /b 0

:verify_config
set "vname=%~1"
curl -s "%NACOS_URL%/nacos/v1/cs/configs?dataId=%vname%&group=%GROUP%&username=%NACOS_USER%&password=%NACOS_PASS%" > "%TEMP%\nacos-verify.txt" 2>nul
for %%s in ("%TEMP%\nacos-verify.txt") do if %%~zs gtr 10 (
    echo       OK %vname%
) else (
    echo       FAIL %vname%
)
del /q "%TEMP%\nacos-verify.txt" 2>nul
exit /b 0

:check_service
set "sname=%~1"
curl -s "%NACOS_URL%/nacos/v1/ns/instance/list?serviceName=%sname%" -u "%NACOS_USER%:%NACOS_PASS%" | findstr "ip" >nul 2>&1
if !errorlevel! equ 0 (
    echo       OK %sname% registered
) else (
    echo       -- %sname% not registered
)
exit /b 0
