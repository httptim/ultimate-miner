-- Test Control Computer Installation
print("=== Control Computer Installation Test ===")
print()

-- Check device type
local device_type = turtle and "turtle" or "computer"
print("Device type: " .. device_type)
print()

-- Check key files
print("Checking installed files:")

local files_to_check = {
    "/shared/module_loader.lua",
    "/shared/constants.lua", 
    "/shared/error_handler.lua",
    "/shared/error_reporter.lua",
    "/control/main.lua",
    "/control/modules/core.lua",
    "/control/modules/network.lua",
    "/control/modules/fleet.lua",
    "/control/modules/ui.lua",
    "/control/screens/dashboard.lua",
    "/startup.lua"
}

local missing = 0
for _, file in ipairs(files_to_check) do
    if fs.exists(file) then
        print("✓ " .. file)
    else
        print("✗ " .. file .. " - MISSING")
        missing = missing + 1
    end
end

print()
print("Summary:")
print("Total files checked: " .. #files_to_check)
print("Missing files: " .. missing)

-- Check startup content
if fs.exists("/startup.lua") then
    print("\nStartup file content:")
    local file = fs.open("/startup.lua", "r")
    local content = file.readAll()
    file.close()
    print(content)
else
    print("\nNo startup file found!")
end

-- Try to run control/main.lua
if fs.exists("/control/main.lua") then
    print("\nTrying to load control/main.lua...")
    local ok, err = pcall(function()
        dofile("/control/main.lua")
    end)
    if not ok then
        print("Error: " .. tostring(err))
    end
else
    print("\nCannot test - /control/main.lua not found")
end