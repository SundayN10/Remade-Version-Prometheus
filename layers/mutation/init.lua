--[[
    Luartex Mutation Layer
    Transforms code structure and naming
]]

local AST = require("core.ast")
local Utils = require("core.utils")

local Mutation = {}
Mutation.__index = Mutation

function Mutation.new(luartex)
    local self = setmetatable({}, Mutation)
    
    self.luartex = luartex
    self.config = luartex.config.mutation
    self.random = luartex.random
    self.logger = luartex.logger
    
    -- Sub-modules
    self.variableRenamer = require("layers.mutation.variable_renamer").new(self)
    self.constantFolder = require("layers.mutation.constant_folder").new(self)
    self.deadCodeInjection = require("layers.mutation.dead_code_injection").new(self)
    self.expressionMutator = require("layers.mutation.expression_mutator").new(self)
    self.structureRandomizer = require("layers.mutation.structure_randomizer").new(self)
    
    return self
end

function Mutation:apply(ast)
    self.logger:debug("Applying mutation layer...")
    
    -- Step 1: Rename variables
    if self.config.renameVariables then
        ast = self.variableRenamer:rename(ast)
    end
    
    -- Step 2: Mutate expressions
    if self.config.expressionMutation then
        ast = self.expressionMutator:mutate(ast)
    end
    
    -- Step 3: Inject dead code
    if self.config.deadCodeInjection then
        ast = self.deadCodeInjection:inject(ast)
    end
    
    -- Step 4: Fold constants (adds complexity)
    ast = self.constantFolder:fold(ast)
    
    -- Step 5: Randomize structure
    ast = self.structureRandomizer:randomize(ast)
    
    return ast
end

return Mutation
