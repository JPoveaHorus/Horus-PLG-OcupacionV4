local _core = require("core")
local _logger = require("logging")
local _storage = require("storage")

local numberPlugin = _storage.get_number("numberPlugin")

local  function errorHandler(err)
    _logger.error("error just reported!: " .. err)
end

-- local status, resultado = xpcall(dividir, manejarError, 10, 0)
local function ListenDevices()
    local status, resultado
    if numberPlugin == 1 then
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomOne")
    end
    
    if numberPlugin == 2 then
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomOne")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomTwo")
    end

    if numberPlugin == 3 then
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomOne")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomTwo")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomThree")
    end

    if numberPlugin == 4 then
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomOne")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomTwo")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomThree")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomFour")
    end

    if numberPlugin == 5 then
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomOne")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomTwo")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomThree")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomFour")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomFive")
    end

    if numberPlugin == 6 then
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomOne")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomTwo")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomThree")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomFour")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomFive")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomSix")
    end
    
    if numberPlugin == 7 then
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomOne")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomTwo")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomThree")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomFour")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomFive")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomSix")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomSeven")
    end

    if numberPlugin == 8 then
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomOne")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomTwo")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomThree")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomFour")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomFive")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomSix")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomSeven")
        status, resultado = xpcall(_core.subscribe, errorHandler ,"HUB:plg.plugin_ocupacion/scripts/functions/roomEight")
    end

    if status then
        _logger.info('Get listen items room: ' .. numberPlugin..", "..resultado)
        _core.send_ui_broadcast {
            status = 'success',
            message = 'Get listen items room: ' .. numberPlugin..", "..resultado,
        }
    else
        _logger.error("Failed subcribe")
    end
end

ListenDevices()
