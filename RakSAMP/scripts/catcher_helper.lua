require("addon")
require('route player_lib')
local sampev = require("samp.events")
local json = require ('json')
local autologin = require ('autologin')

if getBotNick() == 'Nick_Name' then
	catcher = true
	autologin.autologin(getBotNick(), 'password', true, false, false)
end

local function printlog(dict)
	local tag = '[catcher_helper] '
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
	local NORMAL_KEYS = { F = 16 }
	if not NORMAL_KEYS[key] then return false end
	normalKey = NORMAL_KEYS[key]
	updateSync()
	updateSync()
end

local function callMenu()
	while not menu_called do
		pressNormalKey('F')
		print('F pressed')
		wait(1000)
	end
	menu_called = false
end

function onConnect()

end

function sampev.onSendPlayerSync(data)
	if AFK_EMULATION then return false end
	
	if normalKey then
        data.keysData = normalKey
        normalKey = nil
    end
end

function sampev.onServerMessage(color, text)
	if catcher and text:find("« Неоплаченное частное имущество {FF0000}не было {269BD8}выставлено на продажу »") then
		newTask(function() reconnect(40*60*1000) end, 1500)
	
	elseif catcher and text:find("« Неоплаченное частное имущество выставлено на продажу »") then
		print('Login to check...')
		newTask(function() sendClickTextdraw(212) end, 3000)
		
	elseif catcher and text:find("Поздравляем с покупкой!") then
		printlog({type = 0, event = 'purchase', attributes = {}})
		autologin.autologin('Nick_Name', 'password', true, 'DEFAULT', false)
		newTask(function() reconnect(15000) end, 1500)
		
	elseif catcher and text:find("Положили на домашний счет") then
		printlog({type = 0, event = 'payment', attributes = {}})
		exit()
	end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
	if catcher and id == 10075 and title:find("Дом занят") then
		print('House occupied')
		sendDialogResponse(10075, 0, 0, "")
		newTask(function() reconnect(40*60*1000) end, 1500)
		return false
		
	elseif catcher and id == 10075 and title:find("Дом свободен") then
		printlog({type = 0, event = 'free', attributes = {}})
		sendDialogResponse(10075, 0, 0, "")
		newTask(function() sendInput("/buyhouse") end, 1500)
		return false
		
	elseif catcher and id == 9100 and title:find("Банкомат") then
		menu_called = true
		sendDialogResponse(9100, 1, 4, "")
		sendDialogResponse(9104, 1, 0, "5000")
	end
end

function sampev.onPlayerStreamIn(playerId, _, _, position)	
	if catcher then
		local nickIn = (getPlayer(playerId)).nick
		print('[StreamIn] '..nickIn)
	end
end

function sampev.onCreateObject(id, data)
	if catcher and data.modelId == 2754 and math.floor(data.position.x) == 2842 and math.floor(data.position.y) == 1281 and math.floor(data.position.z) == 11 then
		newTask(function() runRoute("!play catcher_atm") end, 5000)
	end
end

function sampev.onShowTextDraw(id, data)
	if catcher and data.text == '~b~PRESS: ~w~F'then
		newTask(callMenu)
	end
end