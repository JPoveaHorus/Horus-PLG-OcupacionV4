---@diagnostic disable: param-type-mismatch
------------module require
local _core = require("core")
local _logger = require("logging")
local _timer = require("timer")
local _json = require("json")
local _storage = require("storage")
local params = ... or {}

------------variable locales
local rojo = 31
local verde = 32
local amarillo = 33

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

local sensor_puerta = _storage.get_string("SENSOR_PUERTA8")
local devicesOn = _storage.get_table("ACTUADORES_ON8")
local devicesOff = _storage.get_table("ACTUADORES_OFF8") or {}
local SensorMovbatt = _storage.get_table("SENSOR_MOV_BATT8")
local SensorMovElec = _storage.get_table("SENSOR_MOV_ELEC8")
local thermostat = _storage.get_table("TERMOSTATO8")
local idmasterswitch = _storage.get_string("MASTERSWITCH8")
local modoPluginStatus = _storage.get_string("ModoId8")
local AccionPluginStatus = _storage.get_string("AccionTextoId8")
local EstadoPluginStatus = _storage.get_string("EstadoTextoId8")
local offpuertaabierta = _storage.get_string("OFFPUERTAABIERTA8")
local masterswitch = _storage.get_string("MASTERSWITCH8") or {}
local motionActivator = _storage.get_string("MOTIONACTIVATOR8")
local SetPointOn = _storage.get_number("SETPOINTON8")
local SetPointOff = _storage.get_number("SETPOINTOFF8")
local ModoSetpoint = _storage.get_string("MODOSETPOINT8")

local data = {}
data.modo = _storage.get_string("Mode8")
data.type = _storage.get_string("type8")
data.counting = _storage.get_string("Counting8")
data.dueTimestamp = _storage.get_number("dueTimestamp8")
data.remaining = _storage.get_string("remaining8")
data.statustext = _storage.get_string("statusText8")
data.acciontext = _storage.get_string("accionTexto8")
data.scancycle = _storage.get_string("scanCycle8")
data.accion = _storage.get_number("accion8")
data.timeraccion = _storage.get_string("timerAccion8")
data.timerduration = _storage.get_number("TimerDuration8")
data.TimerID = _storage.get_string("TimerID8")
data.TimerIdTick = _storage.get_string("TimerIdTick8")
data.Remaining_ant = _storage.get_number("Remaining_ant8")
data.settingAccionId = _storage.get_string("settinAccion8")
data.previousTimer = _storage.get_number("previousTimer8")

----- Tiempos del Plugin
local Tiemposensor = _storage.get_number("TIEMPOSCAN8")
local Tiempo_ocupacion = 450        -- (450*2) 7.5 minutos de ocupación -- 150 pruebas
local Tiempo_puerta = 150           -- (150) seg org                     -- 60 pruebas
local Tiempo_apagado = 10           -- antes 60 seg :: Modificado a 10 seg por sr titto
local TiempoLibre = 10              -- Tiempo libre 10 seg
local TiempoScan = 580              -- (540) 18 Minutos de Scan - 150 pruebas / 580: 19 minutos
local Tiemporesultante = math.floor(Tiemposensor/2)  -- Reduce el tiempo configurado a la mitad
local Tiempo1 = Tiemporesultante    -- Ciclo Scan 1
local Tiempo2 = TiempoScan-Tiempo1  -- Ciclo Scan 2

local umbralTime1 = 0
local umbralTime2 = 150              -- debe terminar en 5 - (150*2)+5 Tiempo de sensado _scan1 (sensor 300/2 = 155) -- pruebas 35
local umbralTime3 = 150              -- debe terminar en 5 - (150*2)+5 Tiempo de sensado PuertaAbierta (sensor 600/2 = 305) -- pruebas 35
--local umbralTime4 = 55              -- debe terminar en 5 - (150*4)+5 - Tiempo de sensado PuertaAbierta Min 10 (sensor 600/2) -- pruebas 25

---- Función para registrar mensajes
local function Registro(Mensaje, color)
    local prefix = "[Horus Smart Energy] "
    if color then
        _logger.info(prefix .. "\27[" .. color .. "m" .. Mensaje .. "\27[0m")
    else
        _logger.info(prefix .. Mensaje)
    end
end

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


--- verification and validation functions of the variables
function Verificar(variable, newvalue)
    local value
    if newvalue ~= nil or newvalue ~= value then
        if (type(newvalue) == "number") then
            value = _storage.get_number(variable)
            _storage.set_number(variable, newvalue)
        end
        if (type(newvalue) == "string") then
            value = _storage.get_string(variable)
            _storage.set_string(variable, newvalue)
        end
        return true
    else
        value = _storage.get_string(variable)
        Registro("no se encontro cambio en la variable: " .. variable, amarillo)
        return false
    end
end

