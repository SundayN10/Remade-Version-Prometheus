--[[
    Luartex Configuration System
]]

local Config = {}

-- Default configuration
Config.defaults = {
    -- Logging
    logLevel = "info",  -- debug, info, warn, error, none
    
    -- Randomization
    seed = nil,  -- nil = use os.time()
    
    -- Output
    minify = true,
    addWatermark = true,
    watermark = "-- Protected by Luartex Obfuscator | discord.gg/GpucUKeCtF",
    
    -- Layer toggles
    layers = {
        stringEncryption = true,
        controlFlow = true,
        virtualization = false,  -- Heavy, optional
        antiTamper = true,
        antiDump = true,
        mutation = true,
        decoys = true,
    },
    
    -- String encryption settings
    stringEncryption = {
        method = "multi",      -- xor, aes, multi
        keyLength = 32,
        splitStrings = true,
        minSplitLength = 3,
    },
    
    -- Control flow settings
    controlFlow = {
        flattenIntensity = 0.8,
        opaquePredicates = true,
        bogusBranches = true,
        maxStates = 100,
    },
    
    -- Virtualization settings
    virtualization = {
        instructionCount = 64,
        registerCount = 32,
        polymorphic = true,
    },
    
    -- Anti-tamper settings
    antiTamper = {
        integrityCheck = true,
        environmentCheck = true,
        checksumVerify = true,
        crashOnDetect = true,
    },
    
    -- Anti-dump settings
    antiDump = {
        memoryProtection = true,
        chunkEncryption = true,
        antiDebug = true,
    },
    
    -- Mutation settings
    mutation = {
        renameVariables = true,
        renameLength = 16,
        deadCodeInjection = true,
        deadCodeDensity = 0.3,
        expressionMutation = true,
    },
    
    -- Decoy settings
    decoys = {
        fakeFunctions = 20,
        fakeStrings = 30,
        honeyTraps = true,
        fakeApiCalls = true,
    },
    
    -- Roblox-specific
    roblox = {
        enabled = false,
        executor = "auto",
        safeMode = true,
    },
}

-- Merge configurations
function Config.merge(base, override)
    local result = {}
    
    for k, v in pairs(base) do
        if type(v) == "table" and type(override[k]) == "table" then
            result[k] = Config.merge(v, override[k])
        elseif override[k] ~= nil then
            result[k] = override[k]
        else
            result[k] = v
        end
    end
    
    for k, v in pairs(override) do
        if result[k] == nil then
            result[k] = v
        end
    end
    
    return result
end

-- Validate configuration
function Config.validate(config)
    local errors = {}
    
    if config.stringEncryption.keyLength < 8 then
        table.insert(errors, "Key length must be at least 8")
    end
    
    if config.controlFlow.flattenIntensity < 0 or config.controlFlow.flattenIntensity > 1 then
        table.insert(errors, "Flatten intensity must be between 0 and 1")
    end
    
    return #errors == 0, errors
end

return Config
