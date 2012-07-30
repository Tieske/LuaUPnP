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
local super = upnp.classes.upnpbase
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
local device = super:subclass({
    devicetype = nil,               -- device type
    --_udn = nil,                      -- device udn (unique device name; UUID)
    parent = nil,                   -- owning UPnP device of this service
    servicelist = nil,              -- table with services, indexed by serviceid
    devicelist = nil,               -- table with sub-devices, indexed by udn
    classname = classname,          -- set object classname
})

-----------------------------------------------------------------------------------------
-- Initializes the statevariable object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function device:initialize()
    logger:debug("Initializing class '%s' as '%s' with id '%s'.", classname, tostring(self.friendlyname), tostring(self._udn or self.udn))
    -- initialize ancestor object
    super.initialize(self)
    -- set defaults

    logger:debug("Initializing class '%s' completed", classname)
end

local creator -- trick LuaDoc to generate the documentation for this one
-----------------------------------------------------------------------------------------
-- Description of the "creator" callback function as it has to be provided to "device:parsefromxml()".
-- This function allows to create the device object hierarchy with custom objects, implemented the required
-- device behaviour. The most common case being to override the <code>action:execute(params)</code> method.
-- NOTE: if the classname "servicexml" a string should be returned allowing the collection of the service
-- description xml.
-- @param plist list of named properties as parsed from the xml, eg. a device could expect a key-value pair
-- <code>friendlyname = "name as specified in xml"</code>. NOTE: alle keys have been converted to lowercase!!
-- @param classname the type of object (or descendant of that type) to be created, this will be any of the
-- following; "device", "service", "statevariable", "action", "argument", or "servicexml".
-- @param parent The parent object to which the requested object will be added. The parent property on the
-- created object will be set afterwards, no need to set it here.
-- @returns object type as requested, to be created by calling <code>objectbaseclass:new(plist)</code>, which
-- will instantiate a new class and set the properties from plist accordingly. EXCEPTION: if class "servicexml"
-- is requested, a string with the service xml should be returned, the string should be parseable by the
-- <code>upnp.getxml()<code> function.
-- @remark if <code>nil</code> is returned, then a standard base class will be instatiated. If "servicexml" was
-- requested, and nothing is returned, an attempt will be made to combine the <code>upnp.webroot</code> value
-- with the <code>SCPDURL</code> element from the device description to locate the xml.
creator = function(plist, classname, parent)
end
creator = nil   -- delete again, only created for documentation purposes

