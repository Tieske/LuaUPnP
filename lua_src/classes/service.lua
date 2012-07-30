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
local classname = "service"

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
local service = upnp.classes.upnpbase:subclass({
    servicetype = nil,              -- service type
    serviceid = nil,                -- service id
    parent = nil,                   -- owning UPnP device of this service
    actionlist = nil,               -- table with actions, indexed by name
    statetable = nil,               -- table with statevariables, indexed by name
    classname = classname,          -- set object classname
})

-----------------------------------------------------------------------------------------
-- Initializes the statevariable object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function service:initialize()
    logger:debug("Initializing class '%s' named '%s'...", classname, tostring(self.name))
    -- initialize ancestor object
    self.super.initialize(self)
    -- set defaults

    logger:debug("Initializing class '%s' completed", classname)

end

-- Parse the element 'actionList' (in lst) into service (in serv), while 'creator' creates required objects
local parseactionlist = function(lst, creator, serv)
    local success
    local elem = lst:getFirstChild()
    while elem do
        if string.lower(elem:getNodeName()) == "action" then
            -- create action
            local act, err = upnp.classes.action:parsefromxml(elem, creator, serv)
            if not act then
                return nil, "Failed to add an action; " .. tostring(err)
            end
            -- add action to service
            success, err = pcall(serv.addaction, serv, act)
            if not success then
                return nil, "Failed to add a parsed action; " .. tostring(err)
            end
        end
        elem = elem:getNextSibling()
    end
    return 1    -- report success
end

-- Parse the element 'serviceStateTable' (in lst) into service (in serv), while 'creator' creates required objects
local parsevariablelist = function(lst, creator, serv)
    local success
    local elem = lst:getFirstChild()
    while elem do
        if string.lower(elem:getNodeName()) == "statevariable" then
            -- create statevariable
            local variable, err = upnp.classes.statevariable:parsefromxml(elem, creator, serv)
            if not variable then
                return nil, "Failed to add a variable; " .. tostring(err)
            end
            -- add variable to service
            success, err = pcall(serv.addaction, serv, variable)
            if not success then
                return nil, "Failed to add a parsed variable; " .. tostring(err)
            end
        end
        elem = elem:getNextSibling()
    end
    return 1    -- report success
end

-----------------------------------------------------------------------------------------
-- Service constructor method, creates a new service, parsed from a service xml.
-- The service object will be created, including all its children.
-- @param xmldoc XML document from which a service is to be parsed, this can be either 1)
-- a string value containing the xml, 2) a string value containing the filename of the xml
-- 3) an IXML object containing the 'service' element
-- @param creator callback function to create individual sub objects
-- @param parent the parent object for the service to be created
-- @param plist key-value list with service properties already parsed from the Device XMLs 'serviceList' element.
-- @returns service object
function service:parsefromxml(xmldoc, creator, parent, plist)
    assert(creator == nil or type(creator) == "function", "parameter creator should be a function or be nil, got " .. type(creator))
    creator = creator or function() end -- empty function if not provided

    local xml = upnp.lib.ixml
    local success, idoc, ielement, err

    idoc, err = upnp.getxml(xmldoc)
    if not idoc then
        return nil, err
    end

    local t = idoc:getNodeType()
    if t ~= "ELEMENT_NODE" and t ~= "DOCUMENT_NODE" then
        return nil, "Expected an XML element or document node, got " .. tostring(t)
    end
    if t == "ELEMENT_NODE" and idoc:getNodeName() ~= "service" then
        return nil, "Expected an XML element named 'service', got " .. tostring(idoc:getNodeName())
    end
    if t == "ELEMENT_NODE" then
        ielement = idoc
    end

    if t == "DOCUMENT_NODE" then
        ielement = idoc:getFirstChild()     -- get root element
        if ielement then ielement = ielement:getFirstChild() end  -- get first content element
        while ielement and string.lower(ielement:getNodeName()) ~= "device" do
            ielement = ielement:getNextSibling()
        end
        if not ielement then
            return nil, "XML document does not contain a 'service' element to parse"
        end
    end
    -- ielement now contains the 'service' element
    -- go create service object
    local serv = (creator(plist, "service", parent) or upnp.classes.service:new(plist))

    -- get started parsing...
    local lst = ielement:getFirstChild()
    local vlist, alist = nil, nil
    while lst do
        local name = string.tolower(lst:getNodeName())
        if name == "actionlist"            then alist = lst
        elseif name == "servicestatetable" then vlist = lst
        else
            -- some other element, do nothing
        end
        lst = lst:getNextSibling();
    end
    -- now first parse the variable list, to make sure that action arguments can find the related variables
    if vlist then
        success, err = parsevariablelist(vlist, serv)
        if not success then
            return nil, "Error parsing serviceStateTable element; " .. tostring(err)
        end
    end
    if alist then
        success, err = parseactionlist(alist, serv)
        if not success then
            return nil, "Error parsing actionList element; " .. tostring(err)
        end
    end

    return serv
end

-----------------------------------------------------------------------------------------
-- Adds a statevariable to the service statetable.
-- @param statevar statevariable object to add
function service:addstatevariable(statevar)
    assert(type(statevar) ~= "table", "Expected statevariable table, got nil")
    assert(statevar.name, "Statevariable name not set, can't add to service")
    -- add to list
    self.statetable = self.statetable or {}
    self.statetable[statevar.name] = statevar
    -- update statevariable
    statevar.parent = self
end

-----------------------------------------------------------------------------------------
-- Adds an action to the service actionlist.
-- @param action action object to add
function service:addaction(action)
    assert(type(action) ~= "table", "Expected action table, got nil")
    assert(action.name, "Action name not set, can't add to service")
    -- add to list
    self.actionlist = self.actionlist or {}
    self.actionlist[action.name] = action
    -- update action
    action.parent = self
end

-----------------------------------------------------------------------------------------
-- Execute an action of the service.
-- @param actionname (string) name of action to execute
-- @param params (table) table of parameter values, keyed by parameter names
-- @returns 2 lists (names and values) of the 'out' arguments (in proper order), or nil, errormsg, errornumber upon failure
function service:executeaction(actionname, params)
    params = params or {}
    actionname = tostring(actionname or "")
    local action = (self.actionlist or {})[actionname]
    if action then
        -- found, execute it
        return action:_execute(params)
    else
        -- not found, error out
        return nil, "Invalid Action; no action by name '" .. actionname .. "'", 401
    end
end

-----------------------------------------------------------------------------------------
-- Creates a list of all variables and values, to be provided when a subscription is accepted
-- @returns list with variablenames
-- @returns list with variablevalues (order matching the name list)
function service:getupnpvalues()
    local names = {}
    local values = {}
    for _, v in pairs(self.statetable) do
        table.insert(names, v.name)
        table.insert(values, v:getupnp())
    end
    return names, values
end

return service
