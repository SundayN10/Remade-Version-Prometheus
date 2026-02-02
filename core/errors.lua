--[[
    Luartex Error Handling
]]

local Errors = {}

-- Error types
Errors.Type = {
    PARSE_ERROR = "ParseError",
    COMPILE_ERROR = "CompileError",
    TRANSFORM_ERROR = "TransformError",
    CONFIG_ERROR = "ConfigError",
    FILE_ERROR = "FileError",
    RUNTIME_ERROR = "RuntimeError",
}

-- Create error object
function Errors.create(type, message, details)
    return {
        type = type,
        message = message,
        details = details or {},
        timestamp = os.time(),
        stack = debug.traceback("", 2),
    }
end

-- Format error for display
function Errors.format(err)
    local lines = {
        string.format("[%s] %s", err.type, err.message),
    }
    
    if err.details.line then
        table.insert(lines, string.format("  at line %d", err.details.line))
    end
    
    if err.details.column then
        table.insert(lines, string.format("  at column %d", err.details.column))
    end
    
    if err.details.source then
        table.insert(lines, string.format("  in: %s", err.details.source))
    end
    
    return table.concat(lines, "\n")
end

-- Throw error
function Errors.throw(type, message, details)
    local err = Errors.create(type, message, details)
    error(Errors.format(err), 2)
end

-- Assert with custom error
function Errors.assert(condition, type, message, details)
    if not condition then
        Errors.throw(type, message, details)
    end
    return condition
end

-- Wrap function with error handling
function Errors.wrap(fn)
    return function(...)
        local success, result = pcall(fn, ...)
        if success then
            return result
        else
            return nil, result
        end
    end
end

-- Try/catch style
function Errors.try(fn, catch)
    local success, result = pcall(fn)
    if success then
        return result
    else
        if catch then
            return catch(result)
        end
        return nil, result
    end
end

return Errors
