#!/usr/bin/env lua
--[[
    Luartex Obfuscator - Command Line Interface
    
    Usage: lua cli.lua [options] <input> [output]
]]

local Luartex = require("init")

local BANNER = [[
    ██╗     ██╗   ██╗ █████╗ ██████╗ ████████╗███████╗██╗  ██╗
    ██║     ██║   ██║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
    ██║     ██║   ██║███████║██████╔╝   ██║   █████╗   ╚███╔╝ 
    ██║     ██║   ██║██╔══██║██╔══██╗   ██║   ██╔══╝   ██╔██╗ 
    ███████╗╚██████╔╝██║  ██║██║  ██║   ██║   ███████╗██╔╝ ██╗
    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
                    
           v1.0.0 | discord.gg/GpucUKeCtF
]]

-- Parse command line arguments
local function parseArgs(args)
    local options = {
        input = nil,
        output = nil,
        preset = "standard",
        verbose = false,
        quiet = false,
        help = false,
        version = false,
        noMinify = false,
        roblox = false,
    }
    
    local i = 1
    while i <= #args do
        local arg = args[i]
        
        if arg == "-h" or arg == "--help" then
            options.help = true
        elseif arg == "-V" or arg == "--version" then
            options.version = true
        elseif arg == "-v" or arg == "--verbose" then
            options.verbose = true
        elseif arg == "-q" or arg == "--quiet" then
            options.quiet = true
        elseif arg == "-p" or arg == "--preset" then
            i = i + 1
            options.preset = args[i]
        elseif arg == "-o" or arg == "--output" then
            i = i + 1
            options.output = args[i]
        elseif arg == "--no-minify" then
            options.noMinify = true
        elseif arg == "--roblox" then
            options.roblox = true
        elseif arg:sub(1, 1) ~= "-" then
            if not options.input then
                options.input = arg
            elseif not options.output then
                options.output = arg
            end
        end
        
        i = i + 1
    end
    
    return options
end

-- Print help
local function printHelp()
    print(BANNER)
    print([[
USAGE:
    lua cli.lua [OPTIONS] <input> [output]

OPTIONS:
    -h, --help          Show this help message
    -V, --version       Show version information
    -v, --verbose       Enable verbose output
    -q, --quiet         Suppress all output
    -p, --preset NAME   Use preset (light, standard, hardened, maximum)
    -o, --output FILE   Output file path
    --no-minify         Disable minification
    --roblox            Enable Roblox-specific optimizations

PRESETS:
    light       Fast obfuscation, basic protection
    standard    Balanced protection (default)
    hardened    Strong protection, slower
    maximum     Maximum protection, very slow

EXAMPLES:
    lua cli.lua script.lua
    lua cli.lua -p maximum script.lua protected.lua
    lua cli.lua --roblox -p hardened game.lua

DISCORD:
    Join us at discord.gg/GpucUKeCtF
]])
end

-- Print version
local function printVersion()
    print("Luartex Obfuscator v" .. Luartex._VERSION)
    print("Discord: " .. Luartex._DISCORD)
end

-- Main function
local function main()
    local args = parseArgs(arg)
    
    if args.help then
        printHelp()
        return
    end
    
    if args.version then
        printVersion()
        return
    end
    
    if not args.quiet then
        print(BANNER)
    end
    
    if not args.input then
        print("Error: No input file specified")
        print("Use --help for usage information")
        os.exit(1)
    end
    
    -- Default output
    if not args.output then
        args.output = args.input:gsub("%.lua$", "") .. ".protected.lua"
    end
    
    -- Build configuration
    local config = {
        logLevel = args.quiet and "none" or (args.verbose and "debug" or "info"),
        minify = not args.noMinify,
        roblox = {
            enabled = args.roblox,
        },
    }
    
    -- Create obfuscator
    local luartex = Luartex.new(config)
    luartex:usePreset(args.preset)
    
    -- Process file
    local result, err = luartex:obfuscateFile(args.input, args.output)
    
    if not result then
        io.stderr:write("Error: " .. tostring(err) .. "\n")
        os.exit(1)
    end
    
    if not args.quiet then
        print("\n✅ Success! Protected file: " .. args.output)
        print("💬 Join our Discord: discord.gg/GpucUKeCtF")
    end
end

main()
