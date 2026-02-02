--[[
    Opaque Predicates
    Adds conditions that always evaluate to true/false but are hard to analyze
]]

local AST = require("core.ast")

local OpaquePredicates = {}
OpaquePredicates.__index = OpaquePredicates

function OpaquePredicates.new(parent)
    local self = setmetatable({}, OpaquePredicates)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function OpaquePredicates:inject(ast)
    local self_ref = self
    
    AST.transform(ast, {
        [AST.NodeType.IF_CLAUSE] = function(node)
            -- Wrap condition with opaque predicate
            node.condition = self_ref:wrapWithTrue(node.condition)
            return node
        end,
        
        [AST.NodeType.WHILE_STATEMENT] = function(node)
            if self_ref.random:bool(0.5) then
                node.condition = self_ref:wrapWithTrue(node.condition)
            end
            return node
        end,
    })
    
    return ast
end

-- Generates a predicate that always evaluates to true
function OpaquePredicates:generateTrue()
    local predicates = {
        -- (x * x) >= 0 (always true for real numbers)
        function(self)
            local x = self.random:int(1, 1000)
            return AST.binaryExpression(">=",
                AST.binaryExpression("*",
                    AST.numberLiteral(x),
                    AST.numberLiteral(x)
                ),
                AST.numberLiteral(0)
            )
        end,
        
        -- (x % 2) == 0 or (x % 2) == 1 (always true)
        function(self)
            local x = self.random:int(1, 1000)
            return AST.binaryExpression("or",
                AST.binaryExpression("==",
                    AST.binaryExpression("%",
                        AST.numberLiteral(x),
                        AST.numberLiteral(2)
                    ),
                    AST.numberLiteral(0)
                ),
                AST.binaryExpression("==",
                    AST.binaryExpression("%",
                        AST.numberLiteral(x),
                        AST.numberLiteral(2)
                    ),
                    AST.numberLiteral(1)
                )
            )
        end,
        
        -- (x + 1) > x (always true)
        function(self)
            local x = self.random:int(1, 1000)
            return AST.binaryExpression(">",
                AST.binaryExpression("+",
                    AST.numberLiteral(x),
                    AST.numberLiteral(1)
                ),
                AST.numberLiteral(x)
            )
        end,
        
        -- type("") == "string" (always true)
        function(self)
            return AST.binaryExpression("==",
                AST.callExpression(
                    AST.identifier("type"),
                    { AST.stringLiteral("") }
                ),
                AST.stringLiteral("string")
            )
        end,
        
        -- #"abc" == 3 (always true)
        function(self)
            local str = self.random:string(self.random:int(3, 8))
            return AST.binaryExpression("==",
                AST.unaryExpression("#",
                    AST.stringLiteral(str)
                ),
                AST.numberLiteral(#str)
            )
        end,
        
        -- not not true (always true)
        function(self)
            return AST.unaryExpression("not",
                AST.unaryExpression("not",
                    AST.booleanLiteral(true)
                )
            )
        end,
    }
    
    local chosen = predicates[self.random:int(1, #predicates)]
    return chosen(self)
end

-- Generates a predicate that always evaluates to false
function OpaquePredicates:generateFalse()
    local predicates = {
        -- x > x (always false)
        function(self)
            local x = self.random:int(1, 1000)
            return AST.binaryExpression(">",
                AST.numberLiteral(x),
                AST.numberLiteral(x)
            )
        end,
        
        -- type(1) == "string" (always false)
        function(self)
            return AST.binaryExpression("==",
                AST.callExpression(
                    AST.identifier("type"),
                    { AST.numberLiteral(self.random:int(1, 1000)) }
                ),
                AST.stringLiteral("string")
            )
        end,
        
        -- false and true (always false)
        function(self)
            return AST.binaryExpression("and",
                AST.booleanLiteral(false),
                AST.booleanLiteral(true)
            )
        end,
        
        -- not true (always false)
        function(self)
            return AST.unaryExpression("not",
                AST.booleanLiteral(true)
            )
        end,
    }
    
    local chosen = predicates[self.random:int(1, #predicates)]
    return chosen(self)
end

-- Wrap expression with AND true predicate
function OpaquePredicates:wrapWithTrue(expr)
    local truePredicate = self:generateTrue()
    
    return AST.binaryExpression("and",
        truePredicate,
        expr
    )
end

-- Wrap expression with OR false predicate
function OpaquePredicates:wrapWithFalse(expr)
    local falsePredicate = self:generateFalse()
    
    return AST.binaryExpression("or",
        falsePredicate,
        expr
    )
end

return OpaquePredicates
