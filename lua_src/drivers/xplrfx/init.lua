-------------------------------------------------------------------
-- UPnP driver file for the rfxlan device with xPL firmware.
-- When 'required' will process its config file and setup devices.
-- @class module
-- @name upnp.drivers.xplrfx

local driver = {}
driver.version        = "0.1"
driver.name           = "xplrfx"
driver._COPYRIGHT     = "Copyright (C) 2012 Thijs Schreijer"
driver._DESCRIPTION   = "UPnP gateway driver for RFXCOM (see www.rfxcom.com) device xPL RFXLAN"
driver._VERSION       = driver.name .. " " .. driver.version
driver.configfilename = driver.name

local configfilecore = [=[

-- Configuration file for the rfxlan device with xPL firmware

return {
  
  -- the xPL address for the driver (to announce on the xPL network)
  xpladdress = "%s", 

  -- set whether the internal xPL hub should be used (true/false)
  usehub = %s,
  
  -- the xPL address of the rfxlan device to use
  rfxxpladdress = "%s", 
  
  -- Device list, each device has the following elements
  ["list"] = { -- list start
%s
  } -- list end

}
]=]
local configdevice = [=[
  { -- device start
    ["friendlyName"] = "%s", 
    ["udn"] = "%s",
    ["dimmer"] = %s,
    ["protocol"] = "%s",
    ["address"] = "%s",
    ["unit"] = %s,
  }, -- device end, repeat block
]=]

local upnp = require("upnp")
local logger = upnp.logger
logger:info("Loading xplrfx driver")
local copas = require("copas.timer")
require("copas.eventer")
local xpl = require("xpl")

--====================================================================================
-- Read configuration
--====================================================================================

logger:debug("Loading configuration file; "..driver.configfilename)
local config, err = upnp.readconfigfile(driver.configfilename)
if not config then
  logger:error("Could not load configfile: " .. tostring(err))
end
config = config or {}
if not config.xpladdress then
  config.xpladdress = xpl.createaddress("tieske","upnp","RANDOM")
  logger:warn("no xPL address set, now setting: " .. config.xpladdress)
end
if not config.rfxxpladdress then
  config.rfxxpladdress = xpl.createaddress("rfxcom","lan","macaddress")
  logger:warn("no rfxlan xPL address set, now setting: " .. config.rfxxpladdress)
end
if not config.usehub then config.usehub = false else config.usehub = true end

if not config.list or #config.list == 0 then
  -- could not load configfile, or no devices, write one
  local dev = configdevice:format(
      "short friendly name max 63 chars",
      "nil,  -- will be set automatically if not provided",
      "[true|false]",
      '"[ac-uk|ac-eu|arc|x10|flamingo|koppla|waveman|harrison|he105|rts10]"',
      '"device address according to protocol"',
      "number, -- only for ac-eu and ac-uk protocols")
  local content = configfilecor:format(config.xpladdress, tostring(config.usehub), config.rfxxpladdress, dev)

  logger:warn("Writing a sample config file for the xplrfx driver: "..driver.configfilename.."-sample")
  if not upnp.writeconfigfile(driver.configfilename.."-sample", content) then
    logger:error("Unable to write a sample config file for the xplrfx driver")
  end
  return nil, "no config file, or no devices in the list"
end

driver.config = config
logger:debug("Configuration loaded; "..driver.configfilename)
logger:debug(config)

--====================================================================================
-- setup the xPL hub
--====================================================================================
xpl.xplhub = config.usehub

--====================================================================================
-- Create our device
--====================================================================================
local xpldev = xpl.classes.xpldevice:new({    -- create a generic xPL device

    initialize = function(self)
        self.super.initialize(self)
        self.configurable = true
        self.version = driver.version   -- make version be reported in heartbeats
        self.address = config.xpladdress
    end,

    --[[ overriden to request a heartbeat on startup it set to do so.
    start = function(self)
        self.super.start(self)
        if opt.hbeat then
            local m = "xpl-cmnd\n{\nhop=1\nsource=%s\ntarget=*\n}\nhbeat.request\n{\ncommand=request\n}\n"
            m = string.format(m, self.address)
            xpl.send(m)
        end
    end,
--]]

    --[[ deal with incoming messages
    handlemessage = function(self, msg)
        local sizeup = function (t, l)
            if #t < l then return t .. string.rep(" ", l - #t) end
            if #t > l then return string.sub(t, 1, l) end
            return t
        end
        -- call ancestor to handle hbeat messages
        self.super.handlemessage(self, msg)
        -- now do my thing
        local log = ""
        log = sizeup(log .. msg.type, 9)
        log = sizeup(log .. msg.schema, #log + 18)
        log = sizeup(log .. msg.source, #log + 35)
        log = sizeup(log .. msg.target, #log + 35)
        log = sizeup(log .. msg.from,   #log + 22)
        print (log)
        if opt.verbose then
            for key, value in msg:eachkvp() do
                log = "   "
                log = sizeup(log .. key, #log + 16) .. "=" .. value
                print(log)
            end
        end
    end,
    --]]
    
})

-- sends an xpl message to the xPLRFX device. Either a power on/off or set dimm level
-- command.
-- @param self UPnP device, must contain a key 'xplrfx' holding the deviceconfig table
-- @param value boolean in case of "power" or number (0-100) in case of "dim"
-- @param lastvalue optional old value, see return value (set to <code>nil</code> to force
-- sending a command even if the same as the last.
-- @return the value for the device being set. Use this in next call to prevent
-- sending messages (% difference, but same level) unnecessary.
local sendcommand = function(self, value, lastvalue)
  local command, level
  local protocol = self.xplrfx.protocol
  local address = self.xplrfx.address
  local unit = self.xplrfx.unit
  local msg = xpl.classes.xplmessage:new({})
  
  msg.type = "xpl-cmnd" 
  msg.target = config.rfxxpladdress
  
  if type(value) == "boolean" then
    command = value and "on" or "off"
  else
    command = "dim"
    level = math.floor(tonumber(value) + .5)
    if level < 0 then level = 0 end
    if level > 100 then level = 100 end
  end
  
  if protocol == "ac-eu" or protocol == "ac-uk" then
    if command == "dim" then command = "preset" end
    msg.schema = "ac.basic"
    msg:add("address", address)
    msg:add("unit", unit)
    msg:add("command", command)
    if level then
      level = math.floor(level/(100/(15+1)))
      if level > 15 then level = 15 end
      msg:add("level", tostring(level))
    end
    if protocol == "ac-eu" then msg:add("eu", "true") end
  else
    msg.schema = "x10.basic"
    msg:add("device", address)
    msg:add("command", command)
    if level then msg:add("level", value) end
    if protocol ~= "x10" then msg:add("protocol", protocol) end
  end
  if type(value) ~= "boolean" then
    value = level
  end
  if value ~= lastvalue then
    msg = tostring(msg)
    xpldev:send(msg)
    logger:debug("xplrfx driver: send xplmessage:\n" .. msg)
  else
    logger:debug("xplrfx driver: nothing send, old value '%s' (%s) is the same as new value '%s' (%s)", tostring(lastvalue), type(lastvalue), tostring(value), type(value))
  end
  return value
end

