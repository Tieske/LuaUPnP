local xml = require("LuaUPnP")

print("Content of IXML library:")
for k,v in pairs(xml) do
    print("   ", k, v);
end

print ("Press enter to continue...")
io.read()
