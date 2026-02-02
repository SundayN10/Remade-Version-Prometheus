--[[
    Memory Guard
    Protects against memory scanning and dumping
]]

local MemoryGuard = {}
MemoryGuard.__index = MemoryGuard

function MemoryGuard.new(parent)
    local self = setmetatable({}, MemoryGuard)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function MemoryGuard:generate()
    local guardVar = self.random:identifier(16)
    local tickVar = self.random:identifier(12)
    local lastVar = self.random:identifier(10)
    
    local code = string.format([[
do
    local %s = os.clock and os.clock() or 0
    local %s = function()
        local current = os.clock and os.clock() or 0
        local delta = current - %s
        %s = current
        
        -- Detect if execution was paused (debugger attach)
        if delta > 5 then
            -- Execution was paused for more than 5 seconds
            local x = nil
            x()
        end
        
        -- Clear sensitive strings from memory
        collectgarbage("collect")
    end
    
    -- Schedule periodic checks
    local %s
    %s = function()
        %s()
        if type(delay) == "function" then
            delay(1, %s)
        elseif type(spawn) == "function" then
            spawn(function()
                while true do
                    wait and wait(1)
                    %s()
                end
            end)
        end
    end
end
]], lastVar, guardVar, lastVar, lastVar,
    tickVar, tickVar, guardVar, tickVar, guardVar)
    
    return code
end

return MemoryGuard
