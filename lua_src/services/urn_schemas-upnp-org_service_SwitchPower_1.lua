---------------------------------------------------------------------------
-- Standard service; "urn:schemas-upnp-org:service:SwitchPower:1".
-- When required, it returns a single function which generates a new service table 
-- on every call (it takes no parameters). The <code>upnp.devicefactory</code> module 
-- takes the device/service tables to build device/service objects.
-- <br><br>Requires to implement the following elements;
-- </p>
-- <ul>
-- <li><code>service.serviceStateTable.Target.afterset = function(self, oldval) ... end</code> to process the changed Target value</li>
-- </ul>
-- <p>
-- @class module
-- @name urn_schemas-upnp-org_service_SwitchPower_1

local logger = upnp.logger

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
        ---------------------------------------------------------
        -- Implement this handler to add SwitchPower capability.
        -- The handler should implement the actual switch behaviour and set the
        -- 'Status' variable to the new value when done.
        -- @param self statevariable object for the 'Target' statevariable
        -- @param oldval the previous value of 'Target'
        -- @example# -- Create a new SwitchPower service
        -- local service = require("upnp.services.urn_schemas-upnp-org_service_SwitchPower_1")()
        -- <br>
        -- -- add implementation
        -- service.serviceStateTable[1].afterset = function(self, oldval)
        --     -- do something useful here...
        --     print("Setting the SwitchPower value to", self:get(), "from", oldval)
        -- <br>
        --     -- When done update value of Status to reflect the change
        --     self:getstatevariable("status"):set(self:get())
        -- end
        -- @see statevariable:afterset
        afterset = function(self, oldval)
        end,        
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