function VariablesDeInicio(variable, defaultValue)
    local value
    if (type(defaultValue) == "number") then
        value = _storage.get_number(variable)
        if value == nil then
            _storage.set_number(variable, defaultValue)
            value = _storage.get_number(variable)
            return value
        else
            return value
        end
    end
    if (type(defaultValue) == "string") then
        value = _storage.get_string(variable)
        if value == nil then
            Registro("secarga valor por defaul", amarillo)
            _storage.set_string(variable, defaultValue)
            value = _storage.get_string(variable)
            return value
        else
            return value
        end
    end
end

---- Actualiza el estado y los textos asociados según el valor proporcionado.
function ActualizarAccion(s)
    Registro("ActualizarAccion", verde)

    -- Identificadores de texto asociados.
    local AccionTextoId = _storage.get_string("AccionTextoId8")
    local EstadoTextoId = _storage.get_string("EstadoTextoId8")
    -- Obtiene el valor actual almacenado.
    local curValue = _storage.get_number("accion8")

    -- Verifica si el valor ha cambiado.
    if tonumber(s) ~= tonumber(curValue) then
        Registro("curValue: " .. curValue .. ", s: " .. s, amarillo)
        -- Actualiza la acción según el valor proporcionado
        Verificar("accion8", s)
        
        -- Mapeo de valores de acción a textos asociados.
        local textMapping = {
            [ACCION_LIBRE] = "Libre",
            [ACCION_PABIERTA] = "Puerta Abierta",
            [ACCION_SCAN] = "Scan",
            [ACCION_OCUPADO] = "Ocupado"
        }

        -- Obtiene el texto asociado al valor de acción actual.
        local accionText = textMapping[s]

        -- Si hay un texto asociado, actualiza el texto correspondiente.
        if accionText then
            Verificar("accionTexto8", accionText)
            setItemValue(AccionTextoId, accionText)
        end
    end

    -- Verifica el valor de acción para actualizar el estado general
    if tonumber(s) ~= -2 then
        local statusText = tonumber(s) == 0 and "Libre" or "Ocupado"

        -- Actualiza el estado texto.
        Verificar("statusText8", statusText)
        setItemValue(EstadoTextoId, statusText)
    end

    return true
end

---- Eventos del plugin(puerta, Puerta Abierta Libre, movimineto, )
function EventoPuerta()
    Registro(" Evento Puerta ", amarillo)
    local SensorPuerta = _core.get_item(sensor_puerta)
    if SensorPuerta.value == true then
        CancelTimer()
        local modoStatus = _core.get_item(tostring(modoPluginStatus))
        if modoStatus then
            Verificar("Mode8", tostring(modoStatus.value))
        end

        if _storage.get_number("accion8") == ACCION_LIBRE  or  _storage.get_number("accion8") == ACCION_CICLO_APAGADO then
            Rutina_Encendido()
        end

        ActualizarAccion(ACCION_PABIERTA)
        Verificar("timerAccion8", "AutoOff")
        Verificar("scanCycle8", "AutoOff")
        StartTimer(Tiempo_puerta)
        return true
    end

    if SensorPuerta.value == false then
        CancelTimer()
        if _storage.get_number("accion8") == ACCION_PABIERTA then

            if _storage.get_string("statusText8") == "Libre" then
                Rutina_Encendido()
            end

            ActualizarAccion(ACCION_SCAN)
            Verificar("scanCycle8", "scan_8")
            Verificar("timerAccion8", "Scan")
            StartTimer(Tiempo1)
            return true
        else

            ActualizarAccion(ACCION_SCAN)
            Verificar("scanCycle8", "scan_8")
            Verificar("timerAccion8", "Scan")
            StartTimer(Tiempo1)
            return true
        end
    end
end

--Evento Scan >> Sensor Mov = On >> Ocupado
function EventTimeMin()
    --Registro(" Inicio Evento Tiempo Mínimo ", rojo)
    local function ProcSensMov(sensoresMovimiento)
        local SensorPuerta = _core.get_item(sensor_puerta)
        if sensoresMovimiento ~= nil then
            for i in pairs(sensoresMovimiento) do
                local sensor = _core.get_item(sensoresMovimiento[i])
                if sensor.value == true and SensorPuerta.value == false then
                    Registro("Evento TimeMin - ON - min 5 ", amarillo)
                    if _storage.get_number("accion8") == ACCION_SCAN then
                        CancelTimer()
                        ActualizarAccion(ACCION_OCUPADO)
                        Verificar("timerAccion8", "Ocupado")
                        Verificar("scanCycle8", "Ocupado")
                        Registro("ocupado = ON 5min SM", verde)
                        return
                    end
                else
                    Registro("No Event Tiempo Min ", verde)
                end
            end
        end
    end

    -- Procesar ambos grupos de sensores de movimiento
    ProcSensMov(SensorMovbatt)
    ProcSensMov(SensorMovElec)
end

