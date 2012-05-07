#ifndef LuaIXML_h
#define LuaIXML_h

#include <ixml.h>
#include <lua.h>
#include <lauxlib.h>

// Define platform specific extern statement
#ifdef WIN32
	#define LPNP_API __declspec(dllexport)
#else
	#define LPNP_API extern
#endif

// Registry ID for the start/end of the node (linked)list
#define STARTNODE "LuaIXML.nodelists"
#define ENDNODE "LuaIXML.nodeliste"

// Required to track usage and free resources when all is out of scope
// Typedefinition for a record that points to an IXML node
typedef struct LuaNodeRecord *pLuaNode;
typedef struct LuaNodeRecord {
	// if Node == NULL, the document was closed, otherwise always filled
	IXML_Node* node;	
} LuaNode;

// Metatable names to define objects
#define LPNP_NODE_MT "LuaUPnP.Node"	

// Registry (weak) table name with userdata references by pointers (lightuserdata)
#define LPNP_WTABLE_IXML "LuaUPnP.IXMLuserdata"

#endif  /* LuaIXML_h */