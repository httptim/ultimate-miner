-- Debug version to test what's happening
print("Testing menu loop behavior...")

-- Simulate the menu structure
local loop_count = 0
local ticks_enabled = true
local old_ticks = ticks_enabled
ticks_enabled = false

print("Ticks disabled, entering loop")

while true do
    loop_count = loop_count + 1
    print("\n=== Loop iteration: " .. loop_count .. " ===")
    
    term.clear()
    term.setCursorPos(1, 1)
    
    print("Test Menu")
    print("1. Test 1")
    print("2. Test 2") 
    print("3. Test GPS")
    print("4. Exit")
    write("Choice: ")
    
    local choice = read()
    print("You entered: '" .. choice .. "'")
    
    if choice == "1" then
        print("Running test 1...")
        os.sleep(1)
    elseif choice == "2" then
        print("Running test 2...")
        os.sleep(1)
    elseif choice == "3" then
        print("Testing GPS...")
        local x, y, z = gps.locate(2)
        if x then
            print("GPS: " .. x .. "," .. y .. "," .. z)
        else
            print("No GPS")
        end
    elseif choice == "4" then
        print("Exiting...")
        ticks_enabled = old_ticks
        break
    else
        print("Invalid choice")
    end
    
    if choice ~= "4" then
        print("\nPress any key to continue...")
        os.pullEvent("key")
        print("Key pressed, continuing loop...")
    end
end

print("\nLoop exited successfully")
print("Ticks restored: " .. tostring(ticks_enabled))