-----------------------------------------------------------------
--  UPnP core module, will load other modules
--  After requiring this module, create your devices
--  and start the copas loop
-----------------------------------------------------------------

local export = {}                           -- module export table
local copas = require('copas.timer')        -- load Copas socket scheduler
local eventer = require('copas.eventer')    -- add event capability to Copas
local dss = require('dss')                  -- load darksidesync module (required for UPnP)
local lib = require("LuaUPnP")              -- load UPnP core module (C code)

-- create a global table
upnp = export   -- create a global table
upnp.classes = upnp.classes or {}
upnp.classes.base = require("upnp.classes.base")
upnp.classes.upnpbase = require("upnp.classes.upnpbase")
upnp.classes.statevariable = require("upnp.classes.statevariable")
upnp.classes.argument = require("upnp.classes.argument")

-- webserver setup
export.webroot = "./web"    -- web root directory
export.baseurl = ""         -- base url pointing to webroot directory
export.devices = {}         -- table of all known (sub)devices by their UDN
export.lib = lib            -- export the cure UPnP lib

-- Link Copas to DSS;
-- the darksidesync lib has a Lua side piece of code that listens to the UDP signal whenever
-- a background lib has delivered something.
-- It provides a socket we need to listen on, and a callback that needs to be called when
-- the socket is ready to read data. All we need to do is add them to our socket scheduler.
-- We're using Copas as a socket scheduler, so add the darksidesync socket and the handler in a
-- Copas way to the scheduler
copas.addserver(dss.getsocket(), function(skt)
        skt = copas.wrap(skt)
        local hdlr = dss.gethandler()
        while true do
            hdlr(skt)
        end
    end)

local errf = function(msg)
	print (debug.traceback(msg or "Stacktrace:"))
    --copas.exitloop()
end


-- Table containg all UPnP events generated by the UPnP lib
local UPnPEvents = {
-- SSDP stuff
	UPNP_DISCOVERY_ADVERTISEMENT_ALIVE = {
		type = "SSDP",
		},
	UPNP_DISCOVERY_SEARCH_RESULT = {
		type = "SSDP",
		},
	UPNP_DISCOVERY_SEARCH_TIMEOUT = {
		type = "SSDP",
		},
	UPNP_DISCOVERY_ADVERTISEMENT_BYEBYE = {
		type = "SSDP",
		},
-- SOAP Stuff
	UPNP_CONTROL_ACTION_COMPLETE = {
		type = "SOAP",
		},
	UPNP_CONTROL_GET_VAR_COMPLETE = {
		type = "SOAP",
		},
-- GENA Stuff
	UPNP_EVENT_RECEIVED = {
		type = "GENA",
		},
	UPNP_EVENT_SUBSCRIBE_COMPLETE = {
		type = "GENA",
		},
	UPNP_EVENT_UNSUBSCRIBE_COMPLETE = {
		type = "GENA",
		},
	UPNP_EVENT_RENEWAL_COMPLETE = {
		type = "GENA",
		},
	UPNP_EVENT_AUTORENEWAL_FAILED = {
		type = "GENA",
		},
	UPNP_EVENT_SUBSCRIPTION_EXPIRED = {
		type = "GENA",
		},
-- Device events
	UPNP_EVENT_SUBSCRIPTION_REQUEST = {
		type = "DEVICE",
		},
	UPNP_CONTROL_GET_VAR_REQUEST = {
		type = "DEVICE",
		},
	UPNP_CONTROL_ACTION_REQUEST = {
		type = "DEVICE",
		},
}
-- Add a 'name' element to each event in the table above
for k,v in pairs(UPnPEvents) do
    v.name = k
end

