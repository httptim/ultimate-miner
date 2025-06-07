-- Clean Install Script for Ultimate Miner
-- This removes old files and does a fresh install

print("=== Ultimate Miner Clean Install ===")
print()
print("This will remove all existing Ultimate Miner files")
print("and perform a fresh installation.")
print()
write("Continue? (y/n): ")
local answer = read()

if answer:lower() ~= "y" then
    print("Installation cancelled.")
    return
end

print()
print("Removing old files...")

-- Remove directories
local dirs = {"/turtle", "/control", "/shared", "/tests", "/docs"}
for _, dir in ipairs(dirs) do
    if fs.exists(dir) then
        fs.delete(dir)
        print("Removed " .. dir)
    end
end

-- Remove root files
local files = {
    "/startup.lua",
    "/installer.lua", 
    "/ultimate_miner_errors.log",
    "/ultimate_miner_crash.log",
    "/control_crash.log",
    "/pastebin_info.txt",
    "/error_report_code.txt"
}

for _, file in ipairs(files) do
    if fs.exists(file) then
        fs.delete(file)
        print("Removed " .. file)
    end
end

print()
print("Downloading fresh installer...")

-- Download and run installer
shell.run("wget", "https://raw.githubusercontent.com/httptim/ultimate-miner/main/installer.lua", "installer.lua")

print()
print("Running installer...")
print()

shell.run("installer.lua")