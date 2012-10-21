
local export = {}
local dimmer = require("upnp.services.urn_schemas-upnp-org_service_Dimming_1")
local binary = require("upnp.devices.urn_schemas-upnp-org_device_BinaryLight_1")

export.newdevice = function()
  local dev = binary.newdevice()
  dev.deviceType = "urn:schemas-upnp-org:device:DimmableLight:1"
  
  local serv = dimming.newservice()
  serv.ServiceId = "urn:upnp-org:device:Dimming:1"
  table.insert(dev.serviceList, serv)
  return dev
end

return export