-----------------------------------------------------------------------------
-- UPnP gateway.
-- This script implements a UPnP gateway, drivers can be loaded and configured.
-- Restarting, stopping and saving configuration actions for the gateway are 
-- available as UPnP methods and can be executed through controlpoint like 
-- DeviceSpy etc.<br/>
-- Use the <code>--help</code> command line option for more information.
-- eg: <code>lua.exe -v .\lua\upnp\bootstrap.lua --help</code><br/>
-- See <a href="../modules/upnp.drivers.driver-template.html">upnp.drivers.driver-template</a> for
-- a quick start in building your own drivers.
-- @class module
-- @name upnp.bootstrap
-- @see upnp.drivers.driver-template
local _VERSION = "0.1"
local _NAME = "LuaUPnP"

local print = print -- make local because UPnP redefines its
local config -- table containing configuration of gateway
local configfile = _NAME  -- filename for configuration
local socket = require("socket")
local logger


local exitcodes = setmetatable({
  ERROR = -1,     -- exit with error code
  CLEAN = 0,      -- exit with success code
  RESTART = 999,  -- exit requires a restart by the bootstrapper script
},{ __index = function(self, key)
      error(string.format("No element named '%s'", tostring(key)), 2)
    end
})
local exitcode = exitcodes.CLEAN   -- exitcode to be used when the loop exits, set default

-- config text will be added to the top of the configuration file
local configtext = string.format("%s version %s\n", _NAME, _VERSION)..[[

  Configuration file, supporting the following elements;
  ======================================================
   -- UPnP properties
  ["friendlyName"] = "short friendly name max 63 chars", 
  ["UDN"]          = nil,          -- will be set automatically if not provided
  
]]

local cli = require 'cliargs'
cli:set_name("LuaUPnP")
cli:add_flag("--version", "prints the program's version and exits")
cli:optarg("DRIVER", "drivers to load and start the UPnP engine with", nil ,5)
cli:add_option("-w, --webroot=PATH", "path to web root folder, where XML description files will be written", "./web/")
cli:add_option("-d, --debug=INFOLEVEL", "level of output to log (DEBUG, INFO, WARN, ERROR, FATAL)", "INFO")
cli:add_option("-c, --configpath=PATH", "path to the configuration files, where the drivers will load/store them (NOTE: must end with a path separator character)", "./config/")

local args = cli:parse_args()

-- Function that will exit the gateway and have it restarted (by commandline script)
local restartgateway = function()
  logger:info("+------------------------------------+")
  logger:info("|      Restarting gateway            |")
  logger:info("+------------------------------------+")
  exitcode = exitcodes.RESTART
  require('copas.timer').exitloop()
end

local utilityservice = {
    serviceType = "urn:schemas-thijsschreijer-nl:service:Gateway:1",
    serviceId = "urn:thijsschreijer-nl:service:Gateway:1",
    
    -------------------------------------------------------------
    --  CUSTOM IMPLEMENTATION
    -------------------------------------------------------------
    customList = {
      -- all elements here are copied into the final object
      -- by devicefactory.builddevice()
    },
    -------------------------------------------------------------
    --  ACTION LIST IMPLEMENTATION
    -------------------------------------------------------------
    actionList = {
      { name = "StopGateway",
        execute = function(self, params)
          logger:info("+------------------------------------+")
          logger:info("|      Exiting gateway               |")
          logger:info("+------------------------------------+")
          require('copas.timer').exitloop()
        end,
      },
      { name = "RestartGateway",
        execute = function(self, params)
          restartgateway()
        end,
      },
			{ name = "SaveConfiguration",
        execute = function(self, params)
          local success, result, err
          local tspend = socket.gettime()
          logger:info("+------------------------------------+")
          logger:info("|      Saving configuration          |")
          logger:info("+------------------------------------+")
          logger:info("Gateway: now writing gateway configuration")
          success, err = upnp.writeconfigfile(configfile, config, configtext)
          if not success then
            logger:error("Failed writing configuration: %s", err)
          end
          for name, driver in pairs(upnp.drivers or {}) do
            if driver.writeconfig then
              logger:info("Gateway: now instructing driver '%s' to write its config", name)
              success, result, err = pcall(driver.writeconfig, driver)
              if not success then err, result = result, nil end  -- pcall failed
              if success and (not result and err) then success = nil end   -- writeconfig returned nil + msg
              if not success then
                logger:error("Failed writing configuration: %s", err)
              end
            else
              logger:warn("Gateway: driver '%s' has no 'writeconfig' method, configuration not stored", name)
            end
          end
          tspend = socket.gettime() - tspend
          logger:info("Gateway: saving all driver configurations took %s seconds", tostring(tspend))
        end,
      },
    },
    
    -------------------------------------------------------------
    --  STATEVARIABLE IMPLEMENTATION
    -------------------------------------------------------------
    serviceStateTable = {
    },
  }


