
local _M = {}

_M.DEFAULT_PASSWORD = "horusconfig"
_M.STORAGE_ACCOUNT_KEY = "account"

_M.ACTUADORES_ON= ... or {}
_M.ACTUADORES_OFF= ... or {}
_M.IDMASTERSWITCH= ... or {}
_M.SENSOR_MOV_BATT = ... or {}
_M.SENSOR_MOV_ELEC = ... or {}
_M.SENSOR_PUERTA = ""
_M.AIRE = ""
_M.TERMOSTATO = ... or {}
_M.SETPOINTON = 23
_M.SETPOINTOFF = 25
_M.MODOSETPOINT = "" or "no"
_M.OFFPUERTAABIERTA = "" or "si"
_M.MASTERSWITCH = "" or "no"
_M.MOTIONACTIVATOR = "" or "no"
_M.TIEMPOSCAN = 900
_M.CREDENTIALS = "true"

return _M