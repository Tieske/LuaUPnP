@echo off
echo off
REM ===================================================
REM This batch files copies the build output to the Lua 
REM for Windows directory, set the path below correct
REM ===================================================

SET T_LUAPATH=C:\Users\Public\lua\5.1
rem change actiev directory, to the one containing this batch file
cd /d %~dp0

REM ========== LUA sources ============================
echo Create Lua\upnp\ directory
md "%T_LUAPATH%\lua\upnp"
echo Copying Lua files
cd lua_src
xcopy "*.*" "%T_LUAPATH%\lua\upnp" /S /Y
cd ..

REM ========== C libaries =============================
echo Create Clib\upnp\ directory
md "%T_LUAPATH%\clibs\upnp"
echo Copying upnp dll's
copy "libupnp\pthread*.*" "%T_LUAPATH%\clibs\upnp"
copy "libupnp\libupnp.*" "%T_LUAPATH%\clibs\upnp"

echo Copying file 'LuaUPnP.*' (dll + debug files)
copy "Debug\core.*" "%T_LUAPATH%\clibs\upnp"

REM ========== Cleanup ================================
rem Delete temp var
SET T_LUAPATH=

