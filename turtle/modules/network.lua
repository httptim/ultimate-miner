-- Network Module for Ultimate Miner
-- Handles all network communication using rednet protocol

local Network = {}
local Core = require("turtle.modules.core")
local State = require("turtle.modules.state")
local Config = require("turtle.modules.config")
local CONSTANTS = require("shared.constants")

-- Module state
local initialized = false
local modem = nil
local modem_side = nil
local is_ender_modem = false
local connected = false
local protocol = "ULTIMATE_MINER_V2"
local computer_id = os.getComputerID()

-- Heartbeat management
local heartbeat_timer = nil
local heartbeat_interval = 5 -- seconds (configurable 5-10)
local last_heartbeat = nil

-- Message handlers
local message_handlers = {}

-- Connection tracking
local control_computer_id = nil
local last_message_time = nil
local connection_timeout = 30 -- seconds

-- Initialize the network module
function Network.init(custom_protocol)
    if initialized then
        return true, "Network already initialized"
    end
    
    -- Set protocol
    if custom_protocol then
        protocol = custom_protocol
    end
    
    -- Find and open modem
    local success, err = Network.openModem()
    if not success then
        return false, "Failed to open modem: " .. err
    end
    
    -- Register default handlers
    Network.registerHandler("ping", function(sender, data)
        Network.send(sender, {
            type = "pong",
            id = computer_id,
            timestamp = os.epoch("utc")
        })
    end)
    
    Network.registerHandler("command", function(sender, data)
        Core.emit("network.command_received", {
            sender = sender,
            command = data.command,
            parameters = data.parameters
        })
    end)
    
    initialized = true
    Core.log("INFO", "Network module initialized with protocol: " .. protocol)
    
    return true, "Network initialized successfully"
end

-- Find and open the best available modem
function Network.openModem()
    -- Try to find ender modem first (infinite range)
    modem = peripheral.find("modem", function(name, m)
        return m.isWireless and m.isWireless() and m.getNamesRemote ~= nil
    end)
    
    if modem then
        is_ender_modem = true
        Core.log("INFO", "Found ender modem")
    else
        -- Try to find any wireless modem
        modem = peripheral.find("modem", function(name, m)
            return m.isWireless and m.isWireless()
        end)
        
        if modem then
            Core.log("INFO", "Found wireless modem")
        else
            -- Fall back to any modem
            modem = peripheral.find("modem")
            if modem then
                Core.log("INFO", "Found wired modem")
            end
        end
    end
    
    if not modem then
        return false, "No modem found"
    end
    
    -- Find which side the modem is on for rednet
    local sides = {"top", "bottom", "left", "right", "front", "back"}
    for _, side in ipairs(sides) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
            modem_side = side
            break
        end
    end
    
    if not modem_side then
        return false, "Could not determine modem side"
    end
    
    -- Open for rednet
    rednet.open(modem_side)
    
    return true, "Modem opened successfully"
end

-- Connect to network
function Network.connect()
    if not initialized then
        return false, "Network not initialized"
    end
    
    connected = true
    last_message_time = os.epoch("utc")
    
    -- Start heartbeat
    Network.startHeartbeat()
    
    -- Broadcast presence
    Network.broadcast({
        type = "turtle_online",
        id = computer_id,
        position = State.get("position"),
        fuel = turtle.getFuelLevel(),
        timestamp = os.epoch("utc")
    })
    
    Core.emit("network.connected", {id = computer_id})
    Core.log("INFO", "Connected to network")
    
    return true, "Connected successfully"
end

-- Disconnect from network
function Network.disconnect()
    if not connected then
        return true, "Already disconnected"
    end
    
    -- Stop heartbeat
    Network.stopHeartbeat()
    
    -- Notify network
    Network.broadcast({
        type = "turtle_offline",
        id = computer_id,
        timestamp = os.epoch("utc")
    })
    
    connected = false
    control_computer_id = nil
    
    Core.emit("network.disconnected", {reason = "Manual disconnect"})
    Core.log("INFO", "Disconnected from network")
    
    return true, "Disconnected successfully"
