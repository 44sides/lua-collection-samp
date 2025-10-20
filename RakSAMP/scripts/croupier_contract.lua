require("addon")
local sampev = require("samp.events")
require("route player_lib")

local dragonsNick, caligulaNick = "Nick_Name", "Nick_Name" -- croupiers 6 rang
local AFK_CONFIG = false
local counter = 0

local CONTRACTS = { [4] = "Ограбление века", [6] = "Я Вас где%-то видел", [7] = "Поножовщина", [9] = "Крутите барабан",
					[12] = "Будем лечить", [14] = "Грибное место", [15] = "Не оставим без лицензий" }
					
function AFKstate(state)
	if state then AFK_EMULATION = true print("AFK enabled") else AFK_EMULATION = false print("AFK disabled") end
end

function getDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

function takeContract(num)
	contract = num
	fcon = true
	sendInput("/fpanel")
	sendDialogResponse(32700, 1, 19, "")
	sendDialogResponse(32700, 1, 1, "")
end

function onConnect()
	if getBotNick() == dragonsNick then dragons = true end
	if getBotNick() == caligulaNick then caligula = true end
	
	if (dragons or caligula) then
		newTask(function()
			wait(60000 * 19) -- timeout
			print("Timeout - 19 minutes! Terminating...")
			print("[croupier_contract] Unexpected behavior!")
			exit()
		end)
	end
end

function ifPlayersAround(radius)
	local myX, myY, myZ = getBotPosition()
	local players = getAllPlayers()
	local around = {}
	for k, v in pairs(players) do
		if doesPlayerExist(k) then
			local distance = getDistanceBetweenCoords(myX, myY, myZ, v.position.x, v.position.y, v.position.z)
			if distance <= radius then
				table.insert(around, v.nick)
			end
		end
	end
	if #around > 0 then return around else return false end
end

function croupierDealing()
	dealing = true
	if AFK_CONFIG then AFKstate(true) end
	sendInput("/deal")
end

function sampev.onSendPlayerSync(data)
	if AFK_EMULATION then return false end
end

function sampev.onServerMessage(color, text)
	if (dragons or caligula) and text:find("^ Выпало число %d+.$") and dealing then
		counter = counter + 1
		print('Counter = '..counter)
		
		if counter == 51 then
			print('Counter limit! Disconnecting...')
			print("[croupier_contract] Unexpected behavior!")
			exit()
		end
		
		newTask(function()
			wait(1000)
			sendInput("/deal")
		end)
	end

	if dragons and text:find("Казино The Four Dragons закрыто, сегодня работает Casino Caligula") then
		print('Dragons is closed! Dragons disconnecting...')
		print("[croupier_contract] Dragons is closed!")
		exit()
	end
	
	if caligula and text:find("Казино Caligula закрыто, сегодня работает Casino The Four Dragons") then
		print('Caligula is closed! Caligula disconnecting...')
		print("[croupier_contract] Caligula is closed!")
		exit()
	end
	
	if (dragons or caligula) and text:find("^ Рулетка уже запущена!$") then
		newTask(function()
			print('Someone is already dealing! Disconnecting...')
			print("[croupier_contract] Someone is already dealing!")
			wait(15000)
			exit()
		end)
	end
	
	if (dragons or caligula) and text:find(" Контракт принят%. Для его выполнения:") then
		print("[croupier_contract] Contract started")
	end
	
	if (dragons or caligula) and text:find("Взять контракт могут только глава семьи и его заместитель") then
		print('You need the rank to take contract! Disconnecting...')
		print("[croupier_contract] Unexpected behavior!")
		exit()
	end
	
	if (dragons or caligula) and text:find('^ Нельзя взять больше %d контрактов$') then
		print('Contract number limit! Disconnecting...')
		print("[croupier_contract] Contract number limit!")
		exit()
	end
	
	if (dragons or caligula) and text:find('Ваша семья успешно завершила контракт {FFFFFF}"Крутите барабан"{CCCCCC}') then
		completed = true
	end
	
	if (dragons or caligula) and text:find("^ Награда: {32CD32}%$%d+") and completed then
		local reward = text:match("^ Награда: {32CD32}%$(%d+)")
		print('Contract completed. Disconnecting...')
		print('[croupier_contract] Contract completed/'..reward..'$')
		exit()
	end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
	if id == 32700 and fcon then
		if string.find(title, "Контракты") then
			local codeg = string.match(text, CONTRACTS[contract].."%s+%d+/%d+%s+%[ {(%w+)}") 
			if codeg == "FF0000" then 
				print("Taking contract...")
				sendDialogResponse(32700, 1, contract, "")
				sendDialogResponse(32700, 1, 0, "")
			elseif codeg == "32CD32" then
				if not taken then print("Contract already taken") end
				fcon = false
				taken = false
				closing = true
				sendDialogResponse(32700, 0, 0, "")
				sendDialogResponse(32700, 0, 0, "")
				sendDialogResponse(32700, 0, 0, "")
			elseif codeg == "FFCC00" then
				print("[croupier_contract] Contract already completed")
				exit()
			end
		end
		if string.find(text, "Вы действительно хотите взять контракт") then
			sendDialogResponse(32700, 1, 0, "")
			taken = true
		end
		return false
	end
	if id == 32700 and closing and string.find(title, "Панель") then
		closing = false
		return false
	elseif id == 32700 and closing then
		return false
	end
