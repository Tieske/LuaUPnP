<?xml version="1.0"?>
<scpd xmlns="urn:schemas-upnp-org:service-1-0">
	<specVersion>
		<major>1</major>
		<minor>0</minor>
	</specVersion>
	<% if #(service.actionList or {}) > 0 then %><actionList>
    <% for i, action in ipairs(service.actionList) do %>
      <%=lp.includemodule("upnp.templates.action", {action = action}) %>
    <% end %>
	</actionList><% end %>
	<serviceStateTable> <% --[[ at least 1 statevar is required for a service! ]] %>
    <% for i, statevar in ipairs(service.serviceStateTable) do %>
      <%=lp.includemodule("upnp.templates.statevariable", {statevariable = statevar}) %>
    <% end %>
	</serviceStateTable>
</scpd>
