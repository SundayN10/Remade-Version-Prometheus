--[[
    Luartex Code Analyzer
    Analyzes code structure for optimization
]]

local AST = require("core.ast")

local Analyzer = {}
Analyzer.__index = Analyzer

function Analyzer.new(luartex)
    local self = setmetatable({}, Analyzer)
    
    self.luartex = luartex
    self.scopes = {}
    self.currentScope = nil
    
    return self
end

function Analyzer:analyze(ast)
    self.scopes = {}
    self:pushScope("global")
    
    self:walkAST(ast)
    
    self:popScope()
    
    return {
        scopes = self.scopes,
        globals = self:getGlobals(),
        upvalues = self:getUpvalues(),
    }
end

function Analyzer:pushScope(name)
    local scope = {
        name = name,
        parent = self.currentScope,
        variables = {},
        children = {},
    }
    
    if self.currentScope then
        table.insert(self.currentScope.children, scope)
    end
    
    table.insert(self.scopes, scope)
    self.currentScope = scope
    
    return scope
end

function Analyzer:popScope()
    local scope = self.currentScope
    self.currentScope = scope and scope.parent
    return scope
end

function Analyzer:declareVariable(name, node)
    if self.currentScope then
        self.currentScope.variables[name] = {
            name = name,
            node = node,
            references = {},
        }
    end
end

function Analyzer:resolveVariable(name)
    local scope = self.currentScope
    
    while scope do
        if scope.variables[name] then
            return scope.variables[name], scope
        end
        scope = scope.parent
    end
    
    return nil, nil
end

function Analyzer:walkAST(node)
    if not node or type(node) ~= "table" then
        return
    end
    
    local nodeType = node.type
    
    if nodeType == AST.NodeType.LOCAL_STATEMENT then
        for _, var in ipairs(node.variables) do
            self:declareVariable(var.name, var)
        end
    elseif nodeType == AST.NodeType.FUNCTION_DECLARATION then
        if node.isLocal and node.identifier then
            self:declareVariable(node.identifier.name, node.identifier)
        end
        
        self:pushScope("function")
        
        for _, param in ipairs(node.parameters) do
            if param.type == AST.NodeType.IDENTIFIER then
                self:declareVariable(param.name, param)
            end
        end
        
        for _, stmt in ipairs(node.body) do
            self:walkAST(stmt)
        end
        
        self:popScope()
        return  -- Don't recurse further
        
    elseif nodeType == AST.NodeType.FUNCTION_EXPRESSION then
        self:pushScope("function")
        
        for _, param in ipairs(node.parameters) do
            if param.type == AST.NodeType.IDENTIFIER then
                self:declareVariable(param.name, param)
            end
        end
        
        for _, stmt in ipairs(node.body) do
            self:walkAST(stmt)
        end
        
        self:popScope()
        return
        
    elseif nodeType == AST.NodeType.FOR_NUMERIC_STATEMENT then
        self:pushScope("for")
        self:declareVariable(node.variable.name, node.variable)
        
        for _, stmt in ipairs(node.body) do
            self:walkAST(stmt)
        end
        
        self:popScope()
        return
        
    elseif nodeType == AST.NodeType.FOR_GENERIC_STATEMENT then
        self:pushScope("for")
        
        for _, var in ipairs(node.variables) do
            self:declareVariable(var.name, var)
        end
        
        for _, stmt in ipairs(node.body) do
            self:walkAST(stmt)
        end
        
        self:popScope()
        return
        
    elseif nodeType == AST.NodeType.IDENTIFIER then
        local variable, scope = self:resolveVariable(node.name)
        if variable then
            table.insert(variable.references, node)
        end
    end
    
    -- Recurse into children
    for key, value in pairs(node) do
        if key ~= "type" and type(value) == "table" then
            if value.type then
                self:walkAST(value)
            else
                for _, child in ipairs(value) do
                    if type(child) == "table" then
                        self:walkAST(child)
                    end
                end
            end
        end
    end
end

function Analyzer:getGlobals()
    local globals = {}
    
    for _, scope in ipairs(self.scopes) do
        for name, var in pairs(scope.variables) do
            if scope.name == "global" then
                globals[name] = var
            end
        end
    end
    
    return globals
end

function Analyzer:getUpvalues()
    local upvalues = {}
    -- Implementation for detecting upvalues
    return upvalues
end

return Analyzer
