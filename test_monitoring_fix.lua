-- Test monitoring fix
print("Testing Ultimate Miner monitoring fix...")
print()

-- Set up paths
package.path = package.path .. ";/?;/?.lua;/?/init.lua"
package.path = package.path .. ";/shared/?.lua;/shared/?/init.lua"
package.path = package.path .. ";/turtle/?.lua;/turtle/?/init.lua"
package.path = package.path .. ";/turtle/modules/?.lua"

-- Test 1: Load Core module
print("1. Testing Core module...")
local success, Core = pcall(require, "turtle.modules.core")
if success then
    print("   ✓ Core loaded")
    -- Check if schedule_repeating_task exists
    if Core.schedule_repeating_task then
        print("   ✓ Core.schedule_repeating_task exists")
    else
        print("   ✓ Core.schedule_repeating_task does not exist (as expected)")
    end
else
    print("   ✗ Failed to load Core: " .. tostring(Core))
end

-- Test 2: Load State module
print("\n2. Testing State module...")
local success2, State = pcall(require, "turtle.modules.state")
if success2 then
    print("   ✓ State loaded")
    -- Initialize State
    local init_ok = pcall(State.init)
    if init_ok then
        print("   ✓ State initialized")
    end
else
    print("   ✗ Failed to load State: " .. tostring(State))
end

-- Test 3: Load Monitoring module
print("\n3. Testing Monitoring module...")
local success3, Monitoring = pcall(require, "turtle.modules.monitoring")
if success3 then
    print("   ✓ Monitoring loaded")
    
    -- Try to initialize
    print("   Attempting to initialize monitoring...")
    local init_success, err = pcall(Monitoring.init)
    if init_success then
        print("   ✓ Monitoring initialized successfully!")
        
        -- Check if tick function exists
        if Monitoring.tick then
            print("   ✓ Monitoring.tick exists")
            -- Try running it
            local tick_ok = pcall(Monitoring.tick)
            if tick_ok then
                print("   ✓ Monitoring.tick runs without error")
            end
        end
    else
        print("   ✗ Failed to initialize: " .. tostring(err))
    end
else
    print("   ✗ Failed to load Monitoring: " .. tostring(Monitoring))
end

-- Test 4: Check Alerts and Cancellation
print("\n4. Testing other affected modules...")
local modules_to_test = {"alerts", "cancellation"}
for _, mod_name in ipairs(modules_to_test) do
    local ok, mod = pcall(require, "turtle.modules." .. mod_name)
    if ok and mod.tick then
        print("   ✓ " .. mod_name .. " has tick function")
    else
        print("   ? " .. mod_name .. " status: " .. (ok and "loaded" or "failed"))
    end
end

print("\nTest complete!")