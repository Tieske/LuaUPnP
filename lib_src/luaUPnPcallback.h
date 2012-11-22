#ifndef LuaUPnPcallback_h
#define LuaUPnPcallback_h

//#include <ixml.h>
//#include <lua.h>
//#include <lauxlib.h>
//#include "luaIXML.h"
#include "luaUPnP.h"

/*
** ===============================================================
**   UPnP callback handling
** ===============================================================
*/
int deliverUpnpDiscovery(Upnp_EventType EventType, const UpnpDiscovery *dEvent, void* cookie);
int deliverUpnpActionComplete(Upnp_EventType EventType, const UpnpActionComplete *acEvent, void* cookie);
int deliverUpnpStateVarComplete(Upnp_EventType EventType, const UpnpStateVarComplete *svcEvent, void* cookie);
int deliverUpnpEvent(Upnp_EventType EventType, const UpnpEvent *eEvent, void* cookie);
int deliverUpnpEventSubscribe(Upnp_EventType EventType, const UpnpEventSubscribe *esEvent, void* cookie);
int deliverUpnpSubscriptionRequest(Upnp_EventType EventType, const UpnpSubscriptionRequest *srEvent, void* cookie);
int deliverUpnpStateVarRequest(Upnp_EventType EventType, const UpnpStateVarRequest *svrEvent, void* cookie);
int deliverUpnpActionRequest(Upnp_EventType EventType, const UpnpActionRequest *arEvent, void* cookie);

#endif  /* LuaUPnPcallback_h */