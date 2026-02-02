--[[
    Luartex String Decoder Runtime
]]

local Decoder = {}

-- XOR decode
function Decoder.xor(data, key)
    local result = {}
    local keyLen = #key
    
    for i = 1, #data do
        local keyIdx = ((i - 1) % keyLen) + 1
        local dataByte = string.byte(data, i)
        local keyByte = string.byte(key, keyIdx)
        result[i] = string.char(dataByte ~ keyByte)
    end
    
    return table.concat(result)
end

-- Base64 decode
function Decoder.base64(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    
    for i = 1, 64 do
        lookup[b:sub(i, i):byte()] = i - 1
    end
    
    data = data:gsub("[^" .. b .. "=]", "")
    local result = {}
    
    for i = 1, #data, 4 do
        local a = lookup[data:byte(i)] or 0
        local b = lookup[data:byte(i + 1)] or 0
        local c = lookup[data:byte(i + 2)] or 0
        local d = lookup[data:byte(i + 3)] or 0
        
        local n = a * 262144 + b * 4096 + c * 64 + d
        
        table.insert(result, string.char(math.floor(n / 65536) % 256))
        if data:sub(i + 2, i + 2) ~= "=" then
            table.insert(result, string.char(math.floor(n / 256) % 256))
        end
        if data:sub(i + 3, i + 3) ~= "=" then
            table.insert(result, string.char(n % 256))
        end
    end
    
    return table.concat(result)
end

-- Multi-layer decode
function Decoder.multi(data, key)
    -- Base64 decode
    local step1 = Decoder.base64(data)
    
    -- XOR with reversed key
    local key2 = key:reverse()
    local step2 = Decoder.xor(step1, key2)
    
    -- Reverse
    local step3 = step2:reverse()
    
    -- Base64 decode again
    local step4 = Decoder.base64(step3)
    
    -- XOR with original key
    local step5 = Decoder.xor(step4, key)
    
    return step5
end

return Decoder
