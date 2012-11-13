---------------------------------------------------------------------------
-- Standard device; "urn:schemas-upnp-org:device:DimmableLight:1".
-- When required, it returns a single function which generates a new device table 
-- on every call (it takes no parameters). The <code>upnp.devicefactory</code> module 
-- takes the device/service tables to build device/service objects.
-- <br><br>Requires to implement the following elements;
-- </p>
-- <ul>
-- <li><code>device.statetodevice</code> handler to update device status when the target values have changed on the UPnP side</li>
-- </ul>
-- <p>
-- @class module
-- @name urn_schemas-upnp-org_device_DimmableLight_1

-----------------------------------------------------------------------------------------
-- Members of the DimmableLight object
-- @class table
-- @name DimmableLight fields/properties
-- @field dimlevels (integer) the number of levels the device supports, indexed from 0 (eg. 15 means levels 0-15, so 16 levels)
-- @field zeroisoff (boolean) when <code>true</code> then the device is completely off at dimlevel 0
-- @field lastpower (boolean) the last power value set in/received from the hardware
-- @field lastlevel (integer) the last dimlevel value set in/received from the hardware

-- default device properties
local dimlevels = 15    -- how many dim levels does the device support, count from 0 to dimlevels
local zeroisoff = true  -- if level is 0 is the Light then completely off?

local logger = upnp.logger
local dimmer = require("upnp.services.urn_schemas-upnp-org_service_Dimming_1")
local binary = require("upnp.devices.urn_schemas-upnp-org_device_BinaryLight_1")


-- Set device state, in the 'afterset' handler. It will instruct the
-- device to actually set the proper values in the hardware through calling
-- <code>device:statetodevice()</code>.
-- This method should be used as the handler for Dimming-loadLevelTarget and SwitchPower-Target variables.
-- @param self the statevariable table/object
-- @param oldval the previous value of the statevariable (will not be used)
local setstate = function(self, oldval)  -- self = variable object!
  local self = self:getdevice() -- redefine self
  local switch = self.servicelist["urn:upnp-org:service:SwitchPower:1"]
  local dimmer = self.servicelist["urn:upnp-org:service:Dimming:1"]
  local power = switch:getstatevariable("target"):get()
  local level = dimmer:getstatevariable("loadleveltarget"):get()

  -- calculate device level and powerstate from % level
  local levels = self.dimlevels
  if not self.zeroisoff then levels = levels + 1 end  -- off is an extra level
  local devlevel = math.floor((level/(100/(levels-1)))+0.5)
  local devpower = (power == 1)
  if devlevel < 1 then devpower = false end
  if not self.zeroisoff then devlevel = devlevel - 1 end  -- remove extra level
  if devlevel < 1 then
    devlevel = 0
  elseif devlevel > self.dimlevels then
    devlevel = self.dimlevels
  end

  local cb = function()  -- in a function to prepare for a coroutine
    -- set results to statevars, sending UPnP events
    self.servicelist["urn:upnp-org:service:SwitchPower:1"]:getstatevariable("status"):set(power)
    self.servicelist["urn:upnp-org:service:Dimming:1"]:getstatevariable("loadlevelstatus"):set(level)
  end

  -- set the device (only if changed from last time)
  if self.lastpower ~= devpower or self.lastlevel ~= devlevel then
    self:statetodevice(devpower, devlevel, cb) -- provide cb to allow for coroutine in an IO scheduler
    self.lastpower = devpower
    self.lastlevel = devlevel
  else
    -- didn't change on hardware level, so set values and send events now
    cb()
  end
end

local statetodevice -- local to trick luadoc
---------------------------------------------------------------
-- Sets provided values into the actual device (hardware). This method must be overriden
-- to communicate with the hardware.
-- <br><strong>NOTE:</strong> setting values in hardware might require use of a coroutine
-- for a socket/IO scheduler. Hence the <code>callback</code> to allow the creation of (for
-- example) a Copas task to send the command to the hardware over an outgoing TCP connection.
-- If you do not do this when using possibly blocking IO calls, then the call might become a
-- blocking call, freezing the entire engine.
-- @param self (table) dimmablelight device object
-- @param power (boolean) powerstate to set (<code>true</code> = on)
-- @param level (integer) dim device level to set (0 to <code>dimlevels</code>)
-- @param callback (function) callback function to call when hardware has been updated (has no arguments)
statetodevice = function(self, power, level, callback)
  logger:error("statetodevice() method on a DimmableLight device has not been set!! must implement it")
