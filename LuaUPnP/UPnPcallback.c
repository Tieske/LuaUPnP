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
static int decodeUpnpCallbackError(lua_State *L, void* pData, void* pUtilData, void* utilid)
{
	// Push the callback function first
	lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
	lua_pushnil(L);
	lua_pushstring(L, (char*)pData);
	return 3;
}
static int deliverUpnpCallbackError(const char* msg, void* cookie)
{
	//TODO: must copy the string, and release upon decoding
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
static int decodeUpnpDiscovery(lua_State *L, void* pData, void* pUtilData, void* utilid)
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
static int decodeUpnpActionComplete(lua_State *L, void* pData, void* pUtilData, void* utilid)
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
static int decodeUpnpStateVarComplete(lua_State *L, void* pData, void* pUtilData, void* utilid)
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
static int decodeUpnpEvent(lua_State *L, void* pData, void* pUtilData, void* utilid)
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
static int decodeUpnpEventSubscribe(lua_State *L, void* pData, void* pUtilData, void* utilid)
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
static int decodeUpnpSubscriptionRequest(lua_State *L, void* pData, void* pUtilData, void* utilid)
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
	//UpnpSubscriptionRequest_delete(srEvent);  do not release resources, the 'return' call still needs them
	//free(mydata);
	return result;
}


// the return function should provide 2 parameters;
//   1) the deviceobject/handle (userdata)
//   2) a table with statevariable name/value pairs.
// The table is optional, and may be empty
// Returns; 1, or nil + errormsg
static int returnUpnpSubscriptionRequest(lua_State *L, void* pData, void* pUtilData, void* utilid, int garbage)
{
	int err = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpSubscriptionRequest* srEvent = (UpnpSubscriptionRequest*)mydata->Event;
	IXML_Document* VarList = NULL;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L == NULL)
	{
		if (garbage) deliverUpnpCallbackError("Error: a UpnpSubscriptionRequest was left unanswered and was garbage collected.", NULL);
		return 0;
	}
	else
	{
		if (garbage) return 0;
		if (lua_gettop(L) == 1) lua_newtable(L);	// push an empty table as second argument
		if (lua_gettop(L) < 2 || getdevice(L,1) == -1 || !lua_istable(L,2))
		{
			lua_pushnil(L);
			lua_pushstring(L, "Error: expected a Device and a table (with variable names and values) as parameters");
			return 2;
		}

		lua_settop(L,2);	// clear remainder of stack
		// iterate over provided table
		lua_pushnil(L);
		while (lua_next(L,2) != 0)
		{
			lua_pushvalue(L, -2);	// duplicate the key, to prevent confusing 'next()'
			err = UpnpAddToPropertySet(&VarList, lua_tostring(L, -1), lua_tostring(L, -2));
			lua_pop(L,2);	// remove copy of key and value
			if (err != UPNP_E_SUCCESS)
			{
				// error with the table contents, invalid
				if (VarList != NULL) ixmlDocument_free(VarList);
				lua_pushnil(L);
				lua_pushstring(L, "Error: Invalid data in StateVariable table provided to SubscriptionRequest");
				return 2;
			}
		}
		//succeeded, store results
		mydata->handle = getdevice(L,1);
		mydata->Extra = VarList;
		//report success
		lua_pushinteger(L, 1);
		return 1;
	}
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
	mydata->Event =  (void*)srEvent; //UpnpSubscriptionRequest_dup(srEvent); we'll be waiting, so no duplicate
	mydata->Cookie = cookie;
	mydata->Extra = NULL;
	mydata->handle = -1;
	//if (mydata->Event == NULL)
	//{
	//	deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpSubscriptionRequest callback.", cookie);
	//	free(mydata);
	//	return 0;
	//}

	// This call will block until all callbacks have been completed
	err = DSS_deliver(cookie, &decodeUpnpSubscriptionRequest, &returnUpnpSubscriptionRequest, mydata);

	// report error if any
	if (err != DSS_SUCCESS)	deliverUpnpCallbackError("Error delivering 'event' for UpnpSubscriptionRequest callback.", cookie);
	
	// Actually handle the subscription
	if (mydata->Extra != NULL) 
	{
		UpnpAcceptSubscriptionExt(
				mydata->handle, 
				UpnpSubscriptionRequest_get_UDN_cstr(srEvent),
				UpnpString_get_String(UpnpSubscriptionRequest_get_ServiceId(srEvent)), 
				(IXML_Document*)mydata->Extra,
				UpnpSubscriptionRequest_get_SID_cstr(srEvent));

		// Cleanup
		ixmlDocument_free((IXML_Document*)mydata->Extra);
	}

	free(mydata);
	return 0;
}

