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

static void clearLuaNode(IXML_Node *node);
static pLuaNode pushLuaNode(lua_State *L, IXML_Node *node);
static pLuaNode pushLuaElement(lua_State *L, IXML_Element *elem);
static pLuaNode pushLuaDocument(lua_State *L, IXML_Document *doc);
static pLuaNode pushLuaAttr(lua_State *L, IXML_Attr *attr);
static pLuaNode pushLuaCDATASection(lua_State *L, IXML_CDATASection *cds);
static void pushLuaNodeList(lua_State *L, IXML_NodeList *list);
static void pushLuaNodeNamedMap(lua_State *L, IXML_NamedNodeMap *nnmap);

/*
** ===============================================================
**  Collecting objects from Lua
** ===============================================================
*/
static IXML_Node* checknode(lua_State *L, int idx);
static IXML_Element* checkelement(lua_State *L, int idx);
static IXML_Document* checkdocument(lua_State *L, int idx);
static IXML_Attr* checkattr(lua_State *L, int idx);
static IXML_CDATASection* checkcdata(lua_State *L, int idx);

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
static int L_tostring(lua_State *L);


/*
** ===============================================================
**  Destroying objects from Lua
** ===============================================================
*/
static void FreeCallBack(IXML_Node* node);
static int L_DestroyNode(lua_State *L);

#endif  /* LuaIXMLsupport_h */