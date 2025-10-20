require("lib.moonloader")
samp = require("lib.samp.events")

local DELAY = 2500

function auto_activation()
	autorent = not autorent
	
	if autorent then 
		sampAddChatMessage('Автоаренду активовано ('..DELAY..'мс)', 0x4dff00)
	else
		sampAddChatMessage('Автоаренду деактивовано', 0x4dff00)
	end
end

function main()
	while not isSampAvailable() do wait(100) end
	
	sampRegisterChatCommand("lavka", auto_activation)
	
    while true do
        wait(0)
    end
end

function pressNormalKey(key)
	local NORMAL_KEYS = { ALT = 1024 }
	if not NORMAL_KEYS[key] then return false end
	normalKey = NORMAL_KEYS[key]
    sampForceOnfootSync()
	sampForceOnfootSync()
end

function samp.onSendPlayerSync(data)
    if normalKey then
        data.keysData = normalKey
        normalKey = nil
    end
end

function samp.onSetObjectMaterialText(id, data)
	local obj = sampGetObjectHandleBySampId(id)
	
	if getObjectModel(obj) == 18659 and data.text:find("Доступен") then
		local _, objX, objY, objZ = getObjectCoordinates(obj)
		local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
		
		sampAddChatMessage('Знайдена вільна лавка!', 0x4dff00)
		addOneOffSound(0.0, 0.0, 0.0, 1138)
		obj_blip = addBlipForObject(obj)
		changeBlipColour(obj_blip, 0x00FF00FF)
		
		if getDistanceBetweenCoords3d(objX, objY, objZ, myX, myY, myZ) < 3 and autorent then
			sampAddChatMessage('Автоменю...', 0x4dff00)
			lua_thread.create(pressNormalKey, 'ALT')
		end
	end
end

function samp.onShowDialog(id, style, title, btn1, btn2, text)
	if id == 32700 and title:find("Аренда") and text:find("{AFAFAF}0%$") and autorent then
		sampAddChatMessage('Автоаренда... ('..DELAY..'мс)', 0x4dff00)
		autolavka_thread = lua_thread.create(autolavka, DELAY)
	end
end

function samp.onSendDialogResponse(id, button, list, input)
	if id == 32700 and sampGetDialogCaption():find("Аренда") and autorent then
		autorent = false
		sampAddChatMessage('Автоаренду скасовано', 0xf50404)
	end
end

function autolavka(delay)
	wait(delay)

	if autorent then
		sampSendDialogResponse(32700, 1, 0, nil)
		sampSendDialogResponse(32700, 1, 0, '10')
			
		sampSendDialogResponse(32700, 1, 1, nil)
		sampSendDialogResponse(32700, 1, 0, '5')
			
		sampSendDialogResponse(32700, 1, 2, nil)
		sampSendDialogResponse(32700, 1, 0, '24')
			
		sampSendDialogResponse(32700, 1, 4, nil)
		sampSendDialogResponse(32700, 1, 0, nil)
	end
end