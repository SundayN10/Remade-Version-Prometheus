--[[
    Luartex Control Flow Obfuscation Layer
    Flattens and obfuscates control flow
]]

local AST = require("core.ast")
local Utils = require("core.utils")

local ControlFlow = {}
ControlFlow.__index = ControlFlow

function ControlFlow.new(luartex)
    local self = setmetatable({}, ControlFlow)
    
    self.luartex = luartex
    self.config = luartex.config.controlFlow
    self.random = luartex.random
    self.logger = luartex.logger
    
    -- Sub-modules
    self.flattener = require("layers.control_flow.flattener").new(self)
    self.opaquePredicates = require("layers.control_flow.opaque_predicates").new(self)
    self.bogusBranches = require("layers.control_flow.bogus_branches").new(self)
    self.loopTransformer = require("layers.control_flow.loop_transformer").new(self)
    
    return self
end

function ControlFlow:apply(ast)
    self.logger:debug("Applying control flow obfuscation...")
    
    -- Step 1: Transform loops
    ast = self.loopTransformer:transform(ast)
    
    -- Step 2: Add opaque predicates
    if self.config.opaquePredicates then
        ast = self.opaquePredicates:inject(ast)
    end
    
    -- Step 3: Add bogus branches
    if self.config.bogusBranches then
        ast = self.bogusBranches:inject(ast)
    end
    
    -- Step 4: Flatten control flow
    if self.config.flattenIntensity > 0 then
        ast = self.flattener:flatten(ast)
    end
    
    return ast
end

return ControlFlow
