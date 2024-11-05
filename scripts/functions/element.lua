local _logger = require("logging")
local _core = require("core")
local _storage = require("storage")
local _json = require("json")

local numberPlugin = _storage.get_number("numberPlugin")

_logger.info("*** Plugin ocupacion ejecucion element ***")

_G.thermostatvar = {}

local function initializeThermostat()
    if _G.constants.TERMOSTATO then
        _logger.info("Thermostat items: " .. _json.encode(_G.constants.TERMOSTATO))
    else
        _logger.warning("TERMOSTATO is nil")
    end
end

local function configureSetting(itemId, storageVar, settingName)
    local item = _core.get_item(itemId)
    _logger.info("name: " .. storageVar .. ", id: " .. item.id)
    _logger.info("settingId: " .. settingName)
    local settingIdString =  _storage.get_string(settingName)

    local success, errmsg = pcall(_core.set_setting_value, settingIdString, tostring(item.id), "synced")

    if not success then
        _logger.error("Failed set setting: " .. (errmsg and (", error: " .. errmsg) or ""))
    else
        _logger.info("Success set setting: " .. item.name)
    end
end

local function initializeElectricMotionSensor()
    if _G.constants.SENSOR_MOV_ELEC then
        for _, itemId in ipairs(_G.constants.SENSOR_MOV_ELEC) do
            configureSetting(itemId, "sernsorMovElec", "settingSensorMovElec" .. tostring(numberPlugin))
        end
    else
        _logger.warning("SENSOR_MOV_ELEC is nil")
    end
end

local function initializeBatteryMotionSensor()
    if _G.constants.SENSOR_MOV_BATT then
        for _, itemId in ipairs(_G.constants.SENSOR_MOV_BATT) do
            configureSetting(itemId, "sernsorMovBatt", "settingSensorMovBatt" .. tostring(numberPlugin))
        end
    else
        _logger.warning("SENSOR_MOV_BATT is nil")
    end
end

local function initializeActuatorsOn()
    if _G.constants.ACTUADORES_ON then
        _logger.info(_json.encode(_G.constants.ACTUADORES_ON))
        for _, itemId in ipairs(_G.constants.ACTUADORES_ON) do
            configureSetting(itemId, "actuadoresOn" .. tostring(numberPlugin),
                "settingActuadoresOn" .. tostring(numberPlugin))
        end
    else
        _logger.warning("ACTUADORES_ON is nil")
    end
end

local function initializeActuatorsOff()
    if _G.constants.ACTUADORES_OFF then
        _logger.info(_json.encode(_G.constants.ACTUADORES_OFF))
        for _, itemId in ipairs(_G.constants.ACTUADORES_OFF) do
            configureSetting(itemId, "actuadoresOff" .. tostring(numberPlugin),
                "settingActuadoresOff" .. tostring(numberPlugin))
        end
    else
        _logger.warning("ACTUADORES_OFF is nil")
    end
end

local function initializeDoorSensor()
    if _G.constants.SENSOR_PUERTA then
        local sensor_puerta = _core.get_item(_storage.get_string("SENSOR_PUERTA" .. tostring(numberPlugin)))

        if sensor_puerta then
        _G.contador = 0
        local sensor_puerta_id = tostring(sensor_puerta.id)
        _logger.info("Door sensor id: " .. sensor_puerta_id)
        _G.ITEM_NAME_SENSOR_PUERTA = sensor_puerta.id

        configureSetting(sensor_puerta_id, "sensorPuerta" .. tostring(numberPlugin),
            "settingSensorPuerta" .. tostring(numberPlugin))
        end
        _core.send_ui_broadcast {
            status = 'success',
            message = 'Variables successfully in the file element',
        }
    else
        _logger.warning("SENSOR_PUERTA is nil")

    end
end
initializeThermostat()
initializeElectricMotionSensor()
initializeBatteryMotionSensor()
initializeActuatorsOn()
initializeActuatorsOff()
initializeDoorSensor()
