
local dimlevels = 15
local zeroisoff = true

local newservice = function()
  return {
    serviceType = "urn:schemas-upnp-org:service:Dimming:1",
    
    -------------------------------------------------------------
    --  SPECIFIC SERVICE IMPLEMENTATION
    -------------------------------------------------------------
    dimlevels = dimlevels, -- how many dim levels does the device support, count from 0 to dimlevels
    zeroisoff = zeroisoff, -- if level is 0 is the Light then completely off?
    
    callback = nil, -- function(service, target, level, power) -- should set the device to this level, no questions asked
    -- when done, the callback function should set LoadLevelStatus to the value of 'target'
    -- level is the level number (0 to dimlevels)
    -- power is boolean, whether power should be on/off
    
    -------------------------------------------------------------
    -- Returns the load percentage for the given dimlevel
    -- @param level The level to be converted into a load %
    -- @return percentage load for the given level
    level2perc = function(self, level)
      local levels = self.dimlevels or dimlevels
      if not self.zeroisoff then levels = levels + 1 end  -- off is an extra level
to be done    
    end,
    -------------------------------------------------------------
    -- Returns the dimlevel for a given load percentage 
    -- @param perc % to be converted to a dimlevel
    -- @return dimlevel to go with the given %
    perc2level = function(self, perc)
      local levels = self.dimlevels or dimlevels
      if not self.zeroisoff then levels = levels + 1 end  -- off is an extra level
to be done      
    end,
    
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
        execute = function(self, params)
          -- if ramping, stop now
          local isramping = self:getstatevariable("isramping"):get()
          if isramping == 1 then
            self:getaction("stopramping"):execute()
          end
          -- set statevariable
          self:getstatevariable("loadleveltarget"):set(params.newloadleveltarget)
          -- call callback to inform driver to set a new level
          self:getservice():callback(params.newloadleveltarget, 
                -- note: perc2level return 2 values!
                self:getservice():perc2level(params.newloadleveltarget))
        end,
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
          local level = self:getstatevariable("loadleveltarget"):get()
          level = level + self:getstatevariable("stepsize"):get()
          if level > 100 then level = 100 end
          self:getaction("setloadleveltarget"):execute( { newloadleveltarget = level } )
        end,
      },
      { name = "StepDown", 
        execute = function(self, params)
          local level = self:getstatevariable("loadleveltarget"):get()
          level = level - self:getstatevariable("stepsize"):get()
          if level < 0 then level = 0 end
          self:getaction("setloadleveltarget"):execute( { newloadleveltarget = level } )
        end,
      },
      { name = "StartRampUp", 
        execute = function(self, params)
          local level = self:getstatevariable("loadleveltarget"):get()
          local rate = self:getstatevariable("ramprate"):get()
          local ramptime = math.floor(((100-level)/rate) * 1000)
          self:getaction("ramptolevel"):execute( { newloadleveltarget = 100, newramptime = ramptime } )
        end,
      },
      { name = "StartRampDown", 
        execute = function(self, params)
          local level = self:getstatevariable("loadleveltarget"):get()
          local rate = self:getstatevariable("ramprate"):get()
          local ramptime = math.floor(((level)/rate) * 1000)
          self:getaction("ramptolevel"):execute( { newloadleveltarget = 0, newramptime = ramptime } )
        end,
      },
      { name = "StopRamp", 
        execute = function(self, params)
          self:getstatevariable("isramping"):set(0)          
          self:getstatevariable("ramppaused"):set(0)
-- to be implemented          
-- cancel ramp timer
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
          -- if ramping, stop now
          local isramping = self:getstatevariable("isramping"):get()
          if isramping == 1 then
            self:getaction("stopramping"):execute()
          end
-- to be implemented          
-- start ramp timer
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