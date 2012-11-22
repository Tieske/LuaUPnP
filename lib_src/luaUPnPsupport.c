#include "luaUPnPsupport.h"

/*
** ===============================================================
** UPnP support
** ===============================================================
*/



/*
** ===============================================================
**  Pushing objects to Lua
** ===============================================================
*/

// Pushes the Device as a userdata on the stack
// returns the userdata, or NULL.
pLuaDevice pushLuaDevice(lua_State *L, UpnpDevice_Handle dev)
{
	pLuaDevice ld = NULL;

	lua_checkstack(L,6);
	// Try and find the node
	lua_getfield(L, LUA_REGISTRYINDEX, LPNP_WTABLE_UPNP);
	lua_pushinteger(L, dev);
	lua_gettable(L, -2);
	if (lua_isnil(L, -1))
	{
		// It is not in the table yet, so we must create a new userdata for this one
		lua_pop(L, 1);									// pop the nil value
		ld = (pLuaDevice)lua_newuserdata(L, sizeof(LuaDevice));		// create userdata (the value)
		if (ld != NULL)
		{
			// Success, so initialize
			ld->device = dev;

			// store in registry userdata reference table
			lua_pushinteger(L, dev);			// the KEY
			lua_pushvalue(L, -2);				// copy userdata as VALUE
			lua_settable(L, -4);				// store KEY/VALUE pair in ref table

			// Set the metatable
			luaL_getmetatable(L, LPNP_DEVICE_MT);
			lua_setmetatable(L, -2);

			// set ctag
			//ixmlNode_setCTag(node, ln);
		}
		else
		{
			lua_pushnil(L);	// failed, so push a nil instead
		}
	}
	else
	{
		// Found it, go get it
		ld = (pLuaDevice)lua_touserdata(L, -1);
	}
	
	lua_remove(L,-2);	// pop the ref table, only the userdata or a nil is left now.
	return ld;
}

// Pushes the Client as a userdata on the stack
// returns the userdata, or NULL.
pLuaClient pushLuaClient(lua_State *L, UpnpClient_Handle client)
{
	pLuaClient lc = NULL;

	lua_checkstack(L,6);
	// Try and find the node
	lua_getfield(L, LUA_REGISTRYINDEX, LPNP_WTABLE_UPNP);
	lua_pushinteger(L, client);
	lua_gettable(L, -2);
	if (lua_isnil(L, -1))
	{
		// It is not in the table yet, so we must create a new userdata for this one
		lua_pop(L, 1);									// pop the nil value
		lc = (pLuaClient)lua_newuserdata(L, sizeof(LuaClient));		// create userdata (the value)
		if (lc != NULL)
		{
			// Success, so initialize
			lc->client = client;

			// store in registry userdata reference table
			lua_pushinteger(L, client);			// the KEY
			lua_pushvalue(L, -2);				// copy userdata as VALUE
			lua_settable(L, -4);				// store KEY/VALUE pair in ref table

			// Set the metatable
			luaL_getmetatable(L, LPNP_CLIENT_MT);
			lua_setmetatable(L, -2);

			// set ctag
			//ixmlNode_setCTag(node, ln);
		}
		else
		{
			lua_pushnil(L);	// failed, so push a nil instead
		}
	}
	else
	{
		// Found it, go get it
		lc = (pLuaClient)lua_touserdata(L, -1);
	}
	
	lua_remove(L,-2);	// pop the ref table, only the userdata or a nil is left now.
	return lc;
}


/*
** ===============================================================
**  Collecting objects from Lua
** ===============================================================
*/

// Get the requested index from the stack and verify it being a proper Device
// throws an error if it fails.
// HARD ERROR
UpnpDevice_Handle checkdevice(lua_State *L, int idx)
{
	pLuaDevice dev;
	luaL_checkudata(L, idx, LPNP_DEVICE_MT);
	if (! UPnPStarted) luaL_error(L, UpnpGetErrorMessage(UPNP_E_FINISH));
	dev = (pLuaDevice)lua_touserdata(L, idx);
	return dev->device;
}

// Get the requested index from the stack and verify it being a proper Device
// returns -1 if it is not a valid device (either no device, or already NULL)
// SOFT ERROR
UpnpDevice_Handle getdevice(lua_State *L, int idx)
{
	// TODO: implement properly, as soft error!!
	return checkdevice(L, idx);
}