end

-- Check if connected
function Network.isConnected()
    if not connected then
        return false
    end
    
    -- Check for connection timeout
    if last_message_time then
        local time_since_message = (os.epoch("utc") - last_message_time) / 1000
        if time_since_message > connection_timeout then
            connected = false
            Core.emit("network.disconnected", {reason = "Timeout"})
            return false
        end
    end
    
    return connected
end

-- Send message to specific recipient
function Network.send(recipient, message)
    if not initialized then
        return false, "Network not initialized"
    end
    
    -- Ensure message is a table
    if type(message) ~= "table" then
        message = {data = message}
    end
    
    -- Add metadata
    message.sender = computer_id
    message.timestamp = os.epoch("utc")
    
    -- Send via rednet with protocol
    rednet.send(recipient, message, protocol)
    
    Core.log("DEBUG", string.format("Sent message to %d: %s", 
        recipient, message.type or "data"))
    
    return true
end

-- Broadcast message to all
function Network.broadcast(message)
    if not initialized then
        return false, "Network not initialized"
    end
    
    -- Ensure message is a table
    if type(message) ~= "table" then
        message = {data = message}
    end
    
    -- Add metadata
    message.sender = computer_id
    message.timestamp = os.epoch("utc")
    
    -- Broadcast via rednet with protocol
    rednet.broadcast(message, protocol)
    
    Core.log("DEBUG", "Broadcast message: " .. (message.type or "data"))
    
    return true
end

-- Receive message with timeout
function Network.receive(timeout)
    if not initialized then
        return false, nil, "Network not initialized"
    end
    
    -- Receive with protocol filter
    local sender, message, received_protocol = rednet.receive(protocol, timeout)
    
    if not sender then
        return false, nil, "Timeout"
    end
    
    -- Update last message time
    last_message_time = os.epoch("utc")
    
    -- Process message if handler exists
    if message and type(message) == "table" and message.type and message_handlers[message.type] then
        local handler = message_handlers[message.type]
        local success, err = pcall(handler, sender, message)
        if not success then
            Core.log("ERROR", "Handler error for " .. message.type .. ": " .. err)
        end
    end
    
    -- Emit event
    Core.emit("network.message_received", {
        sender = sender,
        message = message
    })
    
    return true, {sender = sender, message = message}
end

-- Register message handler
function Network.registerHandler(msg_type, handler)
    if type(handler) ~= "function" then
        return false, "Handler must be a function"
    end
    
    message_handlers[msg_type] = handler
    Core.log("DEBUG", "Registered handler for: " .. msg_type)
    
    return true
end

-- Start heartbeat
function Network.startHeartbeat()
    heartbeat_interval = Config.get("network_heartbeat_interval", 5)
    
    -- Ensure interval is within 5-10 seconds
    heartbeat_interval = math.max(5, math.min(10, heartbeat_interval))
    
    local function sendHeartbeat()
        if connected then
            local status = {
                type = "heartbeat",
                id = computer_id,
                position = State.get("position"),
                fuel = turtle.getFuelLevel(),
                fuel_level = turtle.getFuelLevel(),
                fuel_limit = turtle.getFuelLimit(),
                inventory_free = State.get("inventory_free_slots", 16),
                current_task = State.get("current_task", "idle"),
                mining_stats = State.get("mining_stats", {}),
                timestamp = os.epoch("utc")
            }
            
            -- Send to control computer if known
            if control_computer_id then
                Network.send(control_computer_id, status)
            else
                -- Broadcast to find control computer
                Network.broadcast(status)
            end
            
            last_heartbeat = os.epoch("utc")
            
            -- Schedule next heartbeat
            heartbeat_timer = os.startTimer(heartbeat_interval)
        end
    end
    
    -- Send initial heartbeat
    sendHeartbeat()
    
    -- Register heartbeat handler
    Core.on("timer", function(timer_id)
        if timer_id == heartbeat_timer then
            sendHeartbeat()
        end
    end)
    
    Core.log("INFO", "Heartbeat started with interval: " .. heartbeat_interval .. "s")
