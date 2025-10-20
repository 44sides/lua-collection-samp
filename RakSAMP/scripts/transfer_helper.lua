require('addon')
require('route player_lib')
local sampev = require('samp.events')
local inicfg = require ('inicfg')
local json = require ('json')
local bots = require ('bots')
local autologin = require ('autologin')

local transferNick = bots.CREDENTIALS.TRANSFER[1][1]
local STREAM = {}
local WINDOW_OBJECTS = {}
local WINDOWS_COORDS = {
	{-2314.7836914062, 484.1210021973, 72.2092971802},
	{-2314.7836914062, 486.7055969238, 72.2092971802},
	{-2314.7836914062, 489.1890869141, 72.2092971802},
	{-2314.7836914062, 491.6738891602, 72.2092971802},
	{-2314.7836914062, 494.2687072754, 72.2092971802}
}

autologin.autologin(transferNick, bots.CREDENTIALS.TRANSFER[1][2], true, 'EXIT', true)

local cfg = inicfg.load(nil, 'transfer_helper.ini')

local function printlog(dict)
	local tag = '[transfer_helper] '
	dict['nick'] = getBotNick()
	print(tag..json.encode(dict))
end

local function AFKstate(state)
	if state then AFK_EMULATION = true print('AFK enabled') else AFK_EMULATION = false print('AFK disabled') end
end

local function getDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

local function round(num, decimalPlaces)
    local factor = 10 ^ decimalPlaces
    return math.floor(num * factor + 0.5) / factor
end

local function getPlayerByNick(nick)
	for k, v in pairs(getAllPlayers()) do
		if v.nick == nick then
			return k, v
		end
	end
	return false
end

local function ifPlayersAroundCoords(x, y, z, radius)
	local around = {}
	for k, v in pairs(getAllPlayers()) do
		if doesPlayerExist(k) then
			if getDistanceBetweenCoords(x, y, z, v.position.x, v.position.y, v.position.z) <= radius then
				table.insert(around, v.nick)
			end
		end
	end
	
	if #around > 0 then
		return around
	end
	
	return false
end

local function coordsToWindow(x, y, z)
	for i, v in ipairs(WINDOWS_COORDS) do
		if v[1] == x and v[2] == y and v[3] == z then
			return i
		end
	end
	
	return false
end

local function findFreeWindow(windows)
	for k, v in pairs(windows) do
		if not ifPlayersAroundCoords(v.position.x, v.position.y, v.position.z, 2) then
			return coordsToWindow(v.position.x, v.position.y, v.position.z)
		end
	end
	
	return false
end

local function transferMoney(sum, nick)
	sendDialogResponse(9100, 1, 6, '')
	sendDialogResponse(9106, 1, 0, sum..' '..nick)
	sendDialogResponse(9100, 0, 0, '')
end

function onConnect()
	if getBotNick() == transferNick and cfg.main.mode == 0 then transfer = true end
	if getBotNick() == transferNick and cfg.main.mode == 1 then
		deposit = true
		autologin.autologin(transferNick, bots.CREDENTIALS.TRANSFER[1][2], true, '', false)
	end
	
	if (transfer or deposit) then
		newTask(function()
			wait(60000 * 5) -- timeout
			printlog({type = 1, event = 'timeout', attributes = {}})
			exit()
		end)
	end
end

function sampev.onSendPlayerSync(data)
	if AFK_EMULATION then return false end
end

function onPrintLog(text)
	if transfer and text:find("Spawn to family to treat...") then
		printlog({type = 0, event = 'treatment', attributes = {}})
		treatmentSpawn = true

	elseif (transfer or deposit) and text:find("%[NET%] Connection was closed by the server") then
		printlog({type = 1, event = 'connection_closed', attributes = {}})
		exit()

	elseif (transfer or deposit) and text:find("%[NET%] The connection was lost") then
		printlog({type = 1, event = 'connection_lost', attributes = {}})
		exit()
	end
end

