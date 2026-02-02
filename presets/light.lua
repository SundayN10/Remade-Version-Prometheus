--[[
    Light Preset
    Fast obfuscation with basic protection
]]

return {
    name = "light",
    description = "Fast obfuscation with basic protection",
    
    config = {
        minify = true,
        
        layers = {
            stringEncryption = true,
            controlFlow = false,
            virtualization = false,
            antiTamper = false,
            antiDump = false,
            mutation = true,
            decoys = false,
        },
        
        stringEncryption = {
            method = "xor",
            keyLength = 16,
        },
        
        mutation = {
            renameVariables = true,
            renameLength = 8,
            deadCodeInjection = false,
            expressionMutation = false,
        },
    },
}
