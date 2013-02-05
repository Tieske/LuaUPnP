-- template for a LuaUPnP driver

local upnp = require('upnp')
upnp.devicefactory = require("upnp.devicefactory")
local logger = upnp.logger

local driver = {
  _NAME = ({...})[1],  -- the module name provided to 'require()'
  _VERSION = "0.1",
  _DESCRIPTION = "Template driver code file",
}
logger:info("Loading driver '%s' version %s; %s", driver._NAME, driver._VERSION, driver._DESCRIPTION)

-- Will be called after loading the driver, should return a device table
function driver:getdevice()
  local device    -- device table to be filled here with device data
  
  -- fill it here
  
  return device
end

-- will be called when UPnP is starting, Copas scheduler will not yet be running, no sockets, no timers
function driver:starting()
  logger:info("Driver '%s' is now running the 'starting' event", self._NAME)
end

-- will be called when UPnP has started, copas is running, sockets and timers are running
function driver:started()
  logger:info("Driver '%s' is now running the 'started' event", self._NAME)
end

-- will be called when UPnP is stopping, copas is running, sockets and timers are running
function driver:stopping()
  logger:info("Driver '%s' is now running the 'stopping' event", self._NAME)
end

-- will be calling when UPnP has stopped, Copas scheduler will no longer be running, no sockets, no timers
function driver:stopped()
  logger:info("Driver '%s' is now running the 'stopped' event", self._NAME)
end


logger:info("Loaded driver %s", driver._NAME)
return driver