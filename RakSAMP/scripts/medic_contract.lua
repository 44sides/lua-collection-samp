require('addon')
require('route player_lib')
local sampev = require('samp.events')
local json = require ('json')
local bots = require ('bots')
local autologin = require ('autologin')

local medicNick = bots.CREDENTIALS.MEDIC[1][1]
local clientNick = bots.CREDENTIALS.MEDIC[2][1]
local CONTRACTS = { [12] = 'Будем лечить' }
local STREAM = {}
local SPECIAL_KEYS = { Y = 1, N = 2 }
local counter = 0

local function printlog(dict)
	local tag = '[medic_contract] '
	dict['nick'] = getBotNick()
	print(tag..json.encode(dict))
end

local function AFKstate(state)
	if state then AFK_EMULATION = true print("AFK enabled") else AFK_EMULATION = false print("AFK disabled") end
end

local function takeContract(num)
	contract = num
	fcon = true
	sendInput('/fpanel')
	sendDialogResponse(32700, 1, 19, '')
	sendDialogResponse(32700, 1, 1, '')
	sendDialogResponse(32700, 1, contract, '')
end

local function getDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

local function sampSendTakeDamage(id, damage, weapon, bodypart)
	bs = bitStream.new()
	bs:writeBool(true)
	bs:writeUInt16(id)
	bs:writeFloat(damage)
	bs:writeUInt32(weapon)
	bs:writeUInt32(bodypart)
	return bs:sendRPC(115)
end

local function pressSpecialKey(key)
	if not SPECIAL_KEYS[key] then return false end
    specialKey = SPECIAL_KEYS[key]
    updateSync()
end

local function getPlayerByNick(nick)
	for k, v in pairs(getAllPlayers()) do
		if v.nick == nick then
			return k, v
		end
	end
	return false
end

