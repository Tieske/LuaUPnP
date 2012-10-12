-- Returns an IXML document node containing the xml below
return require("upnp").lib.ixml.ParseBuffer( [===[
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
	<specVersion>
		<major>1</major>
		<minor>0</minor>
	</specVersion>
	<URLBase>base URL for all relative URLs</URLBase>
	<device>
		<deviceType>urn:schemas-upnp-org:device:BinaryLight:1</deviceType>
		<friendlyName>short user-friendly title</friendlyName>
		<manufacturer>manufacturer name</manufacturer>
		<manufacturerURL>URL to manufacturer site</manufacturerURL>
		<modelDescription>long user-friendly title</modelDescription>
		<modelName>model name</modelName>
		<modelNumber>model number</modelNumber>
		<modelURL>URL to model site</modelURL>
		<serialNumber>manufacturer's serial number</serialNumber>
		<UDN>uuid:UUID</UDN>
		<UPC>Universal Product Code</UPC>
		<iconList>
			<icon>
				<mimetype>image/format</mimetype>
				<width>horizontal pixels</width>
				<height>vertical pixels</height>
				<depth>color depth</depth>
				<url>URL to icon</url>
			</icon>
			<!-- XML to declare other icons, if any, go here -->
		</iconList>
		<serviceList>
			<service>
				<serviceType>urn:schemas-upnp-org:service:SwitchPower:1</serviceType>
				<serviceId>urn:upnp-org:serviceId:SwitchPower:1</serviceId>
				<SCPDURL>URL to service description</SCPDURL>
				<controlURL>URL for control</controlURL>
				<eventSubURL>URL for eventing</eventSubURL>
			</service>
			<!-- Declarations for other services added by UPnP vendor (if any) go here -->
		</serviceList>
		<deviceList>
			<!-- Description of embedded devices added by UPnP vendor (if any) go here -->
		</deviceList>
		<presentationURL>URL for presentation</presentationURL>
	</device>
</root>
]===])