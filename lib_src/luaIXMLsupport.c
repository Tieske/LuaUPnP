#include "luaIXMLsupport.h"

/*
** ===============================================================
** IXML support
** ===============================================================
*/



/*
** ===============================================================
**  Pushing objects to Lua
** ===============================================================
*/

// Removes the Lua side reference to an IXML node
void clearLuaNode(IXML_Node *node)
{
	pLuaNode ln = NULL;

	if (node != NULL)
	{
		ln = (pLuaNode)ixmlNode_getCTag(node);
		if (ln != NULL)
		{
			// remove cross references
			ln->node = NULL;
			ixmlNode_setCTag(node, NULL);
		}
	}
}

// Pushes the node as a userdata on the stack, or nil if the node is NULL
// returns the userdata, or NULL.
pLuaNode pushLuaNode(lua_State *L, IXML_Node *node)
{
	pLuaNode ln = NULL;

	if (node == NULL)
	{
		lua_pushnil(L);
		return NULL;
	}

	lua_checkstack(L,6);
	// Try and find the node
	lua_getfield(L, LUA_REGISTRYINDEX, LPNP_WTABLE_IXML);
	lua_pushlightuserdata(L, node);
	lua_gettable(L, -2);
	if (lua_isnil(L, -1))
	{
		// It is not in the table yet, so we must create a new userdata for this one
		lua_pop(L, 1);									// pop the nil value
		ln = (pLuaNode)lua_newuserdata(L, sizeof(LuaNode));		// create userdata (the value)
		if (ln != NULL)
		{
			// Success, so initialize
			ln->node = node;

			// store in registry userdata reference table
			lua_pushlightuserdata(L, node);		// the KEY
			lua_pushvalue(L, -2);				// copy userdata as VALUE
			lua_settable(L, -4);				// store KEY/VALUE pair in ref table

			// Set the metatable
			luaL_getmetatable(L, LPNP_NODE_MT);
			lua_setmetatable(L, -2);

			// set ctag
			ixmlNode_setCTag(node, ln);
		}
		else
		{
			lua_pushnil(L);	// failed, so push a nil instead
		}
	}
	else
	{
		// Found it, go get it
		ln = (pLuaNode)lua_touserdata(L, -1);
	}
	
	lua_remove(L,-2);	// pop the ref table, only the userdata or a nil is left now.
	return ln;
}
pLuaNode pushLuaElement(lua_State *L, IXML_Element *elem)
{
	return pushLuaNode(L, (IXML_Node*)elem);
}
pLuaNode pushLuaDocument(lua_State *L, IXML_Document *doc)
{
	return pushLuaNode(L, (IXML_Node*)doc);
}
pLuaNode pushLuaAttr(lua_State *L, IXML_Attr *attr)
{
	return pushLuaNode(L, (IXML_Node*)attr);
}
pLuaNode pushLuaCDATASection(lua_State *L, IXML_CDATASection *cds)
{
	return pushLuaNode(L, (IXML_Node*)cds);
}
// Pushes the nodelist as a table on the stack (array)
// or nil, if the list is empty.
void pushLuaNodeList(lua_State *L, IXML_NodeList *list)
{
	unsigned long l = 0;	// length of list
	unsigned long c;		// counter
	if (list != NULL) 
		l = ixmlNodeList_length(list);
	if (l > 0)
	{
		lua_checkstack(L, 2);
		lua_createtable(L,l,0);
		for (c = 0; c <= (l - 1); c = c + 1) 
		{
			lua_pushinteger(L, c + 1);
			pushLuaNode(L, ixmlNodeList_item(list, c));
			lua_settable(L, -2);
		}
	}
	else
	{
		// Empty list, deliver a nil
		lua_checkstack(L, 1);
		lua_pushnil(L);
	}
}

// Pushes the namednodemap as a table ???? on the stack (array)
// or nil, of the list is empty.
void pushLuaNodeNamedMap(lua_State *L, IXML_NamedNodeMap *nnmap)
{
	unsigned long l = 0;	// length of list
	unsigned long c = 1;		// counter
	if (nnmap == NULL) 
	{
		lua_checkstack(L, 1);
		lua_pushnil(L);
	}
	else
	{
		l = ixmlNamedNodeMap_getLength(nnmap);
		lua_createtable(L,l,0);
		lua_pushinteger(L,l);
		lua_setfield(L,-2, "n");	// set length field in table
		while (c <= l)
		{
			lua_pushinteger(L, c);
			pushLuaNode(L, ixmlNamedNodeMap_item(nnmap, c - 1));
			lua_settable(L, -3);
			c = c + 1;
		}
	}
}


