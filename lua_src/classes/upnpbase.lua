---------------------------------------------------------------------
-- The base object for UPnP objects. This object provides hierarchy traversal,
-- through lazy-loading.
-- @class module
-- @name upnpbase
-- @copyright 2012 Thijs Schreijer
-- @release Version 0.1, Lua UPnP framework.

-- set the proper classname here, this should match the filename without the '.lua' extension
local classname = "upnpbase"
local oo = require("loop.simple")
-----------------------------------------------------------------------------------------
-- Members of the upnpbase object.
-- @class table
-- @name upnpbase fields/properties
-- @field classname (string) the name of this class, basically the filename without the extension. Required to identify the type
-- of class, but also to re-create a device from persistence.
-- @field parent (table/object) the parent object within the UPnP device hierarchy. Only a root device will not have a parent, but will
-- have a field <code>root</root> set to <code>true</code>.
local upnpbase = oo.class() --upnp.classes.base:subclass({})

-----------------
-- LOCAL STUFF --
-----------------

-- Event handler for the startup/shutdown events (through Copas Timer)
-- Only if an object is parent-less, the methods will be called
-- Each object is supposed to call its own children if required
local cteventhandler = function(self, sender, event)
    if not self.parent and sender == upnp then
        -- only deal with upnp events
        if event == upnp.events.UPnPstarting then
            -- do nothing here
        elseif event == upnp.events.UPnPstarted then
            if self.start then
                self:start()
            end
        elseif event == upnp.events.UPnPstopping then
            if self.stop then
                self:stop()
            end
        elseif event == upnp.events.UPnPstopped then
            -- do nothing here
        else
            -- unknown event, do nothing
        end
    end
end

--------------------------
-- CLASS IMPLEMENTATION --
--------------------------

-- called upon instantiation, hidden in upnpbase becuase we don't want everyone tro call teh rawnew() thing
-- instead do it here, and then  call 'initialize()' as a proper initialization method
function upnpbase:__init(...)
    --print ("calling upnpbase init...")
    ret = oo.rawnew(self, ...)
    if ret.initialize then
        ret:initialize()
    end
    return ret
end

-----------------------------------------------------------------------------------------
-- Check whether the object is a subclass of another class
-- @param super the class to test against
-- @returns <code>true</code> if the object is a subclass of <code>super</code>
function upnpbase:subclassof(super)
    return oo.subclassof(self, super)
end

-----------------------------------------------------------------------------------------
-- Returns the superclass of an object.
-- @returns the super-class of class or <code>nil</code> if class is not a class of the model
-- or does not define a super class.
function upnpbase:superclass()
    return oo.superclass(self)
end

-----------------------------------------------------------------------------------------
-- Creates a descendant class in the table provided.
-- @tbl table with properties to turn into a new object class
-- @returns object that represent a new class that provides the features defined by table and
-- that inherits from the class called upon. Changes on the object returned by this function
-- implies changes reflected on all its instances.
function upnpbase:subclass(tbl)
    return oo.class(tbl or {}, self)
end

-----------------------------------------------------------------------------------------
-- Initializes the upnpbase object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function upnpbase:initialize()
    --logger:debug("Initializing class '%s'...", classname)
    self.classname = classname
    -- override in child classes

    -- subscribe to UPnP library events to detect starting/stopping the application
    upnp:subscribe(self, cteventhandler)
    --logger:debug("Initializing class '%s' completed", classname)
end

-----------------------------------------------------------------------------------------
-- Gets the owning action. Only applicable for arguments.
function upnpbase:getaction()
    local function getit()
        if self.classname ~= "argument" then return end   -- exit if no parameter
        local r = self.parent
        self._action = r
        return r
    end
    return self._action or getit()
end

-----------------------------------------------------------------------------------------
-- Gets the owning service.
function upnpbase:getservice()
    local function getit()
        if self.classname ~= "argument" and
           self.classname ~= "action" and
           self.classname ~= "statevariable" and
           self.classname ~= "service" then
            return  -- there is no service for this type, exit
        end
        local r = self.parent
        if self.classname == "argument" then
            -- parameter is one level further, so special case here
            r = self:getaction()
            if r then
                r = r.parent
            end
        end
        if self.classname == "service" then
            -- silly, requesting ourselves...
            r = self
        end
        self._service = r
        return r
    end
    return self._service or getit()
end

-----------------------------------------------------------------------------------------
-- Gets the owning device.
function upnpbase:getdevice()
    local function getit()
        local r = self:getservice()
        if r then
            r = r.parent
        elseif self.classname == "device" then
            -- silly, requesting ourselves...
            r = self
        end
        self._device = r
        return r
    end
    return self._device or getit()
end

-----------------------------------------------------------------------------------------
-- Gets the owning rootdevice.
function upnpbase:getroot()
    local function getit()
        r = self:getdevice()
        while r ~= nil do
            if r.parent == nil then      -- found root
                self._root = r
                return r
            end
            r = r.parent
        end
        return      -- no root found
    end
    return self._root or getit()
end

-----------------------------------------------------------------------------------------
-- Gets the handle of the owning rootdevice.
function upnpbase:gethandle()
    local function getit()
        local d = self:getroot()
        if d then
            self._handle = d.handle
            return d.handle
        else
            return nil
        end
    end
    return self._handle or getit()
end

-----------------------------------------------------------------------------------------
-- Clears all the lazy-elements set. Applies to <code>getaction(), getservice(), getdevice(),
-- getroot(), gethandle()</code> methods.
-- Override in subclasses to clear tree-structure.
function upnpbase:clearlazyness()
    self._handle = nil
    self._root = nil
    self._device = nil
    self._service = nil
    self._action = nil
end

-----------------------------------------------------------------------------------------
-- Startup handler. Called for the event <code>upnp.events.UPnPstarted</code> (event
-- through the Copas Timer eventer mechanism)
-- This method will only be called on objects WITHOUT a parent (root devices). If an object has children,
-- it should call the <code>start</code> method on its children if required, they will not
-- be called automatically.
function upnpbase:start()
    -- override in descendant classes
end

-----------------------------------------------------------------------------------------
-- Shutdown handler. Called for the event <code>upnp.events.UPnPstopping</code> (event
-- through the Copas Timer eventer mechanism)
-- This method will only be called on objects WITHOUT a parent (root devices). If an object has children,
-- it should call the <code>stop</code> method on its children if required, they will not
-- be called automatically.
function upnpbase:stop()
    -- override in descendant classes
end

return upnpbase
