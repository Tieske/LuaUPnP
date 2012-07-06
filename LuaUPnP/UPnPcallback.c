#include "LuaUPnP.h"
#include "upnp.h"
#include "upnpdebug.h"
#include "string.h"

/*
** ===============================================================
**   UPnP callback handling
** ===============================================================
*/

// Shortcut to cloning an IXML_Document
static IXML_Document* copyIXMLdoc(IXML_Document* inputDoc)
{
	return (IXML_Document*)ixmlNode_cloneNode((IXML_Node*)inputDoc, TRUE);
}

// =================== Error reporting ===========================
static int decodeUpnpCallbackError(lua_State *L, void* pData, void* utilid)
{
	// Push the callback function first
	lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
	lua_pushnil(L);
	lua_pushstring(L, (char*)pData);
	return 3;
}
static int deliverUpnpCallbackError(const char* msg, void* cookie)
{
	return DSS_deliver(cookie, &decodeUpnpCallbackError, NULL, (void*)msg);
}
// =================== Push string if not NULL ===================
// requires table to add it to to be on top of the stack
static void pushstringfield(lua_State *L, const char* key, const char* value)
{
	if (value != NULL && strlen(value) != 0 )
	{
		lua_pushstring(L, key);
		lua_pushstring(L, value);
		lua_settable(L, -3);
	}
}

// =================== Discovery events ==========================
// TODO: update others to only report string if non-null and errors if present
static int decodeUpnpDiscovery(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpDiscovery* dEvent = (UpnpDiscovery*)mydata->Event;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L != NULL)
	{
		// Push the callback function first
		lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
		// Create and fill the event table for Lua
		lua_newtable(L);
		pushstringfield(L, "Event", UpnpGetEventType(mydata->EventType));
		if (dEvent != NULL)
		{
			if (UpnpDiscovery_get_ErrCode(dEvent) != UPNP_E_SUCCESS)
			{
				lua_pushstring(L, "ErrCode");
				lua_pushinteger(L, UpnpDiscovery_get_ErrCode(dEvent));
				lua_settable(L, -3);
				pushstringfield(L, "Error", UpnpGetErrorMessage(UpnpDiscovery_get_ErrCode(dEvent)));
			}
			lua_pushstring(L, "Expires");
			lua_pushinteger(L, UpnpDiscovery_get_Expires(dEvent));
			lua_settable(L, -3);
			pushstringfield(L, "DeviceID", UpnpString_get_String(UpnpDiscovery_get_DeviceID(dEvent)));
			pushstringfield(L, "DeviceType", UpnpString_get_String(UpnpDiscovery_get_DeviceType(dEvent)));
			pushstringfield(L, "ServiceType", UpnpString_get_String(UpnpDiscovery_get_ServiceType(dEvent)));
			pushstringfield(L, "ServiceVer", UpnpString_get_String(UpnpDiscovery_get_ServiceVer(dEvent)));
			pushstringfield(L, "Location", UpnpString_get_String(UpnpDiscovery_get_Location(dEvent)));
			pushstringfield(L, "Os", UpnpString_get_String(UpnpDiscovery_get_Os(dEvent)));
			pushstringfield(L, "Date", UpnpString_get_String(UpnpDiscovery_get_Date(dEvent)));
			pushstringfield(L, "Ext", UpnpString_get_String(UpnpDiscovery_get_Ext(dEvent)));
			// TODO: add address info, check *NIX vs Win32 differences, and IPv4 vs IPv6
			//lua_pushstring(L, "DestAddr");
			//lua_pushstring(L, UpnpDiscovery_get_DestAddr(dEvent));
			//lua_settable(L, -3);
		}
		result = 2;	// 2 return arguments, callback + table
	}
	if (dEvent != NULL) UpnpDiscovery_delete(dEvent);
	free(mydata);
	return result;
}

static int deliverUpnpDiscovery(Upnp_EventType EventType, const UpnpDiscovery *dEvent, void* cookie)
{
	int err = DSS_SUCCESS;
	cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpDiscovery callback.", cookie);
		return 0;
	}
	mydata->EventType = EventType;
	if (dEvent != NULL) {	// in case of UPNP_DISCOVERY_SEARCH_TIMEOUT event == NULL
		mydata->Event =  UpnpDiscovery_dup(dEvent);
	} else {
		mydata->Event = NULL;
	}
	mydata->Cookie = cookie;
	if (mydata->Event == NULL && dEvent != NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpDiscovery callback.", cookie);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpDiscovery, NULL, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpDiscovery callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
			UpnpDiscovery_delete((UpnpDiscovery *)mydata->Event);
			free(mydata);
		}
		return 0;
	}
	return 0;
}

