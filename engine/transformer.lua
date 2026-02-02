--[[
    Luartex AST Transformer
    Base class for AST transformations
]]

local AST = require("core.ast")

local Transformer = {}
Transformer.__index = Transformer

function Transformer.new(luartex)
    local self = setmetatable({}, Transformer)
    
    self.luartex = luartex
    self.random = luartex and luartex.random
    self.logger = luartex and luartex.logger
    
    return self
end

-- Override in subclasses
function Transformer:transform(ast)
    return ast
end

-- Walk and transform all nodes
function Transformer:walkAndTransform(ast, visitor)
    return AST.transform(ast, visitor)
end

-- Replace a node
function Transformer:replace(oldNode, newNode)
    for k, v in pairs(oldNode) do
        oldNode[k] = nil
    end
    for k, v in pairs(newNode) do
        oldNode[k] = v
    end
    return oldNode
end

-- Insert statement before
function Transformer:insertBefore(body, index, statement)
    table.insert(body, index, statement)
end

-- Insert statement after
function Transformer:insertAfter(body, index, statement)
    table.insert(body, index + 1, statement)
end

-- Remove statement
function Transformer:remove(body, index)
    table.remove(body, index)
end

-- Wrap expression in function call
function Transformer:wrapInCall(expr, funcName, args)
    args = args or {}
    table.insert(args, 1, expr)
    
    return AST.callExpression(
        AST.identifier(funcName),
        args
    )
end

-- Wrap statements in do-end block
function Transformer:wrapInDoBlock(statements)
    return AST.doStatement(statements)
end

-- Create IIFE (Immediately Invoked Function Expression)
function Transformer:createIIFE(statements, returnValues)
    local body = {}
    
    for _, stmt in ipairs(statements) do
        table.insert(body, stmt)
    end
    
    if returnValues then
        table.insert(body, AST.returnStatement(returnValues))
    end
    
    return AST.callExpression(
        AST.functionExpression({}, body),
        {}
    )
end

-- Generate a unique variable name
function Transformer:genVar(prefix)
    prefix = prefix or "v"
    return self.random:identifier(12)
end

-- Generate multiple unique variable names
function Transformer:genVars(count, prefix)
    return self.random:uniqueIdentifiers(count, 12)
end

return Transformer
