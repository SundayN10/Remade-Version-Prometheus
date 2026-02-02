--[[
    Constant Folder
    Transforms constants into complex expressions
]]

local AST = require("core.ast")

local ConstantFolder = {}
ConstantFolder.__index = ConstantFolder

function ConstantFolder.new(parent)
    local self = setmetatable({}, ConstantFolder)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function ConstantFolder:fold(ast)
    local self_ref = self
    
    AST.transform(ast, {
        [AST.NodeType.NUMBER_LITERAL] = function(node)
            if self_ref.random:bool(0.6) then
                return self_ref:expandNumber(node.value)
            end
            return node
        end,
    })
    
    return ast
end

function ConstantFolder:expandNumber(value)
    local strategies = {
        self.additionExpansion,
        self.subtractionExpansion,
        self.multiplicationExpansion,
        self.bitwiseExpansion,
        self.mathExpansion,
    }
    
    local strategy = strategies[self.random:int(1, #strategies)]
    return strategy(self, value)
end

function ConstantFolder:additionExpansion(value)
    local a = self.random:int(-1000, 1000)
    local b = value - a
    
    return AST.binaryExpression("+",
        AST.numberLiteral(a),
        AST.numberLiteral(b)
    )
end

function ConstantFolder:subtractionExpansion(value)
    local a = self.random:int(value, value + 1000)
    local b = a - value
    
    return AST.binaryExpression("-",
        AST.numberLiteral(a),
        AST.numberLiteral(b)
    )
end

function ConstantFolder:multiplicationExpansion(value)
    -- Find factors
    if value == 0 then
        return AST.binaryExpression("*",
            AST.numberLiteral(self.random:int(1, 100)),
            AST.numberLiteral(0)
        )
    end
    
    local factors = {}
    for i = 1, math.abs(value) do
        if value % i == 0 then
            table.insert(factors, i)
        end
    end
    
    if #factors > 2 then
        local a = factors[self.random:int(2, #factors - 1)]
        local b = value / a
        
        return AST.binaryExpression("*",
            AST.numberLiteral(a),
            AST.numberLiteral(b)
        )
    end
    
    return AST.numberLiteral(value)
end

function ConstantFolder:bitwiseExpansion(value)
    if value >= 0 and value == math.floor(value) then
        local a = self.random:int(0, 255)
        local b = value ~ a  -- XOR to get b such that a XOR b = value
        
        return AST.callExpression(
            AST.memberExpression(
                AST.identifier("bit32"),
                AST.identifier("bxor"),
                "."
            ),
            {
                AST.numberLiteral(a),
                AST.numberLiteral(b)
            }
        )
    end
    
    return AST.numberLiteral(value)
end

function ConstantFolder:mathExpansion(value)
    local strategies = {
        -- math.floor(value + 0.1)
        function(self, v)
            return AST.callExpression(
                AST.memberExpression(
                    AST.identifier("math"),
                    AST.identifier("floor"),
                    "."
                ),
                {
                    AST.binaryExpression("+",
                        AST.numberLiteral(v),
                        AST.numberLiteral(0.1)
                    )
                }
            )
        end,
        
        -- math.abs(value) or math.abs(-value)
        function(self, v)
            if v >= 0 then
                return AST.callExpression(
                    AST.memberExpression(
                        AST.identifier("math"),
                        AST.identifier("abs"),
                        "."
                    ),
                    { AST.numberLiteral(v) }
                )
            else
                return AST.unaryExpression("-",
                    AST.callExpression(
                        AST.memberExpression(
                            AST.identifier("math"),
                            AST.identifier("abs"),
                            "."
                        ),
                        { AST.numberLiteral(-v) }
                    )
                )
            end
        end,
        
        -- tonumber("value")
        function(self, v)
            return AST.callExpression(
                AST.identifier("tonumber"),
                { AST.stringLiteral(tostring(v)) }
            )
        end,
    }
    
    local strategy = strategies[self.random:int(1, #strategies)]
    return strategy(self, value)
end

return ConstantFolder