// =================== Action Complete events ==========================
static int decodeUpnpActionComplete(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpActionComplete* acEvent = (UpnpActionComplete*)mydata->Event;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L != NULL)
	{
		// Push the callback function first
		lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
		// Create and fill the event table for Lua
		lua_newtable(L);
		pushstringfield(L, "Event", UpnpGetEventType(mydata->EventType));
		if (UpnpActionComplete_get_ErrCode(acEvent) != UPNP_E_SUCCESS)
		{
			lua_pushstring(L, "ErrCode");
			lua_pushinteger(L, UpnpActionComplete_get_ErrCode(acEvent));
			lua_settable(L, -3);
			pushstringfield(L, "Error", UpnpGetErrorMessage(UpnpActionComplete_get_ErrCode(acEvent)));
		}
		pushstringfield(L, "CtrlUrl", UpnpString_get_String(UpnpActionComplete_get_CtrlUrl(acEvent)));
		lua_pushstring(L, "ActionRequest");
		pushLuaDocument(L, UpnpActionComplete_get_ActionRequest(acEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "ActionResult");
		pushLuaDocument(L, UpnpActionComplete_get_ActionResult(acEvent));
		lua_settable(L, -3);
		result = 2;	// 2 return arguments, callback + table
	}
	UpnpActionComplete_delete(acEvent);
	free(mydata);
	return result;
}

static int deliverUpnpActionComplete(Upnp_EventType EventType, const UpnpActionComplete *acEvent, void* cookie)
{
	int err = DSS_SUCCESS;
	cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));
	IXML_Document* ActionRequest = NULL;
	IXML_Document* ActionRequestCopy = NULL;
	IXML_Document* ActionResult = NULL;
	IXML_Document* ActionResultCopy = NULL;

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpActionComplete callback.", cookie);
		return 0;
	}
	ActionRequest = UpnpActionComplete_get_ActionRequest(acEvent);
	ActionResult = UpnpActionComplete_get_ActionResult(acEvent);
	mydata->EventType = EventType;
	mydata->Event =  UpnpActionComplete_dup(acEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpActionComplete callback.", cookie);
		free(mydata);
		return 0;
	}
	ActionRequestCopy = copyIXMLdoc(ActionRequest);
	ActionResultCopy = copyIXMLdoc(ActionResult);
	if ((ActionRequest != NULL && ActionRequestCopy == NULL) || (ActionResult != NULL && ActionResultCopy == NULL))
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event IXMLs' for UpnpActionComplete callback.", cookie);
		ixmlNode_free((IXML_Node*)ActionRequestCopy);
		ixmlNode_free((IXML_Node*)ActionResultCopy);
		UpnpActionComplete_delete((UpnpActionComplete *)mydata->Event);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpActionComplete, NULL, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpActionComplete callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
			ixmlNode_free((IXML_Node*)ActionRequestCopy);
			ixmlNode_free((IXML_Node*)ActionResultCopy);
			UpnpActionComplete_delete((UpnpActionComplete *)mydata->Event);
			free(mydata);
		}
		return 0;
	}
	return 0;
}

// =================== StateVar Complete events ==========================
static int decodeUpnpStateVarComplete(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpStateVarComplete* svcEvent = (UpnpStateVarComplete*)mydata->Event;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L != NULL)
	{
		// Push the callback function first
		lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
		// Create and fill the event table for Lua
		lua_newtable(L);
		pushstringfield(L, "Event", UpnpGetEventType(mydata->EventType));
		if (UpnpStateVarComplete_get_ErrCode(svcEvent) != UPNP_E_SUCCESS)
		{
			lua_pushstring(L, "ErrCode");
			lua_pushinteger(L, UpnpStateVarComplete_get_ErrCode(svcEvent));
			lua_settable(L, -3);
			pushstringfield(L, "Error", UpnpGetErrorMessage(UpnpStateVarComplete_get_ErrCode(svcEvent)));
		}
		pushstringfield(L, "CtrlUrl", UpnpString_get_String(UpnpStateVarComplete_get_CtrlUrl(svcEvent)));
		pushstringfield(L, "StateVarName", UpnpString_get_String(UpnpStateVarComplete_get_StateVarName(svcEvent)));
		pushstringfield(L, "CurrentVal", UpnpStateVarComplete_get_CurrentVal(svcEvent));
		result = 2;	// 2 return arguments, callback + table
	}
	UpnpStateVarComplete_delete(svcEvent);
	free(mydata);
	return result;
}

