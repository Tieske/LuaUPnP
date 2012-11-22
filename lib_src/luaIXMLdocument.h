#ifndef LuaIXMLdocument_h
#define LuaIXMLdocument_h

#include <ixml.h>
#include <lua.h>
#include <lauxlib.h>
#include "luaIXMLdefinitions.h"

/*
** ===============================================================
**  implementation of the Document interface
** ===============================================================
*/
int L_createDocumentEx(lua_State *L);
int L_createElementEx(lua_State *L);
int L_createTextNodeEx(lua_State *L);
int L_createCDATASectionEx(lua_State *L);
int L_createAttributeEx(lua_State *L);
int L_getElementsByTagName_Document(lua_State *L);
int L_createElementNSEx(lua_State *L);
int L_createAttributeNSEx(lua_State *L);
int L_getElementsByTagNameNS_Document(lua_State *L);
int L_getElementById(lua_State *L);
int L_importNode(lua_State *L);


#endif  /* LuaIXMLdocument_h */