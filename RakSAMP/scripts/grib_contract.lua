require('addon')
local sampev = require('samp.events')
local json = require ('json')
local bots = require ('bots')
local autologin = require ('autologin')

local gribNicks = bots.GRIB
local CONTRACTS = { [14] = 'Грибное место' }
local STREAM = {}
local GRIB_CNTR = 0

for i, bot in ipairs(bots.CREDENTIALS.GRIB) do
	autologin.autologin(bot[1], bot[2], true, 'EXIT', true)
end

local function printlog(dict)
	local tag = '[grib_contract] '
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

local function completionNotification()
	printlog({type = 0, event = 'grib_counter', attributes = {counter = GRIB_CNTR}})
	printlog({type = 0, event = 'players_memory', attributes = {players_memory = STREAM}})
	
	if completed then
		printlog({type = 0, event = 'completed', attributes = {completed = true}})
	else
		printlog({type = 0, event = 'completed', attributes = {completed = false}})
	end
	
	--exit()
end

function onConnect()
	if bots.contains(gribNicks, getBotNick()) then grib = true end
	
	if grib then
		newTask(function()
			wait(60000 * 2) -- timeout
			printlog({type = 1, event = 'timeout', attributes = {}})
			--exit()
		end)
	end
end

function sampev.onSendPlayerSync(data)
	if AFK_EMULATION then return false end
end

function onPrintLog(text)
	if grib and text:find("Spawn to family to treat...") then
		printlog({type = 0, event = 'treatment', attributes = {}})
		treatmentSpawn = true

	elseif grib and text:find("%[NET%] Connection was closed by the server") then
		printlog({type = 1, event = 'connection_closed', attributes = {}})
		--exit()

	elseif grib and text:find("%[NET%] The connection was lost") then
		printlog({type = 1, event = 'connection_lost', attributes = {}})
		--exit()
	end
end

function sampev.onServerMessage(color, text)		
	if grib and text:find("^ "..getBotNick().." срезал%(а%) гриб$") then
		printlog({type = 0, event = 'grib_picked', attributes = {}})
		
	elseif grib and text:find("^ Контракт принят%. Для его выполнения:") then
		print("Contract started")
	
	elseif grib and text:find("^ Взять контракт могут только глава семьи и его заместитель") then
		printlog({type = 1, event = 'fcon_rank', attributes = {}})
		exit()
	
	elseif grib and text:find("^ Нельзя взять больше %d контрактов") then
		printlog({type = 1, event = 'fcon_limit', attributes = {}})
		exit()
	
	elseif grib and text:find('^ Ваша семья успешно завершила контракт {FFFFFF}"Грибное место"{CCCCCC}') then
		completed = true
	end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)	
	if grib and fcon and id == 32700 then
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

function sampev.onPlayerStreamIn(playerId, _, _, position) -- I
	local myX, myY, myZ = getBotPosition()
	
	if grib and loginSetSpawn then
		local nickIn = (getPlayer(playerId)).nick
		
		if not bots.contains(gribNicks, nickIn) then
			print('[StreamIn] '..nickIn)
			if getDistanceBetweenCoords(position.x, position.y, position.z, myX, myY, myZ) <= 50 then
				table.insert(STREAM, nickIn)
			end
		end
	end
end

function sampev.onCreatePickup(id, model, pickupType, position) -- II -- 1m 15m
	local myX, myY, myZ = getBotPosition()
	local radius = 15
	
	if grib and loginSetSpawn and model == 1603 and getDistanceBetweenCoords(position.x, position.y, position.z, myX, myY, myZ) <= radius then
		GRIB_CNTR = GRIB_CNTR + 1
		sendPickedUpPickup(id)
	end
	
	if loginSetSpawn and not getPickups then
		getPickups = true
		print('Pickups reached')
		newTask(completionNotification, 1000)
	end
end

function sampev.onSetSpawnInfo(_, _, _, position)
	if grib and treatmentSpawn then
		treatmentSpawn = false
		
	elseif grib and not loginSetSpawn then
		loginSetSpawn = true
		newTask(completionNotification, 8000)
		
	elseif grib then -- died/spawned
		printlog({type = 1, event = 'set_spawn', attributes = {}})
		newTask(function()
			AFKstate(true)
			wait(3000)
			exit()
		end)
	end
end

function sampev.onShowTextDraw(id, data)
	if grib and data.text == "SPAWN_SELECTION_" then
		takeContract(14)
	end
end