--[[local VarGetter = function(self) return self.value end
local VarGetPair = function(self, tables) -- 2 values; name and value returned, in tables if set
    if tables then
        return {self.name}, {self.value}  -- return in tables
    end
    return self.name, self.value          -- return as values
end
local VarSetter = function(self, newval, event)
    if self.value == newval then return end  -- nothing to do
    self.value = newval
    if self.evented then
        print("'" .. tostring(self.name) .. "' was updated to: " .. tostring(newval) .. "  (update event send)")
        if event then
            -- raise event for statevariable
            device:Notify(event.DevUDN, event.ServiceID, self.name, tostring(newval))
        else
            print("No eventdata provided to raise event for statevariable ", self.name)
        end
    else
        print("'" .. tostring(self.name) .. "' was updated to: " .. tostring(newval))
    end
end
local VarList = {
    Status = { value = 0, evented = true },
    Target = { value = 0, evented = false },
    LoadLevelStatus = { value = 100, evented = true },
    LoadLevelTarget = { value = 100, evented = false },
    StepDelta = { value = 20, evented = false },
}
-- Append get/set functions for each variable and a name field
for var, tbl in pairs(VarList) do
    tbl.name = var  -- add a name field to the variable table
    tbl.get = VarGetter
    tbl.getpair = VarGetPair
    tbl.set = VarSetter
end

local printstatus = function()
    s = "ON "
    if VarList.Status:get() == 0 then
        s = "OFF"
    end
    print ("+---------------------------------------------+")
    print (string.format("|    Device is %s at %03d%%                    |", s, VarList.LoadLevelStatus:get()))
    print ("+---------------------------------------------+")
    print()
end


local ActionList = {
    GetStatus = function(event, wt)
        wt:setresult({"ResultStatus"}, {VarList.Status:get()})
    end,
    SetTarget = function(event, wt)
        local t = string.upper(event.Params.newTargetValue)
        if t == "1" or t == "ON" or t == "TRUE" then
            t = 1
        elseif t == "0" or t == "OFF" or t == "FALSE" then
            t = 0
        else
            wt:setresult(600, "Argument Value Invalid")
            return
        end
        wt:setresult()
        VarList.Target:set(t, event)
        VarList.Status:set(t, event)
    end,
    GetTarget = function(event, wt)
        wt:setresult({"RetTargetValue"},{VarList.Target:get()})
    end,
    SetLoadLevelTarget = function(event, wt)
        local t = tonumber(event.Params.NewLoadLevelTarget)
        if not t then
            wt:setresult(600, "Argument Value Invalid")
        else
            if t >= 0 and t<=100 then
                wt:setresult()
                VarList.LoadLevelTarget:set(t, event)
                VarList.LoadLevelStatus:set(t, event)
            else
            wt:setresult(600, "Argument Value Out of Range")
            end
        end
    end,
    GetLoadLevelStatus = function(event, wt)
        wt:setresult({"RetLoadLevelStatus"}, {VarList.LoadLevelStatus:get()})
    end,
    GetStepDelta = function(event, wt)
        wt:setresult({"RetStepDelta"},{VarList.StepDelta:get()})
    end,
    SetStepDelta = function(event, wt)
        local t = tonumber(event.Params.NewStepDelta)
        if not t then
            wt:setresult(600, "Argument Value Invalid")
        else
            if t >= 0 and t<=100 then
                VarList.StepDelta:set(t, event)
                wt:setresult()
            else
            wt:setresult(600, "Argument Value Out of Range")
            end
        end
    end,
    StepDown = function(event, wt)
        wt:setresult()
        local ll = VarList.LoadLevelStatus:get()
        ll = ll - VarList.StepDelta:get()
        if ll<0 then ll = 0 end
        VarList.LoadLevelTarget:set(ll, event)
        VarList.LoadLevelStatus:set(ll, event)
    end,
    StepUp = function(event, wt)
        wt:setresult()
        local ll = VarList.LoadLevelStatus:get()
        ll = ll + VarList.StepDelta:get()
        if ll>100 then ll = 100 end
        VarList.LoadLevelTarget:set(ll, event)
        VarList.LoadLevelStatus:set(ll, event)
    end,
}
]]--

