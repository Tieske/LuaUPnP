---------------------------------------------------------------------
-- The base object for UPnP actions.
-- @class module
-- @name upnp.classes.action
-- @copyright 2012 <a href="http://www.thijsschreijer.nl">Thijs Schreijer</a>, <a href="http://github.com/Tieske/LuaUPnP">LuaUPnP</a> is licensed under <a href="http://www.gnu.org/licenses/gpl-3.0.html">GPLv3</a>
-- @release Version 0.1, LuaUPnP

-- set the proper classname here, this should match the filename without the '.lua' extension
local classname = "action"
local super = upnp.classes.upnpbase
local logger = upnp.logger

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
    local act = creator(plist, "action", parent)
    assert(act == nil or act.classname == "action","Creator didn't deliver an action object")
    if not act then act = upnp.classes.action:new(plist) end
    
    -- parse the argument list
    if alist then
        local success, err
        success, err = parseargumentlist(alist, creator, act, parent)
        if not success then
            return nil, "Failed to parse the action argumentlist; " .. tostring(err)
        end
    end

    -- check for generic getter/setter functionality
    if act.argumentcount > 0 then
      local same = true
      for _, arg in ipairs(act.argumentlist) do
        if arg.direction ~= act.argumentlist[1].direction or arg.name:sub(1,11):lower() == "a_arg_type_" then
          same = false
          break
        end
      end
      if same then
        if (act.argumentlist[1].direction == "in"  and act.name:sub(1,3):lower() == "set") or 
           (act.argumentlist[1].direction == "out" and act.name:sub(1,3):lower() == "get") then
          -- all arguments have the same direction, and methodname starts with 'get' or 'set'
          -- so use generic setter/getter
          if act.name:sub(1,3):lower() == "set" then
            act.execute = self.genericsetter
            logger:info("statevariable:parsefromxml(): setting 'genericsetter' as execute() method for action '%s'", tostring(act.name))
          else
            act.execute = self.genericgetter
            logger:info("statevariable:parsefromxml(): setting 'genericgetter' as execute() method for action '%s'", tostring(act.name))
          end
        end
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
    assert(argument:subclassof(upnp.classes.argument), "The argument is not a subclass of upnp.classes.argument")
assert(argument.classname == "argument")    
    assert(argument.direction == "in" or argument.direction == "out", "Direction must be either 'in' or 'out', not; " .. tostring(argument.direction))
    if self.argumentcount > 0 and argument.direction == "in" then
        assert(self.argumentlist[self.argumentcount].direction == "in", "All 'in' arguments must preceed the 'out' arguments")
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


-----------------------------------------------------------------------------------------
-- Checks parameters, completeness and conversion to Lua values/types.
-- <br><strong>NOTE:</strong> a copy of the table is returned, so the original table will not be modified.
-- @param params table with parameters provided (key value list, where key is the parameter name, value is the Lua typed value)
-- @return params table, or <code>nil + errormsg + errornumber</code> in case of an error
function action:checkparams(params)
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
-- Checks return values, completeness and conversion to UPnP values/types.
-- Transforms the results in 2 lists, names and values, in proper UPnP order, and UPnP typed.
-- @param result table with parameters provided (key value list, where key is the parameter name)
-- @return 2 lists (names and values) of the 'out' arguments (in proper order), or <code>nil, errormsg, errornumber</code> upon failure
function action:checkresults(result)
    -- transform result in 2 lists, names and values
    -- proper order, and UPnP typed values
    logger:debug("Entering action:checkresults() for action '%s'", tostring(self._name))
    result = result or {}
    local names = {}
    local values = {}
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

    logger:debug("Leaving action:checkresults(), success")
    return names, values
end

