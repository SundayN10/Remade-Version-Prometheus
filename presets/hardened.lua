--[[
    Hardened Preset
    Strong protection for sensitive code
]]

return {
    name = "hardened",
    description = "Strong protection for sensitive code",
    
    config = {
        minify = true,
        
        layers = {
            stringEncryption = true,
            controlFlow = true,
            virtualization = false,
            antiTamper = true,
            antiDump = true,
            mutation = true,
            decoys = true,
        },
        
        stringEncryption = {
            method = "multi",
            keyLength = 32,
            splitStrings = true,
            minSplitLength = 2,
        },
        
        controlFlow = {
            flattenIntensity = 0.7,
            opaquePredicates = true,
            bogusBranches = true,
            maxStates = 75,
        },
        
        antiTamper = {
            integrityCheck = true,
            environmentCheck = true,
            checksumVerify = true,
            crashOnDetect = true,
        },
        
        antiDump = {
            memoryProtection = true,
            chunkEncryption = true,
            antiDebug = true,
        },
        
        mutation = {
            renameVariables = true,
            renameLength = 16,
            deadCodeInjection = true,
            deadCodeDensity = 0.3,
            expressionMutation = true,
        },
        
        decoys = {
            fakeFunctions = 20,
            fakeStrings = 25,
            honeyTraps = true,
            fakeApiCalls = true,
        },
    },
}
