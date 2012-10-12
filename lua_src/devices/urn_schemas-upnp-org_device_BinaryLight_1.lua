

local switch = require("upnp.services.urn_schemas-upnp-org_service_SwitchPower_1")
local basic = require("upnp.devices.urn_schemas-upnp-org_device_Basic_1")

local function newdevice()
  local dev = basic.newdevice()
  dev.deviceType = "urn:schemas-upnp-org:device:BinaryLight:1"
  table.insert(dev.serviceList, switch.newservice())
return dev
