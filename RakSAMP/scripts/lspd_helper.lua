require('addon')
require('route player_lib')
local sampev = require('samp.events')
local json = require ('json')
local bots = require ('bots')
local autologin = require ('autologin')

local lspdNick = bots.CREDENTIALS.POLICE[1][1]
local STREAM = {}
local ATWORK = {}
local SPECIAL_KEYS = { H = 3 }
local CODE = {6, 6, 6, 6}

autologin.autologin(lspdNick, bots.CREDENTIALS.POLICE[1][2], true, 'EXIT', true)

local function printlog(dict)
	local tag = '[lspd_helper] '
	dict['nick'] = getBotNick()
	print(tag..json.encode(dict))
end

local function AFKstate(state)
	if state then AFK_EMULATION = true print('AFK enabled') else AFK_EMULATION = false print('AFK disabled') end
end

local function pressSpecialKey(key)
	if not SPECIAL_KEYS[key] then return false end
    specialKey = SPECIAL_KEYS[key]
    updateSync()
end

local function getDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
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

function onConnect()
	if getBotNick() == lspdNick then lspd = true end
	
	if lspd then
		newTask(function()
			wait(60000 * 4) -- timeout
			printlog({type = 1, event = 'timeout', attributes = {}})
			exit()
		end)
	end
end

function sampev.onSendPlayerSync(data)
	if AFK_EMULATION then return false end
	
	if specialKey then
        data.specialKey = specialKey
        specialKey = nil
    end
end

function onPrintLog(text)
	if lspd and text:find("Spawn to family to treat...") then
		printlog({type = 0, event = 'treatment', attributes = {}})
		treatmentSpawn = true

	elseif lspd and text:find("stopping route lspd_closed_locker") then
		sendPickedUpPickup(lockerPickUp) -- extra picked up
		
	elseif lspd and text:find("stopping route lspd_open_locker") then
		sendPickedUpPickup(lockerPickUp) -- extra picked up
	
	elseif lspd and text:find("stopping route lspd_safe_420") then
		sendInput("/fsafe")

	elseif lspd and text:find("%[NET%] Connection was closed by the server") then
		printlog({type = 1, event = 'connection_closed', attributes = {}})
		--exit()
	
	elseif lspd and text:find("%[NET%] The connection was lost") then
		printlog({type = 1, event = 'connection_lost', attributes = {}})
		--exit()
	end
end

function sampev.onServerMessage(color, text)
	if lspd and members then
		if text:find("ID: %d+ | %d%d:%d%d %d%d%.%d%d%.%d%d%d%d | %a+_%a+ [%(Voice%)]*: .+%[%d+%] %- .+") then
			local nick, state = text:match("ID: %d+ | %d%d:%d%d %d%d%.%d%d%.%d%d%d%d | (%a+_%a+) [%(Voice%)]*: .+%[%d+%] %- (.+)")
			if nick ~= lspdNick and not bots.contains(bots.WHITELIST, nick) and state:find("На работе") then
				table.insert(ATWORK, nick)
			end
		elseif text:match("^ Всего: %d+ человек") then
			members = false
			if #ATWORK > 0 then
				printlog({type = 0, event = 'players_atwork', attributes = {players_atwork = ATWORK}})
				exit()
			end
		end
	
	elseif lspd and text:find("^ Рабочий день начат$") then
		local myX, myY, myZ = getBotPosition()
		local around = ifPlayersAroundCoords(myX, myY, myZ, 15.25)
		
		if around and not bots.isSubset(around, bots.WHITELIST) then
			printlog({type = 0, event = 'players_around', attributes = {players_around = around}})
			newTask(function() exit() end, 3000)
		else
			sendInput("/takekeys job")
		end
	
	elseif lspd and (text:find("^ "..lspdNick.." взял%(а%) ключи от камеры") and color == -1920073984 or text:find("^ У вас уже есть ключи от камеры$")) then
		reconnectSpawn = true
		autologin.autologin(lspdNick, bots.CREDENTIALS.POLICE[1][2], true, 'FAMILY', true)
		print('Key taken. Reconnecting to family...')
		newTask(function() reconnect(15000) end, 3000)
	
	elseif lspd and text:find("^ Вы положили в сейф 1 ключей$") then
		printlog({type = 0, event = 'key_obtained', attributes = {}})
		--printlog({type = 0, event = 'players_memory', attributes = {players_memory = STREAM}})
		newTask(function() exit() end, 3000)
	
	elseif lspd and text:find("^ Ключи от камер нельзя брать так часто!$") then
		printlog({type = 1, event = 'too_often', attributes = {}})
		newTask(function() exit() end, 3000)
	
	elseif lspd and text:find("^ У Вас нет столько ключей$") then
		printlog({type = 1, event = 'no_keys', attributes = {}})
		newTask(function() exit() end, 3000)
	end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
	if lspd and id == 20306 and title:find("Раздевалка") and (lspd_closed_locker or lspd_open_locker) then
		lspd_closed_locker = false
		lspd_open_locker = false
		newTask(function() sendDialogResponse(20306, 1, 0, "") end, 200)
		return false

	elseif lspd and AUTOPUT and id == 32700 and title:find("Сейф | {ae433d}Положить") then
		sendDialogResponse(32700, 1, 0, '1')
		closetd = true
		return false
	end
end

