---------------------------------------------------------------------
-- The base object for UPnP devices.
-- @class module
-- @name upnp.classes.device
-- @copyright 2012 <a href="http://www.thijsschreijer.nl">Thijs Schreijer</a>, <a href="http://github.com/Tieske/LuaUPnP">LuaUPnP</a> is licensed under <a href="http://www.gnu.org/licenses/gpl-3.0.html">GPLv3</a>
-- @release Version 0.1, LuaUPnP

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
-- Members of the device object
-- @class table
-- @name device fields/properties
-- @field _udn device udn (unique device name; UUID). Do not access directly, use <code>device:getudn(), device:setudn()</code>
-- @field parent owning device, or <code>nil</code> if it is a root device
-- @field devicelist list of sub-devices, ordered by their UDN
-- @field servicelist list of services, ordered by their serviceid
-- @field devicexmlurl the url to the device XML (relative to the <codce>upnp.webroot</code> directory), this only applies
-- to root-devices
local device = super:subclass()

-----------------------------------------------------------------------------------------
-- Initializes the device object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function device:initialize()
    logger:debug("Initializing class '%s' as '%s' with id '%s'.", classname, tostring(self.friendlyname), tostring(self._udn or self.udn))
    -- initialize ancestor object
    super.initialize(self)
    -- set defaults
    --self.devicetype = nil               -- device type
    --_udn = nil                          -- device udn (unique device name; UUID)
    self.parent = nil                   -- owning UPnP device of this service
    self.classname = classname          -- set object classname
    self.devicelist = {}
    self.servicelist = {}
    logger:debug("Initializing class '%s' completed", classname)
end

local creator -- trick LuaDoc to generate the documentation for this one
-----------------------------------------------------------------------------------------
-- Description of the "creator" callback function as it has to be provided to <code>parsefromxml()</code>.
-- This function allows to create the device object hierarchy with custom objects, implementing the required
-- device behaviour. The most common case being to override the <code>action:execute(params)</code> method.
-- @param plist list of named properties as parsed from the xml, eg. a device could expect a key-value pair
-- <code>friendlyname = "name as specified in xml"</code>. NOTE: all keys have been converted to lowercase!!
-- @param classname the type of object (or descendant of that type) to be created, this will be any of the
-- following; <code>"device", "service", "statevariable", "action", "argument",</code> or <code>"servicexml"</code>.
-- @param parent The parent object to which the requested object will be added. The parent property on the
-- created object will be set afterwards, no need to set it here (<code>nil</code> for a root-device).
-- @return object type as requested, to be created by calling <code>objectbaseclass:new(plist)</code>, which
-- will instantiate a new class and set the properties from plist accordingly. EXCEPTION: if class <code>servicexml</code>
-- is requested, a string with the service xml should be returned, the string should be parseable by the
-- <a href="upnp.html#upnp.getxml"><code>upnp.getxml()</code></a> function. If <code>nil</code> is returned, then a standard baseclass of the requested type 
-- will be instatiated. If <code>"servicexml"</code> was
-- requested, and <code>nil</code> is returned, an attempt will be made to combine the <code>upnp.webroot</code> value
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
-- @param parent the parent object for the device to be created (or <code>nil</code> if a root device)
-- @return device object or <code>nil + error message</code>
-- @see creator
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
                local n = nil
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
                        local n = nil
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
                -- service basics from the device XML have been collected, now get the service XML
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
                logger:debug("device:parsefromxml(), sub-device found; %d", dcount)
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
-- @return udn of the device
function device:getudn()
    return self._udn
end

-----------------------------------------------------------------------------------------
-- Sets the udn (unique device name; UUID) of the device. Adds the device to the global device list.
-- Set it to <code>nil</code> to remove it from the global list and parent object (its own
-- <code>parent</code> property will remain unchanged)
-- @param newudn New udn for the device
function device:setudn(newudn)
    logger:info("device:setudn(), setting device udn; %s", tostring(newudn))
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
    assert(type(service) == "table", "Expected service table, got nil")
    assert(service.serviceid, "ServiceId not set, can't add to device")
    logger:info("device:addservice(), adding service; %s", tostring(service.serviceid))
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
    assert(type(device) == "table", "Expected device table, got nil")
    assert(device._udn, "Sub-device udn (unique device name; UUID) not set, can't add to device")
    -- add to list
    self.devicelist = self.devicelist or {}
    self.devicelist[device._udn] = device
    -- update device
    device.parent = self
end

-----------------------------------------------------------------------------------------
-- Handler called before the new value is set to an owned statevariable (through a service).
-- The new value will have been checked and converted before this handler is called.
-- Override in descendant classes to implement device behaviour. While the <code>afterset()</code> will only
-- be called when the value being set is actually different from the current value, the <code>beforeset()</code>
-- will always be run. Hence, <code>beforeset()</code> has the opportunity to change the value being set.
-- <br>Call order; <code>statevariable:beforeset() -&gt; service:beforeset() -&gt; device:beforeset()</code>
-- @param service the service (table/object) the statevariable is located in
-- @param statevariable the statevariable (table/object) whose value is being changed
-- @param newval the new value to be set
-- @return newval to be set (Lua type) or <code>nil, error message, error number</code> upon failure
-- @see statevariable:beforeset
-- @see device:afterset
function device:beforeset(service, statevariable, newval)
  return newval
end

