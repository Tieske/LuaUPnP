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
local classname = "statevariable"
local super = upnp.classes.upnpbase

-----------------
-- LOCAL STUFF --
-----------------

-- table conversion of upnp types to Lua types
local datatypes = {
    ui1             = "number",
    ui2             = "number",
    ui4             = "number",
    i1              = "number",
    i2              = "number",
    i4              = "number",
    int             = "number",
    r4              = "number",
    r8              = "number",
    number          = "number",
    ["fixed.14.4"]  = "number",
    float           = "number",
    char            = "string",
    ["string"]      = "string",
    ["date"]        = "date",
    dateTime        = "date",
    ["dateTime.tz"]	= "date",
    ["time"]	    = "date",
    ["time.tz"]	    = "date",
    boolean         = "boolean",
    ["bin.base64"]  = "string",
    ["bin.hex"]     = "string",
    uri             = "string",
    uuid            = "string",
}
-- sub table for number; the integers
local integertypes = {
    ui1             = "number",
    ui2             = "number",
    ui4             = "number",
    i1              = "number",
    i2              = "number",
    i4              = "number",
    int             = "number",
}
-- boolean conversion;
local boolconversion = {
    -- trues
    ["true"]  = true,
    ["yes"]   = true,
    ["1"]     = true,
    [1]       = true,
    [true]    = true,
    -- falses
    ["false"] = false,
    ["no"]    = false,
    ["0"]     = false,
    [0]       = false,
    [false]   = false,
}

-- round a number to nearest integer
local function round(num)
    math.floor(num + .5)
end

--------------------------
-- CLASS IMPLEMENTATION --
--------------------------

-----------------------------------------------------------------------------------------
-- Members of the statevariable object
-- @class table
-- @name statevariable fields/properties
-- @field name name of the statevariable
-- @field sendevents indicator for the variable to be an evented statevariable
-- @field _value internal field holding the value, use <code>get, set</code> and <code>getupnp</code> methods for access
-- @field _datatype internal field holding the UPnP type, use <code>getdatatype</code> and <code>setdatatype</code> methods for access
local statevariable = super:subclass({
    name = "",                      -- statevariable name
    _datatype = "string",           -- set the datatype
    defaultvalue = "",              -- default value for statevariable
    sendevents = true,              -- is the variable evented or not
    parent = nil,                   -- owning UPnP service of this variable
    allowedvaluelist = nil,         -- set of possible values (set: keys and values are the same!) for UPnP type 'string' only
    minimum = nil,                  -- numeric values; minimum
    maximum = nil,                  -- numeric values; maximum
    step = nil,                     -- stepsize between minimum & maximum
    classname = classname,          -- set object classname
})

-----------------------------------------------------------------------------------------
-- Initializes the statevariable object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function statevariable:initialize()
    logger:debug("Initializing class '%s' named '%s'...", classname, tostring(self.name))
    -- initialize ancestor object
    super.initialize(self)
    -- set defaults
    self._value = self.defaultvalue
    logger:debug("Initializing class '%s' completed", classname)
end

-- Parse the element 'allowedValueList' (in ielement) into propertylist plist
local parseallowedlist = function(ielement, plist)
    local al = {}
    local elem = ielement:getFirstChild()
    while elem do
        if string.lower(elem:getNodeName()) == "allowedvalue" then
            local v = elem:getNodeValue()
            al[v] = v
        end
        elem = elem:getNextSibling()
    end
    plist["allowedvaluelist"] = al
end
-- Parse the element 'allowedValueRange' (in ielement) into propertylist plist
local parseallowedrange = function(ielement, plist)
    local elem = ielement:getFirstChild()
    while elem do
        plist[string.tolower(elem:getNodeName())] = elem:getNodeValue()
        elem = elem:getNextSibling()
    end
end
-----------------------------------------------------------------------------------------
-- StateVariable constructor method, creates a new variable, parsed from an XML 'stateVariable' element.
-- @param xmldoc an IXML object containing the 'stateVariable' element
-- @param creator callback function to create individual sub objects
-- @param parent the parent object for the variable to be created
-- @returns statevariable object
function statevariable:parsefromxml(xmldoc, creator, parent)
    assert(creator == nil or type(creator) == "function", "parameter creator should be a function or be nil, got " .. type(creator))
    creator = creator or function() end -- empty function if not provided
    local plist = {}    -- property list to create the object from after the properties have been parsed
    local ielement = xmldoc:getFirstChild()
    while ielement do
        local n = nil
        n = string.lower(ielement:getNodeName())
        if n == "allowedvaluelist" then
            parseallowedlist(ielement, plist)
        elseif n == "allowedvaluerange" then
            parseallowedrange(ielement, plist)
        else
            plist[n] = ielement:getNodeValue()
        end
    end
    -- properly update sendevents value to boolean
    local se = string.lower(plist.sendevents or "yes")  -- defaults to yes according to spec
    if se == "false" or se == "no" or se == "0" then
        plist.sendevents = false
    else
        plist.sendevents = true
    end
    -- go create the object
    local var = (creator(plist, "statevariable", parent) or upnp.classes.statevariable:new(plist))
    -- set defaults and update type
    var._datatype = (var.datatype or "string")
    var.datatype = nil
    var._value = (var.value or var.defaultvalue or "")
    var.value = nil

    return var  -- parsing service will add it to the parent service
end


-----------------------------------------------------------------------------------------
-- Gets the variable UPnP type.
function statevariable:getdatatype()
    return self._datatype
end

-----------------------------------------------------------------------------------------
-- Sets the variable UPnP type.
function statevariable:setdatatype(upnptype)
    assert (datatypes[upnptype] ~= nil, "Not a valid UPnP datatype; " .. tostring(upnptype))
    self._datatype = upnptype