end

-- Stop heartbeat
function Network.stopHeartbeat()
    if heartbeat_timer then
        os.cancelTimer(heartbeat_timer)
        heartbeat_timer = nil
    end
    
    Core.log("INFO", "Heartbeat stopped")
end

-- Send status update
function Network.sendStatus(status)
    if not connected then
        return false, "Not connected"
    end
    
    -- Add standard fields
    status.type = status.type or "status_update"
    status.id = computer_id
    status.timestamp = os.epoch("utc")
    
    -- Send to control computer or broadcast
    if control_computer_id then
        return Network.send(control_computer_id, status)
    else
        return Network.broadcast(status)
    end
end

-- Request command from control
function Network.requestCommand()
    if not connected then
        return false, nil, "Not connected"
    end
    
    -- Send request
    local request = {
        type = "command_request",
        id = computer_id,
        position = State.get("position"),
        fuel = turtle.getFuelLevel(),
        inventory_free = State.get("inventory_free_slots", 16),
        capabilities = {
            mining = true,
            navigation = true,
            storage = true,
            patterns = State.get("available_patterns", {})
        }
    }
    
    if control_computer_id then
        Network.send(control_computer_id, request)
    else
        Network.broadcast(request)
    end
    
    -- Wait for response
    local timer = os.startTimer(5) -- 5 second timeout
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "rednet_message" then
            local sender, message, recv_protocol = p1, p2, p3
            
            if recv_protocol == protocol and message and type(message) == "table" then
                if message.type == "command_response" and message.target == computer_id then
                    os.cancelTimer(timer)
                    
                    -- Remember control computer
                    control_computer_id = sender
                    
                    return true, message.command
                end
            end
        elseif event == "timer" and p1 == timer then
            return false, nil, "Timeout waiting for command"
        end
    end
end

-- Discover network services
function Network.discover(service_type, timeout)
    timeout = timeout or 2
    service_type = service_type or "control_computer"
    
    local services = {}
    local discover_msg = {
        type = "discover",
        service = service_type,
        id = computer_id
    }
    
    Network.broadcast(discover_msg)
    
    -- Collect responses
    local timer = os.startTimer(timeout)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "rednet_message" then
            local sender, message, recv_protocol = p1, p2, p3
            
            if recv_protocol == protocol and message and type(message) == "table" then
                if message.type == "discover_response" and message.service == service_type then
                    table.insert(services, {
                        id = sender,
                        info = message.info,
                        distance = message.distance
                    })
                end
            end
        elseif event == "timer" and p1 == timer then
            break
        end
    end
    
    Core.log("INFO", string.format("Discovered %d %s services", #services, service_type))
    
    return services
end

-- Get network statistics
function Network.getStats()
    return {
        connected = connected,
        computer_id = computer_id,
        protocol = protocol,
        modem_type = is_ender_modem and "ender" or (modem and modem.isWireless and modem.isWireless() and "wireless" or "wired"),
        modem_side = modem_side,
        control_computer = control_computer_id,
        last_heartbeat = last_heartbeat,
        heartbeat_interval = heartbeat_interval,
        last_message_time = last_message_time,
        message_handlers = Core.tableKeys(message_handlers)
    }
end

-- Reconnect after failure
function Network.reconnect()
    Core.log("INFO", "Attempting to reconnect...")
    
    -- Close existing connection
    if connected then
        Network.disconnect()
    end
    
    -- Wait a moment
    os.sleep(1)
    
    -- Try to reconnect
    return Network.connect()
end

-- Set control computer ID
function Network.setControlComputer(id)
    control_computer_id = id
    Core.log("INFO", "Control computer set to ID: " .. id)
end

-- Get control computer ID
function Network.getControlComputer()
    return control_computer_id
end

-- Close modem (for shutdown)
function Network.shutdown()
    if connected then
        Network.disconnect()
    end
    
    if modem_side then
        rednet.close(modem_side)
    end
    
    initialized = false
    modem = nil
    modem_side = nil
    
    Core.log("INFO", "Network module shut down")
    
    return true
end

return Network