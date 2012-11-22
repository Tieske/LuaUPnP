#ifndef LuaUPnP_h
#define LuaUPnP_h

#include "upnp.h"
#include "upnptools.h"
#include "uuid.h"
#include <lua.h>
#include <lauxlib.h>
#include "luaIXML.h"
#include "darksidesync_aux.h"

// Define platform specific extern statement
#ifdef WIN32
	#define LPNP_API __declspec(dllexport)
#else
	#define LPNP_API extern
#endif

// Callback name in the registry
#define UPNPCALLBACK "LuaUPnP.callback"

// Metatable names to define objects
#define LPNP_LIBRARY_UD "LuaUPnP.LibUserData"	
#define LPNP_LIBRARY_MT "LuaUPnP.LibUserData.MT"	
#define LPNP_DEVICE_MT "LuaUPnP.Device"	
#define LPNP_CLIENT_MT "LuaUPnP.Client"	

// Registry (weak) table name with userdata references by pointers (lightuserdata)
#define LPNP_WTABLE_UPNP "LuaUPnP.UPnPuserdata"

// Required to track usage and free resources when all is out of scope
// Typedefinition for a record that points to a UPnP device
typedef struct LuaDevRecord *pLuaDevice;
typedef struct LuaDevRecord {
	// if Device == NULL, the device is closed/unopened
	UpnpDevice_Handle device;	
} LuaDevice;

// Typedefinition for a record that points to a UPnP client
typedef struct LuaClientRecord *pLuaClient;
typedef struct LuaClientRecord {
	// if Device == NULL, the client is closed/unopened
	UpnpClient_Handle client;	
} LuaClient;

// tracker for library being started or not
static int UPnPStarted;

struct _EventTypes {
	/*! Error code. */
	int et;
	/*! Error description. */
	const char *etTypeDesc;
};
struct _EventTypes EventTypes[] = {
	{UPNP_CONTROL_ACTION_REQUEST, "UPNP_CONTROL_ACTION_REQUEST"},
	{UPNP_CONTROL_ACTION_COMPLETE, "UPNP_CONTROL_ACTION_COMPLETE"},
	{UPNP_CONTROL_GET_VAR_REQUEST, "UPNP_CONTROL_GET_VAR_REQUEST"},
	{UPNP_CONTROL_GET_VAR_COMPLETE, "UPNP_CONTROL_GET_VAR_COMPLETE"},
	{UPNP_DISCOVERY_ADVERTISEMENT_ALIVE, "UPNP_DISCOVERY_ADVERTISEMENT_ALIVE"},
	{UPNP_DISCOVERY_ADVERTISEMENT_BYEBYE, "UPNP_DISCOVERY_ADVERTISEMENT_BYEBYE"},
	{UPNP_DISCOVERY_SEARCH_RESULT, "UPNP_DISCOVERY_SEARCH_RESULT"},
	{UPNP_DISCOVERY_SEARCH_TIMEOUT, "UPNP_DISCOVERY_SEARCH_TIMEOUT"},
	{UPNP_EVENT_SUBSCRIPTION_REQUEST, "UPNP_EVENT_SUBSCRIPTION_REQUEST"},
	{UPNP_EVENT_RECEIVED, "UPNP_EVENT_RECEIVED"},
	{UPNP_EVENT_RENEWAL_COMPLETE, "UPNP_EVENT_RENEWAL_COMPLETE"},
	{UPNP_EVENT_SUBSCRIBE_COMPLETE, "UPNP_EVENT_SUBSCRIBE_COMPLETE"},
	{UPNP_EVENT_UNSUBSCRIBE_COMPLETE, "UPNP_EVENT_UNSUBSCRIBE_COMPLETE"},
	{UPNP_EVENT_AUTORENEWAL_FAILED, "UPNP_EVENT_AUTORENEWAL_FAILED"},
	{UPNP_EVENT_SUBSCRIPTION_EXPIRED, "UPNP_EVENT_SUBSCRIPTION_EXPIRED"},
};

// async delivery struct
typedef struct _cbdelivery {
	Upnp_EventType EventType;
	void* Event;
	void* Cookie;
	void* Extra;	// just an extra pointer
	int handle;			// either client or device handle
} cbdelivery;


#include "luaUPnPsupport.h"
#include "luaUPnPcallback.h"

#endif  /* LuaUPnP_h */
