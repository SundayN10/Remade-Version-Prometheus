--[[
    Luartex Code Unpacker Runtime
]]

local Unpacker = {}

function Unpacker.unpack(chunks, decoder)
    local result = {}
    
    for i, chunk in ipairs(chunks) do
        local decoded = decoder(chunk.data, chunk.key)
        result[i] = decoded
    end
    
    return table.concat(result)
end

function Unpacker.loadAndRun(packedData, decoder)
    local source = Unpacker.unpack(packedData, decoder)
    
    local fn, err = loadstring(source)
    if fn then
        return fn()
    else
        error("Unpack failed: " .. tostring(err))
    end
end

return Unpacker
