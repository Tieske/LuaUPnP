---------------------------------------------------------------------
-- The base object for UPnP services.
-- @class module
-- @name upnp.classes.service
-- @copyright 2012 <a href="http://www.thijsschreijer.nl">Thijs Schreijer</a>, <a href="http://github.com/Tieske/LuaUPnP">LuaUPnP</a> is licensed under <a href="http://www.gnu.org/licenses/gpl-3.0.html">GPLv3</a>
-- @release Version 0.1, LuaUPnP

-- set the proper classname here, this should match the filename without the '.lua' extension
local classname = "service"
local super = upnp.classes.upnpbase

-----------------
-- LOCAL STUFF --
-----------------


--------------------------
-- CLASS IMPLEMENTATION --
--------------------------

-----------------------------------------------------------------------------------------
-- Members of the service object
-- @class table
-- @name service fields/properties
-- @field servicetype type of the service
-- @field serviceid id of the service
-- @field parent the device owning this service
-- @field actionlist list of actions, indexed by their name
-- @field statetable list of statevariables, indexed by their name
local service = super:subclass()

-----------------------------------------------------------------------------------------
-- Initializes the service object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function service:initialize()
    logger:debug("Initializing class '%s' with id '%s'...", classname, tostring(self.serviceid))
    -- initialize ancestor object
    super.initialize(self)
    -- set defaults
    --self.servicetype = nil              -- service type
    --self.serviceid = nil                -- service id
    self.parent = nil                   -- owning UPnP device of this service
    self.actionlist = {}               -- table with actions, indexed by name
    self.servicestatetable = {}               -- table with statevariables, indexed by name
    classname = classname          -- set object classname

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
                return nil, "Failed to parse an action; " .. tostring(err)
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
                return nil, "Failed to parse a variable; " .. tostring(err)
            end
            -- add variable to service
            success, err = pcall(serv.addstatevariable, serv, variable)
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
-- @param creator callback function to create individual sub objects, see <a href="upnp.device.html#creator"><code>creator()</code></a>.
-- @param parent the parent device object for the service to be created
-- @param plist key-value list with service properties already parsed from the Device XMLs 'serviceList' element.
-- @return service object or <code>nil + error message</code>
function service:parsefromxml(xmldoc, creator, parent, plist)
    assert(creator == nil or type(creator) == "function", "parameter creator should be a function or be nil, got " .. type(creator))
    creator = creator or function() end -- empty function if not provided

    logger:debug("Entering service:parsefromxml()...")

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
        logger:debug("service:parsefromxml(), looking for 'scpd' element in XML doc")
        ielement = idoc:getFirstChild()     -- get document root element
    end
    -- ielement now contains the 'scpd' element
    -- go create service object
    logger:debug("service:parsefromxml(), calling 'creator' to create a service object, or a service baseclass if nothing is returned")
    local serv = (creator(plist, "service", parent) or upnp.classes.service(plist))

    -- get started parsing...
    local lst = ielement:getFirstChild()
    local vlist, alist = nil, nil
    while lst do
        local name = string.lower(lst:getNodeName())
        if name == "actionlist" then
            alist = lst
            logger:debug("service:parsefromxml(), found the 'actionlist' element")
        elseif name == "servicestatetable" then
            vlist = lst
            logger:debug("service:parsefromxml(), found the 'servicestatetable' element")
        else
            -- some other element, do nothing
        end
        lst = lst:getNextSibling();
    end
    -- now first parse the variable list, to make sure that action arguments can find the related variables
    if vlist then
        success, err = parsevariablelist(vlist, creator, serv)
        if not success then
            logger:error("service:parsefromxml(), parsing 'servicestatetable' element failed; %s", tostring(err))
            return nil, "Error parsing serviceStateTable element; " .. tostring(err)
        end
    end
    if alist then
        success, err = parseactionlist(alist, creator, serv)
        if not success then
            logger:error("service:parsefromxml(), parsing 'actionlist' element failed; %s", tostring(err))
            return nil, "Error parsing actionList element; " .. tostring(err)
        end
    end

    logger:debug("Leaving service:parsefromxml()...")
    return serv
end

-----------------------------------------------------------------------------------------
-- Adds a statevariable to the service statetable.
-- @param statevar statevariable object to add
function service:addstatevariable(statevar)
    assert(type(statevar) == "table", "Expected statevariable table, got nil")
    assert(statevar.name, "Statevariable name not set, can't add to service")
    -- add to list
    logger:info("service:addstatevariable(); adding '%s'", tostring(statevar.name))

    -- register original name, switch to lowercase
    statevar._name, statevar.name = statevar.name, string.lower(statevar.name)

    self.servicestatetable = self.servicestatetable or {}
    self.servicestatetable[statevar.name] = statevar
    -- update statevariable
    statevar.parent = self
