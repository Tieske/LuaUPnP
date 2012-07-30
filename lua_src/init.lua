-----------------------------------------------------------------
--  UPnP core module, will load other modules
--  After requiring this module, create your devices
--  and start the copas loop
-----------------------------------------------------------------

-- Setup logger
require ("logging.console")
logger = logging.console()
logger:setLevel (logging.DEBUG)
logger:debug("Starting logger")             -- possible: debug, info, warn, error, fatal
-- replace print function with logger
local oldprint = print
function print(...)
    local arg = {n=select('#',...),...}
    local i = 1
    result = ""
    while i <= arg.n do
        if i == 1 then
            result = tostring(arg[i])
        else
            result = result .. "\t" .. tostring(arg[i])
        end
        i = i + 1
    end
    logger:info(result)
end


local export = {}                           -- module export table
logger:debug("Loading Copas Timer")
local copas = require('copas.timer')        -- load Copas socket scheduler
logger:debug("Loading Copas Eventer")
local eventer = require('copas.eventer')    -- add event capability to Copas
logger:debug("Loading DSS")
local dss = require('dss')                  -- load darksidesync module (required for UPnP)
logger:debug("Loading UPnP core")
local lib = require("upnp.core")            -- load UPnP core module (C code)

-- create a global table
logger:debug("Setting up globals and classes")
upnp = export   -- create a global table
upnp.classes               = upnp.classes or {}
--upnp.classes.base          = require("upnp.classes.base")
upnp.classes.upnpbase      = require("upnp.classes.upnpbase")
upnp.classes.device        = require("upnp.classes.device")
upnp.classes.service       = require("upnp.classes.service")
upnp.classes.statevariable = require("upnp.classes.statevariable")
upnp.classes.action        = require("upnp.classes.action")
upnp.classes.argument      = require("upnp.classes.argument")
upnp.devices = {}          -- global list of UPnP devices, by their UDN
upnp.lib = lib             -- export the core UPnP lib

-- webserver setup
logger:debug("Configuring webserver")
export.webroot = "./web"    -- web root directory
export.baseurl = ""         -- base url pointing to webroot directory

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


-----------------------------------------------------------------------------------------
-- Gets an xml document. If a filename is given, it will first try to open, if it fails it
-- will try again relative to the <code>upnp.webroot</code> directory.
-- @param xmldoc this can be several things; 1) filename, 2) literal xml, 3) IXML object
-- @returns IXML object or nil + errormessage
function export.getxml(xmldoc)
    logger:debug("Entering upnp.getxml(); %s", tostring(xmldoc))
    local xml = upnp.lib.ixml
    local success, idoc, ielement, err
    if type(xmldoc)=="string" then
        -- parse as an xml buffer (literal xml string)
        idoc, err = xml.ParseBuffer(xmldoc)
        if not idoc then
            logger:warn("    Failed parsing as xml: %s", err)
            -- try loading as a file (filename)
            local separator = _G.package.config:sub(1,1)
            local filename = string.gsub(string.gsub(xmldoc, "\\", "/"), "/", separator) -- OS dependent
            idoc, err = xml.LoadDocument(filename)
            if not idoc then
                logger:warn("    Failed parsing as file %s\t %s", filename, err)
                -- nothing still, so try construct location from webroot and string given
                filename = string.gsub(upnp.webroot, "\\", "/") .. "\\" .. string.gsub(xmldoc, "\\", "/")
                filename = string.gsub(filename, "/\\/", "/")
                filename = string.gsub(filename, "/\\", "/")
                filename = string.gsub(filename, "\\/", "/")
                filename = string.gsub(filename, "\\", "/")      -- entire path is now single-foward-slash-separated
                -- parse as filename
                local filename = string.gsub(string.gsub(filename, "\\", "/"), "/", separator) -- OS dependent
                idoc, err = xml.LoadDocument(filename)
                if not idoc then
                    logger:warn("    Failed parsing as webroot based file " .. tostring(filename) .. "\t" .. tostring(err))
                else
                    logger:info("    Parsed as webroot based xml file %s", filename)
                end
            else
                logger:info("    Parsed as xml file")
            end
        else
            logger:info("    Parsed as xml buffer")
        end
        if not idoc then
            logger:error("getxml(): Failed to parse xml buffer/file " .. tostring(xmldoc))
            return nil, "Failed to parse xml buffer/file; " .. tostring(xmldoc)
        end
    elseif type(xmldoc) == "userdata" then
        -- test executing an IXML method to see if its a proper IXML object
        success, err = pcall(xml.getNodeType, xmldoc)
        if not success then
            logger:error("getxml(): userdata is not an IXML object, " .. tostring(err))
            return nil, err
        end
        idoc = xmldoc
    else
        logger:error("getxml(): Expected string or IXML document, got " .. type(xmldoc))
        return nil, "Expected string or IXML document, got " .. type(xmldoc)
    end
    logger:debug("Leaving upnp.getxml()")
    return idoc
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


