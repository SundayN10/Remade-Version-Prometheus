--[[
    Parser Tests
]]

local TestParser = {}

local Parser = require("core.parser")
local AST = require("core.ast")

local tests = {}

function tests.test_parse_simple()
    local source = "local x = 1"
    local ast = Parser.parse(source)
    
    assert(ast ~= nil, "AST should not be nil")
    assert(ast.type == AST.NodeType.CHUNK, "Root should be Chunk")
    assert(#ast.body == 1, "Should have 1 statement")
    assert(ast.body[1].type == AST.NodeType.LOCAL_STATEMENT, "Should be LocalStatement")
    
    return true
end

function tests.test_parse_function()
    local source = [[
        local function test(a, b)
            return a + b
        end
    ]]
    local ast = Parser.parse(source)
    
    assert(ast ~= nil, "AST should not be nil")
    assert(#ast.body == 1, "Should have 1 statement")
    assert(ast.body[1].type == AST.NodeType.FUNCTION_DECLARATION, "Should be FunctionDeclaration")
    assert(ast.body[1].isLocal == true, "Should be local")
    assert(#ast.body[1].parameters == 2, "Should have 2 parameters")
    
    return true
end

function tests.test_parse_if_statement()
    local source = [[
        if x > 0 then
            print("positive")
        elseif x < 0 then
            print("negative")
        else
            print("zero")
        end
    ]]
    local ast = Parser.parse(source)
    
    assert(ast ~= nil, "AST should not be nil")
    assert(#ast.body == 1, "Should have 1 statement")
    assert(ast.body[1].type == AST.NodeType.IF_STATEMENT, "Should be IfStatement")
    assert(#ast.body[1].clauses == 3, "Should have 3 clauses")
    
    return true
end

function tests.test_parse_for_loop()
    local source = [[
        for i = 1, 10 do
            print(i)
        end
    ]]
    local ast = Parser.parse(source)
    
    assert(ast ~= nil, "AST should not be nil")
    assert(ast.body[1].type == AST.NodeType.FOR_NUMERIC_STATEMENT, "Should be ForNumericStatement")
    
    return true
end

function tests.test_parse_table()
    local source = [[
        local t = {
            a = 1,
            b = "test",
            [1] = true,
        }
    ]]
    local ast = Parser.parse(source)
    
    assert(ast ~= nil, "AST should not be nil")
    assert(ast.body[1].type == AST.NodeType.LOCAL_STATEMENT, "Should be LocalStatement")
    
    local init = ast.body[1].init[1]
    assert(init.type == AST.NodeType.TABLE_EXPRESSION, "Should be TableExpression")
    assert(#init.fields == 3, "Should have 3 fields")
    
    return true
end

function tests.test_parse_complex()
    local source = [[
        local Calculator = {}
        Calculator.__index = Calculator
        
        function Calculator.new()
            return setmetatable({value = 0}, Calculator)
        end
        
        function Calculator:add(n)
            self.value = self.value + n
            return self
        end
        
        local calc = Calculator.new()
        calc:add(5):add(10)
        print(calc.value)
    ]]
    local ast = Parser.parse(source)
    
    assert(ast ~= nil, "AST should not be nil")
    assert(#ast.body > 0, "Should have statements")
    
    return true
end

function TestParser.run()
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
                module = "test_parser",
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

return TestParser
