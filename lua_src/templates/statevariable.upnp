<% if statevariable.sendEvents == false then %>
<stateVariable sendEvents="no">
<% else %>
<stateVariable sendEvents="yes">
<% end %>
  <name><%=statevariable.name %></name>
  <dataType><%=statevariable.dataType %></dataType>
  <defaultValue><%=statevariable.defaultValue %></defaultValue>
  <% if #(statevariable.allowedValueList or {}) > 0 then %><allowedValueList>
    <% for i, value in ipairs(statevariable.allowedValueList) do %>
      <allowedValue><%=value %></allowedValue>
    <% end %>
  </allowedValueList><% else %>
  <% if statevariable.allowedValueRange then %><allowedValueRange>
    <minimum><%=statevariable.allowedValueRange.minimum %></minimum>
    <maximum><%=statevariable.allowedValueRange.maximum %></maximum>
    <% if statevariable.allowedValueRange.step then %>
      <step><%=statevariable.allowedValueRange.step %></step>
    <% end %>
  </allowedValueRange><% end %>
  <% end %>
</stateVariable>
