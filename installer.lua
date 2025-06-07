-- Ultimate Miner Installer
-- Automated installation script for turtle and control computer components

local VERSION = "2.2.0"
local GITHUB_BASE = "https://raw.githubusercontent.com/httptim/ultimate-miner/main/"
local GITHUB_REPO = "https://github.com/httptim/ultimate-miner"

-- Installation configuration
local install_config = {
    device_type = nil,  -- "turtle" or "computer"
    install_path = "/",
    github_branch = "main",
    components = {}
}

-- Component definitions
local components = {
    -- Shared components (needed by both turtle and computer)
    shared = {
        "shared/constants.lua"
    },
    
    -- Turtle-specific components
    turtle = {
        "turtle/main.lua",
        "turtle/modules/core.lua",
        "turtle/modules/state.lua", 
        "turtle/modules/config.lua",
        "turtle/modules/navigation.lua",
        "turtle/modules/inventory.lua",
        -- TODO: These modules are not yet implemented
        -- "turtle/modules/mining.lua",
        -- "turtle/modules/safety.lua",
        -- "turtle/modules/storage.lua",
        -- "turtle/modules/network.lua",
        -- Mining patterns (not yet implemented)
        -- "turtle/patterns/strip.lua",
        -- "turtle/patterns/branch.lua",
        -- "turtle/patterns/spiral.lua",
        -- "turtle/patterns/quarry.lua",
        -- "turtle/patterns/tunnel3x3.lua",
        -- "turtle/patterns/adaptive.lua"
    },
    
    -- Control computer components
    control = {
        "control/main.lua",
        -- TODO: These modules are not yet implemented
        -- "control/modules/ui.lua",
        -- "control/modules/fleet.lua",
        -- "control/modules/network.lua",
        -- "control/modules/monitor.lua",
        -- "control/modules/tasks.lua",
        -- "control/modules/config.lua",
        -- UI components (not yet implemented)
        -- "control/ui/dashboard.lua",
        -- "control/ui/turtle_list.lua",
        -- "control/ui/resource_manager.lua",
        -- "control/ui/area_manager.lua",
        -- "control/ui/settings.lua"
    }
}

-- Color support
local function supports_color()
    return term.isColor and term.isColor()
end

-- Clear screen with header
local function clear_screen(header)
    term.clear()
    term.setCursorPos(1, 1)
    
    if supports_color() then
        term.setTextColor(colors.yellow)
    end
    
    print("Ultimate Miner Installer v" .. VERSION)
    print(string.rep("=", 40))
    
    if supports_color() then
        term.setTextColor(colors.white)
    end
    
    if header then
        print(header)
        print()
    end
end

-- Print with optional color
local function print_color(text, color)
    if supports_color() and color then
        term.setTextColor(color)
    end
    print(text)
    if supports_color() then
        term.setTextColor(colors.white)
    end
end

-- Print status message
local function print_status(status, message)
    if status == "success" then
        print_color("[OK] " .. message, colors.green)
    elseif status == "error" then
        print_color("[ERROR] " .. message, colors.red)
    elseif status == "info" then
        print_color("[INFO] " .. message, colors.lightBlue)
    elseif status == "warning" then
        print_color("[WARN] " .. message, colors.yellow)
    else
        print("[ ] " .. message)
    end
end

-- Detect device type
local function detect_device_type()
    if turtle then
        return "turtle"
    else
        return "computer"
    end
end

-- Check if HTTP is enabled
local function check_http()
    if not http then
        print_status("error", "HTTP API is not enabled!")
        print("Please enable the HTTP API in the ComputerCraft config")
        print("to use this installer.")
        return false
    end
    return true
end

