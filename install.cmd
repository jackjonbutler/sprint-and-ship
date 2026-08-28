@echo off
REM Windows installer: copies skills into %USERPROFILE%\.claude\skills
REM (copy mode — re-run after every git pull to pick up updates)
xcopy "%~dp0skills" "%USERPROFILE%\.claude\skills" /E /I /Y
echo.
echo Done. Skills installed to %USERPROFILE%\.claude\skills
echo Re-run install.cmd after git pull to update them.
