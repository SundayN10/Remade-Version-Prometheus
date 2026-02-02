--[[
    Luartex Logger
    Beautiful console output with colors
]]

local Logger = {}
Logger.__index = Logger

local LEVELS = {
    debug = 1,
    info = 2,
    warn = 3,
    error = 4,
    none = 5,
}

local COLORS = {
    reset = "\27[0m",
    bold = "\27[1m",
    dim = "\27[2m",
    
    black = "\27[30m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m",
    
    bgRed = "\27[41m",
    bgGreen = "\27[42m",
    bgYellow = "\27[43m",
    bgBlue = "\27[44m",
}

local LEVEL_COLORS = {
    debug = COLORS.dim .. COLORS.cyan,
    info = COLORS.green,
    warn = COLORS.yellow,
    error = COLORS.bold .. COLORS.red,
}

local LEVEL_ICONS = {
    debug = "🔍",
    info = "✨",
    warn = "⚠️ ",
    error = "❌",
}

function Logger.new(level)
    local self = setmetatable({}, Logger)
    
    self.level = LEVELS[level] or LEVELS.info
    self.useColors = true
    self.useIcons = true
    self.prefix = "[Luartex]"
    
    return self
end

function Logger:_format(level, message)
    local parts = {}
    
    -- Timestamp
    table.insert(parts, COLORS.dim .. os.date("[%H:%M:%S]") .. COLORS.reset)
    
    -- Prefix
    table.insert(parts, COLORS.magenta .. self.prefix .. COLORS.reset)
    
    -- Level
    local levelStr
    if self.useColors then
        levelStr = LEVEL_COLORS[level] .. string.upper(level) .. COLORS.reset
    else
        levelStr = string.upper(level)
    end
    
    if self.useIcons then
        table.insert(parts, LEVEL_ICONS[level] .. " " .. levelStr)
    else
        table.insert(parts, "[" .. levelStr .. "]")
    end
    
    -- Message
    table.insert(parts, message)
    
    return table.concat(parts, " ")
end

function Logger:_log(level, message, ...)
    if LEVELS[level] < self.level then
        return
    end
    
    if select("#", ...) > 0 then
        message = string.format(message, ...)
    end
    
    local formatted = self:_format(level, message)
    
    if level == "error" then
        io.stderr:write(formatted .. "\n")
    else
        print(formatted)
    end
end

function Logger:debug(message, ...)
    self:_log("debug", message, ...)
end

function Logger:info(message, ...)
    self:_log("info", message, ...)
end

function Logger:warn(message, ...)
    self:_log("warn", message, ...)
end

function Logger:error(message, ...)
    self:_log("error", message, ...)
end

function Logger:success(message, ...)
    if self.level <= LEVELS.info then
        local formatted = COLORS.bold .. COLORS.green .. "✅ " .. 
                         string.format(message, ...) .. COLORS.reset
        print(formatted)
    end
end

function Logger:banner(text)
    if self.level <= LEVELS.info then
        print(COLORS.cyan .. string.rep("═", 60) .. COLORS.reset)
        print(COLORS.bold .. COLORS.cyan .. "  " .. text .. COLORS.reset)
        print(COLORS.cyan .. string.rep("═", 60) .. COLORS.reset)
    end
end

function Logger:progress(current, total, label)
    if self.level > LEVELS.info then return end
    
    local width = 30
    local filled = math.floor((current / total) * width)
    local empty = width - filled
    
    local bar = COLORS.green .. string.rep("█", filled) .. 
                COLORS.dim .. string.rep("░", empty) .. COLORS.reset
    
    local percent = math.floor((current / total) * 100)
    
    io.write(string.format("\r%s [%s] %d%% %s", 
        self.prefix, bar, percent, label or ""))
    io.flush()
    
    if current >= total then
        print()
    end
end

return Logger
