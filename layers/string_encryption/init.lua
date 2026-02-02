--[[
    Luartex String Encryption Layer
    Encrypts all strings in the code
]]

local AST = require("core.ast")
local Utils = require("core.utils")

local StringEncryption = {}
StringEncryption.__index = StringEncryption

function StringEncryption.new(luartex)
    local self = setmetatable({}, StringEncryption)
    
    self.luartex = luartex
    self.config = luartex.config.stringEncryption
    self.random = luartex.random
    self.logger = luartex.logger
    
    -- Encryption methods
    self.methods = {
        xor = require("layers.string_encryption.xor_cipher"),
        aes = require("layers.string_encryption.aes_light"),
        base = require("layers.string_encryption.base_encoding"),
    }
    
    self.encryptedStrings = {}
    self.decryptorName = nil
    self.keyName = nil
    
    return self
end

function StringEncryption:apply(ast)
    self.encryptedStrings = {}
    self.decryptorName = self.random:identifier(16)
    self.keyName = self.random:identifier(16)
    
    -- Generate encryption key
    self.key = self.random:string(self.config.keyLength)
    
    -- Find and encrypt all strings
    self:transformStrings(ast)
    
    -- If we encrypted any strings, add the decryptor
    if #self.encryptedStrings > 0 then
        self:injectDecryptor(ast)
        self.luartex.stats.stringsEncrypted = #self.encryptedStrings
        self.logger:debug("Encrypted " .. #self.encryptedStrings .. " strings")
    end
    
    return ast
end

function StringEncryption:transformStrings(ast)
    local self_ref = self
    
    AST.transform(ast, {
        [AST.NodeType.STRING_LITERAL] = function(node)
            -- Skip empty strings
            if not node.value or #node.value == 0 then
                return node
            end
            
            -- Skip very short strings
            if #node.value < 3 then
                return node
            end
            
            return self_ref:encryptString(node)
        end,
    })
end

function StringEncryption:encryptString(node)
    local plaintext = node.value
    local method = self.config.method
    
    -- Choose encryption method
    local encrypted
    if method == "multi" then
        encrypted = self:multiLayerEncrypt(plaintext)
    elseif method == "xor" then
        encrypted = self.methods.xor.encrypt(plaintext, self.key)
    elseif method == "aes" then
        encrypted = self.methods.aes.encrypt(plaintext, self.key)
    else
        encrypted = self.methods.xor.encrypt(plaintext, self.key)
    end
    
    -- Store encrypted data
    local index = #self.encryptedStrings + 1
    table.insert(self.encryptedStrings, {
        original = plaintext,
        encrypted = encrypted,
        index = index,
    })
    
    -- Replace with decryptor call
    return AST.callExpression(
        AST.identifier(self.decryptorName),
        { AST.numberLiteral(index) }
    )
end

function StringEncryption:multiLayerEncrypt(plaintext)
    -- Layer 1: XOR
    local step1 = self.methods.xor.encrypt(plaintext, self.key)
    
    -- Layer 2: Base64
    local step2 = self.methods.base.encode(step1)
    
    -- Layer 3: Reverse
    local step3 = step2:reverse()
    
    -- Layer 4: XOR again with different key
    local key2 = self.key:reverse()
    local step4 = self.methods.xor.encrypt(step3, key2)
    
    return Utils.base64Encode(step4)
end

function StringEncryption:injectDecryptor(ast)
    -- Generate the decryptor function
    local decryptorCode = self:generateDecryptor()
    
    -- Parse the decryptor
    local Parser = require("core.parser")
    local decryptorAST = Parser.parse(decryptorCode)
    
    -- Prepend to the AST body
    for i = #decryptorAST.body, 1, -1 do
        table.insert(ast.body, 1, decryptorAST.body[i])
    end
end

function StringEncryption:generateDecryptor()
    local strings = {}
    
    for _, data in ipairs(self.encryptedStrings) do
        -- Escape the encrypted string
        local escaped = Utils.escapeLuaString(data.encrypted)
        table.insert(strings, '"' .. escaped .. '"')
    end
    
    local stringsTable = "{" .. table.concat(strings, ",") .. "}"
    local keyStr = Utils.escapeLuaString(self.key)
    
    local code = string.format([[
local %s = "%s"
local %s = %s
local %s
do
    local function xd(s, k)
        local r = {}
        local kl = #k
        for i = 1, #s do
            local ki = ((i - 1) %% kl) + 1
            local sb = string.byte(s, i)
            local kb = string.byte(k, ki)
            r[i] = string.char(sb ~ kb)
        end
        return table.concat(r)
    end
    
    local function b64d(d)
        local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local r = {}
        d = d:gsub("[^" .. b .. "=]", "")
        for i = 1, #d, 4 do
            local a, b, c, d = d:byte(i, i + 3)
            a = b:find(string.char(a)) - 1
            b = b:find(string.char(b)) - 1
            c = c and b:find(string.char(c)) - 1 or 0
            d = d and b:find(string.char(d)) - 1 or 0
            local n = a * 262144 + b * 4096 + c * 64 + d
            table.insert(r, string.char(math.floor(n / 65536) %% 256))
            if c then table.insert(r, string.char(math.floor(n / 256) %% 256)) end
            if d then table.insert(r, string.char(n %% 256)) end
        end
        return table.concat(r)
    end
    
    local cache = {}
    %s = function(i)
        if cache[i] then return cache[i] end
        local e = %s[i]
        local d = b64d(e)
        local k2 = %s:reverse()
        d = xd(d, k2)
        d = d:reverse()
        d = b64d(d)
        d = xd(d, %s)
        cache[i] = d
        return d
    end
end
]], self.keyName, keyStr, 
    self.random:identifier(12), stringsTable,
    self.decryptorName, 
    self.random:identifier(12),
    self.keyName,
    self.keyName)
    
    return code
end

return StringEncryption
