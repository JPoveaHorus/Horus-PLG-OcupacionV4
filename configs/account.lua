local _logger = require("logging")
local _json = require("json")
local _storage = require("storage")
local _core = require("core")
local args = ... or {}
local account_credentials = {}
local numberPlugin = 0

_logger.info(">>> Iniciando configuración del plugin de ocupación... <<<")

local inputs_data = {}

local STORAGE_ACCOUNT_KEY = _G.constants.STORAGE_ACCOUNT_KEY

local function Registro(Mensaje)
	_logger.info("[Horus Smart Energy] " .. Mensaje)
end

if type(args.password) == "string" and args.password ~= "" then
	account_credentials.password = args.password
end

if account_credentials.password == _G.constants.DEFAULT_PASSWORD then
	_logger.info("Logged in successfully…")
	_storage.set_table(STORAGE_ACCOUNT_KEY, account_credentials)
else
	_logger.warning("The provided credentials are invalid.")
end

if _storage.get_number("numberPlugin") ~= nil then
	numberPlugin = _storage.get_number("numberPlugin")
end
numberPlugin = numberPlugin + 1

_storage.set_number("numberPlugin", numberPlugin)

function Split(s, re)
	local i1 = 1
	local ls = {}
	local append = table.insert

	if not re then
		re = "%s+"
	end
	if re == "" then
		return { s }
	end
	while true do
		local i2, i3 = s:find(re, i1)
		if not i2 then
			local last = s:sub(i1)
			if last ~= "" then
				append(ls, last)
			end
			if #ls == 1 and ls[1] == "" then
				return {}
			else
				return ls
			end
		end
		append(ls, s:sub(i1, i2 - 1))
		i1 = i3 + 1
	end
end

if args.TiempoScan ~= 0 and args.TiempoScan then
	inputs_data.TiempoScan = args.TiempoScan
	_storage.set_number("TIEMPOSCAN"..tostring(numberPlugin), inputs_data.TiempoScan)
end

if args.SetpointOn ~= 0 and args.SetpointOn then
	inputs_data.SetpointOn = args.SetpointOn
	_storage.set_number("SETPOINTON"..tostring(numberPlugin), inputs_data.SetpointOn)
end

if args.SetpointOff ~= 0 and args.SetpointOff then
	inputs_data.SetpointOff = args.SetpointOff
	_storage.set_number("SETPOINTOFF"..tostring(numberPlugin), inputs_data.SetpointOff)
end

if args.ModoSetpoint ~= "" and args.ModoSetpoint then
	inputs_data.ModoSetpoint = args.ModoSetpoint
	_storage.set_string("MODOSETPOINT"..tostring(numberPlugin), inputs_data.ModoSetpoint)
end

if args.offPuertaAbierta ~= "" and args.offPuertaAbierta then
	inputs_data.offPuertaAbierta = args.offPuertaAbierta
	_storage.set_string("OFFPUERTAABIERTA"..tostring(numberPlugin), inputs_data.offPuertaAbierta)
end

if args.masterSwitch ~= "" and args.masterSwitch then
	inputs_data.masterSwitch = args.masterSwitch
	_storage.set_string("MASTERSWITCH"..tostring(numberPlugin), inputs_data.masterSwitch)
end

if args.motionActivator ~= "" and args.motionActivator then
	inputs_data.motionActivator = args.motionActivator
	_storage.set_string("MOTIONACTIVATOR"..tostring(numberPlugin), inputs_data.motionActivator)
end

if args.idMasterSwitch and args.idMasterSwitch ~= ""  then
	inputs_data.idMasterSwitch = args.idMasterSwitch
	_storage.set_string("IDMASTERSWITCH"..tostring(numberPlugin), inputs_data.idMasterSwitch)
end

if args.actuadores_on ~= "" and type(args.actuadores_on) == "string" then
	_storage.set_string("actuadoresOn"..tostring(numberPlugin), args.actuadores_on)
	inputs_data.actuadoreson = Split(args.actuadores_on, ",")
