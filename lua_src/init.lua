---------------------------------------------------------------------
-- LuaUPnP is a binding for the pupnp library for Lua.
-- <br/>The library has dependencies on
-- <a href="http://luasocket.luaforge.net/">LuaSocket</a>,
-- <a href="http://keplerproject.github.com/copas/">Copas</a>,
-- <a href="http://github.com/Tieske/CopasTimer">CopasTimer</a>,
-- <a href="http://www.keplerproject.org/lualogging/">LuaLogging</a>,
-- <a href="http://luaforge.net/projects/date/">date</a>,
-- <a href="http://loop.luaforge.net/">Loop</a>,
-- <a href="http://github.com/Tieske/DarkSideSync">DarkSideSync</a> and
-- <a href="http://pupnp.sourceforge.net/">pupnp</a>.
-- When 'required' it will load all required modules, the core UPnP library, all devices
-- classes, etc. Only devices need to be set up before calling <code>copas.loop()</code>
-- to start the scheduler.
-- <br/>A global <code>upnp</code> will be created and it will be returned.
-- <br/><br/><strong>Note</strong>: the global <code>print()</code> function will be remapped to the logger, so everything
-- printed will be logged at the <code>info</code> level.
-- @class module
-- @name upnp
-- @copyright 2012 <a href="http://www.thijsschreijer.nl">Thijs Schreijer</a>, <a href="http://github.com/Tieske/LuaUPnP">LuaUPnP</a> is licensed under <a href="http://www.gnu.org/licenses/gpl-3.0.html">GPLv3</a>
-- @release Version 0.x, LuaUPnP.

-----------------------------------------------------------------------
-- List of members and namespaces within LuaUPnP.
-- @name upnp members and namespaces
-- @class table
-- @field classes holds a list of classes for upnp devices; upnpbase, device, service, etc.
-- @field devices list of registered devices indexed by their UDN
-- @field logger the logger in use by the upnp module (all <code>print()</code> commands will be rerouted here)
-- @field webroot path of the web-root directory
-- @field baseurl base url pointing to the web-root directory
-- @field configroot base directory for configuration information
-- @field lib contains the mapped functions of pupnp library
-- @field lib.web contains the mapped functions of upnp web methods
-- @field lib.http contains the mapped functions of upnp http methods
-- @field lib.util contains the mapped functions of upnp util methods
-- @field lib.ixml contains the mapped functions of upnp ixml methods

require ("logging.console")
logger = logging.console()
logger:setLevel (logging.DEBUG)
logger:debug("Starting logger")             -- possible: debug, info, warn, error, fatal
-- replace print function with logger
local oldprint = print
function print(...)
    local arg = {n=select('#',...),...}
    local i = 1
    local result = ""
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
upnp = {}   -- create a global table
upnp.logger = logger
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
upnp.configroot = "."     -- base directory for configuration information

-- webserver setup
logger:debug("Configuring webserver")
upnp.webroot = "./web"    -- web root directory
upnp.baseurl = ""         -- base url pointing to webroot directory

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

---------------------------------------------------------------------
-- Logs an error and then returns it. See usage, it will log the error
-- and then return the lua side nil + error msg, in a single call
-- *usage# return upnperror("my error message")
-- *param msg the error message
local upnperror = function(msg)
    logger:error(msg)
    return nil, msg
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

---------------------------------------------------------
-- Eventhandlers per event type
-- The eventhandlers call the appropriate Lua side object with the event data
-- @return the handlers return 1 on succes, or nil + error upon failure
local EventTypeHandlers
EventTypeHandlers = {
    DEVICE = function(event, wt)
        if event.Event == "UPNP_EVENT_SUBSCRIPTION_REQUEST" then
            -- simply accept everything
            local device = upnp.devices[event.UDN or ""]
            if not device then
                return upnperror(string.format("%s: have no device with id '%s'", event.Event, tostring(event.UDN)))
            end
            local service = (device.servicelist or {})[event.ServiceID]
            if not service then
                return upnperror(string.format("%s: have no service with id '%s' for device '%s'", event.Event, tostring(event.ServiceID), tostring(event.UDN)))
            end
            local hdl = device:gethandle()
            if not hdl then
                return upnperror(string.format("%s: device '%s' has no valid handle (bug??)", event.Event, tostring(event.UDN)))
            end
            local names, values = service:getupnpvalues()
            wt:setresult(device:gethandle(), names, values)   -- getupnpvalues returns 2 tables!!
            logger:info("Subscription accepted, for service '%s' @ device '%s'", tostring(event.ServiceID), tostring(event.UDN))
            logger:debug("send the following statevariable list (names and values)")
            logger:debug(names)
            logger:debug(values)
            return 1
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
                return upnperror(string.format("%s: Error: %s, %s", event.Event, tostring(errnr), tostring(errstr)))
            else
                -- success
                wt:setresult(names, values)
                return 1
            end
        end
    end,
    SOAP = function(event, wt)
        -- do nothing, no controlpoint yet
        print("Received unsupported request; SOAP, SSDP, GENA")
        return 1
    end,
    SSDP = function(event, wt)
        -- for now pass on to SOAP handler
        return EventTypeHandlers.SOAP(event, wt)
    end,
    GENA = function(event, wt)
        -- for now pass on to SOAP handler
        return EventTypeHandlers.SOAP(event, wt)
    end,
}

