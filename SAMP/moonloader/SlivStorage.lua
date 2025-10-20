script_name('Sliv Storage')
script_author('Vlad')
script_description("Fast take from Storage and put in trunk")
script_version("v0.1") 

require("lib.moonloader")
samp = require("lib.samp.events")
vkeys = require('vkeys')
rkeys = require('rkeys')
inicfg = require('inicfg')
ffi = require('ffi')

local delay_command = 1000
local delay_put = 0

cfg = {}
cfg['SlivStorage'] = inicfg.load({
	take = {
		['Deagle'] = false,
		['SDPistol'] = false,
		['M4'] = true,
		['AK47'] = false,
		['ShotGun'] = false,
		['MP5'] = false,
		['Rifle'] = false,
		['Армейская форма'] = false,
		['Растительные наркотики'] = false,
		['Ключ от КПЗ'] = false,
		['Синтетические наркотики'] = false,
		['Готовая Рыба'] = false,
		['Ремонтный комплект'] = false,
		['Материалы'] = false
	},
	put = {
		['Deagle'] = false,
		['SDPistol'] = false,
		['M4'] = true,
		['AK47'] = false,
		['ShotGun'] = false,
		['MP5'] = false,
		['Rifle'] = false,
		['Армейская форма'] = false,
		['Растительные наркотики'] = false,
		['Ключ от КПЗ'] = false,
		['Синтетические наркотики'] = false,
		['Готовая Рыба'] = false,
		['Ремонтный комплект'] = false,
		['Материалы'] = false
	}
}, "..\\config\\SlivStorage.ini")

local itemsTake = cfg['SlivStorage'].take
local itemsPut = cfg['SlivStorage'].put

-- Item names from /inv, Weapon names from /trunk
local items = { 'Deagle', 'SDPistol', 'M4', 'AK47', 'ShotGun', 'MP5', 'Rifle', 'Армейская форма', 'Растительные наркотики', 'Ключ от КПЗ',
				'Синтетические наркотики', 'Готовая Рыба', 'Ремонтный комплект', 'Материалы' } -- safe ordered
local itemToTrunkItem = { ['SDPistol'] = 'SDPistol', ['Deagle'] = 'Deagle', ['ShotGun'] = 'ShotGun', ['MP5'] = 'MP5', ['AK47'] = 'AK47', ['M4'] = 'M4', ['Rifle'] = 'Rifle',
						['Растительные наркотики'] = 'Растительные наркотики', ['Материалы'] = 'Материалы', ['Ключ от КПЗ'] = 'Ключи', ['Ремонтный комплект'] = 'Рем. комплекты',
						['Армейская форма'] = 'Форма', ['Готовая Рыба'] = 'Рыба', ['Синтетические наркотики'] = 'Синтетические наркотики' }
local itemToShort = { ['SDPistol'] = 'sd', ['Deagle'] = 'de', ['ShotGun'] = 'sh', ['MP5'] = 'sm', ['AK47'] = 'ak', ['M4'] = 'm4', ['Rifle'] = 'ri',
						['Растительные наркотики'] = 'drug', ['Материалы'] = 'material', ['Ключ от КПЗ'] = 'key', ['Ремонтный комплект'] = 'rem',
						['Армейская форма'] = 'skin', ['Готовая Рыба'] = 'fish', ['Синтетические наркотики'] = 'synt' }
local idToWeapon = { [23] = 'SDPistol', [24] = 'Deagle', [25] = 'ShotGun', [29] = 'MP5', [30] = 'AK47', [31] = 'M4', [33] = 'Rifle' }
local itemtoTrunkEmptyNum = { ['SDPistol'] = 1, ['Deagle'] = 2, ['ShotGun'] = 3, ['MP5'] = 4, ['AK47'] = 5, ['M4'] = 6, ['Rifle'] = 7,
						['Растительные наркотики'] = 8, ['Материалы'] = 9, ['Ключ от КПЗ'] = 13, ['Ремонтный комплект'] = 14, ['Армейская форма'] = 15,
						['Готовая Рыба'] = 16, ['Синтетические наркотики'] = 22 }
local itemToTrunkSize = { ['SDPistol'] = 300, ['Deagle'] = 300, ['ShotGun'] = 300, ['MP5'] = 300, ['AK47'] = 300, ['M4'] = 300, ['Rifle'] = 300,
						['Растительные наркотики'] = 250, ['Материалы'] = 500, ['Ключ от КПЗ'] = 25, ['Ремонтный комплект'] = 5, ['Армейская форма'] = 5,
						['Готовая Рыба'] = 50, ['Синтетические наркотики'] = 250 }
