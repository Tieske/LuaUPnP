-----------------------------------------------------------------
--  Test module, initialize here, main test function below
-----------------------------------------------------------------

local myxml = [[<?xml version="1.0" encoding="utf-8"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
   <specVersion>
      <major>1</major>
      <minor>0</minor>
   </specVersion>
   <device>
      <deviceType>urn:schemas-upnp-org:device:basic:1</deviceType>
      <presentationURL>WebLink/87ce90b5-8ce9-4743-a15a-6a28fa40feb5.html</presentationURL>
      <friendlyName>DD-WRT WLAN router</friendlyName>
      <manufacturer>Tieske</manufacturer>
      <manufacturerURL>http://www.thijsschreijer.nl</manufacturerURL>
      <modelDescription>Network based URL shortcut available to all users on the network (subnet)</modelDescription>
      <modelName>UPnP WebLink</modelName>
      <modelNumber />
      <modelURL>http://www.thijsschreijer.nl/</modelURL>
      <serialNumber />
      <UDN>uuid:87ce90b5-8ce9-4743-a15a-6a28fa40feb5</UDN>
      <iconList>
         <icon>
            <mimetype>image/png</mimetype>
            <width>32</width>
            <height>32</height>
            <depth>32</depth>
            <url>/icon.png</url>
         </icon>
         <icon>
            <mimetype>image/jpg</mimetype>
            <width>32</width>
            <height>32</height>
            <depth>32</depth>
            <url>/icon.jpg</url>
         </icon>
      </iconList>
   </device>
</root>
]]

local upnp = require("LuaUPnP")
local ixml = upnp.ixml


local function printtree(n, level)
	level = level or ""
	print(level .. tostring(n), n:getNodeName(), n:getNodeValue(), n:hasChildNodes())
	for node in n:children() do
		printtree(node, level .. "   ")
	end
end

-----------------------------------------------------------------
--  Test function, put main code here
-----------------------------------------------------------------

local test = function()
	print (myxml)
	print ("\n\nPress enter to continue...")
	io.read()

	print(type(myxml))
	local file = ixml.ParseBuffer(myxml)

	printtree(file)

end

-----------------------------------------------------------------
--  Generic test functionality to start and trace errors
-----------------------------------------------------------------


local errf = function(msg)
	print (debug.traceback(msg or "Stacktrace:"))
end

xpcall(test, errf)
print ("Press enter to exit...")
io.read()

