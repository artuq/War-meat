@echo off
chcp 65001 >nul 2>&1
title WAR MEAT - Napraw Sprite
REM ═══════════════════════════════════════
REM  WAR MEAT — Napraw sprite z Gema
REM  Przeciągnij plik PNG na ten skrypt!
REM ═══════════════════════════════════════

if "%~1"=="" (
    echo.
    echo  Uzycie: Przeciagnij plik PNG na ten skrypt
    echo  Lub:    napraw_sprite.bat input.png
    echo.
    echo  Co robi:
    echo   - Zmniejsza do 32x32 px ^(nearest neighbor^)
    echo   - Zamienia kolory na palete WAR MEAT
    echo   - Dodaje 1px outline
    echo   - Zapisuje jako NAZWA_fixed.png
    echo.
    pause
    exit /b
)

set "INPUT=%~1"
set "DIR=%~dp1"
set "NAME=%~n1"
set "OUTPUT=%DIR%%NAME%_fixed.png"
set "TOOL=%~dp0dist\palette_enforcer.exe"

if not exist "%TOOL%" (
    echo.
    echo  BLAD: Nie znaleziono palette_enforcer.exe
    echo  Oczekiwana sciezka: %TOOL%
    echo.
    pause
    exit /b 1
)

if not exist "%INPUT%" (
    echo.
    echo  BLAD: Nie znaleziono pliku: %INPUT%
    echo.
    pause
    exit /b 1
)

echo.
echo  [WAR MEAT] Naprawiam sprite: %INPUT%
echo  Narzedzie: %TOOL%
echo.

"%TOOL%" "%INPUT%" "%OUTPUT%" --resize 32 --outline

if %errorlevel% neq 0 (
    echo.
    echo  BLAD: palette_enforcer zwrocil blad %errorlevel%
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo  OK! Zapisano: %OUTPUT%
echo.
pause
