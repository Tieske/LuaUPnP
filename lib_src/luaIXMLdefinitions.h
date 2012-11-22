#ifndef LuaIXMLdefinitions_h
#define LuaIXMLdefinitions_h

#include <ixml.h>

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

#endif  /* LuaIXMLdefinitions_h */