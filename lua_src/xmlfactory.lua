-----------------------------------------------------------------------------
-- xml factory.
-- This module has methods for creating service xmls and device xmls from
-- Lua tables.
-- @class module
-- @name upnp.xmlfactory

local lp = require("upnp.lp")
local upnp = require("upnp")
local logger = upnp.logger
local xmlfactory = {}

-----------------------------------------------------------------------------
-- Compiles and runs a module template. In case of error, it will be logged
-- @param template the modulename of the template to use
-- @param env the environment table to use
-- @return string containing xml or nil + error 
local runtemplate = function(template, env)
  logger:debug("xmlfactory: running template '%s'", template)
  local success, result = pcall(lp.includemodule, template, env)
  if not success then
    logger:error("xmlfactory: Failed running template '%s', with error '%s' and this content:", template, tostring(result))
    logger:error(env)
    return nil, result
  end
  logger:debug("xmlfactory: template completed succesfully")
  return result
end

-----------------------------------------------------------------------------
-- Creates a service xml, using the template engine
-- @param service table with service parameters for the service xml to create
-- @example# -- service table example
-- local service = {
--   -- these two elements are not required for the service xml, but allow
--   -- the same table to be used when creating a rootdevice xml
--   serviceType = "urn:schemas-upnp-org:service:SwitchPower:1",
--   serviceId = "urn:upnp-org:serviceId:myPowerSwitch",
--   -- serviceId does not need to be unique, trailing numbering will 
--   -- automatically be added if needed.
--   -- the SCPDURL, controlURL & eventSubURL will be set automatically
--
--   -- The lists below are used for the service, every element named 
--   -- after its xml counterpart
--   actionList = {
--     { name = "switch",
--       argumentList = {
--         {
--           name = "firstVal",
--           direction = "in",
--           relatedStateVariable = "firstVariable",
--         },
--         {
--           name = "outVal",
--           retval = true,
--           direction = "out",
--           relatedStateVariable = "firstVariable",
--         },
--       },
--     },
--   },
--   serviceStateTable = {
--     { name = "firstVal",
--       evented = true,
--       dataType = "number",
--       defaultValue = "0",
--       allowedValueRange = {
--         minimum = 0,
--         maximum = 100,
--         step = 10,
--       },
--     },
--     { name = "secondVal",
--       evented = true,
--       dataType = "string",
--       defaultValue = "something",
--       allowedValueList = { "something", "anything", "someone", "anyone" },
--     },
--   },
-- }
-- 
-- local xml = upnp.xmlfactory.servicexml(service)
xmlfactory.servicexml = function(service)
  return runtemplate("upnp.templates.service", service)
end

------------------------------------------------------
-- Creates xml files for a root device, using the template engine. The filenames generated are
-- relative, so they should be placed relative to the webroot directory used.
-- <br/>NOTE: serviceId values will be updated with a trailing number if they are not unique within a device
-- <br/>NOTE: SCPDURL value for services will be set to the generated filenames
-- @param rootdev the table with the rootdevice properties, its <code>serviceList</code> property should contain a list with all services defined as shown in the example code of <code>xmlfactory.servicexml()</code>.
-- @return xml string containing the device xml
-- @return table with 2 parts; array part is a list of filenames for the xmls (element 1 is the device xml filename), the hash part will hold the actual xml documents, indexed by their filenames.
xmlfactory.rootxml = function(rootdev)
  local servicelist
  local xml
  local rootpath

  -- Creates and logs a new uuid
  local createUUID = function()
    local uuid = "uuid:" .. upnp.lib.util.createUUID()
    logger:info("created new id; %s", uuid)
    return uuid
  end
  
  -- add service xml to servicelist, undoubles if necessary
  -- @param service table containg the service
  -- @param xml string with xml description of service
  -- @return filename for the service xml for constructing the URL
  local function storeservice(service, xml)
    local name
    for _, filename in ipairs(servicelist or {}) do
      if servicelist[filename] == xml then
        -- this is the same xml
        name = filename
      end
    end
    if not name then
      -- xml wasn't found, so its unique so far, create name and store
      name = service.serviceId:gsub("%:","-")
      local cnt = 1
      while servicelist[rootpath .. name .. "-" .. tostring(cnt) .. ".xml"] do cnt = cnt + 1 end
      name = rootpath .. name .. "-" .. tostring(cnt) .. ".xml"
      servicelist[name] = xml
    end
    table.insert(servicelist, name)
    return name
  end
  
  -- make all serviceId properties unique by adding '-' + number if required
  -- generates xml's and sets SCPDURL element in the service table
  local function processServices(services)
    local list = {}
    for _, service in ipairs(services) do
      -- make serviceId unique
      local cnt = 1
      local id = service.serviceId  -- original
      while list[service.serviceId] do
        cnt = cnt + 1
        service.serviceId = id .. "-" .. tostring(cnt)
      end
      -- generate xml and add it to the files list
      local sxml = xmlfactory.servicexml(service)
      service.SCPDURL = storeservice(service, sxml)
    end
  end
  
  -- traverse all sub devices
  -- creates UUID if not present
  local function processDevice(device)
    device.UDN = device.UDN or createUUID()
    if device.serviceList then processServices(device.serviceList) end
    if device.deviceList then
      -- recurse sub devices
      for _, dev in ipairs(device.deviceList) do processDevice(dev) end
    end
  end
  
  -- get rootUDN, create if necessary
  rootdev.UDN = rootdev.UDN or createUUID()
  rootpath = rootdev.UDN:gsub("%:","-") .. "/"
  
  -- check all devices/services, traverse hierarchy, then create xml
  processDevice(rootdev.device)
  xml = runtemplate("upnp.templates.rootdevice", rootdev)
  
  -- store as nr 1 in list
  rootpath = rootpath .. "device.xml"  -- root dev is always called 'device.xml'
  table.insert(servicelist,1,rootpath)
  servicelist[rootpath] = xml

  return servicelist
end

return xmlfactory
