#include "node.h"

/*
** ===============================================================
**  implementation of the Node interface
** ===============================================================
*/

int L_getNodeName(lua_State *L)
{
	lua_pushstring(L, ixmlNode_getNodeName(checknode(L, 1)));
	return 1;
}

int L_getNodeValue(lua_State *L)
{
	lua_pushstring(L, ixmlNode_getNodeValue(checknode(L, 1)));
	return 1;
}

int L_setNodeValue(lua_State *L)
{
	int err = IXML_SUCCESS;
	err = ixmlNode_setNodeValue(checknode(L, 1), luaL_checkstring(L, 2));
	if (err != IXML_SUCCESS) return pushIXMLerror(L, err);
	lua_pushinteger(L, 1);
	return 1;
}

int L_getNodeType(lua_State *L)
{
	switch (ixmlNode_getNodeType(checknode(L, 1))) {
		case eELEMENT_NODE: {
			lua_pushstring(L, "ELEMENT_NODE");
			break; }
		case eATTRIBUTE_NODE: {
			lua_pushstring(L, "ATTRIBUTE_NODE");
			break; }
		case eTEXT_NODE: {
			lua_pushstring(L, "TEXT_NODE");
			break; }
		case eCDATA_SECTION_NODE: {
			lua_pushstring(L, "CDATA_SECTION_NODE");
			break; }
		case eENTITY_REFERENCE_NODE: {
			lua_pushstring(L, "ENTITY_REFERENCE_NODE");
			break; }
		case eENTITY_NODE: {
			lua_pushstring(L, "ENTITY_NODE");
			break; }
		case ePROCESSING_INSTRUCTION_NODE: {
			lua_pushstring(L, "PROCESSING_INSTRUCTION_NODE");
			break; }
		case eCOMMENT_NODE: {
			lua_pushstring(L, "COMMENT_NODE");
			break; }
		case eDOCUMENT_NODE: {
			lua_pushstring(L, "DOCUMENT_NODE");
			break; }
		case eDOCUMENT_TYPE_NODE: {
			lua_pushstring(L, "DOCUMENT_TYPE_NODE");
			break; }
		case eDOCUMENT_FRAGMENT_NODE: {
			lua_pushstring(L, "DOCUMENT_FRAGMENT_NODE");
			break; }
		case eNOTATION_NODE: {
			lua_pushstring(L, "NOTATION_NODE");
			break; }
		default : {
			lua_pushstring(L, "INVALID_NODE");
			break; }
	}
	return 1;
}

int L_getParentNode(lua_State *L)
{
	pushLuaNode(L, ixmlNode_getParentNode(checknode(L, 1)));
	return 1;
}

int L_getChildNodes(lua_State *L)
{
	pushLuaNodeList(L, ixmlNode_getChildNodes(checknode(L, 1)));
	return 1;
}

int L_getFirstChild(lua_State *L)
{
	pushLuaNode(L, ixmlNode_getFirstChild(checknode(L, 1)));
	return 1;
}

int L_getLastChild(lua_State *L)
{
	pushLuaNode(L, ixmlNode_getLastChild(checknode(L, 1)));
	return 1;
}

int L_getPreviousSibling(lua_State *L)
{
	pushLuaNode(L, ixmlNode_getPreviousSibling(checknode(L, 1)));
	return 1;
}

int L_getNextSibling(lua_State *L)
{
	pushLuaNode(L, ixmlNode_getNextSibling(checknode(L, 1)));
	return 1;
}

int L_getAttributes(lua_State *L)
{
	pushLuaNodeNamedMap(L, ixmlNode_getAttributes(checknode(L, 1)));
	return 1;
}

int L_getOwnerDocument(lua_State *L)
{
	pushLuaDocument(L, ixmlNode_getOwnerDocument(checknode(L, 1)));
	return 1;
}