-----------------------------------------------------------------------------------------
-- Device constructor method, creates a new device, parsed from a device xml.
-- The device object will be created, including all services and sub devices.
-- @param xmldoc XML document from which a device is to be parsed, this can be either 1)
-- a string value containing the xml, 2) a string value containing the filename of the xml
-- 3) an IXML object containing the 'device' element
-- @param creator callback function to create individual sub objects
-- @param parent the parent object for the device to be created (or nil if a root device)
-- @returns device object
function device:parsefromxml(xmldoc, creator, parent)
    assert(creator == nil or type(creator) == "function", "parameter creator should be a function or be nil, got " .. type(creator))
    logger:debug("Entering device:parsefromxml()")
    creator = creator or function() end -- empty function if not provided
    local xml = upnp.lib.ixml
    local success, idoc, ielement, err
    idoc, err = upnp.getxml(xmldoc)
    if not idoc then
        return nil, err
    end

    local t = xml.getNodeType(idoc)
    if t ~= "ELEMENT_NODE" and t ~= "DOCUMENT_NODE" then
        return nil, "Expected an XML element or document node, got " .. tostring(t)
    end
    if t == "ELEMENT_NODE" and idoc:getNodeName() ~= "device" then
        return nil, "Expected an XML element named 'device', got " .. tostring(idoc:getNodeName())
    end
    if t == "ELEMENT_NODE" then
        ielement = idoc
    end

    if idoc:getNodeType() == "DOCUMENT_NODE" then
        logger:debug("device:parsefromxml(), looking for 'device' element in XML doc")
        ielement = idoc:getFirstChild()     -- get root element
        if ielement then ielement = ielement:getFirstChild() end  -- get first content element
        while ielement and string.lower(ielement:getNodeName()) ~= "device" do
            ielement = ielement:getNextSibling()
        end
        if not ielement then
            return nil, "XML document does not contain a 'device' element to parse"
        end
    end
    -- ielement now contains the 'device' element, get started parsing...
    local slist, dlist  -- reference to servicelist element and devicelist element
    local plist = {}    -- property list for device object
    ielement = ielement:getFirstChild()
    while ielement do
        local name = string.lower(ielement:getNodeName())

        if ielement:getNodeType() == "ELEMENT_NODE" then
            if name == "servicelist" then
                logger:debug("device:parsefromxml(), found 'servicelist' element")
                slist = ielement
            elseif name == "devicelist" then
                logger:debug("device:parsefromxml(), found 'devicelist' element")
                dlist = ielement
            else
                local value, n = nil, nil
                n = ielement:getFirstChild()
                while n and n:getNodeType() ~= "TEXT_NODE" do
                    n = n:getNextSibling()
                end
                if n then   -- store property value
                    plist[name] = n:getNodeValue()
                    logger:debug("device:parsefromxml(), found property '%s' @ '%s'", name, plist[name])
                end
                n = nil
            end
        end
        ielement = ielement:getNextSibling()
    end
    -- a list with properties has been compiled in plist
    -- now go create an object with it.
    logger:debug("device:parsefromxml(), instantiating device through 'creator'")
    local dev = creator(plist, "device", parent)
    if not dev then
        logger:debug("device:parsefromxml(), 'creator' didn't deliver, now instantiating a generic device base class")
        dev = upnp.classes.device(plist)
    end
    if dev then
        dev.parent = parent
        if dev.udn then
            -- set UDN properly, add to gloabl lists
            dev:setudn(dev.udn)
            dev.udn = nil
        end
    end

    -- append services
    if dev and slist then
        local s = slist:getFirstChild()
        local scount = 0
        while s do
            if string.lower(s:getNodeName()) == "service" then
                -- it is a service element, go create it
                -- first get a list of properties (from the DEVICE xml)
                scount = scount + 1
                logger:debug("device:parsefromxml(), service found; %d", scount)
                plist = {}   -- reinitialize
                ielement = s:getFirstChild()
                while ielement do
                    local name = string.lower(ielement:getNodeName())

                    if ielement:getNodeType() == "ELEMENT_NODE" then
                        local value, n = nil, nil
                        n = ielement:getFirstChild()
                        while n and n:getNodeType() ~= "TEXT_NODE" do
                            n:getNextSibling()
                        end
                        if n then   -- store property value
                            plist[name] = n:getNodeValue()
                            logger:debug("device:parsefromxml(), service element found %s @ %s", name, tostring(plist[name]))
                        end
                        n = nil
                    end
                    ielement = ielement:getNextSibling()
                end
                -- basics from the device XML have been collected, now get the service XML
                logger:debug("device:parsefromxml(), collecting service-xml through 'creator'")
                local sdoc = creator(plist, "servicexml", dev)
                if not sdoc then
                    -- nothing was returned, so try construct location from url in device xml
                    logger:warn("device:parsefromxml(), 'creator' didn't deliver, using scpdurl field as xml location; %s", tostring(plist.scpdurl))
                    sdoc = plist.scpdurl
                end
                -- go fetch it
                sdoc, err = upnp.classes.service:parsefromxml(sdoc, creator, dev, plist)
                if not sdoc then
                    -- couldn't parse service, so exit
                    logger:error("device:parsefromxml(), parsing the servicexml failed; %s", tostring(err))
                    dev:setudn(nil) -- remove created device
                    return nil, "Failed parsing a service; " .. tostring(err)
                end
                -- add service to device
                success, err = pcall(dev.addservice, dev, sdoc)
                if not success then
                    logger:error("device:parsefromxml(), Failed adding the service to the device; %s", tostring(err))
                    dev:setudn(nil) -- remove created device
                    return nil, "Failed adding parsed service to device; " .. tostring(err)
                end
            end
            s = s:getNextSibling()  -- next service in serviceList xml element
        end
        s = nil
        slist = nil
    end

    -- append sub-devices
    if dev and dlist then
        local s = dlist:getFirstChild()
        local dcount = 0
        while s do
            if string.lower(s:getNodeName()) == "device" then
                -- it is a subdevice element, go create it
                dcount = dcount + 1
                logger:debug("device:parsefromxml(), sub-device found; %d", scount)
                local sd = upnp.classes.device:parsefromxml(s, creator, dev)
                if not sd then
                    -- couldn't parse device, so exit
                    logger:error("device:parsefromxml(), parsing the sub-device failed; %s", tostring(err))
                    dev:setudn(nil) -- remove created device
                    return nil, "Failed parsing a sub-device"
                end
                -- add sub device to device
                success, err = pcall(dev.adddevice, dev, sd)
                if not success then
                    logger:error("device:parsefromxml(), Failed adding the sub-device to the device; %s", tostring(err))
                    dev:setudn(nil) -- remove created device
                    return nil, "Failed adding parsed sub-device to device; " .. tostring(err)
                end
            end
            s = s:getNextSibling()
        end
        s = nil
        dlist = nil
    end

    return dev
