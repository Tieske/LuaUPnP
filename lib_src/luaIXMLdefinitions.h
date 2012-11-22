#ifndef LuaIXMLdefinitions_h
#define LuaIXMLdefinitions_h

#include <ixml.h>
#include <lua.h>
#include <lauxlib.h>

// Required to track usage and free resources when all is out of scope
// Typedefinition for a record that points to an IXML node
typedef struct LuaNodeRecord *pLuaNode;
typedef struct LuaNodeRecord {
	// if Node == NULL, the document was closed, otherwise always filled
	IXML_Node* node;	
} LuaNode;

// Metatable names to define objects
#define LPNP_NODE_MT "LuaUPnP.IXMLNode"	

// Registry (weak) table name with userdata references by pointers (lightuserdata)
#define LPNP_WTABLE_IXML "LuaUPnP.IXMLuserdata"

// include support functions
#include "luaIXMLsupport.h"
#include "luaIXMLelement.h"
#include "luaIXMLnode.h"
#include "luaIXMLdocument.h"

// forward declaration
//int L_getNodeType(lua_State *L);
/*
** ===============================================================
** IXML API
** ===============================================================
*/
int L_PrintDocument(lua_State *L);
int L_PrintNode(lua_State *L);
int L_DocumenttoString(lua_State *L);
int L_NodetoString(lua_State *L);
int L_RelaxParser(lua_State *L);
int L_ParseBufferEx(lua_State *L);
int L_LoadDocumentEx(lua_State *L);
/*
** ===============================================================
**  API doubles
** ===============================================================
*/
int L_getElementsByTagName(lua_State *L);		// Document and Element
int L_getElementsByTagNameNS(lua_State *L);		// Document and Element
int L_item(lua_State *L);						// NamedNodeMap and NodeList


#endif  /* LuaIXMLdefinitions_h */