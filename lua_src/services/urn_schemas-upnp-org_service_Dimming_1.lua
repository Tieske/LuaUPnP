
local newservice = function()
  return {
    serviceType = "urn:schemas-upnp-org:service:Dimming:1",
    
    -------------------------------------------------------------
    --  ACTION LIST IMPLEMENTATION
    -------------------------------------------------------------
    actionList = {
      { name = "SetLoadLevelTarget",
			  argumentList = {
					{ name = "newLoadlevelTarget",
					  direction = "in", 
					  relatedStateVariable = "LoadLevelTarget",
          },
				},
      },
			{ name = "GetLoadLevelTarget",
			  argumentList = {
          { name = "retLoadlevelTarget",
					  direction = "out", 
					  retval = true,
					  relatedStateVariable = "LoadLevelTarget",
          },
				},
      },
			{ name = "GetLoadLevelStatus",
			  argumentList = {
					{ name = "retLoadlevelStatus",
					  direction = "out",
					  retval = true,
					  relatedStateVariable = "LoadLevelStatus",
          },
				},
      },
      { name = "SetOnEffectLevel",
			  argumentList = {
          { name = "newOnEffectLevel",
					  direction = "in", 
					  relatedStateVariable = "OnEffectLevel",
          },
				},
			},
      { name = "SetOnEffect",
			  argumentList = {
			    { name = "newOnEffect",
            direction = "in",
            relatedStateVariable = "OnEffect",
          },
        },
      },
      { name = "GetOnEffectParameters", 
        argumentList = {
          { name = "retOnEffect",
            direction = "out",
            relatedStateVariable = "OnEffect",
          },
          { name = "retOnEffectLevel", 
            direction = "out",
            relatedStateVariable = "OnEffectLevel",
          },
        },
      },
      { name = "StepUp", 
        execute = function(self, params)
-- to be implemented          
        end,
      },
      { name = "StepDown", 
        execute = function(self, params)
-- to be implemented          
        end,
      },
      { name = "StartRampUp", 
        execute = function(self, params)
-- to be implemented          
        end,
      },
      { name = "StartRampDown", 
        execute = function(self, params)
-- to be implemented          
        end,
      },
      { name = "StopRamp", 
        execute = function(self, params)
-- to be implemented          
        end,
      },
      { name = "StartRampToLevel",
        argumentList = {
          { name = "newLoadLevelTarget",
            direction = "in",
            relatedStateVariable = "LoadLevelTarget",
          },
          { name = "newRampTime",
            direction = "in",
            relatedStateVariable = "RampTime",
          },
        },
        execute = function(self, params)
-- to be implemented          
        end,
      },
      { name = "SetStepDelta",
        argumentList = {
          { name = "newStepDelta",
            direction = "in",
            relatedStateVariable = "StepDelta",
          },
        },
      },
      { name = "GetStepDelta",
        argumentList = {
          { name = "retStepDelta",
            direction = "out",
            retval = true,
            relatedStateVariable = "StepDelta",
          },
        },
      },
      { name = "SetRampRate",
        argumentList = {
          { name = "newRampRate",
            direction = "in", 
            relatedStateVariable = "RampRate",
          },
        },
      },
      { name = "GetRampRate",
        argumentList = {
          { name = "retRampRate",
            direction = "out",
            retval = true,
            relatedStateVariable = "RampRate",
          },
        },
      },
      { name = "PauseRamp", 
        execute = function(self, params)
-- to be implemented          
        end,
      },
      { name = "ResumeRamp",
        execute = function(self, params)
-- to be implemented          
        end,
      },
      { name = "GetIsRamping",
        argumentList = {
          { name = "retIsRamping",
            direction = "out",
            retval = true,
            relatedStateVariable = "IsRamping",
          },
        },
      },
      { name = "GetRampPaused",
        argumentList = {
          { name = "retRampPaused",
            direction = "out",
            retval =  true,
            relatedStateVariable = "RampPaused",
          },
        },
      },
      { name = "GetRampTime",
        argumentList = {
          { name = "retRampTime",
            direction = "out",
            retval = true,
            relatedStateVariable = "RampTime",
          },
        },
      },
    },
    
    -------------------------------------------------------------
    --  STATEVARIABLE IMPLEMENTATION
    -------------------------------------------------------------
    serviceStateTable = {
      { name = "LoadLevelTarget",
        sendEvents = false,
        dataType = "ui1",
        defaultValue = "0",
        allowedValueRange = {
          minimum = "0",
          maximum = "100",
        },
        afterset = function(self, oldval)
-- to be implemented          
        end,
      },
      { name = "LoadLevelStatus",
        sendEvents = true,
        dataType = "ui1",
        defaultValue = "0",
        allowedValueRange = {
          minimum = "0",
          maximum = "100",
        },
      },
      { name = "OnEffectLevel",
        sendEvents = false,
        dataType = "ui1",
        defaultValue = "100",
        allowedValueRange = {
          minimum = "0",
          maximum = "100",
        },
      },
      { name = "OnEffect",
        sendEvents = false,
        dataType = "string",
        defaultValue = "Default",
        allowedValueList = { "OnEffectLevel", "LastSetting", "Default" },
      },
      { name = "StepDelta",
        sendEvents = true,
        dataType = "ui1",
        defaultValue = "20",
        allowedValueRange = {
          minimum = "1",
          maximum = "100",
        },
      },
      { name = "RampRate",
        sendEvents = true,
        dataType = "ui1",
        defaultValue = "0",
        allowedValueRange = {
          minimum = "0",
          maximum = "100",
        },
      },
      { name = "RampTime",
        sendEvents = false,
        dataType = "ui4",
        defaultValue = "0",
        allowedValueRange = {
          minimum = "0",
          maximum = "4294967295",
        },
      },
      { name = "IsRamping",
        sendEvents = true,
        dataType = "boolean",
        defaultValue = "0",
      },
      { name = "RampPaused",
        sendEvents = true,
        dataType = "boolean",
        defaultValue = "0",
      },
    },
  }
end

return newservice