function sampev.onServerMessage(color, text)
	if transfer and text:find("^ Переведено на счет .+: %$%d+") then
		local nick_transferred, sum_transferred = text:match("^ Переведено на счет (.+): %$(%d+)")
		printlog({type = 0, event = 'transferred', attributes = {nick = nick_transferred, sum = tonumber(sum_transferred)}})
		newTask(function() exit() end, 3000)
		
	elseif transfer and text:find("^ Новый баланс: %$%d+") then
		local new_balance = text:match("^ Новый баланс: %$(%d+)")
		printlog({type = 0, event = 'balance', attributes = {balance = tonumber(new_balance)}})

	elseif transfer and text:find("^ Недостаточно средств на банковском счету") then
		printlog({type = 1, event = 'not_enough_money', attributes = {}})
		newTask(function() exit() end, 3000)
		
	elseif transfer and text:find("^ Неправильная сумма%. Минимально %- %$1, максимально %- %$10000000") then
		printlog({type = 1, event = 'bad_input', attributes = {nick = cfg.main.nick, sum = cfg.main.sum}})
		newTask(function() exit() end, 3000)

	elseif transfer and text:find("^ Игрок не авторизован") then
		printlog({type = 1, event = 'bad_recipient', attributes = {nick = cfg.main.nick}})
		newTask(function() exit() end, 3000)
		
	elseif transfer and text:find("^ У игрока нет банковского счёта") then
		printlog({type = 1, event = 'bad_recipient', attributes = {nick = cfg.main.nick}})
		newTask(function() exit() end, 3000)
	
	elseif deposit and text:find("^ .+ перевел Вам %$%d+%. %[Метка: .+]") then
		local nick_deposit, sum_deposit, timestamp_deposit = text:match("^ (.+) перевел Вам %$(%d+)%. %[Метка: (.+)]")
		printlog({type = 0, event = 'deposited', attributes = {nick = nick_deposit, sum = tonumber(sum_deposit), timestamp = timestamp_deposit}})
		sendInput('/stats')
	end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)	
	if transfer and id == 9100 and title:find("Меню") then
		if not transferred then
			transferred = true
			newTask(transferMoney, 5000, cfg.main.sum, cfg.main.nick)
		end
		return false

	elseif transfer and id == 9106 and title:find("Перевести игроку со счета") then
		return false
	
	elseif transfer and id == 9105 and title:find("Перевести игроку с наличных") then
		printlog({type = 1, event = 'bad_input', attributes = {nick = cfg.main.nick, sum = cfg.main.sum}})
		newTask(function() exit() end, 3000)
		return false
		
	elseif deposit and id == 9901 and title:find("Статистика") then
		local new_balance = text:match("Банковский%sсчет%s+([^%s]+)"):gsub("%.", "")
		printlog({type = 0, event = 'balance', attributes = {balance = tonumber(new_balance)}})
		newTask(function() exit() end, 3000)
		return false
	end
end

function sampev.onPlayerStreamIn(playerId, _, _, position) -- III
	local myX, myY, myZ = getBotPosition()	
	
	if transfer and loginSetSpawn and interiorIn and getDistanceBetweenCoords(position.x, position.y, position.z, myX, myY, myZ) <= 45 then
		local nickIn = (getPlayer(playerId)).nick
		
		print('[StreamIn] '..nickIn)
		table.insert(STREAM, nickIn)
	end
end

function sampev.onCreateObject(id, data) -- II
	if transfer and loginSetSpawn and interiorIn and data.modelId == 1317 and (math.floor(data.position.x) ~= -2296 or math.floor(data.position.y) ~= 495 or math.floor(data.position.z) ~= 72) then
		WINDOW_OBJECTS[id] = {position = {x = round(data.position.x, 10), y = round(data.position.y, 10), z = round(data.position.z, 10)}}
	end
end

function sampev.onSetPlayerPos(position) -- I
	if transfer and math.floor(position.x) == -2296 and math.floor(position.y) == 489 and math.floor(position.z) == 74 then
		interiorIn = true
	end
end

function sampev.onCreatePickup(id, model, pickupType, position) -- IV
	local myX, myY, myZ = getBotPosition()
	
	if transfer and loginSetSpawn and not entdoorPickedUp and model == 19130 and getDistanceBetweenCoords(myX, myY, myZ, position.x, position.y, position.z) <= 3 then
		entdoorPickedUp = true
		sendPickedUpPickup(id)
	
	elseif transfer and loginSetSpawn and interiorIn and not getPickups then
		getPickups = true
		local window = findFreeWindow(WINDOW_OBJECTS)
		newTask(function() runRoute('!play transfer_window_'..(window and window or 1)) end, 2000)
	end
end

function sampev.onSetSpawnInfo(_, _, _, position)
	if transfer and treatmentSpawn then
		treatmentSpawn = false
		
	elseif transfer and not loginSetSpawn then
		loginSetSpawn = true
		
	elseif transfer and loginSetSpawn then -- died/spawned
		printlog({type = 1, event = 'set_spawn', attributes = {}})
		newTask(function()
			AFKstate(true)
			wait(3000)
			exit()
		end)
	end
end

function sampev.onShowTextDraw(id, data)
	if transfer and data.text == "SPAWN_SELECTION_" then
		print(getPlayerByNick(cfg.main.nick))
		sendInput('/id '..cfg.main.nick)
		if not getPlayerByNick(cfg.main.nick) then
			newTask(function()
				wait(1500)
				sendInput('/id '..cfg.main.nick)
				wait(1000)
				printlog({type = 1, event = 'bad_recipient', attributes = {nick = cfg.main.nick}})
				exit()
			end)
			--printlog({type = 1, event = 'bad_recipient', attributes = {nick = cfg.main.nick}})
			--exit()
		end
	end
end