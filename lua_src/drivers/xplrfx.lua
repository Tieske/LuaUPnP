-------------------------------------------------------------------
-- UPnP gateway driver for the rfxlan device with xPL firmware.
-- See <a href="../modules/upnp.bootstrap.html">upnp.bootstrap</a>, which is the 
-- entry point for loading the drivers.
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

logger:info("Loading driver '%s' version %s; %s", driver._NAME, driver._VERSION, driver._DESCRIPTION)

--===================================================
-- LOADING CONFIGURATION
--===================================================
local defaultconfig = {
    version = driver._VERSION,
    UDN = nil, -- will be created if not provided
    friendlyName = "LuaUPnP gateway driver for " .. driver._NAME,
    xpladdress = xpl.createaddress("tieske","luaupnp","RANDOM"),
    usehub = false,
    rfxxpladdress = xpl.createaddress("rfxcom","lan","macaddress"),
    xplbroadcast = "255.255.255.255",
    list = {},
  }

local configtext = string.format("LuaUPnP driver; '%s' version '%s'\n%s\n",driver._NAME, driver._VERSION, driver._DESCRIPTION)..[[

  Set options below;
  ==================
  xpladdress   : the xPL address for the driver (to announce on the xPL network) 
  xplbroadcast : broadcast address to send xPL messages to
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

-- create UUID if not present, store in 'config' so it can be persisted
if not config.UDN then config.UDN = upnp.lib.util.CreateUUID() end

--====================================================================================
-- DRIVER API IMPLEMENTATION
--====================================================================================

-- Will be called after loading the driver, should return a device table
function driver:getdevice()
  if driver.device then return driver.device end
  -- create a basic device for the driver
  local device = require("upnp.devices.urn_schemas-upnp-org_device_Basic_1")()
  device.friendlyName = config.friendlyName
	device.manufacturer = "manufacturer"
  device.manufacturerURL = "http://www.manufacturer.com"
  device.modelDescription = driver._DESCRIPTION
  device.modelName = driver._NAME .." "..driver._VERSION
  device.UDN = config.UDN
    
  -- generate all devices in the list
  for _,item in pairs(config.list) do
    -- create UUID if not set (set it here so it will be saved along with the config table)
    if not item.UDN then item.UDN = upnp.lib.util.CreateUUID() end

    -- create custom table for this device
    local ct = {
      friendlyName = item.friendlyName,
      UDN = item.UDN,
      customList = {
        devicedata = item,
        statetodevice = function(...) return driver.xpldevice.sendupnpcommand(...) end,
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
  driver.device = device
  return device
end

-- will be called to write the current configuration in a config file
function driver:writeconfig()
  logger:info("Driver '%s' is now writing its configuration file", self._NAME)
  return upnp.writeconfigfile(self._NAME, config, configtext)
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
-- setup the xPL configuration
--====================================================================================
xpl.settings.xplhub = config.usehub
xpl.settings.broadcast = config.xplbroadcast

--====================================================================================
-- Create our xPL device to communicate with the RFXLAN
--====================================================================================
driver.xpldevice = xpl.classes.xpldevice:new({    -- create a generic xPL device

  initialize = function(self)
    self.super.initialize(self)
    self.configurable = false
    self.version = driver._VERSION   -- make version be reported in heartbeats
    self.address = config.xpladdress
  end,

  start = function(self)
    self.super.start(self)
    logger:info("xplrfx: xPL device started %s", config.xpladdress)
  end,

  stop = function(self)
    logger:info("xplrfx: xPL device stopped %s", config.xpladdress)
    self.super.stop(self)
  end,

  statuschanged = function(self, newstatus, oldstatus)
    logger:info("xplrfx: xPL device changing status from '%s' to '%s'", oldstatus, newstatus)
    self.super.statuschanged(self, newstatus, oldstatus)
  end,
    
  -- Will send the actual UPnP change as an xPL message to the rfxlan device
  -- call as;
  --   sendupnpcommand(self, power, callback)         -- for binary devices
  --   sendupnpcommand(self, power, level, callback)  -- for dimmable devices
  sendupnpcommand = function(self, power, level, callback)
    -- NOTE: self == dimmable or binary light device object
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
    msg.source = config.xpladdress
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
      else
        -- already off, nothing to do
        msg = nil
      end
    else
      -- power on
      if binary then
        if self.lastpower then
          -- binary light, already on, so nothing to do
          msg = nil
        else
          -- binary light, must switch on now
          msg:setvalue("command", "on")
        end
      else
        if (self.lastpower == power) and (self.lastlevel == level) then
          -- dimmable, already right power and level, nothing to do
          msg = nil
        else
          -- dimmable, must set new level
          if msg.schema == "ac.basic" then
            msg:setvalue("command", "preset")
          else
            msg:setvalue("command", "dim")
          end
          msg:add("level", level)
        end
      end
    end
    
    if msg and self.devicedata.protocol == "ac-eu" then msg:add("eu", "true") end
    
    -- actually send the message
    if msg then
      msg = tostring(msg)
      logger:debug("xplrfx driver: now sending xplmessage:\n%s", msg)
      local success, err = driver.xpldevice:send(msg)
      if not success then
        logger:error("xplrfx driver: failed sending xPL message; %s", tostring(err))
      end
    else
      logger:debug("xplrfx driver: nothing send, old values '%s', '%s' require no change for new values '%s', '%s'", tostring(self.lastpower), tostring(self.lastlevel), tostring(power), tostring(level))
    end
    
    return callback() -- make sure to call callback before returning
  end
  
})


logger:info("Loaded driver %s", driver._NAME)
return driver