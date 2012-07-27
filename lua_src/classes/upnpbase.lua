---------------------------------------------------------------------
-- The base object for UPnP objects. This object provides hierarchy traversal,
-- through lazy-loading.
-- @class module
-- @name upnpbase
-- @copyright 2012 Thijs Schreijer
-- @release Version 0.1, Lua UPnP framework.

-- set the proper classname here, this should match the filename without the '.lua' extension
local classname = "upnpbase"

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


-----------------------------------------------------------------------------------------
-- Members of the upnpbase object.
-- @class table
-- @name upnpbase fields/properties
-- @field classname (string) the name of this class, basically the filename without the extension. Required to identify the type
-- of class, but also to re-create a device from persistence.
-- @field parent (table/object) the parent object within the UPnP device hierarchy. Only a root device will not have a parent, but will
-- have a field <code>root</root> set to <code>true</code>.
local upnpbase = upnp.classes.base:subclass({})

-----------------------------------------------------------------------------------------
-- Initializes the upnpbase object.
-- Will be called upon instantiation of an object, override this method to set default
-- values for all properties.
function upnpbase:initialize()
    self.classname = classname
    -- override in child classes

    -- subscribe to UPnP library events to detect starting/stopping the application
    upnp:subscribe(self, cteventhandler)
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
            if r.root then      -- found root
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
