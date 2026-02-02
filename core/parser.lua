--[[
    Luartex Parser
    Converts tokens to AST
]]

local Lexer = require("core.lexer")
local AST = require("core.ast")

local Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
    local self = setmetatable({}, Parser)
    
    self.tokens = tokens
    self.position = 1
    self.scopeDepth = 0
    
    return self
end

function Parser:peek(offset)
    offset = offset or 0
    local pos = self.position + offset
    
    while pos <= #self.tokens do
        local token = self.tokens[pos]
        if token.type ~= Lexer.TokenType.COMMENT and 
           token.type ~= Lexer.TokenType.WHITESPACE and
           token.type ~= Lexer.TokenType.NEWLINE then
            return token
        end
        pos = pos + 1
    end
    
    return self.tokens[#self.tokens]
end

function Parser:current()
    return self:peek(0)
end

function Parser:advance()
    local token = self:current()
    self.position = self.position + 1
    
    while self.position <= #self.tokens do
        local t = self.tokens[self.position]
        if t.type ~= Lexer.TokenType.COMMENT and
           t.type ~= Lexer.TokenType.WHITESPACE and
           t.type ~= Lexer.TokenType.NEWLINE then
            break
        end
        self.position = self.position + 1
    end
    
    return token
end

function Parser:expect(type, value)
    local token = self:current()
    
    if token.type ~= type then
        error(string.format("Expected %s but got %s at line %d", type, token.type, token.line or 0))
    end
    
    if value and token.value ~= value then
        error(string.format("Expected '%s' but got '%s' at line %d", value, token.value, token.line or 0))
    end
    
    return self:advance()
end

function Parser:match(type, value)
    local token = self:current()
    if token.type ~= type then return false end
    if value and token.value ~= value then return false end
    return true
end

function Parser:consume(type, value)
    if self:match(type, value) then
        return self:advance()
    end
    return nil
end

function Parser.parse(source)
    local lexer = Lexer.new(source)
    local tokens = lexer:tokenize()
    local parser = Parser.new(tokens)
    return parser:parseChunk()
end

function Parser:parseChunk()
    local body = {}
    
    while not self:match(Lexer.TokenType.EOF) do
        local statement = self:parseStatement()
        if statement then
            table.insert(body, statement)
        end
    end
    
    return AST.chunk(body)
end

function Parser:parseStatement()
    local token = self:current()
    
    if self:match(Lexer.TokenType.PUNCTUATION, ";") then
        self:advance()
        return nil
    end
    
    if token.type == Lexer.TokenType.KEYWORD then
        if token.value == "local" then
            return self:parseLocalStatement()
        elseif token.value == "if" then
            return self:parseIfStatement()
        elseif token.value == "while" then
            return self:parseWhileStatement()
        elseif token.value == "do" then
            return self:parseDoStatement()
        elseif token.value == "for" then
            return self:parseForStatement()
        elseif token.value == "repeat" then
            return self:parseRepeatStatement()
        elseif token.value == "function" then
            return self:parseFunctionDeclaration()
        elseif token.value == "return" then
            return self:parseReturnStatement()
        elseif token.value == "break" then
            self:advance()
            return AST.breakStatement()
        elseif token.value == "goto" then
            return self:parseGotoStatement()
        end
    end
    
    if self:match(Lexer.TokenType.OPERATOR, "::") then
        return self:parseLabelStatement()
    end
    
    return self:parseExpressionStatement()
end

function Parser:parseLocalStatement()
    self:expect(Lexer.TokenType.KEYWORD, "local")
    
    if self:match(Lexer.TokenType.KEYWORD, "function") then
        self:advance()
        local name = self:expect(Lexer.TokenType.IDENTIFIER)
        return self:parseFunctionBody(AST.identifier(name.value), true)
    end
    
    local variables = {}
    
    repeat
        local name = self:expect(Lexer.TokenType.IDENTIFIER)
        table.insert(variables, AST.identifier(name.value))
    until not self:consume(Lexer.TokenType.PUNCTUATION, ",")
    
    local init = {}
    
    if self:consume(Lexer.TokenType.OPERATOR, "=") then
        repeat
            table.insert(init, self:parseExpression())
        until not self:consume(Lexer.TokenType.PUNCTUATION, ",")
    end
    
    return AST.localStatement(variables, init)
end

function Parser:parseIfStatement()
    self:expect(Lexer.TokenType.KEYWORD, "if")
    
    local clauses = {}
    
    -- Main if clause
    local condition = self:parseExpression()
    self:expect(Lexer.TokenType.KEYWORD, "then")
    local body = self:parseBlock()
    table.insert(clauses, AST.ifClause(condition, body))
    
    -- Elseif clauses
    while self:match(Lexer.TokenType.KEYWORD, "elseif") do
        self:advance()
        condition = self:parseExpression()
        self:expect(Lexer.TokenType.KEYWORD, "then")
        body = self:parseBlock()
        table.insert(clauses, AST.elseifClause(condition, body))
    end
    
    -- Else clause
    if self:match(Lexer.TokenType.KEYWORD, "else") then
        self:advance()
        body = self:parseBlock()
        table.insert(clauses, AST.elseClause(body))
    end
    
    self:expect(Lexer.TokenType.KEYWORD, "end")
    
    return AST.ifStatement(clauses)
end

function Parser:parseWhileStatement()
    self:expect(Lexer.TokenType.KEYWORD, "while")
    local condition = self:parseExpression()
    self:expect(Lexer.TokenType.KEYWORD, "do")
    local body = self:parseBlock()
    self:expect(Lexer.TokenType.KEYWORD, "end")
    
    return AST.whileStatement(condition, body)
end

function Parser:parseDoStatement()
    self:expect(Lexer.TokenType.KEYWORD, "do")
    local body = self:parseBlock()
    self:expect(Lexer.TokenType.KEYWORD, "end")
    
    return AST.doStatement(body)
end

function Parser:parseForStatement()
    self:expect(Lexer.TokenType.KEYWORD, "for")
    
    local firstName = self:expect(Lexer.TokenType.IDENTIFIER)
    
    if self:match(Lexer.TokenType.OPERATOR, "=") then
        -- Numeric for
        self:advance()
        local start = self:parseExpression()
        self:expect(Lexer.TokenType.PUNCTUATION, ",")
        local limit = self:parseExpression()
        
        local step = nil
        if self:consume(Lexer.TokenType.PUNCTUATION, ",") then
            step = self:parseExpression()
        end
        
        self:expect(Lexer.TokenType.KEYWORD, "do")
        local body = self:parseBlock()
        self:expect(Lexer.TokenType.KEYWORD, "end")
        
        return AST.forNumericStatement(
            AST.identifier(firstName.value),
            start, limit, step, body
        )
    else
        -- Generic for
        local variables = { AST.identifier(firstName.value) }
        
        while self:consume(Lexer.TokenType.PUNCTUATION, ",") do
            local name = self:expect(Lexer.TokenType.IDENTIFIER)
            table.insert(variables, AST.identifier(name.value))
        end
        
        self:expect(Lexer.TokenType.KEYWORD, "in")
        
        local iterators = {}
        repeat
            table.insert(iterators, self:parseExpression())
        until not self:consume(Lexer.TokenType.PUNCTUATION, ",")
        
        self:expect(Lexer.TokenType.KEYWORD, "do")
        local body = self:parseBlock()
        self:expect(Lexer.TokenType.KEYWORD, "end")
        
        return AST.forGenericStatement(variables, iterators, body)
    end
end

function Parser:parseRepeatStatement()
    self:expect(Lexer.TokenType.KEYWORD, "repeat")
    local body = self:parseBlock()
    self:expect(Lexer.TokenType.KEYWORD, "until")
    local condition = self:parseExpression()
    
    return AST.repeatStatement(condition, body)
end

function Parser:parseFunctionDeclaration()
    self:expect(Lexer.TokenType.KEYWORD, "function")
    
    local base = self:expect(Lexer.TokenType.IDENTIFIER)
    local identifier = AST.identifier(base.value)
    
    -- Handle a.b.c and a:b syntax
    while true do
        if self:match(Lexer.TokenType.PUNCTUATION, ".") then
            self:advance()
            local name = self:expect(Lexer.TokenType.IDENTIFIER)
            identifier = AST.memberExpression(identifier, AST.identifier(name.value), ".")
        elseif self:match(Lexer.TokenType.PUNCTUATION, ":") then
            self:advance()
            local name = self:expect(Lexer.TokenType.IDENTIFIER)
            identifier = AST.memberExpression(identifier, AST.identifier(name.value), ":")
            break
        else
            break
        end
    end
    
    return self:parseFunctionBody(identifier, false)
end

function Parser:parseFunctionBody(identifier, isLocal)
    self:expect(Lexer.TokenType.PUNCTUATION, "(")
    
    local parameters = {}
    
    if not self:match(Lexer.TokenType.PUNCTUATION, ")") then
        repeat
            if self:match(Lexer.TokenType.OPERATOR, "...") then
                self:advance()
                table.insert(parameters, AST.vararg())
                break
            else
                local name = self:expect(Lexer.TokenType.IDENTIFIER)
                table.insert(parameters, AST.identifier(name.value))
            end
        until not self:consume(Lexer.TokenType.PUNCTUATION, ",")
    end
    
    self:expect(Lexer.TokenType.PUNCTUATION, ")")
    
    local body = self:parseBlock()
    
    self:expect(Lexer.TokenType.KEYWORD, "end")
    
    return AST.functionDeclaration(identifier, parameters, body, isLocal)
end

function Parser:parseReturnStatement()
    self:expect(Lexer.TokenType.KEYWORD, "return")
    
    local arguments = {}
    
    -- Check if there are return values
    if not self:match(Lexer.TokenType.KEYWORD, "end") and
       not self:match(Lexer.TokenType.KEYWORD, "else") and
       not self:match(Lexer.TokenType.KEYWORD, "elseif") and
       not self:match(Lexer.TokenType.KEYWORD, "until") and
       not self:match(Lexer.TokenType.EOF) and
       not self:match(Lexer.TokenType.PUNCTUATION, ";") then
        repeat
            table.insert(arguments, self:parseExpression())
        until not self:consume(Lexer.TokenType.PUNCTUATION, ",")
    end
    
    return AST.returnStatement(arguments)
end

function Parser:parseGotoStatement()
    self:expect(Lexer.TokenType.KEYWORD, "goto")
    local label = self:expect(Lexer.TokenType.IDENTIFIER)
    
    return AST.node(AST.NodeType.GOTO_STATEMENT, {
        label = AST.identifier(label.value)
    })
end

function Parser:parseLabelStatement()
    self:expect(Lexer.TokenType.OPERATOR, "::")
    local label = self:expect(Lexer.TokenType.IDENTIFIER)
    self:expect(Lexer.TokenType.OPERATOR, "::")
    
    return AST.node(AST.NodeType.LABEL_STATEMENT, {
        label = AST.identifier(label.value)
    })
end

function Parser:parseBlock()
    local body = {}
    
    while not self:match(Lexer.TokenType.KEYWORD, "end") and
          not self:match(Lexer.TokenType.KEYWORD, "else") and
          not self:match(Lexer.TokenType.KEYWORD, "elseif") and
          not self:match(Lexer.TokenType.KEYWORD, "until") and
          not self:match(Lexer.TokenType.EOF) do
        local statement = self:parseStatement()
        if statement then
            table.insert(body, statement)
        end
    end
    
    return body
end

function Parser:parseExpressionStatement()
    local expr = self:parsePrimaryExpression()
    
    -- Parse suffixes (calls, member access, indexing)
    expr = self:parseSuffixes(expr)
    
    -- Check for assignment
    if self:match(Lexer.TokenType.PUNCTUATION, ",") or
       self:match(Lexer.TokenType.OPERATOR, "=") then
        
        local variables = { expr }
        
        while self:consume(Lexer.TokenType.PUNCTUATION, ",") do
            local var = self:parsePrimaryExpression()
            var = self:parseSuffixes(var)
            table.insert(variables, var)
        end
        
        self:expect(Lexer.TokenType.OPERATOR, "=")
        
        local init = {}
        repeat
            table.insert(init, self:parseExpression())
        until not self:consume(Lexer.TokenType.PUNCTUATION, ",")
        
        return AST.assignmentStatement(variables, init)
    end
    
    -- Must be a function call
    if expr.type ~= AST.NodeType.CALL_EXPRESSION then
        error("Syntax error: expected function call or assignment at line " .. (self:current().line or 0))
    end
    
    return AST.callStatement(expr)
end

function Parser:parseExpression()
    return self:parseOrExpression()
end

function Parser:parseOrExpression()
    local left = self:parseAndExpression()
    
    while self:match(Lexer.TokenType.KEYWORD, "or") do
        self:advance()
        local right = self:parseAndExpression()
        left = AST.binaryExpression("or", left, right)
    end
    
    return left
end

function Parser:parseAndExpression()
    local left = self:parseComparisonExpression()
    
    while self:match(Lexer.TokenType.KEYWORD, "and") do
        self:advance()
        local right = self:parseComparisonExpression()
        left = AST.binaryExpression("and", left, right)
    end
    
    return left
end

function Parser:parseComparisonExpression()
    local left = self:parseConcatExpression()
    
    local ops = { "<", ">", "<=", ">=", "~=", "==" }
    
    while true do
        local matched = false
        for _, op in ipairs(ops) do
            if self:match(Lexer.TokenType.OPERATOR, op) then
                self:advance()
                local right = self:parseConcatExpression()
                left = AST.binaryExpression(op, left, right)
                matched = true
                break
            end
        end
        if not matched then break end
    end
    
    return left
end

function Parser:parseConcatExpression()
    local left = self:parseAddExpression()
    
    if self:match(Lexer.TokenType.OPERATOR, "..") then
        self:advance()
        local right = self:parseConcatExpression()  -- Right associative
        return AST.binaryExpression("..", left, right)
    end
    
    return left
end

function Parser:parseAddExpression()
    local left = self:parseMulExpression()
    
    while self:match(Lexer.TokenType.OPERATOR, "+") or
          self:match(Lexer.TokenType.OPERATOR, "-") do
        local op = self:advance().value
        local right = self:parseMulExpression()
        left = AST.binaryExpression(op, left, right)
    end
    
    return left
end

function Parser:parseMulExpression()
    local left = self:parseUnaryExpression()
    
    while self:match(Lexer.TokenType.OPERATOR, "*") or
          self:match(Lexer.TokenType.OPERATOR, "/") or
          self:match(Lexer.TokenType.OPERATOR, "//") or
          self:match(Lexer.TokenType.OPERATOR, "%") do
        local op = self:advance().value
        local right = self:parseUnaryExpression()
        left = AST.binaryExpression(op, left, right)
    end
    
    return left
end

function Parser:parseUnaryExpression()
    if self:match(Lexer.TokenType.KEYWORD, "not") then
        self:advance()
        return AST.unaryExpression("not", self:parseUnaryExpression())
    end
    
    if self:match(Lexer.TokenType.OPERATOR, "-") then
        self:advance()
        return AST.unaryExpression("-", self:parseUnaryExpression())
    end
    
    if self:match(Lexer.TokenType.OPERATOR, "#") then
        self:advance()
        return AST.unaryExpression("#", self:parseUnaryExpression())
    end
    
    return self:parsePowerExpression()
end

function Parser:parsePowerExpression()
    local left = self:parseCallExpression()
    
    if self:match(Lexer.TokenType.OPERATOR, "^") then
        self:advance()
        local right = self:parseUnaryExpression()  -- Right associative
        return AST.binaryExpression("^", left, right)
    end
    
    return left
end

function Parser:parseCallExpression()
    local expr = self:parsePrimaryExpression()
    return self:parseSuffixes(expr)
end

function Parser:parseSuffixes(expr)
    while true do
        if self:match(Lexer.TokenType.PUNCTUATION, ".") then
            self:advance()
            local name = self:expect(Lexer.TokenType.IDENTIFIER)
            expr = AST.memberExpression(expr, AST.identifier(name.value), ".")
            
        elseif self:match(Lexer.TokenType.PUNCTUATION, "[") then
            self:advance()
            local index = self:parseExpression()
            self:expect(Lexer.TokenType.PUNCTUATION, "]")
            expr = AST.indexExpression(expr, index)
            
        elseif self:match(Lexer.TokenType.PUNCTUATION, ":") then
            self:advance()
            local name = self:expect(Lexer.TokenType.IDENTIFIER)
            expr = AST.memberExpression(expr, AST.identifier(name.value), ":")
            expr = self:parseCallSuffix(expr)
            
        elseif self:match(Lexer.TokenType.PUNCTUATION, "(") or
               self:match(Lexer.TokenType.STRING) or
               self:match(Lexer.TokenType.PUNCTUATION, "{") then
            expr = self:parseCallSuffix(expr)
            
        else
            break
        end
    end
    
    return expr
end

function Parser:parseCallSuffix(expr)
    local arguments = {}
    
    if self:match(Lexer.TokenType.PUNCTUATION, "(") then
        self:advance()
        
        if not self:match(Lexer.TokenType.PUNCTUATION, ")") then
            repeat
                table.insert(arguments, self:parseExpression())
            until not self:consume(Lexer.TokenType.PUNCTUATION, ",")
        end
        
        self:expect(Lexer.TokenType.PUNCTUATION, ")")
        
    elseif self:match(Lexer.TokenType.STRING) then
        local str = self:advance()
        table.insert(arguments, self:parseStringLiteral(str))
        
    elseif self:match(Lexer.TokenType.PUNCTUATION, "{") then
        table.insert(arguments, self:parseTableExpression())
    end
    
    return AST.callExpression(expr, arguments)
end

function Parser:parsePrimaryExpression()
    local token = self:current()
    
    -- Grouped expression
    if self:match(Lexer.TokenType.PUNCTUATION, "(") then
        self:advance()
        local expr = self:parseExpression()
        self:expect(Lexer.TokenType.PUNCTUATION, ")")
        return expr
    end
    
    -- Identifier
    if token.type == Lexer.TokenType.IDENTIFIER then
        self:advance()
        return AST.identifier(token.value)
    end
    
    -- Number
    if token.type == Lexer.TokenType.NUMBER then
        self:advance()
        return AST.numberLiteral(tonumber(token.value), token.value)
    end
    
    -- String
    if token.type == Lexer.TokenType.STRING then
        self:advance()
        return self:parseStringLiteral(token)
    end
    
    -- Keywords
    if token.type == Lexer.TokenType.KEYWORD then
        if token.value == "nil" then
            self:advance()
            return AST.nilLiteral()
        elseif token.value == "true" then
            self:advance()
            return AST.booleanLiteral(true)
        elseif token.value == "false" then
            self:advance()
            return AST.booleanLiteral(false)
        elseif token.value == "function" then
            self:advance()
            return self:parseFunctionExpression()
        end
    end
    
    -- Vararg
    if self:match(Lexer.TokenType.OPERATOR, "...") then
        self:advance()
        return AST.vararg()
    end
    
    -- Table
    if self:match(Lexer.TokenType.PUNCTUATION, "{") then
        return self:parseTableExpression()
    end
    
    error("Unexpected token: " .. token.type .. " (" .. tostring(token.value) .. ") at line " .. (token.line or 0))
end

function Parser:parseStringLiteral(token)
    local raw = token.value
    local value = raw
    
    -- Remove quotes
    if raw:sub(1, 1) == '"' or raw:sub(1, 1) == "'" then
        value = raw:sub(2, -2)
    elseif raw:sub(1, 2) == "[[" then
        value = raw:sub(3, -3)
    elseif raw:sub(1, 1) == "[" then
        -- Long string with equals
        local _, endPos = raw:find("^%[=*%[")
        local closeLen = endPos - 1
        value = raw:sub(endPos + 1, -(closeLen + 1))
    end
    
    return AST.stringLiteral(value, raw)
end

function Parser:parseFunctionExpression()
    self:expect(Lexer.TokenType.PUNCTUATION, "(")
    
    local parameters = {}
    
    if not self:match(Lexer.TokenType.PUNCTUATION, ")") then
        repeat
            if self:match(Lexer.TokenType.OPERATOR, "...") then
                self:advance()
                table.insert(parameters, AST.vararg())
                break
            else
                local name = self:expect(Lexer.TokenType.IDENTIFIER)
                table.insert(parameters, AST.identifier(name.value))
            end
        until not self:consume(Lexer.TokenType.PUNCTUATION, ",")
    end
    
    self:expect(Lexer.TokenType.PUNCTUATION, ")")
    
    local body = self:parseBlock()
    
    self:expect(Lexer.TokenType.KEYWORD, "end")
    
    return AST.functionExpression(parameters, body)
end

function Parser:parseTableExpression()
    self:expect(Lexer.TokenType.PUNCTUATION, "{")
    
    local fields = {}
    
    while not self:match(Lexer.TokenType.PUNCTUATION, "}") do
        local field
        
        if self:match(Lexer.TokenType.PUNCTUATION, "[") then
            -- [expr] = value
            self:advance()
            local key = self:parseExpression()
            self:expect(Lexer.TokenType.PUNCTUATION, "]")
            self:expect(Lexer.TokenType.OPERATOR, "=")
            local value = self:parseExpression()
            field = AST.tableField(key, value)
            
        elseif self:match(Lexer.TokenType.IDENTIFIER) and
               self:peek(1) and self:peek(1).type == Lexer.TokenType.OPERATOR and
               self:peek(1).value == "=" then
            -- name = value
            local key = self:advance()
            self:expect(Lexer.TokenType.OPERATOR, "=")
            local value = self:parseExpression()
            field = AST.tableField(AST.stringLiteral(key.value), value)
            
        else
            -- value (array part)
            local value = self:parseExpression()
            field = AST.tableField(nil, value)
        end
        
        table.insert(fields, field)
        
        if not self:consume(Lexer.TokenType.PUNCTUATION, ",") and
           not self:consume(Lexer.TokenType.PUNCTUATION, ";") then
            break
        end
    end
    
    self:expect(Lexer.TokenType.PUNCTUATION, "}")
    
    return AST.tableExpression(fields)
end

return Parser
