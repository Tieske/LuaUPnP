<device>
  <deviceType><%=(device.deviceType or "urn:schemas-upnp-org:device:Basic:1"):sub(1,63) %></deviceType>
  <friendlyName><%=(device.friendlyName or "short user-friendly title"):sub(1,63) %></friendlyName>
  <manufacturer><%=(device.manufacturer or "manufacturer name"):sub(1,63) %></manufacturer>
  <% if device.manufacturerURL then %><manufacturerURL><%=(device.manufacturerURL) %></manufacturerURL><% end %>
  <% if device.modelDescription then %><modelDescription><%=(device.modelDescription):sub(1,127) %></modelDescription><% end %>
  <modelName><%=(device.modelName or "model name"):sub(1,31) %></modelName>
  <% if device.modelNumber then %><modelNumber><%=(device.modelNumber):sub(1,31) %></modelNumber><% end %>
  <% if device.modelURL then %><modelURL><%=(device.modelURL) %></modelURL><% end %>
  <% if device.serialNumber then %><serialNumber><%=(device.serialNumber) %></serialNumber><% end %>
  <UDN><%=device.UDN %></UDN>
  <% if device.UPC then %><UPC><%=(device.UPC):sub(1,12) %></UPC><% end %>
  <% if #(device.iconList or {}) > 0 then %><iconList>
    <% for i, icon in ipairs(device.iconList) do %><icon>
      <mimetype><%= icon.mimeType %></mimetype>
      <width><%= tostring(icon.width) %></width>
      <height><%= tostring(icon.height) %></height>
      <depth><%= tostring(icon.depth) %></depth>
      <url><%= icon.url %></url>
    </icon><% end %>
    <!-- XML to declare other icons, if any, go here -->
  </iconList><% end %>
  <% if #(device.serviceList or {}) > 0 then %><serviceList>
    <% for i, service in ipairs(device.serviceList) do %><service>
      <serviceType><%= service.serviceType %></serviceType>
      <serviceId><%= service.serviceId %></serviceId>
      <SCPDURL><%= service.SCPDURL %></SCPDURL>
      <controlURL><%= service.controlURL %></controlURL>
      <eventSubURL><%= (service.eventSubURL or "") %></eventSubURL>
    </service><% end %>
    <!-- Declarations for other services added by UPnP vendor (if any) go here -->
  </serviceList><% end %>
  <% if #(device.deviceList or {}) > 0 then %><deviceList>
    <!-- Description of embedded devices added by UPnP vendor (if any) go here -->
    <% for i, subdevice in ipairs(device.deviceList) do %>
      <%=lp.includemodule("upnp.templates.device", {device = subdevice}) %>
    <% end %>
  </deviceList><% end %>
  <% if device.presentationURL then %><presentationURL><%=(device.presentationURL) %></presentationURL><% end %>
</device>
