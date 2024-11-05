-- Preconfiguracion para uso solo de observación
------------module require---------------------------------------------------------------------------
local _core = require("core")
local _logger = require("logging")
local _timer = require("timer")
local _json = require("json")
local _storage = require("storage")
local params = ... or {}
-----------------------------------------------------------------------------------------------------

------------variable locales-------------------------------------------------------------------------


local verde = 32
local amarillo = 33
local rojo = 31

local ACCION_LIBRE = 0
local ACCION_AUTOOFF = 20
local ACCION_PABIERTA = 40
local ACCION_CICLO_APAGADO = 60
local ACCION_SCAN = 80
local ACCION_OCUPADO = 100

local MODO_APAGADO = "Apagado"
local MODO_MANUAL = "Manual"
local MODO_AUTO = "Auto"

local PreOffAireDoor = "si"

local sensor_puerta = _storage.get_string("SENSOR_PUERTA1")
local devicesOn = _storage.get_table("ACTUADORES_ON1")
local devicesOff = _storage.get_table("ACTUADORES_OFF1")
local SensorMovbatt = _storage.get_table("SENSOR_MOV_BATT1")
local SensorMovElec = _storage.get_table("SENSOR_MOV_ELEC1")
local thermostat = _storage.get_table("TERMOSTATO1")
local idmasterswitch = _storage.get_string("MASTERSWITCH1")
local modoPluginStatus = _storage.get_string("ModoId1")
local AccionPluginStatus = _storage.get_string("AccionTextoId1")
local EstadoPluginStatus = _storage.get_string("EstadoTextoId1")
local offpuertaabierta = _storage.get_string("OFFPUERTAABIERTA1")
local masterswitch = _storage.get_string("MASTERSWITCH1")
local motionActivator = _storage.get_string("MOTIONACTIVATOR1")
local SetPointOn = _storage.get_number("SETPOINTON1")
local SetPointOff = _storage.get_number("SETPOINTOFF1")
local ModoSetpoint = _storage.get_string("MODOSETPOINT1")

----- Tiempos del Plugin
 
local Tiempo_ocupacion = 450            -- (450*2) 7.5 minutos de ocupación
local Tiempo_puerta = 150               -- (150) org
local Tiempo_apagado = 60
local TiempoLibre = 10
local Tiemposensor = _storage.get_number("TIEMPOSCAN1")
local TiempoScan = 540  -- 18 Minutos de Scan
local Tiemporesultante = math.floor(Tiemposensor/2)  -- Reduce el tiempo configurado a la mitad
local Tiempo1 = Tiemporesultante  -- Ciclo Scan 1
local Tiempo2 = TiempoScan-Tiempo1  -- Ciclo Scan 2

local umbralTime1 = 0
local umbralTime2 = 140                             -- (150*2) Tiempo de sensado inicial

-------------------------------------------------------------
--- verification and validation functions of the variables
-----------------------------------------------------------------

local data = {}
data.modo = _storage.get_string('Mode1')
data.type = _storage.get_string('type1')
data.counting = _storage.get_string("Counting1")
data.dueTimestamp = _storage.get_number("dueTimestamp1")
data.remaining = _storage.get_string("remaining1")
data.statustext = _storage.get_string("statusText1")
data.acciontext = _storage.get_string('accionTexto1')
data.scancycle = _storage.get_string('scanCycle1')
data.accion = _storage.get_number("accion1")
data.timeraccion = _storage.get_string('timerAccion1')
data.timerduration = _storage.get_number('TimerDuration1')
data.TimerID = _storage.get_string("TimerID1")
data.TimerIdTick = _storage.get_string("TimerIdTick1")
data.Remaining_ant = _storage.get_number("Remaining_ant1")
data.settingAccionId = _storage.get_string("settinAccion1")
data.previousTimer = _storage.get_number("previousTimer1")
    

--imprimir registros en el controlador
--##############################################
-- Función para registrar mensajes
local function Registro(Mensaje, color)
    local prefix = "[ Horus Smart Energy ] "
    if color then
        _logger.info(prefix .. "\27[" .. color .. "m" .. Mensaje .. "\27[0m")
    else
        _logger.info(prefix .. Mensaje)
    end
end
--##############################################




