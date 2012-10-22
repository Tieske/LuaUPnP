local logger = upnp.logger
local switch = require("upnp.services.urn_schemas-upnp-org_service_SwitchPower_1")
local basic = require("upnp.devices.urn_schemas-upnp-org_device_Basic_1")

local newdevice = function()
  local dev = basic()
  dev.deviceType = "urn:schemas-upnp-org:device:BinaryLight:1"
  logger:info("Switching 'Basic' to '"..dev.deviceType.."' device")
  
  local serv = switch()
  serv.serviceId = "urn:upnp-org:device:SwitchPower:1"
  logger:info("adding '"..serv.serviceId.."' service")
  table.insert(dev.serviceList, serv)
  return dev
end

return newdevice