end


local statefromdevice -- local to trick luadoc
---------------------------------------------------------------
-- Sets provided values into the UPnP device (software representation). This method must be
-- called from the devicedriver to update changes from the hardware to the UPnP device.
-- @param self (table) dimmablelight device object
-- @param power (boolean) powerstate to set (<code>true</code> = on)
-- @param level (integer) dim level to set (0 to dimlevels)
statefromdevice = function(self, power, level)
  if power == self.lastpower and level == self.lastlevel then
    -- nothing changed, no updates, do nothing
  else
    -- go update
    self.lastlevel = level
    self.lastpower = power
    levels = self.dimlevels
    if not self.zeroisoff then
      level = level + 1
      levels = levels + 1
    end
    local target = math.floor(100/(levels-1)*level + 0.5)
    self.servicelist["urn:upnp-org:service:Dimming:1"]:getaction("setloadleveltarget").execute( { newloadleveltarget = target } )
    if power then
      self.servicelist["urn:upnp-org:service:SwitchPower:1"]:getaction("settarget").execute( { newtargetvalue = "1" } )
    else
      self.servicelist["urn:upnp-org:service:SwitchPower:1"]:getaction("settarget").execute( { newtargetvalue = "0" } )
    end
  end
end

-- Stops the device while stopping ramping to close timers.
-- @param self (table) dimmablelight device object
local stopdimmablelight = function(self)
  self.servicelist["urn:upnp-org:service:Dimming:1"]:getaction("stopramp"):execute()
  upnp.classes.device.stop(self)
end

-- Stops ramping upon powering off a device, and sets the OnEffect upon powering up a device.
-- @param self (table) statevariable object
local powerbeforeset = function(self, newval)
  local dimmer = self:getdevice().servicelist["urn:upnp-org:service:Dimming:1"]
  if newval == 0 then
    -- being switched off
    dimmer:getaction("stopramp"):execute()
  end
  if newval == 1 and self:getstatevariable("status"):get() == 0 then
    -- being switched on
    if dimmer:getstatevariable("oneffect"):get() == "OnEffectLevel" then
      -- must set OnEffectLevel before powering up
      dimmer:getstatevariable("loadleveltarget"):set(dimmer:getstatevariable("oneffectlevel"):get())
    end
  end
  return newval
end

-- Handles the 'Default' value for OnEffect.
-- @param self (table) statevariable object
local oneffectbeforeset = function(self, newval)
  if newval == "Default" then
    return self.defaultvalue
  end
  return newval
end

local newdevice = function()
  -- start with a binary light, then update
  local dev = binary()
  dev.deviceType = "urn:schemas-upnp-org:device:DimmableLight:1"
  logger:info("Switching 'BinaryLight' to '"..dev.deviceType.."' device")

  -- add dimmer service
  local serv = dimmer()
  serv.serviceId = "urn:upnp-org:service:Dimming:1"
  logger:info("adding '"..serv.serviceId.."' service")
  table.insert(dev.serviceList, serv)

  -- set the update handlers for Target and LoadLevelTarget variables and start/stop methods
  dev.stop = stopdimmablelight
  dev.serviceList[1].serviceStateTable[1].afterset = setstate -- add update method for Power; Switch service is nr 1 in list, Target is variable 1
  dev.serviceList[1].serviceStateTable[1].beforeset = powerbeforeset
  dev.serviceList[2].serviceStateTable[1].afterset = setstate -- add update method for Dimmer; LoadLevelStatus is nr 1 in variablelist
  dev.serviceList[2].serviceStateTable[4].beforeset = oneffectbeforeset  -- OnEffect is nr 4 in variablelist
  
  -- update device elements in customList
  dev.customList = dev.customList or {}
  dev.customList.dimlevels = dimlevels
  dev.customList.zeroisoff = zeroisoff
  dev.customList.lastpower = nil
  dev.customList.lastlevel = nil
  -- add methods to interact with hardware
  dev.customList.statefromdevice = statefromdevice
  dev.customList.statetodevice = statetodevice

  return dev
end

return newdevice