---------------------------------------------------------------------
-- Callback function, executed whenever a UPnP event arrives through DSS.
-- It will call the appropriate function from the <code>EventTypeHandlers</code> table
-- *param wt waitingthread object, on which 'setresult' must be called
-- *param event table with event parameters
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
        upnperror("UPnPCallback(): The UPnP lib returned an error through DSS: " .. tostring(err))
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
        lib.web.SetRootDir(upnp.webroot)    -- setup the webserver
        upnp.baseurl = "http://" .. lib.GetServerIpAddress() .. ":" .. lib.GetServerPort() .. "/";
        -- raise event done
        logger:info("UPnP library started;")
        logger:info("    WebRoot = '%s'", tostring(upnp.webroot))
        logger:info("    BaseURL = '%s'.", tostring(upnp.baseurl))
        self:dispatch(upnp.events.UPnPstarted)
    elseif event == copas.events.loopstopping then
        -- Copas is stopping
        logger:debug("Stopping UPnP library... (1/3)")
        local et = self:dispatch(upnp.events.UPnPstopping)
        et:waitfor()    -- wait for event completion
        lib.Finish()
        -- raise event done
        logger:debug("UPnP library stopped (2/3).")
        et = self:dispatch(upnp.events.UPnPstopped)
        -- wait for this one, because copas loopstopping will wait for the current
        -- thread to finish, but not on threads spawned by this process. So waiting
        -- must be done here.
        et:waitfor()
        logger:debug("UPnP library stop handlers completed (3/3).")
    end
end

-----------------------------------------------------------------------------------------
-- Starts a UPnP device. Registers the device with the lib to enable network comms and callbacks.
-- @param rootdev device object, must be a root device with the <code>rootdev.devicexmlurl</code> set
-- to the relative path within the <code>webroot</code> path, where the device description xml can be
-- downloaded.
-- @return handle to the newly registered device or nil + error message
function upnp.startdevice(rootdev)
    logger:debug("Entering upnp.startdevice()...")
    if type(rootdev) ~= "table" or
       rootdev.classname ~= "device" or
       rootdev.parent ~= nil then
       return upnperror("upnp.startdevice(): Expected a root-device table, didn't get it")
    end
    if not rootdev.devicexmlurl then
        return upnperror(string.format("upnp.startdevice(); property 'devicexmlurl' not set, cannot start device '%s' without description url.", tostring(rootdev.getudn())))
    end
    -- structure url
    local url = string.gsub(upnp.baseurl, "\\", "/") .. "\\" .. string.gsub(rootdev.devicexmlurl, "\\", "/")
    url = string.gsub(url, "/\\/", "/")
    url = string.gsub(url, "/\\", "/")
    url = string.gsub(url, "\\/", "/")
    url = string.gsub(url, "\\", "/")      -- entire path is now single-foward-slash-separated
    -- start it
    local hdl, err = lib.RegisterRootDevice(url, upnp.UPnPCallback)
    if hdl then
        logger:info("upnp.startdevice(); advertizing '%s' with id '%s'", tostring(rootdev.friendlyname), tostring(rootdev:getudn()))
        hdl:SendAdvertisement(100)
        logger:debug("upnp.startdevice(); successfully started device")
    else
        logger:error("upnp.startdevice(); error returned from RegisterRootDevice(): " .. tostring(err))
    end
    logger:debug("Leaving upnp.startdevice()...")
    return hdl, err
end

-----------------------------------------------------------------------------------------
-- Stops a UPnP device. Unregisters the device with the lib to disable network comms and callbacks.
-- @param hdl handle to the currently enabled device
-- @return 1 on success, or <code>nil + error message</code>
function upnp.stopdevice(hdl)
    return lib.UnRegisterRootDevice(hdl)
end

-----------------------------------------------------------------------------------------
-- Read a configfile. The configfile must be a lua table format, starting with '<code>
-- return {</code>' and ending with '<code>}</code>'.
-- @param configname configuration filename to load. This should only be a filename
-- (no path), and it will be sought for in the <code>upnp.configroot</code> directory.
-- @return table with configuration loaded, or <code>nil + error</code> if it failed
-- @see upnp.configroot #upnp members and namespaces
function readconfigfile(configname)
  local path = upnp.configroot:gsub("\\","/")
  if #path>0 and path:sub(-1,-1) ~= "/" then
    path = path .. "/"
  end
  while configname:sub(1,1) == "/" do
    configname = configname:sub(2, -1)
  end
  path = path .. configname

  logger:debug("upnp.readconfigfile, reading from: " .. path)
  local success, result = pcall(dofile, path)
  if not success then
    logger:error("upnp.readconfigfile: " .. tostring(result))
    return nil, result  -- return error
  end
  return result