function sampev.onMoveObject(id, fromPos, destPos, speed, rotation)
	if lspd and id == doorId and lspd_closed_lock then
		printlog({type = 0, event = 'door_moved', attributes = {route = 'lspd_closed_lock'}})
		exit()
		
	elseif lspd and id == doorId and lspd_closed_doorwait and math.floor(destPos.x) == 1196 and math.floor(destPos.y) == 1337 and math.floor(destPos.z) == 3011 then
		print('Door opened')
		lspd_closed_doorwait = false
		lspd_closed_locker = true
		newTask(function() runRoute("!play lspd_closed_locker") end, 800)
		
	elseif lspd and id == doorId and lspd_closed_locker then
		printlog({type = 0, event = 'door_moved', attributes = {route = 'lspd_closed_locker'}})
		exit()

	elseif lspd and id == doorId and lspd_open_locker then
		printlog({type = 0, event = 'door_moved', attributes = {route = 'lspd_open_locker'}})
		exit()
	end
end

local dialing = newTask(
	function()
		for _, digit in ipairs(CODE) do
			wait(200)
			if digit == 0 then sendClickTextdraw(tdindex + 11) else sendClickTextdraw(tdindex + digit) end
		end
	end, true)

local ok_pressing = newTask(function() wait(200) sendClickTextdraw(tdindex + 12) end, true)

local autoputting = newTask(
	function()
		sendClickTextdraw(tdindex + 27) -- keys
		wait(200)
		sendClickTextdraw(tdindex + 42) -- PUT
	end, true)

function sampev.onShowTextDraw(id, data)
	--if lspd and not reconnectSpawn and data.text == "SPAWN_SELECTION_" then
	--	members = true
	--	sendInput("/members")

	if lspd and data.text == '~b~PRESS: ~w~H' and lspd_closed_lock then
		lspd_closed_lock = false
		lspd_closed_doorwait = true
		newTask(function()
			runRoute('!stop')
			pressSpecialKey('H') 
		end, 1000)
	
    elseif lspd and (AUTOPW or AUTOPUT) and (data.text == 'VEHICLE' or data.text == 'BOAT') then
		FAMILYSAFE = false
	
	elseif lspd and AUTOPW and FAMILYSAFE and (data.text == 'X____0____>') then
		tdindex = id
		dialing:resume()
	
	--number confirmation
	elseif lspd and AUTOPW and FAMILYSAFE and (#data.text == 4 and data.text == table.concat(CODE)) then
		ok_pressing:resume()
	
	elseif lspd and closetd then 
		sendClickTextdraw(65535)
		closetd = false
		
	elseif lspd and AUTOPUT and (data.modelId == 348) then
		tdindex = id
		
	elseif lspd and AUTOPUT and (data.text == "TAKE") then
		autoputting:resume()
	end
end

function sampev.onCreateObject(id, data) -- II
	if lspd and loginSetSpawn and interiorIn and data.modelId == 19859 and math.floor(data.position.x) == 1197 and math.floor(data.position.y) == 1337 and math.floor(data.position.z) == 3011 then
		print('object door closed')
		doorId = id
		lspd_closed_lock = true
		newTask(function() runRoute('!play lspd_closed_lock') end, 2500)
	
	elseif lspd and loginSetSpawn and interiorIn and data.modelId == 19859 and math.floor(data.position.x) == 1196 and math.floor(data.position.y) == 1337 and math.floor(data.position.z) == 3011 then
		print('object door open')
		doorId = id
		lspd_open_locker = true
		newTask(function() runRoute('!play lspd_open_locker') end, 2500)
	end
end

function sampev.onSetPlayerPos(position) -- I
	if lspd and loginSetSpawn and not firstSpawn then
		firstSpawn = true
		members = true
		sendInput("/members")

	elseif lspd and loginSetSpawn and math.floor(position.x) == 1209 and math.floor(position.y) == 1333 and math.floor(position.z) == 3011 then
		interiorIn = true
	end
end

function sampev.onPlayerStreamIn(playerId, _, _, position) -- III
	local myX, myY, myZ = getBotPosition()
	local nickIn = (getPlayer(playerId)).nick
	
	if lspd and loginSetSpawn and interiorIn and getDistanceBetweenCoords(position.x, position.y, position.z, myX, myY, myZ) <= 55 then
		print('[StreamIn] '..nickIn)
		table.insert(STREAM, nickIn)
	end
end

function sampev.onCreatePickup(id, model, pickupType, position) -- IV
	local myX, myY, myZ = getBotPosition()
	
	if lspd and loginSetSpawn and not entdoorPickedUp and model == 19130 and getDistanceBetweenCoords(position.x, position.y, position.z, myX, myY, myZ) <= 3 then
		sendPickedUpPickup(id)
		entdoorPickedUp = true

	elseif lspd and loginSetSpawn and interiorIn and model == 1275 then
		lockerPickUp = id
	end
end

function sampev.onSetSpawnInfo(_, _, _, position)
	if lspd and treatmentSpawn then
		treatmentSpawn = false

	elseif lspd and not loginSetSpawn then
		loginSetSpawn = true
		
	elseif lspd and reconnectSpawn then
		reconnectSpawn = false
		AUTOPW, AUTOPUT, FAMILYSAFE = true, true, true
		
		if math.floor(position.x) == 225 and math.floor(position.y) == 1023 and math.floor(position.z) == 1084 then 
			newTask(function() runRoute("!play lspd_safe_225") end, 2000)

		elseif math.floor(position.x) == 420 and math.floor(position.y) == 2536 and math.floor(position.z) == 10 then 
			newTask(function() runRoute("!play lspd_safe_420") end, 2000)
		end
	
	elseif lspd then -- died/spawned
		printlog({type = 1, event = 'set_spawn', attributes = {}})
		newTask(function()
			AFKstate(true)
			wait(3000)
			exit()
		end)
	end
end