#ifndef LuaIXMLnode_h
#define LuaIXMLnode_h

#include <ixml.h>
#include <lua.h>
#include <lauxlib.h>
#include "luaIXMLdefinitions.h"

/*
** ===============================================================
**  implementation of the Node interface
** ===============================================================
*/
int L_getNodeName(lua_State *L);
int L_getNodeValue(lua_State *L);
int L_setNodeValue(lua_State *L);
int L_getNodeType(lua_State *L);
int L_getParentNode(lua_State *L);
int L_getChildNodes(lua_State *L);
int L_getFirstChild(lua_State *L);
int L_getLastChild(lua_State *L);
int L_getPreviousSibling(lua_State *L);
int L_getNextSibling(lua_State *L);
int L_getAttributes(lua_State *L);
int L_getOwnerDocument(lua_State *L);
int L_getNameSpaceURI(lua_State *L);
int L_getPrefix(lua_State *L);
int L_getLocalName(lua_State *L);
int L_insertBefore(lua_State *L);
int L_replaceChild(lua_State *L);
int L_removeChild(lua_State *L);
int L_appendChild(lua_State *L);
int L_hasChildNodes(lua_State *L);
int L_cloneNode(lua_State *L);
int L_hasAttributes(lua_State *L);

/*
** ===============================================================
**  In addition to the interface, an node-child iterator
** ===============================================================
*/
int L_childIter(lua_State *L);
int L_children(lua_State *L);


#endif  /* LuaIXMLnode_h */
