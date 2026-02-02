--[[
    Environment Check Generator
    Verifies the execution environment
]]

local EnvironmentCheck = {}
EnvironmentCheck.__index = EnvironmentCheck

function EnvironmentCheck.new(parent)
    local self = setmetatable({}, EnvironmentCheck)
    
    self.parent = parent
    self.random = parent.random
    self.config = parent.parent.config
    
    return self
end

function EnvironmentCheck:generate()
    local envVar = self.random:identifier(14)
    local checkVar = self.random:identifier(12)
    
    local checks = {}
    
    -- Check for required globals
    table.insert(checks, [[
        if type(_G) ~= "table" then return false end
        if type(tostring) ~= "function" then return false end
        if type(tonumber) ~= "function" then return false end
        if type(type) ~= "function" then return false end
        if type(pairs) ~= "function" then return false end
        if type(ipairs) ~= "function" then return false end
    ]])
    
    -- Check string library
    table.insert(checks, [[
        if type(string) ~= "table" then return false end
        if type(string.sub) ~= "function" then return false end
        if type(string.byte) ~= "function" then return false end
        if type(string.char) ~= "function" then return false end
    ]])
    
    -- Check table library
    table.insert(checks, [[
        if type(table) ~= "table" then return false end
        if type(table.insert) ~= "function" then return false end
        if type(table.concat) ~= "function" then return false end
    ]])
    
    -- Check math library
    table.insert(checks, [[
        if type(math) ~= "table" then return false end
        if type(math.floor) ~= "function" then return false end
        if type(math.random) ~= "function" then return false end
    ]])
    
    -- Roblox-specific checks
    if self.config.roblox and self.config.roblox.enabled then
        table.insert(checks, [[
            if type(game) ~= "userdata" then return false end
            if type(workspace) ~= "userdata" then return false end
            if type(Instance) ~= "table" then return false end
        ]])
    end
    
    local code = string.format([[
do
    local %s = function()
        %s
        return true
    end
    
    local %s = %s()
    if not %s then
        local x = 0
        while true do
            x = x + 1
            if x > 1000000000 then break end
        end
        error("")
    end
end
]], envVar, table.concat(checks, "\n        "),
    checkVar, envVar, checkVar)
    
    return code
end

return EnvironmentCheck
