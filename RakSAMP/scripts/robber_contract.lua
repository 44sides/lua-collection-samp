require('addon')
require('route player_lib')
local sampev = require('samp.events')
local json = require ('json')
local bots = require ('bots')
local autologin = require ('autologin')

local robberOneNick = bots.CREDENTIALS.ROBBER[1][1]
local robberTwoNick = bots.CREDENTIALS.ROBBER[2][1]
local robberThreeNick = bots.CREDENTIALS.ROBBER[3][1]
local CONTRACTS = { [4] = 'Ограбление века' }
local STREAM = {}

autologin.autologin(robberOneNick, bots.CREDENTIALS.ROBBER[1][2], true, 'EXIT', true)
autologin.autologin(robberTwoNick, bots.CREDENTIALS.ROBBER[2][2], true, 'EXIT', true)
autologin.autologin(robberThreeNick, bots.CREDENTIALS.ROBBER[3][2], true, 'EXIT', true)

local function printlog(dict)
	local tag = '[robber_contract] '
	dict['nick'] = getBotNick()
	print(tag..json.encode(dict))
end
					
local function AFKstate(state)
	if state then AFK_EMULATION = true print('AFK enabled') else AFK_EMULATION = false print('AFK disabled') end
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

local function robberRobbering()
	robbering_cntr = 0
	robbering = true
end

local function completionNotification()
	if cooldown then
		printlog({type = 0, event = 'robbed', attributes = {cooldown = true}})
		wait(60000 * 3.01)
	else
		printlog({type = 0, event = 'robbed', attributes = {cooldown = false}})
	end
	
	if completed then
		printlog({type = 0, event = 'completed', attributes = {completed = true}})
	else
		printlog({type = 0, event = 'completed', attributes = {completed = false}})
	end
	
	exit()
end

function onConnect()
	if getBotNick() == robberOneNick then robberOne = true end
	if getBotNick() == robberTwoNick then robberTwo = true end
	if getBotNick() == robberThreeNick then robberThree = true end
	
	if (robberOne or robberTwo or robberThree) then
		newTask(function()
			wait(60000 * 6) -- timeout
			printlog({type = 1, event = 'timeout', attributes = {}})
			exit()
		end)
	end
end

function sampev.onSendPlayerSync(data)
	if AFK_EMULATION then return false end
	
	if robbering then
		sendTargetUpdate(65535, 65535, 65535, actorId)
		if robbering_cntr % 2 == 0 then data.keysData = 128 end
		if robbering_cntr % 2 == 1 then data.keysData = 0 end
		robbering_cntr = robbering_cntr + 1
	end
end

function onPrintLog(text)
	if (robberOne or robberTwo or robberThree) and text:find("Spawn to family to treat...") then
		printlog({type = 0, event = 'treatment', attributes = {}})
		treatmentSpawn = true

	elseif robberOne and text:find("stopping route robberOne_spot") then
		--printlog({type = 0, event = 'stopping_route', attributes = {name = 'robberOne_spot'}})
		newTask(robberRobbering, 1500)
	
	elseif robberTwo and text:find("stopping route robberTwo_spot") then
		printlog({type = 0, event = 'stopping_route', attributes = {name = 'robberTwo_spot'}})
		newTask(function() AFKstate(true) end, 1000)
	
	elseif robberThree and text:find("stopping route robberThree_spot") then
		printlog({type = 0, event = 'stopping_route', attributes = {name = 'robberThree_spot'}})
		newTask(function() AFKstate(true) end, 1000)
	
	elseif (robberOne or robberTwo or robberThree) and text:find("%[NET%] Connection was closed by the server") then
		printlog({type = 1, event = 'connection_closed', attributes = {}})
		exit()
	
	elseif (robberOne or robberTwo or robberThree) and text:find("%[NET%] The connection was lost") then
		printlog({type = 1, event = 'connection_lost', attributes = {}})
		exit()
	end
end

