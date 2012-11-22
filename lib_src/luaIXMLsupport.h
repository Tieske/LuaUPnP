#ifndef LuaIXMLsupport_h
#define LuaIXMLsupport_h

#include <ixml.h>
#include <lua.h>
//#include <lauxlib.h>
#include "luaIXML.h"

/*
** ===============================================================
**  Pushing objects to Lua
** ===============================================================
*/

void clearLuaNode(IXML_Node *node);
pLuaNode pushLuaNode(lua_State *L, IXML_Node *node);
pLuaNode pushLuaElement(lua_State *L, IXML_Element *elem);
pLuaNode pushLuaDocument(lua_State *L, IXML_Document *doc);
pLuaNode pushLuaAttr(lua_State *L, IXML_Attr *attr);
pLuaNode pushLuaCDATASection(lua_State *L, IXML_CDATASection *cds);
void pushLuaNodeList(lua_State *L, IXML_NodeList *list);
void pushLuaNodeNamedMap(lua_State *L, IXML_NamedNodeMap *nnmap);

/*
** ===============================================================
**  Collecting objects from Lua
** ===============================================================
*/
IXML_Node* checknode(lua_State *L, int idx);
IXML_Element* checkelement(lua_State *L, int idx);
IXML_Document* checkdocument(lua_State *L, int idx);
IXML_Attr* checkattr(lua_State *L, int idx);
IXML_CDATASection* checkcdata(lua_State *L, int idx);

/*
** ===============================================================
**  Pushing (soft) errors to Lua
** ===============================================================
*/
int pusherror(lua_State *L, const char* errorstr);
int pushIXMLerror(lua_State *L, int err);

/*
** ===============================================================
**  tostring method for the node userdatas
** ===============================================================
*/
int L_tostring(lua_State *L);


/*
** ===============================================================
**  Destroying objects from Lua
** ===============================================================
*/
void FreeCallBack(IXML_Node* node);
int L_DestroyNode(lua_State *L);

#endif  /* LuaIXMLsupport_h */