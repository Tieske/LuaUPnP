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
**  UPnP API: Callbacks
** ===============================================================
*/
#include "darksidesync_aux.c"
#include "UPnPcallback.c"

static int LuaCallback(Upnp_EventType EventType, const void *Event, void *Cookie)
{
	int result;
	switch ( EventType )
	{
		/* SSDP Stuff */
		case UPNP_DISCOVERY_ADVERTISEMENT_ALIVE:
		case UPNP_DISCOVERY_SEARCH_RESULT: 
		case UPNP_DISCOVERY_SEARCH_TIMEOUT:
		case UPNP_DISCOVERY_ADVERTISEMENT_BYEBYE: {
			result = deliverUpnpDiscovery(EventType, (UpnpDiscovery *)Event, Cookie);
			break;
		}
		/* SOAP Stuff */
		case UPNP_CONTROL_ACTION_COMPLETE: {
			result = deliverUpnpActionComplete(EventType, (UpnpActionComplete *)Event, Cookie);
			break;
		}
		case UPNP_CONTROL_GET_VAR_COMPLETE:	{
			result = deliverUpnpStateVarComplete(EventType, (UpnpStateVarComplete *)Event, Cookie);
			break;
		}
		/* GENA Stuff */
		case UPNP_EVENT_RECEIVED: {
			result = deliverUpnpEvent(EventType, (UpnpEvent *)Event, Cookie);
			break;
		}
		case UPNP_EVENT_SUBSCRIBE_COMPLETE:
		case UPNP_EVENT_UNSUBSCRIBE_COMPLETE:
		case UPNP_EVENT_RENEWAL_COMPLETE:
		case UPNP_EVENT_AUTORENEWAL_FAILED:
		case UPNP_EVENT_SUBSCRIPTION_EXPIRED: {
			result = deliverUpnpEventSubscribe(EventType, (UpnpEventSubscribe *)Event, Cookie);
			break;
		}
		/* Device events */
		case UPNP_EVENT_SUBSCRIPTION_REQUEST: {
			result = deliverUpnpSubscriptionRequest(EventType, (UpnpSubscriptionRequest *)Event, Cookie);
			break;
		}
		case UPNP_CONTROL_GET_VAR_REQUEST: {
			result = deliverUpnpStateVarRequest(EventType, (UpnpStateVarRequest *)Event, Cookie);
			break;
		}
		case UPNP_CONTROL_ACTION_REQUEST: {
			result = deliverUpnpActionRequest(EventType, (UpnpActionRequest *)Event, Cookie);
			break;
		}
	}
	return result;
}


/*
** ===============================================================
**  UPnP API: Initialization & Registration
** ===============================================================
*/

// Cancel method to be provide to DSS
// when called, then DSS is shutting down, so we must also shut down
void DSS_cancel(void* utilid, void* pData)
{
	UpnpFinish();					// stop UPnP threads
	DSS_shutdown(NULL, utilid);		// unregister myself with DSS
};

static int L_UpnpInit(lua_State *L)
{
	const char* ipaddr = NULL;
	unsigned short port = 0;
	int result = UPNP_E_SUCCESS;

	// Check parameters
	luaL_checktype(L, 1, LUA_TFUNCTION);
	if (lua_gettop(L) > 1) ipaddr = luaL_checkstring(L, 2);
	if (lua_gettop(L) > 2) port = (unsigned short)luaL_checkint(L,3);

	// Store the callback function
	lua_settop(L, 1);
	lua_setfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);

	result = UpnpInit(ipaddr, port);

	lua_checkstack(L,3);
	if (result == UPNP_E_SUCCESS)	
	{
		lua_pushinteger(L, 1);	// push 1 as positive result
		return 1;
	}
	// report error
	return pushUPnPerror(L, result, NULL);
}