// =================== StateVar request events ==========================
//static int decodeUpnpStateVarRequest(lua_State *L, void* pData, void* pUtilData, void* utilid)
//{
//	int result = 0;
//	cbdelivery* mydata = (cbdelivery*)pData;
//	UpnpStateVarRequest* svrEvent = (UpnpStateVarRequest*)mydata->Event;
//
//	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
//	if (L != NULL)
//	{
//		// Push the callback function first
//		lua_getfield(L, LUA_REGISTRYINDEX, UPNPCALLBACK);
//		// Create and fill the event table for Lua
//		lua_newtable(L);
//		pushstringfield(L, "Event", UpnpGetEventType(mydata->EventType));
//		if (UpnpStateVarRequest_get_ErrCode(svrEvent) != UPNP_E_SUCCESS)
//		{
//			lua_pushstring(L, "ErrCode");
//			lua_pushinteger(L, UpnpStateVarRequest_get_ErrCode(svrEvent));
//			lua_settable(L, -3);
//			pushstringfield(L, "Error", UpnpGetErrorMessage(UpnpStateVarRequest_get_ErrCode(svrEvent)));
//		}
//		lua_pushstring(L, "Socket");
//		lua_pushinteger(L, UpnpStateVarRequest_get_Socket(svrEvent));
//		lua_settable(L, -3);
//		pushstringfield(L, "ErrStr", UpnpString_get_String(UpnpStateVarRequest_get_ErrStr(svrEvent)));
//		pushstringfield(L, "DevUDN", UpnpString_get_String(UpnpStateVarRequest_get_DevUDN(svrEvent)));
//		pushstringfield(L, "ServiceID", UpnpString_get_String(UpnpStateVarRequest_get_ServiceID(svrEvent)));
//		pushstringfield(L, "StateVarName", UpnpString_get_String(UpnpStateVarRequest_get_StateVarName(svrEvent)));
//		// TODO: add address info, check *NIX vs Win32 differences, and IPv4 vs IPv6
//		//lua_pushstring(L, "CtrlCpIPAddr");
//		//lua_pushstring(L, UpnpString_get_String(UpnpStateVarRequest_get_CtrlCpIPAddr(svrEvent)));
//		//lua_settable(L, -3);
//		pushstringfield(L, "CurrentVal", UpnpStateVarRequest_get_CurrentVal(svrEvent));
//		result = 2;	// 2 return arguments, callback + table
//	}
//	UpnpStateVarRequest_delete(svrEvent);
//	free(mydata);
//	return result;
//}

// see UPnP architecture 1.0, section 3.3.2 Control: Query: Response, 
static int deliverUpnpStateVarRequest(Upnp_EventType EventType, const UpnpStateVarRequest *svrEvent, void* cookie)
{
	// set response for not-implemented as per UPnP architecture 1.0, section 3.3.2 Control: Query: Response
	UpnpStateVarRequest_set_ErrCode((UpnpStateVarRequest *)svrEvent, 401);
	UpnpStateVarRequest_strcpy_ErrStr((UpnpStateVarRequest *)svrEvent, "Invalid Action");
	return 0;

	//int err = DSS_SUCCESS;
	//cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));

	//if (mydata == NULL)
	//{
	//	deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpStateVarRequest callback.", cookie);
	//	return 0;
	//}
	//mydata->EventType = EventType;
	//mydata->Event =  UpnpStateVarRequest_dup(svrEvent);
	//mydata->Cookie = cookie;
	//if (mydata->Event == NULL)
	//{
	//	deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpStateVarRequest callback.", cookie);
	//	free(mydata);
	//	return 0;
	//}

	//err = DSS_deliver(cookie, &decodeUpnpStateVarRequest, NULL, mydata);
	//if (err != DSS_SUCCESS)
	//{
	//	deliverUpnpCallbackError("Error delivering 'event' for UpnpStateVarRequest callback.", cookie);
	//	if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
	//	{
	//		UpnpStateVarRequest_delete((UpnpStateVarRequest *)mydata->Event);
	//		free(mydata);
	//	}
	//	return 0;
	//}
	//return 0;
}

