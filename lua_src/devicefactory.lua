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

-- list of elements NOT to copy when building a service
local servicedonotcopy = { 
  SCPDURL = 1, 
  controlURL = 1,
  eventSubURL = 1,
  serviceId = 1,
  serviceType = 1,
  actionList = 1,
  serviceStateTable = 1,
}
-- list of elements NOT to copy when building a device
local devicedonotcopy = {
  deviceType = 1,
  friendlyName = 1,
  manufacturer = 1,
  manufacturerURL = 1,
  modelDescription = 1,
  modelName = 1,
  modelNumber = 1,
  modelURL = 1,
  serialNumber = 1,
  UDN = 1,
  UPC = 1,
  iconList = 1,
  deviceList = 1,
  serviceList = 1,
  presentationURL = 1,
}

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
      logger:error("devicefactory.typecheck: %s", err)
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
-- @return new table with two empty subtables; <code>actionList</code> and <code>serviceStateTable</code>.
devicefactory.emptyservice = function()
  return { actionList = {}, serviceStateTable = {} }
end

--------------------------------------------------------------------------------------
-- Creates an empty device table.
-- @return new table with two empty subtables; <code>serviceList</code> and <code>deviceList</code>.
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
-- local customtable = {
--     serviceStateTable = {
--         StepDelta = false,  -- remove this variable
--     },
--     actionList = {
--         StepUp = false,     -- remove this action
--         StepDown = {        -- implement the action behaviour
--           execute = function(self, params) 
--             print ("method being executed now!")
--           end,
--         },
--     },
-- }
devicefactory.customizeservice = function(service, customtable)
  if customtable == nil then return service end
  if customtable.customList then
    service.customList = service.customList or {}
    for k,v in pairs(customtable.customList) do
      logger:debug("devicefactory.customizeservice: customList found, now copying '%s' = %s", tostring(k), tostring(v))
      service.customList[k] = v
    end
  end
  if customtable.serviceStateTable and next(customtable.serviceStateTable) then
    for i,v in ipairs(service.serviceStateTable or {}) do
      local variable = customtable.serviceStateTable[v.name]
      if variable == nil then
        logger:debug("devicefactory.customizeservice: statevariable '%s' not found in customtable", tostring(v.name))
      elseif variable == false then 
        -- drop optional variable
        table.remove(service.serviceStateTable, i)
        logger:debug("devicefactory.customizeservice: dropping statevariable '%s'", tostring(v.name))
      elseif type(variable) == "table" then
        -- add methods
        if variable.beforeset then
          logger:debug("devicefactory.customizeservice: adding statevariable '%s:beforeset' implementation", v.name)
          v.beforeset = variable.beforeset or v.beforeset
        end
        if variable.afterset then
          logger:debug("devicefactory.customizeservice: adding statevariable '%s:afterset' implementation", v.name)
          v.afterset = variable.afterset or v.afterset
        end
      end
    end
  end
  if customtable.actionList and next(customtable.actionList) then
    for i,v in ipairs(service.actionList or {}) do
      local action = customtable.actionList[v.name]
      if action == nil then
        logger:debug("devicefactory.customizeservice: action '%s' not found in customtable", tostring(v.name))
      elseif action == false then 
        -- drop optional action
        table.remove(service.actionList, i)
        logger:debug("devicefactory.customizeservice: dropping action '%s'", tostring(v.name))
      elseif type(action) == "table" then
        -- add method
        if action.execute then
          logger:debug("devicefactory.customizeservice: adding action '%s:execute' implementation", v.name)
          v.execute = action.execute or v.execute
        end
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
-- local customtable = {
--     -- customize device level first
--     friendlyName = "This is my new UPnP device",
--     start = function(self)   -- implement startup behaviour
--       self:superclass().start(self)
--       print("myDevice is now starting...")
--     end,
--     stop = function(self)    -- implement device shutdown behaviour
--       print("myDevice is now stopped")
--       self:superclass().stop(self)
--     end,
--     -- customize services next
--     serviceList = {
--       ["urn:upnp-org:serviceId:Dimming:1"] = {
--         serviceStateTable = {
--           StepDelta = false,
--         },
--         actionList = {
--           StepUp = false,
--           StepDown = {
--             execute = function(self, params) 
--               print ("method being executed now!")
--             end,
--           },
--         },  -- actionList
--       },  -- dimming service
--     },  -- serviceList
--   },  -- customtable
--
-- -- go create a dimmable light and then customize it
-- local myDevTable = devicefactory.customizedevice(devicefactory.createdevice("schemas.upnp.org", "DimmableLight", "1") , customtable)
devicefactory.customizedevice = function(device, customtable)
  if customtable == nil then return device end
  for k,v in pairs(device) do
    if customtable[k] == false then
      device[k] = nil
      logger:debug("devicefactory.customizedevice: dropping device property '%s'", tostring(k))
    elseif (type(v) == "string" or type(v) == "nil") and type(customtable[k]) == "string"  then
      device[k] = customtable[k]
      logger:debug("devicefactory.customizedevice: setting '%s' to '%s'", tostring(k), tostring(device[k]))
    end
  end
  if type(customtable.start) == "function" then 
    device.start = customtable.start
    logger:debug("devicefactory.customizedevice: adding 'start' implementation")
  end
  if type(customtable.stop) == "function" then 
    device.stop = customtable.stop
    logger:debug("devicefactory.customizedevice: adding 'stop' implementation")
  end
  if customtable.customList then
    device.customList = device.customList or {}
    for k,v in pairs(customtable.customList) do
      logger:debug("devicefactory.customizedevice: customList found, now copying '%s' = %s", tostring(k), tostring(v))
      device.customList[k] = v
    end
  end
  if customtable.serviceList and next(customtable.serviceList) then
    for i,v in ipairs(device.serviceList or {}) do
      local service = customtable.serviceList[v.serviceId]
      if service == nil then
        logger:debug("devicefactory.customizedevice: service '%s' not found in customtable", tostring(v.serviceId))
      elseif service == false then 
        table.remove(device.serviceList, i)
        logger:debug("devicefactory.customizedevice: dropping service '%s'", tostring(v.serviceId))
      else
        logger:debug("devicefactory.customizedevice: customizing service '%s'", tostring(v.serviceId))
        devicefactory.customizeservice(v, service)
      end
    end
  end
  if customtable.deviceList and next(customtable.deviceList) then
    for i,v in ipairs(device.deviceList or {}) do
      local subdev = customtable.deviceList[v.deviceType]
      if subdev == nil then
        logger:debug("devicefactory.customizedevice: subdevice '%s' not found in customtable", tostring(v.deviceType))
      elseif subdev == false then 
        table.remove(device.deviceList, i)
        logger:debug("devicefactory.customizedevice: dropping subdevice '%s'", tostring(v.deviceType))
      else
        logger:debug("devicefactory.customizedevice: customizing subdevice '%s'", tostring(v.deviceType))
        devicefactory.customizedevice(v, subdev)
      end
    end
  end
  return device
