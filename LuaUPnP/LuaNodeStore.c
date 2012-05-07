//#include "LuaIXML.h"
//
//// Utilities for manipulating the linked list of UserData's used to connect 
//// Lua references to the corresponding IXML nodes
//
//
//// Get start node
//// Returns the pointer to the start node, or NULL
//pLuaNode ListGetStart(lua_State *L)
//{
//	pLuaNode result;
//	lua_checkstack(L, 1);
//	lua_getfield(L, LUA_REGISTRYINDEX, STARTNODE);
//	result = lua_touserdata(L, -1);
//	lua_pop(L,1);
//	return result;
//}
//
//// Add node to the linked list
//// the item provided may be a list itself, and any item in that list
//void ListAddNode(lua_State *L, pLuaNode lnode)
//{
//	pLuaNode oldtop;
//	pLuaNode newtop;
//
//	// Get current top
//	//lua_checkstack(L, 1);	GetStart does the check already
//	oldtop = ListGetStart(L);
//
//	// if newtop provided itself is a list, find end of list
//	newtop = lnode;
//	while (newtop->nextnode != NULL) newtop = newtop->nextnode;
//
//	// Connect old list to new list
//	newtop->nextnode = oldtop;
//	if (oldtop != NULL) oldtop->prevnode = newtop;
//
//	// if newtop provided itself is a list, find start of list
//	newtop = lnode;
//	while (newtop->prevnode != NULL) newtop = newtop->prevnode;
//
//	// store
//	lua_pushlightuserdata(L, newtop);
//	lua_setfield(L, LUA_REGISTRYINDEX, STARTNODE);
//}
//
//
//// Free a node
//void ListFreeNode(lua_State *L, IXML_Node node)
//{
//	//TODO: implement the freeing of a list node
//
//}
//
//
