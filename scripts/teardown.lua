local _logger = require("logging")
local _storage = require("storage")
local _core = require("core")
local _timer = require("timer")
local _json = require("json")

local params = ... or {}

_logger.info("params: " .. _json.encode(params))

_logger.info("Plugin ocupacion teardown...")


local devices = _core.get_devices()
local gateway_id = _core.get_gateway().id

if devices then
    for _, device in ipairs(devices) do
        if device.gateway_id == gateway_id then
            if _timer.exists(device.id) then
                _timer.cancel(device.id)
            end
        end
    end
end

function Purge()

    _core.unsubscribe("HUB:plg.plugin_ocupacion/scripts/functions/roomEight")
    _core.unsubscribe("HUB:plg.plugin_ocupacion/scripts/functions/roomSeven")
    _core.unsubscribe("HUB:plg.plugin_ocupacion/scripts/functions/roomSix")
    _core.unsubscribe("HUB:plg.plugin_ocupacion/scripts/functions/roomFive")
    _core.unsubscribe("HUB:plg.plugin_ocupacion/scripts/functions/roomFour")
    _core.unsubscribe("HUB:plg.plugin_ocupacion/scripts/functions/roomThree")
    _core.unsubscribe("HUB:plg.plugin_ocupacion/scripts/functions/roomTwo")
    _core.unsubscribe("HUB:plg.plugin_ocupacion/scripts/functions/roomOne")
    
    _logger.info("Remove all devices")
    _core.remove_gateway_devices(_core.get_gateway().id)

    _logger.info("Clear all storage")
    _storage.delete_all()
end

function OldFW()
    local fw = {}
    local firmware = _core.get_hub_info().firmware or ""
    _logger.info("FW: " .. firmware)
    for value in string.gmatch(firmware, "([^.]+)") do
        table.insert(fw, tonumber(value))
    end

    if #fw > 3 and (fw[1] < 2 or fw[2] < 0 or fw[3] < 31 or fw[4] < 2062) then
        _logger.info("Old firmware")
        return true
    end
    return false
end

local success, res = pcall(OldFW)
if success and res then
    Purge()
end



if params.operation then
    if params.operation == 'uninstall' then
        Purge()
    elseif params.operation == 'teardown' then
        _logger.info("params: " .. _json.encode(params))
    else
        _logger.error('Unrecognized teardown operation ' .. params.operation)
    end
end