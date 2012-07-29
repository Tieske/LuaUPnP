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
local classname = "argument"

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
local argument = upnp.classes.upnpbase:subclass({
    name = "",                      -- argument name
    statevariable = nil,            -- related statevariable object
    direction = "in",               -- in/out going argument, either "in" or "out"
    position = 0,                   -- position in the actions argument list
    parent = nil,                   -- owning UPnP action of this argument
    classname = classname,          -- set object classname
})

-----------------------------------------------------------------------------------------
-- Initializes the argument object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function argument:initialize()
    logger:debug("Initializing class '%s' named '%s'...", classname, tostring(self.name))
    -- initialize ancestor object
    super.initialize(self)
    logger:debug("Initializing class '%s' completed", classname)
end

-----------------------------------------------------------------------------------------
-- Argument constructor method, creates a new argument, parsed from an XML 'argument' element.
-- @param xmldoc an IXML object containing the 'argument' element
-- @param creator callback function to create individual sub objects
-- @param parent the parent object for the argument to be created
-- @param service the service to attach to. Required because the parent relationships in the
-- hierarchy haven't been set yet while parsing and the argument needs to access the statevariable
-- list to check whether the related statevariable actually exists
-- @returns argument object
function argument:parsefromxml(xmldoc, creator, parent, service)
    assert(creator == nil or type(creator) == "function", "parameter creator should be a function or be nil, got " .. type(creator))
    creator = creator or function() end -- empty function if not provided
    local plist = {}    -- property list to create the object from after the properties have been parsed
    local ielement = xmldoc:getFirstChild()
    while ielement do
        local n = nil
        n = string.lower(ielement:getNodeName())
        if n == "retval" then
            plist[n] = true
        else
            plist[n] = ielement:getNodeValue()
        end
    end
    -- check statevariable
    if not plist.relatedstatevariable or not service.statetable[plist.relatedstatevariable] then
        return nil, "Error cannot attach statevariable to parsed argument, statevariable not found; " .. tostring(plist.relatedstatevariable)
    end
    -- attach statevariable
    plist.statevariable = service.statetable[plist.relatedstatevariable]
    plist.relatedstatevariable = nil
    -- go create the object
    local arg = (creator(plist, "argument", parent) or upnp.classes.argument:new(plist))

    return arg  -- the parsing action will add it to the parent action
end

-----------------------------------------------------------------------------------------
-- Formats the argument value in upnp format.
-- @param value the Lua typed value to be formatted as UPnP type, according to the UPnP type set
-- in the related statevariable for this argument
-- @returns The value in UPnP format as a Lua string.
function argument:getupnp(value)
    assert(self.statevariable, "No statevariable has been set")
    assert(value ~= nil, "Expected value, got nil")

    return self.statevariable:getupnp(value)
end

-----------------------------------------------------------------------------------------
-- Check a value against the arguments related statevariable.
-- will coerce booleans and numbers, including min/max/step values.  Only
-- values not convertable will return an error.
-- @param value the argument value
-- @returns value (in corresponding lua type) on success, nil on failure
-- @returns error string, if failure
-- @returns error number, if failure
function argument:check(value)
    assert(self.statevariable, "No statevariable has been set")
    assert(value ~= nil, "Expected value, got nil")

    return self.statevariable:check(value)
end


return argument