-----------------------------------------------------------------------------------------
-- Handler called after the new value has been set to an owned statevariable (through a service).
-- <br/><strong>NOTE:</strong> this will only be called when the value
-- has actually changed, so setting the current value again will not trigger it!
-- Override in descendant classes to implement device behaviour.
-- <br>Call order; <code>statevariable:afterset() -&gt; service:afterset() -&gt; device:afterset()</code>
-- @param service the service (table/object) the statevariable is located in
-- @param statevariable the statevariable (table/object) whose value is being changed
-- @param oldval the previous value of the statevariable
-- @see statevariable:beforeset
-- @see device:beforeset
function device:afterset(service, statevariable, oldval)
end

-----------------------------------------------------------------------------------------
-- Executes an action on a service owned by the device.
-- <br>Call order: <code>device:executeaction() -&gt; action:checkparams() -&gt; service:executeaction() -&gt; action:execute() -&gt; action:checkresults()</code>
-- @param serviceid ServiceId string, or service table/object
-- @param actionname Name of the action to execute, or action table/object
-- @param params table with argument values, indexed by argument name.
-- @return 2 lists (names and values) of the 'out' arguments (in proper UPnP order), or <code>nil, errormsg, errornumber</code> upon failure
-- @see service:executeaction
-- @see action:execute
-- @see action:checkparams
-- @see action:checkresults
function device:executeaction(serviceid, actionname, params)
  logger:debug("device:executeaction(), entering...")
  -- find service
  local service
  if type(serviceid) == "table" then
    service = serviceid
  else
    service = self.servicelist[tostring(serviceid)]
    if not service then
      return nil, "Action Failed; no service '" .. tostring(serviceid) .. "'", 501
    end
  end
  logger:debug("device:executeaction(), service was found...")
  -- find action
  local action
  if type(actionname) == "table" then
    action = actionname
  else
    action = service.actionlist[string.lower(tostring(actionname))]
    if not action then
      return nil, "Invalid Action; no action by name '" .. actionname .. "'", 401
    end
  end
  logger:debug("device:executeaction(), action was found...")
  -- check params
  local checked, errmsg, errnr
  checked, errmsg, errnr = action:checkparams(params or {})
  if not checked then
    return nil, errmsg, errnr
  end
  logger:debug("device:executeaction(), parameters checked and passed...")
  -- execute action
  local success, results
  success, results, errmsg, errnr = pcall(service.executeaction, service, action, checked)
  if not success then
      -- pcall error...
      logger:error("service:executeaction() failed (pcall); %s", tostring(results))
      errnr = 501
      errmsg = "Action Failed. Internal error; " .. tostring(results)
      return nil, errmsg, errnr
  end
  if not results and (errmsg ~= nil or errnr ~= nil) then
      -- execution failed
      logger:error("service:executeaction() failed (returned error); %s %s", tostring(errnr), tostring(errmsg))
      return nil, errmsg, errnr
  end
  -- return updated checked and formatted results (or nil + error info)
  logger:debug("device:executeaction(), checking results and exiting")
  return action:checkresults(results)
end

-----------------------------------------------------------------------------------------
-- Startup handler. Called by <code>upnpbase</code> ancestor object for the event <code>upnp.events.UPnPstarted</code> (event
-- through the Copas Timer eventer mechanism)
-- When called it will call the <code>start()</code> method on all sub-devices. Override
-- in child classes to add specific startup functionality (starting hardware comms for example)
-- See also <a href="upnp.upnpbase.html#upnpbase:start"><code>upnpbase:start()</code></a>
function device:start()
    logger:debug("entering device:start(), starting device  %s...", tostring(self._udn))
    assert(self.handle == nil, "Cannot start device, device handle is already available, stop first.")
    -- start ancestor object
    super.start(self)

    -- register with UPnP lib to go online
    if not self.parent then
        -- only start with lib when I'm a root device
        local err
        self.handle, err = upnp.startdevice(self)
        if not self.handle then
            logger:fatal("device:start(); upnp lib could not start device: %s", tostring(err))
            copas:exitloop()
            return
        end
    end

    -- start all sub-devices
    for _, dev in pairs(self.devicelist) do
        dev:start()
    end
    logger:debug("leaving device:start()")
end

-----------------------------------------------------------------------------------------
-- Shutdown handler. Called by <code>upnpbase</code> ancestor object for the event <code>upnp.events.UPnPstopping</code> (event
-- through the Copas Timer eventer mechanism)
-- When called it will call the <code>stop()</code> method on all sub-devices. Override
-- in child classes to add specific shutdown functionality (stopping hardware comms for example)
-- See also <a href="upnp.upnpbase.html#upnpbase:start"><code>upnpbase:stop()</code></a>
function device:stop()
    logger:debug("entering device:stop(), stopping device  %s...", tostring(self._udn))
    -- stop all sub-devices
    for _, dev in pairs(self.devicelist) do
        dev:stop()
    end

    -- unregister
    if not self.parent then     -- this is a root device
        local dev = self:gethandle()
        if dev then
            upnp.stopdevice(dev)
        end
        self.handle = nil       -- erase handle
        self:clearlazyness()    -- handle is gone, so propagate change
    end
    -- stop ancestor object
    super.stop(self)
    logger:debug("leaving device:stop()")
end

-- Clears all the lazy-elements set. Applies to <code>getaction(), getservice(), getdevice(),
-- getroot(), gethandle()</code> methods.
-- Override in subclasses to clear tree-structure.
function device:clearlazyness()
    super.clearlazyness(self)
    for _, dev in pairs(self.devicelist or {}) do
        dev:clearlazyness()
    end
    for _, serv in pairs(self.servicelist or {}) do
        serv:clearlazyness()
    end
end

return device
