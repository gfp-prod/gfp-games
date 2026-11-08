@echo off
cd /d "%~dp0"
where godot >nul 2>nul
if not errorlevel 1 (
  echo Testing initial scene...
  godot --headless --path "%~dp0" --script res://tests/smoke_test.gd
  if errorlevel 1 goto fail
  echo Testing living-world simulation...
  godot --headless --path "%~dp0" --script res://tests/ecology_smoke_test.gd
  if errorlevel 1 goto fail
  echo All engine smoke tests passed.
  pause
  exit /b 0
)
echo Godot is not on PATH. Open this project in Godot and use the editor, or add the Godot executable to PATH.
pause
exit /b 1
:fail
echo Test failed. Copy the error shown above and send it to the developer.
pause
exit /b 1