-- Eventhandlers per event type
local EventTypeHandlers
EventTypeHandlers = {
    DEVICE = function(event, wt)
        if event.Event == "UPNP_EVENT_SUBSCRIPTION_REQUEST" then
            -- simply accept everything
            local device = upnp.devices[event.UDN or ""]
            local service = (device.servicelist or {})[event.ServiceID]
            if service then
                wt:setresult(device, service:getupnpvalues())   -- getupnpvalues returns 2 tables!!
                print()
                print("Added a subscription for service:", event.ServiceID)
                print()
            else
                print()
                print("Invalid subscription request for service:", event.ServiceID)
                print()
            end
        elseif event.Event == "UPNP_CONTROL_ACTION_REQUEST" then
            -- lookup device and service
            local device = upnp.devices[event.UDN or ""]
            local service = (device.servicelist or {})[event.ServiceID]
            local errstr, errnr, names, values = nil, nil, nil, nil
            if not service then
                errstr = "Action Failed; unknown ServiceId"
                errnr = 501
            else
                -- execute it
                names, values, errnr = service:executeaction(event.ActionName, event.Params)
                if not names then
                    -- failed, switch variables
                    errstr = values
                    values = nil
                end
            end
            -- return results
            if errnr then
                -- error
                wt:setresult(errnr, errstr)
            else
                -- success
                wt:setresult(names, values)
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
        logger:debug("UPnPCallback: received UPnP event; ")
        logger:debug(event)
        local et = UPnPEvents[event.Event].type
        if EventTypeHandlers[et] then
            -- execute handler for the received event type
            EventTypeHandlers[et](event, wt);
        end
    else
        -- an error occured
        logger:debug("UPnPCallback: " .. tostring(err))
    end
end

-- Event handler to handle Copas start/stop events as
-- generated by copas.eventer
local CopasEventHandler = function(self, sender, event)
    if sender ~= copas then
        return
    end

    if event == copas.events.loopstarted then
        -- Copas startup is complete, now start UPnP
        local et = self:dispatch(upnp.events.UPnPstarting)
        et:waitfor()    -- wait for event completion
        -- do initialization
        logger:debug("Starting UPnP library...")
        lib.Init(UPnPCallback)         -- start, attach event handler for UPnP events
        lib.web.SetRootDir(export.webroot)    -- setup the webserver
        export.baseurl = "http://" .. lib.GetServerIpAddress() .. ":" .. lib.GetServerPort() .. "/";
        -- raise event done
        self:dispatch(upnp.events.UPnPstarted)
        logger:info("UPnP library started, WebRoot = '%s', BaseURL = '%s'.", tostring(export.webroot), tostring(export.baseurl))
    elseif event == copas.events.loopstopping then
        -- Copas is stopping
        logger:debug("Stopping UPnP library...")
        local et = self:dispatch(upnp.events.UPnPstopping)
        et:waitfor()    -- wait for event completion
        lib.Finish()
        -- raise event done
        logger:debug("UPnP library stopped.")
        self:dispatch(upnp.events.UPnPstopped)
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
logger:debug("Loaded UPnP library")
return export
