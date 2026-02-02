--[[
    Standard Preset
    Balanced protection for most use cases
]]

return {
    name = "standard",
    description = "Balanced protection for most use cases",
    
    config = {
        minify = true,
        
        layers = {
            stringEncryption = true,
            controlFlow = true,
            virtualization = false,
            antiTamper = true,
            antiDump = false,
            mutation = true,
            decoys = true,
        },
        
        stringEncryption = {
            method = "multi",
            keyLength = 24,
            splitStrings = true,
        },
        
        controlFlow = {
            flattenIntensity = 0.5,
            opaquePredicates = true,
            bogusBranches = true,
        },
        
        antiTamper = {
            integrityCheck = true,
            environmentCheck = true,
            checksumVerify = false,
        },
        
        mutation = {
            renameVariables = true,
            renameLength = 12,
            deadCodeInjection = true,
            deadCodeDensity = 0.2,
            expressionMutation = true,
        },
        
        decoys = {
            fakeFunctions = 10,
            fakeStrings = 15,
            honeyTraps = true,
            fakeApiCalls = false,
        },
    },
}
