local _core             = require("core")
local _logger           = require("logging")
local _json             = require("json")
local _storage          = require("storage")
local _constants        = require("HUB:plg.plugin_ocupacion/configs/constants")
local numberPlugin      = _storage.get_number("numberPlugin")
local credentials       = _storage.get_table(_constants.STORAGE_ACCOUNT_KEY)

local success, errmsg = pcall(_logger.info, _json.encode(credentials))

if not success then
    _logger.error("Failed crdentials" .. (errmsg and (", error: " .. errmsg) or ""))
else
    _logger.info("credentials success")
end

if not credentials then
    _logger.warning("No account is configured… The user did not log in yet.")
end

local function CreateDevice()
    local my_gateway_id = (_core.get_gateway() or {}).id
    if not my_gateway_id then
        _logger.error("Failed to get current gateway ID, skip creating devices")
        return nil
    end

    -- Obtén el contador persistente para dispositivos genéricos
    local counter = tonumber(_storage.get_string("generic_device_counter") or "0")
    counter = counter + 1

    -- Guarda el nuevo contador
    _storage.set_string("generic_device_counter", tostring(counter))

    -- Recorre los dispositivos existentes para verificar el conteo
    local count = 0
    for _, device in pairs(_core.get_devices() or {}) do
        if device.gateway_id == my_gateway_id then
            count = count + 1
            if count >= 12 then
                return device.id
            end
        end
    end

    -- Crear un nuevo dispositivo con el contador incrementado
    _logger.info("*******Create new device")
    return _core.add_device {
        gateway_id = my_gateway_id,
        name = "Plugin ocupacion" .. tostring(counter),
        category = "generic_io",
        subcategory = "generic_io",
        type = "device",
        device_type_id = "600",
        battery_powered = false,
        info = {
            manufacturer = "Horus Smart Control",
            model = "1.0.0"
        },
        persistent = false,
        reachable = true,
        ready = true,
        status = "idle"
    }
end

local function CreateItem(device_id)
    if not device_id then
        _logger.error("No se puede crear el artículo. Falta device_id...")
        return nil
    end
    _logger.info("Create new 'device' item")

    -- Configuración de dispositivos para el plugin
    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'accion'
        },
        description = {
            text = 'configuracion externa'
        },
        value_type = "int",
        value = 0,
        status = "synced",
        has_setter = true,
        has_getter = true
    }
    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'estado'
        },
        description = {
            text = 'configuracion externa'
        },
        value_type = "string",
        value = "",
        status = "synced",
        has_setter = true,
        has_getter = true
    }

    -- En esta sección se están agregando los dispositivos necesarios para el funcionamiento del plugin.

    -- Dispositivo 1: Controlador de luces
    -- Este dispositivo permitirá controlar la iluminación en respuesta a eventos del sensor de movimiento
    -- o el sensor de puerta.
    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'Actuadores On'
        },
        description = {
            text = 'Registra itemId dispositivos a on'
        },
        value_type = "string",
        value = "",
        status = "synced",
        has_setter = true,
        has_getter = true
    }
    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'Actuadores Off'
        },
        description = {
            text = 'Registra itemId dispositivos a off'
        },
        value_type = "string",
        value = "",
        status = "synced",
        has_setter = true,
        has_getter = true
    }
    -- Dispositivo 2: Sensor de puerta
    -- Se agrega un sensor de puerta para monitorizar la apertura y cierre de puertas
    -- y desplegar un evento llamado evento de puerta.
    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'Sensor Puerta'
        },
        description = {
            text = 'Registra itemId del sensor de puerta'
        },
        value_type = "string",
        value = "",
        status = "synced",
        has_setter = true,
        has_getter = true
    }

    -- Dispositivo 3: Sensor de movimiento
    -- Este dispositivo detectará cambios en el entorno y desencadenará acciones correspondientes
    -- como es el evento de movimiento.
    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'Sensor Movimiento Batt'
        },
        description = {
            text = 'Registra itemId del Sensor de movimiento batt'
        },
        value_type = "string",
        value = "",
        status = "synced",
        has_setter = true,
        has_getter = true
    }

    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'Sensor Movimiento Elec'
        },
        description = {
            text = 'Registra itemId del Sensor de movimiento elec'
        },
        value_type = "string",
        value = "",
        status = "synced",
        has_setter = true,
        has_getter = true
    }

    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'Off puerta Abierta'
        },
        description = {
            text = 'Registra si desea que el sistema apague por evento de puerta abierta'
        },
        value_type = "string",
        value = "",
        status = "synced",
        has_setter = true,
        has_getter = true
    }

    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'Disparador Mov'
        },
        description = {
            text = 'Registra si desea activación por movimiento'
        },
        value_type = "string",
        value = "",
        status = "synced",
        has_setter = true,
        has_getter = true
    }

    -- Dispositivo 4: Termostato
    -- Este dispositivo permitirá controlar el funcionamiento del termostato
    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'SetPoint On'
        },
        description = {
            text = 'Registra el setpoint de encendido'
        },
        value_type = "int",
        value = 0,
        status = "synced",
        has_setter = true,
        has_getter = true
    }

    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'SetPoint Off'
        },
        description = {
            text = 'Registra el setpoint de apagado'
        },
        value_type = "int",
        value = 0,
        status = "synced",
        has_setter = true,
        has_getter = true
    }

    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'Modo SetPoint'
        },
        description = {
            text = 'Registra si desea subir el Setpoint del termostato al pasar a Libre'
        },
        value_type = "string",
        value = "",
        status = "synced",
        has_setter = true,
        has_getter = true
    }

    _core.add_setting {
        device_id = device_id,
        label = {
            text = 'Tiempo Scan'
        },
        description = {
            text = 'Registra el Tiempo de Scan'
        },
        value_type = "int",
        value = 150,
        status = "synced",
        has_setter = true,
        has_getter = true
    }

    -- Items de los estados que el Plugin posee como lo son accion texto, estado texto, modo y tipo
    _core.add_item({
        device_id = device_id,
        name = "AccionTexto",
        value_type = "string",
        has_getter = true,
        has_setter = true,
        enum = { "Libre", "Puerta Abierta", "Scan", "Ocupado" },
        value = "Libre",
        show = true,
    })
    _core.add_item({
        device_id = device_id,
        name = "EstadoTexto",
        value_type = "string",
        has_getter = true,
        has_setter = true,
        enum = { "Libre", "Ocupado" },
        value = "Libre",
        show = true,
    })
    _core.add_item({
        device_id = device_id,
        name = "Modo",
        value_type = "string",
        has_getter = true,
        has_setter = true,
        enum = { "Auto", "Apagado", "Manual" },
        value = "Auto",
        show = true,
    })
    _core.add_item({
        device_id = device_id,
        name = "type",
        value_type = "string",
        has_getter = true,
        has_setter = true,
        value = "hotel",
        show = true,
    })
