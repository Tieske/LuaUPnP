#include "document.h"


/*
** ===============================================================
**  implementation of the Document interface
** ===============================================================
*/

int L_createDocumentEx(lua_State *L)
{
	IXML_Document* doc = NULL;
	int err = IXML_SUCCESS;
	err = ixmlDocument_createDocumentEx(&doc);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaDocument(L, doc);
	return 1;
}

int L_createElementEx(lua_State *L)
{
	IXML_Element* elem = NULL;
	int err = IXML_SUCCESS;
	err = ixmlDocument_createElementEx(checkdocument(L,1), luaL_checkstring(L,2), &elem);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaElement(L, elem);
	return 1;
}

int L_createTextNodeEx(lua_State *L)
{
	IXML_Node* node = NULL;
	int err = IXML_SUCCESS;
	err = ixmlDocument_createTextNodeEx(checkdocument(L,1), luaL_checkstring(L,2), &node);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaNode(L, node);
	return 1;
}

int L_createCDATASectionEx(lua_State *L)
{
	IXML_CDATASection* cdnode = NULL;
	int err = IXML_SUCCESS;
	err = ixmlDocument_createCDATASectionEx(checkdocument(L,1), luaL_checkstring(L,2), &cdnode);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaCDATASection(L, cdnode);
	return 1;
}

int L_createAttributeEx(lua_State *L)
{
	IXML_Attr* attr = NULL;
	int err = IXML_SUCCESS;
	err = ixmlDocument_createAttributeEx(checkdocument(L,1), luaL_checkstring(L,2), &attr);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaAttr(L, attr);
	return 1;
}

int L_getElementsByTagName_Document(lua_State *L)
{
	pushLuaNodeList(L, ixmlDocument_getElementsByTagName(checkdocument(L, 1), luaL_checkstring(L,2)));
	return 1;
}

int L_createElementNSEx(lua_State *L)
{
	IXML_Element* elem = NULL;
	int err = IXML_SUCCESS;
	err = ixmlDocument_createElementNSEx(checkdocument(L,1), luaL_checkstring(L,2), luaL_checkstring(L,3), &elem);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaElement(L, elem);
	return 1;
}

int L_createAttributeNSEx(lua_State *L)
{
	IXML_Attr* attr = NULL;
	int err = IXML_SUCCESS;
	err = ixmlDocument_createAttributeNSEx(checkdocument(L,1), luaL_checkstring(L,2), luaL_checkstring(L,3), &attr);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaAttr(L, attr);
	return 1;
}

int L_getElementsByTagNameNS_Document(lua_State *L)
{
	pushLuaNodeList(L, ixmlDocument_getElementsByTagNameNS(checkdocument(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3)));
	return 1;
}

int L_getElementById(lua_State *L)
{
	pushLuaElement(L, ixmlDocument_getElementById(checkdocument(L, 1), luaL_checkstring(L,2)));
	return 1;
}

int L_importNode(lua_State *L)
{
	IXML_Node* node = NULL;
	int err = IXML_SUCCESS;
	err = ixmlDocument_importNode(checkdocument(L,1), checknode(L,2), lua_toboolean(L,3), &node);
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	pushLuaNode(L, node);
	return 1;
}
