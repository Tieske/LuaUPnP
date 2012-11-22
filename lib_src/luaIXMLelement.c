#include "element.h"

/*
** ===============================================================
**  implementation of the Element interface
** ===============================================================
*/

int L_getTagName(lua_State *L)
{
	lua_pushstring(L, ixmlElement_getTagName(checkelement(L, 1)));
	return 1;
}

int L_getAttribute(lua_State *L)
{
	lua_pushstring(L, ixmlElement_getAttribute(checkelement(L, 1), luaL_checkstring(L,2)));
	return 1;
}

int L_setAttribute(lua_State *L)
{
	int err = ixmlElement_setAttribute(checkelement(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3));
	if (err != IXML_SUCCESS) return pushIXMLerror(L,err);
	lua_pushinteger(L,1);
	return 1;
}

int L_removeAttribute(lua_State *L)
{
	int err = ixmlElement_removeAttribute(checkelement(L, 1), luaL_checkstring(L,2));
	if (err != IXML_SUCCESS) return pushIXMLerror(L,err);
	lua_pushinteger(L,1);
	return 1;
}

int L_getAttributeNode(lua_State *L)
{
	IXML_Attr *attr = ixmlElement_getAttributeNode(checkelement(L, 1), luaL_checkstring(L,2));
	if (attr == NULL)
		lua_pushnil(L);
	else
		pushLuaAttr(L, attr);
	return 1;
}

int L_setAttributeNode(lua_State *L)
{
	IXML_Attr *oldattr;
	int err = ixmlElement_setAttributeNode(checkelement(L, 1), checkattr(L, 2), &oldattr);
	if (err != IXML_SUCCESS) return pushIXMLerror(L,err);
	pushLuaAttr(L, oldattr);
	return 1;
}

int L_removeAttributeNode(lua_State *L)
{
	IXML_Attr *oldattr;
	int err = ixmlElement_removeAttributeNode(checkelement(L, 1), checkattr(L, 2), &oldattr);
	if (err != IXML_SUCCESS) return pushIXMLerror(L,err);
	pushLuaAttr(L, oldattr);
	return 1;
}

int L_getElementsByTagName_Element(lua_State *L)
{
	pushLuaNodeList(L, ixmlElement_getElementsByTagName(checkelement(L, 1), luaL_checkstring(L,2)));
	return 1;
}

int L_getAttributeNS(lua_State *L)
{
	lua_pushstring(L, ixmlElement_getAttributeNS(checkelement(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3)));
	return 1;
}

int L_setAttributeNS(lua_State *L)
{
	int err = ixmlElement_setAttributeNS(checkelement(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3), luaL_checkstring(L,4));
	if (err != IXML_SUCCESS) return pushIXMLerror(L,err);
	lua_pushinteger(L,1);
	return 1;
}

int L_removeAttributeNS(lua_State *L)
{
	int err = ixmlElement_removeAttributeNS(checkelement(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3));
	if (err != IXML_SUCCESS) return pushIXMLerror(L,err);
	lua_pushinteger(L,1);
	return 1;
}

int L_getAttributeNodeNS(lua_State *L)
{
	IXML_Attr *attr = ixmlElement_getAttributeNodeNS(checkelement(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3));
	if (attr == NULL)
		lua_pushnil(L);
	else
		pushLuaAttr(L, attr);
	return 1;
}

int L_setAttributeNodeNS(lua_State *L)
{
	IXML_Attr *oldattr;
	int err = ixmlElement_setAttributeNodeNS(checkelement(L, 1), checkattr(L, 2), &oldattr);
	if (err != IXML_SUCCESS) return pushIXMLerror(L,err);
	pushLuaAttr(L, oldattr);
	return 1;
}

int L_getElementsByTagNameNS_Element(lua_State *L)
{
	pushLuaNodeList(L, ixmlElement_getElementsByTagNameNS(checkelement(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3)));
	return 1;
}

int L_hasAttribute(lua_State *L)
{
	lua_pushboolean(L, ixmlElement_hasAttribute(checkelement(L,1), luaL_checkstring(L,2)));
	return 1;
}

int L_hasAttributeNS(lua_State *L)
{
	lua_pushboolean(L, ixmlElement_hasAttributeNS(checkelement(L,1), luaL_checkstring(L,2), luaL_checkstring(L,3)));
	return 1;
}