end

local device_id = CreateDevice()
_logger.info(device_id)
CreateItem(device_id)

_G.idPg = device_id
_G.ID_PLUGIN = _core.get_items_by_device_id(device_id)

if _G.ID_PLUGIN then
    _logger.info("ID de los diferentes item del PLUGIN DE OCUPACION %%%%%%%%%%%%%%%%%%%%%%%%")
    for _, item in ipairs(_G.ID_PLUGIN) do
        if item.name == "AccionTexto" then
            _G.AccionTexto = item.id
            _storage.set_string("AccionTextoId"..numberPlugin, item.id)
        elseif item.name == "EstadoTexto" then
            _storage.set_string("EstadoTextoId"..numberPlugin, item.id)
        elseif item.name == "Modo" then
            _storage.set_string("ModoId"..numberPlugin, item.id)
        elseif item.name == "type" then
            _storage.set_string("TypeId"..numberPlugin, item.id)
        end
    end
end

local settingId = _core.get_setting_ids_by_device_id(device_id)
if settingId ~= nil then
    for _, settingId in pairs(settingId) do
        local setting = _core.get_setting(tostring(settingId))
        if setting ~= nil and setting.label.text == 'accion' then
            -- No operation needed for 'accion'
        elseif setting.label.text == 'Sensor Movimiento Batt' then
            _storage.set_string("settingSensorMovBatt"..numberPlugin, settingId)
        elseif setting.label.text == 'Sensor Movimiento Elec' then
            _storage.set_string("settingSensorMovElec"..numberPlugin, settingId)
            _storage.set_string("settinAccion"..numberPlugin, settingId)
        elseif setting.label.text == 'Actuadores On' then
            _storage.set_string("settingActuadoresOn"..numberPlugin, settingId)
        elseif setting.label.text == 'Actuadores Off' then
            _storage.set_string("settingActuadoresOff"..numberPlugin, settingId)
        elseif setting.label.text == 'Sensor Puerta' then
            _storage.set_string("settingSensorPuerta"..numberPlugin, settingId)
        elseif setting.label.text == 'Off puerta Abierta' then
            _storage.set_string("settingOffPuertaAbierta"..numberPlugin, settingId)
        elseif setting.label.text == 'Disparador Mov' then
            _storage.set_string("settingDisparadorMov"..numberPlugin, settingId)
        end
    end
end
