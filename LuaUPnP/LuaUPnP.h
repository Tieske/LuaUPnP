#ifndef LuaUPnP_h
#define LuaUPnP_h

#include "upnp.h"
#include "upnptools.h"
#include <lua.h>
#include <lauxlib.h>

// Define platform specific extern statement
#ifdef WIN32
	#define LPNP_API __declspec(dllexport)
#else
	#define LPNP_API extern
#endif

// Metatable names to define objects
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
	// if Device == NULL, the device is closed/unopened
	UpnpClient_Handle client;	
} LuaClient;

#endif  /* LuaUPnP_h */