function EventMovement(Sensor)
    Registro("Evento de movimiento", amarillo)
    local motion = _storage.get_string("motion8")
    if Sensor ~= nil then
        Registro("sensor : " .. _json.encode(Sensor), amarillo)
        for i in ipairs(Sensor) do -- Rutina FOR : conocer estado de SM
            local sensor_id = _core.get_item(Sensor[i])
            if sensor_id.value == true then
                if motion ~= nil then -- Conocer estado de SM
                    local securityThreat = _storage.get_string("securityThreat8")
                    -- Registro("value sensor motion: " .. _json.encode(sensor_id.value) .. ", " ..
                    --     _json.encode(data.modo) .. ", " .. motionActivator .. ", " .. motion, amarillo)
                    setItemValue(motion, true)
                    setItemValue(securityThreat, true)
                end

                if _storage.get_number("accion8") == ACCION_LIBRE then
                    -- if masterswitch == "si" then
                    --     RoutineOn(devicesOn)
                    -- end

                    if motionActivator == "si" and data.modo == "Auto" then
                        if thermostat ~= nil then
                            ThermostatPower(thermostat.mode._id, "cool")
                            SetPointTermostato(thermostat.setpoint._id, SetPointOn)
                        end
                    end

                    CancelTimer()
                    ActualizarAccion(ACCION_OCUPADO)
                    Verificar("scanCycle8", "Ocupado")
                    Verificar("timerAccion8", "Ocupado")

                    -- CancelTimer()
                    -- ActualizarAccion(ACCION_SCAN)
                    -- Verificar("scanCycle8", "scan_8")
                    -- Verificar("timerAccion8", "Scan")
                    -- StartTimer(Tiempo1)
                    return
                end

                if _storage.get_number("accion8") == ACCION_SCAN then
                    CancelTimer()
                    ActualizarAccion(ACCION_OCUPADO)
                    Verificar("timerAccion8", "Ocupado")
                    Verificar("scanCycle8", "Ocupado")
                    Registro("se paso al la accion 1 ocupado por disparo del sensor de movimiento", verde)
                    return
                end

                if _storage.get_number("accion8") == ACCION_PABIERTA then
                    if _storage.get_string("statusText8") == "Libre" then
                        Rutina_Encendido()
                    end
                    CancelTimer()
                    ActualizarAccion(ACCION_SCAN)
                    Verificar("timerAccion8", "Scan")
                    Verificar("scanCycle8", "scan_8")
                    StartTimer(Tiempo1)
                    return
                end

                if _storage.get_number("accion8") == ACCION_CICLO_APAGADO then
                    CancelTimer()
                    ActualizarAccion(ACCION_OCUPADO)
                    Verificar("timerAccion8","Ocupado")
                    Verificar("scanCycle8", "Ocupado")
                    if PreOffAireDoor == "si" then
                        Registro("on actuadores", amarillo)
                        if masterswitch == "si" then
                            RoutineOn(devicesOn)
                        end
                        if motionActivator == "si" and data.modo == "Auto" then
                            if thermostat ~= nil then
                                ThermostatPower(thermostat.mode._id, "cool")
                                SetPointTermostato(thermostat.setpoint._id, SetPointOn)
                            end
                        end
                    end
                    return
                end
            end

            if sensor_id.value == false then
                if motion ~= nil then
                    local securityThreat = _storage.get_string("securityThreat8")
                    -- Registro("value sensor motion: " .. _json.encode(sensor_id.value) .. ", " ..
                    --     _json.encode(data.modo) .. ", " .. motionActivator .. ", " .. motion, amarillo)
                    setItemValue(motion, false)
                    setItemValue(securityThreat, false)
                end
            end
        end
    end
end

