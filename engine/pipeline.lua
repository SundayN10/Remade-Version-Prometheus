--[[
    Luartex Processing Pipeline
    Orchestrates the obfuscation process
]]

local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.new(luartex)
    local self = setmetatable({}, Pipeline)
    
    self.luartex = luartex
    self.stages = {}
    self.hooks = {
        beforeStage = {},
        afterStage = {},
    }
    
    return self
end

function Pipeline:addStage(name, handler, priority)
    table.insert(self.stages, {
        name = name,
        handler = handler,
        priority = priority or 50,
    })
    
    -- Sort by priority
    table.sort(self.stages, function(a, b)
        return a.priority < b.priority
    end)
end

function Pipeline:removeStage(name)
    for i, stage in ipairs(self.stages) do
        if stage.name == name then
            table.remove(self.stages, i)
            return true
        end
    end
    return false
end

function Pipeline:analyze(ast)
    local analysis = {
        functions = {},
        variables = {},
        strings = {},
        loops = {},
        conditionals = {},
        calls = {},
    }
    
    local AST = require("core.ast")
    
    AST.walk(ast, {
        [AST.NodeType.FUNCTION_DECLARATION] = function(node)
            table.insert(analysis.functions, node)
        end,
        
        [AST.NodeType.FUNCTION_EXPRESSION] = function(node)
            table.insert(analysis.functions, node)
        end,
        
        [AST.NodeType.STRING_LITERAL] = function(node)
            table.insert(analysis.strings, node)
        end,
        
        [AST.NodeType.LOCAL_STATEMENT] = function(node)
            for _, var in ipairs(node.variables) do
                table.insert(analysis.variables, var)
            end
        end,
        
        [AST.NodeType.WHILE_STATEMENT] = function(node)
            table.insert(analysis.loops, node)
        end,
        
        [AST.NodeType.FOR_NUMERIC_STATEMENT] = function(node)
            table.insert(analysis.loops, node)
        end,
        
        [AST.NodeType.FOR_GENERIC_STATEMENT] = function(node)
            table.insert(analysis.loops, node)
        end,
        
        [AST.NodeType.IF_STATEMENT] = function(node)
            table.insert(analysis.conditionals, node)
        end,
        
        [AST.NodeType.CALL_EXPRESSION] = function(node)
            table.insert(analysis.calls, node)
        end,
    })
    
    self.luartex.analysis = analysis
    
    self.luartex.logger:debug("Analysis complete:")
    self.luartex.logger:debug("  Functions: " .. #analysis.functions)
    self.luartex.logger:debug("  Variables: " .. #analysis.variables)
    self.luartex.logger:debug("  Strings: " .. #analysis.strings)
    self.luartex.logger:debug("  Loops: " .. #analysis.loops)
    
    return analysis
end

function Pipeline:run(ast)
    for _, stage in ipairs(self.stages) do
        -- Before hooks
        for _, hook in ipairs(self.hooks.beforeStage) do
            hook(stage.name, ast)
        end
        
        -- Run stage
        local startTime = os.clock()
        ast = stage.handler(ast, self.luartex) or ast
        local elapsed = os.clock() - startTime
        
        self.luartex.logger:debug(string.format("Stage '%s' completed in %.3fs", stage.name, elapsed))
        
        -- After hooks
        for _, hook in ipairs(self.hooks.afterStage) do
            hook(stage.name, ast, elapsed)
        end
    end
    
    return ast
end

function Pipeline:onBeforeStage(callback)
    table.insert(self.hooks.beforeStage, callback)
end

function Pipeline:onAfterStage(callback)
    table.insert(self.hooks.afterStage, callback)
end

return Pipeline
