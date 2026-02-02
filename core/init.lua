--[[
    Luartex Core Module Loader
]]

local Core = {}

Core.Logger = require("core.logger")
Core.Parser = require("core.parser")
Core.Compiler = require("core.compiler")
Core.Lexer = require("core.lexer")
Core.AST = require("core.ast")
Core.Random = require("core.random")
Core.Utils = require("core.utils")
Core.Errors = require("core.errors")

return Core