end

-----------------------------------------------------------------------------------------
-- Adds an action to the service actionlist.
-- @param action action object to add
function service:addaction(action)
    assert(type(action) == "table", "Expected action table, got nil")
    assert(action.name, "Action name not set, can't add to service")
    -- add to list
    logger:info("service:addaction(); adding '%s'", tostring(action.name))

    -- register original name, switch to lowercase
    action._name, action.name = action.name, string.lower(action.name)

    self.actionlist = self.actionlist or {}
    self.actionlist[action.name] = action
    -- update action
    action.parent = self
end

-----------------------------------------------------------------------------------------
-- Execute an action owned by the service. Preferably call the <code>device:executeaction()</code>
-- method, as that ensures that all objects in the hierarchy are informed about the results, additionally
-- it will check and convert parameters in and results going out.
-- @param actionname (string or table) name of action to execute, or action table/object
-- @param params (table) table of parameter values, keyed by parameter names
-- @return 2 lists (names and values) of the 'out' arguments (in proper order), or <code>nil, errormsg, errornumber</code> upon failure
-- @see device:executeaction
-- @see action:execute
function service:executeaction(actionname, params)
  logger:debug("service:executeaction(), entering...")
  -- find action
  local action
  if type(actionname) == "table" then
    action = actionname
  else
    action = self.actionlist[string.lower(tostring(actionname))]
    if not action then
      return nil, "Invalid Action; no action by name '" .. actionname .. "'", 401
    end
  end
  -- execute it
  logger:debug("service:executeaction(), action found, executing and exiting")
  return action:execute(params)
end

-----------------------------------------------------------------------------------------
-- Creates a list of all variables and values, to be provided when a subscription is accepted
-- @return list with variablenames
-- @return list with variablevalues (order matching the name list)
function service:getupnpvalues()
    local names = {}
    local values = {}
    for _, v in pairs(self.servicestatetable) do
        if v.sendevents then    -- only if evented
            table.insert(names, v._name)    -- use original casing for name here
            table.insert(values, v:getupnp())
        end
    end
    return names, values
end

-----------------------------------------------------------------------------------------
-- Handler called before the new value is set to an owned statevariable.
-- The new value will have been checked and converted before this handler is called.
-- Override in descendant classes to implement device behaviour (when overriding, do not forget
-- to call the ancestor method to make this 'event' bubble up to the device level).
-- While the <code>afterset()</code> will only
-- be called when the value being set is actually different from the current value, the <code>beforeset()</code>
-- will always be run. Hence, <code>beforeset()</code> has the opportunity to change the value being set.
-- <br>Call order; <code>statevariable:beforeset() -&gt; service:beforeset() -&gt; device:beforeset()</code>
-- @param statevariable the statevariable (table/object) whose value is being changed
-- @param newval the new value to be set
-- @return newval to be set (Lua type) or <code>nil, error message, error number</code> upon failure
-- @see statevariable:beforeset
-- @see service:afterset
function service:beforeset(statevariable, newval)
  if self.parent and self.parent.beforeset then
    return self.parent:beforeset(self, statevariable, newval)
  else
    return newval
  end
end

-----------------------------------------------------------------------------------------
-- Handler called after the new value has been set to an owned statevariable.
-- <br/><strong>NOTE:</strong> this will only be called when the value
-- has actually changed, so setting the current value again will not trigger it!
-- Override in descendant classes to implement device behaviour (when overriding, do not forget
-- to call the ancestor method to make this 'event' bubble up to the device level)
-- <br>Call order; <code>statevariable:afterset() -&gt; service:afterset() -&gt; device:afterset()</code>
-- @param statevariable the statevariable (table/object) whose value is being changed
-- @param oldval the previous value of the statevariable
-- @see statevariable:beforeset
-- @see service:beforeset
function service:afterset(statevariable, oldval)
  if self.parent and self.parent.afterset then
    return self.parent:afterset(self, statevariable, oldval)
  else
    return
  end
end


-- Clears all the lazy-elements set. Applies to <code>getaction(), getservice(), getdevice(),
-- getroot(), gethandle()</code> methods.
-- Override in subclasses to clear tree-structure.
function service:clearlazyness()
    super.clearlazyness(self)
    for _, statevar in pairs(self.servicestatetable or {}) do
        statevar:clearlazyness()
    end
    for _, act in pairs(self.actionlist or {}) do
        act:clearlazyness()
    end
end

return service