-- Download file from GitHub
local function download_file(file_path, save_path)
    local url = GITHUB_BASE .. file_path
    
    print_status("info", "Downloading: " .. file_path)
    
    local response = http.get(url)
    if not response then
        print_status("error", "Failed to download: " .. file_path)
        return false
    end
    
    local content = response.readAll()
    response.close()
    
    -- Create directory if needed
    local dir = fs.getDir(save_path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Save file
    local file = fs.open(save_path, "w")
    if not file then
        print_status("error", "Failed to save: " .. save_path)
        return false
    end
    
    file.write(content)
    file.close()
    
    return true
end

-- Install components
local function install_components(component_list)
    local success_count = 0
    local total = #component_list
    
    for i, file_path in ipairs(component_list) do
        local save_path = fs.combine(install_config.install_path, file_path)
        
        if download_file(file_path, save_path) then
            success_count = success_count + 1
            print_status("success", string.format("(%d/%d) %s", i, total, file_path))
        else
            print_status("error", string.format("(%d/%d) Failed: %s", i, total, file_path))
        end
        
        -- Small delay to avoid rate limiting
        os.sleep(0.1)
    end
    
    return success_count, total
end

-- Create startup file
local function create_startup()
    local startup_content = ""
    
    if install_config.device_type == "turtle" then
        startup_content = [[
-- Ultimate Miner Turtle Startup
shell.run("/turtle/main.lua")
]]
    else
        startup_content = [[
-- Ultimate Miner Control Computer Startup
shell.run("/control/main.lua")
]]
    end
    
    local file = fs.open("/startup.lua", "w")
    if file then
        file.write(startup_content)
        file.close()
        print_status("success", "Created startup file")
        return true
    else
        print_status("error", "Failed to create startup file")
        return false
    end
end

-- Installation menu
local function show_menu()
    clear_screen("Installation Options")
    
    print("Detected device: " .. install_config.device_type:upper())
    print()
    print("1. Install " .. install_config.device_type .. " components")
    print("2. Install both turtle and control components")
    print("3. Install specific component")
    print("4. Uninstall")
    print("5. Exit")
    print()
    write("Select option (1-5): ")
    
    local choice = read()
    return tonumber(choice)
end

-- Perform installation
local function perform_install(install_type)
    clear_screen("Installing Components")
    
    local files_to_install = {}
    
    -- Add shared components
    for _, file in ipairs(components.shared) do
        table.insert(files_to_install, file)
    end
    
    -- Add module loader (required for main programs)
    table.insert(files_to_install, "shared/module_loader.lua")
    
    -- Add specific components
    if install_type == "turtle" or install_type == "both" then
        for _, file in ipairs(components.turtle) do
            table.insert(files_to_install, file)
        end
    end
    
    if install_type == "control" or install_type == "both" then
        for _, file in ipairs(components.control) do
            table.insert(files_to_install, file)
        end
    end
    
    print_status("info", "Installing " .. #files_to_install .. " files...")
    print()
    
    local success, total = install_components(files_to_install)
    
    print()
    print_status("info", string.format("Installation complete: %d/%d files", success, total))
    
    if success == total then
        print_status("success", "All components installed successfully!")
        
        -- Create startup file
        if install_type ~= "both" then
            print()
            write("Create startup file? (y/n): ")
            if read():lower() == "y" then
                create_startup()
            end
        end
        
        return true
    else
        print_status("error", "Some components failed to install")
        return false
    end
end

-- Uninstall
local function uninstall()
    clear_screen("Uninstall Ultimate Miner")
    
    print_status("warning", "This will remove all Ultimate Miner files!")
    write("Are you sure? (y/n): ")
    
    if read():lower() ~= "y" then
        print_status("info", "Uninstall cancelled")
        return
    end
    
    -- Remove directories
    local dirs_to_remove = {"/turtle", "/control", "/shared"}
    for _, dir in ipairs(dirs_to_remove) do
        if fs.exists(dir) then
            fs.delete(dir)
            print_status("success", "Removed " .. dir)
        end
    end
    
    -- Remove startup if it's ours
    if fs.exists("/startup.lua") then
        local file = fs.open("/startup.lua", "r")
        if file then
            local content = file.readAll()
            file.close()
            if content:find("Ultimate Miner") then
                fs.delete("/startup.lua")
                print_status("success", "Removed startup file")
            end
        end
    end
    
    print()
    print_status("success", "Uninstall complete!")
end

-- Main installation flow
local function main()
    -- Initial setup
    install_config.device_type = detect_device_type()
    
    -- Check requirements
    if not check_http() then
        return
    end
    
    -- Show header
    clear_screen()
    print_color("Welcome to Ultimate Miner!", colors.yellow)
    print()
    print("Repository: " .. GITHUB_REPO)
    print("Version: " .. VERSION)
    print()
    
    -- Main menu loop
    while true do
        local choice = show_menu()
        
        if choice == 1 then
            -- Install for current device
            perform_install(install_config.device_type)
            print()
            print("Press any key to continue...")
            os.pullEvent("key")
        elseif choice == 2 then
            -- Install both
            perform_install("both")
            print()
            print("Press any key to continue...")
            os.pullEvent("key")
        elseif choice == 3 then
            -- Custom install
            clear_screen("Custom Installation")
            print("Available components:")
            print("1. Turtle components only")
            print("2. Control computer components only")
            print("3. Shared libraries only")
            write("\nSelect component set (1-3): ")
            local comp_choice = tonumber(read())
            
            if comp_choice == 1 then
                perform_install("turtle")
            elseif comp_choice == 2 then
                perform_install("control")
            elseif comp_choice == 3 then
                install_components(components.shared)
            end
            
            print()
            print("Press any key to continue...")
            os.pullEvent("key")
        elseif choice == 4 then
            -- Uninstall
            uninstall()
            print()
            print("Press any key to continue...")
            os.pullEvent("key")
        elseif choice == 5 then
            -- Exit
            clear_screen()
            print_status("info", "Installation cancelled")
            break
        else
            print_status("error", "Invalid choice")
            os.sleep(1)
        end
    end
end

-- Run installer
main()