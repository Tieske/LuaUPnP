

local dimmer = require("upnp.services.urn_schemas-upnp-org_service_Dimming_1")
local binary = require("upnp.devices.urn_schemas-upnp-org_device_BinaryLight_1")

local function newdevice()
  local dev = binary.newdevice()
  dev.deviceType = "urn:schemas-upnp-org:device:DimmableLight:1"
  table.insert(dev.serviceList, dimming.newservice())
return dev
