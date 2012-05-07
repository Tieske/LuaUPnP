#ifndef LuaIXML_c
#define LuaIXML_c

#include "LuaIXML.h"
#include "LuaNodeStore.c"
#include "Support.c"
#include "Node.c"
#include "Document.c"
#include "Element.c"


/*
** ===============================================================
** IXML API
** ===============================================================
*/

static int L_PrintDocument(lua_State *L)
{
	DOMString result;
	result = ixmlPrintDocument(checkdocument(L, 1));
	if (result == NULL) return pusherror(L, "Error printing document");
	lua_pushstring(L, result);
	ixmlFreeDOMString(result);
	return 1;
};

static int L_PrintNode(lua_State *L)
{
	DOMString result;
	result = ixmlPrintNode(checknode(L, 1));
	if (result == NULL) return pusherror(L, "Error printing node");
	lua_pushstring(L, result);
	ixmlFreeDOMString(result);
	return 1;
};

static int L_DocumenttoString(lua_State *L)
{
	DOMString result;
	result = ixmlDocumenttoString(checkdocument(L, 1));
	if (result == NULL) return pusherror(L, "Error creating document string");
	lua_pushstring(L, result);
	ixmlFreeDOMString(result);
	return 1;
};

static int L_NodetoString(lua_State *L)
{
	DOMString result;
	result = ixmlNodetoString(checknode(L, 1));
	if (result == NULL) return pusherror(L, "Error creating node string");
	lua_pushstring(L, result);
	ixmlFreeDOMString(result);
	return 1;
};

static int L_RelaxParser(lua_State *L)
{
	int newChar = 0;
	newChar = luaL_checkinteger(L,1);

	if (newChar < 0 && newChar > 255)
	{
		return luaL_error(L, "To set relaxed mode, the error replacement character provided must be from 1 to 255, or 0 to set strict mode");
	}
	else
	{
		ixmlRelaxParser((char)newChar);
	}
	return 0;
};

static int L_ParseBufferEx(lua_State *L)
{
	int err = IXML_SUCCESS;
	IXML_Document* doc = NULL;
	err = ixmlParseBufferEx(luaL_checkstring(L,1), &doc);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaDocument(L, doc);
	return 1;
};

static int L_LoadDocumentEx(lua_State *L)
{
	int err = IXML_SUCCESS;
	IXML_Document* doc = NULL;
	err = ixmlLoadDocumentEx(luaL_checkstring(L,1), &doc);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaDocument(L, doc);
	return 1;
};

/*
** ===============================================================
**  API doubles
** ===============================================================
*/

static int L_getElementsByTagName(lua_State *L)			// Document and Element
{
	unsigned short nt = ixmlNode_getNodeType(checknode(L, 1));
	
	if (nt == eDOCUMENT_NODE)
		return L_getElementsByTagName_Document(L);
	else if (nt == eELEMENT_NODE)
		return L_getElementsByTagName_Element(L);
	else
		return luaL_error(L, "Wrong node type, expected document or element node");
}

static int L_getElementsByTagNameNS(lua_State *L)		// Document and Element
{
	unsigned short nt = ixmlNode_getNodeType(checknode(L, 1));

	if (nt == eDOCUMENT_NODE)
		return L_getElementsByTagNameNS_Document(L);
	else if (nt == eELEMENT_NODE)
		return L_getElementsByTagNameNS_Element(L);
	else
		return luaL_error(L, "Wrong node type, expected Document or Element node");
}

static int L_item(lua_State *L)							// NamedNodeMap and NodeList
{
	// TODO: implement
	return luaL_error(L, "Not implemented");
}

/*
** ===============================================================
** Library initialization
** ===============================================================
*/

