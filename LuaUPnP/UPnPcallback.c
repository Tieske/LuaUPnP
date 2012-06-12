#include "LuaUPnP.h"
#include "upnp.h"
#include "upnpdebug.h"

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
	lua_pushnil(L);
	lua_pushstring(L, (char*)pData);
	return 2;
}
static int deliverUpnpCallbackError(const char* msg, void* cookie)
{
	return DSS_deliver(cookie, &decodeUpnpCallbackError, (void*)msg);
}

// =================== Discovery events ==========================
static int decodeUpnpDiscovery(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
	UpnpDiscovery* dEvent = (UpnpDiscovery*)mydata->Event;

	// if L == NULL; DSS is unregistering the UPNP lib and we can't access Lua
	if (L != NULL)
	{
		// Create and fill the event table for Lua
		lua_newtable(L);
		lua_pushstring(L, "Event");
		lua_pushstring(L, UpnpGetEventType(mydata->EventType));
		lua_settable(L, -3);
		lua_pushstring(L, "ErrCode");
		lua_pushinteger(L, UpnpDiscovery_get_ErrCode(dEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "Error");
		lua_pushstring(L, UpnpGetErrorMessage(UpnpDiscovery_get_ErrCode(dEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "Expires");
		lua_pushinteger(L, UpnpDiscovery_get_Expires(dEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "DeviceID");
		lua_pushstring(L, UpnpString_get_String(UpnpDiscovery_get_DeviceID(dEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "DeviceType");
		lua_pushstring(L, UpnpString_get_String(UpnpDiscovery_get_DeviceType(dEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "ServiceType");
		lua_pushstring(L, UpnpString_get_String(UpnpDiscovery_get_ServiceType(dEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "ServiceVer");
		lua_pushstring(L, UpnpString_get_String(UpnpDiscovery_get_ServiceVer(dEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "Location");
		lua_pushstring(L, UpnpString_get_String(UpnpDiscovery_get_Location(dEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "Os");
		lua_pushstring(L, UpnpString_get_String(UpnpDiscovery_get_Os(dEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "Date");
		lua_pushstring(L, UpnpString_get_String(UpnpDiscovery_get_Date(dEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "Ext");
		lua_pushstring(L, UpnpString_get_String(UpnpDiscovery_get_Ext(dEvent)));
		lua_settable(L, -3);
		// TODO: add address info
		//lua_pushstring(L, "DestAddr");
		//lua_pushstring(L, UpnpDiscovery_get_DestAddr(dEvent));
		//lua_settable(L, -3);
		result = 1;	// 1 return argument, the table
	}
	UpnpDiscovery_delete(dEvent);
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
	mydata->Event =  UpnpDiscovery_dup(dEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpDiscovery callback.", cookie);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpDiscovery, mydata);
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
		// Create and fill the event table for Lua
		lua_newtable(L);
		lua_pushstring(L, "Event");
		lua_pushstring(L, UpnpGetEventType(mydata->EventType));
		lua_settable(L, -3);
		lua_pushstring(L, "ErrCode");
		lua_pushinteger(L, UpnpActionComplete_get_ErrCode(acEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "Error");
		lua_pushstring(L, UpnpGetErrorMessage(UpnpActionComplete_get_ErrCode(acEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "CtrlUrl");
		lua_pushstring(L, UpnpString_get_String(UpnpActionComplete_get_CtrlUrl(acEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "ActionRequest");
		pushLuaDocument(L, UpnpActionComplete_get_ActionRequest(acEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "ActionResult");
		pushLuaDocument(L, UpnpActionComplete_get_ActionResult(acEvent));
		lua_settable(L, -3);
		result = 1;	// 1 return argument, the table
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

	err = DSS_deliver(cookie, &decodeUpnpActionComplete, mydata);
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
		// Create and fill the event table for Lua
		lua_newtable(L);
		lua_pushstring(L, "Event");
		lua_pushstring(L, UpnpGetEventType(mydata->EventType));
		lua_settable(L, -3);
		lua_pushstring(L, "ErrCode");
		lua_pushinteger(L, UpnpStateVarComplete_get_ErrCode(svcEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "Error");
		lua_pushstring(L, UpnpGetErrorMessage(UpnpStateVarComplete_get_ErrCode(svcEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "CtrlUrl");
		lua_pushstring(L, UpnpString_get_String(UpnpStateVarComplete_get_CtrlUrl(svcEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "StateVarName");
		lua_pushstring(L, UpnpString_get_String(UpnpStateVarComplete_get_StateVarName(svcEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "CurrentVal");
		lua_pushstring(L, UpnpStateVarComplete_get_CurrentVal(svcEvent));
		lua_settable(L, -3);
		result = 1;	// 1 return argument, the table
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

	err = DSS_deliver(cookie, &decodeUpnpStateVarComplete, mydata);
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
		// Create and fill the event table for Lua
		lua_newtable(L);
		lua_pushstring(L, "Event");
		lua_pushstring(L, UpnpGetEventType(mydata->EventType));
		lua_settable(L, -3);
		lua_pushstring(L, "EventKey");
		lua_pushinteger(L, UpnpEvent_get_EventKey(eEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "ChangedVariables");
		pushLuaDocument(L, UpnpEvent_get_ChangedVariables(eEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "SID");
		lua_pushstring(L, UpnpString_get_String(UpnpEvent_get_SID(eEvent)));
		lua_settable(L, -3);
		result = 1;	// 1 return argument, the table
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

	err = DSS_deliver(cookie, &decodeUpnpEvent, mydata);
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
		// Create and fill the event table for Lua
		lua_newtable(L);
		lua_pushstring(L, "Event");
		lua_pushstring(L, UpnpGetEventType(mydata->EventType));
		lua_settable(L, -3);
		lua_pushstring(L, "ErrCode");
		lua_pushinteger(L, UpnpEventSubscribe_get_ErrCode(esEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "Error");
		lua_pushstring(L, UpnpGetErrorMessage(UpnpEventSubscribe_get_ErrCode(esEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "TimeOut");
		lua_pushinteger(L, UpnpEventSubscribe_get_TimeOut(esEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "SID");
		lua_pushstring(L, UpnpString_get_String(UpnpEventSubscribe_get_SID(esEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "PublisherUrl");
		lua_pushstring(L, UpnpString_get_String(UpnpEventSubscribe_get_PublisherUrl(esEvent)));
		lua_settable(L, -3);
		result = 1;	// 1 return argument, the table
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

	err = DSS_deliver(cookie, &decodeUpnpEventSubscribe, mydata);
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
		// Create and fill the event table for Lua
		lua_newtable(L);
		lua_pushstring(L, "ServiceId");
		lua_pushstring(L, UpnpString_get_String(UpnpSubscriptionRequest_get_ServiceId(srEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "UDN");
		lua_pushstring(L, UpnpString_get_String(UpnpSubscriptionRequest_get_UDN(srEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "SID");
		lua_pushstring(L, UpnpString_get_String(UpnpSubscriptionRequest_get_SID(srEvent)));
		lua_settable(L, -3);
		result = 1;	// 1 return argument, the table
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

	err = DSS_deliver(cookie, &decodeUpnpSubscriptionRequest, mydata);
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
		// Create and fill the event table for Lua
		lua_newtable(L);
		lua_pushstring(L, "Event");
		lua_pushstring(L, UpnpGetEventType(mydata->EventType));
		lua_settable(L, -3);
		lua_pushstring(L, "ErrCode");
		lua_pushinteger(L, UpnpStateVarRequest_get_ErrCode(svrEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "Error");
		lua_pushstring(L, UpnpGetErrorMessage(UpnpStateVarRequest_get_ErrCode(svrEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "Socket");
		lua_pushinteger(L, UpnpStateVarRequest_get_Socket(svrEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "ErrStr");
		lua_pushstring(L, UpnpString_get_String(UpnpStateVarRequest_get_ErrStr(svrEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "DevUDN");
		lua_pushstring(L, UpnpString_get_String(UpnpStateVarRequest_get_DevUDN(svrEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "ServiceID");
		lua_pushstring(L, UpnpString_get_String(UpnpStateVarRequest_get_ServiceID(svrEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "StateVarName");
		lua_pushstring(L, UpnpString_get_String(UpnpStateVarRequest_get_StateVarName(svrEvent)));
		lua_settable(L, -3);
		// TODO: add address info
		//lua_pushstring(L, "CtrlCpIPAddr");
		//lua_pushstring(L, UpnpString_get_String(UpnpStateVarRequest_get_CtrlCpIPAddr(svrEvent)));
		//lua_settable(L, -3);
		lua_pushstring(L, "CurrentVal");
		lua_pushstring(L, UpnpStateVarRequest_get_CurrentVal(svrEvent));
		lua_settable(L, -3);
		result = 1;	// 1 return argument, the table
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

	err = DSS_deliver(cookie, &decodeUpnpStateVarRequest, mydata);
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
		// Create and fill the event table for Lua
		lua_newtable(L);
		lua_pushstring(L, "Event");
		lua_pushstring(L, UpnpGetEventType(mydata->EventType));
		lua_settable(L, -3);
		lua_pushstring(L, "ErrCode");
		lua_pushinteger(L, UpnpActionRequest_get_ErrCode(arEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "Error");
		lua_pushstring(L, UpnpGetErrorMessage(UpnpActionRequest_get_ErrCode(arEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "Socket");
		lua_pushinteger(L, UpnpActionRequest_get_Socket(arEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "ErrStr");
		lua_pushstring(L, UpnpString_get_String(UpnpActionRequest_get_ErrStr(arEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "DevUDN");
		lua_pushstring(L, UpnpString_get_String(UpnpActionRequest_get_DevUDN(arEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "ServiceID");
		lua_pushstring(L, UpnpString_get_String(UpnpActionRequest_get_ServiceID(arEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "ActionRequest");
		pushLuaDocument(L, UpnpActionRequest_get_ActionRequest(arEvent));
		lua_pushstring(L, "ActionResult");
		pushLuaDocument(L, UpnpActionRequest_get_ActionResult(arEvent));
		lua_pushstring(L, "SoapHeader");
		pushLuaDocument(L, UpnpActionRequest_get_SoapHeader(arEvent));
		// TODO: add address info
		//lua_pushstring(L, "CtrlCpIPAddr");
		//lua_pushstring(L, UpnpString_get_String(UpnpActionRequest_get_CtrlCpIPAddr(arEvent)));
		//lua_settable(L, -3);
		result = 1;	// 1 return argument, the table
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

	err = DSS_deliver(cookie, &decodeUpnpActionRequest, mydata);
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