end

-----------------------------------------------------------------------------------------
-- Write a configfile. The configfile must be a string in Lua table format, starting with '<code>
-- return {</code>' and ending with '<code>}</code>'.
-- @param configname configuration filename to write to. This should only be a filename only
-- (no path), and it will be stored in the <code>upnp.configroot</code> directory.
-- @param content the content to write, must be valid Lua code returning a table.
-- @return 1 on success, <code>nil + errormsg</code> upon failure
-- @see upnp.configroot #upnp members and namespaces
function writeconfigfile(configname, content)
  local path = upnp.configroot:gsub("\\","/")
  if #path>0 and path:sub(-1,-1) ~= "/" then
    path = path .. "/"
  end
  while configname:sub(1,1) == "/" do
    configname = configname:sub(2, -1)
  end
  path = path .. configname

  logger:debug("upnp.writeconfigfile, writing to: " .. path)
  local file, err = io.open(path, "w")
  if not file then
    logger:error("upnp.readconfigfile: " .. tostring(err))
    return nil, err  -- return error
  end
  file:write(content)
  file:close()
  return 1
end
-----------------------------------------------------------------------------------------
-- Gets an xml document. It will try to get the xml from several things; 1) filename,
-- 2) literal xml, 3) IXML object. If a filename is given, it will first try to open, if
-- it fails it will try again relative to the <code>upnp.webroot</code> directory.
-- @param xmldoc either 1) filename, 2) literal xml, 3) IXML object
-- @return IXML object or <code>nil + errormessage</code>
function upnp.getxml(xmldoc)
    logger:debug("Entering upnp.getxml(); %s", tostring(xmldoc))
    local xml = upnp.lib.ixml
    local success, idoc, err
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
            return upnperror("getxml(): Failed to parse xml buffer/file " .. tostring(xmldoc))
        end
    elseif type(xmldoc) == "userdata" then
        -- test executing an IXML method to see if its a proper IXML object
        success, err = pcall(xml.getNodeType, xmldoc)
        if not success then
            return upnperror("getxml(): userdata is not an IXML object, " .. tostring(err))
        end
        idoc = xmldoc
    else
        return upnperror("getxml(): Expected string or IXML document, got " .. type(xmldoc))
    end
    logger:debug("Leaving upnp.getxml()")
    return idoc
end


local subscribe, unsubscribe, events        -- make local trick LuaDoc
---------------------------------------------------------------------------------
-- Subscribe to events of upnp library.
-- These are not individual device/service event, but library events.
-- @name upnp.subscribe
-- @see copas.eventer http://tieske.github.com/CopasTimer/
-- @see upnp.events
subscribe = function()
end
subscribe = nil
---------------------------------------------------------------------------------
-- Unsubscribe from events of upnp library.
-- @name upnp.unsubscribe
-- @see copas.eventer http://tieske.github.com/CopasTimer/
-- @see upnp.events
unsubscribe = function()
end
unsubscribe = nil
---------------------------------------------------------------------------------
-- Events generated by upnp library for starting and stopping. Besides these events
-- there are additional events from <code>copas</code> as that scheduler is used (see
-- 'CopasTimer' and specifically the <code>copas.eventer</code> module).
-- @see upnp.subscribe
-- @see upnp.unsubscribe
-- @class table
-- @name upnp.events
-- @field UPnPstarting This event is started on the <code>copas.events.loopstarted</code> event and executes before any UPnP code is being run. Only when this event is complete (all handlers spawned have finished) the UPnP code will start. Use this event to setup any UPnP devices.
-- @field UPnPstarted Runs after the UPnP library has been initiated and is running. The device object typically start themselves on this event and will announce themselves.
-- @field UPnPstopping This event is started from the <code>copas.events.loopstopping</code> event and executes before any UPnP code is being torn down. Only when this event is complete (all handlers spawned have finished) the UPnP code will initiate the teardown. The device object typically will stop itself on this event.
-- @field UPnPstopped Runs after the UPnP code has been stopped
events = { "UPnPstarting", "UPnPstarted", "UPnPstopping", "UPnPstopped"}

-- add event capability to module table
copas.eventer.decorate(upnp, events)

-- subscribe to copas events
copas:subscribe(upnp, CopasEventHandler)

-- return the upnp table as module table
logger:debug("Loaded UPnP library")
return upnp
