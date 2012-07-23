-----------------------------------------------------------------
--  Sample config file for a device
--
--
-----------------------------------------------------------------

local device = {
    udn = nil,      -- will be generated if nil
    xml = "",       -- either an XML block, or a filename
    contents = {
        -- contents of device (parameters for device xml)
    },
    servicelist = {
        [1] = {
            serviceType = "",
            serviceId = nil,    -- will be generated if nil
            xml = ""           -- either an XML block, or a filename
            contents = {
                -- contents of service (parameters for service xml)
            },
        },
