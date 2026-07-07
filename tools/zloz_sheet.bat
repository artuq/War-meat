@echo off
chcp 65001 >nul 2>&1
title WAR MEAT - Zloz Sheet
REM ═══════════════════════════════════════
REM  WAR MEAT — Złóż klatki w sprite sheet
REM  Przeciągnij FOLDER z klatkami na ten skrypt!
REM ═══════════════════════════════════════

if "%~1"=="" (
    echo.
    echo  Uzycie: Przeciagnij FOLDER z klatkami PNG na ten skrypt
    echo  Lub:    zloz_sheet.bat folder_z_klatkami [kolumny]
    echo.
    echo  Przyklad:
    echo   zloz_sheet.bat frames\assault_idle
    echo   zloz_sheet.bat frames\assault_walk 4
    echo.
    echo  Co robi:
    echo   - Bierze wszystkie PNG z folderu
    echo   - Sklada w jeden sprite sheet
    echo   - Zapisuje jako NAZWA_FOLDERU_sheet.png
    echo.
    pause
    exit /b
)

set "INPUT=%~1"
set "FOLDERNAME=%~n1"
set "OUTPUT=%~dp1%FOLDERNAME%_sheet.png"
set "TOOL=%~dp0dist\sheet_assembler.exe"
set "COLS=%~2"

if not exist "%TOOL%" (
    echo.
    echo  BLAD: Nie znaleziono sheet_assembler.exe
    echo  Oczekiwana sciezka: %TOOL%
    echo.
    pause
    exit /b 1
)

if not exist "%INPUT%\" (
    echo.
    echo  BLAD: Nie znaleziono folderu: %INPUT%
    echo.
    pause
    exit /b 1
)

echo.
echo  [WAR MEAT] Skladam sheet z: %INPUT%
echo  Narzedzie: %TOOL%
echo.

if "%COLS%"=="" (
    "%TOOL%" "%INPUT%" "%OUTPUT%"
) else (
    "%TOOL%" "%INPUT%" "%OUTPUT%" --cols %COLS%
)

if %errorlevel% neq 0 (
    echo.
    echo  BLAD: sheet_assembler zwrocil blad %errorlevel%
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo  OK! Zapisano: %OUTPUT%
echo.
pause
