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
})

-----------------------------------------------------------------------------------------
-- Initializes the statevariable object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function service:initialize()
    -- initialize ancestor object
    super.initialize(self)
    -- update classname
    self.classname = classname
    -- set defaults

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