end

-----------------------------------------------------------------------------------------
-- Gets the udn (unique device name; UUID) of the device.
-- @returns udn of the device
function device:getudn()
    return self._udn
end

-----------------------------------------------------------------------------------------
-- Sets the udn (unique device name; UUID) of the device.
-- Set it to <code>nil</code> to remove it from the global list and parent object (its own
-- <code>parent</code> property will remain unchanged)
-- @param newudn New udn for the device
function device:setudn(newudn)
    logger:debug("device:setudn(), setting device udn; %s", tostring(newudn))
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
    if newudn then
        if self.parent then
            -- update parent list
            self.parent.devicelist[self._udn] = self
        end
        -- update global list
        upnp.devices[self._udn] = self
    end
end

-----------------------------------------------------------------------------------------
-- Adds a service to the device.
-- @param service service object to add
function device:addservice(service)
    logger:debug("device:addservice(), adding service")
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
    logger:debug("device:adddevice(), adding sub-device")
    assert(type(device) ~= "table", "Expected device table, got nil")
    assert(device._udn, "Sub-device udn (unique device name; UUID) not set, can't add to device")
    -- add to list
    self.devicelist = self.devicelist or {}
    self.devicelist[device._udn] = device
    -- update device
    device.parent = self
end

-----------------------------------------------------------------------------------------
-- Startup handler. Called for the event <code>upnp.events.UPnPstarted</code> (event
-- through the Copas Timer eventer mechanism)
-- When called it will call the <code>start()</code> method on all sub-devices. Override
-- in child classes to add specific startup functionality (starting hardware comms for example)
-- See also <code>upnpbase:start()</code>
function device:start()
    logger:debug("entering device:start(), starting device  %s...", tostring(self._udn))
    -- start ancestor object
    self.super.start(self)
    -- start all sub-devices
    for _, dev in pairs(self.devicelist) do
        dev:start()
    end
    logger:error("leaving device:start()")
end

-----------------------------------------------------------------------------------------
-- Shutdown handler. Called for the event <code>upnp.events.UPnPstopping</code> (event
-- through the Copas Timer eventer mechanism)
-- When called it will call the <code>stop()</code> method on all sub-devices. Override
-- in child classes to add specific shutdown functionality (stopping hardware comms for example)
-- See also <code>upnpbase:stop()</code>
function device:stop()
    logger:debug("entering device:stop(), stopping device  %s...", tostring(self._udn))
    -- stop all sub-devices
    for _, dev in pairs(self.devicelist) do
        dev:stop()
    end
    -- stop ancestor object
    self.super.stop(self)
    logger:debug("leaving device:stop()")
end

return device
