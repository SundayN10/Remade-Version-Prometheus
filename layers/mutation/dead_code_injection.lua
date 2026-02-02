--[[
    Dead Code Injection
    Injects code that never executes to confuse analysis
]]

local AST = require("core.ast")

local DeadCodeInjection = {}
DeadCodeInjection.__index = DeadCodeInjection

function DeadCodeInjection.new(parent)
    local self = setmetatable({}, DeadCodeInjection)
    
    self.parent = parent
    self.random = parent.random
    self.config = parent.config
    
    return self
end

function DeadCodeInjection:inject(ast)
    local self_ref = self
    
    AST.transform(ast, {
        [AST.NodeType.FUNCTION_DECLARATION] = function(node)
            self_ref:injectIntoBody(node.body)
            return node
        end,
        
        [AST.NodeType.FUNCTION_EXPRESSION] = function(node)
            self_ref:injectIntoBody(node.body)
            return node
        end,
    })
    
    return ast
end

function DeadCodeInjection:injectIntoBody(body)
    if not body or #body == 0 then
        return
    end
    
    local density = self.config.deadCodeDensity or 0.3
    local injectCount = math.floor(#body * density)
    
    for _ = 1, injectCount do
        local position = self.random:int(1, #body + 1)
        local deadCode = self:generateDeadCode()
        table.insert(body, position, deadCode)
    end
end

function DeadCodeInjection:generateDeadCode()
    local generators = {
        self.generateDeadVariable,
        self.generateDeadIf,
        self.generateDeadLoop,
        self.generateDeadFunction,
        self.generateDeadCalculation,
        self.generateDeadTableOp,
    }
    
    local generator = generators[self.random:int(1, #generators)]
    return generator(self)
end

function DeadCodeInjection:generateDeadVariable()
    local varName = self.random:identifier(12)
    local value
    
    local valueType = self.random:int(1, 4)
    if valueType == 1 then
        value = AST.numberLiteral(self.random:int(-10000, 10000))
    elseif valueType == 2 then
        value = AST.stringLiteral(self.random:string(self.random:int(5, 20)))
    elseif valueType == 3 then
        value = AST.booleanLiteral(self.random:bool())
    else
        value = AST.tableExpression({})
    end
    
    return AST.localStatement(
        { AST.identifier(varName) },
        { value }
    )
end

function DeadCodeInjection:generateDeadIf()
    -- if false then ... end (never executes)
    local condition = AST.booleanLiteral(false)
    
    local fakeBody = {
        self:generateDeadVariable(),
        AST.callStatement(
            AST.callExpression(
                AST.identifier(self.random:identifier(10)),
                { AST.numberLiteral(self.random:int(1, 1000)) }
            )
        )
    }
    
    return AST.ifStatement({
        AST.ifClause(condition, fakeBody)
    })
end

function DeadCodeInjection:generateDeadLoop()
    local counter = self.random:identifier(10)
    
    -- for i = 1, 0 do ... end (never executes, 1 > 0)
    return AST.forNumericStatement(
        AST.identifier(counter),
        AST.numberLiteral(1),
        AST.numberLiteral(0),
        nil,
        {
            AST.callStatement(
                AST.callExpression(
                    AST.identifier("print"),
                    { AST.identifier(counter) }
                )
            )
        }
    )
end

function DeadCodeInjection:generateDeadFunction()
    local funcName = self.random:identifier(14)
    local paramName = self.random:identifier(8)
    
    return AST.functionDeclaration(
        AST.identifier(funcName),
        { AST.identifier(paramName) },
        {
            AST.returnStatement({
                AST.binaryExpression("+",
                    AST.identifier(paramName),
                    AST.numberLiteral(self.random:int(1, 100))
                )
            })
        },
        true  -- local
    )
end

function DeadCodeInjection:generateDeadCalculation()
    local varName = self.random:identifier(10)
    local a = self.random:int(1, 1000)
    local b = self.random:int(1, 1000)
    
    local ops = { "+", "-", "*", "/" }
    local op = ops[self.random:int(1, #ops)]
    
    return AST.localStatement(
        { AST.identifier(varName) },
        {
            AST.binaryExpression(op,
                AST.numberLiteral(a),
                AST.numberLiteral(b)
            )
        }
    )
end

function DeadCodeInjection:generateDeadTableOp()
    local tableName = self.random:identifier(12)
    local keyName = self.random:identifier(8)
    
    return AST.doStatement({
        AST.localStatement(
            { AST.identifier(tableName) },
            { AST.tableExpression({}) }
        ),
        AST.assignmentStatement(
            {
                AST.indexExpression(
                    AST.identifier(tableName),
                    AST.stringLiteral(keyName)
                )
            },
            { AST.numberLiteral(self.random:int(1, 1000)) }
        )
    })
end

return DeadCodeInjection