end

--------------------------------------------------------------------------------------
-- Creates a standard device, customizes it, generates xml's, parses them and returns the UPnP device object.
-- This method takes a number of steps to create a fully functional device;</p>
-- <ol>
-- <li>Creates a device table for a standard device (<code>devicefactory.createdevice()</code>)</li>
-- <li>Drops optionals as set in the <code>customtable</code> parameter (<code>devicefactory.customizedevice()</code>)
-- and adds the implementations of device/variable/action methods from the <code>customtable</code> to the device table</li>
-- <li>Creates the XML's for the device and its services (<code>xmlfactory.rootxml()</code>)</li>
-- <li>Writes the XML's to the webroot directory, so they are accessible (<code>xmlfactory.writetoweb()</code>)</li>
-- <li>Parses the XML's into a root-device object structure, whilst adding the custom implementations as set in the devicetable (<code>upnp.classes.device:parsefromxml()</code>)</li>
-- <li>sets the <code>devicexmlurl</code> on the device and returns the device object</li>
-- <ol><p>
-- @see devicefactory.createdevice
-- @see devicefactory.customizedevice
-- @see xmlfactory.rootxml
-- @see xmlfactory.writetoweb
-- @see upnp.classes.device:parsefromxml
-- @param domain domainname of the type to create, alternatively, the full <code>deviceType</code> contents. In the latter case the <code>devicetype</code> and <code>version</code> arguments can be omitted.
-- @param devicetype [optional] name of the type to create, or nil if the domain contains the full type identifier
-- @param version [optional] version number of the type to create, or nil if the domain contains the full type identifier
-- @param customtable [optional] table with customizations (see <code>devicefactory.customizedevice()</code>)
-- @return device a <code>upnp.classes.device</code> object representing the device, or <code>nil + errormsg</code>
-- @example# -- two ways to create the same device, both without customization/implementation
-- devicefactory.builddevice("schemas.upnp.org", "BinaryLight", "1", {} )
--   -- or full schema and no customtable
-- devicefactory.builddevice("urn:schemas-upnp-org:device:BinaryLight:1")
devicefactory.builddevice = function(domain, devicetype, version, customtable)
  local devtable, xmllist, device, err, err2, success, devicepath
  
  if type(devicetype) ~= "string" and customtable == nil then
    -- the optionals not provided, reshuffle arguments
    customtable = devicetype
    devicetype = nil
  end
  customtable = customtable or {}
  
  -- create device table for the standardized device
  logger:debug("devicefactory.builddevice; creating device table %s, %s, %s", tostring(domain), tostring(devicetype or ""), tostring(version or ""))
  success, devtable, err = pcall(devicefactory.createdevice, domain, servicetype, version)
  if not success then return nil, devtable end -- pcall; devtable holds error
  if devtable == nil then return nil, err end -- contained error (nil + errmsg)
  
  -- customize the standard device
  logger:debug("devicefactory.builddevice; device table created, now start customizing")
  success, devtable, err = pcall(devicefactory.customizedevice, devtable, customtable)
  if not success then return nil, devtable end -- pcall; devtable holds error
  if devtable == nil then return nil, err end -- contained error (nil + errmsg)

  -- generate xml list
  logger:debug("devicefactory.builddevice; device table customized, now start generating xmls")
  success, xmllist, err = pcall(xmlfactory.rootxml, devtable)
  if not success then return nil, xmllist end -- pcall; xmllist holds error
  if xmllist == nil then return nil, err end -- contained error (nil + errmsg)
  
  -- write webserver files
  logger:debug("devicefactory.builddevice; xmls created, now writing them to webroot folder")
  success, err, err2 = pcall(xmlfactory.writetoweb, xmllist)
  if not success then return nil, err end -- pcall; err holds error
  if err2 ~= nil then return nil, err2 end -- contained error (nil + errmsg)
  
  -- creator function
  local creations = {} -- created objects, index by themselves, value is sub-table of devtable
  local creator = function(plist, classname, parent)
    -- plist = object properties, indexed by lowercase (!!!) names
    -- classname = "device", "service", "statevariable", "action", "argument", "servicexml"
    -- parent is the parent object, or nil for a root device
    logger:debug("devicefactory.builddevice; creator: class requested = %s", tostring(classname))
    if classname == "servicexml" then
      -- the device.parsefromxml() parser will automatically fallback to the SCPDURL 
      -- property listed in the device description if nothing is returned, next call 
      -- here if for actually creating the service object, and thats when we will 
      -- customize it.
      -- Only prepend path to device directory to make sure it gets found
      return devicepath .. plist.scpdurl
    end
    
    local target = upnp.classes[classname](plist)
    local source
    if classname == "device" then
      if parent == nil then
        source = devtable  -- root device
      else
        -- lookup device in parent deviceList
        for _, dev in pairs(creations[parent].deviceList) do
          if dev.UDN and dev.UDN == plist.udn then
            source = dev
            break
          end
        end
        assert(source, "devicefactory.builddevice[creator]; unkown device: UDN = " .. tostring(plist.udn))
      end
      logger:debug("devicefactory.builddevice; creator: created device with UDN = %s", tostring(plist.udn))
      -- implement/customize device methods
      target.start = source.start or target.start
      target.stop = source.stop or target.stop
      for k,v in pairs(source.customList) do
        target[k] = v
      end
    
    elseif classname == "service" then
      for _, serv in pairs(creations[parent].serviceList) do
        if serv.serviceId == plist.serviceid then
          source = serv
          break
        end
      end
      assert(source, "devicefactory.builddevice[creator]; unkown service: serviceId = " .. tostring(plist.serviceid))
      logger:debug("devicefactory.builddevice; creator: created service with serviceId = %s", tostring(plist.serviceid))
      -- implement/customize service methods
      for k,v in pairs(source.customList) do
        target[k] = v
      end
    
    elseif classname == "argument" then
      logger:debug("devicefactory.builddevice; creator: created argument named = %s", tostring(plist.name))
      -- has no custom methods, nor any child-objects, nothing to do here
    
    elseif classname == "statevariable" then
      -- lookup variable in parent serviceStateTable
      for _, var in pairs(creations[parent].serviceStateTable) do
        if var.name and var.name == plist.name then
          source = var
          break
        end
      end
      assert(source, "devicefactory.builddevice[creator]; unkown statevariable: " .. tostring(plist.name))
      logger:debug("devicefactory.builddevice; creator: created statevariable named = %s", tostring(plist.name))
      -- implement/customize statevariable methods
      target.beforeset = source.beforeset or target.beforeset
      target.afterset = source.afterset or target.afterset
      
    elseif classname == "action" then
      -- lookup action in parent actionList
      for _, act in pairs(creations[parent].actionList) do
        if act.name and act.name == plist.name then
          source = act
          break
        end
      end
      assert(source, "devicefactory.builddevice[creator]; unkown action: " .. tostring(plist.name))
      logger:debug("devicefactory.builddevice; creator: created action named = %s", tostring(plist.name))
      -- implement/customize action methods
      target.execute = source.execute or target.execute
    
    else
      error("devicefactory.builddevice[creator]; unkown classname: " .. tostring(classname))
    end
    
    -- store results and return created object
    creations[target] = source
    return target
  end
  
  -- parse xml into an object structure representing the device
  logger:debug("devicefactory.builddevice; parsing xmls into device objects")
  devicepath = xmllist[1]:gsub("device.xml", "")
  success, device, err = pcall(upnp.classes.device.parsefromxml, upnp.classes.device, xmllist[1], creator, nil)
  if not success then return nil, device end -- pcall; device holds error
  if device == nil then return nil, err end -- contained error (nil + errmsg)
  
  -- set xml location in device (required by upnp.startdevice()) and return the device
  logger:debug("devicefactory.builddevice; device created")
  device.devicexmlurl = xmllist[1]
  return device
end

return devicefactory