function EventoActuadores(Actuador)
    Registro("_______ evento de Actuadores_______", amarillo)
    if Actuador ~= nil then
        local tiempoRestante1 = Tiempo1 - (data.previousTimer or 0)
        local tiempoRestante2 = Tiempo2 - (data.previousTimer or 0)
        Registro("sensor : " .. _json.encode(Actuador), amarillo)
        for i in ipairs(Actuador) do
            local actuador_id = _core.get_item(Actuador[i])
            Registro("value Actuador: " .. _json.encode(actuador_id.value) .. ", " ..
                _json.encode(data.modo))
            if actuador_id.value == true then
                if data.scancycle == nil or data.scancycle == "Libre" then
                    if masterswitch == "si" then
                        --RoutineOn(devicesOn)
                    end

                    if motionActivator == "si" and data.modo == "Auto" then
                        if thermostat ~= nil then
                            ThermostatPower(thermostat.mode._id, "cool")
                            SetPointTermostato(thermostat.setpoint._id, SetPointOn)
                        end
                    end                  
                    CancelTimer()
                    Verificar("timerAccion8","Ocupado")
                    Verificar("scanCycle8", "Ocupado")
                    ActualizarAccion(ACCION_OCUPADO)
                    Registro("Pasa a accion 8 OCUPADO por disparo de Actuador true", amarillo)
                    return
                end
                if _storage.get_number("accion8") == ACCION_PABIERTA and data.scancycle == "PuertaAbierta" then
                    if _storage.get_string("statusText8") == "Libre" then
                        if masterswitch == "si" then
                            RoutineOn(devicesOn)
                        end
                        if motionActivator == "si" and data.modo == "Auto" then
                            if thermostat ~= nil then
                                ThermostatPower(thermostat.mode._id, "cool")
                                SetPointTermostato(thermostat.setpoint._id, SetPointOn)
                            end
                        end
                    end
                    CancelTimer()
                    ActualizarAccion(ACCION_SCAN)
                    Verificar("timerAccion8", "Scan")
                    Verificar("scanCycle8", "scan_8")
                    StartTimer(Tiempo1)
                    return
                end    
                if (tiempoRestante1 >= 10 and data.scancycle == "scan_8") then
                    Registro("el tiempo restante 1 es mayor al valor especificado", amarillo)
                    if _storage.get_number("accion8") == ACCION_CICLO_APAGADO then
                        if PreOffAireDoor == "si" then
                            Registro("on actuadores", amarillo)
                            Rutina_Encendido()
                        end
                        CancelTimer()
                        ActualizarAccion(ACCION_OCUPADO)
                        Verificar("timerAccion8", "Ocupado")
                        Verificar("scanCycle8", "Ocupado")
                        return
                    end
                    if _storage.get_number("accion8") == ACCION_SCAN then
                        CancelTimer()
                        ActualizarAccion(ACCION_OCUPADO)
                        Verificar("timerAccion8", "Ocupado")
                        Verificar("scanCycle8", "Ocupado")
                        Registro("se paso a accion8 OCUPADO por disparo de Actuador", verde)
                        return
                    end
                end
                if (tiempoRestante2 >= 10 and data.scancycle == "scan_Libre") then
                    Registro("el tiempo restante 2 es mayor al valor especificado", amarillo)
                    if _storage.get_number("accion8") == ACCION_CICLO_APAGADO then
                        if PreOffAireDoor == "si" then
                            Registro("on actuadores", amarillo)
                            Rutina_Encendido()
                        end
                        CancelTimer()
                        ActualizarAccion(ACCION_OCUPADO)
                        Verificar("timerAccion8", "Ocupado")
                        Verificar("scanCycle8", "Ocupado")
                        return
                    end
                    if _storage.get_number("accion8") == ACCION_SCAN then
                        CancelTimer()
                        ActualizarAccion(ACCION_OCUPADO)
                        Verificar("timerAccion8", "Ocupado")
                        Verificar("scanCycle8", "Ocupado")
                        Registro("se paso a accion8 OCUPADO por disparo de Actuador", verde)
                        return
                    end
                end
            end
            if actuador_id.value == false then
                if _storage.get_number("accion8") == ACCION_SCAN then
                    CancelTimer()
                    ActualizarAccion(ACCION_OCUPADO)
                    Verificar("timerAccion8","Ocupado")
                    Verificar("scanCycle8", "Ocupado")
                    Registro("Pasa a accion 8 OCUPADO por disparo de Actuador false", amarillo)
                    return
                end              
                if _storage.get_number("accion8") == ACCION_PABIERTA and data.statustext == "Ocupado" then
                    CancelTimer()
                    ActualizarAccion(ACCION_SCAN)
                    Verificar("timerAccion8", "Scan")
                    Verificar("scanCycle8", "scan_8")
                    StartTimer(Tiempo1)
                    return
                end
            end
        end
        Registro("Fin Actuadores", verde)
        return true
    end
end

function PuertaAbierta()
    Registro("Puerta Abierta habitacion uno", amarillo)
    CancelTimer()
    ActualizarAccion(ACCION_PABIERTA)
    Verificar("timerAccion8", "PuertaAbierta")
    Verificar("scanCycle8", "PuertaAbierta")
    Registro("Tiempo_ocupacion: " .. Tiempo_ocupacion, amarillo)
    StartTimer(Tiempo_ocupacion)
end

