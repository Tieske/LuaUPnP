#include "luaIXML.h"
// TODO: locking on IXML objects needs to be done, might get modified or freed by UPnP lib !! or just make copies... always


/*
** ===============================================================
** IXML API
** ===============================================================
*/

int L_PrintDocument(lua_State *L)
{
	DOMString result;
	result = ixmlPrintDocument(checkdocument(L, 1));
	if (result == NULL) return pusherror(L, "Error printing document");
	lua_pushstring(L, result);
	ixmlFreeDOMString(result);
	return 1;
};

int L_PrintNode(lua_State *L)
{
	DOMString result;
	result = ixmlPrintNode(checknode(L, 1));
	if (result == NULL) return pusherror(L, "Error printing node");
	lua_pushstring(L, result);
	ixmlFreeDOMString(result);
	return 1;
};

int L_DocumenttoString(lua_State *L)
{
	DOMString result;
	result = ixmlDocumenttoString(checkdocument(L, 1));
	if (result == NULL) return pusherror(L, "Error creating document string");
	lua_pushstring(L, result);
	ixmlFreeDOMString(result);
	return 1;
};

int L_NodetoString(lua_State *L)
{
	DOMString result;
	result = ixmlNodetoString(checknode(L, 1));
	if (result == NULL) return pusherror(L, "Error creating node string");
	lua_pushstring(L, result);
	ixmlFreeDOMString(result);
	return 1;
};

int L_RelaxParser(lua_State *L)
{
	int newChar = 0;
	newChar = luaL_checkinteger(L,1);

	if (newChar < 0 || newChar > 255)
	{
		return luaL_error(L, "To set relaxed mode, the error replacement character provided must be from 1 to 255, or 0 to set strict mode");
	}
	else
	{
		ixmlRelaxParser((char)newChar);
	}
	return 0;
};

int L_ParseBufferEx(lua_State *L)
{
	int err = IXML_SUCCESS;
	IXML_Document* doc = NULL;
	err = ixmlParseBufferEx(luaL_checkstring(L,1), &doc);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaDocument(L, doc);
	return 1;
};

int L_LoadDocumentEx(lua_State *L)
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

int L_getElementsByTagName(lua_State *L)			// Document and Element
{
	unsigned short nt = ixmlNode_getNodeType(checknode(L, 1));
	
	if (nt == eDOCUMENT_NODE)
		return L_getElementsByTagName_Document(L);
	else if (nt == eELEMENT_NODE)
		return L_getElementsByTagName_Element(L);
	else
		return luaL_error(L, "Wrong node type, expected document or element node");
}

int L_getElementsByTagNameNS(lua_State *L)		// Document and Element
{
	unsigned short nt = ixmlNode_getNodeType(checknode(L, 1));

	if (nt == eDOCUMENT_NODE)
		return L_getElementsByTagNameNS_Document(L);
	else if (nt == eELEMENT_NODE)
		return L_getElementsByTagNameNS_Element(L);
	else
		return luaL_error(L, "Wrong node type, expected Document or Element node");
}

int L_item(lua_State *L)							// NamedNodeMap and NodeList
{
	// TODO: implement, NodeList is all Lua table, map, to be decided
	return luaL_error(L, "Not implemented");
}