static int deliverUpnpStateVarComplete(Upnp_EventType EventType, const UpnpStateVarComplete *svcEvent, void* cookie)
{
	int err = DSS_SUCCESS;
	cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpStateVarComplete callback.", cookie);
		return 0;
	}
	mydata->EventType = EventType;
	mydata->Event =  UpnpStateVarComplete_dup(svcEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpStateVarComplete callback.", cookie);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpStateVarComplete, NULL, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpStateVarComplete callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
			UpnpStateVarComplete_delete((UpnpStateVarComplete *)mydata->Event);
			free(mydata);
		}
		return 0;
	}
	return 0;
}

// =================== Event events ==========================
static int decodeUpnpEvent(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpEvent* eEvent = (UpnpEvent*)mydata->Event;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L != NULL)
	{
		// Push the callback function first
		lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
		// Create and fill the event table for Lua
		lua_newtable(L);
		pushstringfield(L, "Event", UpnpGetEventType(mydata->EventType));
		lua_pushstring(L, "EventKey");
		lua_pushinteger(L, UpnpEvent_get_EventKey(eEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "ChangedVariables");
		pushLuaDocument(L, UpnpEvent_get_ChangedVariables(eEvent));
		lua_settable(L, -3);
		pushstringfield(L, "SID", UpnpString_get_String(UpnpEvent_get_SID(eEvent)));
		result = 2;	// 2 return arguments, callback + table
	}
	UpnpEvent_delete(eEvent);
	free(mydata);
	return result;
}

static int deliverUpnpEvent(Upnp_EventType EventType, const UpnpEvent *eEvent, void* cookie)
{
	int err = DSS_SUCCESS;
	cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));
	IXML_Document* ChangedVariables;
	IXML_Document* ChangedVariablesCopy;

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpEvent callback.", cookie);
		return 0;
	}
	ChangedVariables = UpnpEvent_get_ChangedVariables(eEvent);
	mydata->EventType = EventType;
	mydata->Event =  UpnpEvent_dup(eEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpEvent callback.", cookie);
		free(mydata);
		return 0;
	}
	ChangedVariablesCopy = copyIXMLdoc(ChangedVariables);
	if (ChangedVariables != NULL && ChangedVariablesCopy == NULL)
	{
		ixmlNode_free((IXML_Node*)ChangedVariablesCopy);
		deliverUpnpCallbackError("Out of memory duplicating 'event IXMLs' for UpnpEvent callback.", cookie);
		UpnpEvent_delete((UpnpEvent *)mydata->Event);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpEvent, NULL, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpEvent callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
			ixmlNode_free((IXML_Node*)ChangedVariablesCopy);
			UpnpEvent_delete((UpnpEvent *)mydata->Event);
			free(mydata);
		}
		return 0;
	}
	return 0;
}

// =================== Event Subscribe events ==========================
static int decodeUpnpEventSubscribe(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpEventSubscribe* esEvent = (UpnpEventSubscribe*)mydata->Event;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L != NULL)
	{
		// Push the callback function first
		lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
		// Create and fill the event table for Lua
		lua_newtable(L);
		pushstringfield(L, "Event", UpnpGetEventType(mydata->EventType));
		if (UpnpEventSubscribe_get_ErrCode(esEvent) != UPNP_E_SUCCESS)
		{
			lua_pushstring(L, "ErrCode");
			lua_pushinteger(L, UpnpEventSubscribe_get_ErrCode(esEvent));
			lua_settable(L, -3);
			pushstringfield(L, "Error", UpnpGetErrorMessage(UpnpEventSubscribe_get_ErrCode(esEvent)));
		}
		lua_pushstring(L, "TimeOut");
		lua_pushinteger(L, UpnpEventSubscribe_get_TimeOut(esEvent));
		lua_settable(L, -3);
		pushstringfield(L, "SID", UpnpString_get_String(UpnpEventSubscribe_get_SID(esEvent)));
		pushstringfield(L, "PublisherUrl", UpnpString_get_String(UpnpEventSubscribe_get_PublisherUrl(esEvent)));
		result = 2;	// 2 return arguments, callback + table
	}
	UpnpEventSubscribe_delete(esEvent);
	free(mydata);
	return result;
}

static int deliverUpnpEventSubscribe(Upnp_EventType EventType, const UpnpEventSubscribe *esEvent, void* cookie)
{
	int err = DSS_SUCCESS;
	cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpEventSubscribe callback.", cookie);
		return 0;
	}
	mydata->EventType = EventType;
	mydata->Event =  UpnpEventSubscribe_dup(esEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpEventSubscribe callback.", cookie);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpEventSubscribe, NULL, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpEventSubscribe callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
			UpnpEventSubscribe_delete((UpnpEventSubscribe *)mydata->Event);
			free(mydata);
		}
		return 0;
	}
	return 0;
}

