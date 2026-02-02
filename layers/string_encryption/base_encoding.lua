--[[
    Base Encoding Utilities
]]

local BaseEncoding = {}

local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function BaseEncoding.encode(data)
    local result = {}
    local padding = ""
    
    local mod = #data % 3
    if mod > 0 then
        padding = string.rep("=", 3 - mod)
        data = data .. string.rep("\0", 3 - mod)
    end
    
    for i = 1, #data, 3 do
        local b1, b2, b3 = string.byte(data, i, i + 2)
        local n = b1 * 65536 + b2 * 256 + b3
        
        table.insert(result, B64_CHARS:sub(math.floor(n / 262144) + 1, math.floor(n / 262144) + 1))
        table.insert(result, B64_CHARS:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1))
        table.insert(result, B64_CHARS:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1))
        table.insert(result, B64_CHARS:sub(n % 64 + 1, n % 64 + 1))
    end
    
    local encoded = table.concat(result)
    return encoded:sub(1, #encoded - #padding) .. padding
end

function BaseEncoding.decode(data)
    local lookup = {}
    for i = 1, #B64_CHARS do
        lookup[B64_CHARS:sub(i, i)] = i - 1
    end
    
    data = data:gsub("=", "")
    local result = {}
    
    for i = 1, #data, 4 do
        local a = lookup[data:sub(i, i)] or 0
        local b = lookup[data:sub(i + 1, i + 1)] or 0
        local c = lookup[data:sub(i + 2, i + 2)] or 0
        local d = lookup[data:sub(i + 3, i + 3)] or 0
        
        local n = a * 262144 + b * 4096 + c * 64 + d
        
        table.insert(result, string.char(math.floor(n / 65536) % 256))
        if i + 2 <= #data then
            table.insert(result, string.char(math.floor(n / 256) % 256))
        end
        if i + 3 <= #data then
            table.insert(result, string.char(n % 256))
        end
    end
    
    return table.concat(result)
end

-- Custom base encoding with shuffled alphabet
function BaseEncoding.encodeCustom(data, alphabet)
    alphabet = alphabet or B64_CHARS
    local result = {}
    
    for i = 1, #data, 3 do
        local b1 = string.byte(data, i) or 0
        local b2 = string.byte(data, i + 1) or 0
        local b3 = string.byte(data, i + 2) or 0
        
        local n = b1 * 65536 + b2 * 256 + b3
        
        table.insert(result, alphabet:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1))
        table.insert(result, alphabet:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1))
        table.insert(result, alphabet:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1))
        table.insert(result, alphabet:sub(n % 64 + 1, n % 64 + 1))
    end
    
    return table.concat(result)
end

return BaseEncoding