local itemToSafeSize = { ['SDPistol'] = 100, ['Deagle'] = 100, ['ShotGun'] = 40, ['MP5'] = 200, ['AK47'] = 200, ['M4'] = 200, ['Rifle'] = 40,
						['Растительные наркотики'] = 150, ['Материалы'] = 500, ['Ключ от КПЗ'] = 25, ['Ремонтный комплект'] = 5, ['Армейская форма'] = 2,
						['Готовая Рыба'] = 25, ['Синтетические наркотики'] = 150 }
				
local tItems = {}
local dSafe = {}

function rkeys.onHotKey(id, keys)
    if isPauseMenuActive() or isSampfuncsConsoleActive() or sampIsChatInputActive() or sampIsDialogActive() then
        return false
    end
end

function msgChat(text, color)
    sampAddChatMessage('[SlivStorage] '..text, color)
end

function getAllPickups()
    local pu = {}
    pPu = sampGetPickupPoolPtr() + 16388
    for i = 0, 4095 do
        local id = readMemory(pPu + 4 * i, 4)
        if id ~= -1 then
            table.insert(pu, sampGetPickupHandleBySampId(i))
        end
    end
    return pu
end

function getPickupModel(id)
    local PICKUP_POOL = sampGetPickupPoolPtr()
    return ffi.cast("int *", (id * 20 + 61444) + PICKUP_POOL)[0]
end

-- @return int index
-- @return false
function isValueInArray(array, value)
	for i, elem in ipairs(array) do
		if elem == value then
			return i
		end
	end
	return false
end

-- @return int size
function DictionarySize(dictionary)
    local size = 0
    for k, v in pairs(dictionary) do
        size = size + 1
    end
    return size
end

-- @return table
function mergeTables(x, y)
	local z = {}
	local n = 0
	for _,v in ipairs(x) do n=n+1; z[n]=v end
	for _,v in ipairs(y) do n=n+1; z[n]=v end
	return z
end

-- @return iterator
function createArrayIterator(arr)
	local iterator = {}
    local i = 0

    function iterator.next()
        i = i + 1
        if arr[i] then
            return arr[i], i
        end
    end

    function iterator.decreaseAmmo(number)
		local ammo = arr[i][2]
        if arr[i] and ammo then
            arr[i][2] = ammo - number
        end
    end

    return iterator
end

