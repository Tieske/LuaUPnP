-- command-line runner
package.path = "./lua/?.lua;./lua/?/init.lua;./lua/?/?.lua;" .. package.path

local cli = require 'cliargs'
local print = print -- make local becasue UPnP redefines its
local configfile = "LuaUPnP"  -- filename for configuration

cli:set_name("LuaUPnP")
cli:add_flag("--version", "prints the program's version and exits")
cli:optarg("DRIVER", "drivers to load and start the UPnP engine with", nil ,5)
cli:add_option("-w, --webroot=PATH", "path to web root folder, where XML description files will be written", "./web/")
cli:add_option("-d, --debug=INFOLEVEL", "level of output to log (DEBUG, INFO, WARN, ERROR, FATAL)", "INFO")
cli:add_option("-c, --configpath=PATH", "path to the configuration files, where the drivers will load/store them (NOTE: must end with a path separator character)", "./")

local args = cli:parse_args()

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
  local logger = upnp.logger
  -- configure engine with commandline options
  logger:info("Setting debug level to; " .. args.debug)
  logger:setLevel(args.debug)
  logger:info("Setting configuration path to; " .. args.configpath)
  upnp.configroot = args.configpath
  upnp.webroot = args.webroot

  -- Load configuration
  local config
  if not upnp.existsconfigfile(configfile) then
    -- no configfile yet, so set defaults
    config = [[
-- LuaUPnP configuration file
return {
  friendlyName = "%s",
  UDN = "%s",
}
    ]]
    config = string.format(config,"LuaUPnP gateway", upnp.lib.util.CreateUUID())
    upnp.writeconfigfile(configfile, config)
  end
  
  config = upnp.readconfigfile(configfile)
  if not config then
    -- something is wrong, exit
    logger:fatal("Failed loading '%s' configfile", configfile)
    os.exit()
  end
  
  -- create device
  local device = require("upnp.devices.urn_schemas-upnp-org_device_Basic_1")()
  device.UDN = config.UDN
  device.friendlyName = config.friendlyName
	device.manufacturer = "Thijs Schreijer"
  device.manufacturerURL = "http://www.thijsschreijer.nl"
  device.modelDescription = "A generic gateway device powered by the Lua scripting language, easily customized to add your own devices"
  device.modelName = "LuaUPnP gateway"
  
  -- load a single driver
  local loaddriver = function(driver)
    local success, result = pcall(require, "upnp.drivers."..driver)
    if not success then
      logger:fatal("Failed loading driver '%s'; %s", driver, tostring(result))
      os.exit()
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
      os.exit()
    end
  end
  
  -- build the device and xmls from the device table
  upnp.devicefactory = require("upnp.devicefactory")
  local upnpdevice, e = upnp.devicefactory.builddevice(device)
  if not upnpdevice then
    logger:fatal("Failed to build device; %s", e)
    os.exit()
  end
  

  -- start the engine by starting the copas loop
  require('copas.timer').loop()
  
end

