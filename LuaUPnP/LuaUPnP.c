#include "LuaUPnP.h"

/*
** ===============================================================
**  Forward declarations
** ===============================================================
*/


/*
** ===============================================================
**  Core code files
** ===============================================================
*/

#include "LuaIXML.c"


/*
** ===============================================================
** UPnP API
** ===============================================================
*/


/*
** ===============================================================
** Library initialization
** ===============================================================
*/


// Register table for the UPnP functions
static const struct luaL_Reg UPnPfunctions[] = {
	{NULL,NULL}
};


LPNP_API	int luaopen_LuaUPnP(lua_State *L)
{
	/////////////////////////////////////////////
	//  Initialize IXML part
	/////////////////////////////////////////////

	// Create a new metatable for the nodes
	luaL_newmetatable(L, LPNP_NODE_MT);
	// Set it as a metatable to itself
	lua_pushvalue(L, -1); 
	lua_setfield(L, -2, "__index");
	// Add GC method
	lua_pushstring(L, "__gc");
	lua_pushcfunction(L, L_DestroyNode);
	lua_settable(L, -3);
	// add tostring method
	lua_pushstring(L, "__tostring");
	lua_pushcfunction(L, L_tostring);
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

	/////////////////////////////////////////////
	//  Initialize UPnP part
	/////////////////////////////////////////////



	
	
	// Register UPnP functions
	luaL_register(L,"LuaUPnP",UPnPfunctions);


	/////////////////////////////////////////////
	//  Register IXML functions
	/////////////////////////////////////////////

	// Register functions in sub-table of main UPnP table
	lua_pushstring(L, "ixml");
	lua_newtable(L);
	luaL_register(L, NULL, IXMLfunctions);
	lua_settable(L, -3);

	return 1;
};

