@echo off

echo ========================================
echo  Hiking Platform - Stop All
echo ========================================

cd /d "%~dp0"

echo.
echo [1/2] Stopping Docker...
docker compose down 2>nul
echo       OK

echo.
echo [2/2] Cleaning ports...
for %%p in (9999 8848 33306 36379 8888) do (
    for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /R /C:":%%p "') do (
        echo       killing port %%p (PID: %%a)
        taskkill /f /pid %%a >nul 2>&1
    )
)

echo.
echo ========================================
echo  All stopped
echo ========================================
pause