end

function onPrintLog(text)
	if dragons and text:find('stopping route croupier_dragons_table') then
		newTask(function()
			wait(3000)
			local around = ifPlayersAround(3.25)
			if around then
				print(table.concat(around, ', ')..' is around. Disconnecting...')
				print('[croupier_contract] Players around! '..table.concat(around, ', '))
				exit()
			else
				croupierDealing()
			end
		end)
	end
	if caligula and text:find('stopping route croupier_caligula_table') then
		newTask(function()
			wait(3000)
			local around = ifPlayersAround(3.25)
			if around then
				print(table.concat(around, ', ')..' is around. Disconnecting...')
				print('[croupier_contract] Players around! '..table.concat(around, ', '))
				exit()
			else
				croupierDealing()
			end
		end)
	end
	
	if (dragons or caligula) and text:find('Spawn to family to treat...') then
		treatmentSpawn = true
		print("[croupier_contract] Spawn to family to treat")
	end
	
	if (dragons or caligula) and text:find('%[NET%] Connection was closed by the server') then
		print("[croupier_contract] Connection was closed by the server")
		exit()
	end

	if (dragons or caligula) and text:find('%[NET%] The connection was lost') then
		print("[croupier_contract] The connection was lost")
		exit()
	end
end

function sampev.onSendPickedUpPickup(id)
	if dragons and id == lockerPickUp and not lockerPickedUp then
		lockerPickedUp = true
		
		newTask(function()
			wait(1500)
			runRoute("!play croupier_dragons_table")
		end)
	end
	
	if caligula and id == lockerPickUp and not lockerPickedUp then
		lockerPickedUp = true
		
		newTask(function()
			wait(1500)
			runRoute("!play croupier_caligula_table")
		end)
	end
end

function sampev.onSetSpawnInfo(_, _, _, position)
	if (dragons or caligula) and treatmentSpawn then
		treatmentSpawn = false
	elseif (dragons or caligula) and not loginSpawn then
		loginSpawn = true
	elseif dragons and loginSpawn then
		newTask(function()
			print('Dragons died/spawned! Disconnecting...')
			print("[croupier_contract] Unexpected behavior!")
			wait(3000)
			exit()
		end)
	elseif caligula and loginSpawn then
		newTask(function()
			print('Caligula died/spawned! Disconnecting...')
			print("[croupier_contract] Unexpected behavior!")
			wait(3000)
			exit()
		end)
	end
end

function sampev.onCreatePickup(id, model, pickupType, position)
	local myX, myY, myZ = getBotPosition()
	local distance = getDistanceBetweenCoords(myX, myY, myZ, position.x, position.y, position.z)

	if (dragons or caligula) and model == 19132 and distance <= 3 and not entdoorPickedUp then
		sendPickedUpPickup(id)
		entdoorPickedUp = true
	end
	
	if dragons and model == 1275 and math.floor(position.x) == 1963 and math.floor(position.y) == 1063 and math.floor(position.z) == 994 then
		lockerPickUp = id
		newTask(function()
			wait(2500)
			runRoute("!play croupier_dragons_locker")
			wait(2500)
			takeContract(9) -- taking contract
		end)
	end
	
	if caligula and model == 1275 and math.floor(position.x) == 2150 and math.floor(position.y) == 1603 and math.floor(position.z) == 1006 then
		lockerPickUp = id
		newTask(function()
			wait(2500)
			runRoute("!play croupier_caligula_locker")
			wait(2500)
			takeContract(9) -- taking contract
		end)
	end
end