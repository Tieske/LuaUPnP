-----------------------------------------------------------------
--  Test module, initialize here, main test function below
-----------------------------------------------------------------

local copas = require('copas.timer')        -- load Copas socket scheduler
local dss = require('dss')      -- load darksidesync module
local upnp = require("LuaUPnP")
local ft = require ("pl.pretty").write
table.print = function(t) print(ft(t)) end

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

local wait = function(t)
	print ("\n\n" .. tostring(t or "Press enter to continue..."))
	io.read()
end

local errf = function(msg)
	print (debug.traceback(msg or "Stacktrace:"))
    copas.exitloop()
end

-----------------------------------------------------------------
--  Test functions, put main code here
-- if a different interval to next test is required, return interval in seconds
-----------------------------------------------------------------
local device        -- UPnP device handle
local webroot = "./web"
local baseurl
local upnpcb = function(event, err)
    if event then
        print ("Received event:")
        table.print(event)
        print()
    else
        -- an error occured
        print ("LuaUPnP error:")
        print(err)
        print()
    end
end

local testlist = {
    function()
        print("starting UPnP")
        upnp.Init(upnpcb)
        baseurl = "http://" .. upnp.GetServerIpAddress() .. ":" .. upnp.GetServerPort() .. "/";
        print ("BaseURL:", baseurl)
    end,

    function()
        print("Setting webserver root")
        print (upnp.web.SetRootDir(webroot))
    end,

    function()
        print("Registering device")
        local result = { upnp.RegisterRootDevice(baseurl .. "DimmableLight_dcp.xml") }
        device = result[1]
        table.print(result);
        return
    end,

    function()
        print("Advertising device")
        local result = { device:SendAdvertisement(100) }
        table.print(result);
        return 60
    end,

    function()
        print("Unregistering device")
        local result = { device:UnRegisterRootDevice() }
        table.print(result);
    end,

    function()
        print("stopping UPnP")
        upnp.Finish()
    end,

}


-----------------------------------------------------------------
--  Generic test functionality to start and trace errors
-----------------------------------------------------------------

local timer
local testcount = 1
local testinterval = 1/2      -- seconds
-- test function to run tests in a row
local test = function()

    if testlist[testcount] then
        -- run next test
        print ("=========== starting test " .. testcount .. " ===========")
        local success, int = xpcall(testlist[testcount], errf)
        if success then
            int = int or testinterval
        else
            int = testinterval
        end
        timer:arm(int)
        testcount = testcount + 1
        if int ~= testinterval then
            print("(next test starts in " .. tostring(int) .. " seconds)")
        end
    else
        -- we're done, exit
        print ("=========== tests completed ===========")
        timer:cancel()
        copas.exitloop()
    end

end


wait ("Press enter to start...")

-- create timer for test function
timer = copas.newtimer(nil, test, nil, true, nil)
timer:arm(0)    -- run first test immediately

copas.loop()

--wait ("Press enter to exit...")

