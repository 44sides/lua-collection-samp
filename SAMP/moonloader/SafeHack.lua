script_name('SAFE Hacker')
script_author('Vlad')
script_description("Brute force password hacking")
script_version("v0.12") 

require("lib.moonloader")
samp = require("lib.samp.events")
vkeys = require('vkeys')
rkeys = require('rkeys')
inicfg = require('inicfg')

function isStringDigits(str)
    for i = 1, #str do
        if not tonumber(str:sub(i, i)) then
            return false
        end
    end
    return true
end

cfg = {}
cfg['SafeHack'] = inicfg.load({
	delays = {
		digit_delay = 100,
		safe_delay = 700
	}
}, "..\\config\\SafeHack.ini")

function saveIni()
	local saved = inicfg.save(cfg['SafeHack'], string.format('..\\config\\SafeHack.ini'))
    if saved then
        return saved
    end
end

filepath = ".\\moonloader\\config\\SafeHackCodes.ini"
file = io.open(filepath, "r")
if not file then
    file = io.open(filepath, "w")
    file:close()
    file = io.open(filepath, "r")
end

local lines = {}
for line in file:lines() do
	if #line == 4 and isStringDigits(line) then
		table.insert(lines, line)
	end
end

file:close()

local pw_set = lines

local tdindex = nil
local DIGIT_DELAY = cfg['SafeHack'].delays.digit_delay
local SAFE_DELAY = cfg['SafeHack'].delays.safe_delay

function state_clean()
	state = nil
	start, range = false, false
	pw = {0, 0, 0, 0}
	to = 0
	pw_ind = 0
end

state_clean()

function stringToIntArray(str)
    local t = {}
    for i = 1, #str do
		t[i] = tonumber(str:sub(i, i))
    end
	return t
end

function areArraysEqual(arr1, arr2)
    for i = 1, 4 do
        if arr1[i] ~= arr2[i] then
            return false
        end
    end
	return true
end

function pwIncrementation(arr)
	arr[4] = arr[4] + 1
	if arr[4] == 10 then arr[4] = 0 arr[3] = arr[3] + 1 end
	if arr[3] == 10 then arr[3] = 0 arr[2] = arr[2] + 1 end
	if arr[2] == 10 then arr[2] = 0 arr[1] = arr[1] + 1 end
	return arr
end

function pwNext()
	pw_ind = pw_ind + 1
	if pw_ind > #pw_set then 
		return false
	else
		local pw = stringToIntArray(pw_set[pw_ind])
		return pw
	end
end

function hack_deactivation()
	if start then
		start = false
		sampAddChatMessage("[SafeHack] Start деактивовано", 0xD78E10)
		state = 'start'
		return
	end
	if range then
		range = false
		sampAddChatMessage("[SafeHack] Range деактивовано", 0xD78E10)
		state = 'range'
		return
	end
	
	if state == 'start' then
		start = true
		sampAddChatMessage("[SafeHack] Start активовано", 0xD78E10)
		return
	end
	if state == 'range' then
		range = true
		sampAddChatMessage("[SafeHack] Range активовано", 0xD78E10)
		return
	end
end

function main()
	while not isSampAvailable() do wait(100) end
	
	sampAddChatMessage("[SafeHack] /safehack", 0xD78E10)
	
	deactivationRegId = rkeys.registerHotKey({vkeys.VK_LCONTROL, vkeys.VK_H}, 1, hack_deactivation)
	
    while true do
        wait(0)
    end
end

hacking = lua_thread.create_suspended(
	function()
		for _, digit in ipairs(pw) do
			wait(DIGIT_DELAY)
			if digit == 0 then sampSendClickTextdraw(tdindex + 11) else sampSendClickTextdraw(tdindex + digit) end
		end
		
		wait(SAFE_DELAY)
		sampSendChat("/safe")
		ok_pressing:terminate()
	end)

ok_pressing = lua_thread.create_suspended(function() wait(DIGIT_DELAY) sampSendClickTextdraw(tdindex + 12) end)

