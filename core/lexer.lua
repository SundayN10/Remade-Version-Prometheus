--[[
    Luartex Lexer
    Tokenizes Lua source code
]]

local Lexer = {}
Lexer.__index = Lexer

-- Token types
Lexer.TokenType = {
    EOF = "EOF",
    IDENTIFIER = "IDENTIFIER",
    NUMBER = "NUMBER",
    STRING = "STRING",
    KEYWORD = "KEYWORD",
    OPERATOR = "OPERATOR",
    PUNCTUATION = "PUNCTUATION",
    COMMENT = "COMMENT",
    WHITESPACE = "WHITESPACE",
    NEWLINE = "NEWLINE",
}

-- Lua keywords
local KEYWORDS = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["goto"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true,
}

-- Operators
local OPERATORS = {
    ["+"] = true, ["-"] = true, ["*"] = true, ["/"] = true, ["%"] = true,
    ["^"] = true, ["#"] = true, ["=="] = true, ["~="] = true, ["<="] = true,
    [">="] = true, ["<"] = true, [">"] = true, ["="] = true, [".."] = true,
    ["..."] = true, ["//"] = true,
}

-- Punctuation
local PUNCTUATION = {
    ["("] = true, [")"] = true, ["{"] = true, ["}"] = true,
    ["["] = true, ["]"] = true, [";"] = true, [":"] = true,
    [","] = true, ["."] = true,
}

function Lexer.new(source)
    local self = setmetatable({}, Lexer)
    
    self.source = source
    self.position = 1
    self.line = 1
    self.column = 1
    self.tokens = {}
    
    return self
end

function Lexer:peek(offset)
    offset = offset or 0
    local pos = self.position + offset
    if pos > #self.source then
        return nil
    end
    return self.source:sub(pos, pos)
end

function Lexer:advance(count)
    count = count or 1
    for _ = 1, count do
        local char = self:peek()
        if char == "\n" then
            self.line = self.line + 1
            self.column = 1
        else
            self.column = self.column + 1
        end
        self.position = self.position + 1
    end
end

function Lexer:match(pattern)
    local match = self.source:match("^" .. pattern, self.position)
    return match
end

function Lexer:createToken(type, value)
    return {
        type = type,
        value = value,
        line = self.line,
        column = self.column,
        position = self.position,
    }
end

function Lexer:readString(quote)
    local start = self.position
    self:advance()  -- Skip opening quote
    
    local value = {}
    while true do
        local char = self:peek()
        
        if char == nil then
            error("Unterminated string at line " .. self.line)
        elseif char == quote then
            self:advance()
            break
        elseif char == "\\" then
            self:advance()
            local escape = self:peek()
            if escape then
                table.insert(value, "\\" .. escape)
                self:advance()
            end
        else
            table.insert(value, char)
            self:advance()
        end
    end
    
    return quote .. table.concat(value) .. quote
end