-- @return str[][] table, int rows, int cols, [str[] header]
function dialogToTable(header, dialog)
	local t, h = {}, nil
	
	for line in dialog:gmatch('[^\n]+') do
		t[#t+1] = {}
		for column in line:gmatch('[^%c]+') do
			table.insert(t[#t], column)
		end
	end

	if header then h = t[1] table.remove(t, 1) end
	
	return t, #t, #t[1], h
end

-- @return int num
-- @return nil
function AvailableSlotTrunk(tTrunk, item)
	local trunkItem = itemToTrunkItem[item]
	
	for n, row in ipairs(tTrunk) do
		if row[1] == trunkItem and tonumber(row[2]) < itemToTrunkSize[item] then
			return n
		end
	end
	
	for n, row in ipairs(tTrunk) do
		if row[1] == 'Пусто' then
			return n
		end
	end
	
	return nil
end

-- @return bool
function ifWeaponPut()
	if itemsPut['Deagle'] or itemsPut['SDPistol'] or itemsPut['M4'] or itemsPut['AK47'] or itemsPut['ShotGun'] or
	   itemsPut['MP5'] or itemsPut['Rifle'] then
		return true
	else
		return false
	end
end

-- @return bool
function ifInvPut()
	if itemsPut['Армейская форма'] or itemsPut['Растительные наркотики'] or itemsPut['Ключ от КПЗ'] or itemsPut['Синтетические наркотики'] or
	   itemsPut['Готовая Рыба'] or itemsPut['Ремонтный комплект'] or itemsPut['Материалы'] then
		return true
	else
		return false
	end
end

-- @return refilled tItems
function getAllWeapons()
    for i = 0, 12 do
        local id, ammo, _ = getCharWeaponInSlot(PLAYER_PED, i)
        if id >= 1 and id <= 46 and ammo > 0 then
			tItems[#tItems + 1] = {}
			table.insert(tItems[#tItems], idToWeapon[id])
			table.insert(tItems[#tItems], ammo)
        end
    end
end

-- @return refilled tItems
function getAllInv()
	inv = true
	sampSendChat("/inv")
end

-- @return filled tItems
function getAllItems()
	if ifWeaponPut() then
		getAllWeapons()
	end
	
	if ifInvPut() then
		getAllInv()
	else
		itemsReform()
		itemIterator = createArrayIterator(tItems)
		item, i = itemIterator.next()
		first_iteration = true
		sampSendChat("/trunk")
	end
end

-- @return reformed tItems
function itemsReform()
	for i = #tItems, 1, -1 do
		if not isValueInArray(items, tItems[i][1]) or not itemsPut[tItems[i][1]] then
			table.remove(tItems, i)
		else
			tItems[i][2] = tonumber(tItems[i][2])
		end
	end
end

-- @return reformed dSafe
function safeReform()
	for k, _ in pairs(dSafe) do
		if itemsTake[k] then
			dSafe[k] = tonumber(dSafe[k])
		else
			dSafe[k] = nil
		end
	end
end

function takeSafe()
	for k, v in pairs(dSafe) do
		wait(delay_command)
		sampSendChat("/safe "..itemToShort[k].." "..itemToSafeSize[k]) -- берет максимум
	end
end

function sendPickup(model)
	if slivpd then
		for i, h in ipairs(getAllPickups()) do
			local id = sampGetPickupSampIdByHandle(h)
			local pX, pY, pZ = getPickupCoordinates(h)
			local X, Y, Z = getCharCoordinates(PLAYER_PED)
			if getPickupModel(id) == 353 and getDistanceBetweenCoords3d(pX, pY, pZ, X, Y, Z) <= 15 then
				sampSendPickedUpPickup(id)
				break
			end
		end
	end
end

function safe_activation()
	safe = true
	sampSendChat("/safe")
	printStringNow("~g~~h~~h~Safe ~w~activated ~u~", 1500)
end

function safe_deactivation(code)
	if code == 0 then end
	safe = false
end

function trunk_activation()
	if slivpd then
		trunk = true
		--setCurrentCharWeapon(PLAYER_PED, 0)
		getAllItems()
		printStringNow("~g~~h~~h~Trunk ~w~activated ~d~", 1500)
	end
end

function trunk_deactivation(code)
	if code == 0 then end
	if code == 200 then end
	if code == 300 then end
	if code == 400 then end
	if code == 500 then msgChat("Нічого покласти", 0x9ACD32) end 
	trunk = false
	tItems = {}
	itemIterator = nil
end

function slivpd_activation()
	slivpd = not slivpd
	dialogClose = 0
	if slivpd then msgChat("SlivPD активовано", 0x9ACD32) else msgChat("SlivPD деактивовано", 0x9ACD32) end
end

function slivpd_deactivation(code)
	if code == 0 then end
	slivpd = false
end

function trunkhand_activation()
	trunkhand = not trunkhand
	if trunkhand then msgChat("trunkhand активовано", 0x9ACD32) else msgChat("trunkhand деактивовано", 0x9ACD32) end
end

function main()
	while not isSampAvailable() do wait(100) end
	
	msgChat("/slivpd /trunkhand {228B22}"..thisScript().version, 0x9ACD32)
	
	sampRegisterChatCommand("slivpd", slivpd_activation)
	sampRegisterChatCommand("trunkhand", trunkhand_activation)
	
	activationRegId = rkeys.registerHotKey({vkeys.VK_4}, 1, sendPickup)
	activationRegId = rkeys.registerHotKey({vkeys.VK_5}, 1, trunk_activation)
	
	--activationRegId = rkeys.registerHotKey({vkeys.VK_2}, 1, safe_activation)
	--activationRegId = rkeys.registerHotKey({vkeys.VK_5}, 1, function() safeReform() for key, value in pairs(dSafe) do print(key, value) end end)
	
    while true do
        wait(0)
		--if safe then sampToggleCursor(false) end
    end
end

function samp.onShowDialog(id, style, title, button1, button2, text)
	if trunkhand and id == 32700 and title:find("Багажник | {ae433d}Слоты") then
		local tTrunk = dialogToTable(true, text)
		lua_thread.create(
			function()
				for i, v in ipairs(tTrunk) do
					if v[1] ~= "Пусто" then
						wait(500)
						sampSendDialogResponse(32700, 1, i - 1, nil)
						sampSendDialogResponse(32700, 1, 1, nil)
						sampSendDialogResponse(32700, 1, nil, v[2])
						return
					end
				end
				trunkhand_activation()
			end)
	end

	if inv and id == 20255 and title:find("Инвентарь | {ae433d}") then
		local tInv = dialogToTable(true, text)
		tItems = mergeTables(tItems, tInv)
		inv = false
		sampSendDialogResponse(20255, 0, nil, nil)
		
		if trunk then 
			lua_thread.create(
				function()
					itemsReform()
					itemIterator = createArrayIterator(tItems)
					item, i = itemIterator.next()
					first_iteration = true
					wait(delay_command)
					sampSendChat("/trunk")
				end)
		end
		
		return false
	end

	if trunk and id == 32700 then
	
		if title:find("Багажник | {ae433d}Слоты") then
			lua_thread.create(
				function()
					if not first_iteration then wait(delay_put) end

::NextItem::
					if item then
						local tTrunk = dialogToTable(true, text)
						local slot = AvailableSlotTrunk(tTrunk, item[1])
						if slot then
							if tTrunk[slot][1] == "Пусто" then
								local limit = itemToTrunkSize[item[1]]
								local quantity = limit  if item[2] < limit then quantity = item[2] end
								sampSendDialogResponse(32700, 1, slot - 1, nil)
								sampSendDialogResponse(32700, 1, itemtoTrunkEmptyNum[item[1]] - 1, nil)
								sampSendDialogResponse(32700, 1, nil, quantity)
								itemIterator.decreaseAmmo(quantity)
								if item[2] == 0 then item, i = itemIterator.next() end
							else
								local limit = itemToTrunkSize[item[1]] - tTrunk[slot][2]
								local quantity = limit  if item[2] < limit then quantity = item[2] end
								sampSendDialogResponse(32700, 1, slot - 1, nil)
								sampSendDialogResponse(32700, 1, 0, nil)
								sampSendDialogResponse(32700, 1, nil, quantity)
								itemIterator.decreaseAmmo(quantity)
								if item[2] == 0 then item, i = itemIterator.next() end
							end
						else
							msgChat("Немає місця для {729629}"..item[1], 0x9ACD32)
							item, i = itemIterator.next()
							goto NextItem
						end
					else
						if first_iteration then trunk_deactivation(500) else trunk_deactivation(0) end
						sampSendDialogResponse(32700, 0, nil, nil)
					end
					
					if first_iteration then first_iteration = false end
				end)
		end
		
		return false
	end
	
	if slivpd and dialogClose == 0 and id == 20057 and title:find("Выбор оружия | {ae433d}Оружейная комната") then
		if itemsTake['Deagle'] then sampSendDialogResponse(20057, 1, 0, nil) dialogClose = dialogClose + 1 end
		if itemsTake['ShotGun'] then sampSendDialogResponse(20057, 1, 1, nil) dialogClose = dialogClose + 1 end
		if itemsTake['MP5'] then sampSendDialogResponse(20057, 1, 2, nil) dialogClose = dialogClose + 1 end
		if itemsTake['M4'] then sampSendDialogResponse(20057, 1, 3, nil) dialogClose = dialogClose + 1 end
		if itemsTake['Rifle'] then sampSendDialogResponse(20057, 1, 4, nil) dialogClose = dialogClose + 1 end
		sampSendDialogResponse(20057, 0, nil, nil)
		return false
	elseif slivpd and dialogClose ~= 0 and id == 20057 and title:find("Выбор оружия | {ae433d}Оружейная комната") then
		dialogClose = dialogClose - 1
		return false
	end

	if slivpd and id == 8242 and title:find("Лифт") then
		if getActiveInterior() == 21 then sampSendDialogResponse(8242, 1, 3, nil)
		elseif getActiveInterior() == 0 then sampSendDialogResponse(8242, 1, 2, nil) end
		return false
	end
end

function samp.onShowTextDraw(id, data)
	if safe and data.text == 'HOUSE' or data.text == 'VEHICLE' then
		if DictionarySize(dSafe) ~= 0 then dSafe = {} end
	end
	
	local ammo = data.text:match("(%d+)/%d+")
	if safe and ammo then
		local length = DictionarySize(dSafe)
		dSafe[items[length + 1]] = ammo
		if length + 1 == #items then
			safe_deactivation(0)
			sampSendClickTextdraw(65535)
			safeReform()
			lua_thread.create(takeSafe)
		end
    end
end

function samp.onServerMessage(color, text)
	if trunk and (text:find("^ У вас нет с собой") or text:find("^ У вас нет столько патронов")) then
		trunk_deactivation(200)
	end
	
	if trunk and text == " Не флуди!" then
		trunk_deactivation(300)
	end
	
	if trunk and text == " Вы должны находиться возле багажника доступного транспорта" then
		trunk_deactivation(400)
	end
	
	if safe and text == (' Для быстрого взятия введите: /safe [параметр] [количество]') then return false end
	if safe and text == (' Доступные параметры: sd, de, sh, sm, ak, m4, ri, rem, skin, material, drug, key, fish, synt') then return false end
end

function samp.onSendCommand(command)
	if command:match("^/slivpd$") then
		slivpd_activation()
	end
end

function saveIni()
	local saved = inicfg.save(cfg['SlivStorage'], string.format('..\\config\\SlivStorage.ini'))
    if saved then
        return saved
    end
end

function onScriptTerminate(name, bool)
	if  name == thisScript() then
		if saveIni() then print("Settings has been saved.") end
	end
end