function PuertaAbiertaLibre()
    Registro("Step-0")
    local contador, contadorDisparos, contadorLibres = 0, 0, 0
    local EstadoTextoId = _storage.get_string("EstadoTextoId8")

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

    contarSensores(SensorMovbatt)
    contarSensores(SensorMovElec)

    -- local Mensaje = contador .. " - " .. contadorDisparos .. " - " .. contadorLibres
    -- local Mensaje1 = "sensor de puerta value:" .. _json.encode(sensor_puerta.value)
    -- Registro(Mensaje, amarillo)
    -- Registro(Mensaje1, amarillo)
    
    if contador == contadorLibres then
        -- local Mensaje2 = "modo y estado de off puerta abierta: " ..
        --     offpuertaabierta .. ", " .. _storage.get_string("Mode8")
        -- Registro(Mensaje2, amarillo)
        CancelTimer()
        Verificar("statusText8", "Libre")
        setItemValue(EstadoTextoId,"Libre")

        -- rutina Comentada // Investigar con la org
        if _storage.get_string("Mode8") ~= MODO_APAGADO then
            Registro("Step-8")
            if offpuertaabierta == "si" then
                Rutina_Apagado()
            end
        end

        -- if _storage.get_string("Mode8") ~= MODO_APAGADO and offpuertaabierta == "si" then
        --     -- Rutina_Apagado() -- Descomentar cuando sea necesario
        --         ThermostatPower(thermostat.mode._id, "off")
        -- end
    else
        if data.modo ~= "Apagado" then
            if thermostat ~= nil then
                if ModoSetpoint == "si" then
                    Registro("Step-8")
                    Registro("Subir Setpoint Aire", amarillo)
                    ThermostatPower(thermostat.mode._id, "cool")
                    SetPointTermostato(thermostat.setpoint._id, SetPointOff)
                    --SetFanTermostato(thermostat.fanMode._id, "auto_low")
    
                elseif ModoSetpoint == "no" then
    
                    Registro("Apagado Aire", amarillo)
                    ThermostatPower(thermostat.mode._id, "off")
    
                end
            else
                Registro("no tiene termostato", amarillo)
            end
        end
        CancelTimer()
        Verificar("timerAccion8","Ocupado")
        Verificar("scanCycle8", "Ocupado")
        ActualizarAccion(ACCION_OCUPADO)
    end
    return true
end

function CycleOff()
    local contador = 0
    local contadorDisparos = 0
    local contadorLibres = 0

    if SensorMovbatt ~= nil then
        for i in pairs(SensorMovbatt) do
            local id = _core.get_item(SensorMovbatt[i])
            contador = contador + 1
            if id.value == true then
                contadorDisparos = contadorDisparos + 1
            end
            if id.value == false then
                contadorLibres = contadorLibres + 1
            end
        end
    end

    if SensorMovElec ~= nil then
        for i in pairs(SensorMovElec) do
            local id = _core.get_item(SensorMovElec[i])
            contador = contador + 1
            if id.value == true then
                contadorDisparos = contadorDisparos + 1
            end
            if id.value == false then
                contadorLibres = contadorLibres + 1
            end
        end
    end

    -- local Mensaje = "estado de los sensores cantidad " ..
    --     contador .. "---- disparos " .. contadorDisparos .. " --- " .. _json.encode(data.scancycle)
    -- Registro(Mensaje, amarillo)

    if (contador > 0 and contadorDisparos > 0) then
        CancelTimer()    
        Verificar("timerAccion8","Ocupado")
        Verificar("scanCycle8", "Ocupado")
        ActualizarAccion(ACCION_OCUPADO)
        return
    end

    if (contador == contadorLibres) then
        if data.scancycle == "scan_8" then
            CancelTimer()
            ActualizarAccion(ACCION_SCAN)
            Verificar("scanCycle8", "scan_Libre")
            Verificar("timerAccion8", "Scan")
            StartTimer(Tiempo2)

        elseif data.scancycle == "scan_Libre" then
            if _storage.get_string("Mode8") ~= MODO_APAGADO then
                if PreOffAireDoor == "si" then
                    RoutineOff(devicesOn)
                    RoutineOff(devicesOff)
                end
            end
            CancelTimer()
            ActualizarAccion(ACCION_CICLO_APAGADO)
            Verificar("timerAccion8", "CicloApagado")
            Verificar("scanCycle8", "CicloApagado")
            Registro("Tiempo_apagado: " .. Tiempo_apagado, amarillo)
            StartTimer(Tiempo_apagado)
        end
        return
    end
end

---- Rutinas Encebdido y Apagado
function Rutina_Encendido()

    local mode = _storage.get_string("Mode8")
    -- local Mensaje = "rutina de encendido en el modo: " .. mode
    -- Registro(Mensaje, rojo)

    RoutineOn(devicesOn)
    for i = 1, 1 do
        if data.modo == "Auto" then
            if motionActivator == "si" and thermostat ~= nil then
                Registro(("Intento On Thermo: " .. i),rojo) 
    
                if thermostat.mode.value ~= "cool" then
                    ThermostatPower(thermostat.mode._id, "cool")
                    Registro("Cool : Thermo",verde)
                    --SetPointTermostato(thermostat.setpoint._id, 24)
                end
                if thermostat.setpoint.value ~= SetPointOn then
                    SetPointTermostato(thermostat.setpoint._id, SetPointOn)
                end
                -- if thermostat.fanMode.value ~= "auto_low" then
                --     SetFanTermostato(thermostat.fanMode._id, "auto_low")
                -- end
            else
                Registro("no tiene termostato", amarillo)
            end
        end
    end
    
    return mode
end

