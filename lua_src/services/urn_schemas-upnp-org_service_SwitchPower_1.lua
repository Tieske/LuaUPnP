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
    
    -------------------------------------------------------------
    --  ACTION LIST IMPLEMENTATION
    -------------------------------------------------------------
    actionList = {
      { name = "SetTarget",
        argumentList = {
          { name = "newTargetValue", 
            relatedStateVariable = "Target", 
            direction = "in",
          },
        },
      },
      { name = "GetTarget",
        argumentList = {
          { name = "RetTargetValue",
            relatedStateVariable = "Target",
            direction = "out",
          },
        },
      },
      { name = "GetStatus",
        argumentList = {
          { name = "ResultStatus",
            relatedStateVariable = "Status",
            direction = "out",
          },
        },
      },
    },
    -------------------------------------------------------------
    --  STATEVARIABLE IMPLEMENTATION
    -------------------------------------------------------------
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
    -------------------------------------------------------------
    --  CUSTOM IMPLEMENTATION
    -------------------------------------------------------------
    customList = {
      -- all elements here are copied into the final object
      -- by devicefactory.builddevice()
    },
  }
end

return newservice