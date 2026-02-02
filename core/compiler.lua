--[[
    Luartex Compiler
    Converts AST back to Lua source code
]]

local AST = require("core.ast")

local Compiler = {}
Compiler.__index = Compiler

function Compiler.new(options)
    local self = setmetatable({}, Compiler)
    
    self.options = options or {}
    self.indent = 0
    self.output = {}
    self.minify = self.options.minify or false
    
    return self
end

function Compiler:emit(code)
    table.insert(self.output, code)
end

function Compiler:newline()
    if not self.minify then
        self:emit("\n" .. string.rep("    ", self.indent))
    end
end

function Compiler:space()
    if not self.minify then
        self:emit(" ")
    end
end

function Compiler:separator()
    if self.minify then
        self:emit(" ")
    else
        self:emit(" ")
    end
end

function Compiler.compile(ast, options)
    local compiler = Compiler.new(options)
    
    -- Add watermark
    if options and options.addWatermark then
        local watermark = options.watermark or "-- Protected by Luartex Obfuscator | discord.gg/GpucUKeCtF"
        compiler:emit(watermark)
        compiler:emit("\n")
    end
    
    compiler:compileNode(ast)
    
    return table.concat(compiler.output)
end

function Compiler:compileNode(node)
    if not node or not node.type then
        return
    end
    
    local handler = self["compile" .. node.type]
    
    if handler then
        handler(self, node)
    else
        error("Unknown node type: " .. node.type)
    end
end

function Compiler:compileChunk(node)
    for i, statement in ipairs(node.body) do
        if i > 1 then
            self:newline()
        end
        self:compileNode(statement)
    end
end

function Compiler:compileLocalStatement(node)
    self:emit("local ")
    
    for i, var in ipairs(node.variables) do
        if i > 1 then
            self:emit(",")
            self:space()
        end
        self:compileNode(var)
    end
    
    if node.init and #node.init > 0 then
        self:space()
        self:emit("=")
        self:space()
        
        for i, init in ipairs(node.init) do
            if i > 1 then
                self:emit(",")
                self:space()
            end
            self:compileNode(init)
        end
    end
end

function Compiler:compileAssignmentStatement(node)
    for i, var in ipairs(node.variables) do
        if i > 1 then
            self:emit(",")
            self:space()
        end
        self:compileNode(var)
    end
    
    self:space()
    self:emit("=")
    self:space()
    
    for i, init in ipairs(node.init) do
        if i > 1 then
            self:emit(",")
            self:space()
        end
        self:compileNode(init)
    end
end

function Compiler:compileCallStatement(node)
    self:compileNode(node.expression)
end

function Compiler:compileIfStatement(node)
    for i, clause in ipairs(node.clauses) do
        self:compileNode(clause)
    end
    self:newline()
    self:emit("end")
end

function Compiler:compileIfClause(node)
    self:emit("if")
    self:separator()
    self:compileNode(node.condition)
    self:separator()
    self:emit("then")
    self.indent = self.indent + 1
    
    for _, statement in ipairs(node.body) do
        self:newline()
        self:compileNode(statement)
    end
    
    self.indent = self.indent - 1
end

function Compiler:compileElseifClause(node)
    self:newline()
    self:emit("elseif")
    self:separator()
    self:compileNode(node.condition)
    self:separator()
    self:emit("then")
    self.indent = self.indent + 1
    
    for _, statement in ipairs(node.body) do
        self:newline()
        self:compileNode(statement)
    end
    
    self.indent = self.indent - 1
end

function Compiler:compileElseClause(node)
    self:newline()
    self:emit("else")
    self.indent = self.indent + 1
    
    for _, statement in ipairs(node.body) do
        self:newline()
        self:compileNode(statement)
    end
    
    self.indent = self.indent - 1
end

function Compiler:compileWhileStatement(node)
    self:emit("while")
    self:separator()
    self:compileNode(node.condition)
    self:separator()
    self:emit("do")
    self.indent = self.indent + 1
    
    for _, statement in ipairs(node.body) do
        self:newline()
        self:compileNode(statement)
    end
    
    self.indent = self.indent - 1
    self:newline()
    self:emit("end")
end

function Compiler:compileDoStatement(node)
    self:emit("do")
    self.indent = self.indent + 1
    
    for _, statement in ipairs(node.body) do
        self:newline()
        self:compileNode(statement)
    end
    
    self.indent = self.indent - 1
    self:newline()
    self:emit("end")
end

function Compiler:compileForNumericStatement(node)
    self:emit("for")
    self:separator()
    self:compileNode(node.variable)
    self:space()
    self:emit("=")
    self:space()
    self:compileNode(node.start)
    self:emit(",")
    self:space()
    self:compileNode(node.limit)
    
    if node.step then
        self:emit(",")
        self:space()
        self:compileNode(node.step)
    end
    
    self:separator()
    self:emit("do")
    self.indent = self.indent + 1
    
    for _, statement in ipairs(node.body) do
        self:newline()
        self:compileNode(statement)
    end
    
    self.indent = self.indent - 1
    self:newline()
    self:emit("end")
end

