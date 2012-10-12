--[[
UPnP devices + services methods/props
  - module: module name required to recreate the device
  - serialize: serializes the device, including toplevel 'module' property
    does not serialize sub-devices. UPnP lib will iterate over the devices
    to store them top down
  - writexml(path): writes the description xml's in the target dir order
       path/devUUID/device.xml   -> device xml
       path/devUUID/serviceId.xml  -> for each service xml
    all sub-devices write to their own 'devUUID' folder

UPnP device modules
return a module table containing
  - new: create a new device
  - deserialize: to recreate a device 
  
  
Drivers
  - on startup register for COPAS events
  - 
]]