static int L_UpnpFinish(lua_State *L)
{
	int result = UPNP_E_SUCCESS;

	result = UpnpFinish();		// stop UPnP

	lua_checkstack(L,3);
	if (result == UPNP_E_SUCCESS)	
	{
		// clear callback function
		lua_pushnil(L);
		lua_setfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);

		lua_pushinteger(L, 1);	// push 1 as positive result
		return 1;
	}
	// report error
	return pushUPnPerror(L, result, NULL);
}

static int L_UpnpGetServerPort(lua_State *L)
{
	lua_pushinteger(L, (int)UpnpGetServerPort());
	return 1;
}

static int L_UpnpGetServerIpAddress(lua_State *L)
{
	lua_pushstring(L, UpnpGetServerIpAddress());
	return 1;
}

static int L_UpnpRegisterClient(lua_State *L)
{
	int result = UPNP_E_SUCCESS;
	UpnpClient_Handle handle = 0;
	pLuaClient lc;
	result = UpnpRegisterClient(&LuaCallback, DSS_getutilid(L), &handle);
	if (result == UPNP_E_SUCCESS)
	{
		lc = pushLuaClient(L, handle);
		if (lc != NULL) return 1;		// success
		// failure, so unregister again
		result = UpnpUnRegisterClient(handle);
		// nil is already present on stack, add error text
		lua_pushstring(L, "LuaUPnP; Failed to create client userdata, out of memory?");
		return 2;
	}
	// report error
	return pushUPnPerror(L, result, NULL);
}

static int L_UpnpRegisterRootDevice(lua_State *L)
{
	int result = UPNP_E_SUCCESS;
	UpnpDevice_Handle handle = 0;
	pLuaDevice ld;
	result = UpnpRegisterRootDevice(luaL_checkstring(L,1), &LuaCallback, DSS_getutilid(L), &handle);
	if (result == UPNP_E_SUCCESS)
	{
		ld = pushLuaDevice(L, handle);
		if (ld != NULL) return 1;		// success
		// failure, so unregister again
		result = UpnpUnRegisterRootDevice(handle);
		// nil is already present on stack, add error text
		lua_pushstring(L, "LuaUPnP; Failed to create device userdata, out of memory?");
		return 2;
	}
	// report error
	return pushUPnPerror(L, result, NULL);
}

static int L_UpnpRegisterRootDevice2(lua_State *L)
{
	int result = UPNP_E_SUCCESS;
	UpnpDevice_Handle handle = 0;
	pLuaDevice ld;
	size_t slen;
	const char* str = luaL_checklstring(L, 2, &slen);
	result = UpnpRegisterRootDevice2(checkUpnp_DescType(L, 1), str, slen, lua_toboolean(L, 3), &LuaCallback, DSS_getutilid(L), &handle);
	if (result == UPNP_E_SUCCESS)
	{
		ld = pushLuaDevice(L, handle);
		if (ld != NULL) return 1;		// success
		// failure, so unregister again
		result = UpnpUnRegisterRootDevice(handle);
		// nil is already present on stack, add error text
		lua_pushstring(L, "LuaUPnP; Failed to create device userdata, out of memory?");
		return 2;
	}
	// report error
	return pushUPnPerror(L, result, NULL);
}