function Rutina_Apagado()

    local mode = _storage.get_string("Mode8")
    -- local Mensaje = "rutina de apagado en el modo: " .. mode
    -- Registro(Mensaje, amarillo)

    RoutineOff(devicesOn)
    RoutineOff(devicesOff)

        for i = 1, 1 do
            if data.modo ~= "Apagado" then
                if thermostat ~= nil then
                    if ModoSetpoint == "si" then

                        Registro("Subir Setpoint Aire", amarillo)
                        SetPointTermostato(thermostat.setpoint._id, SetPointOff)
                        --SetFanTermostato(thermostat.fanMode._id, "auto_low")

                    elseif ModoSetpoint == "no" then

                        Registro("Apagando Aire", amarillo)
                        ThermostatPower(thermostat.mode._id, "off")

                    end
                    Registro("Intento On Thermo: " .. i)
                else
                    Registro("no tiene termostato", amarillo)
                end
            end
        end
    return mode
end

---- estasdos del plugin (libre, Ocupado)
function Libre()
    -- local Mensaje = "funcion Libre"
    Registro("funcion Libre", verde)
    Rutina_Apagado()
    CancelTimer()
    ActualizarAccion(ACCION_LIBRE)
    Verificar("timerAccion8", "Libre")
    StartTimer(TiempoLibre)

end

function Occupied()
    -- local Mensaje = "funcion ocupado"
    Registro("funcion ocupado", verde)
    CancelTimer()
    ActualizarAccion(ACCION_OCUPADO)
    Verificar("timerAccion8", "Ocupado")
    Verificar("scanCycle8", "Ocupado")
    Rutina_Encendido()
end

---- funcion de acciones de encendido y apagado
function RoutineOn(item_id)
    local id = {}
        if _storage.get_string("Mode8") == MODO_AUTO then
            for i in ipairs(item_id) do
                id = _core.get_item(item_id[i])
            end
            _logger.info("valor de los dispositivos: " .. tostring(id.value))
            if id.value ~= true then
                PowerOnActuator(item_id)
            end
            return
        end
        if _storage.get_string("Mode8") ~= MODO_AUTO then
            for i in ipairs(item_id) do
                id = _core.get_item(item_id[i])
            end
            _logger.info("valor de los dispositivos: " .. tostring(id.value))
            Registro("no se enciende ningun dispositivo", amarillo)
            return
        end
    return false
end
function RoutineOff(item_id)

    local id = {}

    if _storage.get_string("Mode8") ~= MODO_APAGADO then
        for i in ipairs(item_id) do
            id = _core.get_item(item_id[i])
        end
        _logger.info("valor de los dispositivos: " .. tostring(id.value))
        if id.value == true then
            ShutdownActuator(item_id)
        else
            ShutdownActuator(item_id)
        end
        return
    end
end
function ShutdownActuator(item_id)
    Registro(" evento apagado de actuadores", verde)
    local actuadores_on
    for i in ipairs(item_id) do
        actuadores_on = _core.get_item(item_id[i])
        _logger.info("id_actuadores: " .. actuadores_on.name)
        _logger.info("id_actuadores: " .. actuadores_on.id)
        _core.set_item_value(item_id[i], false)
    end
end
function PowerOnActuator(item_id)
    Registro("evento Encendido de actuadores", verde)
    local actuadores_on
    for i in ipairs(item_id) do
        actuadores_on = _core.get_item(item_id[i])
        _logger.info("id_actuadores: " .. actuadores_on.name)
        _logger.info("id_actuadores: " .. actuadores_on.id)
        _core.set_item_value(item_id[i], true)
    end
end
function ThermostatPower(item_id, value)
    -- Registro("Thermostat: " .. thermostat.mode.name .. ": " .. thermostat.mode._id, amarillo)
    -- Registro("Encendido Aire", verde)

    _core.set_item_value(item_id, value)

    _timer.set_timeout(5000, "HUB:plg.plugin_ocupacion/scripts/functions/thermostat",
    { itemId = item_id, itemValue = value })

end
function SetPointTermostato(item_id, value)
    Registro("Thermostat: " .. thermostat.mode.name .. ": " .. thermostat.setpoint._id, rojo)

    _timer.set_timeout(5000, "HUB:plg.plugin_ocupacion/scripts/functions/thermostat",
    { itemId = item_id, itemValue = value })

    -- _timer.set_timeout(5000, "HUB:plg.plugin_ocupacion/scripts/functions/thermostat",
    -- { itemId = item_id, itemValue = value })

end
function SetFanTermostato(item_id, value)
    Registro("Thermostat: " .. thermostat.mode.name .. ": " .. thermostat.setpoint._id, amarillo)

    _timer.set_timeout(5000, "HUB:plg.plugin_ocupacion/scripts/functions/thermostat",
    { itemId = item_id, itemValue = value })

end