-- @return str[][] table, int rows, int cols, str[] header
local function dialogToTable(header_status, text)
	local t, h = {}, nil
	
	for row in text:gmatch('[^\n]+') do
		t[#t+1] = {}
		for column in row:gmatch('[^%c]+') do
			table.insert(t[#t], column)
		end
	end

	if header_status then h = t[1] table.remove(t, 1) end
	
	return t, #t, #t[1], h
end

function onConnect()
	if getBotNick() == medicNick then 
		medic = true
		autologin.autologin(medicNick, bots.CREDENTIALS.MEDIC[1][2], true, 'EXIT', true)
	end
	if getBotNick() == clientNick then
		client = true
		autologin.autologin(clientNick, bots.CREDENTIALS.MEDIC[2][2], true, 'EXIT', true)
	end
	
	if (medic or client) then
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

-- function sampev.onPlayerSync(id, data)
	-- if medic and treating and id == clientId and data.health < 100 and not sent then
	-- end
-- end

function onPrintLog(text)
	if (medic or client) and text:find("Spawn to family to treat...") then
		printlog({type = 0, event = 'treatment', attributes = {}})
		treatmentSpawn = true

	elseif medic and text:find("%[Route Player%]: stopping route medic_food_") then
		printlog({type = 0, event = 'stopping_route', attributes = {name = 'medic_food_'}})
		takeContract(12)
		
	elseif client and text:find("%[Route Player%]: stopping route client_food_") then
		sampSendTakeDamage(65535, 1, 54, 3)
		sendInput('/hi '..getPlayerByNick(medicNick))

	elseif (medic or client) and text:find("%[NET%] Connection was closed by the server") then
		printlog({type = 1, event = 'connection_closed', attributes = {}})
		exit()
	
	elseif (medic or client) and text:find("%[NET%] The connection was lost") then
		printlog({type = 1, event = 'connection_lost', attributes = {}})
		exit()
	end
end

function sampev.onServerMessage(color, text)
	if medic and text:find("^ Рабочий день начат$") then
		newTask(function() runRoute('!play medic_food_'..route) end, 400)
	
	elseif medic and text:find("^ "..clientNick.."%[%d+%] предложил Вам пожать руку$") then
		clientId = getPlayerByNick(clientNick)
		sendInput('/heal '..clientId)
	
	elseif medic and text:find("^ Вы вылечили "..clientNick) then
		counter = counter + 1
		printlog({type = 0, event = 'treated', attributes = {}})
		newTask(function() sendInput('/heal '..clientId) end, 1250)
		
		if counter == 11 then
			printlog({type = 1, event = 'counter_exceeded', attributes = {}})
			exit()
		end
	
    elseif medic and (text:find("^ Игрок слишком далеко!$") or text:find("^ Игрок не найден$")) then
		printlog({type = 1, event = 'client_not_found', attributes = {}})
		exit()
	
	elseif medic and text:find("^ Контракт принят%. Для его выполнения:") then
		printlog({type = 0, event = 'started', attributes = {}})

	elseif medic and text:find("^ Взять контракт могут только глава семьи и его заместитель") then
		printlog({type = 1, event = 'fcon_rank', attributes = {}})
		exit()
	
	elseif medic and text:find("^ Нельзя взять больше %d контрактов$") then
		printlog({type = 1, event = 'fcon_limit', attributes = {}})
		exit()
		
	elseif medic and text:find('^ Ваша семья успешно завершила контракт {FFFFFF}"Будем лечить"{CCCCCC}') then
		printlog({type = 0, event = 'completed', attributes = {completed = true}})
		exit()

	elseif client and text:find("^ "..medicNick.."%[%d+%] предложил Вам провести курс оздоровления") then
		pressSpecialKey('Y')

	elseif client and text:find("^ "..medicNick.." вылечил Вас") then
		sampSendTakeDamage(65535, 1, 54, 3)
	
	elseif client and text:find("^ У Вас недостаточно денег$") then
		printlog({type = 1, event = 'no_money', attributes = {}})
		exit()
	end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
	if medic and fcon and id == 32700 then
		if not contract_taken then
		
			if title:find("Контракты") then
				local line = text:match(CONTRACTS[contract].."[^\n]+")
				if line:find("Не взят") then
					nottaken_status = true				
				elseif line:find("Выполняется") then
					inprogress_status = true		
				elseif line:find("Выполнен") then
					printlog({type = 0, event = 'completed_already', attributes = {}})
					exit()
				end
				
			elseif title:find(CONTRACTS[contract]) then
				local reward = tonumber(text:match("{32CD32}%$(%d+)"))
				printlog({type = 0, event = 'reward', attributes = {reward = reward}})	
				contract_taken = true
				if nottaken_status then
					sendDialogResponse(32700, 1, 0, "")
					sendDialogResponse(32700, 1, 0, "")
				elseif inprogress_status then
					printlog({type = 0, event = 'started_already', attributes = {}})
					sendDialogResponse(32700, 0, 0, "")
				end
				sendDialogResponse(32700, 0, 0, "")
				sendDialogResponse(32700, 0, 0, "")
				sendDialogResponse(32700, 0, 0, "")
			end
			
		elseif title:find("Панель") then
			fcon = false
		end
		
		return false

	elseif (medic or client) and id == 32700 and title:find("Лифт") then
		sendDialogResponse(32700, 1, 2, "")
		return false
	
	elseif medic and id == 20274 and title:find("Раздевалка") then
		newTask(function() sendDialogResponse(20274, 1, 0, "") end, 500)
		return false
	
	elseif client and id == 20302 and title:find("Принять") then
		for n, row in ipairs(dialogToTable(true, text)) do
			if row[1] == 'Курс оздоровления' and row[2] == medicNick then
				sendDialogResponse(20302, 1, n-1, "Курс оздоровления")
				break
			end
		end
		return false

	elseif client and id == 20301 and title:find("Подтверждение") then
		sendDialogResponse(20301, 1, 0, "")
		return false
	end
end

-- function sampev.onSendPickedUpPickup(id)
	-- if medic and id == foodPickUp and not foodPickedUp then
		-- foodPickedUp = true
		-- print('stop........')
		-- runRoute('!stop')
	-- end
-- end

function sampev.onApplyPlayerAnimation(id, animLib, animName)
	if medic and id == getBotId() and animName == 'EAT_Burger' then
		runRoute('!stop')
		updateSync()
	end
end

function sampev.onPlayerQuit(playerId, reason)
	if client and (getPlayer(playerId)).nick == medicNick then
		print('Medic quit! Disconnecting '..getBotNick())
		newTask(function() exit() end, 5000)
	end
end

function sampev.onTogglePlayerControllable(controllable) -- II
	if medic and interiorIn and controllable and not run then
		newTask(function() runRoute('!play medic_uniform_'..route) end, 400)
		run = true
	
	elseif client and interiorIn and controllable and not run then
		newTask(function() runRoute('!play client_food_'..route) end, 400)
		run = true
	end
end

function sampev.onSetPlayerPos(position) -- I
	if (medic or client) and (math.floor(position.x) == 23 or math.floor(position.x) == 28) and math.floor(position.y) == 421 and math.floor(position.z) == 3384 then
		interiorIn = true
		route = math.floor(position.x)
	end
end

function sampev.onPlayerStreamIn(playerId, _, _, position)
	local myX, myY, myZ = getBotPosition()

	if medic and loginSetSpawn and interiorIn and getDistanceBetweenCoords(position.x, position.y, position.z, myX, myY, myZ) <= 65 then
		local nickIn = (getPlayer(playerId)).nick
		
		if not bots.contains(bots.MEDIC, nickIn) then
			print('[StreamIn] '..nickIn)
			table.insert(STREAM, nickIn)
		end
	end
end

function sampev.onCreatePickup(id, model, pickupType, position)
	local myX, myY, myZ = getBotPosition()
	
	if (medic or client) and loginSetSpawn and not entdoorPickedUp and model == 19130 and getDistanceBetweenCoords(myX, myY, myZ, position.x, position.y, position.z) <= 3 then
		sendPickedUpPickup(id)
		entdoorPickedUp = true
	end
	
	-- if medic and model == 2219 then
		-- foodPickUp = id
	-- end
end

function sampev.onSetSpawnInfo(_, _, _, position)
	if (medic or client) and treatmentSpawn then
		treatmentSpawn = false

	elseif (medic or client) and not loginSetSpawn then
		loginSetSpawn = true
	
	elseif (medic or client) then -- died/spawned
		printlog({type = 1, event = 'set_spawn', attributes = {}})
		newTask(function()
			AFKstate(true)
			wait(3000)
			exit()
		end)
	end
end

function sampev.onShowTextDraw(id, data)
	if client and ((data.text):find(".+ %- .+ [%-+]") or (data.text):find("Collision")) then
		print(data.text:match("[^~]+"))
	end
end