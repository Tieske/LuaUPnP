-----------------------------------------------------------------------------
-- device factory.
-- This module has methods for creating services and devices from standard
-- elements (provided the required modules to support that device/service)
-- are available.
-- @class module
-- @name upnp.devicefactory


local upnp = require("upnp")
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


-- @param element table containing the data to use to create it
-- @param elemtype is either "device" or "service"
local creategeneric = function(element, domain, elemtype, typename, version)
  fulltype = typecheck(domain, elemtype, typename, version)
  if not fulltype then return nil, string.format("cannot create %s, typecheck failed", tostring(elemtype)) end
  
  local success, creator = pcall(require, "upnp."..elemtype.."."..fulltype:gsub("%:","_"):gsub("%.","_")
  if not success then
    return nil, string.format("cannot create '%s', no module found for it or error loading. ErrMsg: %s", tostring(devtype), tostring(creator))
  end
  
  return creator(element)
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
-- Creates the requested device (if available). The output can be used as input for the
-- <code>xmlfactory</code>.
-- For the parameters check the device property <code>deviceType</code> in the device xml of the
-- UPnP architecture documents.
-- @param device table with device data used to create it
-- @param domain domainname of the type to create, alternatively, the full <code>deviceType</code> contents
-- @param devicetype name of the type to create, or nil if the domain contains the full type identifier
-- @param version version number of the type to create, or nil if the domain contains the full type identifier
-- @return device table, or nil + errormsg
-- @example# device = {  -- put device table here
--     }
-- devicefactory.createdevice(device, "schemas.upnp.org", "BinaryLight", "1")
--   -- or
-- devicefactory.createdevice(device, "urn:schemas-upnp-org:device:BinaryLight:1")
devicefactory.createdevice = function(device, domain, devicetype, version)
  local results = { creategeneric(device, domain, "device", devicetype, version) }
  if not results[1] then
    logger:error("devicefactory.createdevice: " .. tostring(results[2]))
    return nil, results[2]
  end
  return unpack(results)
end

--------------------------------------------------------------------------------------
-- Creates the requested service (if available). The output can be used as input for the
-- <code>xmlfactory</code>. See <code>createdevice()</code> for more details.
-- @see devicefactory.createdevice
devicefactory.createservice = function(service, domain, servicetype, version)
  local results = { creategeneric(service, domain, "service", servicetype, version) }
  if not results[1] then
    logger:error("devicefactory.createservice: " .. tostring(results[2]))
    return nil, results[2]
  end
  return unpack(results)
end

return devicefactory