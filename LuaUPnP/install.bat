@echo off
echo off
REM ===================================================
REM This batch files copies the build output to the Lua 
REM for Windows directory, set the path below correct
REM ===================================================
SET T_LUAPATH=C:\Users\Public\lua\5.1

echo Copying upnp dll's
copy "..\libupnp\*.dll" "%T_LUAPATH%\clibs"

echo Copying file 'LuaUPnP.dll'
copy "..\Debug\LuaUPnP.dll" "%T_LUAPATH%\clibs"

