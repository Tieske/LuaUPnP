-- template for a LuaUPnP driver

-- throwing an error during startup will cancel loading and exit as fatal error.

local driver = {
  _NAME = string.match(" ."..({...})[1], ".+%.(.+)$"),  -- the module name (last element) as provided to 'require()'
  _VERSION = "0.1",
  _DESCRIPTION = "Template driver code file",
}
logger:info("Loading driver '%s' version %s; %s", driver._NAME, driver._VERSION, driver._DESCRIPTION)

local upnp = require('upnp')
upnp.devicefactory = require("upnp.devicefactory")
local logger = upnp.logger


--===================================================
-- LOADING CONFIGURATION
--===================================================
local defaultconfig = {
    version = driver._VERSION,
    UDN = nil, -- will be set automatically
    friendlyName = "LuaUPnP gateway driver for " .. driver._NAME
    -- add defaults here
    
  }
local configtext = string.format("LuaUPnP driver; '%s' version '%s'\n%s\n",driver._NAME, driver._VERSION, driver._DESCRIPTION)..[[
This is text that goes into the header of the config file, describe the options here.
]]

-- If no configuration file exists yet, try and write one with the defaults now
if not upnp.existsconfigfile(driver._NAME) then
  upnp.writeconfigfile(driver._NAME, defaultconfig, configtext)
end
configtext = nil

-- Load the configuration file
local config, err = upnp.readconfigfile(driver._NAME, defaultconfig)
if err then error("Error loading configuration file for " .. driver._NAME .."; " .. tostring(err)) end


if config.version ~= driver._VERSION then
  -- mismatch in driver version, do some upgrading?
  error(string.format("Configuration file version conflict; expected version %s, got %s", driver._VERSION, config.version))
end


--===================================================
-- DRIVER API IMPLEMENTATION
--===================================================

-- Will be called after loading the driver, should return a device table
function driver:getdevice()
  -- create a basic device for the driver
  local device = require("upnp.devices.urn_schemas-upnp-org_device_Basic_1")()
  device.friendlyName = config.friendlyName
	device.manufacturer = "manufacturer"
  device.manufacturerURL = "http://www.manufacturer.com"
  device.modelDescription = driver._DESCRIPTION
  device.modelName = driver._NAME .." "..driver._VERSION
  device.UDN = config.UDN
  
  
  -- Add some sub-devices to the driver device
  -- as example a standard BinaryLight device
  local binary = upnp.devicefactory.customizedevice(
    -- create a standard device
    upnp.devicefactory.createdevice("urn:schemas-upnp-org:device:BinaryLight:1"),
    -- apply a customization table
    { friendlyName = "Binary device",
      customList = {
        statetodevice = function(...) print(...) end
      }
    })
  
  -- add it to the driver device
  table.insert(device.deviceList, binary)
  
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