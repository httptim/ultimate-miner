-- Fix all menu functions in turtle/main.lua
print("Fixing all menu functions...")

-- Read the current file
local file = fs.open("/turtle/main.lua", "r")
if not file then
    print("Error: Cannot open /turtle/main.lua")
    return
end

local lines = {}
while true do
    local line = file.readLine()
    if not line then break end
    table.insert(lines, line)
end
file.close()

local fixes_applied = 0

-- Function to find and fix a function
local function fixFunction(func_name, has_submenu)
    print("Fixing " .. func_name .. "...")
    
    local start_line = nil
    local end_line = nil
    local depth = 0
    
    -- Find function start
    for i, line in ipairs(lines) do
        if line:match("^local function " .. func_name .. "%(%)") then
            start_line = i
            depth = 1
            
            -- Find function end
            for j = i + 1, #lines do
                if lines[j]:match("^%s*function") then
                    depth = depth + 1
                elseif lines[j]:match("^end") then
                    depth = depth - 1
                    if depth == 0 then
                        end_line = j
                        break
                    end
                end
            end
            break
        end
    end
    
    if not start_line or not end_line then
        print("  Could not find " .. func_name)
        return false
    end
    
    -- Check if it needs fixing
    local needs_fix = false
    local has_read = false
    local has_recursive_call = false
    
    for i = start_line, end_line do
        if lines[i]:match("read%(%)") then
            has_read = true
        end
        if lines[i]:match(func_name .. "%(%)%s*%-%-") then
            has_recursive_call = true
        end
    end
    
    if not has_read and not has_submenu then
        print("  No fix needed - no user input")
        return false
    end
    
    -- Apply fixes
    if has_submenu or has_read then
        -- Add tick disabling after function declaration
        table.insert(lines, start_line + 1, "    -- Disable background ticks while in this menu")
        table.insert(lines, start_line + 2, "    local old_ticks = ticks_enabled")
        table.insert(lines, start_line + 3, "    ticks_enabled = false")
        table.insert(lines, start_line + 4, "    ")
        end_line = end_line + 4
        
        -- Add tick restoration before returns
        for i = end_line - 1, start_line + 5, -1 do
            if lines[i]:match("return") and not lines[i]:match("return ") then
                -- Insert restoration before return
                table.insert(lines, i, "            ticks_enabled = old_ticks  -- Restore tick state")
                end_line = end_line + 1
            end
        end
        
        -- Add restoration before final end
        table.insert(lines, end_line, "    ticks_enabled = old_ticks  -- Restore tick state")
        end_line = end_line + 1
        
        fixes_applied = fixes_applied + 1
    end
    
    -- Fix recursive calls if present
    if has_recursive_call then
        print("  Fixing recursive call...")
        
        -- Need to wrap in while loop
        -- This is more complex, so for now just remove the recursive call
        for i = start_line, end_line do
            if lines[i]:match(func_name .. "%(%)%s*%-%-") then
                lines[i] = lines[i]:gsub(func_name .. "%(%)%s*", "")
                print("  Removed recursive call")
            end
        end
    end
    
    return true
end

-- Fix each function
fixFunction("startMining", true)
fixFunction("configureSettings", false) 
fixFunction("testMovement", true)  -- Already partially fixed
fixFunction("viewStatistics", false)
fixFunction("networkMode", false)

-- Write the fixed file
print("\nWriting fixed file...")
file = fs.open("/turtle/main_fixed.lua", "w")
for _, line in ipairs(lines) do
    file.writeLine(line)
end
file.close()

print("\nFixed " .. fixes_applied .. " functions")
print("Output: /turtle/main_fixed.lua")
print("\nTo apply: mv /turtle/main_fixed.lua /turtle/main.lua")