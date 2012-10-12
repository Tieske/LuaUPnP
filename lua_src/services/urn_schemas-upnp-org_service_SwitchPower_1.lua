

local function newservice()
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
    <!-- Declarations for other state variables added by UPnP vendor (if any) go here -->
  </serviceStateTable>
</scpd>

