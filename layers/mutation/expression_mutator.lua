--[[
    Expression Mutator
    Transforms expressions into equivalent but more complex forms
]]

local AST = require("core.ast")

local ExpressionMutator = {}
ExpressionMutator.__index = ExpressionMutator

function ExpressionMutator.new(parent)
    local self = setmetatable({}, ExpressionMutator)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function ExpressionMutator:mutate(ast)
    local self_ref = self
    
    AST.transform(ast, {
        [AST.NodeType.BINARY_EXPRESSION] = function(node)
            if self_ref.random:bool(0.4) then
                return self_ref:mutateBinary(node)
            end
            return node
        end,
        
        [AST.NodeType.BOOLEAN_LITERAL] = function(node)
            if self_ref.random:bool(0.5) then
                return self_ref:mutateBoolean(node)
            end
            return node
        end,
    })
    
    return ast
end

function ExpressionMutator:mutateBinary(node)
    local op = node.operator
    
    if op == "+" then
        -- a + b => a - (-b)
        if self.random:bool(0.3) then
            return AST.binaryExpression("-",
                node.left,
                AST.unaryExpression("-", node.right)
            )
        end
        
    elseif op == "-" then
        -- a - b => a + (-b)
        if self.random:bool(0.3) then
            return AST.binaryExpression("+",
                node.left,
                AST.unaryExpression("-", node.right)
            )
        end
        
    elseif op == "==" then
        -- a == b => not (a ~= b)
        if self.random:bool(0.3) then
            return AST.unaryExpression("not",
                AST.binaryExpression("~=", node.left, node.right)
            )
        end
        
    elseif op == "~=" then
        -- a ~= b => not (a == b)
        if self.random:bool(0.3) then
            return AST.unaryExpression("not",
                AST.binaryExpression("==", node.left, node.right)
            )
        end
        
    elseif op == "<" then
        -- a < b => not (a >= b)
        if self.random:bool(0.3) then
            return AST.unaryExpression("not",
                AST.binaryExpression(">=", node.left, node.right)
            )
        end
        
    elseif op == ">" then
        -- a > b => not (a <= b)
        if self.random:bool(0.3) then
            return AST.unaryExpression("not",
                AST.binaryExpression("<=", node.left, node.right)
            )
        end
        
    elseif op == "and" then
        -- a and b => not (not a or not b)
        if self.random:bool(0.2) then
            return AST.unaryExpression("not",
                AST.binaryExpression("or",
                    AST.unaryExpression("not", node.left),
                    AST.unaryExpression("not", node.right)
                )
            )
        end
        
    elseif op == "or" then
        -- a or b => not (not a and not b)
        if self.random:bool(0.2) then
            return AST.unaryExpression("not",
                AST.binaryExpression("and",
                    AST.unaryExpression("not", node.left),
                    AST.unaryExpression("not", node.right)
                )
            )
        end
    end
    
    return node
end

function ExpressionMutator:mutateBoolean(node)
    if node.value then
        -- true => not false
        local strategies = {
            function() return AST.unaryExpression("not", AST.booleanLiteral(false)) end,
            function() return AST.binaryExpression("==", AST.numberLiteral(1), AST.numberLiteral(1)) end,
            function() return AST.binaryExpression("~=", AST.numberLiteral(1), AST.numberLiteral(0)) end,
        }
        return strategies[self.random:int(1, #strategies)]()
    else
        -- false => not true
        local strategies = {
            function() return AST.unaryExpression("not", AST.booleanLiteral(true)) end,
            function() return AST.binaryExpression("==", AST.numberLiteral(1), AST.numberLiteral(0)) end,
            function() return AST.binaryExpression(">", AST.numberLiteral(0), AST.numberLiteral(1)) end,
        }
        return strategies[self.random:int(1, #strategies)]()
    end
end

return ExpressionMutator
