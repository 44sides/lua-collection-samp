require('addon')
require('route player_lib')
local sampev = require('samp.events')
local json = require('json')
local bots = require('bots')
local autologin = require('autologin')

local lavkaNicks = bots.keysToList(bots.CREDENTIALS.LAVKA)
local STREAM = {}
local timezone = 3 - os.date("%z") / 100
local items = {}
local lavka_cntr = 0
local nameplate_position = {x=0,y=0,z=0}

if bots.contains(lavkaNicks, getBotNick()) then
	lavka = true
	autologin.autologin(getBotNick(), bots.CREDENTIALS.LAVKA[getBotNick()], true, 'EXIT', true)
end

local function printlog(dict)
	local tag = '[lavka_helper] '
	dict['nick'] = getBotNick()
	print(tag..json.encode(dict))
end

local function AFKstate(state)
	if state then AFK_EMULATION = true print("AFK enabled") else AFK_EMULATION = false print("AFK disabled") end
end

local function getDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

local function pressNormalKey(key)
	local NORMAL_KEYS = { ALT = 1024 }
	if not NORMAL_KEYS[key] then return false end
	normalKey = NORMAL_KEYS[key]
	updateSync()
	updateSync()
end

local function delayed_notification(callback)
	wait(1000)
	callback()
end

local function items_notification()		
	printlog({type = 0, event = 'items', attributes = items})
	items = {}
end

local function callMenu()
	while not lavka_called do
		pressNormalKey('ALT')
		print('ALT pressed')
		wait(1000)
	end
	lavka_called = false
end

function onConnect()
	if lavka then
		printlog({type = 0, event = 'connected', attributes = {ip = connected_ip}})
		newTask(function()
			wait(60000 * 3) -- timeout
			printlog({type = 1, event = 'timeout', attributes = {}})
			exit()
		end)
	end
end

function sampev.onSendPlayerSync(data)
	if AFK_EMULATION then return false end
	
	if normalKey then
        data.keysData = normalKey
        normalKey = nil
    end
end

function onPrintLog(text)
	if lavka and text:find("Spawn to family to treat...") then
		printlog({type = 0, event = 'treatment', attributes = {}})
		treatmentSpawn = true

	elseif lavka and text:find("%[NET%] Connection was closed by the server") then
		printlog({type = 1, event = 'connection_closed', attributes = {}})
		if loginSetSpawn then connectionSpawn = true end
	
	elseif lavka and text:find("%[NET%] The connection was lost") then
		printlog({type = 1, event = 'connection_lost', attributes = {}})
		if loginSetSpawn then connectionSpawn = true end

	elseif lavka and text:find("%[NET%] Bad nickname") then
		printlog({type = 1, event = 'bad_nickname', attributes = {}})
		newTask(function() exit() end, 1000)
	end
end

