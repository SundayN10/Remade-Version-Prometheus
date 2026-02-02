--[[
    Runtime Decryption
    Encrypts code that's decrypted at runtime
]]

local Utils = require("core.utils")

local RuntimeDecrypt = {}
RuntimeDecrypt.__index = RuntimeDecrypt

function RuntimeDecrypt.new(parent)
    local self = setmetatable({}, RuntimeDecrypt)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function RuntimeDecrypt:encrypt(source)
    -- Generate encryption key
    local key = self.random:string(32)
    
    -- XOR encrypt the source
    local encrypted = Utils.xor(source, key)
    
    -- Base64 encode
    local encoded = Utils.base64Encode(encrypted)
    
    -- Generate decryption code
    local decryptorCode = self:generateDecryptor(encoded, key)
    
    return decryptorCode
end

function RuntimeDecrypt:generateDecryptor(encoded, key)
    local keyEscaped = Utils.escapeLuaString(key)
    local encodedEscaped = Utils.escapeLuaString(encoded)
    
    local decVar = self.random:identifier(14)
    local xorVar = self.random:identifier(12)
    local b64Var = self.random:identifier(12)
    local keyVar = self.random:identifier(10)
    local dataVar = self.random:identifier(10)
    
    local code = string.format([[
do
    local %s = "%s"
    local %s = "%s"
    
    local %s = function(d)
        local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local r = {}
        d = d:gsub("[^" .. b .. "=]", "")
        
        for i = 1, #d, 4 do
            local a, b, c, d = d:byte(i, i + 3)
            local lookup = {}
            for j = 1, 64 do lookup[b:sub(j,j):byte()] = j - 1 end
            
            a = lookup[a] or 0
            b = lookup[b] or 0
            c = lookup[c] or 0
            d = lookup[d] or 0
            
            local n = a * 262144 + b * 4096 + c * 64 + d
            r[#r + 1] = string.char(math.floor(n / 65536) %% 256)
            if c then r[#r + 1] = string.char(math.floor(n / 256) %% 256) end
            if d then r[#r + 1] = string.char(n %% 256) end
        end
        
        return table.concat(r)
    end
    
    local %s = function(s, k)
        local r = {}
        for i = 1, #s do
            local ki = ((i - 1) %% #k) + 1
            r[i] = string.char(string.byte(s, i) ~ string.byte(k, ki))
        end
        return table.concat(r)
    end
    
    local %s = %s(%s(%s), %s)
    local fn, err = loadstring(%s)
    if fn then
        fn()
    else
        error(err)
    end
end
]], keyVar, keyEscaped, dataVar, encodedEscaped,
    b64Var, xorVar, decVar, xorVar, b64Var, dataVar, keyVar, decVar)
    
    return code
end

return RuntimeDecrypt
