<action>
  <name><%=action.name %></name>
  <% if #(action.argumentList or {}) > 0 then %><argumentList>
    <% for i, argument in ipairs(action.argumentList) do %>
    <argument>
      <name><%=argument.name %></name>
      <direction><%=argument.direction %></direction>
      <% if argument.retval then %><retval /><% end %>
      <relatedStateVariable><%=argument.relatedStateVariable %></relatedStateVariable>
    </argument><% end %>
  </argumentList><% end %>
</action>
