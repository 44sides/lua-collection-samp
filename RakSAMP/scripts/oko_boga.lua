require("addon")
local sampev = require("samp.events")
local json = require ('json')

local function printlog(dict)
	local tag = '[oko_boga] '
	dict['nick'] = getBotNick()
	print(tag..json.encode(dict))
end

local function send()
	local bs = bitStream.new()
	bs:writeUInt8(212)
	bs:writeUInt16(0)
	bs:writeUInt16(0)
	bs:writeUInt16(0)
	bs:writeFloat(432.54400634766)
	bs:writeFloat(-1847.4200439453)
	bs:writeFloat(5.5425300598145)
	return bs:sendPacketEx(HIGH_PRIORITY, UNRELIABLE_SEQUENCED, 1)
end

function onConnect()
	if getBotNick() == 'Nick_Name' then oko = true end
end

function onPrintLog(text)
	if oko and text:find("%[NET%] The connection was lost") then
		print('players = '..getPlayerCount())
	end
end

function sampev.onSendRequestClass()
	if oko then
		newTask(function()
			wait(0)
			for i=1,10 do
				print(send())
			end
		end)
	end
end

function sampev.onSendSpectatorSync(data)
	if oko then
		data.position.x = 432.54400634766
		data.position.y = -1847.4200439453
		data.position.z = 5.5425300598145
	end
end

function sampev.onSetCameraPosition(position)
	if oko then
		print('players = '..getPlayerCount())
	end
end

function sampev.onSetObjectMaterialText(id, data)
	if oko then
		if data.text == "Evolve {000000}RP" then
			printlog({type = 1, event = 'stop', attributes = {}})
		end
		
		if data.fontName == 'Quartz MS' then
			printlog({type = 0, event = 'set_text', attributes = {text = data.text}})
		end
	end
end