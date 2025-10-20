require ('lib.moonloader')
local samp = require('lib.samp.events')
local http = require('copas.http')
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8

local token = ''
local lavkas = {'Nick_Name', 'Nick_Name', 'Nick_Name'}

local server_url = "http://127.0.0.1:5000"
local timezone = 3 - os.date("%z") / 100
local items = {}
local tape_prompt = "Натисніть {ee6c4d}O{6fa8dc}, щоб надіслати стрічку"

function send_mykolaj_message(path, dict)
	local data = encodeJson(dict)
	local response_data = {}
	
    local body, code, headers, status = http.request {
		method = "POST",
        url = server_url..path,
        headers = {
			["Content-Type"] = "application/json",
			['Content-Length'] = data:len()
        },
		source = ltn12.source.string(data),
        sink = ltn12.sink.table(response_data)
    }
	
	sampAddChatMessage(status, 0xFFFF00)

	local response = table.concat(response_data)
	
	print(response:sub(1, -2))
end

function items_notification(nick)	
	local message = ''
	
	for k, v in pairs(items) do
		message = message.."\u{1F3F7}\u{FE0F}  "..u8("Ваш предмет "..k.." в количестве "..v[1].." ед. был выкуплен за "..v[2].."$ покупателем\n")
		items[k] = nil
	end
	
	lua_thread.create(send_mykolaj_message, '/send_lavka_message', {message = message, nick = nick, token = token})
end

function show_delayed_prompt(prompt, color)
	wait(1000)
	sampAddChatMessage(prompt, color)
	wait(60000)
	items = {}
end

function ifNickInLavkas(nick)
	for _, v in ipairs(lavkas) do
		if nick == v then
			return true
		end
	end
	return false
end

function main()
	while not isSampAvailable() do wait(100) end
	
	while true do
		wait(0)
		
		if next(items) and isKeyJustPressed(VK_O) and not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() then
			lua_thread.create(items_notification, sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))))
		end
	end
end

function samp.onShowDialog(id, style, title, btn1, btn2, text)
	local nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
	if id == 32700 and title:find("Прилавок | {AE433D}Продление аренды") and ifNickInLavkas(nick) then
		local H, M, d, m, Y = text:match("(%d%d):(%d%d) (%d%d)%.(%d%d)%.(%d%d%d%d)")
		end_ts = os.time({year = Y, month = m, day = d, hour = H - timezone, min = M, sec = 0})
	end
end

function samp.onServerMessage(color, text)
	local nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
	if ifNickInLavkas(nick) then
		if text:find("^ [%[Offline%-info%]: ]?.+Ваша одежда {AE433D}.+ .+ выкуплена за {33AA33}%d+%$") then
			print(text)
			local amount = 1
			local item, price = text:match("Ваша одежда {AE433D}(.+) .+ выкуплена за {33AA33}(%d+)%$")
			items[item] = {(items[item] and items[item][1] or 0) + tonumber(amount), (items[item] and items[item][2] or 0) + tonumber(price)}
			if prompt_thread then prompt_thread:terminate() end
			prompt_thread = lua_thread.create(show_delayed_prompt, tape_prompt, 0x6fa8dc)
			
		elseif text:find("^ [%[Offline%-info%]: ]?.+Ваш асессуар {AE433D}.+ .+ выкуплен за {33AA33}%d+%$") then
			print(text)
			local amount = 1
			local item, price = text:match("Ваш асессуар {AE433D}(.+) .+ выкуплен за {33AA33}(%d+)%$")
			items[item] = {(items[item] and items[item][1] or 0) + tonumber(amount), (items[item] and items[item][2] or 0) + tonumber(price)}
			if prompt_thread then prompt_thread:terminate() end
			prompt_thread = lua_thread.create(show_delayed_prompt, tape_prompt, 0x6fa8dc)
				
		elseif text:find("^ [%[Offline%-info%]: ]?.+Ваш предмет {AE433D}.+ .+в количестве {AE433D}%d+ ед%. .+ выкуплен за {33AA33}%d+%$") then
			print(text)
			local item, amount, price = text:match("Ваш предмет {AE433D}(.+) .+в количестве {AE433D}(%d+) ед%. .+ выкуплен за {33AA33}(%d+)%$")
			items[item] = {(items[item] and items[item][1] or 0) + tonumber(amount), (items[item] and items[item][2] or 0) + tonumber(price)}
			if prompt_thread then prompt_thread:terminate() end
			prompt_thread = lua_thread.create(show_delayed_prompt, tape_prompt, 0x6fa8dc)
			
		elseif text:find("^ Аренда прилавка была продлена") then
			local renewed_hours = text:match("(%d+) ч%.")
			local renewed_ts = end_ts + renewed_hours * 3600
			local message = "\u{1F3F7}\u{FE0F} "..u8((text:gsub("{%x+}", '').." до "))..os.date("%Y-%m-%d %H:%M", renewed_ts + timezone * 3600)..' ('..nick..')'
			lua_thread.create(send_mykolaj_message, '/send_lavka_message', {message = message, nick = nick, token = token})
			lua_thread.create(send_mykolaj_message, '/renew_lavka', {nick = nick, renewed_ts = renewed_ts, token = token})
		end
	end
end