/*
** ===============================================================
**  Collecting objects from Lua
** ===============================================================
*/

// Get the requested index from the stack and verify it being a proper Node
// throws an error if it fails.
// HARD ERROR
IXML_Node* checknode(lua_State *L, int idx)
{
	pLuaNode node;
	luaL_checkudata(L, idx, LPNP_NODE_MT);
	node = (pLuaNode)lua_touserdata(L, idx);
	if (node->node == NULL) luaL_error(L, "Invalid Node (document closed?)");
	return node->node;
}

// Get the requested index from the stack and verify it being a proper Element
// throws an error if it fails.
// HARD ERROR
IXML_Element* checkelement(lua_State *L, int idx)
{
	Nodeptr node = checknode(L, idx);
	if (ixmlNode_getNodeType(node) != eELEMENT_NODE) luaL_error(L, "Wrong node type; expected Element");
	return (IXML_Element*)node;
}
// Get the requested index from the stack and verify it being a proper Document
// throws an error if it fails.
// HARD ERROR
IXML_Document* checkdocument(lua_State *L, int idx)
{
	Nodeptr doc = checknode(L, idx);
	if (ixmlNode_getNodeType(doc) != eDOCUMENT_NODE) luaL_error(L, "Wrong node type; expected Document");
	return (IXML_Document*)doc;
}
// Get the requested index from the stack and verify it being a proper Attribute
// throws an error if it fails.
// HARD ERROR
IXML_Attr* checkattr(lua_State *L, int idx)
{
	Nodeptr attr = checknode(L, idx);
	if (ixmlNode_getNodeType(attr) != eATTRIBUTE_NODE) luaL_error(L, "Wrong node type; expected Attribute");
	return (IXML_Attr*)attr;
}
// Get the requested index from the stack and verify it being a proper CDATASection
// throws an error if it fails.
// HARD ERROR
IXML_CDATASection* checkcdata(lua_State *L, int idx)
{
	Nodeptr cdata = checknode(L, idx);
	if (ixmlNode_getNodeType(cdata) != eCDATA_SECTION_NODE) luaL_error(L, "Wrong node type; expected CDATASection");
	return (IXML_CDATASection*)cdata;
}


/*
** ===============================================================
**  Pushing (soft) errors to Lua
** ===============================================================
*/

// Pushes nil + message, call from a return statement; eg:  
//     return pusherror(L, "Some error description");
// SOFT ERROR
int pusherror(lua_State *L, const char* errorstr)
{
	lua_checkstack(L,2);
	lua_pushnil(L);
	lua_pushstring(L, errorstr);
	return 2;
}

