
local export = {}

export.newservice = function()
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

return export