function sampev.onServerMessage(color, text)
	if lavka and text:find("^ [%[Offline%-info%]: ]?.+Ваша одежда {AE433D}.+ .+ выкуплена за {33AA33}%d+%$") then
		local amount = 1
		local item, price = text:match("Ваша одежда {AE433D}(.+) .+ выкуплена за {33AA33}(%d+)%$")
		items[item] = {(items[item] and items[item][1] or 0) + tonumber(amount), (items[item] and items[item][2] or 0) + tonumber(price)}
		if items_task then items_task:kill() end
		items_task = newTask(delayed_notification, false, items_notification)
			
	elseif lavka and text:find("^ [%[Offline%-info%]: ]?.+Ваш асессуар {AE433D}.+ .+ выкуплен за {33AA33}%d+%$") then
		local amount = 1
		local item, price = text:match("Ваш асессуар {AE433D}(.+) .+ выкуплен за {33AA33}(%d+)%$")
		items[item] = {(items[item] and items[item][1] or 0) + tonumber(amount), (items[item] and items[item][2] or 0) + tonumber(price)}
		if items_task then items_task:kill() end
		items_task = newTask(delayed_notification, false, items_notification)
				
	elseif lavka and text:find("^ [%[Offline%-info%]: ]?.+Ваш предмет {AE433D}.+ .+в количестве {AE433D}%d+ ед%. .+ выкуплен за {33AA33}%d+%$") then
		local item, amount, price = text:match("Ваш предмет {AE433D}(.+) .+в количестве {AE433D}(%d+) ед%. .+ выкуплен за {33AA33}(%d+)%$")
		items[item] = {(items[item] and items[item][1] or 0) + tonumber(amount), (items[item] and items[item][2] or 0) + tonumber(price)}
		if items_task then items_task:kill() end
		items_task = newTask(delayed_notification, false, items_notification)

	elseif lavka and text:find("^ Аренда прилавка была продлена") then
		local renewed_hours = text:match("(%d+) ч%.")
		local renewed_ts = end_ts + renewed_hours * 3600
		printlog({type = 0, event = 'renewed', attributes = {renewed_hours = tonumber(renewed_hours), renewed_ts = renewed_ts}})
		printlog({type = 0, event = 'players_memory', attributes = {players_memory = STREAM}})
		newTask(function() exit() end, 10000)

	elseif lavka and text:find("^ Вы не можете продлить аренду более чем на %d+ ч%.") or text:find("^ Вы указали неверное количество часов") then
		printlog({type = 1, event = 'bad_input', attributes = {}})
		exit()
	
	elseif lavka and text:find("^ У Вас недостатосно средств$") then
		printlog({type = 1, event = 'no_money', attributes = {}})
		exit()
	end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
	if lavka and id == 32700 and title:find("Прилавок | {AE433D}Меню") then
		lavka_called = true
		sendDialogResponse(32700, 1, 2, "")
		return false

	elseif lavka and id == 32700 and title:find("Прилавок | {AE433D}Продление аренды") then
		local H, M, d, m, Y = text:match("(%d%d):(%d%d) (%d%d)%.(%d%d)%.(%d%d%d%d)")
		end_ts = os.time({year = Y, month = m, day = d, hour = H - timezone, min = M, sec = 0})
		local left_sec = end_ts - os.time()
		local renewal_hour = 12 - left_sec / 3600
		sendDialogResponse(32700, 1, 0, tostring(math.floor(renewal_hour)))
		return false
	end
end

function sampev.onPlayerStreamIn(playerId, _, _, position)	
	if lavka and loginSetSpawn then
		local myX, myY, myZ = getBotPosition()
		local nickIn = (getPlayer(playerId)).nick
		print('[StreamIn] '..nickIn)
		if getDistanceBetweenCoords(position.x, position.y, position.z, myX, myY, myZ) <= 25 then
			table.insert(STREAM, nickIn)
		end
	end
end

function sampev.onCreateObject(id, data) -- I
	if lavka then
		if data.modelId == 18659 then
			obj_position = data.position
		end
	end
end

function sampev.onSetObjectMaterialText(id, data)
	if lavka then
		if data.fontName == 'Quartz MS' and data.text:find(getBotNick()) then -- II
			nameplate_position = obj_position
		end
	end
end

function sampev.onCreate3DText(id, color, position, _, _, _, _, text) -- III
	if lavka and text:find("^.+Прилавок .+№%d+") then
		local myX, myY, myZ = getBotPosition()
		lavka_cntr = lavka_cntr + 1
		
		if getDistanceBetweenCoords(position.x, position.y, position.z, nameplate_position.x, nameplate_position.y, nameplate_position.z) < 2 then
			if getDistanceBetweenCoords(position.x, position.y, position.z, myX, myY, myZ) < 1.20 then
				lavka_near = true
				newTask(callMenu)
			end
		end

		if lavka_cntr == 26 then 
			lavka_cntr = 0
			if not lavka_near then
				printlog({type = 1, event = 'too_far', attributes = {}})
				exit()
			end
		end
	end
end

function sampev.onSetSpawnInfo(_, _, _, position)
	if lavka and treatmentSpawn then
		treatmentSpawn = false

	elseif lavka and connectionSpawn then
		connectionSpawn = false

	elseif lavka and not loginSetSpawn then
		loginSetSpawn = true
	
	elseif lavka then -- died/spawned
		printlog({type = 1, event = 'set_spawn', attributes = {}})
		newTask(function()
			AFKstate(true)
			wait(3000)
			exit()
		end)
	end
end

function sampev.onConnectionRequestAccepted(ip)
	connected_ip = ip
end