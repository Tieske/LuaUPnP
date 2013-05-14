@ECHO OFF
SETLOCAL

SET VERSION=0.1-1
SET LR_PATH=C:\Users\Public\Lua\LuaRocks\2.0\


SET SELF=%~dp0
SET ROCKNAME=luaupnp-%VERSION%.win32-x86.rock
SET TARGET=%SELF%%ROCKNAME%\
SET LUA=%TARGET%lua\
SET BIN=%TARGET%bin\
SET LIB=%TARGET%lib\

rd /S /Q "%TARGET%"
md "%TARGET%"

REM Copy rockspec file
copy "%SELF%*.rockspec" "%TARGET%"

REM Copy Lua files
md "%LUA%"
xcopy /S /E "%SELF%lua_src\*.*" "%LUA%"

REM Copy and rename binary module
md "%LIB%"
md "%LIB%\upnp"
copy "%SELF%Release\LuaUPnP.dll" "%LIB%\upnp\core.dll"

REM Copy support dlls
md "%BIN%"
copy "%SELF%libupnp\Release\libupnp.dll" "%BIN%"
copy "%SELF%libupnp\Release\pthreadVC2.dll" "%BIN%"

REM compress into rock
cd %TARGET%
del "%SELF%%ROCKNAME%.zip"
%LR_PATH%7z a -r -tzip "%SELF%%ROCKNAME%.zip" *.*
cd %SELF%
REM remove temp directory
rd /S /Q "%TARGET%"

REM remove the .zip extension
rename "%SELF%%ROCKNAME%.zip" "%ROCKNAME%"



pause

