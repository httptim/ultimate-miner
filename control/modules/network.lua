-- Network Module for Control Computer
-- Handles network communication and turtle management

local Network = {}
local Core = require("control.modules.core")

-- Configuration
Network.PROTOCOL = "ULTIMATE_MINER_V2"
Network.COMPUTER_ID = os.getComputerID()
Network.HEARTBEAT_TIMEOUT = 30  -- Seconds before considering turtle disconnected

-- State
Network.initialized = false
Network.modem = nil
Network.modem_side = nil
Network.message_handlers = {}
Network.event_listener_active = false

-- Initialize network
function Network.init()
    if Network.initialized then
        Core.log("INFO", "Network already initialized")
        return true, "Already initialized"
    end
    
    -- Find and open modem
    local success, err = Network.openModem()
    if not success then
        return false, err
    end
    
    -- Start event listener
    Network.startEventListener()
    
    -- Register as control computer service
    Network.advertiseService()
    
    Network.initialized = true
    Core.log("INFO", "Network initialized with protocol: " .. Network.PROTOCOL)
    
    return true, "Network initialized successfully"
end

-- Find and open the best modem
function Network.openModem()
    -- Priority: ender modem > wireless > wired
    local modem_priority = function(name, modem)
        if modem.isWireless and modem.isWireless() then
            -- Check if it's an ender modem (infinite range)
            if modem.getRange then
                local range = modem.getRange()
                if range == nil or range > 100000 then
                    return 3  -- Ender modem
                end
            end
            return 2  -- Wireless modem
        end
        return 1  -- Wired modem
    end
    
    local best_modem = nil
    local best_side = nil
    local best_priority = 0
    
    -- Check all sides
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.getType(side) == "modem" then
            local modem = peripheral.wrap(side)
            local priority = modem_priority(side, modem)
            
            if priority > best_priority then
                best_modem = modem
                best_side = side
                best_priority = priority
            end
        end
    end
    
    if not best_modem then
        return false, "No modem found"
    end
    
    -- Open rednet on the modem
    rednet.open(best_side)
    
    Network.modem = best_modem
    Network.modem_side = best_side
    
    local modem_types = {[1] = "wired", [2] = "wireless", [3] = "ender"}
    Core.log("INFO", "Opened " .. modem_types[best_priority] .. " modem on " .. best_side)
    
    return true
end

-- Advertise as control computer service
function Network.advertiseService()
    -- This allows turtles to discover the control computer
    rednet.host(Network.PROTOCOL, "control_computer")
    Core.log("INFO", "Advertising control computer service")
end

-- Start the event listener
function Network.startEventListener()
    if Network.event_listener_active then
        return
    end
    
    Network.event_listener_active = true
    
    -- Register event handler for rednet messages
    Core.on("rednet_message", function(sender, message, protocol)
        if protocol == Network.PROTOCOL then
            Network.handleMessage(sender, message)
        end
    end)
    
    Core.log("INFO", "Network event listener started")
end

-- Handle incoming messages
function Network.handleMessage(sender, message)
    if type(message) ~= "table" then
        Core.log("WARNING", "Invalid message format from " .. sender)
        return
    end
    
    local msg_type = message.type
    if not msg_type then
        Core.log("WARNING", "Message without type from " .. sender)
        return
    end
    
    Core.log("DEBUG", "Received " .. msg_type .. " from turtle " .. sender)
    
    -- Handle discover requests specially
    if msg_type == "discover" and message.service == "control_computer" then
        Network.send(sender, {
            type = "discover_response",
            service = "control_computer",
            info = {
                name = "Main Control",
                computer_id = Network.COMPUTER_ID,
                capabilities = Core.getCapabilities()
            }
        })
        return
    end
    
    -- Emit event for this message type
    Core.emit("network:" .. msg_type, sender, message)
    
    -- Call registered handlers
    if Network.message_handlers[msg_type] then
        for _, handler in ipairs(Network.message_handlers[msg_type]) do
            local success, err = pcall(handler, sender, message)
            if not success then
                Core.log("ERROR", "Handler error for " .. msg_type .. ": " .. tostring(err))
            end
        end
    end
end

-- Register a message handler
function Network.registerHandler(msg_type, handler)
    if type(handler) ~= "function" then
        return false, "Handler must be a function"
    end
    
    if not Network.message_handlers[msg_type] then
        Network.message_handlers[msg_type] = {}
    end
    
    table.insert(Network.message_handlers[msg_type], handler)
    Core.log("DEBUG", "Registered handler for message type: " .. msg_type)
    
    return true
end

-- Send a message to a specific turtle
function Network.send(recipient, message)
    if not Network.initialized then
        return false, "Network not initialized"
    end
    
    -- Add timestamp
    message.timestamp = os.epoch("utc")
    message.from_control = true
    
    rednet.send(recipient, message, Network.PROTOCOL)
    Core.log("DEBUG", "Sent " .. (message.type or "unknown") .. " to turtle " .. recipient)
    
    return true
end

-- Broadcast a message to all turtles
function Network.broadcast(message)
    if not Network.initialized then
        return false, "Network not initialized"
    end
    
    -- Add timestamp
    message.timestamp = os.epoch("utc")
    message.from_control = true
    
    rednet.broadcast(message, Network.PROTOCOL)
    Core.log("DEBUG", "Broadcast " .. (message.type or "unknown") .. " to all turtles")
    
    return true
end

-- Send a command to a specific turtle
function Network.sendCommand(turtle_id, command, data)
    return Network.send(turtle_id, {
        type = "command",
        command = command,
        data = data
    })
end

-- Request status from a specific turtle
function Network.requestStatus(turtle_id)
    return Network.send(turtle_id, {
        type = "status_request"
    })
end

-- Request status from all turtles
function Network.requestAllStatus()
    return Network.broadcast({
        type = "status_request"
    })
end

-- Send emergency stop to all turtles
function Network.emergencyStopAll(reason)
    Core.log("CRITICAL", "Emergency stop all turtles: " .. (reason or "Unknown"))
    
    return Network.broadcast({
        type = "command",
        command = "emergency_stop",
        data = {
            reason = reason or "Control computer emergency stop"
        }
    })
end

-- Get network statistics
function Network.getStats()
    return {
        initialized = Network.initialized,
        computer_id = Network.COMPUTER_ID,
        protocol = Network.PROTOCOL,
        modem_side = Network.modem_side,
        modem_type = Network.modem and (Network.modem.isWireless and Network.modem.isWireless() and "wireless" or "wired") or "none",
        heartbeat_timeout = Network.HEARTBEAT_TIMEOUT,
        handlers_registered = Core.tableKeys(Network.message_handlers)
    }
end

-- Shutdown network
function Network.shutdown()
    Core.log("INFO", "Network shutting down")
    
    -- Unhost service
    rednet.unhost(Network.PROTOCOL)
    
    -- Close modem
    if Network.modem_side then
        rednet.close(Network.modem_side)
    end
    
    Network.initialized = false
    Network.event_listener_active = false
    Network.message_handlers = {}
    
    return true
end

return Network