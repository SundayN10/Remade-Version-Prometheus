--[[
    Luartex Output Optimizer
    Optimizes the final output
]]

local Optimizer = {}
Optimizer.__index = Optimizer

function Optimizer.new(options)
    local self = setmetatable({}, Optimizer)
    
    self.options = options or {}
    
    return self
end

function Optimizer:optimize(source)
    if self.options.minify then
        source = self:minify(source)
    end
    
    if self.options.removeComments then
        source = self:removeComments(source)
    end
    
    return source
end

function Optimizer:minify(source)
    -- Remove extra whitespace
    source = source:gsub("%s+", " ")
    
    -- Remove spaces around operators
    source = source:gsub(" ([%+%-%*/%^%%=<>~,;:%.%[%]%(%){}]) ", "%1")
    source = source:gsub("([%+%-%*/%^%%=<>~,;:%.%[%]%(%){}]) ", "%1")
    source = source:gsub(" ([%+%-%*/%^%%=<>~,;:%.%[%]%(%){}])", "%1")
    
    -- Restore spaces around keywords
    local keywords = {"and", "or", "not", "local", "function", "if", "then", 
                      "else", "elseif", "end", "while", "do", "for", "in",
                      "repeat", "until", "return", "break"}
    
    for _, kw in ipairs(keywords) do
        source = source:gsub("(%w)" .. kw .. "(%w)", "%1 " .. kw .. " %2")
    end
    
    -- Remove leading/trailing whitespace
    source = source:gsub("^%s+", ""):gsub("%s+$", "")
    
    return source
end

function Optimizer:removeComments(source)
    -- Remove multi-line comments
    source = source:gsub("%-%-%[%[.-%]%]", "")
    
    -- Remove single-line comments
    source = source:gsub("%-%-[^\n]*", "")
    
    return source
end

function Optimizer:removeDeadCode(ast)
    -- Implementation for dead code removal
    return ast
end

return Optimizer
