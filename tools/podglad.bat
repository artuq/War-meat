@echo off
chcp 65001 >nul 2>&1
title WAR MEAT - Podglad Sprite
REM ═══════════════════════════════════════
REM  WAR MEAT — Podgląd sprite sheetów
REM  Przeciągnij plik PNG na ten skrypt!
REM ═══════════════════════════════════════

set "TOOL=%~dp0dist\sprite_viewer.exe"

if not exist "%TOOL%" (
    echo.
    echo  BLAD: Nie znaleziono sprite_viewer.exe
    echo  Oczekiwana sciezka: %TOOL%
    echo.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo.
    echo  Otwieram bez pliku ^(wybierz w oknie^)...
    echo.
    start "" "%TOOL%"
    exit /b
)

if not exist "%~1" (
    echo.
    echo  BLAD: Nie znaleziono pliku: %~1
    echo.
    pause
    exit /b 1
)

echo.
echo  [WAR MEAT] Otwieram podglad: %~nx1
echo.
start "" "%TOOL%" "%~1"
