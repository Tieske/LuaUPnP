local logger = upnp.logger
local dimmer = require("upnp.services.urn_schemas-upnp-org_service_Dimming_1")
local binary = require("upnp.devices.urn_schemas-upnp-org_device_BinaryLight_1")

local newdevice = function()
  local dev = binary()
  dev.deviceType = "urn:schemas-upnp-org:device:DimmableLight:1"
  logger:info("Switching 'BinaryLight' to '"..dev.deviceType.."' device")
  
  local serv = dimming()
  serv.serviceId = "urn:upnp-org:device:Dimming:1"
  logger:info("adding '"..serv.serviceId.."' service")
  table.insert(dev.serviceList, serv)
  return dev
end

return newdevice