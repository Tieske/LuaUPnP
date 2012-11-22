#ifndef LuaUPnPsupport_h
#define LuaUPnPsupport_h

//#include <ixml.h>
#include <lua.h>
#include <lauxlib.h>
#include "luaIXML.h"
#include "upnptools.h"
#include "luaUPnPdefinitions.h"

/*
** ===============================================================
**  Pushing objects to Lua
** ===============================================================
*/
pLuaDevice pushLuaDevice(lua_State *L, UpnpDevice_Handle dev);
pLuaClient pushLuaClient(lua_State *L, UpnpClient_Handle client);

/*
** ===============================================================
**  Collecting objects from Lua
** ===============================================================
*/
UpnpDevice_Handle checkdevice(lua_State *L, int idx);
UpnpDevice_Handle getdevice(lua_State *L, int idx);
UpnpClient_Handle checkclient(lua_State *L, int idx);
UpnpClient_Handle getclient(lua_State *L, int idx);
Upnp_DescType checkUpnp_DescType(lua_State *L, int idx);

/*
** ===============================================================
**  Pushing (soft) errors to Lua
** ===============================================================
*/
int pushUPnPerror(lua_State *L, int err, IXML_Document* respdoc);
const char *UpnpGetEventType(int et);

/*
** ===============================================================
**  tostring method for the device/client userdatas
** ===============================================================
*/
int L_devicetostring(lua_State *L);
int L_clienttostring(lua_State *L);

/*
** ===============================================================
**  Destroying objects from Lua
** ===============================================================
*/
int L_DestroyDevice(lua_State *L);
int L_DestroyClient(lua_State *L);

#endif  /* LuaUPnPsupport_h */