---------------------------------------------------------------------
-- The base object for UPnP action arguments.
-- @class module
-- @name upnp.classes.argument
-- @copyright 2012 <a href="http://www.thijsschreijer.nl">Thijs Schreijer</a>, <a href="http://github.com/Tieske/LuaUPnP">LuaUPnP</a> is licensed under <a href="http://www.gnu.org/licenses/gpl-3.0.html">GPLv3</a>
-- @release Version 0.1, LuaUPnP

-- set the proper classname here, this should match the filename without the '.lua' extension
local classname = "argument"
local super = upnp.classes.upnpbase

-----------------
-- LOCAL STUFF --
-----------------

--------------------------
-- CLASS IMPLEMENTATION --
--------------------------

-----------------------------------------------------------------------------------------
-- Members of the argument object
-- @class table
-- @name Argument fields/properties
-- @field name name of the argument
-- @field parent the owning action object
-- @field direction of the argument either <code>'in'</code> or <code>'out'</code>
-- @field statevariable the related statevariable object
-- @field position position on the argument list of the owning action
local argument = super:subclass()

-----------------------------------------------------------------------------------------
-- Initializes the argument object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function argument:initialize()
    logger:debug("Initializing class '%s' named '%s'...", classname, tostring(self.name))
    -- initialize ancestor object
    super.initialize(self)
    --self.name = ""                      -- argument name
    --self.statevariable = nil            -- related statevariable object
    self.direction = self.direction or "in"               -- in/out going argument, either "in" or "out"
    self.position = self.position or 0                   -- position in the actions argument list
    self.parent = nil                   -- owning UPnP action of this argument
    self.classname = classname          -- set object classname
    logger:debug("Initializing class '%s' completed", classname)
end

-----------------------------------------------------------------------------------------
-- Argument constructor method, creates a new argument, parsed from an XML 'argument' element.
-- @param xmldoc an IXML object containing the 'argument' element
-- @param creator callback function to create individual sub objects, see <a href="upnp.device.html#creator"><code>creator()</code></a>.
-- @param parent the parent action object for the argument to be created
-- @param service the service to attach to. Required because the parent relationships in the
-- hierarchy haven't been set yet while parsing and the argument needs to access the statevariable
-- list to check whether the related statevariable actually exists
-- @return argument object or <code>nil + error message</code>
function argument:parsefromxml(xmldoc, creator, parent, service)
    assert(creator == nil or type(creator) == "function", "parameter creator should be a function or be nil, got " .. type(creator))
    creator = creator or function() end -- empty function if not provided
    local plist = {}    -- property list to create the object from after the properties have been parsed
    local ielement = xmldoc:getFirstChild()
    while ielement do
        local name = nil
        name = string.lower(ielement:getNodeName())
        if name == "retval" then
            logger:debug("argument:parsefromxml(): adding '%s' @ 'true'", tostring(name))
            plist[name] = true
        else
            local n = nil
            n = ielement:getFirstChild()
            while n and n:getNodeType() ~= "TEXT_NODE" do
                n = n:getNextSibling()
            end
            if n then   -- store property value
                local val = n:getNodeValue()
                logger:debug("argument:parsefromxml(): adding '%s' @ '%s'", tostring(name), tostring(val))
                plist[name] = val
            end
        end
        ielement = ielement:getNextSibling()
    end
    -- check statevariable
    if plist.relatedstatevariable then
        plist.relatedstatevariable = string.lower(plist.relatedstatevariable)
    end
    if not plist.relatedstatevariable or not service.statetable[plist.relatedstatevariable] then
        return nil, "Error cannot attach statevariable to parsed argument, statevariable not found; " .. tostring(plist.relatedstatevariable)
    end
    -- attach statevariable
    plist.statevariable = service.statetable[plist.relatedstatevariable]
    plist.relatedstatevariable = nil
    -- go create the object
    local arg = (creator(plist, "argument", parent) or upnp.classes.argument(plist))

    return arg  -- the parsing action will add it to the parent action
end

-----------------------------------------------------------------------------------------
-- Formats the argument value in upnp format.
-- @param value the Lua typed value to be formatted as UPnP type, according to the UPnP type set
-- in the related statevariable for this argument
-- @return The value in UPnP format as a Lua string.
function argument:getupnp(value)
    assert(self.statevariable, "No statevariable has been set")
    assert(value ~= nil, "Expected value, got nil")

    return self.statevariable:getupnp(value)
end

-----------------------------------------------------------------------------------------
-- Check a value against the arguments related statevariable.
-- This will coerce booleans and numbers, including min/max/step values. Only
-- values not convertable will return an error.
-- @param value the argument value
-- @return value (in corresponding lua type) on success, <code>nil</code> on failure
-- @return error string, if failure
-- @return error number, if failure
function argument:check(value)
    assert(self.statevariable, "No statevariable has been set")
    assert(value ~= nil, "Expected value, got nil")

    return self.statevariable:check(value)
end


return argument
