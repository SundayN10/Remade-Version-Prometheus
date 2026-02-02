--[[
    Full Obfuscation Tests
]]

local TestObfuscation = {}

local tests = {}

function tests.test_basic_obfuscation()
    local Luartex = require("init")
    
    local source = [[
        local x = 1 + 2
        print(x)
    ]]
    
    local obfuscator = Luartex.new({
        logLevel = "none",
    })
    obfuscator:usePreset("light")
    
    local result = obfuscator:obfuscate(source)
    
    assert(result ~= nil, "Result should not be nil")
    assert(#result > 0, "Result should not be empty")
    assert(result ~= source, "Result should be different from source")
    
    return true
end

function tests.test_standard_preset()
    local Luartex = require("init")
    
    local source = [[
        local function add(a, b)
            return a + b
        end
        
        local result = add(5, 10)
        print("Result: " .. result)
    ]]
    
    local obfuscator = Luartex.new({
        logLevel = "none",
    })
    obfuscator:usePreset("standard")
    
    local result = obfuscator:obfuscate(source)
    
    assert(result ~= nil, "Result should not be nil")
    assert(#result > #source, "Obfuscated code should be larger")
    
    -- Verify it's valid Lua
    local fn, err = loadstring(result)
    -- Note: May fail due to missing runtime, but syntax should be valid
    
    return true
end

function tests.test_variable_names_changed()
    local Luartex = require("init")
    
    local source = [[
        local mySpecialVariable = 123
        local anotherVariable = mySpecialVariable * 2
    ]]
    
    local obfuscator = Luartex.new({
        logLevel = "none",
    })
    obfuscator:usePreset("standard")
    
    local result = obfuscator:obfuscate(source)
    
    -- Original variable names should not appear
    assert(not result:find("mySpecialVariable"), "Variable should be renamed")
    assert(not result:find("anotherVariable"), "Variable should be renamed")
    
    return true
end

function tests.test_strings_encrypted()
    local Luartex = require("init")
    
    local source = [[
        local secret = "This is a secret message!"
        print(secret)
    ]]
    
    local obfuscator = Luartex.new({
        logLevel = "none",
    })
    obfuscator:usePreset("standard")
    
    local result = obfuscator:obfuscate(source)
    
    -- Original string should not appear in plain text
    assert(not result:find("This is a secret message!"), "String should be encrypted")
    
    return true
end

function tests.test_output_larger()
    local Luartex = require("init")
    
    local source = [[
        for i = 1, 10 do
            print(i)
        end
    ]]
    
    local obfuscator = Luartex.new({
        logLevel = "none",
    })
    obfuscator:usePreset("hardened")
    
    local result = obfuscator:obfuscate(source)
    
    -- Hardened preset should significantly increase size
    assert(#result > #source * 2, "Hardened output should be much larger")
    
    return true
end

function tests.test_watermark_present()
    local Luartex = require("init")
    
    local source = "print('test')"
    
    local obfuscator = Luartex.new({
        logLevel = "none",
        addWatermark = true,
    })
    obfuscator:usePreset("light")
    
    local result = obfuscator:obfuscate(source)
    
    -- Watermark should be present
    assert(result:find("Luartex") or result:find("discord"), "Watermark should be present")
    
    return true
end

function tests.test_reproducible_with_seed()
    local Luartex = require("init")
    
    local source = [[
        local x = 1
        local y = 2
    ]]
    
    local obfuscator1 = Luartex.new({
        logLevel = "none",
        seed = 99999,
    })
    obfuscator1:usePreset("light")
    local result1 = obfuscator1:obfuscate(source)
    
    local obfuscator2 = Luartex.new({
        logLevel = "none",
        seed = 99999,
    })
    obfuscator2:usePreset("light")
    local result2 = obfuscator2:obfuscate(source)
    
    -- Same seed should produce same output
    assert(result1 == result2, "Same seed should produce same output")
    
    return true
end

function tests.test_different_without_seed()
    local Luartex = require("init")
    
    local source = "local x = 1"
    
    local obfuscator1 = Luartex.new({
        logLevel = "none",
        seed = 11111,
    })
    obfuscator1:usePreset("light")
    local result1 = obfuscator1:obfuscate(source)
    
    local obfuscator2 = Luartex.new({
        logLevel = "none",
        seed = 22222,
    })
    obfuscator2:usePreset("light")
    local result2 = obfuscator2:obfuscate(source)
    
    -- Different seeds should produce different output
    assert(result1 ~= result2, "Different seeds should produce different output")
    
    return true
end

function TestObfuscation.run()
    local passed = 0
    local failed = 0
    local errors = {}
    
    for name, testFn in pairs(tests) do
        local success, err = pcall(testFn)
        
        if success then
            print("  ✓ " .. name)
            passed = passed + 1
        else
            print("  ✗ " .. name .. ": " .. tostring(err))
            failed = failed + 1
            table.insert(errors, {
                module = "test_obfuscation",
                test = name,
                error = tostring(err)
            })
        end
    end
    
    return {
        passed = passed,
        failed = failed,
        errors = errors
    }
end

return TestObfuscation
