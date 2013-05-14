@ECHO OFF
SETLOCAL
SET SPATH=%~dp0
@ECHO ON
rd /S /Q "%SPATH%Debug"
rd /S /Q "%SPATH%ipch"
rd /S /Q "%SPATH%Release"
rd /S /Q "%SPATH%lib_src\Debug"
rd /S /Q "%SPATH%lib_src\Release"
del /S /Q "%SPATH%lib_src\*.o"
@ECHO OFF
pause



