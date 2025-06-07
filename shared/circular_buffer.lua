-- Circular Buffer Implementation for Ultimate Miner
-- Memory-efficient circular buffer for history tracking

local circular_buffer = {}
circular_buffer.__index = circular_buffer

-- Create a new circular buffer
function circular_buffer.new(max_size)
    local self = setmetatable({}, circular_buffer)
    
    self.buffer = {}
    self.max_size = max_size or 500
    self.head = 1  -- Next write position
    self.tail = 1  -- Oldest item position
    self.count = 0
    self.version = 1  -- For change tracking
    
    return self
end

-- Add item to buffer
function circular_buffer:push(item)
    -- Store item at head position
    self.buffer[self.head] = item
    
    -- Update count
    if self.count < self.max_size then
        self.count = self.count + 1
    else
        -- Buffer is full, advance tail
        self.tail = self.tail % self.max_size + 1
    end
    
    -- Advance head
    self.head = self.head % self.max_size + 1
    
    -- Increment version for change tracking
    self.version = self.version + 1
end

-- Get item by index (1-based from oldest)
function circular_buffer:get(index)
    if index < 1 or index > self.count then
        return nil
    end
    
    -- Calculate actual position in buffer
    local pos = (self.tail + index - 2) % self.max_size + 1
    return self.buffer[pos]
end

-- Get most recent item
function circular_buffer:peek()
    if self.count == 0 then
        return nil
    end
    
    -- Head points to next write position, so go back one
    local pos = (self.head - 2) % self.max_size + 1
    return self.buffer[pos]
end

-- Get oldest item
function circular_buffer:peekOldest()
    if self.count == 0 then
        return nil
    end
    
    return self.buffer[self.tail]
end

-- Remove and return most recent item
function circular_buffer:pop()
    if self.count == 0 then
        return nil
    end
    
    -- Move head back
    self.head = (self.head - 2) % self.max_size + 1
    local item = self.buffer[self.head]
    self.buffer[self.head] = nil
    
    self.count = self.count - 1
    self.version = self.version + 1
    
    return item
end

-- Get all items as array (oldest to newest)
function circular_buffer:toArray()
    local array = {}
    
    for i = 1, self.count do
        array[i] = self:get(i)
    end
    
    return array
end

-- Get recent items (last N)
function circular_buffer:getRecent(n)
    n = math.min(n or 10, self.count)
    local result = {}
    
    for i = self.count - n + 1, self.count do
        table.insert(result, self:get(i))
    end
    
    return result
end

-- Clear buffer
function circular_buffer:clear()
    self.buffer = {}
    self.head = 1
    self.tail = 1
    self.count = 0
    self.version = self.version + 1
end

-- Get buffer size
function circular_buffer:size()
    return self.count
end

-- Check if buffer is empty
function circular_buffer:isEmpty()
    return self.count == 0
end

-- Check if buffer is full
function circular_buffer:isFull()
    return self.count >= self.max_size
end

-- Resize buffer (preserves most recent items if shrinking)
function circular_buffer:resize(new_size)
    if new_size == self.max_size then
        return
    end
    
    -- Get current items
    local items = self:toArray()
    
    -- Clear and resize
    self.buffer = {}
    self.max_size = new_size
    self.head = 1
    self.tail = 1
    self.count = 0
    
    -- Re-add items (keeping most recent if needed)
    local start = math.max(1, #items - new_size + 1)
    for i = start, #items do
        self:push(items[i])
    end
    
    self.version = self.version + 1
end

-- Find item in buffer
function circular_buffer:find(predicate)
    for i = 1, self.count do
        local item = self:get(i)
        if predicate(item, i) then
            return item, i
        end
    end
    return nil
end

-- Filter items
function circular_buffer:filter(predicate)
    local result = {}
    
    for i = 1, self.count do
        local item = self:get(i)
        if predicate(item, i) then
            table.insert(result, item)
        end
    end
    
    return result
end

-- Apply function to all items
function circular_buffer:forEach(func)
    for i = 1, self.count do
        func(self:get(i), i)
    end
end

-- Get memory usage estimate
function circular_buffer:getMemoryUsage()
    -- Estimate based on stored items
    local item_size = 0
    
    if self.count > 0 then
        -- Sample first item
        local sample = self:get(1)
        if type(sample) == "table" then
            -- Rough estimate: 32 bytes per table entry
            item_size = 32
            for k, v in pairs(sample) do
                if type(v) == "string" then
                    item_size = item_size + #v
                elseif type(v) == "number" then
                    item_size = item_size + 8
                end
            end
        elseif type(sample) == "string" then
            item_size = #sample + 24
        else
            item_size = 8
        end
    end
    
    return {
        buffer_size = self.max_size,
        used_slots = self.count,
        estimated_bytes = self.count * item_size,
        overhead_bytes = 64 + (self.max_size * 8)  -- Buffer structure overhead
    }
end

-- Compact buffer (remove nil entries if any)
function circular_buffer:compact()
    local items = self:toArray()
    self:clear()
    
    for _, item in ipairs(items) do
        if item ~= nil then
            self:push(item)
        end
    end
end

-- Iterator function
function circular_buffer:iter()
    local i = 0
    return function()
        i = i + 1
        if i <= self.count then
            return i, self:get(i)
        end
    end
end

-- Serialize for persistence
function circular_buffer:serialize()
    return {
        buffer = self:toArray(),
        max_size = self.max_size,
        version = self.version
    }
end

-- Deserialize from persistence
function circular_buffer.deserialize(data)
    local buffer = circular_buffer.new(data.max_size)
    
    for _, item in ipairs(data.buffer or {}) do
        buffer:push(item)
    end
    
    buffer.version = data.version or 1
    return buffer
end

return circular_buffer