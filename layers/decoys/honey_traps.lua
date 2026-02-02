--[[
    Honey Traps
    Code that detects when someone is trying to analyze/modify the script
]]

local AST = require("core.ast")

local HoneyTraps = {}
HoneyTraps.__index = HoneyTraps

function HoneyTraps.new(parent)
    local self = setmetatable({}, HoneyTraps)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function HoneyTraps:inject(ast)
    -- Add honey trap functions that look important
    local traps = {
        self:generateLicenseCheck(),
        self:generateKeyValidator(),
        self:generateAntiCheat(),
    }
    
    for _, trap in ipairs(traps) do
        local position = self.random:int(1, #ast.body + 1)
        table.insert(ast.body, position, trap)
    end
    
    return ast
end

function HoneyTraps:generateLicenseCheck()
    local funcName = self.random:choice({
        "validateLicense", "checkLicense", "verifyKey",
        "authUser", "checkAuth", "validateUser"
    })
    funcName = funcName .. self.random:string(4)
    
    return AST.functionDeclaration(
        AST.identifier(funcName),
        { AST.identifier("key") },
        {
            AST.ifStatement({
                AST.ifClause(
                    AST.binaryExpression("~=",
                        AST.callExpression(
                            AST.identifier("type"),
                            { AST.identifier("key") }
                        ),
                        AST.stringLiteral("string")
                    ),
                    {
                        AST.returnStatement({ AST.booleanLiteral(false) })
                    }
                )
            }),
            AST.localStatement(
                { AST.identifier("hash") },
                {
                    AST.numberLiteral(0)
                }
            ),
            AST.forNumericStatement(
                AST.identifier("i"),
                AST.numberLiteral(1),
                AST.unaryExpression("#", AST.identifier("key")),
                nil,
                {
                    AST.assignmentStatement(
                        { AST.identifier("hash") },
                        {
                            AST.binaryExpression("+",
                                AST.identifier("hash"),
                                AST.callExpression(
                                    AST.memberExpression(
                                        AST.identifier("string"),
                                        AST.identifier("byte"),
                                        "."
                                    ),
                                    {
                                        AST.identifier("key"),
                                        AST.identifier("i")
                                    }
                                )
                            )
                        }
                    )
                }
            ),
            AST.returnStatement({
                AST.binaryExpression("==",
                    AST.binaryExpression("%",
                        AST.identifier("hash"),
                        AST.numberLiteral(1000)
                    ),
                    AST.numberLiteral(self.random:int(0, 999))
                )
            })
        },
        true
    )
end

function HoneyTraps:generateKeyValidator()
    local funcName = "decrypt" .. self.random:identifier(8)
    
    return AST.functionDeclaration(
        AST.identifier(funcName),
        { AST.identifier("data"), AST.identifier("key") },
        {
            AST.localStatement(
                { AST.identifier("result") },
                { AST.tableExpression({}) }
            ),
            AST.forNumericStatement(
                AST.identifier("i"),
                AST.numberLiteral(1),
                AST.unaryExpression("#", AST.identifier("data")),
                nil,
                {
                    AST.localStatement(
                        { AST.identifier("ki") },
                        {
                            AST.binaryExpression("+",
                                AST.binaryExpression("%",
                                    AST.binaryExpression("-",
                                        AST.identifier("i"),
                                        AST.numberLiteral(1)
                                    ),
                                    AST.unaryExpression("#", AST.identifier("key"))
                                ),
                                AST.numberLiteral(1)
                            )
                        }
                    ),
                    AST.callStatement(
                        AST.callExpression(
                            AST.memberExpression(
                                AST.identifier("table"),
                                AST.identifier("insert"),
                                "."
                            ),
                            {
                                AST.identifier("result"),
                                AST.callExpression(
                                    AST.memberExpression(
                                        AST.identifier("string"),
                                        AST.identifier("char"),
                                        "."
                                    ),
                                    {
                                        AST.callExpression(
                                            AST.memberExpression(
                                                AST.identifier("bit32"),
                                                AST.identifier("bxor"),
                                                "."
                                            ),
                                            {
                                                AST.callExpression(
                                                    AST.memberExpression(
                                                        AST.identifier("string"),
                                                        AST.identifier("byte"),
                                                        "."
                                                    ),
                                                    {
                                                        AST.identifier("data"),
                                                        AST.identifier("i")
                                                    }
                                                ),
                                                AST.callExpression(
                                                    AST.memberExpression(
                                                        AST.identifier("string"),
                                                        AST.identifier("byte"),
                                                        "."
                                                    ),
                                                    {
                                                        AST.identifier("key"),
                                                        AST.identifier("ki")
                                                    }
                                                )
                                            }
                                        )
                                    }
                                )
                            }
                        )
                    )
                }
            ),
            AST.returnStatement({
                AST.callExpression(
                    AST.memberExpression(
                        AST.identifier("table"),
                        AST.identifier("concat"),
                        "."
                    ),
                    { AST.identifier("result") }
                )
            })
        },
        true
    )
end

function HoneyTraps:generateAntiCheat()
    local funcName = "checkIntegrity" .. self.random:identifier(6)
    
    return AST.functionDeclaration(
        AST.identifier(funcName),
        {},
        {
            AST.localStatement(
                { AST.identifier("checks") },
                { AST.tableExpression({}) }
            ),
            AST.ifStatement({
                AST.ifClause(
                    AST.binaryExpression("~=",
                        AST.callExpression(
                            AST.identifier("type"),
                            { AST.identifier("game") }
                        ),
                        AST.stringLiteral("userdata")
                    ),
                    {
                        AST.returnStatement({ AST.booleanLiteral(false) })
                    }
                )
            }),
            AST.returnStatement({ AST.booleanLiteral(true) })
        },
        true
    )
end

return HoneyTraps
