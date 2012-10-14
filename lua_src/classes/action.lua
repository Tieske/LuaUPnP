---------------------------------------------------------------------
-- The base object for UPnP actions.
-- @class module
-- @name upnp.classes.action
-- @copyright 2012 <a href="http://www.thijsschreijer.nl">Thijs Schreijer</a>, <a href="http://github.com/Tieske/LuaUPnP">LuaUPnP</a> is licensed under <a href="http://www.gnu.org/licenses/gpl-3.0.html">GPLv3</a>
-- @release Version 0.1, LuaUPnP

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
-- @name Action fields/properties
-- @field name name of the action
-- @field parent the owning upnpservice object
-- @field argumentlist list with arguments, indexed both by name and number (order in the list)
-- @field argumentcount number of arguments for the action
local action = super:subclass()

-----------------------------------------------------------------------------------------
-- Initializes the action object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function action:initialize()
    logger:debug("Initializing class '%s' named '%s'...", classname, tostring(self.name))
    -- initialize ancestor object
    super.initialize(self)
    -- set defaults
    --self.name = ""                      -- action name
    self.parent = nil                   -- owning UPnP service of this variable
    self.argumentlist = {}             -- list of arguments, each indexed both by name and number (position)
    self.argumentcount = 0              -- number of arguments
    self.classname = classname          -- set object classname
    logger:debug("Initializing class '%s' completed", classname)
end

--------------------------------------------------------------------------------------------------------
-- Parse an IXML 'argumentList' element (alist) in the parent (action object), while using 'creator' to generate objects
-- service = parent service, because the 'parent' relations ships haven't been set yet and the argument creation needs
-- the variablelist to check if the related statevariable exists
-- *param alist ixml object holding the argumentlist
-- *param creator creator function that creates the argument objects
-- *param parent the parent argument object
-- *param service the owning service, because the xml is being parsed, the owning service has not been set
-- yet and access to the service is required to check wether the related statevariables exist
-- *return 1 on success or nil + error message
local parseargumentlist = function(alist, creator, parent, service)
    local success, arg, err
    local elem = alist:getFirstChild()
    while elem do
        if string.lower(elem:getNodeName()) == "argument" then
            arg, err = upnp.classes.argument:parsefromxml(elem, creator, parent, service)
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
-- @param creator callback function to create individual sub objects, see <a href="upnp.device.html#creator"><code>creator()</code></a>.
-- @param parent the parent service object for the action to be created
-- @return action object or <code>nil + error message</code>
function action:parsefromxml(xmldoc, creator, parent)
    logger:debug("Entering action:parsefromxml()...")
    assert(creator == nil or type(creator) == "function", "parameter creator should be a function or be nil, got " .. type(creator))
    creator = creator or function() end -- empty function if not provided
    local plist = {}    -- property list to create the object from after the properties have been parsed
    local alist = nil
    local ielement = xmldoc:getFirstChild()
    while ielement do
        local name = nil
        name = string.lower(ielement:getNodeName())
        if name == "argumentlist" then
            alist = ielement
            logger:debug("action:parsefromxml(), found 'argumentList' element")
        else
            local n = nil
            n = ielement:getFirstChild()
            while n and n:getNodeType() ~= "TEXT_NODE" do
                n = n:getNextSibling()
            end
            if n then   -- store property value
                local val = n:getNodeValue()
                logger:debug("action:parsefromxml(): adding '%s' @ '%s'", tostring(name), tostring(val))
                plist[name] = val
            end
        end
        ielement = ielement:getNextSibling()
    end
    -- go create the object
    local act = (creator(plist, "action", parent) or upnp.classes.action:new(plist))
    -- parse the argument list
    if alist then
        local success, err
        success, err = parseargumentlist(alist, creator, act, parent)
        if not success then
            return nil, "Failed to parse the action argumentlist; " .. tostring(err)
        end
    end

    logger:debug("Leaving statevariable:parsefromxml()...")
    return act  -- the parsing service will add it to the parent service
end

-----------------------------------------------------------------------------------------
-- Adds an argument to the actions argument list.
-- This will append an argument, so adding must be done in proper UPnP order!
-- @param argument the argument object to be added to the argumentlist
function action:addargument(argument)
    assert(type(argument) == "table", "Expected argument table, got nil")
    assert(argument.direction == "in" or argument.direction == "out", "Direction must be either 'in' or 'out', not; " .. tostring(argument.direction))
    if self.argumentcount > 0 and argument.direction == "in" then
        assert(self.argumentlist[self.argumentcount] == "in", "All 'in' arguments must preceed the 'out' arguments")
    end
    -- increase count
    self.argumentcount = self.argumentcount + 1
    logger:info("action:addargument(); adding nr %d named '%s'", self.argumentcount, tostring(argument.name))

    -- register original name, switch to lowercase
    argument._name, argument.name = argument.name, string.lower(argument.name)

    -- add to list
    self.argumentlist[self.argumentcount] = argument    -- add on index/position
    self.argumentlist[argument.name] = argument         -- add by name
    -- update argument
    argument.parent = self
    argument.position = self.argumentcount
