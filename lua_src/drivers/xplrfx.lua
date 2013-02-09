-------------------------------------------------------------------
-- UPnP driver file for the rfxlan device with xPL firmware.
-- When 'required' will process its config file and setup devices.
-- @class module
-- @name upnp.drivers.xplrfx


-- throwing an error during startup will cancel loading and exit as fatal error.

local driver = {
  _NAME = string.match(" ."..({...})[1], ".+%.(.+)$"),  -- the module name (last element) as provided to 'require()'
  _VERSION = "0.1",
  _DESCRIPTION   = "UPnP gateway driver for RFXCOM (see www.rfxcom.com) device xPL RFXLAN"
}

local upnp = require('upnp')
upnp.devicefactory = require("upnp.devicefactory")
local logger = upnp.logger
local xpl = require('xpl')
local xpldev    -- forward declaration

logger:info("Loading driver '%s' version %s; %s", driver._NAME, driver._VERSION, driver._DESCRIPTION)

--===================================================
-- LOADING CONFIGURATION
--===================================================
local defaultconfig = {
    version = driver._VERSION,
    friendlyName = "LuaUPnP gateway driver for " .. driver._NAME,
    xpladdress = xpl.createaddress("tieske","luaupnp","RANDOM"),
    usehub = false,
    rfxxpladdress = xpl.createaddress("rfxcom","lan","macaddress"),
    list = {},
  }

local configtext = string.format("LuaUPnP driver; '%s' version '%s'\n%s\n",driver._NAME, driver._VERSION, driver._DESCRIPTION)..[[

  Set options below;
  ==================
  xpladdress   : the xPL address for the driver (to announce on the xPL network) 
  usehub       : set whether the internal xPL hub should be used (true/false)
                 Do not use it when your system already runs an xPL hub.
  rfxxpladdress: the xPL address of the rfxlan device
  UDN          : UUID, will be set automatically if not provided
  friendlyName : the friendly name for the driver device, max 63 chars
  
  list         : List of devices known, each device has the following elements
  {  -- device start
     -- UPnP properties
    ["friendlyName"] = "short friendly name max 63 chars", 
    ["UDN"]      = nil,          -- will be set automatically if not provided
     -- device properties for RFXLAN
    ["dimmer"]   = true|false,   -- does the device have a dimming capability?
    ["protocol"] = "ac-uk|ac-eu|arc|x10|flamingo|koppla|waveman|harrison|he105|rts10",
    ["address"]  = "device address according to protocol",  -- eg. "A1" for an X10 device; 
    ["unit"]     = number,       -- only for ac-eu and ac-uk protocols,
  }, -- device end, repeat block
  
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

if config.rfxxpladdress == defaultconfig.rfxxpladdress then
  error("no xPL address has been set for the RFXLAN device. Edit configfile to add it.")
end

if not config.list or #config.list == 0 then
  -- could not load configfile, or no devices, write one
  error("The configuration file has no devices configured. Please add some.")
end

--====================================================================================
-- DRIVER API IMPLEMENTATION
--====================================================================================

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
  
  local sendcommand = function(self, power, level, callback)
    -- self == dimmable or binary light device object
    local binary = (type(level) == "function")
    if binary then
      -- binary device: has no 'level' parameter, so shift 'level' value to 'callback'
      callback = level
      level = nil
    end
    logger:debug("%s; power = %s, level = %s", self.friendlyname, tostring(power), tostring(level))
    
    -- create xPL message
    local msg = xpl.classes.xplmessage:new({})
    msg.type = "xpl-cmnd" 
    msg.target = config.rfxxpladdress
    if self.devicedata.protocol == "ac-eu" or self.devicedata.protocol == "ac-uk" then
      msg.schema = "ac.basic"
      msg:add("address", self.devicedata.address)
      msg:add("unit", self.devicedata.unit)
      msg:add("command","")
    else
      msg.schema = "x10.basic"
      msg:add("device", self.devicedata.address)
      msg:add("command","")
      if self.devicedata.protocol ~= "x10" then msg:add("protocol", self.devicedata.protocol) end
    end
    
    if not power then
      -- power off
      if self.lastpower then
        -- currently on, so must switch off
        msg:setvalue("command", "off")
print("power off, now")        
      else
        -- already off, nothing to do
        msg = nil
print("power off, already off")        
      end
    else
      -- power on
      if binary then
        if self.lastpower then
          -- binary light, already on, so nothing to do
          msg = nil
print("binary: power on, already on")          
        else
          -- binary light, must switch on now
          msg:setvalue("command", "on")
print("binary: power on, now")          
        end
      else
        if (self.lastpower == power) and (self.lastlevel == level) then
          -- dimmable, already right power and level, nothing to do
print("dimmable: equal, already done", power, level, self.lastpower, self.lastlevel)          
          msg = nil
        else
          -- dimmable, must set new level
          if msg.schema == "ac.basic" then
            msg:setvalue("command", "preset")
          else
            msg:setvalue("command", "dim")
          end
          msg:add("level", level)
print("dimmable: not equal, set now")          
        end
      end
    end
    
    if msg and self.devicedata.protocol == "ac-eu" then msg:add("eu", "true") end
    
    -- actually send the message
    if msg then
      msg = tostring(msg)
      xpldev:send(msg)
      logger:debug("xplrfx driver: send xplmessage:\n%s", msg)
    else
      logger:debug("xplrfx driver: nothing send, old values '%s', '%s' require no change for new values '%s', '%s'", tostring(self.lastpower), tostring(self.lastlevel), tostring(power), tostring(level))
    end
    
    return callback() -- make sure to call callback before returning
  end
  
  -- generate all devices in the list
  for _,item in pairs(config.list) do
    -- create custom table for this device
    local ct = {
      friendlyName = item.friendlyName,
      UDN = item.UDN,
      customList = {
        devicedata = item,
        statetodevice = sendcommand,
        zeroisoff = (item.protocol ~= "ac-eu" and item.protocol ~= "ac-uk")
      }  
    }
    
    -- determine device type to create
    local dt
    if item.dimmer then
      dt = "urn:schemas-upnp-org:device:DimmableLight:1"
    else
      dt = "urn:schemas-upnp-org:device:BinaryLight:1"
    end
    
    -- create device, and add it to the driver as subdevice
    local dev = upnp.devicefactory.customizedevice(upnp.devicefactory.createdevice(dt), ct)
    table.insert(device.deviceList, dev)
  end
  
  -- all sub devices added, now return driver device (containing all subs)
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

--====================================================================================
-- setup the xPL hub
--====================================================================================
xpl.xplhub = config.usehub

--====================================================================================
-- Create our xPL device to communicate with the RFXLAN
--====================================================================================
xpldev = xpl.classes.xpldevice:new({    -- create a generic xPL device

    initialize = function(self)
        self.super.initialize(self)
        self.configurable = false
        self.version = driver._VERSION   -- make version be reported in heartbeats
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



logger:info("Loaded driver %s", driver._NAME)
return driver