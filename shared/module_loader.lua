-- Module Loader
-- Sets up the module loading environment for Ultimate Miner

local module_loader = {}

-- Setup require and package for proper module loading
function module_loader.setup(base_path)
    base_path = base_path or "/"
    
    -- Get cc.require
    local cc_require = require("cc.require")
    local env = getfenv(2)  -- Get caller's environment
    
    -- Create custom require with our base path
    local require_fn, package = cc_require.make(env, base_path)
    
    -- Add our custom paths to package.path
    local paths = {
        "?.lua",
        "?/init.lua",
        "/?.lua", 
        "/turtle/modules/?.lua",
        "/control/modules/?.lua",
        "/shared/?.lua",
        "/turtle/patterns/?.lua",
        "/control/ui/?.lua"
    }
    
    -- Build the path string
    local path_str = table.concat(paths, ";")
    package.path = path_str
    
    -- Set up the environment
    env.require = require_fn
    env.package = package
    
    -- Also update the global package.path for compatibility
    if _G.package then
        _G.package.path = path_str
    end
    
    return require_fn, package
end

-- Helper to load a module with error handling
function module_loader.load_module(module_name, required)
    required = required ~= false  -- Default to required
    
    local success, module = pcall(require, module_name)
    
    if success then
        return module, nil
    else
        local error_msg = "Failed to load module '" .. module_name .. "': " .. tostring(module)
        
        if required then
            error(error_msg)
        else
            -- Optional module, just return nil
            return nil, error_msg
        end
    end
end

-- Load multiple modules at once
function module_loader.load_modules(module_list)
    local loaded = {}
    local errors = {}
    
    for name, required in pairs(module_list) do
        local module, err = module_loader.load_module(name, required)
        
        if module then
            loaded[name] = module
        elseif err then
            table.insert(errors, err)
        end
    end
    
    return loaded, errors
end

-- Check if running in the correct environment
function module_loader.check_environment()
    local env_type = "unknown"
    local issues = {}
    
    -- Detect environment
    if turtle then
        env_type = "turtle"
    elseif term then
        env_type = "computer"
    else
        table.insert(issues, "Unknown environment - not turtle or computer")
    end
    
    -- Check for required APIs
    local required_apis = {"fs", "os", "term", "textutils"}
    for _, api in ipairs(required_apis) do
        if not _G[api] then
            table.insert(issues, "Missing required API: " .. api)
        end
    end
    
    -- Check for HTTP (optional but recommended)
    if not http then
        table.insert(issues, "HTTP API not available (optional)")
    end
    
    return env_type, issues
end

-- Initialize a program with proper module loading
function module_loader.init_program(program_type)
    -- Check environment
    local env_type, issues = module_loader.check_environment()
    
    if #issues > 0 and issues[1]:find("Missing required") then
        error("Environment check failed:\n" .. table.concat(issues, "\n"))
    end
    
    -- Verify we're running on the correct device
    if program_type == "turtle" and env_type ~= "turtle" then
        error("This program must be run on a turtle!")
    elseif program_type == "control" and env_type == "turtle" then
        error("This program must be run on a computer!")
    end
    
    -- Setup module loading
    module_loader.setup()
    
    -- Load core modules that everything needs
    local core_modules = {
        ["shared.constants"] = true,
    }
    
    -- Add type-specific core modules
    if program_type == "turtle" then
        core_modules["turtle.modules.core"] = true
        core_modules["turtle.modules.state"] = true
        core_modules["turtle.modules.config"] = true
    elseif program_type == "control" then
        core_modules["control.modules.config"] = true
    end
    
    local loaded, errors = module_loader.load_modules(core_modules)
    
    if #errors > 0 then
        error("Failed to load core modules:\n" .. table.concat(errors, "\n"))
    end
    
    return loaded, env_type
end

return module_loader