-- Eventhandlers per event type
local EventTypeHandlers = {
    DEVICE = function(event, wt)
        if event.Event == "UPNP_EVENT_SUBSCRIPTION_REQUEST" then
            -- simply accept everything
            local names = {}
            local values = {}
            for n, v in pairs(VarList) do
                table.insert(names, n)
                table.insert(values, v:get())
            end
            wt:setresult(device, names, values)
            print()
            print("Added a subscription for service:", event.ServiceID)
            print()
        elseif event.Event == "UPNP_CONTROL_ACTION_REQUEST" then
            if ActionList[event.ActionName] == nil then
                print ("ActionRequest received for an unknown action;", event.ActionName)
            else
                print ("Now executing; ", event.ActionName)
                ActionList[event.ActionName](event, wt)
                print ("Action completed")
                printstatus()
            end
        end
    end,
    SOAP = function(event, wt)
        -- do nothing, no controlpoint yet
        print("Received unsupported request; SOAP, SSDP, GENA")
    end,
    SSDP = function(event, wt)
        -- for now pass on to SOAP handler
        EventTypeHandlers.SOAP(event, wt)
    end,
    GENA = function(event, wt)
        -- for now pass on to SOAP handler
        EventTypeHandlers.SOAP(event, wt)
    end,
}

-- Callback function, executed whenever a UPnP event arrives
-- wt = waitingthread object, on which 'setresult' must be called
-- event = table with event parameters
local UPnPCallback = function (wt, event)
    local err
    if type(wt) ~= "userdata" then
        err = event
        event = wt
        wt = nil
    end
    if event then
        -- we've got an event to handle
        local et = UPnPEvents[event.Event].type
        if EventTypeHandlers[et] then
            -- execute handler for the received event type
            EventTypeHandlers[et](event, wt);
        end
    else
        -- an error occured
        print ("LuaUPnP error:")
        print(err)
        print()
    end
end

-- Event handler to handle Copas start/stop events as
-- generated by copas.eventer
local CopasEventHandler = function(self, sender, event)
    if sender ~= copas then
        return
    end

    if event == "loopstarted" then
        -- Copas startup is complete, now start UPnP
        local et = self:dispatch("UPnPstarting")
        et:waitfor()    -- wait for event completion
        -- do initialization
        print("Starting UPnP library...")
        lib.Init(UPnPCallback)         -- start, attach event handler for UPnP events
        lib.web.SetRootDir(webroot)    -- setup the webserver
        baseurl = "http://" .. lib.GetServerIpAddress() .. ":" .. lib.GetServerPort() .. "/";
        -- raise event done
        self:dispatch("UPnPstarted")
        print("UPnP library started, WebRoot = '" .. webroot .. "', BaseURL = '" .. baseurl .. "'.")
    elseif event == "loopstopping" then
        -- Copas is stopping
        local et = self:dispatch("UPnPstopping")
        et:waitfor()    -- wait for event completion
        lib.Finish()
        -- raise event done
        self:dispatch("UPnPstopped")
    end
end


local subscribe, unsubscribe, events        -- make local trick LuaDoc
---------------------------------------------------------------------------------
-- Subscribe to events of xpllistener.
-- @usage# function xpldevice:eventhandler(sender, event, msg, ...)
--     -- do your stuff with the message
-- end
-- &nbsp
-- function xpldevice:initialize()
--     -- subscribe to events of listener for new messages
--     xpl.listener:subscribe(self, self.eventhandler, xpl.listener.events.newmessage)
-- end
-- @see copas.eventer
-- @see events
subscribe = function()
end
subscribe = nil
---------------------------------------------------------------------------------
-- Unsubscribe from events of xpllistener.
-- @see copas.eventer
-- @see events
unsubscribe = function()
end
unsubscribe = nil
---------------------------------------------------------------------------------
-- Events generated by xpllistener. There is only one event, for additional events
-- the start and stop events of the <code>copas</code> scheduler may be used (see
-- 'CopasTimer' and specifically the <code>copas.eventer</code> module).
-- @see subscribe
-- @see unsubscribe
-- @class table
-- @name events
-- @field newmessage event to indicate a new message has arrived. The message will
-- be passed as an argument to the event handler.
-- @field networkchange event to indicate that the newtork state changed (ip address,
-- connectio lost/restored, etc.). The <code>newState</code> and <code>oldState</code>
-- will be passed as arguments to the event handler (see 'NetCheck' documentation for
-- details on the <code>xxxState</code> format)
-- @see subscribe
events = { "UPnPstarting", "UPnPstarted", "UPnPstopping", "UPnPstopped"}

-- add event capability to module table
copas.eventer.decorate(export, events)

-- subscribe to copas events
copas:subscribe(export, CopasEventHandler)

-- return the upnp table as module table
return export