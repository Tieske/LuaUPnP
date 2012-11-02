-- default device properties
local dimlevels = 15    -- how many dim levels does the device support, count from 0 to dimlevels
local zeroisoff = true  -- if level is 0 is the Light then completely off?


local logger = upnp.logger
local dimmer = require("upnp.services.urn_schemas-upnp-org_service_Dimming_1")
local binary = require("upnp.devices.urn_schemas-upnp-org_device_BinaryLight_1")


--------------------------------------------------------------
-- Set device state, in the 'afterupdate' handler. It will instruct the
-- device to actually set the proper values in the hardware through calling
-- <code>device:statetodevice()</code>.
-- This method should be used as the handler for Dimming-loadLevelTarget and SwitchPower-Target variables.
-- @param self the statevariable table/object
-- @param oldval the previous value of the statevariable (will not be used)
local setstate = function(self, oldval)  -- self = variable object!
  local self = self:getdevice() -- redefine self
  local power = self.servicelist[1]:getstatevariable("target"):get()
  local level = self.servicelist[2]:getstatevariable("loadleveltarget"):get()
    
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
    self.servicelist[1]:getvariable("status"):set(power)
    self.servicelist[2]:getvariable("loadlevelstatus"):set(level)
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

---------------------------------------------------------------
-- Sets provided values into the actual device (hardware). This method must be overriden
-- to communicate with the hardware.
-- <br><strong>NOTE:</strong> setting values in hardware might require use of a coroutine
-- for a socket/IO scheduler. Hence the <code>callback<code> to allow the creation of (for
-- example) a Copas task to send the command to the hardware over an outgoing TCP connection. 
-- If you do not do this when using possibly blocking IO calls, then the call might become a 
-- blocking call, freezing the entire engine.
-- @param self (table) dimmablelight device object
-- @param power (boolean) powerstate to set (<code>true</code> = on)
-- @param level (integer) dim device level to set (0 to <code>dimlevels</code>)
-- @param callback (function) callback function to call when hardware has been updated (has no arguments)
local statetodevice = function(self, power, level, callback)
  logger:error("setdevicestate method on a DimmableLight device has not been set!! must implement it")
end

---------------------------------------------------------------
-- Sets provided values into the UPnP device (software representation). This method must be
-- called from the devicedriver to update changes from the hardware to the UPnP device.
-- @param self (table) dimmablelight device object
-- @param power (boolean) powerstate to set (true = on)
-- @param level (integer) dim level to set (0 to dimlevels)
local statefromdevice = function(self, power, level)
  if power == self.lastpower and level = self.lastlevel then
    -- nothing changed, no updates, do nothing
  else
    
  end
end

local newdevice = function()
  -- start with a binary light, then update
  local dev = binary()
  dev.deviceType = "urn:schemas-upnp-org:device:DimmableLight:1"
  logger:info("Switching 'BinaryLight' to '"..dev.deviceType.."' device")
  
  -- add dimmer service
  local serv = dimming()
  serv.serviceId = "urn:upnp-org:device:Dimming:1"
  logger:info("adding '"..serv.serviceId.."' service")
  table.insert(dev.serviceList, serv)
  
  -- update device elements
  dev.dimlevels = dimlevels
  dev.zeroisoff = zeroisoff
  dev.lastpower = nil
  dev.lastlevel = nil
  -- add methods to interact with hardware
  dev.statefromdevice = statefromdevice
  dev.statetodevice = statetodevice
  -- set the afterupdate handlers for Target and LoadLevelTarget variables
  dev.servicelist[1].serviceStateTable[1].afterupdate = setstate -- add update method for Power; Switch service is nr 1 in list, Target is variable 1
  dev.servicelist[2].serviceStateTable[1].afterupdate = setstate -- add update method for Dimmer; LoadLevelStatus is nr 1 in variablelist
  
  return dev
end

return newdevice