-----------------------------------------------------------------------------------------
-- Executes the action.
-- Override in descendant classes to implement the actual device behaviour. 
-- Preferably call the <code>device:executeaction()</code>
-- method, as that ensures that all objects in the hierarchy are informed about the results, additionally
-- it will check and convert parameters in and results going out.
-- <br><strong>NOTE:</strong> If parsed from an 
-- xml file the <code>genericgetter()/genericsetter()</code> might automatically have been set as the 
-- <code>execute()</code> method.
-- @param params table with named 'out' arguments (each argument indexed by its name). 
-- @return table with named return values (each indexed by its lowercase name). Upon an error the function 
-- should return; <code>nil, errorstring, errornumber</code> (see
-- the 6xx error codes in the UPnP 1.0 architecture document, section 3.2.2)
-- @see device:executeaction
-- @see service:executeaction
-- @see action:genericgetter
-- @see action:genericsetter
function action:execute(params)
    return {}, {}
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

-----------------------------------------------------------------------------------------
-- Generic function for standard actions 'getVariableName'. This method is capable of returning
-- multiple parameters, it will simply report all 'out' arguments of the action based on the 
-- related statevariables current value.
-- <br><strong>NOTE:</strong> when an action is parsed from an xml, and the following conditions
-- are met;</p><ul>
-- <li>action name starts with <code>'get'</code> (case independent)</li>
-- <li>the action has 1 or more arguments</li>
-- <li>all arguments are direction <code>'out'</code></li>
-- <li>none of the arguments has a related statevariable which name starts with <code>'A_ARG_TYPE_'</code> (case independent)</li>
-- </ul><p> then the <code>genericgetter</code> will automatically be set as the <code>execute()</code>
-- method for the action.
-- @param params list of parameters (not used by getters, but is standard in <code>execute()</code> method signature)
-- @return table with named return arguments (see <code>action:execute()</code> for format)
-- @example# -- usage for generic getter, assign to execute method
-- myAction.execute = upnp.classes.action.genericgetter
-- @see action:execute
function action:genericgetter(params)
    logger:debug("Entering action:genericgetter() for action '%s'", tostring(self._name))
    local result = {}
    local count = 0
    for _, arg in ipairs(self.argumentlist or {}) do
        if arg.direction == "out" then
            result[arg.name] = arg.statevariable:get()
            logger:debug("       adding argument '%s' with value '%s'", tostring(self._name), result[arg.name])
            count = count + 1
        end
    end
    logger:debug("Leaving action:genericgetter() for action '%s', number of return args: %s", tostring(self._name), tostring(count))
    return result
end

-----------------------------------------------------------------------------------------
-- Generic function for standard actions 'setVariableName'. This method is capable of aetting
-- multiple statevariable values, it will simply store all values of the parameters in the 
-- related statevariables.
-- <br><strong>NOTE:</strong> when an action is parsed from an xml, and the following conditions
-- are met;</p><ul>
-- <li>action name starts with <code>'set'</code> (case independent)</li>
-- <li>the action has 1 or more arguments</li>
-- <li>all arguments are direction <code>'in'</code></li>
-- <li>none of the arguments has a related statevariable which name starts with <code>'A_ARG_TYPE_'</code> (case independent)</li>
-- </ul><p> then the <code>genericsetter</code> will automatically be set as the <code>execute()</code>
-- method for the action.
-- @param params list of parameters
-- @return <code>1</code> on success, or <code>nil</code> on error
-- @return <code>errorstring</code> on error
-- @return <code>errornr</code> on error
-- @example# -- usage for generic getter, assign to execute method
-- myAction.execute = upnp.classes.action.genericgetter
-- @see action:execute
function action:genericsetter(params)
    logger:debug("action:genericsetter() entering... for action '%s'", tostring(self._name))
    local count = 0
    for pname, pvalue in pairs(params) do
        local param = self.argumentlist[pname]
        if param then
            logger:debug("action:genericsetter(): setting variable '%s' to value '%s'", tostring(param.statevariable._name), tostring(pvalue))
            count = count + 1
            local res, errstr, errnr = param.statevariable:set(pvalue)
            if res == nil then
                return res, errstr, errnr
            end
        end
    end
    logger:debug("action:genericsetter() leaving... for action '%s', number of args set: %s", tostring(self._name), tostring(count))
    return 1
end

return action