else
	inputs_data.actuadoreson = nil
end

if args.actuadores_off ~= "" and type(args.actuadores_off) == "string" then
	_storage.set_string("actuadoresOff"..tostring(numberPlugin), args.actuadores_off)
	inputs_data.actuadoresoff = Split(args.actuadores_off, ",")
else
	inputs_data.actuadoresoff = nil
end

if args.sensor_puerta ~= nil then
	_storage.set_string("sensorPuerta"..tostring(numberPlugin), args.sensor_puerta)
	inputs_data.sensor_puerta = tostring(args.sensor_puerta)

else
	inputs_data.sensor_puerta = nil
end

if args.Aire ~= nil and args.Aire then
	_storage.set_string("aire", args.Aire)
	inputs_data.Aire = Split(args.Aire, ",")
	inputs_data.Thermostat = _core.get_items_by_device_id(args.Aire)
	local thermostat = {}
	for _, item in ipairs(inputs_data.Thermostat) do
		if item.name == "thermostat_setpoint_cooling" then
			thermostat.setpoint = {
				_id = item.id,
				name = item.name,
				value = item.value
			}
		elseif item.name == "thermostat_mode" then
			thermostat.mode = {
				name = item.name,
				_id = item.id,
				value = item.value
			}
		elseif item.name == "thermostat_fan_state" then
			thermostat.fanState = {
				name = item.name,
				_id = item.id,
				value = item.value
			}
		elseif item.name == "thermostat_fan_mode" then
			thermostat.fanMode = {
				name = item.name,
				_id = item.id
			}
		elseif item.name == "thermostat_operating_state" then
			thermostat.operatingState = {
				name = item.name,
				_id = item.id
			}
		elseif item.name == "temp" then
			thermostat.temp = {
				name = item.name,
				_id = item.id
			}
		end
	end
	_storage.set_table("TERMOSTATO"..tostring(numberPlugin), thermostat)
	-- _storage.set_string("AIRE",args.Aire)
else
	inputs_data.Aire = nil
end

if args.sensor_movbatt ~= nil then
	_storage.set_string("sernsorMovBatt"..tostring(numberPlugin), args.sensor_movbatt)
	inputs_data.sensormovbatt = Split(args.sensor_movbatt, ",")
else
	inputs_data.sensormovbatt = nil
end

if args.sensor_movelec ~= nil then
	_storage.set_string("sernsorMovElec"..tostring(numberPlugin), args.sensor_movelec)
	inputs_data.sensormovelec = Split(args.sensor_movelec, ",")
else
	inputs_data.sensormovelec = nil
end

if inputs_data then
	if inputs_data.sensor_puerta ~= nil then
	_storage.set_string("SENSOR_PUERTA"..tostring(numberPlugin), inputs_data.sensor_puerta)
	end
	if inputs_data.sensormovelec ~= nil then
		_storage.set_table("SENSOR_MOV_ELEC"..tostring(numberPlugin), inputs_data.sensormovelec)
	loadfile("HUB:plg.plugin_ocupacion/scripts/functions/createSensorMotion")()
	end
	_storage.set_table("ACTUADORES_ON"..tostring(numberPlugin), inputs_data.actuadoreson)
	_storage.set_table("ACTUADORES_OFF"..tostring(numberPlugin), inputs_data.actuadoresoff)
	_storage.set_table("SENSOR_MOV_BATT"..tostring(numberPlugin), inputs_data.sensormovbatt)
	_logger.info("SENSOR_MOV_ELEC"..tostring(numberPlugin))

	Registro("load successfully completed")
	_storage.set_string("CREDENTIALS", "true")	
	loadfile("HUB:plg.plugin_ocupacion/scripts/functions/create_device")()	
	loadfile("HUB:plg.plugin_ocupacion/scripts/startup")()
end
