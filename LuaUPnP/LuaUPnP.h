#ifndef LuaUPnP_h
#define LuaUPnP_h

#include "LuaIXML.h"
#include <lua.h>
#include <lauxlib.h>

// Define platform specific extern statement
#ifdef WIN32
	#define LPNP_API __declspec(dllexport)
#else
	#define LPNP_API extern
#endif

// Metatable names to define objects
//#define LPNP_NODE_MT "LuaUPnP.Node"	


#endif  /* LuaUPnP_h */