static const struct luaL_Reg IXMLfunctions[] = {
	// IXML API
	{"PrintDocument",L_PrintDocument},
	{"PrintNode",L_PrintNode},
	{"DocumenttoString",L_DocumenttoString},
	{"NodetoString",L_NodetoString},
	{"RelaxParser",L_RelaxParser},
	{"ParseBuffer",L_ParseBufferEx},
	{"LoadDocument",L_LoadDocumentEx},
	// Node API
	{"getNodeName",L_getNodeName},
	{"getNodeValue",L_getNodeValue},
	{"setNodeValue",L_setNodeValue},
	{"getNodeType",L_getNodeType},
	{"getParentNode",L_getParentNode},
	{"getChildNodes",L_getChildNodes},
	{"getFirstChild",L_getFirstChild},
	{"getLastChild",L_getLastChild},
	{"getPreviousSibling",L_getPreviousSibling},
	{"getNextSibling",L_getNextSibling},
	{"getAttributes",L_getAttributes},
	{"getOwnerDocument",L_getOwnerDocument},
	{"getNamespaceURI",L_getNameSpaceURI},
	{"getPrefix",L_getPrefix},
	{"getLocalName",L_getLocalName},
	{"insertBefore",L_insertBefore},
	{"replaceChild",L_replaceChild},
	{"removeChild",L_removeChild},
	{"appendChild",L_appendChild},
	{"hasChildNodes",L_hasChildNodes},
	{"cloneNode",L_cloneNode},
	{"hasAttributes",L_hasAttributes},
	// Attr API
	/* empty */
	// CDATA API
	/* empty */
	// Document API
	{"createDocument",L_createDocumentEx},
	{"createElement",L_createElementEx},
	{"createTextNode",L_createTextNodeEx},
	{"createCDATASection",L_createCDATASectionEx},
	{"createAttribute",L_createAttributeEx},
	//{"getElementsByTagName",L_getElementsByTagName}
	{"createElementNS",L_createElementNSEx},
	{"createAttributeNS",L_createAttributeNSEx},
	//{"getElementsByTagNameNS",L_getElementsByTagName},
	{"getElementById",L_getElementById},
	{"importNode",L_importNode},
	// Element API
	{"getTagName",L_getTagName},
	{"getAttribute",L_getAttribute},
	{"setAttribute",L_setAttribute},
	{"removeAttribute",L_removeAttribute},
	{"getAttributeNode",L_getAttributeNode},
	{"setAttributeNode",L_setAttributeNode},
	{"removeAttributeNode",L_removeAttributeNode},
	//{"getElementsByTagName",L_getElementsByTagName},
	{"getAttributeNS",L_getAttributeNS},
	{"setAttributeNS",L_setAttributeNS},
	{"removeAttributeNS",L_removeAttributeNS},
	{"getAttributeNodeNS",L_getAttributeNodeNS},
	{"setAttributeNodeNS",L_setAttributeNodeNS},
	//{"getElementsByTagNameNS",L_getElementsByTagNameNS},
	{"hasAttribute",L_hasAttribute},
	{"hasAttributeNS",L_hasAttributeNS},
/*	// NamedNodeMap API
	{"getLength",L_getLength},
	{"getNamedItem",L_getNamedItem},
	{"setNamedItem",L_setNamedItem},
	{"removeNamedItem",L_removeNamedItem},
	//{"item",L_item},
	{"getNamedItemNS",L_getNamedItemNS},
	{"setNamedItemNS",L_setNamedItemNS},
	{"removeNamedItemNS",L_removeNamedItemNS},
	// NodeList API
	//{"item",L_item},
	{"length",L_length},
*/	// API Doubles
	{"getElementsByTagName",L_getElementsByTagName},		// Document and Element
	{"getElementsByTagNameNS",L_getElementsByTagNameNS},	// Document and Element
/*	{"item",L_item},										// NamedNodeMap and NodeList
*/	{NULL,NULL}
};

// Methods for the document object
static const struct luaL_Reg LPNP_Node_Methods[] = {
	//{"new", LPNP_DocNew},
	{NULL, NULL}
};

LPNP_API	int luaopen_LuaUPnP(lua_State *L)
{
	// Register functions
	luaL_register(L,"ixml",IXMLfunctions);

	// Create a new metatable for the nodes
	luaL_newmetatable(L, LPNP_NODE_MT);
	// Set it as a metatable to itself
	lua_pushvalue(L, -1); 
	lua_setfield(L, -2, "__index");
	// Add GC method
	lua_pushstring(L, "__gc");
	lua_pushcfunction(L, L_DestroyNode);
	lua_settable(L, -3);
	// Register the methods of the object
	luaL_register(L, NULL, LPNP_Node_Methods);

	// Create reference table for the userdatas
	lua_newtable(L);				// table
	lua_newtable(L);				// meta table
	lua_pushstring(L,"v");			// weak values
	lua_setfield(L, -2, "__mode");	// metatable weak values 'mode'
	lua_setmetatable(L, -2);		// set the meta table
	lua_setfield(L, LUA_REGISTRYINDEX, LPNP_WTABLE_IXML);	// store in registry


	// set the 'free' callback from IXML
	ixmlSetBeforeFree(&FreeCallBack);

	return 1;
};




#endif  /* LuaIXML_c */