function ThermostatPower(item_id, value)
    Registro("Thermostat: " .. thermostat.mode.name .. thermostat.mode._id, amarillo)
    Registro("Encendido Aire", amarillo)

    _core.set_item_value(item_id, value)

    _timer.set_timeout(5000, "HUB:plg.plugin_ocupacion/scripts/functions/thermostat",
    { itemId = item_id, itemValue = value })

end
function SetPointTermostato(item_id, value)
    Registro("Thermostat: " .. thermostat.mode.name .. thermostat.setpoint._id, amarillo)

    _timer.set_timeout(10000, "HUB:plg.plugin_ocupacion/scripts/functions/thermostat",
    { itemId = item_id, itemValue = value })

    _timer.set_timeout(15000, "HUB:plg.plugin_ocupacion/scripts/functions/thermostat",
    { itemId = item_id, itemValue = value })

end
function SetFanTermostato(item_id, value)
    Registro("Thermostat: " .. thermostat.mode.name .. thermostat.setpoint._id, amarillo)

    _timer.set_timeout(20000, "HUB:plg.plugin_ocupacion/scripts/functions/thermostat",
    { itemId = item_id, itemValue = value })

end


for i = 1, 2 do
    if data.modo == "Auto" then
        if motionActivator == "si" and thermostat ~= nil then
            Registro("Intento On Thermo: " .. i)

            if thermostat.mode.value ~= "cool" then
                ThermostatPower(thermostat.mode._id, "cool")
            end
            if thermostat.setpoint.value ~= SetPointOn then
                SetPointTermostato(thermostat.setpoint._id, SetPointOn)
            end
            if thermostat.fanMode.value ~= "auto_low" then
                SetFanTermostato(thermostat.fanMode._id, "auto_low")
            end

        else
            Registro("no tiene termostato", amarillo)
        end
    end
end

--Thermostado Funcion
ThermostatPower(thermostat.mode._id, "off")

-- Funcion Set Value
local function setItemValue(itemId, value)
    local success, result = xpcall(
        function()
            return _core.set_item_value(itemId, value)
        end,
        function(err)
            Registro("Error al establecer el valor del ítem " .. itemId .. ": " .. (err or "Error desconocido"), rojo)
            return err -- Importante: devolver el error para xpcall
        end
    )
    if not success then
        Registro("Error en el manejador de errores para " .. itemId .. ": " .. (result or "Error desconocido"), rojo)
    else
        Registro("device: " .. itemId .. ", value: " .. _json.encode(value))
    end
end


function PuertaAbiertaLibre()
    local contador, contadorDisparos, contadorLibres = 0, 0, 0
    local EstadoTextoId = _storage.get_string("EstadoTextoId1")

    local function contarSensores(sensores)
        if sensores ~= nil then
            for _, sensor in ipairs(sensores) do
                contador = contador + 1
                local sensor_id = _core.get_item(sensor)
                if sensor_id.value == true then
                    contadorDisparos = contadorDisparos + 1
                else
                    contadorLibres = contadorLibres + 1
                end
            end
        end
    end

    -- Contar los sensores de ambos tipos
    contarSensores(SensorMovbatt)
    contarSensores(SensorMovElec)

    -- Verificar los resultados de los contadores
    if contador == contadorLibres then
        CancelTimer()
        Verificar("statusText1", "Libre")
        setItemValue(EstadoTextoId, "Libre")
        
        if _storage.get_string("Mode1") ~= MODO_APAGADO and offpuertaabierta == "si" then
            -- Rutina_Apagado() -- Descomentar cuando sea necesario
        end
    else
        if data.modo ~= "Apagado" then
            if thermostat ~= nil then
                if ModoSetpoint == "si" then
                    Registro("Subir Setpoint Aire", amarillo)
                    SetPointTermostato(thermostat.setpoint._id, SetPointOff)
                    SetFanTermostato(thermostat.fanMode._id, "auto_low")
                else
                    Registro("Apagado Aire", amarillo)
                    ThermostatPower(thermostat.mode._id, "off")
                end
            else
                Registro("no tiene termostato", amarillo)
            end
        end
        CancelTimer()
        Verificar("timerAccion1", "Ocupado")
        Verificar("scanCycle1", "Ocupado")
        ActualizarAccion(ACCION_OCUPADO)
    end

    return true
end


