--[[
    Integrity Check Generator
    Generates code that verifies script integrity
]]

local IntegrityCheck = {}
IntegrityCheck.__index = IntegrityCheck

function IntegrityCheck.new(parent)
    local self = setmetatable({}, IntegrityCheck)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function IntegrityCheck:generate()
    local checkVar = self.random:identifier(16)
    local funcVar = self.random:identifier(14)
    local resultVar = self.random:identifier(12)
    
    local code = string.format([[
do
    local %s = function()
        local %s = true
        
        -- Check for debugger
        if debug and debug.sethook then
            local h = debug.gethook and debug.gethook()
            if h then
                %s = false
            end
        end
        
        -- Check for getinfo manipulation
        if debug and debug.getinfo then
            local i = debug.getinfo(1)
            if not i or i.what ~= "Lua" then
                %s = false
            end
        end
        
        -- Check string.dump availability (bytecode dumping)
        if string.dump then
            local ok, err = pcall(function()
                local f = function() end
                local d = string.dump(f)
                if #d < 10 then
                    %s = false
                end
            end)
        end
        
        -- Verify math functions haven't been tampered
        if math.floor(3.7) ~= 3 then
            %s = false
        end
        
        if math.abs(-5) ~= 5 then
            %s = false
        end
        
        -- Check tostring
        if tostring(123) ~= "123" then
            %s = false
        end
        
        return %s
    end
    
    if not %s() then
        while true do end  -- Infinite loop on detection
    end
end
]], funcVar, resultVar,
    resultVar, resultVar, resultVar, resultVar, resultVar, resultVar, resultVar,
    funcVar)
    
    return code
end

return IntegrityCheck
