--[[
    Self-Verification
    Code that verifies its own integrity
]]

local SelfVerify = {}
SelfVerify.__index = SelfVerify

function SelfVerify.new(parent)
    local self = setmetatable({}, SelfVerify)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function SelfVerify:generate()
    local funcVar = self.random:identifier(16)
    local keyVar = self.random:identifier(12)
    
    local key = self.random:int(10000, 99999)
    local expected = (key * 7 + 13) % 1000
    
    local code = string.format([[
do
    local %s = %d
    local %s = function()
        local result = (%s * 7 + 13) %% 1000
        return result == %d
    end
    
    if not %s() then
        local _ = nil
        _()  -- Crash
    end
end
]], keyVar, key, funcVar, keyVar, expected, funcVar)
    
    return code
end

return SelfVerify
