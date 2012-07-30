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
local classname = "action"
local super = upnp.classes.upnpbase

-----------------
-- LOCAL STUFF --
-----------------

--------------------------
-- CLASS IMPLEMENTATION --
--------------------------

-----------------------------------------------------------------------------------------
-- Members of the action object
-- @class table
-- @name action fields/properties
-- @field name name of the action
-- @field evented indicator for the variable to be an evented statevariable
-- @field _value internal field holding the value, use <code>get, set</code> and <code>getupnp</code> methods for access
-- @field _datatype internal field holding the UPnP type, use <code>getdatatype</code> and <code>setdatatype</code> methods for access
local action = super:subclass({
    name = "",                      -- action name
    parent = nil,                   -- owning UPnP service of this variable
    argumentlist = nil,             -- list of arguments, each indexed both by name and number (position)
    argumentcount = 0,              -- number of arguments
    classname = classname,          -- set object classname
})

-----------------------------------------------------------------------------------------
-- Initializes the action object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function action:initialize()
    logger:debug("Initializing class '%s' named '%s'...", classname, tostring(self.name))
    -- initialize ancestor object
    super.initialize(self)
    -- set defaults
    logger:debug("Initializing class '%s' completed", classname)
end

-- Parse an IXML 'argumentList' element (alist) in the parent (action object), while using 'creator' to generate objects
-- service = parent service, because the 'parent' relations ships haven't been set yet and the argument creation needs
-- the variablelist to check if the related statevariable exists
local parseargumentlist = function(alist, creator, parent, service)
    local success, arg, err
    local elem = alist:getFirstChild()
    while elem do
        if string.lower(elem:getNodeName()) == "argument" then
            arg, err = upnp.classes.argument:parsefromxml(elem, creator, parent)
            if not arg then
                return nil, "Error parsing an argument from the list; " .. tostring(err)
            end
            success, err = pcall(parent.addargument, parent, arg)
            if not success then
                return nil, "Error adding a parsed argument to the action; " .. tostring(err)
            end
        end
        elem = elem:getNextSibling()
    end
    return 1   -- report success
end

-----------------------------------------------------------------------------------------
-- Action constructor method, creates a new action, parsed from an XML 'action' element.
-- @param xmldoc an IXML object containing the 'action' element
-- @param creator callback function to create individual sub objects
-- @param parent the parent object for the action to be created
-- @returns action object
function action:parsefromxml(xmldoc, creator, parent)
    assert(creator == nil or type(creator) == "function", "parameter creator should be a function or be nil, got " .. type(creator))
    creator = creator or function() end -- empty function if not provided
    local plist = {}    -- property list to create the object from after the properties have been parsed
    local alist = nil
    local ielement = xmldoc:getFirstChild()
    while ielement do
        local n = nil
        n = string.lower(ielement:getNodeName())
        if n == "argumentlist" then
            alist = ielement
        else
            plist[n] = ielement:getNodeValue()
        end
    end
    -- go create the object
    local act = (creator(plist, "action", parent) or upnp.classes.action:new(plist))
    -- parse the argument list
    local success
    success, err = parseargumentlist(alist, creator, act, parent)
    if not success then
        return nil, "Failed to parse the action argumentlist; " .. tostring(err)
    end

    return act  -- the parsing service will add it to the parent service
end

-----------------------------------------------------------------------------------------
-- Adds an argument to the actions argument list.
-- This will append an argument, so adding must be done in proper UPnP order!
function action:addargument(argument)
    assert(type(argument) ~= "table", "Expected argument table, got nil")
    assert(argument.direction == "in" or argument.direction == "out", "Direction must be either 'in' or 'out', not; " .. tostring(argument.direction))
    assert(self.argumentcount > 0 and argument.direction == "in" and
           self.argumentlist[self.argumentcount] ~= "in", "All 'in' arguments must preceed the 'out' arguments")
    -- increase count
    self.argumentcount = self.argumentcount + 1
    -- add to list
    self.argumentlist[self.argumentcount] = argument    -- add on index/position
    self.argumentlist[argument.name] = argument         -- add by name
    -- update argument
    argument.parent = self
    argument.position = self.argumentcount
end


-- Checks parameters, completeness and conversion to Lua values/types
local function checkparams(params)
    if self.argumentcount > 0 then
        local i = 1;
        local p = self.argumentlist[i]
        while p do
            if p.direction ~= "out" then
                if params[p.name] then
                    local success, val, errstr, errnr = pcall(p.check, p, params[p.name])
                    if success and val then     -- pcall succeeded and a value was returned
                        params[p.name] = val    -- now converted to Lua type, replace UPnP type
                    else
                        -- failure, report error and exit
                        if not success then
                            -- pcall failed, convert lua error to UPnP error
                            errnr = 600
                            errstr = "Argument Value Invalid. Error converting value for argument '" .. tostring(p.name) .. "' ;" .. tostring(val)
                            val = nil
                        end
                        -- return UPnP error
                        return nil, errstr, errnr
                    end
                else
                    return nil, "Invalid Args. Missing argument named; " .. tostring(p.name), 402
                end
            end
            i = i + 1
            p = self.argumentlist[i]
        end
    end
    -- succeeded, return updated list
    return params
end

-----------------------------------------------------------------------------------------
-- Executes the action.
-- Override in descendant classes to implement the actual device behaviour. NOTE: if not
-- overridden, the default result will be an error; 602, Optional Action Not Implemented (hence;
-- from the descedant overridden method, DO NOT call the ancestor method, as it will only return the error)
-- @param params table with named arguments (each argument indexed
-- by its name). Before calling the arguments will have been checked, converted and counted.
-- @returns table with named return values (each indexed by its name). The
-- returned values can be the Lua types, will be converted to UPnP types (and validated) before sending.
-- Upon an error the function should return; nil, errorstring, errornumber (see
-- the 6xx error codes in the UPnP 1.0 architecture document, section 3.2.2)
-- @see action:_execute
function action:execute(params)
    return nil, "Optional Action Not Implemented; " .. tostring(self.name), 602
end

-----------------------------------------------------------------------------------------
-- Executes the action while checking inputs and outputs. Parameter values may be in either UPnP or Lua format.
-- The actual implementation is in <code>action:execute()</code> which will be called by this method. So to
-- implement device behaviour, override the <code>action:execute()</code> method, and not this one.
-- @param params table with argument values, indexed by argument name.
-- @returns 2 lists (names and values) of the 'out' arguments (in proper order), or nil, errormsg, errornumber upon failure
function action:_execute(params)
    local result, names, values
    local result, err, errnr = checkparams(params)
    if not result then
        -- parameter check failed
        return result, err, errnr
    end

    success, result, err, errnr = pcall(self.execute, self, params)
    if not success then
        -- pcall error...
        errnr = 501
        err = "Action Failed. Internal error; " .. tostring(result)
        result = nil
    end
    if not result then
        -- execution failed
        return result, err, errnr
    end
    -- transform result in 2 lists, names and values
    -- proper order, and UPnP typed values
    names = {}
    values = {}
    local i = 1
    for n, arg in ipairs(self._argumentlist or {}) do
        if arg.direction == "out" then
            names[i] = arg.name
            if not result[arg.name] then
                return nil, "Action Failed; device internal error, argument '" .. tostring(arg.name) .. "' is missing from the results", 501
            end
            values[i] = arg.getupnp(result[arg.name])
            i = i + 1
        end
    end

    return names, values
end

return action
