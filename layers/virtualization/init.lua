--[[
    Luartex Virtualization Layer
    Converts Lua code to run on a custom virtual machine
]]

local AST = require("core.ast")
local Utils = require("core.utils")

local Virtualization = {}
Virtualization.__index = Virtualization

function Virtualization.new(luartex)
    local self = setmetatable({}, Virtualization)
    
    self.luartex = luartex
    self.config = luartex.config.virtualization
    self.random = luartex.random
    self.logger = luartex.logger
    
    -- Sub-modules
    self.vmGenerator = require("layers.virtualization.vm_generator").new(self)
    self.bytecodeCompiler = require("layers.virtualization.bytecode_compiler").new(self)
    self.instructionSet = require("layers.virtualization.instruction_set").new(self)
    
    return self
end

function Virtualization:apply(ast)
    self.logger:debug("Applying virtualization layer...")
    
    -- Generate unique instruction set
    local instructions = self.instructionSet:generate()
    
    -- Generate VM runtime
    local vmRuntime = self.vmGenerator:generate(instructions)
    
    -- Compile functions to bytecode
    local virtualizedCount = 0
    
    AST.transform(ast, {
        [AST.NodeType.FUNCTION_DECLARATION] = function(node)
            if self.random:bool(0.6) then
                local result = self:virtualizeFunction(node, instructions)
                if result then
                    virtualizedCount = virtualizedCount + 1
                    return result
                end
            end
            return node
        end,
    })
    
    -- Inject VM runtime at the beginning
    if virtualizedCount > 0 then
        self:injectVMRuntime(ast, vmRuntime)
        self.luartex.stats.functionsVirtualized = virtualizedCount
        self.logger:debug("Virtualized " .. virtualizedCount .. " functions")
    end
    
    return ast
end

function Virtualization:virtualizeFunction(funcNode, instructions)
    -- Compile function body to bytecode
    local bytecode, err = self.bytecodeCompiler:compile(funcNode.body, instructions)
    
    if not bytecode then
        self.logger:debug("Could not virtualize function: " .. tostring(err))
        return nil
    end
    
    -- Create bytecode array
    local bytecodeArray = {}
    for _, byte in ipairs(bytecode) do
        table.insert(bytecodeArray, AST.numberLiteral(byte))
    end
    
    -- Replace function body with VM call
    local vmCallName = self.vmGenerator.vmExecuteName
    
    local newBody = {
        AST.returnStatement({
            AST.callExpression(
                AST.identifier(vmCallName),
                {
                    AST.tableExpression(
                        Utils.map(bytecodeArray, function(n)
                            return AST.tableField(nil, n)
                        end)
                    )
                }
            )
        })
    }
    
    funcNode.body = newBody
    return funcNode
end

function Virtualization:injectVMRuntime(ast, vmRuntime)
    -- Parse VM runtime code
    local Parser = require("core.parser")
    local vmAST = Parser.parse(vmRuntime)
    
    -- Prepend to AST
    for i = #vmAST.body, 1, -1 do
        table.insert(ast.body, 1, vmAST.body[i])
    end
end

return Virtualization
