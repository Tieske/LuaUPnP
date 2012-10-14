-----------------------------------------------------------------------------
-- Device factory for generating standardized services and devices (xml's + implementation code).
-- This module has methods for creating services and devices from standard
-- elements (provided the required modules to support that device/service)
-- are available.
-- @class module
-- @name upnp.devicefactory


local upnp = require("upnp")
local xmlfactory = require("upnp.xmlfactory")
local logger = upnp.logger
local devicefactory = {}

-- Checks a type, or creates one from the elements. Either the separate elements are given, or the 
-- first argument can be the full string.
-- @param domain string, domainname to use; standard = <code>"schemas.upnp.org"</code>. 
-- @param elementtype string, either "device" or "service"
-- @param typename string name of the type; example: <code>"BinaryLight"</code>
-- @param version integer version number of type; example <code>1</code>
-- @return fulltype or nil + error
local typecheck = function(domain, elementtype, typename, version)
  if not typename or not version then
    -- must split domain parameter
    local et, sdom
    _, _, sdom, et, typename, version = domain:find("^urn%:(.-)%:(.-)%:(.-)%:(.-)$")
    if et ~= elementtype then
      local err = string.format("typecheck failed; '%s' is of type '%s', expected type '%s'", tostring(domain), tostring(et), tostring(elementtype))
      logging:error("devicefactory.typecheck: %s", err)
      return nil, err
    end
    domain = sdom
  end
  return ("urn:"..domain..":"..elementtype..":"..typename..":"..version):gsub(" ",""):gsub("%.","-")
end


-- @param elemtype is either "device" or "service"
local creategeneric = function(domain, elemtype, typename, version)
  fulltype = typecheck(domain, elemtype, typename, version)
  if not fulltype then return nil, string.format("cannot create %s, typecheck failed", tostring(elemtype)) end
  
  local success, creator = pcall(require, "upnp."..elemtype.."s."..fulltype:gsub("%:","_"):gsub("%.","_"))
  if not success then
    return nil, string.format("cannot create '%s', no module found for it or error loading. ErrMsg: %s", tostring(devtype), tostring(creator))
  end
  
  return creator()
end

--------------------------------------------------------------------------------------
-- Creates an empty service table.
devicefactory.emptyservice = function()
  return { actionList = {}, serviceStateTable = {} }
end

--------------------------------------------------------------------------------------
-- Creates an empty device table.
devicefactory.emptydevice = function()
  return { serviceList = {}, deviceList = {} }
end

--------------------------------------------------------------------------------------
-- Creates the requested device table (if available). The output can be used as input for the
-- <code>xmlfactory</code>.
-- For the parameters check the device property <code>deviceType</code> in the device xml of the
-- UPnP architecture documents.
-- @param domain domainname of the type to create, alternatively, the full <code>deviceType</code> contents
-- @param devicetype name of the type to create, or nil if the domain contains the full type identifier
-- @param version version number of the type to create, or nil if the domain contains the full type identifier
-- @return device table, or nil + errormsg
-- @example# -- two ways to create the same device
-- devicefactory.createdevice("schemas.upnp.org", "BinaryLight", "1")
--   -- or
-- devicefactory.createdevice("urn:schemas-upnp-org:device:BinaryLight:1")
devicefactory.createdevice = function(domain, devicetype, version)
  local results = { creategeneric(domain, "device", devicetype, version) }
  if not results[1] then
    logger:error("devicefactory.createdevice: " .. tostring(results[2]))
    return nil, results[2]
  end
  return unpack(results)
end

--------------------------------------------------------------------------------------
-- Creates the requested service table (if available). The output can be used as input for the
-- <code>xmlfactory</code>. See <code>createdevice()</code> for more details.
-- @param domain domainname of the type to create, alternatively, the full <code>serviceType</code> contents
-- @param servicetype name of the type to create, or nil if the domain contains the full type identifier
-- @param version version number of the type to create, or nil if the domain contains the full type identifier
-- @return service table, or nil + errormsg
-- @see devicefactory.createdevice
devicefactory.createservice = function(domain, servicetype, version)
  local results = { creategeneric(domain, "service", servicetype, version) }
  if not results[1] then
    logger:error("devicefactory.createservice: " .. tostring(results[2]))
    return nil, results[2]
  end
  return unpack(results)
end

--------------------------------------------------------------------------------------
-- Customizes a service by dropping optional elements (statevariables and/or actions) and
-- adding the implementation functions/methods. 
-- @param service the service table to be customized (typically
-- this is the table returned from <code>devicefactory.createservice()</code>).
-- @param customtable a table containing the elements to customize by name, with value
-- <code>false</code> to drop, or a table containing the <code>execute, beforeset, 
-- afterset</code> functions.
-- @return service table, but it will have been modified, might also throw an error
-- @see devicefactory.createservice
-- @see upnp.classes.action:execute
-- @see upnp.classes.statevariable:beforeset
-- @see upnp.classes.statevariable:afterset
-- @example# -- example customtable for a 'urn:schemas-upnp-org:service:Dimming:1' service
-- local customtable = devicefactory.emptyservice()
-- -- remove a variable and an action
-- customtable.serviceStateTable.StepDelta = false
-- customtable.actionList.StepUp = false
-- -- implement the 'execute' method for an action
-- customtable.actionList.StepDown = { execute = function(self) 
--        print ("method being executed now!")
--      end } 
devicefactory.customizeservice = function(service, customtable)
  if customtable == nil then return service end
  if customtable.serviceStateTable and next(customtable.serviceStateTable) then
    for i,v in ipairs(service.serviceStateTable or {}) do
      local variable = customtable.serviceStateTable[v.name]
      if variable == false then 
        -- drop optional variable
        table.remove(service.serviceStateTable, i)
      elseif type(variable) == "table" then
        -- add methods
        v.beforeset = variable.beforeset or v.beforeset
        v.afterset = variable.afterset or v.afterset
      end
    end
  end
  if customtable.actionList and next(customtable.actionList) then
    for i,v in ipairs(service.actionList or {}) do
      local action = customtable.actionList[v.name]
      if action == false then 
        -- drop optional action
        table.remove(service.actionList, i)
      elseif type(variable) == "table" then
        -- add method
        v.execute = variable.execute or v.execute
      end
    end
  end
  return service
end

--------------------------------------------------------------------------------------
-- Customizes a device by dropping optional elements (statevariables and/or actions) and
-- adding the implementation functions/methods. 
-- Includes any underlying services and sub-devices. On device level you can set
-- device properties like <code>friendlyName</code>, etc. A service can be dropped by including an 
-- element with its <code>serviceId</code>, set to <code>false</code>. A device can be dropped by including an
-- element with its <code>deviceType</code>, set to <code>false</code>. The <code>start()</code> and <code>stop()</code>
-- methods on device level can also be provided.
-- For implementing code for statevariables
-- and actions, see <code>devicefactory.customizeservice</code>
-- <br/>NOTE: the subdevices are indexed by <code>deviceType</code> in the customtable
-- hence if a device contains 2 sub-devices of the same type, things might go berserk!
-- @see upnp.classes.device:start
-- @see upnp.classes.device:stop
-- @return device table, but it will have been modified, might also throw an error
-- @param device the device table where elements need to be dropped from (typically
-- this is the table returned from <code>devicefactory.createdevice()</code>).
-- @param customtable a table containing the elements to drop by <code>serviceId</code> (for services)
-- or <code>deviceType</code> (for devices), with value <code>false</code>.
-- @see devicefactory.createdevice
-- @example# -- example customtable for a 'urn:schemas-upnp-org:device:DimmableLight:1' device
-- local customtable = devicefactory.emptydevice()
-- -- customize device level first
-- customtable.friendlyName = "This is my new UPnP device"
-- customtable.start = function(self)
--       self:superclass().start(self)
--       print("myDevice is now starting...")
--     end) 
-- customtable.stop = function(self)
--       print("myDevice is now stopped")
--       self:superclass().stop(self)
--     end) 
--
-- -- prepare a service to be customized
-- customtable.serviceList["urn:upnp-org:serviceId:Dimming:1"] = devicefactory.emptyservice()
-- -- remove a variable and an action
-- customtable.serviceList["urn:upnp-org:serviceId:Dimming:1"].serviceStateTable.StepDelta = false
-- customtable.serviceList["urn:upnp-org:serviceId:Dimming:1"].actionList.StepUp = false
-- -- implement the 'execute' method for an action
-- customtable.serviceList["urn:upnp-org:serviceId:Dimming:1"].actionList.StepDown = { execute = function(self) 
--        print ("method being executed now!")
--     end } 
-- 
-- -- go create a dimmable light and then customize it
-- local myDevTable = devicefactory.customizedevice(devicefactory.createdevice("schemas.upnp.org", "DimmableLight", "1") , customtable)
devicefactory.customizedevice = function(device, customtable)
  if customtable == nil then return device end
  for k,v in pairs(device) do
    if customtable[k] == false then
      device[k] = nil
    elseif (type(v) == "string" or type(v) == "nil") and type(customtable[k]) == "string"  then
      device[k] = customtable[k]
    end
  end
  if type(customtable.start) == "function" then device.start = customtable.start end
  if type(customtable.stop) == "function" then device.stop = customtable.stop end
  if customtable.serviceList and next(customtable.serviceList) then
    for i,v in ipairs(device.serviceList or {}) do
      if customtable.serviceList[v.serviceId] == false then 
        table.remove(device.serviceList, i)
      else
        devicefactory.customizeservice(v, customtable.serviceList[v.serviceId])
      end
    end
  end
  if customtable.deviceList and next(customtable.deviceList) then
    for i,v in ipairs(device.deviceList or {}) do
      if customtable.deviceList[v.deviceType] == false then 
        table.remove(device.deviceList, i)
      else
        devicefactory.customizedevice(v, customtable.deviceList[v.deviceType])
      end
    end
  end
  return device
