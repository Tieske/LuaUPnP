#include "LuaUPnP.h"

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
static pLuaDevice pushLuaDevice(lua_State *L, UpnpDevice_Handle dev)
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
static pLuaClient pushLuaClient(lua_State *L, UpnpClient_Handle client)
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
static UpnpDevice_Handle checkdevice(lua_State *L, int idx)
{
	pLuaDevice dev;
	luaL_checkudata(L, idx, LPNP_DEVICE_MT);
	dev = (pLuaDevice)lua_touserdata(L, idx);
	return dev->device;
}

// Get the requested index from the stack and verify it being a proper Client
// throws an error if it fails.
// HARD ERROR
static UpnpClient_Handle checkclient(lua_State *L, int idx)
{
	pLuaClient client;
	luaL_checkudata(L, idx, LPNP_CLIENT_MT);
	client = (pLuaClient)lua_touserdata(L, idx);
	return client->client;
}

// Get the Upnp_DescType from Lua
static Upnp_DescType checkUpnp_DescType(lua_State *L, int idx)
{
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
/*	switch (err) {
		case UPNP_E_SUCCESS: 
			lua_pushstring(L, "UPNP_E_SUCCESS");
			break;
		case UPNP_E_INVALID_HANDLE: 
			lua_pushstring(L, "UPNP_E_INVALID_HANDLE");
			break;
		case UPNP_E_INVALID_PARAM: 
			lua_pushstring(L, "UPNP_E_INVALID_PARAM");
			break;
		case UPNP_E_OUTOF_HANDLE: 
			lua_pushstring(L, "UPNP_E_OUTOF_HANDLE");
			break;
		case UPNP_E_OUTOF_CONTEXT: 
			lua_pushstring(L, "UPNP_E_OUTOF_CONTEXT");
			break;
		case UPNP_E_OUTOF_MEMORY: 
			lua_pushstring(L, "UPNP_E_OUTOF_MEMORY");
			break;
		case UPNP_E_INIT: 
			lua_pushstring(L, "UPNP_E_INIT");
			break;
		case UPNP_E_BUFFER_TOO_SMALL: 
			lua_pushstring(L, "UPNP_E_BUFFER_TOO_SMALL");
			break;
		case UPNP_E_INVALID_DESC: 
			lua_pushstring(L, "UPNP_E_INVALID_DESC");
			break;
		case UPNP_E_INVALID_URL: 
			lua_pushstring(L, "UPNP_E_INVALID_URL");
			break;
		case UPNP_E_INVALID_SID: 
			lua_pushstring(L, "UPNP_E_INVALID_SID");
			break;
		case UPNP_E_INVALID_DEVICE: 
			lua_pushstring(L, "UPNP_E_INVALID_DEVICE");
			break;
		case UPNP_E_INVALID_SERVICE: 
			lua_pushstring(L, "UPNP_E_INVALID_SERVICE");
			break;
		case UPNP_E_BAD_RESPONSE: 
			lua_pushstring(L, "UPNP_E_BAD_RESPONSE");
			break;
		case UPNP_E_BAD_REQUEST: 
			lua_pushstring(L, "UPNP_E_BAD_REQUEST");
			break;
		case UPNP_E_INVALID_ACTION: 
			lua_pushstring(L, "UPNP_E_INVALID_ACTION");
			break;
		case UPNP_E_FINISH: 
			lua_pushstring(L, "UPNP_E_FINISH");
			break;
		case UPNP_E_INIT_FAILED: 
			lua_pushstring(L, "UPNP_E_INIT_FAILED");
			break;
		case UPNP_E_URL_TOO_BIG: 
			lua_pushstring(L, "UPNP_E_URL_TOO_BIG");
			break;
		case UPNP_E_BAD_HTTPMSG: 
			lua_pushstring(L, "UPNP_E_BAD_HTTPMSG");
			break;
		case UPNP_E_ALREADY_REGISTERED: 
			lua_pushstring(L, "UPNP_E_ALREADY_REGISTERED");
			break;
		case UPNP_E_INVALID_INTERFACE: 
			lua_pushstring(L, "UPNP_E_INVALID_INTERFACE");
			break;
		case UPNP_E_NETWORK_ERROR: 
			lua_pushstring(L, "UPNP_E_NETWORK_ERROR");
			break;
		case UPNP_E_SOCKET_WRITE: 
			lua_pushstring(L, "UPNP_E_SOCKET_WRITE");
			break;
		case UPNP_E_SOCKET_READ: 
			lua_pushstring(L, "UPNP_E_SOCKET_READ");
			break;
		case UPNP_E_SOCKET_BIND: 
			lua_pushstring(L, "UPNP_E_SOCKET_BIND");
			break;
		case UPNP_E_SOCKET_CONNECT: 
			lua_pushstring(L, "UPNP_E_SOCKET_CONNECT");
			break;
		case UPNP_E_OUTOF_SOCKET: 
			lua_pushstring(L, "UPNP_E_OUTOF_SOCKET");
			break;
		case UPNP_E_LISTEN: 
			lua_pushstring(L, "UPNP_E_LISTEN");
			break;
		case UPNP_E_TIMEDOUT: 
			lua_pushstring(L, "UPNP_E_TIMEDOUT");
			break;
		case UPNP_E_SOCKET_ERROR: 
			lua_pushstring(L, "UPNP_E_SOCKET_ERROR");
			break;
		case UPNP_E_FILE_WRITE_ERROR: 
			lua_pushstring(L, "UPNP_E_FILE_WRITE_ERROR");
			break;
		case UPNP_E_CANCELED: 
			lua_pushstring(L, "UPNP_E_CANCELED");
			break;
		case UPNP_E_EVENT_PROTOCOL: 
			lua_pushstring(L, "UPNP_E_EVENT_PROTOCOL");
			break;
		case UPNP_E_SUBSCRIBE_UNACCEPTED: 
			lua_pushstring(L, "UPNP_E_SUBSCRIBE_UNACCEPTED");
			break;
		case UPNP_E_UNSUBSCRIBE_UNACCEPTED: 
			lua_pushstring(L, "UPNP_E_UNSUBSCRIBE_UNACCEPTED");
			break;
		case UPNP_E_NOTIFY_UNACCEPTED: 
			lua_pushstring(L, "UPNP_E_NOTIFY_UNACCEPTED");
			break;
		case UPNP_E_INVALID_ARGUMENT: 
			lua_pushstring(L, "UPNP_E_INVALID_ARGUMENT");
			break;
		case UPNP_E_FILE_NOT_FOUND: 
			lua_pushstring(L, "UPNP_E_FILE_NOT_FOUND");
			break;
		case UPNP_E_FILE_READ_ERROR: 
			lua_pushstring(L, "UPNP_E_FILE_READ_ERROR");
			break;
		case UPNP_E_EXT_NOT_XML: 
			lua_pushstring(L, "UPNP_E_EXT_NOT_XML");
			break;
		case UPNP_E_NO_WEB_SERVER: 
			lua_pushstring(L, "UPNP_E_NO_WEB_SERVER");
			break;
		case UPNP_E_OUTOF_BOUNDS: 
			lua_pushstring(L, "UPNP_E_OUTOF_BOUNDS");
			break;
		case UPNP_E_NOT_FOUND: 
			lua_pushstring(L, "UPNP_E_NOT_FOUND");
			break;
		case UPNP_E_INTERNAL_ERROR: 
			lua_pushstring(L, "UPNP_E_INTERNAL_ERROR");
			break;
		case UPNP_SOAP_E_INVALID_ACTION: 
			lua_pushstring(L, "UPNP_SOAP_E_INVALID_ACTION");
			break;
		case UPNP_SOAP_E_INVALID_ARGS: 
			lua_pushstring(L, "UPNP_SOAP_E_INVALID_ARGS");
			break;
		case UPNP_SOAP_E_OUT_OF_SYNC: 
			lua_pushstring(L, "UPNP_SOAP_E_OUT_OF_SYNC");
			break;
		case UPNP_SOAP_E_INVALID_VAR: 
			lua_pushstring(L, "UPNP_SOAP_E_INVALID_VAR");
			break;
		case UPNP_SOAP_E_ACTION_FAILED: 
			lua_pushstring(L, "UPNP_SOAP_E_ACTION_FAILED");
			break;
		default:
			lua_pushstring(L, "UPNP_UNKNOWN_ERROR");
			break;
	}
*/	lua_pushinteger(L, err);
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
static int L_DestroyDevice(lua_State *L)
{
	pLuaDevice dev = (pLuaDevice)lua_touserdata(L, 1);
	//if (dev->device != NULL)
	UpnpUnRegisterRootDevice(dev->device);
	return 0;
}

// GC method for client object
static int L_DestroyClient(lua_State *L)
{
	pLuaClient client = (pLuaClient)lua_touserdata(L, 1);
	//if (client->client != NULL)
	UpnpUnRegisterClient(client->client);
	return 0;
}