// Pushes nil + IXML error, call from a return statement; eg:  
//     return pushIXMLerror(L, errno);
// SOFT ERROR
int pushIXMLerror(lua_State *L, int err)
{
	lua_checkstack(L,3);
	lua_pushnil(L);
	switch (err) {
		case IXML_INDEX_SIZE_ERR: 
			lua_pushstring(L, "IXML_INDEX_SIZE_ERR");
			break;
		case IXML_DOMSTRING_SIZE_ERR: 
			lua_pushstring(L, "IXML_DOMSTRING_SIZE_ERR");
			break;
		case IXML_HIERARCHY_REQUEST_ERR: 
			lua_pushstring(L, "IXML_HIERARCHY_REQUEST_ERR");
			break;
		case IXML_WRONG_DOCUMENT_ERR: 
			lua_pushstring(L, "IXML_WRONG_DOCUMENT_ERR");
			break;
		case IXML_INVALID_CHARACTER_ERR: 
			lua_pushstring(L, "IXML_INVALID_CHARACTER_ERR");
			break;
		case IXML_NO_DATA_ALLOWED_ERR: 
			lua_pushstring(L, "IXML_NO_DATA_ALLOWED_ERR");
			break;
		case IXML_NO_MODIFICATION_ALLOWED_ERR: 
			lua_pushstring(L, "IXML_NO_MODIFICATION_ALLOWED_ERR");
			break;
		case IXML_NOT_FOUND_ERR: 
			lua_pushstring(L, "IXML_NOT_FOUND_ERR");
			break;
		case IXML_NOT_SUPPORTED_ERR: 
			lua_pushstring(L, "IXML_NOT_SUPPORTED_ERR");
			break;
		case IXML_INUSE_ATTRIBUTE_ERR: 
			lua_pushstring(L, "IXML_INUSE_ATTRIBUTE_ERR");
			break;
		case IXML_INVALID_STATE_ERR: 
			lua_pushstring(L, "IXML_INVALID_STATE_ERR");
			break;
		case IXML_SYNTAX_ERR: 
			lua_pushstring(L, "IXML_SYNTAX_ERR");
			break;
		case IXML_INVALID_MODIFICATION_ERR: 
			lua_pushstring(L, "IXML_INVALID_MODIFICATION_ERR");
			break;
		case IXML_NAMESPACE_ERR: 
			lua_pushstring(L, "IXML_NAMESPACE_ERR");
			break;
		case IXML_INVALID_ACCESS_ERR: 
			lua_pushstring(L, "IXML_INVALID_ACCESS_ERR");
			break;
		case IXML_NO_SUCH_FILE: 
			lua_pushstring(L, "IXML_NO_SUCH_FILE");
			break;
		case IXML_INSUFFICIENT_MEMORY: 
			lua_pushstring(L, "IXML_INSUFFICIENT_MEMORY");
			break;
		case IXML_FILE_DONE: 
			lua_pushstring(L, "IXML_FILE_DONE");
			break;
		case IXML_INVALID_PARAMETER: 
			lua_pushstring(L, "IXML_INVALID_PARAMETER");
			break;
		case IXML_FAILED: 
			lua_pushstring(L, "IXML_FAILED");
			break;
		case IXML_INVALID_ITEM_NUMBER: 
			lua_pushstring(L, "IXML_INVALID_ITEM_NUMBER");
			break;
		default:
			lua_pushstring(L, "IXML_UNKNOWN_ERROR");
			break;
	}
	lua_pushinteger(L, err);
	return 3;
}


/*
** ===============================================================
**  tostring method for the node userdatas
** ===============================================================
*/

int L_tostring(lua_State *L)
{
    char buf[32];
	L_getNodeType(L);			// pushes string with node type
    sprintf(buf, "%p", lua_touserdata(L, 1));	// creates HEX address
    lua_pushfstring(L, "%s: %s", lua_tostring(L, -1), buf);
    return 1;
}

/*
** ===============================================================
**  Destroying objects from Lua
** ===============================================================
*/

// Will be called for each Node freed from IXML side
void FreeCallBack(IXML_Node* node)
{
	pLuaNode ln;
	if (node != NULL)
	{
		ln = (pLuaNode)ixmlNode_getCTag(node);
		if (ln != NULL)
		{
			// There is a Lua reference, so must clear that so document
			// will be considered closed
			ln->node = NULL;
		}
	}
}

// GC method for object
int L_DestroyNode(lua_State *L)
{
	pLuaNode node = (pLuaNode)lua_touserdata(L, 1);
	if (node->node != NULL)
	{
		if (node->node->ctag == node)
		{
			// custom tag points to this record (should be!)
			node->node->ctag = NULL;
			if (ixmlNode_getOwnerDocument(node->node) == NULL)
			{
				// there is no owner, so it is going out-of-scope and
				// we should free it now.
				switch (ixmlNode_getNodeType(node->node)) {
					case eATTRIBUTE_NODE: 
						ixmlAttr_free((IXML_Attr*)node->node);
						break;
					case eDOCUMENT_NODE:
						ixmlDocument_free((IXML_Document*)node->node);
						break;
					case eCDATA_SECTION_NODE:
						ixmlCDATASection_free((IXML_CDATASection*)node->node);
						break;
					case eELEMENT_NODE:
						ixmlElement_free((IXML_Element*)node->node);
						break;
					default:
						ixmlNode_free(node->node);
				}
			}
		}
		else
		{
			// shouldn't be, something is wrong, leave it for now
		}
	}
	return 0;
}