---- Main
function Main()
    local TimerRemainingV = TiempoTranscurrido()
    local EstadoAccion = _json.encode(data.scancycle)

    local SensorPuerta = _core.get_item(sensor_puerta)
    Registro("timerId: " .. _json.encode(data.TimerID),verde)
    Registro("previousTimer_8: " .. _json.encode(data.previousTimer))
    Registro("TimerRemainingV_8: " .. _json.encode(TimerRemainingV))
    Registro("Modo plugin: " .. _json.encode(data.modo),verde)
    Registro("TimerAccion8: " .. _json.encode(data.timeraccion),amarillo)
    Registro("scanCycle8: " .. _json.encode(data.scancycle),verde)
    Registro("plugin status: " .. data.acciontext,rojo)

    -- No mover: calculo de tiempos e intervalos
    if TimerRemainingV - data.previousTimer >= 10 then
        Registro("TimerRemainingV: " .. TimerRemainingV, amarillo)
        Registro("plugin status: " .. "acciontext: " .. data.acciontext .. ", statustext: " .. data.statustext,amarillo)
        Registro("timerduration: " .. data.timerduration .. ", timeraccion: " .. data.timeraccion, amarillo)
    end

    Verificar("previousTimer8", tonumber(TimerRemainingV))

    if data.accion == 100 or data.accion == 0 then
        Verificar("TimerDuration8", 0)
    else
        if TimerRemainingV > 0 then
            CancelTimer()
            StartTimer(TimerRemainingV)
        end
    end

    -- calculos de tiempo para luego ejecutar acciones
    umbralTime1 = Tiemporesultante - TimerRemainingV
    Registro("Tiempo Recorrido= ".. TimerRemainingV)
    Registro("Tiempo Resultante= ".. Tiemporesultante)
    Registro("Tiempo Umbral Time = " .. math.abs(umbralTime1))


    -- Scan minimo de SM para ocupacion antes de 20 min del tiempo total
    if EstadoAccion =='"scan_8"' then
        Registro("Inicio Evento Timer - Scan", amarillo)
        if  SensorPuerta.value == false and umbralTime1 >= (umbralTime2-7) and umbralTime1 <= (umbralTime2+7) then 
            Registro("Evento Timer - Iniciado", amarillo)
            EventTimeMin()
        end
    end

    if EstadoAccion == '"AutoOff"' then
        Registro("Evento PuertaAb - Scan", verde)
        if SensorPuerta.value == true and umbralTime1 >= (umbralTime3-7) and umbralTime1 <= (umbralTime3+7) then
            ThermostatPower(thermostat.mode._id, "off")
            Registro("Evento: Aire Off - Puerta Abierta - 5 min", amarillo)
        end
    end


end

---- funciones de tipo timer
function StartTimer(timerduration)
    local counting = VariablesDeInicio("Counting8", "0")
    if counting == "8" then
        return false
    end
    Verificar("TimerDuration8", timerduration)
    return StartTimeralways()
end

function StartTimeralways()
    local duration = VariablesDeInicio("TimerDuration8", 30)
    local dueTimestamp1 = os.time() + duration
    Verificar("dueTimestamp8", dueTimestamp1)
    local status = RemainingUpgrade()
    Verificar("Counting8", "8")
    if data.TimerID ~= "" and status then
        local timerID = data.TimerID
        _storage.set_string("TimerID8", tostring(timerID))
        --Registro("TimerID8: " .. timerID) -- No es necesario mostrar el ID del Timer
        _timer.set_timeout_with_id(10000, tostring(timerID),
            "HUB:plg.plugin_ocupacion/scripts/functions/roomEight",
            { arg_name = "timer" })
        return true
    else
        Registro("timer sin id")
        local timerID = _timer.set_timeout(10000, "HUB:plg.plugin_ocupacion/scripts/functions/roomEight",
            { arg_name = "timer" })
        _storage.set_string("TimerID8", tostring(timerID))
        return true
    end
end

function TiempoTranscurrido()
    local Timerload = _storage.get_string("remaining8") or 0

    if Timerload == "0" or Timerload == 0 then
        return 0
    elseif string.len(Timerload) < 12 then
        local minutos = tonumber(string.sub(Timerload, 6, 7))
        local segundo = tonumber(string.sub(Timerload, 9, 10))
        minutos = minutos * 60
        segundo = minutos + segundo
        return segundo
    else
        local horas = tonumber(string.sub(Timerload, 2, 3))
        local minutos = tonumber(string.sub(Timerload, 5, 6))
        local segundos = tonumber(string.sub(Timerload, 8, 9))
        horas = horas * 3600
        minutos = minutos * 60
        segundos = horas + minutos + segundos
        return segundos
    end
end

function CancelTimer()
    local counting = VariablesDeInicio("Counting8", "0")
    if counting == "0" then
        return false
    end
    if data.TimerID ~= "" then
        local timerID = data.TimerID
        _storage.set_string("TimerID8", tostring(timerID))
        --Registro("TimerID8: " .. timerID, amarillo) -- No es necesario mostrar el ID del Timer
        if timerID then
            if _timer.exists(tostring(timerID)) then
                _timer.cancel(tostring(timerID))
            else
                Registro("timer does not exist")
            end
        else
            Registro("timerID does  not exist", amarillo)
        end
    end
    Remaining_ant = 0
    Verificar("Counting8", "0")
    Verificar("dueTimestamp8", 0)
    Verificar("remaining8", "0")
    Verificar("TimerDuration8", 0)
    return true
