@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo ========================================
echo  Hiking Platform - One-Click Deploy
echo ========================================

set "SD=%~dp0"
set "SD=%SD:~0,-1%"
cd /d "%SD%"

echo.
echo [1/5] Starting Docker containers (with rebuild)...
docker compose up -d --build
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Docker failed. Is Docker Desktop running?
    pause
    exit /b 1
)
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Docker failed. Is Docker Desktop running?
    pause
    exit /b 1
)
echo       OK

echo.
echo [2/5] Waiting for MySQL...
set r=0
:wm
docker exec pig-mysql mysql -uroot -proot -e "SELECT 1" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo       OK MySQL ready
    goto :mr
)
set /a r+=1
if %r% geq 30 (
    echo [ERROR] MySQL timeout
    pause
    exit /b 1
)
echo       waiting... (%r%/30)
timeout /t 2 >nul
goto :wm
:mr

echo.
echo [2.5/5] Waiting for Redis...
set r=0
:wr
docker exec pig-redis redis-cli ping 2>nul | findstr "PONG" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo       OK Redis ready
    goto :rr
)
set /a r+=1
if %r% geq 20 (
    echo [WARN] Redis timeout
    goto :rr
)
echo       waiting... (%r%/20)
timeout /t 2 >nul
goto :wr
:rr

echo.
echo [3/5] Checking business data...
docker exec pig-mysql mysql -uroot -proot pig -e "SELECT COUNT(*) FROM sys_menu WHERE menu_id = 10000" -s -N 2>nul | findstr /X "0" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo       Importing menus and roles...
    docker cp "%SD%\db\init-hiking-permission.sql" pig-mysql:/tmp/init.sql
    docker exec pig-mysql mysql -uroot -proot --default-character-set=utf8mb4 pig -e "source /tmp/init.sql"
    echo       OK imported
    echo       Cleaning up default menus...
    docker cp "%SD%\db\cleanup-menus.sql" pig-mysql:/tmp/cleanup.sql
    docker exec pig-mysql mysql -uroot -proot --default-character-set=utf8mb4 pig -e "source /tmp/cleanup.sql" 2>nul
    echo       OK cleaned
) else (
    echo       OK data exists, skip
)

echo.
echo [4/5] Importing Nacos config...
if exist "%SD%\config\nacos-backup\import-nacos.bat" (
    call "%SD%\config\nacos-backup\import-nacos.bat"
) else (
    echo       [WARN] import-nacos.bat not found, skip
)

echo.
echo [5/5] Waiting for Gateway...
set r=0
:wg
curl -s -o nul -w "%%{http_code}" http://localhost:9999/auth/oauth2/token 2>nul | findstr /R "[0-9]" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo       OK Gateway ready
    goto :gr
)
set /a r+=1
if %r% geq 30 (
    echo       [WARN] Gateway timeout
    goto :gr
)
echo       waiting... (%r%/30)
timeout /t 3 >nul
goto :wg
:gr

echo.
echo ========================================
echo  Deploy done!
echo ========================================
echo.
echo  Backend:
echo    Gateway:  http://localhost:9999
echo    Nacos:    http://localhost:8848/nacos
echo.
echo  Login: admin / 123456
echo.
echo  Frontend:
echo    cd pig-ui ^&^& npm install ^&^& npm run dev
echo    http://localhost:8888
echo.
echo  Stop: stop-all.bat
echo ========================================
pause
