---------------------------------------------------------------------------
-- Standard service; urn:schemas-upnp-org:SwitchPower:1.
-- Requires to implement the following elements;
-- </p>
-- <ul>
-- <li><code>service.serviceStateTable.Target.afterset = function(self, oldval) ... end</code> to process the changed Target value</li>
-- </ul>
-- <p>
-- @class module
-- @name urn_schemas-upnp-org_service_SwitchPower_1

local newservice = function()
  return {
    serviceType = "urn:schemas-upnp-org:service:SwitchPower:1",
    actionList = {
      { name = "SetTarget",
        argumentList = {
          { name = "newTargetValue", 
            relatedStateVariable = "Target", 
            direction = "in",
          },
        },
        execute = upnp.classes.action.genericsetter,
      },
      { name = "GetTarget",
        argumentList = {
          { name = "RetTargetValue",
            relatedStateVariable = "Target",
            direction = "out",
          },
        },
        execute = upnp.classes.action.genericgetter,
      },
      { name = "GetStatus",
        argumentList = {
          { name = "ResultStatus",
            relatedStateVariable = "Status",
            direction = "out",
          },
        },
        execute = upnp.classes.action.genericgetter,
      },
    },
    serviceStateTable = {
      { name = "Target",
        sendEvents = false,
        dataType = "boolean",
        defaultValue = "0",
      },
      { name = "Status",
        sendEvents = true,
        dataType = "boolean",
        defaultValue = "0",
      },
    },
  }
end

return newservice