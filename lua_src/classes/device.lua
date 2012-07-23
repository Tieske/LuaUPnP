---------------------------------------------------------------------
-- The base object for xPL devices. It features all the main characteristics
-- of the xPL devices, so only user code needs to be added. Starting, stopping,
-- regular heartbeats, configuration has all been implemented in this base class.<br/>
-- <br/>No global will be created, it just returns the xpldevice base class. The main
-- xPL module will create a global <code>xpl.classes.xpldevice</code> to access it.<br/>
-- <br/>You can create a new device from; <code>xpl.classes.xpldevice:new( {} )</code>,
-- but it is probably best to use the
-- <a href="../files/src/xpl/new_device_template.html">new_device_template.lua</a>
-- file as an example on how to use the <code>xpldevice</code> class
-- @class module
-- @name xpldevice
-- @copyright 2011 Thijs Schreijer
-- @release Version 0.1, LuaxPL framework.

-- set the proper classname here, this should match the filename without the '.lua' extension
local classname = "device"

-----------------
-- LOCAL STUFF --
-----------------


--------------------------
-- CLASS IMPLEMENTATION --
--------------------------

-----------------------------------------------------------------------------------------
-- Members of the statevariable object
-- @class table
-- @name statevariable fields/properties
-- @field name name of the statevariable
-- @field evented indicator for the variable to be an evented statevariable
-- @field _value internal field holding the value, use <code>get, set</code> and <code>getupnp</code> methods for access
-- @field _datatype internal field holding the UPnP type, use <code>getdatatype</code> and <code>setdatatype</code> methods for access
local device = upnp.classes.upnpbase:subclass({
    devicetype = nil,               -- device type
    --_udn = nil,                      -- device udn (unique device name; UUID)
    parent = nil,                   -- owning UPnP device of this service
    servicelist = nil,              -- table with services, indexed by serviceid
    devicelist = nil,               -- table with sub-devices, indexed by udn
})

-----------------------------------------------------------------------------------------
-- Initializes the statevariable object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function device:initialize()
    -- initialize ancestor object
    super.initialize(self)
    -- update classname
    self.classname = classname
    -- set defaults
    _udn = nil
end

-----------------------------------------------------------------------------------------
-- Gets the udn (unique device name; UUID) of the device.
-- @returns udn of the device
function device:setudn()
    return self._udn
end

-----------------------------------------------------------------------------------------
-- Sets the udn (unique device name; UUID) of the device.
-- @param newudn New udn for the device
function device:setudn(newudn)
    assert(type(newudn) == "string", "Expected UDN as string, got nil")

    if self._udn then
        -- already set, go clear existing stuff
        if self.parent then
            -- remove from parents device list
            self.parent.devicelist[self._udn] = nil
        end
        -- remove from global list
        upnp.devices[self._udn] = nil
    end
    -- set new values
    self._udn = newudn
    if self.parent then
        -- update parent list
        self.parent.devicelist[self._udn] = self
    end
    -- update global list
    upnp.devices[self._udn] = self
end

-----------------------------------------------------------------------------------------
-- Adds a service to the device.
-- @param service service object to add
function device:addservice(service)
    assert(type(service) ~= "table", "Expected service table, got nil")
    assert(service.serviceid, "ServiceId not set, can't add to device")
    -- add to list
    self.servicelist = self.servicelist or {}
    self.servicelist[service.serviceid] = service
    -- update service
    service.parent = self
end

-----------------------------------------------------------------------------------------
-- Adds a sub-device to the device.
-- @param device device object to add
function device:adddevice(device)
    assert(type(device) ~= "table", "Expected device table, got nil")
    assert(device._udn, "Sub-device udn (unique device name; UUID) not set, can't add to device")
    -- add to list
    self.devicelist = self.devicelist or {}
    self.devicelist[device._udn] = device
    -- update device
    device.parent = self
end


return device