end

--------------------------------------------------------------------------------------
-- Creates a standard device, customizes it, generates xml's, parses them and returns the UPnP device object.
-- @param domain domainname of the type to create, alternatively, the full <code>deviceType</code> contents
-- @param devicetype name of the type to create, or nil if the domain contains the full type identifier
-- @param version version number of the type to create, or nil if the domain contains the full type identifier
-- @param customtable table with customizations (see <code>devicefactory.customizedevice()</code>)
-- @return device a <code>upnp.classes.device</code> object representing the device, or <code>nil + errormsg</code>
devicefactory.builddevice = function(domain, devicetype, version, customtable)
  local devtable, xmllist, device, err, err2, success
  
  -- create device table for the standardized device
  success, devtable, err = pcall(devicefactory.createdevice, domain, servicetype, version)
  if not success then return nil, devtable end -- pcall; devtable holds error
  if dev == nil then return nil, err end -- contained error (nil + errmsg)
  
  -- customize the standard device
  success, devtable, err = pcall(devicefactory.customizedevice, devtable, customtable)
  if not success then return nil, devtable end -- pcall; devtable holds error
  if devtable == nil then return nil, err end -- contained error (nil + errmsg)

  -- generate xml list
  success, xmllist, err = pcall(xmlfactory.rootxml, devtable)
  if not success then return nil, xmllist end -- pcall; xmllist holds error
  if xmllist == nil then return nil, err end -- contained error (nil + errmsg)
    
  -- write webserver files
  success, err, err2 = xmlfactory.writetoweb(xmllist)
  if not success then return nil, err end -- pcall; err holds error
  if err2 ~= nil then return nil, err2 end -- contained error (nil + errmsg)

  -- creator function
  local creator = function(plist, classname, parent)
    to be done
  end
  
  -- parse xml into an object structure representing the device
  success, device, err = pcall(upnp.classes.device.parsefromxml, upnp.classes.device, xmllist[1], creator, nil)
  if not success then return nil, device end -- pcall; device holds error
  if device == nil then return nil, err end -- contained error (nil + errmsg)
  
  -- set xml location in device (required by upnp.startdevice()) and return the device
  device.devicexmlurl = xmllist[1]
  return device
end

return devicefactory