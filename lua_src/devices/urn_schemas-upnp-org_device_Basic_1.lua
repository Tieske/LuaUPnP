local logger = upnp.logger

local newdevice = function()
  logger:info("Creating a new 'urn:schemas-upnp-org:device:Basic:1' device")
  return {
    -------------------------------------------------------------
    --  DEVICE IMPLEMENTATION
    -------------------------------------------------------------
    UDN = upnp.lib.util.CreateUUID(),
		deviceType = "urn:schemas-upnp-org:device:Basic:1",
		friendlyName = "short user-friendly title",
		manufacturer = "manufacturer name",
		--[[<iconList>
			<icon>
				<mimetype>image/format</mimetype>
				<width>horizontal pixels</width>
				<height>vertical pixels</height>
				<depth>color depth</depth>
				<url>URL to icon</url>
			</icon>
		</iconList>
		--]]
		serviceList = {
    },
    deviceList = {
    },
    -- presentationURL = "",
    
    -------------------------------------------------------------
    --  CUSTOM IMPLEMENTATION
    -------------------------------------------------------------
    customList = {
      -- all elements here are copied into the final object
      -- by devicefactory.builddevice()
    },
  }
end

return newdevice