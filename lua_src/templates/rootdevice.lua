<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
	<specVersion>
		<major>1</major>
		<minor>0</minor>
	</specVersion>
	<% --[[ <URLBase>base URL for all relative URLs</URLBase> Not used, deprecated in later versions ]] %>
  <%=lp.includemodule("upnp.templates.device", {device = device}) %>
</root>