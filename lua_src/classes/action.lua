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
local action = upnp.classes.upnpbase:subclass({
    name = "",                      -- action name
    parent = nil,                   -- owning UPnP service of this variable
    argumentlist = nil,             -- list of arguments, each indexed both by name and number (position)
    argumentcount = 0,              -- number of arguments
})

-----------------------------------------------------------------------------------------
-- Initializes the action object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function action:initialize()
    -- initialize ancestor object
    super.initialize(self)
    -- update classname
    self.classname = classname
    -- set defaults

end


-----------------------------------------------------------------------------------------
-- Adds an argument to the actions argument list.
-- This will append an argument, so adding must be done in proper UPnP order!
function action:addargument(argument)
    assert(type(argument) ~= "table", "Expected argument table, got nil")
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

-----------------------------------------------------------------------------------------
-- Sets the function to execute the action.
-- The function set will be called with two arguments; 1) the action object from which it is called
-- (to be used as 'self'), and 2) a table with named arguments (each argument indexed
-- by its name). Before calling the arguments will have been checked, converted and counted.
-- The function should return a table with named return values (each indexed by its name)
-- Upon an error the function should return; nil, errorstring, errornumber (see
-- the 6xx error codes in the UPnP 1.0 architecture document, section 3.2.2)
-- @param f the function to execute when the action gets called
function action:setfunction(f)
    assert (type(f) == "function", "Expected function, got " .. type(f))
    self._function = f
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
-- Executes the action. Parameter values may be in either UPnP or Lua format.
-- @param params table with argument values, indexed by argument name.
-- @returns table with named 'out' arguments, or nil, errormsg, errornumber upon failure
function action:execute(params)
    local result
    local result, err, errnr = checkparams(params)
    if result then
        success, result, err, errnr = pcall(self._function, self, params)
        if not success then
            -- pcall error...
            errnr = 501
            err = "Action Failed. Internal error; " .. tostring(result)
            result = nil
        end
    end
    return result, err, errnr
end

return action