if args then
  if args.version then
    local upnp = require 'upnp' 
    return print("\n\n" .. upnp._VERSION .. "; " .. (upnp._DESCRIPTION or "nil"))
  end
  
  if args.DRIVER[#args.DRIVER] == "" then
    args.DRIVER[#args.DRIVER] = nil
  end
  
  if #args.DRIVER == 0 then
    return print("At least 1 driver must be specified, use --help option for more information")
  end
  
  args.debug = args.debug:upper()
  if not ({DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4, FATAL = 5})[args.debug] then
    return print("Invalid value for --debug option, use --help option for more information")
  end
  
  
  local upnp = require 'upnp' -- only load upnp here, because it redefines 'print'
  logger = upnp.logger
  logger:info("+------------------------------------+")
  logger:info("|      Loading configuration         |")
  logger:info("+------------------------------------+")
  -- configure engine with commandline options
  logger:info("Setting debug level to; " .. args.debug)
  logger:setLevel(args.debug)
  logger:info("Setting configuration path to; " .. args.configpath)
  upnp.configroot = args.configpath
  upnp.webroot = args.webroot

  -- Load configuration
  if not upnp.existsconfigfile(configfile) then
    -- no configfile yet, so set defaults
    config = { friendlyName = "LuaUPnP gateway", UDN = upnp.lib.util.CreateUUID() }
    upnp.writeconfigfile(
      configfile, 
      { friendlyName = "LuaUPnP gateway", UDN = upnp.lib.util.CreateUUID(), version = _VERSION },
      configtext)
  end
  
  config = upnp.readconfigfile(configfile)
  if not config then
    -- something is wrong, exit
    logger:fatal("Failed loading '%s' configfile", configfile)
    os.exit(exitcodes.ERROR)
  end
  
  if config.version ~= _VERSION then
    -- config file for different version, do some upgrading here?
    
  end
  
  -- create UUID if not present, store in 'config' so it can be persisted
  if not config.UDN then config.UDN = upnp.lib.util.CreateUUID() end
  
  -- create device
  logger:info("+------------------------------------+")
  logger:info("|      Setting up root device        |")
  logger:info("+------------------------------------+")
  local device = require("upnp.devices.urn_schemas-upnp-org_device_Basic_1")()
  device.UDN = config.UDN
  device.friendlyName = config.friendlyName
	device.manufacturer = "Thijs Schreijer"
  device.manufacturerURL = "http://www.thijsschreijer.nl"
  device.modelDescription = "A generic gateway device powered by the Lua scripting language, easily customized to add your own devices"
  device.modelName = "LuaUPnP gateway"
  
  -- create utility service
  logger:info("adding '"..utilityservice.serviceId.."' service")
  table.insert(device.serviceList, utilityservice)

  -- load a single driver
  local loaddriver = function(driver)
    local success, result = pcall(require, "upnp.drivers."..driver)
    if not success then
      logger:fatal("Failed loading driver '%s'; %s", driver, tostring(result))
      os.exit(exitcodes.ERROR)
    else
      logger:info("Loaded driver '%s'", driver)
      -- subscribe to UPnP start/stop events
      if result.starting then upnp:subscribe(result, result.starting, upnp.events.UPnPstarting) end
      if result.started  then upnp:subscribe(result, result.started,  upnp.events.UPnPstarted)  end
      if result.stopping then upnp:subscribe(result, result.stopping, upnp.events.UPnPstopping) end
      if result.stopped  then upnp:subscribe(result, result.stopped,  upnp.events.UPnPstopped)  end
      return result
    end
  end

  -- load drivers specified on commandline and load their devices
  logger:info("+------------------------------------+")
  logger:info("|      Loading drivers               |")
  logger:info("+------------------------------------+")
  upnp.drivers = upnp.drivers or {}
  for _, drivername in ipairs(args.DRIVER) do
    -- load driver
    local driver = loaddriver(drivername)
    upnp.drivers[drivername] = driver
    -- get its devices
    local success, driverdev = pcall(function() return driver:getdevice() end)
    if success then
      if driverdev then
        table.insert(device.deviceList, driverdev)
      else
        logger:warn("Driver '%s' did not return any devices", drivername)
      end
    else
      logger:fatal("Driver '%s' failed to deliver its devices; %s", drivername, driverdev)
      os.exit(exitcodes.ERROR)
    end
  end
  
  -- build the device and xmls from the device table
  logger:info("+------------------------------------+")
  logger:info("|      Build the root/sub-devices    |")
  logger:info("+------------------------------------+")
  upnp.devicefactory = require("upnp.devicefactory")
  local upnpdevice, e = upnp.devicefactory.builddevice(device)
  if not upnpdevice then
    logger:fatal("Failed to build device; %s", e)
    os.exit(exitcodes.ERROR)
  end
  

  -- start the engine by starting the copas loop
  logger:info("+------------------------------------+")
  logger:info("|      Starting the main loop        |")
  logger:info("+------------------------------------+")
  require('copas.timer').loop()
  
  -- exit using proper exitcode
  os.exit(exitcode)
end