function samp.onShowTextDraw(id, data)
    if (range or start) and (data.text == 'HOUSE' or data.text == 'VEHICLE' or data.text == 'BOAT' or data.text == 'HOTEL') then
		tdindex = id + 86
		hacking:run()
    end
	
	--number confirmation
	if (range or start) and (#data.text == 4 and data.text == table.concat(pw)) then
		ok_pressing:run()
	end
end

function samp.onServerMessage(color, text)
	if range and text == (' Пин-код не совпал') then
		printStyledString("~r~"..table.concat(pw), 1500, 7)
		local lastpw = table.concat(pw)
		pw = pwIncrementation(pw)
		if areArraysEqual(pw, to) then sampAddChatMessage("[SafeHack] Цикл закінчено на "..lastpw, 0xD78E10) state_clean() end
	end
	if start and text == (' Пин-код не совпал') then
		printStyledString("~r~"..table.concat(pw), 1500, 7)
		local lastpw = table.concat(pw)
		pw = pwNext()
		if not pw then sampAddChatMessage("[SafeHack] Цикл закінчено на "..lastpw, 0xD78E10) state_clean() end
	end
	
    if (range or start) and text == (' [Загрузка] Сейф открывается..') then
		printStyledString("~g~"..table.concat(pw), 30000, 7)
		sampAddChatMessage("[SafeHack] Код — "..table.concat(pw), 0xD78E10) state_clean()
    end
	
	--flood recovery
	if (range or start) and text == (' Не флуди!') then
		lua_thread.create(function() hacking:terminate() wait(SAFE_DELAY) sampSendChat("/safe") end)
	end
	
	if (range or start) and text == (' Пин-код не совпал') then return false end
	if (range or start) and text == (' Для быстрого взятия используйте: /safe [параметр] [количество]') then return false end
	if (range or start) and text == (' Доступные параметры: sd, de, sh, sm, ak, m4, ri, rem, skin, material, drug, key, fish, synt') then return false end
end

function samp.onSendCommand(command)
	if command:match("^/safehack$") then
		sampAddChatMessage("[SafeHack] /safehack start, /safehack <від> <до>, /safehack digit <затримка>, /safehack safe <затримка>", 0xD78E10)
	end

	if command:match("^/safehack start$") then
		state_clean()
		start = true range = false
		pw = pwNext()
		sampAddChatMessage("[SafeHack] Start активовано. Введіть /safe", 0xD78E10)
		if not pw then state_clean() sampAddChatMessage("[SafeHack] Цикл закінчено", 0xD78E10) end
	end
	
	local from_str, to_str = command:match("^/safehack (%d%d%d%d) (%d%d%d%d)$")
	if from_str and to_str then
		if from_str <= to_str then
			state_clean()
			range = true start = false
			pw = stringToIntArray(from_str)
			to = pwIncrementation(stringToIntArray(to_str))
			sampAddChatMessage("[SafeHack] Range "..from_str.."-"..to_str.." активовано. Введіть /safe", 0xD78E10)
		else
			sampAddChatMessage("[SafeHack] "..from_str.." > "..to_str, 0xD78E10)
		end
	end
	
	if command:match("^/safehack status$") then
		sampAddChatMessage("[SafeHack] Наступний код у черзі — "..table.concat(pw), 0xD78E10)
	end
	
	local digit_config = command:match("^/safehack digit (%d+)$")
	if digit_config then
		DIGIT_DELAY = tonumber(digit_config)
		cfg['SafeHack'].delays.digit_delay = tonumber(digit_config)
		sampAddChatMessage("[SafeHack] Затримка між цифрами "..DIGIT_DELAY.."мс", 0xD78E10)
	end
	local safe_config = command:match("^/safehack safe (%d+)$")
	if safe_config then
		SAFE_DELAY = tonumber(safe_config)
		cfg['SafeHack'].delays.safe_delay = tonumber(safe_config)
		sampAddChatMessage("[SafeHack] Затримка між вводу /safe "..SAFE_DELAY.."мс", 0xD78E10)
	end
end

function onScriptTerminate(script, bool)
	if script == thisScript() then
		if saveIni() then print("Settings has been saved.") end
	end
end