function sampev.onServerMessage(color, text)
	if (robberOne or robberTwo or robberThree) and text:find("Если вы покинете игру в течение 3 минут, то будете посажены в тюрьму") then
		cooldown = true

	elseif (robberOne or robberTwo or robberThree) and text:find("^ Вы получили %$2500 от продавца$") then
		robbed = true
		newTask(completionNotification, 100)
	
	elseif robberOne and text:find("Имейте совесть%. Вы уже грабили недавно%. Полиция уже едет%. %(%( До следующего ограбления %d+:%d+ %)%)") then
		local timer = text:match("Имейте совесть%. Вы уже грабили недавно%. Полиция уже едет%. %(%( До следующего ограбления (%d+:%d+) %)%)")
		printlog({type = 0, event = 'robbed_already', attributes = {timer = timer}})
		exit()
		
	elseif robberOne and text:find("Вы серьезно%?! Я Вас не боюсь%. %(%( Необходимо минимум 3 человека %)%)") then
		printlog({type = 1, event = 'not_enough_robbers', attributes = {}})
		exit()
	
	elseif robberOne and text:find("^ Контракт принят%. Для его выполнения:") then
		print("Contract started")

	elseif robberOne and text:find("^ Взять контракт могут только глава семьи и его заместитель") then
		printlog({type = 1, event = 'fcon_rank', attributes = {}})
		exit()
	
	elseif robberOne and text:find("^ Нельзя взять больше %d контрактов$") then
		printlog({type = 1, event = 'fcon_limit', attributes = {}})
		exit()
	
	elseif (robberOne or robberTwo or robberThree) and text:find('^ Ваша семья успешно завершила контракт {FFFFFF}"Ограбление века"{CCCCCC}') then
		completed = true
	end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)	
	if robberOne and fcon and id == 32700 then
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
					print('Contract already taken')
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
	end
end

function sampev.onShowTextDraw(id, data)
	if robberOne and data.text == 'Robbery' then
		print('Robbery...')
		robbering = false
		takeContract(4)
	end
end

function sampev.onCreateActor(id, skinId, position, rotation, health) -- IV
	if (robberOne or robberTwo or robberThree) and loginSetSpawn and interiorIn and skinId == 43 then
		local myX, myY, myZ = getBotPosition()
		local around = ifPlayersAroundCoords(myX, myY, myZ, 30)
		
		if around and not bots.isSubset(around, bots.lists(bots.ROBBER, bots.WHITELIST)) then
			printlog({type = 0, event = 'players_around', attributes = {players_around = around}})
			exit()
		end
		
		getStream = true
		
		if robberOne then
			if not armed then
				printlog({type = 1, event = 'not_armed', attributes = {}})
				exit()
			end
			actorId = id
			newTask(function() runRoute('!play robberOne_spot') end, 2000)

		elseif robberTwo then
			newTask(function() runRoute('!play robberTwo_spot') end, 2000)
			
		elseif robberThree then
			newTask(function() runRoute('!play robberThree_spot') end, 2000)
		end
	end
end

function sampev.onPlayerQuit(playerId, reason)
	if (robberOne or robberTwo or robberThree) and not robbed then
		if bots.contains(bots.ROBBER, (getPlayer(playerId)).nick) then
			print('A robber quit! Disconnecting '..getBotNick())
			exit()
		end
	end
end

function sampev.onSetPlayerPos(position) -- I
	if (robberOne or robberTwo or robberThree) and math.floor(position.x) == 207 and math.floor(position.y) == -110 and math.floor(position.z) == 1005 then
		interiorIn = true
	end
end

function sampev.onPlayerStreamIn(playerId, _, _, position) -- II
	local myX, myY, myZ = getBotPosition()
	local nickIn = (getPlayer(playerId)).nick	
	
	if (robberOne or robberTwo or robberThree) and loginSetSpawn and interiorIn and getStream and not bots.contains(bots.lists(bots.ROBBER, bots.WHITELIST), nickIn) and getDistanceBetweenCoords(position.x, position.y, position.z, myX, myY, myZ) <= 30 then
		print('[StreamIn] '..nickIn)
		table.insert(STREAM, nickIn)
		printlog({type = 0, event = 'players_around', attributes = {players_around = STREAM}})
		exit()
	end
end

function sampev.onGivePlayerWeapon(weapon, ammo)
	if robberOne and weapon == 24 then
		armed = true
	end
end

function sampev.onCreatePickup(id, model, pickupType, position)	-- III
	local myX, myY, myZ = getBotPosition()

	if (robberOne or robberTwo or robberThree) and loginSetSpawn and not entdoorPickedUp and model == 19130 and getDistanceBetweenCoords(myX, myY, myZ, position.x, position.y, position.z) <= 3 then
		local around = ifPlayersAroundCoords(myX, myY, myZ, 15)
		
		if around and not bots.isSubset(around, bots.lists(bots.ROBBER, bots.WHITELIST)) then
			printlog({type = 0, event = 'players_around', attributes = {players_around = around}})
			exit()
		end
		
		sendPickedUpPickup(id)
		entdoorPickedUp = true
	end
end

function sampev.onSetSpawnInfo(_, _, _, position)
	if (robberOne or robberTwo or robberThree) and treatmentSpawn then
		treatmentSpawn = false

	elseif (robberOne or robberTwo or robberThree) and not loginSetSpawn then
		loginSetSpawn = true
	
	elseif (robberOne or robberTwo or robberThree) then -- died/spawned
		printlog({type = 1, event = 'set_spawn', attributes = {}})
		newTask(function()
			AFKstate(true)
			wait(3000)
			exit()
		end)
	end
end