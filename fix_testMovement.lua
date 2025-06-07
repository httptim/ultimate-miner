-- Fix testMovement indentation
print("Fixing testMovement function...")

local input_file = "/turtle/main.lua"
local output_file = "/turtle/main_fixed.lua"

-- Read the file
local file = fs.open(input_file, "r")
if not file then
    print("Error: Cannot open " .. input_file)
    return
end

local lines = {}
local in_testMovement = false
local fixed_lines = 0

-- Read all lines
while true do
    local line = file.readLine()
    if not line then break end
    
    -- Check if we're entering testMovement
    if line:match("^local function testMovement%(%)") then
        in_testMovement = true
        table.insert(lines, line)
    -- Check if we're exiting testMovement (the final end)
    elseif in_testMovement and line:match("^end%s*$") and not line:match("end%s*%-%-") then
        in_testMovement = false
        table.insert(lines, line)
    -- Fix indentation inside testMovement
    elseif in_testMovement then
        -- If line starts with less than 8 spaces and has content, it needs fixing
        local spaces, content = line:match("^(%s*)(.+)")
        if spaces and content and #spaces < 8 and not content:match("^while true do") then
            -- Add 8 more spaces to fix indentation
            line = "        " .. line
            fixed_lines = fixed_lines + 1
        end
        table.insert(lines, line)
    else
        table.insert(lines, line)
    end
end
file.close()

-- Write the fixed file
file = fs.open(output_file, "w")
for _, line in ipairs(lines) do
    file.writeLine(line)
end
file.close()

print("Fixed " .. fixed_lines .. " lines")
print("Output written to: " .. output_file)
print()
print("To apply the fix:")
print("mv " .. output_file .. " " .. input_file)