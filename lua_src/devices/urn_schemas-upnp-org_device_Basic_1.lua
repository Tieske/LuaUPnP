
local export = {}

export.newdevice = function()
  return {
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
  }
end

return export