int L_getNameSpaceURI(lua_State *L)
{
	const DOMString nsuri = ixmlNode_getNamespaceURI(checknode(L, 1));
	if (nsuri != NULL)
		lua_pushstring(L, nsuri);
	else
		lua_pushnil(L);
	return 1;
}

int L_getPrefix(lua_State *L)
{
	const DOMString prefix = ixmlNode_getPrefix(checknode(L, 1));
	if (prefix != NULL)
		lua_pushstring(L, prefix);
	else
		lua_pushnil(L);
	return 1;
}

int L_getLocalName(lua_State *L)
{
	const DOMString local = ixmlNode_getLocalName(checknode(L, 1));
	if (local != NULL)
		lua_pushstring(L, local);
	else
		lua_pushnil(L);
	return 1;
}

int L_insertBefore(lua_State *L)
{
	IXML_Node* addtonode = checknode(L, 1);
	IXML_Node* newchild = checknode(L, 2);
	IXML_Node* beforechild = NULL;
	int result;
	if (lua_isnil(L,3)) 
		result = ixmlNode_insertBefore(addtonode, newchild, NULL);
	else
		result = ixmlNode_insertBefore(addtonode, newchild, beforechild);
	if (result != IXML_SUCCESS)	pushIXMLerror(L, result);
	lua_pushinteger(L, 1);
	return 1;
}

int L_replaceChild(lua_State *L)
{
	IXML_Node* ret = NULL;
	int result = IXML_SUCCESS;
	result = ixmlNode_replaceChild(checknode(L, 1), checknode(L, 2), checknode(L, 3), &ret);
	if (result != IXML_SUCCESS)	pushIXMLerror(L, result);
	pushLuaNode(L, ret);
	return 1;
}

int L_removeChild(lua_State *L)
{
	IXML_Node* ret = NULL;
	int result = IXML_SUCCESS;
	result = ixmlNode_removeChild(checknode(L, 1), checknode(L, 2), &ret);
	if (result != IXML_SUCCESS)	pushIXMLerror(L, result);
	pushLuaNode(L, ret);
	return 1;
}

int L_appendChild(lua_State *L)
{
	IXML_Node* addtonode = checknode(L, 1);
	IXML_Node* newchild = checknode(L, 2);
	int result;
	result = ixmlNode_appendChild(addtonode, newchild);
	if (result != IXML_SUCCESS)	pushIXMLerror(L, result);
	lua_pushinteger(L, 1);
	return 1;
}

int L_hasChildNodes(lua_State *L)
{
	if (ixmlNode_hasChildNodes(checknode(L,1)) == TRUE)
		lua_pushboolean(L, TRUE);
	else
		lua_pushboolean(L, FALSE);
	return 1;
}

int L_cloneNode(lua_State *L)
{
	pushLuaNode(L, ixmlNode_cloneNode(checknode(L,1), lua_toboolean(L,2)));
	return 1;
}

int L_hasAttributes(lua_State *L)
{
	lua_pushboolean(L, ixmlNode_hasAttributes(checknode(L,1)));
	return 1;
}

/*
** ===============================================================
**  In addition to the interface, an node-child iterator
** ===============================================================
*/

// iterator closure
int L_childIter(lua_State *L)
{
	pLuaNode node = (pLuaNode)lua_touserdata(L,2);
	if (node == NULL)
		node = pushLuaNode(L, ixmlNode_getFirstChild(((pLuaNode)lua_touserdata(L,1))->node));
	else
		node = pushLuaNode(L, ixmlNode_getNextSibling(node->node));
	return 1;
}

// iterator factory
int L_children(lua_State *L)
{
	checknode(L,1);
	lua_settop(L, 1);		// remove extra values
	lua_pushcfunction(L, &L_childIter);	// 1st value for iterator craetion, include the 1 upvalue
	lua_pushvalue(L, 1);	// duplicate node, 2nd value for iterator creation
	//lua_pushnil(L);			// initial value for iterator (3rd value)
	//return 3;
	return 2;
}