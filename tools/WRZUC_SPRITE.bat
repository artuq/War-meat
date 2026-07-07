@echo off
:: WAR MEAT — Sprite Processor (drag-and-drop)
:: Przeciągnij plik JPG/PNG na ten .bat i gotowe!
:: Output trafia automatycznie do assets/sprites/<kategoria>/
::
:: Opcje (edytuj poniżej):
::   Domyślnie usuwa BIAŁE tło #FFFFFF (to co AI Studio generuje jako JPG)
::   i auto-resize per kategoria (soldiers=128px, enemies=80px, weapons=brak)
::
::   Opcje ręczne (zmień OPTS poniżej):
::   --resize 112     -> inna docelowa wielkość (np. Tank 112px)
::   --resize 0       -> wyłącz resize (zostaw oryginalne 1024px)
::   --outline        -> dodaj 1px granatowy outline
::   --color FF00FF   -> usuń magentę zamiast bieli
::   --no-palette     -> pomiń snapping palety WAR MEAT
::
:: Domyślne ustawienie: auto-resize + białe tło (zalecane dla żołnierzy)

set OPTS=

if "%~1"=="" (
    echo.
    echo  WAR MEAT Sprite Processor
    echo  Przeciagnij plik JPG lub PNG na ten plik .bat
    echo.
    echo  Lub uruchom z argumentem:
    echo    %~nx0 sciezka\do\pliku.jpg
    echo.
    pause
    exit /b 1
)

:: Znajdź Python (.venv ma priorytet)
set REPO=%~dp0..
set VENV_PY=%REPO%\.venv\Scripts\python.exe
set SCRIPT=%REPO%\tools\process_sprite.py

if exist "%VENV_PY%" (
    set PYTHON=%VENV_PY%
) else (
    set PYTHON=python
)

echo.
echo  Przetwarzanie: %~nx1
echo.
"%PYTHON%" "%SCRIPT%" %OPTS% "%~1"

if errorlevel 1 (
    echo.
    echo  BLAD podczas przetwarzania!
    pause
) else (
    echo  Gotowe!
    timeout /t 3
)
