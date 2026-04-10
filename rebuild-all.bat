@echo off
setlocal enabledelayedexpansion

echo ========================================
echo  Rebuild All Services
echo ========================================

set "SD=%~dp0"
set "SD=%SD:~0,-1%"
cd /d "%SD%"

echo.
echo [1/3] Maven build all modules...
call mvn clean package -DskipTests -T 1C 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Maven build failed
    pause
    exit /b 1
)
echo       OK

echo.
echo [2/3] Rebuild Docker images and restart...
docker compose up -d --build --force-recreate
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Docker rebuild failed
    pause
    exit /b 1
)
echo       OK

echo.
echo [3/3] Waiting for Gateway...
set r=0
:wg
curl -s -o nul -w "%%{http_code}" http://localhost:9999/auth/oauth2/token 2>nul | findstr /R "[0-9]" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo       OK Gateway ready
    goto :done
)
set /a r+=1
if %r% geq 40 (
    echo       [WARN] Gateway timeout
    goto :done
)
echo       waiting... (%r%/40)
timeout /t 3 >nul
goto :wg

:done
echo.
echo ========================================
echo  Rebuild complete!
echo ========================================
echo.
echo  Gateway:  http://localhost:9999
echo  Nacos:    http://localhost:8848/nacos
echo ========================================
pause
