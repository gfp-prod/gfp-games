@echo off
setlocal
cd /d "%~dp0"
where godot >nul 2>nul
if not errorlevel 1 (
  godot --path "%~dp0" --editor
  exit /b
)
where godot4 >nul 2>nul
if not errorlevel 1 (
  godot4 --path "%~dp0" --editor
  exit /b
)
echo VERBA requires Godot 4.5 or newer.
echo Open Godot, click Import, and select this folder's project.godot.
echo Download: https://godotengine.org/download/windows/
pause