end

function TimerRemaining(timer)
    local _horas = ""
    local _minutos = ""
    local horas = math.floor(timer / 3600)
    timer = timer - (horas * 3600)
    local minutos = math.floor(timer / 60)
    timer = timer - (minutos * 60)
    local segundos = timer or "0"
    if horas < 10 then
        _horas = "0" .. horas
    end
    if minutos < 10 then
        _minutos = "0" .. minutos
    else
        _minutos = tostring(minutos)
    end
    if segundos < 10 then
        segundos = "0" .. segundos
    else
        segundos = tostring(segundos)
    end
    return (_horas .. ":" .. _minutos .. ":" .. segundos)
end

function RemainingUpgrade()
    local dueTimestamp1 = VariablesDeInicio("dueTimestamp8", 0)
    local remaining = tonumber(dueTimestamp1) - os.time()
    if remaining < 0 then
        remaining = 0
    end
    local restante = TimerRemaining(remaining)
    Remaining_ant = remaining
    Verificar("remaining8", "TR" .. restante)
    return remaining > 0
end

function Tick8()
    local counting = VariablesDeInicio("Counting8", "0")
    if counting == "0" then
        Registro("counting is false")
        return false
    end
    local status = RemainingUpgrade()
    if (status == true) then
        if params.timerId ~= nil then
            local timerID = tostring(params.timerId)
            _timer.set_timeout_with_id(10000, tostring(params.timerId),
                "HUB:plg.plugin_ocupacion/scripts/functions/roomEight",
                { arg_name = "main" })
            if (timerID ~= "") then
                _logger.info("TimerID: " .. timerID)
                _storage.set_string("TimerID8", tostring(timerID))
                return true
            end
            return
        end
    end
    -- tiempo finalizado
    Remaining_ant = 0
    Verificar("Counting8", "0")
    Verificar("dueTimestamp8", "0")
    Verificar("remaining8", "0")
    local timerAccion = VariablesDeInicio("timerAccion8", "0")
    Registro("timerAccion: " .. _json.encode(timerAccion))
    if timerAccion == "AutoOff" then
        PuertaAbierta()
    elseif timerAccion == "PuertaAbierta" then
        PuertaAbiertaLibre()
    elseif timerAccion == "Scan" then
        CycleOff()
    elseif timerAccion == "CicloApagado" then
        Libre()
    elseif timerAccion == "Libre" then
        Verificar("scanCycle8", "Libre")
        CancelTimer()
    end
    return true
end

---- funcion principal
if sensor_puerta ~= nil then
    -- Registro(sensor_puerta..", ".. params.event)
    if params._id == sensor_puerta and params.event == "item_updated" then
        EventoPuerta()
    end
end
if SensorMovbatt ~= nil then
    for i in pairs(SensorMovbatt) do
        if params._id == SensorMovbatt[i] and params.event == "item_updated" then
            EventMovement(SensorMovbatt)
        end
    end
end
if SensorMovElec ~= nil then
    for i in pairs(SensorMovElec) do
        if params._id == SensorMovElec[i] and params.event == "item_updated" then
            EventMovement(SensorMovElec)
        end
    end
end
if modoPluginStatus then
    local modeButton = _core.get_item(tostring(modoPluginStatus))
    if modeButton.value ~= data.modo then
        Verificar("Mode8", tostring(modeButton.value))
        Registro("Modo successful change ",verde)
        CancelTimer()
        ActualizarAccion(ACCION_SCAN)
        Verificar("scanCycle8", "scan_8")
        Verificar("timerAccion8", "Scan")
        StartTimer(Tiempo1)
    end
end
if AccionPluginStatus then

    local EstadoTexto = _core.get_item(tostring(EstadoPluginStatus))
    local AccionButton = _core.get_item(tostring(AccionPluginStatus))

    if AccionButton.value == "Libre" then
        if EstadoTexto.value == "Ocupado" then
            Registro("Accion cambió con éxito ",verde)
            Verificar("scanCycle8", "LibreForzado")
            Libre()
        end
    end
end
if devicesOn ~= nil then
    for i in pairs(devicesOn) do
        local type = _core.get_item(devicesOn[i])
        if params._id == devicesOn[i] and params.event == "item_updated" then
            EventoActuadores(devicesOn)
        end
    end
end
if devicesOff ~= nil then
    for i in pairs(devicesOff) do
        local type = _core.get_item(devicesOff[i])
        if params._id == devicesOff[i] and params.event == "item_updated" then
            EventoActuadores(devicesOff)
        end
    end
end
if params.arg_name == "timer" then
    local statusTick = Tick8()
else
    Main()
end