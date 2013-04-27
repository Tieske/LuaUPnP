package = "luaupnp"
version = "0.1-1"
source = {
   url = "to be filled",
}
description = {
   summary = "Universal Plug and Play (UPnP) Lua binding for the pupnp library",
   detailed = [[
      LuaUPnP is a glue library between Lua and the pupnp library. It provides
      a simple way to create UPnP devices or controlpoints using the Lua
      scripting language.
   ]],
   homepage = "https://github.com/Tieske/LuaUPnP",
   license = "unknown"
}
dependencies = {
   "lua >= 5.1, < 5.2",
   "luafilesystem = 1.6.2",
   "darksidesync >= 0.1",
   "copas >= 1.1.6",
   "lualogging >= 1.3",
   "loop",
   "coxpcall >= 1.13",
   "date >= 2.0.1",
}
build = {
  type = "builtin",
  platforms = {
    unix = {
      modules = {
        ["upnp.core"] = {
          sources = {
            "lib_src/luaIXML.c",
            "lib_src/luaIXMLdocument.c",
            "lib_src/luaIXMLelement.c",
            "lib_src/luaIXMLnode.c",
            "lib_src/luaIXMLsupport.c",
            "lib_src/luaUPnP.c",
            "lib_src/luaUPnPcallback.c",
            "lib_src/luaUPnPsupport.c",
            "dss/darksidesync_aux.c",
          },
          incdirs = {
            "lib_src",
            "dss",
            "/usr/local/include/upnp",
          },
          libraries = {
            "upnp",
            "ixml",
          },
          defines = {
            "IXML_HAS_SCRIPTSUPPORT",
          }
        }
      }
    },
    win32 = {
      modules = {
        ["upnp.core"] = {
          sources = {
            "lib_src/luaIXML.c",
            "lib_src/luaIXMLdocument.c",
            "lib_src/luaIXMLelement.c",
            "lib_src/luaIXMLnode.c",
            "lib_src/luaIXMLsupport.c",
            "lib_src/luaUPnP.c",
            "lib_src/luaUPnPcallback.c",
            "lib_src/luaUPnPsupport.c",
            "dss/darksidesync_aux.c",
          },
          incdirs = {
            "lib_src",
            "dss",
            "../pupnp/ixml/inc",
            "../pupnp/upnp/inc",
            "../pupnp/upnp/src/inc",
            "../pupnp/threadutil/inc",
          },
          libraries = {
            --"wsock32"
          },
          defines = {
            "IXML_HAS_SCRIPTSUPPORT",
          }

        }
      }
    }
  },
  modules = {
    ["upnp.devicefactory"] = "lua_src/devicefactory.lua",
    ["upnp.init"]          = "lua_src/init.lua",
    ["upnp.lp"]            = "lua_src/lp.lua",
    ["upnp.xmlfactory"]    = "lua_src/xmlfactory.lua",
    ["upnp.classes.action"]        = "lua_src/classes/action.lua",
    ["upnp.classes.argument"]      = "lua_src/classes/argument.lua",
    ["upnp.classes.device"]        = "lua_src/classes/device.lua",
    ["upnp.classes.service"]       = "lua_src/classes/service.lua",
    ["upnp.classes.statevariable"] = "lua_src/classes/statevariable.lua",
    ["upnp.classes.upnpbase"]      = "lua_src/classes/upnpbase.lua",
    ["upnp.devices.urn_schemas-upnp-org_device_Basic_1"]         = "lua_src/devices/urn_schemas-upnp-org_device_Basic_1.lua",
    ["upnp.devices.urn_schemas-upnp-org_device_BinaryLight_1"]   = "lua_src/devices/urn_schemas-upnp-org_device_BinaryLight_1.lua",
    ["upnp.devices.urn_schemas-upnp-org_device_DimmableLight_1"] = "lua_src/devices/urn_schemas-upnp-org_device_DimmableLight_1.lua",
    ["upnp.services.urn_schemas-upnp-org_service_Dimming_1"]     = "lua_src/services/urn_schemas-upnp-org_service_Dimming_1.lua",
    ["upnp.services.urn_schemas-upnp-org_service_SwitchPower_1"] = "lua_src/services/urn_schemas-upnp-org_service_SwitchPower_1.lua",
    ["upnp.templates.action"]        = "lua_src/templates/action.lua",
    ["upnp.templates.device"]        = "lua_src/templates/device.lua",
    ["upnp.templates.rootdevice"]    = "lua_src/templates/rootdevice.lua",
    ["upnp.templates.service"]       = "lua_src/templates/service.lua",
    ["upnp.templates.statevariable"] = "lua_src/templates/statevariable.lua",
  },
--  copy_directories = { "doc", "samples", "etc", "test" }
}