function Compiler:compileForGenericStatement(node)
    self:emit("for")
    self:separator()
    
    for i, var in ipairs(node.variables) do
        if i > 1 then
            self:emit(",")
            self:space()
        end
        self:compileNode(var)
    end
    
    self:separator()
    self:emit("in")
    self:separator()
    
    for i, iter in ipairs(node.iterators) do
        if i > 1 then
            self:emit(",")
            self:space()
        end
        self:compileNode(iter)
    end
    
    self:separator()
    self:emit("do")
    self.indent = self.indent + 1
    
    for _, statement in ipairs(node.body) do
        self:newline()
        self:compileNode(statement)
    end
    
    self.indent = self.indent - 1
    self:newline()
    self:emit("end")
end

function Compiler:compileRepeatStatement(node)
    self:emit("repeat")
    self.indent = self.indent + 1
    
    for _, statement in ipairs(node.body) do
        self:newline()
        self:compileNode(statement)
    end
    
    self.indent = self.indent - 1
    self:newline()
    self:emit("until")
    self:separator()
    self:compileNode(node.condition)
end

function Compiler:compileFunctionDeclaration(node)
    if node.isLocal then
        self:emit("local ")
    end
    
    self:emit("function")
    self:separator()
    self:compileNode(node.identifier)
    self:emit("(")
    
    for i, param in ipairs(node.parameters) do
        if i > 1 then
            self:emit(",")
            self:space()
        end
        self:compileNode(param)
    end
    
    self:emit(")")
    self.indent = self.indent + 1
    
    for _, statement in ipairs(node.body) do
        self:newline()
        self:compileNode(statement)
    end
    
    self.indent = self.indent - 1
    self:newline()
    self:emit("end")
end

function Compiler:compileReturnStatement(node)
    self:emit("return")
    
    if node.arguments and #node.arguments > 0 then
        self:separator()
        
        for i, arg in ipairs(node.arguments) do
            if i > 1 then
                self:emit(",")
                self:space()
            end
            self:compileNode(arg)
        end
    end
end

function Compiler:compileBreakStatement(node)
    self:emit("break")
end

function Compiler:compileGotoStatement(node)
    self:emit("goto ")
    self:compileNode(node.label)
end

function Compiler:compileLabelStatement(node)
    self:emit("::")
    self:compileNode(node.label)
    self:emit("::")
end

function Compiler:compileIdentifier(node)
    self:emit(node.name)
end

function Compiler:compileStringLiteral(node)
    if node.raw then
        self:emit(node.raw)
    else
        self:emit('"' .. node.value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"')
    end
end

function Compiler:compileNumberLiteral(node)
    self:emit(node.raw or tostring(node.value))
end

function Compiler:compileBooleanLiteral(node)
    self:emit(tostring(node.value))
end

function Compiler:compileNilLiteral(node)
    self:emit("nil")
end

function Compiler:compileVararg(node)
    self:emit("...")
end

function Compiler:compileBinaryExpression(node)
    local needsParens = node.operator == "and" or node.operator == "or"
    
    if needsParens then self:emit("(") end
    self:compileNode(node.left)
    self:space()
    self:emit(node.operator)
    self:space()
    self:compileNode(node.right)
    if needsParens then self:emit(")") end
end

function Compiler:compileUnaryExpression(node)
    self:emit(node.operator)
    if node.operator == "not" then
        self:separator()
    end
    self:compileNode(node.argument)
end

function Compiler:compileCallExpression(node)
    self:compileNode(node.base)
    self:emit("(")
    
    for i, arg in ipairs(node.arguments) do
        if i > 1 then
            self:emit(",")
            self:space()
        end
        self:compileNode(arg)
    end
    
    self:emit(")")
end

function Compiler:compileMemberExpression(node)
    self:compileNode(node.base)
    self:emit(node.indexer)
    self:compileNode(node.identifier)
end

function Compiler:compileIndexExpression(node)
    self:compileNode(node.base)
    self:emit("[")
    self:compileNode(node.index)
    self:emit("]")
end

function Compiler:compileFunctionExpression(node)
    self:emit("function(")
    
    for i, param in ipairs(node.parameters) do
        if i > 1 then
            self:emit(",")
            self:space()
        end
        self:compileNode(param)
    end
    
    self:emit(")")
    self.indent = self.indent + 1
    
    for _, statement in ipairs(node.body) do
        self:newline()
        self:compileNode(statement)
    end
    
    self.indent = self.indent - 1
    self:newline()
    self:emit("end")
end

function Compiler:compileTableExpression(node)
    if #node.fields == 0 then
        self:emit("{}")
        return
    end
    
    self:emit("{")
    self.indent = self.indent + 1
    
    for i, field in ipairs(node.fields) do
        self:newline()
        self:compileNode(field)
        
        if i < #node.fields then
            self:emit(",")
        end
    end
    
    self.indent = self.indent - 1
    self:newline()
    self:emit("}")
end

function Compiler:compileTableField(node)
    if node.key then
        if node.key.type == AST.NodeType.STRING_LITERAL and
           node.key.value:match("^[%a_][%w_]*$") then
            -- Simple key, use name = value syntax
            self:emit(node.key.value)
        else
            -- Complex key, use [key] = value syntax
            self:emit("[")
            self:compileNode(node.key)
            self:emit("]")
        end
        self:space()
        self:emit("=")
        self:space()
    end
    
    self:compileNode(node.value)
end

return Compiler
