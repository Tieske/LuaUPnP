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
--  Test functions, put main code here.
-----------------------------------------------------------------
local cp        -- controlpoint id

local testlist = {
    function()
        print("List of the UPnP module:\n========================\n")
        table.print(upnp);
        print("\n\n")
    end,

    function()
        cp = upnp.RegisterClient()
        print(tostring(cp))
    end,

    function()
        print("starting UPnP")
        upnp.Init()
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
-- test function to run tests in a row
local test = function()

    if testlist[testcount] then
        -- run next test
        print ("=========== starting test " .. testcount .. " ===========")
        xpcall(testlist[testcount], errf)
        testcount = testcount + 1
    else
        -- we're done, exit
        print ("=========== tests completed ===========")
        timer:cancel()
        copas.exitloop()
    end

end


wait ("Press enter to start...")

-- create timer for test function, every 0.5 second
timer = copas.newtimer(test, test, nil, true, nil):arm(1)

copas.loop()

--wait ("Press enter to exit...")