function Lexer:readLongString()
    local start = self.position
    local equals = 0
    
    self:advance()  -- Skip [
    while self:peek() == "=" do
        equals = equals + 1
        self:advance()
    end
    
    if self:peek() ~= "[" then
        error("Invalid long string at line " .. self.line)
    end
    self:advance()  -- Skip second [
    
    local closePattern = "]" .. string.rep("=", equals) .. "]"
    local content = {}
    
    while true do
        local char = self:peek()
        if char == nil then
            error("Unterminated long string at line " .. self.line)
        end
        
        -- Check for closing
        local remaining = self.source:sub(self.position)
        if remaining:sub(1, #closePattern) == closePattern then
            for _ = 1, #closePattern do self:advance() end
            break
        end
        
        table.insert(content, char)
        self:advance()
    end
    
    return "[[" .. table.concat(content) .. "]]"
end

function Lexer:readNumber()
    local value = {}
    local hasDecimal = false
    local hasExponent = false
    
    -- Check for hex
    if self:peek() == "0" and (self:peek(1) == "x" or self:peek(1) == "X") then
        table.insert(value, self:peek())
        self:advance()
        table.insert(value, self:peek())
        self:advance()
        
        while true do
            local char = self:peek()
            if char and char:match("[0-9a-fA-F]") then
                table.insert(value, char)
                self:advance()
            else
                break
            end
        end
        
        return table.concat(value)
    end
    
    while true do
        local char = self:peek()
        
        if char and char:match("%d") then
            table.insert(value, char)
            self:advance()
        elseif char == "." and not hasDecimal and not hasExponent then
            hasDecimal = true
            table.insert(value, char)
            self:advance()
        elseif (char == "e" or char == "E") and not hasExponent then
            hasExponent = true
            table.insert(value, char)
            self:advance()
            
            if self:peek() == "+" or self:peek() == "-" then
                table.insert(value, self:peek())
                self:advance()
            end
        else
            break
        end
    end
    
    return table.concat(value)
end

function Lexer:readIdentifier()
    local value = {}
    
    while true do
        local char = self:peek()
        if char and char:match("[%w_]") then
            table.insert(value, char)
            self:advance()
        else
            break
        end
    end
    
    return table.concat(value)
end

function Lexer:skipWhitespace()
    while true do
        local char = self:peek()
        if char == " " or char == "\t" or char == "\r" then
            self:advance()
        else
            break
        end
    end
end

function Lexer:readComment()
    local value = {}
    self:advance()  -- Skip first -
    self:advance()  -- Skip second -
    
    if self:peek() == "[" and (self:peek(1) == "[" or self:peek(1) == "=") then
        -- Long comment
        local start = self.position
        self:advance()  -- Skip [
        
        local equals = 0
        while self:peek() == "=" do
            equals = equals + 1
            self:advance()
        end
        
        if self:peek() == "[" then
            self:advance()
            local closePattern = "]" .. string.rep("=", equals) .. "]"
            
            while true do
                if self:peek() == nil then break end
                
                local remaining = self.source:sub(self.position)
                if remaining:sub(1, #closePattern) == closePattern then
                    for _ = 1, #closePattern do self:advance() end
                    break
                end
                
                self:advance()
            end
        end
    else
        -- Single line comment
        while self:peek() and self:peek() ~= "\n" do
            self:advance()
        end
    end
    
    return "--" .. table.concat(value)
end

function Lexer:nextToken()
    self:skipWhitespace()
    
    local char = self:peek()
    
    if char == nil then
        return self:createToken(Lexer.TokenType.EOF, nil)
    end
    
    -- Newline
    if char == "\n" then
        local token = self:createToken(Lexer.TokenType.NEWLINE, "\n")
        self:advance()
        return token
    end
    
    -- Comments
    if char == "-" and self:peek(1) == "-" then
        local comment = self:readComment()
        return self:createToken(Lexer.TokenType.COMMENT, comment)
    end
    
    -- Strings
    if char == "\"" or char == "'" then
        local str = self:readString(char)
        return self:createToken(Lexer.TokenType.STRING, str)
    end
    
    -- Long strings
    if char == "[" and (self:peek(1) == "[" or self:peek(1) == "=") then
        local str = self:readLongString()
        return self:createToken(Lexer.TokenType.STRING, str)
    end
    
    -- Numbers
    if char:match("%d") or (char == "." and self:peek(1) and self:peek(1):match("%d")) then
        local num = self:readNumber()
        return self:createToken(Lexer.TokenType.NUMBER, num)
    end
    
    -- Identifiers and keywords
    if char:match("[%a_]") then
        local id = self:readIdentifier()
        if KEYWORDS[id] then
            return self:createToken(Lexer.TokenType.KEYWORD, id)
        end
        return self:createToken(Lexer.TokenType.IDENTIFIER, id)
    end
    
    -- Multi-character operators
    local twoChar = self.source:sub(self.position, self.position + 1)
    local threeChar = self.source:sub(self.position, self.position + 2)
    
    if threeChar == "..." then
        self:advance(3)
        return self:createToken(Lexer.TokenType.OPERATOR, "...")
    end
    
    if OPERATORS[twoChar] then
        self:advance(2)
        return self:createToken(Lexer.TokenType.OPERATOR, twoChar)
    end
    
    -- Single character operators
    if OPERATORS[char] then
        self:advance()
        return self:createToken(Lexer.TokenType.OPERATOR, char)
    end
    
    -- Punctuation
    if PUNCTUATION[char] then
        self:advance()
        return self:createToken(Lexer.TokenType.PUNCTUATION, char)
    end
    
    -- Unknown character
    error("Unexpected character '" .. char .. "' at line " .. self.line)
end

function Lexer:tokenize()
    local tokens = {}
    
    while true do
        local token = self:nextToken()
        table.insert(tokens, token)
        
        if token.type == Lexer.TokenType.EOF then
            break
        end
    end
    
    self.tokens = tokens
    return tokens
end

return Lexer
