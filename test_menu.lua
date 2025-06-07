-- Simple menu test
print("Testing simple menu...")

while true do
    print("\nTest Menu:")
    print("1. Option 1")
    print("2. Option 2") 
    print("3. Exit")
    write("Choice: ")
    
    local choice = read()
    print("You entered: '" .. choice .. "' (length: " .. #choice .. ")")
    
    if choice == "1" then
        print("Option 1 selected!")
    elseif choice == "2" then
        print("Option 2 selected!")
    elseif choice == "3" then
        print("Exiting...")
        break
    else
        print("Unknown choice")
    end
    
    print("Press any key...")
    os.pullEvent("key")
end

print("Test complete")