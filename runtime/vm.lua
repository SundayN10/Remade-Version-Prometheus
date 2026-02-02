--[[
    Luartex VM Runtime
    Minimal VM for running virtualized code
]]

local VM = {}

function VM.create(config)
    local vm = {
        stack = {},
        sp = 0,
        registers = {},
        pc = 1,
        bytecode = nil,
        constants = config.constants or {},
        running = false,
    }
    
    function vm:push(value)
        self.sp = self.sp + 1
        self.stack[self.sp] = value
    end
    
    function vm:pop()
        local value = self.stack[self.sp]
        self.stack[self.sp] = nil
        self.sp = self.sp - 1
        return value
    end
    
    function vm:peek()
        return self.stack[self.sp]
    end
    
    function vm:run(bytecode, ...)
        self.bytecode = bytecode
        self.pc = 1
        self.stack = {}
        self.sp = 0
        self.registers = {...}
        self.running = true
        
        while self.running and self.pc <= #bytecode do
            local opcode = bytecode[self.pc]
            self.pc = self.pc + 1
            
            local handler = config.handlers[opcode]
            if handler then
                local result = handler(self)
                if result ~= nil then
                    return result
                end
            end
        end
        
        return self:pop()
    end
    
    return vm
end

return VM
