require("addon")
local sampev = require("samp.events")
require("follow_lib")
--autologin

local passenger1Nick, passenger2Nick, driverNick = "Nick_Name", "Nick_Name", "Nick_Name"
local distance = 300

local NORMAL_KEYS = { F = 16 }
					
function pressNormalKey(key)
	if not NORMAL_KEYS[key] then return false end
	normalKey = NORMAL_KEYS[key]
    updateSync()
end

function onConnect()
end

function sampev.onSendSpawn()
	if getBotNick() == passenger1Nick then
		passenger1 = true
		driverId = getPlayerId(driverNick)
		if driverId then followCommand("!follow "..driverId.." 1") end
	end
	
	if getBotNick() == passenger2Nick then
		passenger2 = true
		driverId = getPlayerId(driverNick)
		if driverId then followCommand("!follow "..driverId.." 2") end
	end
	
	if (passenger1 or passenger2) then pressNormalKey('F') end
end

function getDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
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

function checkTraveledDistanceLoop()
	print('Distance checking...')
	while true do
		wait(50)
		local botX, botY, botZ = getBotPosition()
		if getDistanceBetweenCoords(iX, iY, iZ, botX, botY, botZ) >= distance then
			followCommand("!exitveh")
			break
		end
	end
end

function onPrintLog(text)
	if (passenger1 or passenger2) and text:find("Bot enter %d+ vehId as passenger %d") then
		iX, iY, iZ = getBotPosition()
		newTask(checkTraveledDistanceLoop)
	end
end

function sampev.onSendPlayerSync(data)
    if normalKey then
        data.keysData = normalKey
        normalKey = nil
	end
end

function sampev.onServerMessage(color, text)
	
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)	
    if (passenger1 or passenger2) and id == 3008 then
        sendDialogResponse(3008, 1, 0, "")
		return false
    end
	
    if (passenger1 or passenger2) and id == 10075 then
		return false
    end
	
    if passenger1 and id == 32700 and text:find('Как вас обслужили?') then
		sendDialogResponse(32700, 1, 0, "")
		newTask(function()
			wait(550)
			reconnect(16500)
		end)
		return false
    end

    if passenger2 and id == 32700 and text:find('Как вас обслужили?') then
		sendDialogResponse(32700, 1, 0, "")
		newTask(function()
			wait(600)
			reconnect(19500)
		end)
		return false
    end
end