// =================== Subscription Request events ==========================
static int decodeUpnpSubscriptionRequest(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpSubscriptionRequest* srEvent = (UpnpSubscriptionRequest*)mydata->Event;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L != NULL)
	{
		// Push the callback function first
		lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
		// Create and fill the event table for Lua
		lua_newtable(L);
		pushstringfield(L, "Event", UpnpGetEventType(mydata->EventType));
		pushstringfield(L, "ServiceId", UpnpString_get_String(UpnpSubscriptionRequest_get_ServiceId(srEvent)));
		pushstringfield(L, "UDN", UpnpString_get_String(UpnpSubscriptionRequest_get_UDN(srEvent)));
		pushstringfield(L, "SID", UpnpString_get_String(UpnpSubscriptionRequest_get_SID(srEvent)));
		result = 2;	// 2 return arguments, callback + table
	}
	UpnpSubscriptionRequest_delete(srEvent);
	free(mydata);
	return result;
}

static int deliverUpnpSubscriptionRequest(Upnp_EventType EventType, const UpnpSubscriptionRequest *srEvent, void* cookie)
{
	int err = DSS_SUCCESS;
	cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpSubscriptionRequest callback.", cookie);
		return 0;
	}
	mydata->EventType = EventType;
	mydata->Event =  UpnpSubscriptionRequest_dup(srEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpSubscriptionRequest callback.", cookie);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpSubscriptionRequest, NULL, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpSubscriptionRequest callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
			UpnpSubscriptionRequest_delete((UpnpSubscriptionRequest *)mydata->Event);
			free(mydata);
		}
		return 0;
	}
	return 0;
}

// =================== StateVar request events ==========================
static int decodeUpnpStateVarRequest(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpStateVarRequest* svrEvent = (UpnpStateVarRequest*)mydata->Event;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L != NULL)
	{
		// Push the callback function first
		lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
		// Create and fill the event table for Lua
		lua_newtable(L);
		pushstringfield(L, "Event", UpnpGetEventType(mydata->EventType));
		if (UpnpStateVarRequest_get_ErrCode(svrEvent) != UPNP_E_SUCCESS)
		{
			lua_pushstring(L, "ErrCode");
			lua_pushinteger(L, UpnpStateVarRequest_get_ErrCode(svrEvent));
			lua_settable(L, -3);
			pushstringfield(L, "Error", UpnpGetErrorMessage(UpnpStateVarRequest_get_ErrCode(svrEvent)));
		}
		lua_pushstring(L, "Socket");
		lua_pushinteger(L, UpnpStateVarRequest_get_Socket(svrEvent));
		lua_settable(L, -3);
		pushstringfield(L, "ErrStr", UpnpString_get_String(UpnpStateVarRequest_get_ErrStr(svrEvent)));
		pushstringfield(L, "DevUDN", UpnpString_get_String(UpnpStateVarRequest_get_DevUDN(svrEvent)));
		pushstringfield(L, "ServiceID", UpnpString_get_String(UpnpStateVarRequest_get_ServiceID(svrEvent)));
		pushstringfield(L, "StateVarName", UpnpString_get_String(UpnpStateVarRequest_get_StateVarName(svrEvent)));
		// TODO: add address info, check *NIX vs Win32 differences, and IPv4 vs IPv6
		//lua_pushstring(L, "CtrlCpIPAddr");
		//lua_pushstring(L, UpnpString_get_String(UpnpStateVarRequest_get_CtrlCpIPAddr(svrEvent)));
		//lua_settable(L, -3);
		pushstringfield(L, "CurrentVal", UpnpStateVarRequest_get_CurrentVal(svrEvent));
		result = 2;	// 2 return arguments, callback + table
	}
	UpnpStateVarRequest_delete(svrEvent);
	free(mydata);
	return result;
}

static int deliverUpnpStateVarRequest(Upnp_EventType EventType, const UpnpStateVarRequest *svrEvent, void* cookie)
{
	int err = DSS_SUCCESS;
	cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpStateVarRequest callback.", cookie);
		return 0;
	}
	mydata->EventType = EventType;
	mydata->Event =  UpnpStateVarRequest_dup(svrEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpStateVarRequest callback.", cookie);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpStateVarRequest, NULL, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpStateVarRequest callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
			UpnpStateVarRequest_delete((UpnpStateVarRequest *)mydata->Event);
			free(mydata);
		}
		return 0;
	}
	return 0;
}