// =================== Action request events ==========================
static int decodeUpnpActionRequest(lua_State *L, void* pData, void* pUtilData, void* utilid)
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
		pushstringfield(L, "ActionName", UpnpString_get_String(UpnpActionRequest_get_ActionName(arEvent)));
		lua_pushstring(L, "ActionRequest");
		pushLuaDocument(L, UpnpActionRequest_get_ActionRequest(arEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "ActionResult");
		pushLuaDocument(L, UpnpActionRequest_get_ActionResult(arEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "SoapHeader");
		pushLuaDocument(L, UpnpActionRequest_get_SoapHeader(arEvent));
		lua_settable(L, -3);
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

// the return function should provide 2 parameters;
//   1) the deviceobject/handle (userdata)
//   2) an array (numbered table) with argument names
//   3) an array (numbered table) with the corresponding return values
// The tables may be present, and may be empty. 
// To return an error, the following must be returned instead of the tables
//   2) error number
//   3) error string
// Possible return errors; see ErrorCode table in UPnP architecture 1.0, section 3.2.2 Control: Action: Response. 
// Returns; 1, or nil + errormsg
static int returnUpnpActionRequest(lua_State *L, void* pData, void* pUtilData, void* utilid, int garbage)
{
	int err = 0;
	int i = 1;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpActionRequest* arEvent = (UpnpActionRequest*)mydata->Event;
	IXML_Document* RetList = NULL;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L == NULL)
	{
		// report error as action failed; from arch doc: "May be returned in current state of service prevents invoking that action."
		UpnpActionRequest_set_ActionResult(arEvent, NULL);
		UpnpActionRequest_set_ErrCode(arEvent, 501);
		UpnpActionRequest_strcpy_ErrStr(arEvent, "Action Failed");
		if (garbage) deliverUpnpCallbackError("Error: a UpnpActionRequest was left unanswered and was garbage collected.", NULL);
		return 0;
	}
	else
	{
		if (garbage) return 0;
		if (lua_gettop(L) == 1) lua_newtable(L);	// push an empty table as second argument
		if (lua_gettop(L) == 2) lua_newtable(L);	// push an empty table as third argument
		if (lua_gettop(L) < 3 || getdevice(L,1) == -1 || !lua_istable(L,2) || !lua_istable(L,3))
		{
			UpnpActionRequest_set_ActionResult(arEvent, NULL);
			UpnpActionRequest_set_ErrCode(arEvent, 501);
			UpnpActionRequest_strcpy_ErrStr(arEvent, "Action Failed");
			lua_pushnil(L);
			lua_pushstring(L, "Error: expected a Device and 2 tables (argument names and values) as parameters");
			return 2;
		}

		lua_settop(L,3);	// clear remainder of stack
		// iterate over provided tables
		while (1)
		{
			lua_pushinteger(L, i);
			lua_gettable(L, 2); // gets the argname at pos 4
			if (lua_isnil(L,-1))
			{
				// we're done
				lua_settop(L, 3);
				break;
			}
			lua_pushinteger(L, i);
			lua_gettable(L, 3); // gets the argvalue at pos 5

			//if (UpnpAddToActionResponse(&RetList, actionname,
			//		    TvServiceType[TV_SERVICE_CONTROL],
			//		    luaL_tolstring(L, 4, NULL),
			//		    luaL_tolstring(L, 5, NULL)) != UPNP_E_SUCCESS)
			//{
			//	// error adding element
			//	(*out) = NULL;
			//	(*errorString) = "Internal Error";
			//	free(value);
			//	return UPNP_E_INTERNAL_ERROR;
			//}

			lua_pushvalue(L, -2);	// duplicate the key, to prevent confusing 'next()'
			err = UpnpAddToPropertySet(&RetList, lua_tostring(L, -1), lua_tostring(L, -2));
			lua_pop(L,2);	// remove copy of key and value
			if (err != UPNP_E_SUCCESS)
			{
				// error with the table contents, invalid
				if (RetList != NULL) ixmlDocument_free(RetList);
				lua_pushnil(L);
				lua_pushstring(L, "Error: Invalid data in StateVariable table provided to SubscriptionRequest");
				return 2;
			}
			i += 1;
		}
		//succeeded, store results
		mydata->handle = getdevice(L,1);
		mydata->Extra = RetList;
		//report success
		lua_pushinteger(L, 1);
		return 1;
	}
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

