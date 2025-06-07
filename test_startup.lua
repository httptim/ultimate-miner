-- Test startup issues
print("Testing Ultimate Miner startup...")
print("")

-- Test 1: Module loader
print("1. Testing module loader...")
local success, result = pcall(require, "/shared/module_loader")
if success then
    print("   ✓ Module loader loaded")
else
    print("   ✗ Failed to load module loader:")
    print("     " .. tostring(result))
end

-- Test 2: Init program
if success then
    print("\n2. Testing init_program...")
    local success2, modules = pcall(function()
        return result.init_program(turtle and "turtle" or "control")
    end)
    if success2 then
        print("   ✓ Program initialized")
    else
        print("   ✗ Failed to initialize:")
        print("     " .. tostring(modules))
    end
end

-- Test 3: Error handler
print("\n3. Testing error handler...")
local success3, err = pcall(require, "shared.error_handler")
if success3 then
    print("   ✓ Error handler loaded")
else
    print("   ✗ Failed to load error handler:")
    print("     " .. tostring(err))
end

-- Test 4: Error reporter
print("\n4. Testing error reporter...")
local success4, err2 = pcall(require, "shared.error_reporter")
if success4 then
    print("   ✓ Error reporter loaded")
else
    print("   ✗ Failed to load error reporter:")
    print("     " .. tostring(err2))
end

print("\nTest complete. Check for any errors above.")