end


-----------------------------------------------------------------------------------------
-- Gets the variable value.
-- The value will be in the corresponding Lua type. Note: for a date object, always
-- a copy will be stored/returned to prevent changes from going 'unevented', so the
-- change must be explicitly set.
function statevariable:get()
    if type(self._value) == "table" then
        -- always create a new date table/object to prevent unintended changes
        return self._value:copy()  -- copy date to new object
    end
    return self._value
end

-----------------------------------------------------------------------------------------
-- Gets the variable value in upnp format.
-- @param value (optional) the value to convert to the UPnP format of this variable. If
-- omitted, then the current value of the statevariable will be used (this parameters main
-- use is returning properly formatted results for action arguments during a call)
-- @returns The statevariable value in UPnP format as a Lua string.
function statevariable:getupnp(value)
    value = value or self._value
    local t = datatypes[self._datatype]
    if t == "number" then
        return tostring(value)
    elseif t == "string" then
        return tostring(value)
    elseif t == "boolean" then
        if value then return "1" else return "0" end
    elseif t == "date" then
-- TODO to be done
        return tostring(value)
    else
        error("unknown type; ".. tostring(t))
    end
end

-----------------------------------------------------------------------------------------
-- Check a value against the statevariable.
-- will coerce booelans and numbers, including min/max/step values.  Only
-- values not convertable will return an error.
-- @param value the new value for the statevariable
-- @returns value (in corresponding lua type) on success, nil on failure
-- @returns error string, if failure
-- @returns error number, if failure
function statevariable:check(value)
    assert(value ~= nil, "nil is not a valid value")
    local t = datatypes[self._datatype]
    local result, errnr, errstr

    if t == "number" then
        -- convert to number, check integer, check min/max/step
        result = tonumber(value)
        if result then
            if integertypes[self._datatype] then
                -- make sure its an integer
                result = round(result)
            end
            -- validate step
            if self.step and self.maximum and self.minimum then
                local s = (result - self.minimum)/self.step  -- level of step
                result = round(s) * self.step + self.minimum
            end
            -- validate min/max
            if self.minimum then result = math.max(self.minimum, result) end
            if self.maximum then result = math.min(self.maximum, result) end
        else
            -- couldn't convert, hence error
            result = nil
            errnr = 600
            errstr = "Argument Value Invalid, not a valid number; " .. tostring(value)
        end
    elseif t == "string" then
        -- convert tostring
        result = tostring(value)
        if self._datatype == "string" and self.allowedvaluelist then
            -- check against allowedvaluelist
            if self.allowedvaluelist[result] == nil then
                -- not found, so error out
                result = nil
                errnr = 601
                errstr = "Argument Value Out of Range; " .. tostring(value)
            end
        end
    elseif t == "boolean" then
        result = boolconversion[value]
        if not result then
            -- couldn't convert, hence error
            result = nil
            errnr = 600
            errstr = "Argument Value Invalid, not a valid boolean; " .. tostring(value)
        end
    elseif t == "date" then
        if isdate(value) then
            -- we got a date object
            result = value
        elseif type(value) == "string" then
            -- we a string to parse, so construct a date
            local success, res = pcall(date.__call, date, value)
            if success then
                result = res
            else
                result = nil
                errnr = 600
                errstr = "Argument Value Invalid, unable to parse date-time value; " .. tostring(value)
            end
        else
            result = nil
            errnr = 600
            errstr = "Argument Value Invalid, unable to parse date-time value; " .. tostring(value)
        end
    else
        -- unknown type
        error("Unknown type; " .. tostring(t))
    end
end

-----------------------------------------------------------------------------------------
-- Handler called before the new value is set. The newvalue will have been checked and converted
-- before this handler is called.
-- Override in descendant classes to implement device behaviour.
-- @param newval the new value to be set (this handler has the opportunity to change the value being set!)
-- @returns newval to be set (Lua type) or nil, error message, error number upon failure
function statevariable:beforeset(newval)
    return newval
end

-----------------------------------------------------------------------------------------
-- Handler called after the new value has been set. The newvalue will have been checked and converted
-- before this handler is called. NOTE: this will only be called when the value has actually changed!
-- Override in descendant classes to implement device behaviour.
-- @param oldval the previous value of the statevariable
-- @returns nothing
function statevariable:afterset(oldval)
end

-----------------------------------------------------------------------------------------
-- Sets the statevariable value.
-- Any value provided will be converted to the corresponding Lua type
-- @param value the new value for the statevariable
-- @param noevent boolean indicating whether and event should be blocked for evented
-- statevariables
-- @returns value (in corresponding lua type) on success, nil on failure
-- @returns error string, if failure
-- @returns error number, if failure
function statevariable:set(value, noevent)
    -- check provided values
    local newval, errstr, errnr = self:check(value)
    if newval == nil then
        return newval, errstr, errnr
    end
    -- call before handler
    newval, errstr, errnr = self:beforeset(newval)
    if newval == nil then
        return newval, errstr, errnr
    end

    if self._value ~= newval then
        local oldval = self._value
        if datatypes[self._datatype] == "date" then
            -- always create a new date table/object to prevent unintended changes
            newval = newval:copy()
        end
        self._value = newval              -- set new value, fire event
        if self.sendevents and not noevent then
            local handle = self:gethandle()
            if handle then
                handle:Notify(event.DevUDN, event.ServiceID, self.name, newval)
            end
        end
        -- call the after handler
        self:afterset(oldval)
    end
    return newval
end


return statevariable
