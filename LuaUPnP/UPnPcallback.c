#include "LuaUPnP.h"
#include "upnp.h"
#include "upnpdebug.h"

/*
** ===============================================================
**   UPnP callback handling
** ===============================================================
*/

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
		// TODO: DeviceId is in the documentation, but not in the code ???
		//lua_pushstring(L, "DeviceId");
		//lua_pushstring(L, UpnpDiscovery_get_DeviceId(dEvent));
		//lua_settable(L, -3);
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
		lua_pushstring(L, (const char*)UpnpActionComplete_get_CtrlUrl(acEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "ActionRequest");
		//TODO: should the IXML_document be copied, or can we use this instance? did copying the event already craete a new IXML copy as well?
		pushLuaDocument(L, UpnpActionComplete_get_ActionRequest(acEvent));
		lua_settable(L, -3);
		lua_pushstring(L, "ActionResult");
		//TODO: should the IXML_document be copied, or can we use this instance? did copying the event already craete a new IXML copy as well?
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

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpActionComplete callback.", cookie);
		return 0;
	}
	mydata->EventType = EventType;
	mydata->Event =  UpnpActionComplete_dup(acEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpActionComplete callback.", cookie);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpActionComplete, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpActionComplete callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
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
		lua_pushstring(L, UpnpGetErrorMessage(UpnpStateVarComplete_get_ErrCode(dEvent)));
		lua_settable(L, -3);
		lua_pushstring(L, "Expires");
		lua_pushinteger(L, UpnpDiscovery_get_Expires(dEvent));
		lua_settable(L, -3);
		// TODO: DeviceId is in the documentation, but not in the code ???
		//lua_pushstring(L, "DeviceId");
		//lua_pushstring(L, UpnpDiscovery_get_DeviceId(dEvent));
		//lua_settable(L, -3);
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
static int decodeUpnpActionComplete(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
x	UpnpActionComplete* acEvent = (UpnpActionComplete*)mydata->Event;

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
		// TODO: DeviceId is in the documentation, but not in the code ???
		//lua_pushstring(L, "DeviceId");
		//lua_pushstring(L, UpnpDiscovery_get_DeviceId(dEvent));
		//lua_settable(L, -3);
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
		result = 1;	// 1 return argument, the table
	}
x	UpnpDiscovery_delete(acEvent);
	free(mydata);
	return result;
}

static int deliverUpnpEvent(Upnp_EventType EventType, const UpnpEvent *eEvent, void* cookie)
{
	int err = DSS_SUCCESS;
	cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpEvent callback.", cookie);
		return 0;
	}
	mydata->EventType = EventType;
	mydata->Event =  UpnpEvent_dup(eEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpEvent callback.", cookie);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpEvent, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpEvent callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
			UpnpEvent_delete((UpnpEvent *)mydata->Event);
			free(mydata);
		}
		return 0;
	}
	return 0;
}

// =================== Event Subscribe events ==========================
static int decodeUpnpActionComplete(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
x	UpnpActionComplete* acEvent = (UpnpActionComplete*)mydata->Event;

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
		// TODO: DeviceId is in the documentation, but not in the code ???
		//lua_pushstring(L, "DeviceId");
		//lua_pushstring(L, UpnpDiscovery_get_DeviceId(dEvent));
		//lua_settable(L, -3);
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
		result = 1;	// 1 return argument, the table
	}
x	UpnpDiscovery_delete(acEvent);
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
static int decodeUpnpActionComplete(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
x	UpnpActionComplete* acEvent = (UpnpActionComplete*)mydata->Event;

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
		// TODO: DeviceId is in the documentation, but not in the code ???
		//lua_pushstring(L, "DeviceId");
		//lua_pushstring(L, UpnpDiscovery_get_DeviceId(dEvent));
		//lua_settable(L, -3);
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
		result = 1;	// 1 return argument, the table
	}
x	UpnpDiscovery_delete(acEvent);
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
static int decodeUpnpActionComplete(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
x	UpnpActionComplete* acEvent = (UpnpActionComplete*)mydata->Event;

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
		// TODO: DeviceId is in the documentation, but not in the code ???
		//lua_pushstring(L, "DeviceId");
		//lua_pushstring(L, UpnpDiscovery_get_DeviceId(dEvent));
		//lua_settable(L, -3);
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
		result = 1;	// 1 return argument, the table
	}
x	UpnpDiscovery_delete(acEvent);
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
static int decodeUpnpActionComplete(lua_State *L, void* pData, void* utilid)
{
	int result = 0;
	cbdelivery* mydata = (cbdelivery*)pData;
x	UpnpActionComplete* acEvent = (UpnpActionComplete*)mydata->Event;

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
		// TODO: DeviceId is in the documentation, but not in the code ???
		//lua_pushstring(L, "DeviceId");
		//lua_pushstring(L, UpnpDiscovery_get_DeviceId(dEvent));
		//lua_settable(L, -3);
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
		result = 1;	// 1 return argument, the table
	}
x	UpnpDiscovery_delete(acEvent);
	free(mydata);
	return result;
}

static int deliverUpnpActionRequest(Upnp_EventType EventType, const UpnpActionRequest *arEvent, void* cookie)
{
	int err = DSS_SUCCESS;
	cbdelivery* mydata = (cbdelivery*)malloc(sizeof(cbdelivery));

	if (mydata == NULL)
	{
		deliverUpnpCallbackError("Out of memory allocating 'mydata' for UpnpActionRequest callback.", cookie);
		return 0;
	}
	mydata->EventType = EventType;
	mydata->Event =  UpnpActionRequest_dup(arEvent);
	mydata->Cookie = cookie;
	if (mydata->Event == NULL)
	{
		deliverUpnpCallbackError("Out of memory duplicating 'event' for UpnpActionRequest callback.", cookie);
		free(mydata);
		return 0;
	}

	err = DSS_deliver(cookie, &decodeUpnpActionRequest, mydata);
	if (err != DSS_SUCCESS)
	{
		deliverUpnpCallbackError("Error delivering 'event' for UpnpActionRequest callback.", cookie);
		if (err != DSS_ERR_UDP_SEND_FAILED) // only in this case data is still delivered and shouldn't be released
		{
			UpnpActionRequest_delete((UpnpActionRequest *)mydata->Event);
			free(mydata);
		}
		return 0;
	}
	return 0;
}