static int L_UpnpUnRegisterClient(lua_State *L)
{
	int result = UpnpUnRegisterClient(checkclient(L, 1));
	if (result != UPNP_E_SUCCESS) return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpUnRegisterRootDevice(lua_State *L)
{
	int result = UpnpUnRegisterRootDevice(checkdevice(L, 1));
	if (result != UPNP_E_SUCCESS) return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpSetMaxContentLength(lua_State *L)
{
	int result = UpnpSetMaxContentLength((size_t)luaL_checklong(L, 1));
	if (result != UPNP_E_SUCCESS) return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

/*
** ===============================================================
**  UPnP API: Discovery
** ===============================================================
*/

static int L_UpnpSearchAsync(lua_State *L)
{
	int result = UpnpSearchAsync(checkclient(L, 1), luaL_checkint(L,2), luaL_checkstring(L,3), DSS_getutilid(L));
	if (result != UPNP_E_SUCCESS) return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpSendAdvertisement(lua_State *L)
{
	int result = UpnpSendAdvertisement(checkdevice(L, 1), luaL_checkint(L,2));
	if (result != UPNP_E_SUCCESS) return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}


/*
** ===============================================================
**  UPnP API: Control
** ===============================================================
*/

static int L_UpnpGetServiceVarStatus(lua_State *L)
{
	DOMString res = NULL;
	int result = UpnpGetServiceVarStatus(checkclient(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3), &res);
	if (result != UPNP_E_SUCCESS)
	{
		if (res != NULL) ixmlFreeDOMString(res);
		return pushUPnPerror(L, result, NULL);
	}
	lua_pushstring(L, res);
	ixmlFreeDOMString(res);
	return 1;
}

static int L_UpnpGetServiceVarStatusAsync(lua_State *L)
{
	int result = UpnpGetServiceVarStatusAsync(checkclient(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3), &LuaCallback, DSS_getutilid(L));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpSendAction(lua_State *L)
{
	IXML_Document* RespNode = NULL;
	int result = UpnpSendAction(checkclient(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3), NULL, checkdocument(L, 4), &RespNode);
	if (result == UPNP_E_SUCCESS)
	{
		pushLuaDocument(L, RespNode);
		return 1;
	}
	return pushUPnPerror(L, result, RespNode);
}

static int L_UpnpSendActionEx(lua_State *L)
{
	IXML_Document* RespNode = NULL;
	int result = UpnpSendActionEx(checkclient(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3), NULL, checkdocument(L, 4), checkdocument(L, 5), &RespNode);
	if (result == UPNP_E_SUCCESS)
	{
		pushLuaDocument(L, RespNode);
		return 1;
	}
	return pushUPnPerror(L, result, RespNode);
}

static int L_UpnpSendActionAsync(lua_State *L)
{
	IXML_Document* RespNode = NULL;
	int result = UpnpSendActionAsync(checkclient(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3), NULL, checkdocument(L, 4), &LuaCallback, DSS_getutilid(L));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpSendActionExAsync(lua_State *L)
{
	IXML_Document* RespNode = NULL;
	int result = UpnpSendActionExAsync(checkclient(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3), NULL, checkdocument(L, 4), checkdocument(L, 5), &LuaCallback, DSS_getutilid(L));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}


/*
** ===============================================================
**  UPnP API: Eventing
** ===============================================================
*/

static int L_UpnpAcceptSubscription(lua_State *L)
{
	return luaL_error(L, "Not implemented, use the 'Ext' version");
	// TODO: implement, not now
}

static int L_UpnpAcceptSubscriptionExt(lua_State *L)
{
	// TODO: check the cast of the string from a const
	int result = UpnpAcceptSubscriptionExt(checkdevice(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3), checkdocument(L, 4), (char*)luaL_checkstring(L,5));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpNotify(lua_State *L)
{
	return luaL_error(L, "Not implemented, use the 'Ext' version");
	// TODO: implement, not now
}

static int L_UpnpNotifyExt(lua_State *L)
{
	int result = UpnpNotifyExt(checkdevice(L, 1), luaL_checkstring(L,2), luaL_checkstring(L,3), checkdocument(L, 4));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpRenewSubscription(lua_State *L)
{
	int timeout = luaL_checkint(L,2);
	int result = UpnpRenewSubscription(checkclient(L, 1), &timeout, luaL_checkstring(L,3));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, timeout);
	return 1;
}

static int L_UpnpRenewSubscriptionAsync(lua_State *L)
{
	// TODO: check the cast to a string below, make copy?
	int result = UpnpRenewSubscriptionAsync(checkclient(L, 1), luaL_checkint(L,2), (char*)luaL_checkstring(L,3), &LuaCallback, DSS_getutilid(L));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpSetMaxSubscriptions(lua_State *L)
{
	int setmax = luaL_checkint(L,2);
	int result = UPNP_E_SUCCESS;
	if (setmax == -1) setmax = UPNP_INFINITE;		// use -1 to set no limit
	result = UpnpSetMaxSubscriptions(checkdevice(L, 1), setmax);
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpSetMaxSubscriptionTimeOut(lua_State *L)
{
	int setto = luaL_checkint(L,2);
	int result = UPNP_E_SUCCESS;
	if (setto == -1) setto = UPNP_INFINITE;		// use -1 to set no timeout, wait forever
	result = UpnpSetMaxSubscriptionTimeOut(checkdevice(L, 1), setto);
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpSubscribe(lua_State *L)
{
	int timeout = luaL_checkint(L,3);
	Upnp_SID SubsId;
	int result = UpnpSubscribe(checkclient(L, 1), luaL_checkstring(L,2), &timeout, SubsId);
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, timeout);
	lua_pushstring(L, SubsId);
	return 2;
}

static int L_UpnpSubscribeAsync(lua_State *L)
{
	int result = UpnpSubscribeAsync(checkclient(L, 1), luaL_checkstring(L,2), luaL_checkint(L,3), &LuaCallback, DSS_getutilid(L));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpUnSubscribe(lua_State *L)
{
	int result = UpnpUnSubscribe(checkclient(L, 1), luaL_checkstring(L,2));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpUnSubscribeAsync(lua_State *L)
{
	// TODO: check the cast from a const on the checkstring below, make copy?
	int result = UpnpUnSubscribeAsync(checkclient(L, 1), (char *)luaL_checkstring(L,2), &LuaCallback, DSS_getutilid(L));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}


/*
** ===============================================================
**  UPnP API: Control point HTTP
** ===============================================================
*/

static int L_UpnpDownloadUrlItem(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpOpenHttpGet(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpOpenHttpGetProxy(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpOpenHttpGetEx(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpReadHttpGet(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpHttpGetProgress(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpCancelHttpGet(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpCloseHttpGet(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpOpenHttpPost(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpWriteHttpPost(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpCloseHttpPost(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpDownloadXmlDoc(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

/*
** ===============================================================
**  UPnP API: Web server
** ===============================================================
*/

static int L_UpnpSetWebServerRootDir(lua_State *L)
{
	int result = UpnpSetWebServerRootDir(luaL_checkstring(L,1));
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushinteger(L, 1);
	return 1;
}

static int L_UpnpSetVirtualDirCallbacks(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpEnableWebserver(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpIsWebserverEnabled(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpAddVirtualDir(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpRemoveVirtualDir(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

static int L_UpnpRemoveAllVirtualDirs(lua_State *L)
{
	// TODO: implement, not now
	return luaL_error(L, "method not implemented yet!");
}

/*
** ===============================================================
**  UPnP API: utils/tools
** ===============================================================
*/

static int L_UpnpResolveURL(lua_State *L)
{
	size_t l1;
	size_t l2;
	int result = UPNP_E_SUCCESS;
	const char* BaseURL = luaL_checklstring(L,1, &l1);
	const char* RelURL = luaL_checklstring(L,2, &l2);
	char* AbsURL = (char*)malloc(l1 + l2 + 2);
	if (AbsURL == NULL)
	{
		result = UPNP_E_OUTOF_MEMORY;
	}
	else
	{
		result = UpnpResolveURL(BaseURL, RelURL, AbsURL);
	}
	if (result != UPNP_E_SUCCESS)	return pushUPnPerror(L, result, NULL);
	lua_pushstring(L, AbsURL);
	free(AbsURL);
	return 1;
}

static int Lx_UpnpMakeAction(lua_State *L, int response)
{
	const char* ActionName = luaL_checkstring(L,1);
	const char* ServType = luaL_checkstring(L,2);
	const char* ArgName = NULL;
	const char* ArgVal = NULL;
	int result = UPNP_E_SUCCESS;
	IXML_Document* doc;
	if (response)
		doc = UpnpMakeActionResponse(ActionName, ServType, 0, NULL);
	else
		doc = UpnpMakeAction(ActionName, ServType, 0, NULL);

	if (doc != NULL)
	{
		if (lua_gettop(L) > 2 && lua_istable(L,3))
		{
			/* table is in the stack at index 't' */
			lua_pushnil(L);  /* first key */
			while (lua_next(L, 3) != 0) {
				/* uses 'key' (at index -2) and 'value' (at index -1) */
				if (lua_type(L,-2) == LUA_TSTRING)
				{
					ArgName = lua_tostring(L, -2);
					ArgVal = lua_tostring(L, -1);
					if (response)
						result = UpnpAddToActionResponse(&doc, ActionName, ServType, ArgName, ArgVal);
					else
						result = UpnpAddToAction(&doc, ActionName, ServType, ArgName, ArgVal);
				}
				else
				{
					// key is not a string, must make a copy to prevent conversion to a string
					lua_pushvalue(L,-2);		// copy name to new stack pos, where it will be converted
					ArgName = lua_tostring(L, -1);
					ArgVal = lua_tostring(L, -2);
					if (response)
						result = UpnpAddToActionResponse(&doc, ActionName, ServType, ArgName, ArgVal);
					else
						result = UpnpAddToAction(&doc, ActionName, ServType, ArgName, ArgVal);
					lua_pop(L, 1);	// pop the copy
				}
				/* removes 'value'; keeps 'key' for next iteration */
				lua_pop(L, 1);
				if (result != UPNP_E_SUCCESS)
				{
					ixmlDocument_free(doc);
					return luaL_error(L, "Error adding argument names and values to the Action");
				}
			}
		}
		else
		{
			// 3rd argument is missing or not a table
			ixmlDocument_free(doc);
			return luaL_error(L, "argument error, 3rd argument; expected a table");
		}
	}
	pushLuaDocument(L, doc);
	return 1;
}

static int Lx_UpnpAddToAction(lua_State *L, int response)
{
	int result = UPNP_E_SUCCESS;
	const char* ActionName = luaL_checkstring(L,2);
	const char* ServType = luaL_checkstring(L,3);
	const char* ArgName = luaL_checkstring(L,4);
	const char* ArgVal = luaL_checkstring(L,5);
	IXML_Document* doc = NULL;
	if (! lua_isnil(L,1))	doc = checkdocument(L, 1);

	if (response)
		result = UpnpAddToActionResponse(&doc, ActionName, ServType, ArgName, ArgVal);
	else
		result = UpnpAddToAction(&doc, ActionName, ServType, ArgName, ArgVal);

	if (result != UPNP_E_SUCCESS)
	{
		if (lua_isnil(L,1))		ixmlDocument_free(doc);		// destroy only if created
		return pushUPnPerror(L, result, NULL);
	}
	pushLuaDocument(L, doc);
	return 1;
}

// Param list modified; no numer and no args, just a table, key-values
static int L_UpnpMakeAction(lua_State *L)
{
	return Lx_UpnpMakeAction(L, 0);
}

static int L_UpnpAddToAction(lua_State *L)
{
	return Lx_UpnpAddToAction(L, 0);
}

// Param list modified; no numer and no args, just a table, key-values
static int L_UpnpMakeActionResponse(lua_State *L)
{
	return Lx_UpnpMakeAction(L, 1);
}

static int L_UpnpAddToActionResponse(lua_State *L)
{
	return Lx_UpnpAddToAction(L, 1);
}

static int L_UpnpAddToPropertySet(lua_State *L)
{
	int result = UPNP_E_SUCCESS;
	const char* ArgName = luaL_checkstring(L,4);
	const char* ArgVal = luaL_checkstring(L,5);
	IXML_Document* doc = NULL;
	if (! lua_isnil(L,1))	doc = checkdocument(L, 1);

	result = UpnpAddToPropertySet(&doc, ArgName, ArgVal);

	if (result != UPNP_E_SUCCESS)
	{
		if (lua_isnil(L,1))		ixmlDocument_free(doc);		// destroy only if created
		return pushUPnPerror(L, result, NULL);
	}
	pushLuaDocument(L, doc);
	return 1;
}

// Param list modified; no numer and no args, just a table, key-values
static int L_UpnpCreatePropertySet(lua_State *L)
{
	const char* ArgName = NULL;
	const char* ArgVal = NULL;
	int result = UPNP_E_SUCCESS;
	IXML_Document* doc = UpnpCreatePropertySet(0, NULL);

	if (doc != NULL)
	{
		if (lua_gettop(L) > 2 && lua_istable(L,1))
		{
			/* table is in the stack at index 't' */
			lua_pushnil(L);  /* first key */
			while (lua_next(L, 1) != 0) {
				/* uses 'key' (at index -2) and 'value' (at index -1) */
				if (lua_type(L,-2) == LUA_TSTRING)
				{
					ArgName = lua_tostring(L, -2);
					ArgVal = lua_tostring(L, -1);
					result = UpnpAddToPropertySet(&doc, ArgName, ArgVal);
				}
				else
				{
					// key is not a string, must make a copy to prevent conversion to a string
					lua_pushvalue(L,-2);		// copy name to new stack pos, where it will be converted
					ArgName = lua_tostring(L, -1);
					ArgVal = lua_tostring(L, -2);
					result = UpnpAddToPropertySet(&doc, ArgName, ArgVal);
					lua_pop(L, 1);	// pop the copy
				}
				/* removes 'value'; keeps 'key' for next iteration */
				lua_pop(L, 1);
				if (result != UPNP_E_SUCCESS)
				{
					ixmlDocument_free(doc);
					return luaL_error(L, "Error adding argument names and values to the Propertyset");
				}
			}
		}
		else
		{
			// 3rd argument is missing or not a table
			ixmlDocument_free(doc);
			return luaL_error(L, "argument error, 3rd argument; expected a table");
		}
	}
	pushLuaDocument(L, doc);
	return 1;
}

/*static int L_UpnpGetErrorMessage(lua_State *L)
{
	// no use, keep internal
}
*/


/*
** ===============================================================
** Library initialization / shutdown
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
	{"IsEnabled",L_UpnpIsWebserverEnabled},
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
	//{"GetErrorMessage",L_UpnpGetErrorMessage},
	{NULL,NULL}
};


// Close method called when Lua shutsdown the library
// Note: check Lua os.exit() function for exceptions,
// it will not always be called!
static int L_closeLib(lua_State *L) {
	// stop UPnP
	UpnpFinish();
	// shutdown DSS
	DSS_shutdown(L, NULL);
	return 0;
}

LPNP_API	int luaopen_LuaUPnP(lua_State *L)
{

	/////////////////////////////////////////////
	//  Create lib close userdata
	/////////////////////////////////////////////

	// first register with DSS
	DSS_initialize(L, &DSS_cancel);	// will not return on error.

	// Setup a close method to unregister from DSS
	lua_newuserdata(L, sizeof(void*));
	luaL_newmetatable(L, LPNP_LIBRARY_MT);	// Create a new metatable
	lua_pushstring(L, "__gc");
	lua_pushcfunction(L, L_closeLib);
	lua_settable(L, -3);					// Add GC metamethod
	lua_setmetatable(L, -2);				// Attach metatable to userdata
	lua_setfield(L, LUA_REGISTRYINDEX, LPNP_LIBRARY_UD);	// store userdata in registry


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

