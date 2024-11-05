local _logger = require("logging")
local _storage = require("storage")
local _json = require("json")
local _core = require("core")
local _timer = require("timer")
local params = ... or {}

local function numeroPlugin()
    local my_gateway_id = (_core.get_gateway() or {}).id
    if not my_gateway_id then
        _logger.error("Failed to get current gateway ID, skip creating devices")
        return nil
    end
    for _, device in pairs(_core.get_devices() or {}) do
        if device.gateway_id == my_gateway_id then 
            if device.name == "Plugin ocupacion" then
                _logger.info("existe Plugin ocupacion: " .. _storage.get_number("numberPlugin"))
                return
            end
        end
    end
end

local _constants = require("HUB:plg.plugin_ocupacion/configs/constants")

_logger.info("<<<Plugin ocupacion starting up...>>>")
_G.constants = _constants or {}
local CREDENTIALS = _storage.get_string("CREDENTIALS")

if not _json then
    _timer.set_timeout(20000, "HUB:plg.plugin_ocupacion/scripts/startup", { arg_name = "arg_value" })
    _logger.info("failt start up, call delay...")
else
    _logger.info("params: " .. _json.encode(params))
    _logger.info("_constants: " .. _json.encode(_constants))
    if CREDENTIALS == _G.constants.CREDENTIALS then
        local numberPlugin = _storage.get_number("numberPlugin")
        _G.constants.OFFPUERTAABIERTA = _storage.get_string("OFFPUERTAABIERTA"..tostring(numberPlugin))
        _G.constants.MASTERSWITCH = _storage.get_string("MASTERSWITCH"..tostring(numberPlugin))
        _G.constants.MOTIONACTIVATOR = _storage.get_string("MOTIONACTIVATOR"..tostring(numberPlugin))
        _G.constants.IDMASTERSWITCH = _storage.get_string("IDMASTERSWITCH"..tostring(numberPlugin))
        _G.constants.SENSOR_PUERTA = _storage.get_string("SENSOR_PUERTA"..tostring(numberPlugin))
        _G.constants.ACTUADORES_ON = _storage.get_table("ACTUADORES_ON"..tostring(numberPlugin))
        _G.constants.ACTUADORES_OFF = _storage.get_table("ACTUADORES_OFF"..tostring(numberPlugin))
        _G.constants.SENSOR_MOV_BATT = _storage.get_table("SENSOR_MOV_BATT"..tostring(numberPlugin))
        _G.constants.SENSOR_MOV_ELEC = _storage.get_table("SENSOR_MOV_ELEC"..tostring(numberPlugin))
        _G.constants.TERMOSTATO = _storage.get_table("TERMOSTATO"..tostring(numberPlugin))
        _G.constants.SETPOINTON = _storage.get_number("SETPOINTON"..tostring(numberPlugin))
        _G.constants.SETPOINTOFF = _storage.get_number("SETPOINTOFF"..tostring(numberPlugin))
        _G.constants.MODOSETPOINT = _storage.get_string("MODOSETPOINT"..tostring(numberPlugin))
        _G.constants.TIEMPOSCAN = _storage.get_number("TIEMPOSCAN"..tostring(numberPlugin))
        loadfile("HUB:plg.plugin_ocupacion/scripts/items/initialdata")()
        loadfile("HUB:plg.plugin_ocupacion/scripts/functions/element")()
        loadfile("HUB:plg.plugin_ocupacion/scripts/functions/listen_item")()
        numeroPlugin()
    else
        _logger.info("no se han cargado los item ID de los equipos")
    end
end
