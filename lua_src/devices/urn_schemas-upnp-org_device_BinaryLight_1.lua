---------------------------------------------------------------------------
-- Standard device; "urn:schemas-upnp-org:device:BinaryLight:1".
-- When required, it returns a single function which generates a new device table 
-- on every call (it takes no parameters). The <code>upnp.devicefactory</code> module 
-- takes the device/service tables to build device/service objects.
-- <br><br>Requires to implement the following elements;
-- </p>
-- <ul>
-- <li><code>device.statetodevice</code> handler to update device status when 
-- the target value has changed on the UPnP side</li>
-- </ul>
-- <p>
-- @class module
-- @name urn_schemas-upnp-org_device_BinaryLight_1

-----------------------------------------------------------------------------------------
-- Members of the BinaryLight object
-- @class table
-- @name BinaryLight fields/properties
-- @field lastpower (boolean) the last power value set in/received from the hardware

local logger = upnp.logger
local switch = require("upnp.services.urn_schemas-upnp-org_service_SwitchPower_1")
local basic = require("upnp.devices.urn_schemas-upnp-org_device_Basic_1")

-- Set device state, in the 'afterset' handler. It will instruct the
-- device to actually set the proper values in the hardware through calling
-- <code>device:statetodevice()</code>.
-- This method should be used as the handler for the SwitchPower-Target variable.
-- @param self the statevariable table/object
-- @param oldval the previous value of the statevariable (will not be used)
local setpower = function(self, oldval)  -- self = variable object!
  local power = self:getstatevariable("target"):get()
  local devpower = (power == 1)

  local cb = function()  -- in a function to prepare for a coroutine
    -- set results to statevars, sending UPnP events
    self:getstatevariable("status"):set(power)
  end

  -- set the device (only if changed from last time)
  if self.lastpower ~= devpower then
    self:statetodevice(devpower, cb) -- provide cb to allow for coroutine in an IO scheduler
    self.lastpower = devpower
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
-- @param self (table) binarylight device object
-- @param power (boolean) powerstate to set (<code>true</code> = on)
-- @param callback (function) callback function to call when hardware has been updated (has no arguments)
statetodevice = function(self, power, callback)
  logger:error("setdevicestate method on a BinaryLight device has not been set!! must implement it")
end


local statefromdevice -- local to trick luadoc
---------------------------------------------------------------
-- Sets provided values into the UPnP device (software representation). This method must be
-- called from the devicedriver to update changes from the hardware to the UPnP device.
-- @param self (table) binarylight device object
-- @param power (boolean) powerstate to set (<code>true</code> = on)
statefromdevice = function(self, power, level)
  if power == self.lastpower then
    -- nothing changed, no updates, do nothing
  else
    -- go update
    self.lastpower = power
    if power then
      self:getaction("settarget").execute( { newtargetvalue = "1" } )
    else
      self:getaction("settarget").execute( { newtargetvalue = "0" } )
    end
  end
end

local newdevice = function()
  local dev = basic()
  dev.deviceType = "urn:schemas-upnp-org:device:BinaryLight:1"
  logger:info("Switching 'Basic' to '"..dev.deviceType.."' device")
  
  local serv = switch()
  serv.serviceId = "urn:upnp-org:service:SwitchPower:1"
  logger:info("adding '"..serv.serviceId.."' service")
  table.insert(dev.serviceList, serv)
  
  -- set the update handlers for Target variable
  dev.serviceList[1].serviceStateTable[1].afterset = setpower -- add update method for Power; Switch service is nr 1 in list, Target is variable 1
  
  -- update device elements in customList
  dev.customList = dev.customList or {}
  dev.customList.lastpower = nil
  -- add methods to interact with hardware
  dev.customList.statefromdevice = statefromdevice
  dev.customList.statetodevice = statetodevice
  
  return dev
end

return newdevice
