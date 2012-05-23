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

static int deliverUpnpActionComplete(Upnp_EventType EventType, const UpnpActionComplete *acEvent, void* cookie)
{
	// TODO: implement
}

static int deliverUpnpStateVarComplete(Upnp_EventType EventType, const UpnpStateVarComplete *svcEvent, void* cookie)
{
	// TODO: implement
}

static int deliverUpnpEvent(Upnp_EventType EventType, const UpnpEvent *eEvent, void* cookie)
{
	// TODO: implement
}

static int deliverUpnpEventSubscribe(Upnp_EventType EventType, const UpnpEventSubscribe *esEvent, void* cookie)
{
	// TODO: implement
}

static int deliverUpnpSubscriptionRequest(Upnp_EventType EventType, const UpnpSubscriptionRequest *srEvent, void* cookie)
{
	// TODO: implement
}

static int deliverUpnpStateVarRequest(Upnp_EventType EventType, const UpnpStateVarRequest *svrEvent, void* cookie)
{
	// TODO: implement
}

static int deliverUpnpActionRequest(Upnp_EventType EventType, const UpnpActionRequest *arEvent, void* cookie)
{
	// TODO: implement
}

