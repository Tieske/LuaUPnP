#ifndef LuaIXMLelement_h
#define LuaIXMLelement_h

#include <ixml.h>
#include <lua.h>
#include <lauxlib.h>
#include "luaIXMLdefinitions.h"
#include "luaIXMLsupport.h"

/*
** ===============================================================
**  implementation of the Element interface
** ===============================================================
*/
int L_getTagName(lua_State *L);
int L_getAttribute(lua_State *L);
int L_setAttribute(lua_State *L);
int L_removeAttribute(lua_State *L);
int L_getAttributeNode(lua_State *L);
int L_setAttributeNode(lua_State *L);
int L_removeAttributeNode(lua_State *L);
int L_getElementsByTagName_Element(lua_State *L);
int L_getAttributeNS(lua_State *L);
int L_setAttributeNS(lua_State *L);
int L_removeAttributeNS(lua_State *L);
int L_getAttributeNodeNS(lua_State *L);
int L_setAttributeNodeNS(lua_State *L);
int L_getElementsByTagNameNS_Element(lua_State *L);
int L_hasAttribute(lua_State *L);
int L_hasAttributeNS(lua_State *L);

#endif  /* LuaIXMLelement_h */