// Get the requested index from the stack and verify it being a proper Client
// throws an error if it fails.
// HARD ERROR
UpnpClient_Handle checkclient(lua_State *L, int idx)
{
	pLuaClient client;
	luaL_checkudata(L, idx, LPNP_CLIENT_MT);
	if (! UPnPStarted) luaL_error(L,  UpnpGetErrorMessage(UPNP_E_FINISH));
	client = (pLuaClient)lua_touserdata(L, idx);
	return client->client;
}

// Get the requested index from the stack and verify it being a proper Client
// returns -1 if it is not a valid client (either no client, or already NULL)
// SOFT ERROR
UpnpClient_Handle getclient(lua_State *L, int idx)
{
	return checkclient(L, idx);
}

// Get the Upnp_DescType from Lua
Upnp_DescType checkUpnp_DescType(lua_State *L, int idx)
{
// TODO: replace this code with the OPTION CHECKs lua provides
	const char* etype = NULL;
	etype = luaL_checkstring(L, idx);
	lua_checkstack(L,1);
	if (idx < 0) idx = idx - 1;		// one less because we added a string

	lua_pushstring(L, "URL");
	if (lua_equal(L, idx, -1))
	{
		lua_pop(L,1);
		return UPNPREG_URL_DESC;
	}
	lua_pop(L,1);
	lua_pushstring(L, "FILENAME");
	{
		lua_pop(L,1);
		return UPNPREG_FILENAME_DESC;
	}
	lua_pop(L,1);
	lua_pushstring(L, "STRING");
	{
		lua_pop(L,1);
		return UPNPREG_BUF_DESC;
	}
	lua_pop(L,1);
	// we failed to parse it, error...
	return (Upnp_DescType)luaL_error(L, "Expected a type identifier (string); 'URL', 'FILENAME', or 'STRING'");
}

/*
** ===============================================================
**  Pushing (soft) errors to Lua
** ===============================================================
*/

// Pushes nil + UPnP error, call from a return statement; eg:  
//     return pushUPnPerror(L, errno, soap);
// SOFT ERROR
int pushUPnPerror(lua_State *L, int err, IXML_Document* respdoc)
{
	lua_checkstack(L,3);
	lua_pushnil(L);
	lua_pushstring(L, UpnpGetErrorMessage(err));
	lua_pushinteger(L, err);
	if (err > 0)	// SOAP error, also add document containing error
	{
		pushLuaDocument(L, respdoc);
		return 4;
	}
	return 3;
}

// Transform EventType enum to a string
const char *UpnpGetEventType(int et)
{
	size_t i;

	for (i = 0; i < sizeof (EventTypes) / sizeof (EventTypes[0]); ++i) {
		if (et == EventTypes[i].et) {
			return EventTypes[i].etTypeDesc;
		}
	}

	return "Unknown event type";
}


/*
** ===============================================================
**  tostring method for the device/client userdatas
** ===============================================================
*/

int L_devicetostring(lua_State *L)
{
    char buf[32];
	lua_pushstring(L, "UPnPdevice");			// pushes string with node type
    sprintf(buf, "%p", lua_touserdata(L, 1));	// creates HEX address
    lua_pushfstring(L, "%s: %s", lua_tostring(L, -1), buf);
    return 1;
}
int L_clienttostring(lua_State *L)
{
    char buf[32];
	lua_pushstring(L, "UPnPclient");			// pushes string with node type
    sprintf(buf, "%p", lua_touserdata(L, 1));	// creates HEX address
    lua_pushfstring(L, "%s: %s", lua_tostring(L, -1), buf);
    return 1;
}

/*
** ===============================================================
**  Destroying objects from Lua
** ===============================================================
*/

// GC method for device object
int L_DestroyDevice(lua_State *L)
{
	pLuaDevice dev = (pLuaDevice)lua_touserdata(L, 1);
	if (UPnPStarted)	UpnpUnRegisterRootDevice(dev->device);
	return 0;
}

// GC method for client object
int L_DestroyClient(lua_State *L)
{
	pLuaClient client = (pLuaClient)lua_touserdata(L, 1);
	if (UPnPStarted)	UpnpUnRegisterClient(client->client);
	return 0;
}