// =================== Action request events ==========================
static int decodeUpnpActionRequest(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpActionRequest* arEvent = (UpnpActionRequest*)mydata->Event;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L != NULL)
	{
		// Push the callback function first
		lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
		// Create and fill the event table for Lua
		lua_newtable(L);
		pushstringfield(L, "Event", UpnpGetEventType(mydata->EventType));
		if (UpnpActionRequest_get_ErrCode(arEvent) != UPNP_E_SUCCESS)
		{
			lua_pushstring(L, "ErrCode");
			lua_pushinteger(L, UpnpActionRequest_get_ErrCode(arEvent));
			lua_settable(L, -3);
			pushstringfield(L, "Error", UpnpGetErrorMessage(UpnpActionRequest_get_ErrCode(arEvent)));
		}
		lua_pushstring(L, "Socket");
		lua_pushinteger(L, UpnpActionRequest_get_Socket(arEvent));
		lua_settable(L, -3);
		pushstringfield(L, "ErrStr", UpnpString_get_String(UpnpActionRequest_get_ErrStr(arEvent)));
		pushstringfield(L, "DevUDN", UpnpString_get_String(UpnpActionRequest_get_DevUDN(arEvent)));
		pushstringfield(L, "ServiceID", UpnpString_get_String(UpnpActionRequest_get_ServiceID(arEvent)));
		lua_pushstring(L, "ActionRequest");
		pushLuaDocument(L, UpnpActionRequest_get_ActionRequest(arEvent));
		lua_pushstring(L, "ActionResult");
		pushLuaDocument(L, UpnpActionRequest_get_ActionResult(arEvent));
		lua_pushstring(L, "SoapHeader");
		pushLuaDocument(L, UpnpActionRequest_get_SoapHeader(arEvent));
		// TODO: add address info, check *NIX vs Wid32 differences, and IPv4 vs IPv6
		//lua_pushstring(L, "CtrlCpIPAddr");
		//lua_pushstring(L, UpnpString_get_String(UpnpActionRequest_get_CtrlCpIPAddr(arEvent)));
		//lua_settable(L, -3);
		result = 2;	// 2 return arguments, callback + table
	}
	UpnpActionRequest_delete(arEvent);
	free(mydata);
	return result;
}

static int deliverUpnpActionRequest(Upnp_EventType EventType, const UpnpActionRequest *arEvent, void* cookie)
{
	int err = DSS_SUCCESS;
	cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));
	IXML_Document* ActionRequest = NULL;
	IXML_Document* ActionRequestCopy = NULL;
	IXML_Document* ActionResult = NULL;
	IXML_Document* ActionResultCopy = NULL;
	IXML_Document* SoapHeader = NULL;
	IXML_Document* SoapHeaderCopy = NULL;

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpActionRequest callback.", cookie);
		return 0;
	}
	ActionRequest = UpnpActionRequest_get_ActionRequest(arEvent);
	ActionResult = UpnpActionRequest_get_ActionResult(arEvent);
	SoapHeader = UpnpActionRequest_get_SoapHeader(arEvent);
	mydata->EventType = EventType;
	mydata->Event =  UpnpActionRequest_dup(arEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpActionRequest callback.", cookie);
		free(mydata);
		return 0;
	}
	ActionRequestCopy = copyIXMLdoc(ActionRequest);
	ActionResultCopy = copyIXMLdoc(ActionResult);
	SoapHeaderCopy = copyIXMLdoc(SoapHeader);
	if ((ActionRequest != NULL && ActionRequestCopy == NULL) || 
		(ActionResult != NULL && ActionResultCopy == NULL) ||
		(SoapHeader != NULL && SoapHeaderCopy == NULL))

	{
		deliverUpnpCallbackError("Out of memory duplicating 'event IXMLs' for UpnpActionRequest callback.", cookie);
		ixmlNode_free((IXML_Node*)ActionRequestCopy);
		ixmlNode_free((IXML_Node*)ActionResultCopy);
		ixmlNode_free((IXML_Node*)SoapHeaderCopy);
		UpnpActionRequest_delete((UpnpActionRequest *)mydata->Event);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpActionRequest, NULL, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpActionRequest callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
			ixmlNode_free((IXML_Node*)ActionRequestCopy);
			ixmlNode_free((IXML_Node*)ActionResultCopy);
			ixmlNode_free((IXML_Node*)SoapHeaderCopy);
			UpnpActionRequest_delete((UpnpActionRequest *)mydata->Event);
			free(mydata);
		}
		return 0;
	}
	return 0;
}

