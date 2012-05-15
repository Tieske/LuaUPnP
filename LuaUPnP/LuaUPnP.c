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
#include "UPnPsupport.c"

/*
** ===============================================================
**  UPnP API: Initialization & Registration
** ===============================================================
*/

static int L_UpnpInit(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpFinish(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpGetServerPort(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpGetServerIpAddress(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpRegisterClient(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpRegisterRootDevice(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpRegisterRootDevice2(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpUnRegisterClient(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpUnRegisterRootDevice(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpSetMaxContentLength(lua_State *L)
{
	// TODO: implement
}

/*
** ===============================================================
**  UPnP API: Discovery
** ===============================================================
*/

static int L_UpnpSearchAsync(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpSendAdvertisement(lua_State *L)
{
	// TODO: implement
}


/*
** ===============================================================
**  UPnP API: Control
** ===============================================================
*/

static int L_UpnpGetServiceVarStatus(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpGetServiceVarStatusAsync(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpSendAction(lua_State *L)
{
	// TODO: implement, combine with EX version
}

static int L_UpnpSendActionEx(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpSendActionAsync(lua_State *L)
{
	// TODO: implement, combine with Ex version
}

static int L_UpnpSendActionExAsync(lua_State *L)
{
	// TODO: implement
}


/*
** ===============================================================
**  UPnP API: Eventing
** ===============================================================
*/

static int L_UpnpAcceptSubscription(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpAcceptSubscriptionExt(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpNotify(lua_State *L)
{
	// TODO: implement, combine with Ext
}

static int L_UpnpNotifyExt(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpRenewSubscription(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpRenewSubscriptionAsync(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpSetMaxSubscriptions(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpSetMaxSubscriptionTimeOut(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpSubscribe(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpSubscribeAsync(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpUnSubscribe(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpUnSubscribeAsync(lua_State *L)
{
	// TODO: implement
}


/*
** ===============================================================
**  UPnP API: Control point HTTP
** ===============================================================
*/

static int L_UpnpDownloadUrlItem(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpOpenHttpGet(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpOpenHttpGetProxy(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpOpenHttpGetEx(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpReadHttpGet(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpHttpGetProgress(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpCancelHttpGet(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpCloseHttpGet(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpOpenHttpPost(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpWriteHttpPost(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpCloseHttpPost(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpDownloadXmlDoc(lua_State *L)
{
	// TODO: implement
}

/*
** ===============================================================
**  UPnP API: Web server
** ===============================================================
*/

static int L_UpnpSetWebServerRootDir(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpSetVirtualDirCallbacks(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpEnableWebserver(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpIsWebserverEnabled(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpAddVirtualDir(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpRemoveVirtualDir(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpRemoveAllVirtualDirs(lua_State *L)
{
	// TODO: implement
}

/*
** ===============================================================
**  UPnP API: utils/tools
** ===============================================================
*/

static int L_UpnpResolveURL(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpMakeAction(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpAddToAction(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpMakeActionResponse(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpAddToActionResponse(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpAddToPropertySet(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpCreatePropertySet(lua_State *L)
{
	// TODO: implement
}

static int L_UpnpGetErrorMessage(lua_State *L)
{
	// TODO: implement
}



/*
** ===============================================================
** Library initialization
** ===============================================================
*/


// Register table for the UPnP functions
static const struct luaL_Reg UPnPfunctions[] = {
	// Initialization & Registration
	{"Init",L_UpnpInit},
	{"Finish",L_UpnpFinish},
	{"GetServerPort",L_UpnpGetServerPort},
	{"GetServerIpAddress",L_UpnpGetServerIpAddress},
	{"RegisterClient",L_UpnpRegisterClient},
	{"RegisterRootDevice",L_UpnpRegisterRootDevice},
	{"RegisterRootDevice2",L_UpnpRegisterRootDevice2},
	{"UnRegisterClient",L_UpnpUnRegisterClient},
	{"UnRegisterRootDevice",L_UpnpUnRegisterRootDevice},
	{"SetMaxContentLength",L_UpnpSetMaxContentLength},
	// Discovery
	{"SearchAsync",L_UpnpSearchAsync},
	{"SendAdvertisement",L_UpnpSendAdvertisement},
	// Control
	{"GetServiceVarStatus",L_UpnpGetServiceVarStatus},
	{"GetServiceVarAsync",L_UpnpGetServiceVarStatusAsync},
	{"SendAction",L_UpnpSendAction},
	{"SendActionEx",L_UpnpSendActionEx},
	{"SendActionAsync",L_UpnpSendActionAsync},
	{"SendActionExAsync",L_UpnpSendActionExAsync},
	// Eventing
	{"AcceptSubscription",L_UpnpAcceptSubscription},
	{"AcceptSubscriptionExt",L_UpnpAcceptSubscriptionExt},
	{"Notify",L_UpnpNotify},
	{"NotifyExt",L_UpnpNotifyExt},
	{"RenewSubscription",L_UpnpRenewSubscription},
	{"RenewSubscriptionAsync",L_UpnpRenewSubscriptionAsync},
	{"SetMaxSubscriptions",L_UpnpSetMaxSubscriptions},
	{"SetMaxSubscriptionTimeOut",L_UpnpSetMaxSubscriptionTimeOut},
	{"Subscribe",L_UpnpSubscribe},
	{"SubscribeAsync",L_UpnpSubscribeAsync},
	{"UnSubscribe",L_UpnpUnSubscribe},
	{"UnSubscribeAsync",L_UpnpUnSubscribeAsync},

	{NULL,NULL}
};

// Register table for the UPnP device methods
static const struct luaL_Reg UPnPDeviceMethods[] = {
	// Initialization & Registration
	{"UnRegisterRootDevice",L_UpnpUnRegisterRootDevice},
	// Discovery
	{"SendAdvertisement",L_UpnpSendAdvertisement},
	// Eventing
	{"AcceptSubscription",L_UpnpAcceptSubscription},
	{"AcceptSubscriptionExt",L_UpnpAcceptSubscriptionExt},
	{"Notify",L_UpnpNotify},
	{"NotifyExt",L_UpnpNotifyExt},
	{"SetMaxSubscriptions",L_UpnpSetMaxSubscriptions},
	{"SetMaxSubscriptionTimeOut",L_UpnpSetMaxSubscriptionTimeOut},

	{NULL,NULL}
};

// Register table for the UPnP client methods
static const struct luaL_Reg UPnPClientMethods[] = {
	// Initialization & Registration
	{"UnRegisterClient",L_UpnpUnRegisterClient},
	// Discovery
	{"SearchAsync",L_UpnpSearchAsync},
	// Control
	{"GetServiceVarStatus",L_UpnpGetServiceVarStatus},
	{"GetServiceVarAsync",L_UpnpGetServiceVarStatusAsync},
	{"SendAction",L_UpnpSendAction},
	{"SendActionEx",L_UpnpSendActionEx},
	{"SendActionAsync",L_UpnpSendActionAsync},
	{"SendActionExAsync",L_UpnpSendActionExAsync},
	// Eventing
	{"RenewSubscription",L_UpnpRenewSubscription},
	{"RenewSubscriptionAsync",L_UpnpRenewSubscriptionAsync},
	{"Subscribe",L_UpnpSubscribe},
	{"SubscribeAsync",L_UpnpSubscribeAsync},
	{"UnSubscribe",L_UpnpUnSubscribe},
	{"UnSubscribeAsync",L_UpnpUnSubscribeAsync},
	// Control point HTTP
	{"DownloadUrlItem",L_UpnpDownloadUrlItem},
	{"OpenHttpGet",L_UpnpOpenHttpGet},
	{"OpenHttpGetProxy",L_UpnpOpenHttpGetProxy},
	{"OpenHttpGetEx",L_UpnpOpenHttpGetEx},
	{"ReadHttpGet",L_UpnpReadHttpGet},
	{"HttpGetProgress",L_UpnpHttpGetProgress},
	{"CancelHttpGet",L_UpnpCancelHttpGet},
	{"CloseHttpGet",L_UpnpCloseHttpGet},
	{"OpenHttpPost",L_UpnpOpenHttpPost},
	{"WriteHttpPost",L_UpnpWriteHttpPost},
	{"CloseHttpPost",L_UpnpCloseHttpPost},
	{"DownloadXmlDoc",L_UpnpDownloadXmlDoc},

	{NULL,NULL}
};

// Register table for the UPnP Http methods
static const struct luaL_Reg UPnPHttp[] = {
	// Control point HTTP
	{"DownloadUrlItem",L_UpnpDownloadUrlItem},
	{"OpenGet",L_UpnpOpenHttpGet},
	{"OpenGetProxy",L_UpnpOpenHttpGetProxy},
	{"OpenGetEx",L_UpnpOpenHttpGetEx},
	{"ReadGet",L_UpnpReadHttpGet},
	{"HttpGetProgress",L_UpnpHttpGetProgress},
	{"CancelGet",L_UpnpCancelHttpGet},
	{"CloseGet",L_UpnpCloseHttpGet},
	{"OpenPost",L_UpnpOpenHttpPost},
	{"WritePost",L_UpnpWriteHttpPost},
	{"ClosePost",L_UpnpCloseHttpPost},
	{"DownloadXmlDoc",L_UpnpDownloadXmlDoc},
	{NULL,NULL}
};

// Register table for the UPnP Webserver methods
static const struct luaL_Reg UPnPWeb[] = {
	{"SetRootDir",L_UpnpSetWebServerRootDir},
	{"SetVirtualDirCallbacks",L_UpnpSetVirtualDirCallbacks},
	{"Enable",L_UpnpEnableWebserver},
	{"IsEnbaled",L_UpnpIsWebserverEnabled},
	{"AddVirtualDir",L_UpnpAddVirtualDir},
	{"RemoveVirtualDir",L_UpnpRemoveVirtualDir},
	{"RemoveAllVirtualDirs",L_UpnpRemoveAllVirtualDirs},
	{NULL,NULL}
};

// Register table for the UPnP util/tool methods
static const struct luaL_Reg UPnPUtil[] = {
	{"ResolveURL",L_UpnpResolveURL},
	{"MakeAction",L_UpnpMakeAction},
	{"AddToAction",L_UpnpAddToAction},
	{"MakeActionResponse",L_UpnpMakeActionResponse},
	{"AddToActionResponse",L_UpnpAddToActionResponse},
	{"AddToPropertySet",L_UpnpAddToPropertySet},
	{"CreatePropertySet",L_UpnpCreatePropertySet},
	{"GetErrorMessage",L_UpnpGetErrorMessage},
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


	/* setup Device */

	// Create a new metatable for the devices
	luaL_newmetatable(L, LPNP_DEVICE_MT);
	// Set it as a metatable to itself
	lua_pushvalue(L, -1); 
	lua_setfield(L, -2, "__index");
	// Add GC method
	lua_pushstring(L, "__gc");
	lua_pushcfunction(L, L_DestroyDevice);
	lua_settable(L, -3);
	// add tostring method
	lua_pushstring(L, "__tostring");
	lua_pushcfunction(L, L_devicetostring);
	lua_settable(L, -3);
	// Register the methods of the object
	luaL_register(L, NULL, UPnPDeviceMethods);

	/* setup Client/Controlpoint */

	// Create a new metatable for the devices
	luaL_newmetatable(L, LPNP_CLIENT_MT);
	// Set it as a metatable to itself
	lua_pushvalue(L, -1); 
	lua_setfield(L, -2, "__index");
	// Add GC method
	lua_pushstring(L, "__gc");
	lua_pushcfunction(L, L_DestroyClient);
	lua_settable(L, -3);
	// add tostring method
	lua_pushstring(L, "__tostring");
	lua_pushcfunction(L, L_clienttostring);
	lua_settable(L, -3);
	// Register the methods of the object
	luaL_register(L, NULL, UPnPClientMethods);

	// Create reference table for the userdatas (devices and clients/controlpoints)
	lua_newtable(L);				// table
	lua_newtable(L);				// meta table
	lua_pushstring(L,"v");			// weak values
	lua_setfield(L, -2, "__mode");	// metatable weak values 'mode'
	lua_setmetatable(L, -2);		// set the meta table
	lua_setfield(L, LUA_REGISTRYINDEX, LPNP_WTABLE_UPNP);	// store in registry

	// Register UPnP functions
	luaL_register(L,"LuaUPnP",UPnPfunctions);

	/////////////////////////////////////////////
	//  Register Webserver, HTTP and util functions
	/////////////////////////////////////////////

	// Register WebServer functions in sub-table of main UPnP table
	lua_pushstring(L, "web");
	lua_newtable(L);
	luaL_register(L, NULL, UPnPWeb);
	lua_settable(L, -3);
	// Register Http functions in sub-table of main UPnP table
	lua_pushstring(L, "http");
	lua_newtable(L);
	luaL_register(L, NULL, UPnPHttp);
	lua_settable(L, -3);
	// Register Util/Tools functions in sub-table of main UPnP table
	lua_pushstring(L, "util");
	lua_newtable(L);
	luaL_register(L, NULL, UPnPUtil);
	lua_settable(L, -3);

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

