local _logger = require("logging")
local _storage = require("storage")
local _core = require("core")
local _json = require("json")

_logger.info('Setting Changed')
_logger.debug(...)

local numberPlugin = _storage.get_number("numberPlugin")
local args = ... or {}

-- Definir una tabla con los identificadores y sus nombres correspondientes
local settingIdentifiers = {
    {id = "settinAccion", name = "settingAccion"},
    {id = "settingActuadoresOn", name = "settingActuadoresOn"},
    {id = "settingActuadoresOff", name = "settingActuadoresOff"},
    {id = "settingSensorPuerta", name = "settinSensorPuerta"},
    {id = "settingSensorMovBatt", name = "settingSensorMovBatt"},
    {id = "settingSensorMovElec", name = "settingSensorMovElec"},
    {id = "settingMasterSwitch", name = "settingmasterSwitch"},
    {id = "settingOffPuertaAbierta", name = "settingOffPuertaAbierta"},
    {id = "settingmodosetpoint", name = "settingmodosetpoint"},
    {id = "settingDisparadorMov", name = "settingDisparadorMov"},
}

-- Iterar sobre los identificadores y verificar si coinciden con el argumento
for _, settingInfo in ipairs(settingIdentifiers) do
    local settingId = settingInfo.id .. tostring(numberPlugin)
    local settingName = settingInfo.name

    local success, settingValue = pcall(_core.get_setting, settingId)

    if success then
        _logger.debug(settingName .. ": " .. _json.encode(settingValue))
    else
        _logger.error("Error al obtener el valor de " .. settingName .. ": " .. settingValue)
    end
end