--[[
    Fake Functions Generator
    Generates fake functions that are never called
]]

local AST = require("core.ast")

local FakeFunctions = {}
FakeFunctions.__index = FakeFunctions

function FakeFunctions.new(parent)
    local self = setmetatable({}, FakeFunctions)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function FakeFunctions:inject(ast, count)
    local functions = {}
    
    for _ = 1, count do
        local func = self:generateFakeFunction()
        table.insert(functions, func)
    end
    
    -- Shuffle and insert at random positions
    self.random:shuffle(functions)
    
    for _, func in ipairs(functions) do
        local position = self.random:int(1, #ast.body + 1)
        table.insert(ast.body, position, func)
    end
    
    return ast
end

function FakeFunctions:generateFakeFunction()
    local funcName = self.random:identifier(self.random:int(10, 18))
    local paramCount = self.random:int(0, 4)
    local params = {}
    
    for i = 1, paramCount do
        table.insert(params, AST.identifier(self.random:identifier(8)))
    end
    
    local body = self:generateFakeBody(params)
    
    return AST.functionDeclaration(
        AST.identifier(funcName),
        params,
        body,
        true  -- local
    )
end

function FakeFunctions:generateFakeBody(params)
    local body = {}
    local statementCount = self.random:int(3, 10)
    
    for _ = 1, statementCount do
        local stmt = self:generateFakeStatement(params)
        table.insert(body, stmt)
    end
    
    -- Add return
    table.insert(body, self:generateFakeReturn(params))
    
    return body
end

function FakeFunctions:generateFakeStatement(params)
    local generators = {
        function(self, params)
            -- Local variable
            local varName = self.random:identifier(10)
            return AST.localStatement(
                { AST.identifier(varName) },
                { AST.numberLiteral(self.random:int(1, 10000)) }
            )
        end,
        
        function(self, params)
            -- If statement
            return AST.ifStatement({
                AST.ifClause(
                    AST.binaryExpression(">",
                        AST.numberLiteral(self.random:int(1, 100)),
                        AST.numberLiteral(self.random:int(1, 100))
                    ),
                    {
                        AST.localStatement(
                            { AST.identifier(self.random:identifier(8)) },
                            { AST.stringLiteral(self.random:string(15)) }
                        )
                    }
                )
            })
        end,
        
        function(self, params)
            -- For loop
            local counter = self.random:identifier(6)
            return AST.forNumericStatement(
                AST.identifier(counter),
                AST.numberLiteral(1),
                AST.numberLiteral(self.random:int(5, 20)),
                nil,
                {
                    AST.localStatement(
                        { AST.identifier(self.random:identifier(8)) },
                        {
                            AST.binaryExpression("*",
                                AST.identifier(counter),
                                AST.numberLiteral(2)
                            )
                        }
                    )
                }
            )
        end,
        
        function(self, params)
            -- Table operation
            local tableName = self.random:identifier(10)
            return AST.doStatement({
                AST.localStatement(
                    { AST.identifier(tableName) },
                    { AST.tableExpression({}) }
                ),
                AST.assignmentStatement(
                    {
                        AST.indexExpression(
                            AST.identifier(tableName),
                            AST.numberLiteral(1)
                        )
                    },
                    { AST.stringLiteral(self.random:string(10)) }
                )
            })
        end,
    }
    
    local generator = generators[self.random:int(1, #generators)]
    return generator(self, params)
end

function FakeFunctions:generateFakeReturn(params)
    local returnType = self.random:int(1, 4)
    
    if returnType == 1 then
        return AST.returnStatement({ AST.numberLiteral(self.random:int(0, 1000)) })
    elseif returnType == 2 then
        return AST.returnStatement({ AST.stringLiteral(self.random:string(10)) })
    elseif returnType == 3 then
        return AST.returnStatement({ AST.booleanLiteral(self.random:bool()) })
    else
        return AST.returnStatement({ AST.tableExpression({}) })
    end
end

return FakeFunctions