end


-- Checks parameters, completeness and conversion to Lua values/types
local function checkparams(self, params)
    -- convert parameters to lowercase for matching
    local lcase = {}
    for name, value in pairs(params) do
        lcase[string.lower(name)] = value
    end
    params = lcase
    lcase = nil
    -- now check parameters
    if self.argumentcount > 0 then
        local i = 1;
        local p = self.argumentlist[i]
        while p do
            if p.direction ~= "out" then
                if params[p.name] then
                    local success, val, errstr, errnr = pcall(p.check, p, params[p.name])
                    if success and val ~= nil then     -- pcall succeeded and a value was returned
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
-- Override in descendant classes to implement the actual device behaviour. <br/><strong>NOTE 1</strong>: if not
-- overridden, the default result will be an error; <code>602, Optional Action Not Implemented</code> (hence;
-- from the descedant overridden method, DO NOT call the ancestor method, as it will only return the error)
-- <br/><strong>NOTE 2</strong>: this method is wrapped by <code>action:_execute()</code> from which it will be
-- called. So never call this method directly, if you need to execute, call <code>_execute()</code>. If called
-- externally, it is best to call <a href="upnp.service.html#service:executeaction"><code>service:executeaction()</code></a>
-- as that will also return the proper UPnP error if the action doesn't exist.
-- @param params table with named arguments (each argument indexed
-- by its name). Before calling the arguments will have been checked, converted and counted.
-- @return table with named return values (each indexed by its name). The
-- returned values can be the Lua types, will be converted to UPnP types (and validated) before sending.
-- Upon an error the function should return; <code>nil, errorstring, errornumber</code> (see
-- the 6xx error codes in the UPnP 1.0 architecture document, section 3.2.2)
-- @see action:_execute
-- @see service:executeaction
function action:execute(params)
    logger:warning("Action '%s' has not been implemented!", tostring(self._name))
    return nil, "Optional Action Not Implemented; " .. tostring(self._name), 602
end

-----------------------------------------------------------------------------------------
-- Executes the action while checking inputs and outputs. Parameter values may be in either UPnP or Lua format.
-- The actual implementation is in <code>action:execute()</code> which will be called by this method.
-- <br/>Actual execution order;
-- <br/>1) <code>action:_execute()</code> verifies correctness of all arguments provided and converts them to Lua equivalents
-- <br/>2) <code>action:execute()</code> gets called to perform actual device behaviour
-- <br/>3) <code>action:_execute()</code> verifies the return values and converts them to UPnP formats
-- <br/>So to implement device behaviour, override the <code>action:execute()</code> method, to execute the action
-- call <code>action:_execute()</code> or even better call <a href="upnp.service.html#service:executeaction"><code>service:executeaction()</code></a>
-- as that will also return the proper UPnP error if the action doesn't exist.
-- @param params table with argument values, indexed by argument name.
-- @return 2 lists (names and values) of the 'out' arguments (in proper order), or <code>nil, errormsg, errornumber</code> upon failure
-- @see action:execute
-- @see service:executeaction
function action:_execute(params)
    logger:info("Entering action:_execute() for action '%s'", tostring(self._name))
    local names, values, success
    local result, err, errnr = checkparams(self, params)
    if not result then
        -- parameter check failed
        logger:error("action:_execute() checking parameters failed; %s", tostring(err))
        return result, err, errnr
    else
        -- parameter check succeeded, updated list was returned
        params = result     -- update local params table
    end

    success, result, err, errnr = pcall(self.execute, self, params)
    if not success then
        -- pcall error...
        logger:error("action:execute() failed (pcall); %s", tostring(result))
        errnr = 501
        err = "Action Failed. Internal error; " .. tostring(result)
        result = nil
        return nil, err, errnr
    end
    if not result and (err ~= nil or errnr ~= nil) then
        -- execution failed
        logger:error("action:execute() failed (returned error); %s", tostring(err))
        return nil, err, errnr
    end
    -- transform result in 2 lists, names and values
    -- proper order, and UPnP typed values
    names = {}
    values = {}
    local i = 1
    for _, arg in ipairs(self.argumentlist or {}) do
        if arg.direction == "out" then
            names[i] = arg._name    -- use original casing here
            if not result[arg.name] then
                logger:error("action:execute() results are incomplete; '%s' is missing as a return value.", tostring(arg._name))
                return nil, "Action Failed; device internal error, argument '" .. tostring(arg._name) .. "' is missing from the results", 501
            end
            values[i] = arg:getupnp(result[arg.name])
            logger:info("    results: %2d   %s = '%s'", i, tostring(names[i]),tostring(values[i]))
            i = i + 1
        end
    end

    logger:debug("Leaving action:_execute()")
    return names, values
end

-- Clears all the lazy-elements set. Applies to <code>getaction(), getservice(), getdevice(),
-- getroot(), gethandle()</code> methods.
-- Override in subclasses to clear tree-structure.
function action:clearlazyness()
    super.clearlazyness(self)
    for _, arg in pairs(self.argumentlist or {}) do
        arg:clearlazyness()
    end
end

return action
