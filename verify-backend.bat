@echo off
setlocal enabledelayedexpansion

echo ========================================
echo  Hiking Platform - Health Check
echo ========================================

set P=0
set F=0

echo.
echo [1/4] Docker containers...
for %%c in (pig-mysql pig-redis pig-register pig-gateway pig-auth pig-upms) do (
    docker inspect --format "{{.State.Status}}" %%c 2>nul | findstr "running" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo       OK %%c
        set /a P+=1
    ) else (
        echo       FAIL %%c not running
        set /a F+=1
    )
)

echo.
echo [2/4] Ports...
set "PH_OK=0"
docker exec pig-mysql mysql -uroot -proot -e "SELECT 1" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo       OK port 33306 ^(MySQL^)
    set /a P+=1
) else (
    echo       FAIL port 33306 not listening
    set /a F+=1
)
docker exec pig-redis redis-cli ping 2>nul | findstr "PONG" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo       OK port 36379 ^(Redis^)
    set /a P+=1
) else (
    echo       FAIL port 36379 not listening
    set /a F+=1
)
curl -s -o nul -w "%%{http_code}" http://localhost:8848/nacos/ 2>nul | findstr "200 302" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo       OK port 8848 ^(Nacos^)
    set /a P+=1
) else (
    echo       FAIL port 8848 not listening
    set /a F+=1
)
curl -s -o nul -w "%%{http_code}" http://localhost:9999/auth/oauth2/token 2>nul | findstr /R "[0-9]" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo       OK port 9999 ^(Gateway^)
    set /a P+=1
) else (
    echo       FAIL port 9999 not listening
    set /a F+=1
)

echo.
echo [3/4] Database...
docker exec pig-mysql mysql -uroot -proot pig -e "SELECT COUNT(*) FROM sys_menu WHERE del_flag='0'" -s -N 2>nul > %TEMP%\mc.txt 2>nul
set /p MC=<%TEMP%\mc.txt 2>nul
if defined MC (
    echo       OK menus: %MC%
    set /a P+=1
) else (
    echo       FAIL cannot query menus
    set /a F+=1
)

docker exec pig-mysql mysql -uroot -proot pig -e "SELECT COUNT(*) FROM sys_role WHERE del_flag='0'" -s -N 2>nul > %TEMP%\rc.txt 2>nul
set /p RC=<%TEMP%\rc.txt 2>nul
if defined RC (
    echo       OK roles: %RC%
    set /a P+=1
) else (
    echo       FAIL cannot query roles
    set /a F+=1
)

echo.
echo [4/4] Login API...
curl -s -X POST "http://localhost:9999/auth/oauth2/token" -H "Authorization: Basic YXBwOmFwcA==" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=password&username=admin&password=YehdBPev&scope=server" 2>nul > %TEMP%\lr.txt
type %TEMP%\lr.txt | findstr "access_token" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo       OK admin login success
    set /a P+=1
) else (
    echo       FAIL admin login failed
    type %TEMP%\lr.txt
    set /a F+=1
)

echo.
echo ========================================
echo  Result: %P% PASS / %F% FAIL
echo ========================================
if %F% equ 0 (
    echo  All passed! Open http://localhost:8888
) else (
    echo  Some failed. Try: start-all.bat
)
echo ========================================
del /q %TEMP%\mc.txt %TEMP%\rc.txt %TEMP%\lr.txt 2>nul
pause
