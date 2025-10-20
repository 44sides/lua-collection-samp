require("addon")
local sampev = require("samp.events")
require("route player_lib")

local instructorNick, studentNick = "Nick_Name", "Nick_Name" -- instructor 6 rang, first logged in
local AFK_CONFIG = true

local SPECIAL_KEYS = { H = 3 }
local CONTRACTS = { [4] = "Ограбление века", [6] = "Я Вас где%-то видел", [7] = "Поножовщина", [9] = "Крутите барабан",
					[12] = "Будем лечить", [14] = "Грибное место", [15] = "Не оставим без лицензий" }

function pressSpecialKey(key)
	if not SPECIAL_KEYS[key] then return false end
    specialKey = SPECIAL_KEYS[key]
    updateSync()
end

function AFKstate(state)
	if state then AFK_EMULATION = true print("AFK enabled") else AFK_EMULATION = false print("AFK disabled") end
end

function takeContract(num)
	contract = num
	fcon = true
	sendInput("/fpanel")
	sendDialogResponse(32700, 1, 19, "")
	sendDialogResponse(32700, 1, 1, "")
end

local counter = 0

function onConnect()
	if getBotNick() == instructorNick then instructor = true end
	if getBotNick() == studentNick then student = true end
	
	if (instructor or student) then
		newTask(function()
			wait(60000 * 5) -- timeout
			print("Timeout - 5 minutes! Terminating...")
			print("[instructor_contract] Unexpected behavior!")
			exit()
		end)
	end
end

function getPlayerId(nick)
	local players = getAllPlayers()
	for k, v in pairs(players) do
		if v.nick == nick then
			return k
		end
	end
	return false
end

function getDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

function ifPlayersAround()
	local myX, myY, myZ = getBotPosition()
	local players = getAllPlayers()
	for k, v in pairs(players) do
		if doesPlayerExist(k) then 
			local distance = getDistanceBetweenCoords(myX, myY, myZ, v.position.x, v.position.y, v.position.z)
			if distance <= 3.25 then
				return true
			end
		end
	end
end

function instructorSelling()
	--selling = true
	sendInput("/givelicense "..studentId)
end

function sampev.onSendPlayerSync(data)
	if AFK_EMULATION then return false end
	
	if specialKey then
        data.specialKey = specialKey
        specialKey = nil
    end
end

function onPrintLog(text)
	if instructor and text:find('stopping route instructor_health_closed') then
		if AFK_CONFIG then AFKstate(true) end
		takeContract(15) -- taking contract
	end

	if instructor and text:find('stopping route instructor_health_open') then
		if AFK_CONFIG then AFKstate(true) end
		takeContract(15) -- taking contract
	end
	
	if (instructor or student) and text:find('%[NET%] Connection was closed by the server') then
		print("[instructor_contract] Connection was closed by the server")
		exit()
	end

	if (instructor or student) and text:find('%[NET%] The connection was lost') then
		print("[instructor_contract] The connection was lost")
		exit()
	end
end

function sampev.onServerMessage(color, text)
	if instructor and text:find(studentNick.." читает Правила Дорожного Движения") then
		newTask(function()
			print('Instructor selling...')
			studentId = getPlayerId(studentNick)
			wait(5000)
			instructorSelling()
		end)
	end
	
	if instructor and text:find("^ Рабочий день начат$") then
		newTask(function()
			wait(500)
			if closed then runRoute("!play instructor_health_closed") end
			if open then runRoute("!play instructor_health_open") end
		end)
	end
	
	if instructor and text:find("Информация:{FFFFFF} Вы приступили к приему экзамена по вождению у "..studentNick) then
		cancel = true
		
		newTask(function()
			wait(2000)
			sendInput("/givelicense "..studentId)
		end)
	end
	
	if instructor and text:find("Вы завершили урок у {FFFFFF}"..studentNick) then
		counter = counter + 1
		print('Instructor counter = '..counter)
		
		if counter == 16 then
			print('Counter limit! Instructor disconnecting...')
			print("[instructor_contract] Unexpected behavior!")
			exit()
		end
		
		newTask(function()
			wait(2000)
			instructorSelling()
		end)
	end
	
	if instructor and text:find("Игрок должен находиться рядом с вами") then
		print('Student is too far! Instructor disconnecting...')
		print("[instructor_contract] Unexpected behavior!")
		exit()
	end
	
	if instructor and text:find("^ У клиента недостаточно денег$") then
		print('Student has no money! Instructor disconnecting...')
		print("[instructor_contract] Student has no money!")
		exit()
	end
	
	if instructor and text:find("У игрока уже присутствует лицензия на вождение!") then
		print('Student already has a driving license! Instructor disconnecting...')
		print("[instructor_contract] Unexpected behavior!")
		exit()
	end
	
	if instructor and text:find(" Контракт принят%. Для его выполнения:") then
		print("Contract started")
    end
	
    if instructor and text:find("Взять контракт могут только глава семьи и его заместитель") then
		print('You need the rank to take contract! Instructor disconnecting...')
		print("[instructor_contract] Unexpected behavior!")
		exit()
    end
	
	if instructor and text:find('^ Нельзя взять больше %d контрактов$') then
		print('Contract number limit! Instructor disconnecting...')
		print("[instructor_contract] Contract number limit!")
		exit()
	end

	if instructor and text:find('Ваша семья успешно завершила контракт {FFFFFF}"Не оставим без лицензий"{CCCCCC}') then
		completed = true
	end
	
	if instructor and text:find("^ Награда: {32CD32}%$%d+") and completed then
		local reward = text:match("^ Награда: {32CD32}%$(%d+)")
		print('Contract completed. Instructor disconnecting...')
		print('[instructor_contract] Contract completed/'..reward..'$')
		exit()
	end

	--if student and text:find('Ваша семья успешно завершила контракт {FFFFFF}"Не оставим без лицензий"{CCCCCC}') then
	--	print('Contract completed. Student disconnecting...')
	--	--wait
	--	exit()
	--end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
	if instructor and id == 20274 and title:find("Раздевалка") then
		if closed then instructor_locker_closed = false end
		if open then instructor_locker_open = false end
		
		newTask(function()
			wait(1500)
			sendDialogResponse(20274, 1, 0, "")
		end)
		return false
	end
	
	if instructor and cancel and id == 32700 and title:find("Выдача лицензий") then
		cancel = false
		sendDialogResponse(32700, 1, 6, "")
		return false
	elseif instructor and id == 32700 and title:find("Выдача лицензий") then
		sendDialogResponse(32700, 1, 5, "")
		return false
	end
	
	if student and id == 0 and title:find("Правила дорожного движения") then
		sendDialogResponse(0, 0, 0, "")
		return false
	end
	
	if student and id == 32700 and title:find("Покупка лицензий") and text:find(instructorNick) then
		sendDialogResponse(32700, 1, 0, "")
		return false
	elseif student and id == 32700 and title:find("Покупка лицензий") and not text:find(instructorNick) then
		sendDialogResponse(32700, 0, 0, "")
		return false
	end

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
				print("[instructor_contract] Contract already completed")
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

