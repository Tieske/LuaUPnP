#ifndef LuaIXML_h
#define LuaIXML_h

#include <lua.h>
//#include <lauxlib.h>
#include "luaIXMLdefinitions.h"
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
	{"children", L_children},
/*	{"item",L_item},										// NamedNodeMap and NodeList
*/	{NULL,NULL}
};

// Methods for the nodes
static const struct luaL_Reg LPNP_Node_Methods[] = {
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
	{"children", L_children},
/*	{"item",L_item},										// NamedNodeMap and NodeList
*/	{NULL,NULL}
};


#endif  /* LuaIXML_h */