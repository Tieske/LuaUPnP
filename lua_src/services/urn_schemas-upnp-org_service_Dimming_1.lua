---------------------------------------------------------------------------
-- Standard service; "urn:schemas-upnp-org:service:Dimming:1".
-- When required, it returns a single function which generates a new service table 
-- on every call (it takes no parameters). The <code>upnp.devicefactory</code> module 
-- takes the device/service tables to build device/service objects.
-- <br><br>Requires to implement the following elements;
-- </p>
-- <ul>
-- <li><code>service.serviceStateTable.loadLevelTarget.afterset = function(self, oldval) ... end</code> to process the changed loadLevelTarget value</li>
-- <li>When a containing device stops, is should stop ramping when ramping is in progress</li>
-- </ul>
-- <p><strong>Note:</strong> the RampRate variable deviates from the standard because 
-- the default value is not 0 but 5. The specified 0 is an illegal value, and is preventing 
-- RampUp() and RampDown() from working without first altering RampRate.
-- @class module
-- @name urn_schemas-upnp-org_service_Dimming_1

local gettime = require("socket").gettime
local copas = require("copas.timer")

local newservice = function()
  return {
    serviceType = "urn:schemas-upnp-org:service:Dimming:1",
    
    -------------------------------------------------------------
    --  CUSTOM IMPLEMENTATION
    -------------------------------------------------------------
    customList = {
      -- all elements here are copied into the final object
      -- by devicefactory.builddevice()
    },
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
            self:getaction("stopramp"):execute()
          end
          -- set statevariable
          self:getstatevariable("loadleveltarget"):set(params.newloadleveltarget)
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
          level = level + self:getstatevariable("StepDelta"):get()
          self:getaction("setloadleveltarget"):execute( { newloadleveltarget = level } )
        end,
      },
      { name = "StepDown", 
        execute = function(self, params)
          local level = self:getstatevariable("loadleveltarget"):get()
          level = level - self:getstatevariable("StepDelta"):get()
          self:getaction("setloadleveltarget"):execute( { newloadleveltarget = level } )
        end,
      },
      { name = "StartRampUp", 
        execute = function(self, params)
          local rate = self:getstatevariable("ramprate"):get()
          if rate == 0 then
            return nil, "Action Failed: statevariable ramprate must be greater than 0", 501
          end
          local level = self:getstatevariable("loadleveltarget"):get()
          local ramptime = math.floor(((100-level)/rate) * 1000)
          self:getaction("startramptolevel"):execute( { newloadleveltarget = 100, newramptime = ramptime } )
        end,
      },
      { name = "StartRampDown", 
        execute = function(self, params)
          local rate = self:getstatevariable("ramprate"):get()
          if rate == 0 then
            return nil, "Action Failed: statevariable ramprate must be greater than 0", 501
          end
          local level = self:getstatevariable("loadleveltarget"):get()
          local ramptime = math.floor(((level)/rate) * 1000)
          self:getaction("startramptolevel"):execute( { newloadleveltarget = 0, newramptime = ramptime } )
        end,
      },
      { name = "StopRamp", 
        execute = function(self, params)
          local service = self:getservice()
          service:getstatevariable("isramping"):set(0)          
          service:getstatevariable("ramppaused"):set(0)
          service:getstatevariable("ramptime"):set(0)
          if service.ramptimer then
            service.ramptimer:cancel()
          end
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
          if self:getstatevariable("isramping"):get() == 1 then
            self:getaction("stopramp"):execute()
          end
          local service = self:getservice()
          -- create new timer with upvalues
          local callback = function()
            -- this will run as a timer callback, on the MAIN Lua thread, so not a scheduler thread
            -- what fraction of time still to go?
            local fullruntime = service.rampendtime - service.rampstarttime   -- all in seconds
            local fraction = (service.rampendtime - gettime()) / fullruntime
            -- calculate new target value
            local newtarget = service.ramptarget - (service.ramptarget - service.rampstartlevel) * fraction
            newtarget = math.floor(newtarget + 0.5)  -- round to full %
            if newtarget < 0 then newtarget = 0 elseif newtarget > 100 then newtarget = 100 end
            -- if we've approached target within 3%, then close enough so set target now
            if newtarget-service.ramptarget >= -3 and newtarget-service.ramptarget <= 3 then
              newtarget = service.ramptarget
            end
            -- set variables
            service:getstatevariable("ramptime"):set((service.rampendtime - gettime()) * 1000)  -- in msec
            service:getstatevariable("loadleveltarget"):set(newtarget)
            -- check whether we're done
            if newtarget == service.ramptarget then
              service:getaction("stopramp"):execute()    -- done, so stop
            else
              service.ramptimer:arm(1)                      -- not done, arm timer for next second
            end
          end
          if not service.ramptimer then
            service.ramptimer = copas.newtimer(nil, callback, nil, false, nil)
          end
          
          service:getstatevariable("isramping"):set(1)          
          service:getstatevariable("ramppaused"):set(0)
          service.rampstartlevel = tonumber(service:getstatevariable("loadleveltarget"):get()) or 100
          service.ramptarget = tonumber(params.newloadleveltarget) or 1000 -- unit is millisecs
          service:getstatevariable("ramptime"):set(params.newramptime)
          service.rampstarttime = gettime()   -- in seconds
          service.rampendtime = gettime() + ((tonumber(params.newramptime) or 1000)/1000)   -- in seconds
          -- execute now (will arm timer)
          callback()
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
          if self:getstatevariable("isramping"):get() == 0 then
            return nil, "Cannot pause ramping, no ramping is in progress", 700
          end
          self:getstatevariable("ramppaused"):set(1)
          self:getservice().ramptimer:cancel()
        end,
      },
      { name = "ResumeRamp",
        execute = function(self, params)
          if self:getstatevariable("isramping"):get() == 0 then
            return nil, "Cannot resume ramping, no ramping is in progress", 700
          end
          if self:getstatevariable("ramppaused"):get() ~= 1 then
            return nil, "Cannot resume ramping, ramping is not paused", 700
          end
          self:getstatevariable("ramppaused"):set(0)
          -- get remaining ramptime and restart from now
          local service = self:getservice()
          local rt = self:getstatevariable("ramptime"):get()
          service.rampstarttime = gettime()
          service.rampendtime = gettime() + ((tonumber(rt) or 1000)/1000)
          service.rampstartlevel = tonumber(service:getstatevariable("loadleveltarget"):get()) or 100
          
          self:getservice().ramptimer:arm(0) -- at 0; execute now (=asap)
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
        ---------------------------------------------------------
        -- Implement this handler to add Dimming capability.
        -- The handler should implement the actual dimming behaviour and set the
        -- 'LoadLevelStatus' variable to the new value when done.
        -- @param self statevariable object for the 'LoadLevelTarget' statevariable
        -- @param oldval the previous value of 'LoadLevelTarget'
        -- @example# -- Create a new Dimming service
        -- local service = require("upnp.services.urn_schemas-upnp-org_service_Dimming_1")()
        -- <br>
        -- -- add implementation
        -- service.serviceStateTable[1].afterset = function(self, oldval)
        --     -- do something useful here...
        --     print("Setting the Dimming value to", self:get(), "from", oldval)
        -- <br>
        --     -- When done update value of Status to reflect the change
        --     self:getstatevariable("status"):set(self:get())
        -- end
        -- @see statevariable:afterset
        afterset = function(self, oldval)
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
        defaultValue = "OnEffectLevel",
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
        defaultValue = "5",
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