function sampev.onMoveObject(id, _, _, _, rotation)
	if instructor and id == doorObject and instructor_lock_closed then
		print('Door moved! Instructor disconnecting... (instructor_lock_closed)')
		print("[instructor_contract] Door moved!")
		exit()
		
	elseif instructor and id == doorObject and instructor_door_closed and rotation.z == 180 then
		print('Door opened')
		instructor_door_closed = false
		instructor_locker_closed = true
	
		newTask(function()
			wait(1500)
			runRoute("!play instructor_locker_closed")
		end)
		
	elseif instructor and id == doorObject and instructor_locker_closed then
		print('Door moved! Instructor disconnecting... (instructor_locker_closed)')
		print("[instructor_contract] Door moved!")
		exit()

	elseif instructor and id == doorObject and instructor_locker_open then
		print('Door moved! Instructor disconnecting... (instructor_locker_open)')
		print("[instructor_contract] Door moved!")
		exit()
	end
end

function sampev.onShowTextDraw(id, data)
	if data.text == "~b~PRESS: ~w~H" and instructor_lock_closed then
		runRoute("!stop")
		
		newTask(function()
			wait(1000)
			instructor_lock_closed = false
			instructor_door_closed = true
			pressSpecialKey('H')
		end)
	end
end

function sampev.onCreateObject(id, data)
	if instructor and data.modelId == 19859 and data.rotation.z == 90 then
		closed = true
		doorObject = id
		doorRotation = data.rotation.z
		instructor_lock_closed = true
		
		newTask(function()
			wait(2500)
			runRoute("!play instructor_lock_closed")
		end)
	end
	
	if instructor and data.modelId == 19859 and data.rotation.z == 180 then
		open = true
		doorObject = id
		doorRotation = data.rotation.z
		instructor_locker_open = true
		
		newTask(function()
			wait(2500)
			runRoute("!play instructor_locker_open")
		end)
	end
	
	if student and data.modelId == 19859 and (data.rotation.z == 90 or data.rotation.z == 180) then
		doorObject = id
		doorRotation = data.rotation.z
		
		newTask(function()
			wait(2500)
			runRoute("!play student_pdd")
		end)
	end
end

function sampev.onPlayerQuit(playerId, reason)
	if student then
		local nick = (getPlayer(playerId)).nick -- try catch
		if nick == instructorNick then
			print('Instructor disconnected! Student disconnecting...')
			newTask(function()
				wait(20000)
				exit()
			end)
		end
	end
end

function sampev.onPlayerStreamIn(playerId, _, _, position)
	local nickIn = (getPlayer(playerId)).nick
	local myX, myY, myZ = getBotPosition()
	if (instructor or student) and not string.find(table.concat({instructorNick, studentNick}, ","), nickIn) and getDistanceBetweenCoords(position.x, position.y, position.z, myX, myY, myZ) <= 55 and streamIn then
		print('[instructor_contract] [InStream] '..nickIn)
	end
end

function sampev.onSetInterior(interior)
	if (instructor or student) and interior == 10 then
		streamIn = true
	end
end

function sampev.onSetSpawnInfo(_, _, _, position)
	if (instructor or student) and not loginSpawn then
		loginSpawn = true
		
	elseif instructor and loginSpawn then
		newTask(function()
			print('Instructor died/spawned! Disconnecting...')
			print("[instructor_contract] Unexpected behavior!")
			wait(3000)
			exit()
		end)
	elseif student and loginSpawn then
		newTask(function()
			print('Student died/spawned! Disconnecting...')
			print("[instructor_contract] Unexpected behavior!")
			wait(3000)
			exit()
		end)
	end
end

function sampev.onCreatePickup(id, model, pickupType, position)
	local myX, myY, myZ = getBotPosition()
	local distance = getDistanceBetweenCoords(myX, myY, myZ, position.x, position.y, position.z)

	if (instructor or student) and model == 19130 and distance <= 3 and not entdoorPickedUp then
		sendPickedUpPickup(id)
		entdoorPickedUp = true
	end
end