-- template for a LuaUPnP driver

local upnp = require('upnp')
upnp.devicefactory = require("upnp.devicefactory")
local logger = upnp.logger

local driver = {
  _NAME = ({...})[1],  -- the module name provide to 'require()'
  _VERSION = "0.1",
  _DESCRIPTION = "Demo3 driver, providing software only devices",
}
logger:info("Loading driver '%s' version %s; %s", driver._NAME, driver._VERSION, driver._DESCRIPTION)


-- utility function to print status for this demo application
local printstatus = function(self, power, level, callback)
  self = self:getdevice() -- redefine self, get containing device
  if type(level) == "function" then
    -- no level parameter: probably binary device
    callback = level
    level = nil
  end
  -- call callback first to report newly set values below
  callback()

  local s = "ON "
  if self.servicelist["urn:upnp-org:service:SwitchPower:1"]:getstatevariable("status"):get() == 0 then
    s = "OFF"
  end
  local l = "                "
  if level then
    l = string.format("at %03d%% (l = %02d)",
      self.servicelist["urn:upnp-org:service:Dimming:1"]:getstatevariable("loadlevelstatus"):get(),
      level)
  end
  local n = self.friendlyname
  n = "| " .. n .. string.rep(" ", 44 - #n) .. "|"
  print ("+---------------------------------------------+")
  print (n)
  print (string.format("|    Device is %s %s           |", s, l))
  print ("+---------------------------------------------+")
  print()
end


-- Will be called after loading the driver, should return a device table
function driver:getdevice()
  -- create a basic device for this demo driver
  local device = require("upnp.devices.urn_schemas-upnp-org_device_Basic_1")()
  device.friendlyName = "LuaUPnP demo3 driver"
	device.manufacturer = "Thijs Schreijer"
  device.manufacturerURL = "http://www.thijsschreijer.nl"
  device.modelDescription = "Demo3 showing 2 software only devices; BinaryLight and DimmableLight"
  device.modelName = "LuaUPnP demo3 driver"

  -- create the devices from a default implementation
  local binary = upnp.devicefactory.customizedevice(
    -- create a standard device
    upnp.devicefactory.createdevice("urn:schemas-upnp-org:device:BinaryLight:1"),
    -- apply a customization table
    { friendlyName = "Binary demo3 device",
      customList = {
        statetodevice = printstatus
      }
    })

  local dimmable = upnp.devicefactory.customizedevice(
    upnp.devicefactory.createdevice("urn:schemas-upnp-org:device:DimmableLight:1"),
    { friendlyName = "Dimmable demo3 device",
      customList = {
        statetodevice = printstatus
      }
    })
  -- add them to driver device
  table.insert(device.deviceList, binary)
  table.insert(device.deviceList, dimmable)

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
