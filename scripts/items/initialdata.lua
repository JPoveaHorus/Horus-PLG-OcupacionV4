local _storage = require("storage")
local _logger = require("logging")

local numberPlugin = _storage.get_number("numberPlugin")

local settings = {
    "Mode",
    "Type",
    "Counting",
    "dueTimestamp",
    "remaining",
    "TimerDuration",
    "statusText",
    "accionTexto",
    "accion",
    "timerAccion",
    "ScanCycle",
    "TimerID",
    "TimerIdTick",
    "Remaining_ant",
    "previousTimer",
}

for _, setting in ipairs(settings) do
    local key = setting .. numberPlugin
    _logger.info(key)
    -- local value = (setting == "accion") and 0 or ((setting == "TimerDuration") and 0 or "")
    local valueNumber = 0
    local valueString = "0"
    local valueStringText = "Libre"
    local valueStringGeneral = ""

    if setting == "dueTimestamp" or setting == "accion" or setting == "TimerDuration" or setting == "Remaining_ant1" or setting == "previousTimer" then
        _storage.set_number(key, valueNumber)
    elseif setting == "remaining" or setting == "Counting" or setting == "timerAccion" then
        _storage.set_string(key, valueString)
    elseif setting == "statusText" then
        _storage.set_string(key, valueStringText)
    elseif setting == "Mode" then
        _storage.set_string(key, "Auto")
    elseif setting == "Type" then
        _storage.set_string(key, "Hotel")
    else
        _storage.set_string(key, valueStringGeneral)
    end
end

