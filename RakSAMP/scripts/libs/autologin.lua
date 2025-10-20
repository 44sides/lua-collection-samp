require('addon')
local utils = require("samp.events.utils")

-- 210 family, 212 exit, 214 default, 208 house

local a = {}

function a.autologin(nick, password, autologin, autospawn, autotreatment)
	a[nick] = {password = password, autologin = autologin, autospawn = autospawn, autotreatment = autotreatment}
	return true
end

local function pressNormalKey(key)
	local NORMAL_KEYS = { ALT = 1024 }
	if not NORMAL_KEYS[key] then
		return false
	end
	normalKey = NORMAL_KEYS[key]
    updateSync()
end

registerHandler("onSendPacket", function(id, bs)
	if id == PACKET_PLAYER_SYNC then
		if normalKey then
			local data = (utils.process_outcoming_sync_data(bs, 'PlayerSyncData'))[1]
			data.keysData = normalKey
			normalKey = nil
		end
	end
end)

registerHandler("onReceiveRPC", function(id, bs)
	if id == 61 and a[getBotNick()] then
		local id, _ = bs:readInt16(), bs:ignoreBits(8)
		local title = bs:readString(bs:readUInt8())
		
		if id == 32700 and title:find("Ввод пароля") and a[getBotNick()].autologin then
			print('Autologin...')
			pickspawn = true
			sendDialogResponse(32700, 1, -1, a[getBotNick()].password)
			return false
		end
		
		if id == 6700 and title:find("Дом") and a[getBotNick()].autotreatment and treatment then
			sendDialogResponse(6700, 1, 1, "")
			return false
		end
	end
end)

registerHandler("onReceiveRPC", function(id, bs)
	if id == 134 and a[getBotNick()] then
		local id = bs:readUInt16()
		
		if pickspawn then
			--setBotPosition(0, 0, 0)
			if id == 210 and a[getBotNick()].autotreatment and getBotHealth() <= 40 then
				print('Spawn to family to treat...')
				newTask(function() sendClickTextdraw(210) end, 3000)
				treatment = true
			elseif id == 210 and a[getBotNick()].autospawn == 'FAMILY' and not treatment then
				print('Spawn to family...')
				newTask(function() sendClickTextdraw(210) end, 3000)
				pickspawn = false
			elseif id == 212 and a[getBotNick()].autospawn == 'EXIT' and not treatment then
				print('Spawn to exit...')
				newTask(function() sendClickTextdraw(212) end, 3000)
				pickspawn = false
			elseif id == 214 and a[getBotNick()].autospawn == 'DEFAULT' and not treatment then
				print('Spawn to default...')
				newTask(function() sendClickTextdraw(214) end, 3000)
				pickspawn = false
			end
		end
	end
end)

registerHandler("onReceiveRPC", function(id, bs)
	if id == 93 and a[getBotNick()] then
		local _, text = bs:ignoreBits(32), bs:readString(bs:readUInt32())
		
		if text:find("^ Вы ввели неверный пароль! Осталось попыток:") and a[getBotNick()].autologin then
			a[getBotNick()].autologin = false
		end
		
		if (text:find("^ Вы были вылечены на 25 процентов") or text:find("^ Вы здоровы")) and a[getBotNick()].autotreatment and treatment then
			if getBotHealth() < 90 then
				pressNormalKey('ALT')
			else
				print('Treatment completed. Reconnecting...')
				treatment = false
				reconnect(3000)
			end
		elseif text:find("^ В этом месте нет аптечек") and a[getBotNick()].autotreatment and treatment then
			print('No kits! Reconnecting...')
			treatment = false
			a[getBotNick()].autotreatment = false
			reconnect(3000)
		end
	end
end)

registerHandler("onReceiveRPC", function(id, bs)
	if id == 68 and a[getBotNick()] then
		local _, position = bs:ignoreBits(48), bs:readVector3()
		
		if a[getBotNick()].autotreatment and treatment then
			newTask(function() pressNormalKey('ALT') end, 3000)
		end
	end
end)

return a