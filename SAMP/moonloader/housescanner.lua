require ('lib.moonloader')
local samp = require('lib.samp.events')
local vkeys = require('vkeys')
local rkeys = require('rkeys')
copas = require 'copas'
http = require 'copas.http'
local encoding = require('encoding')
u8 = encoding.UTF8

local COOKIE = "R3ACTLB=; PHPSESSID="

function samp.onServerMessage(color, text)
	if text == " « Неоплаченное частное имущество выставлено на продажу »" then
		found = false
		--lua_thread.create(function() for i=1,35 do GETHouseNumber(1) print(i) wait(5000) end end)
		lua_thread.create(function() GETHouseNumber(1) end)
		setClipboardText("/buyhouse")
	end
end

function for_sale()
	found = false
	lua_thread.create(function() GETHouseNumber(2) end)
end

function GETHouseNumber(mode)
	addOneOffSound(0.0, 0.0, 0.0, 1138)
	
	local respbody = {}
	
    local body, code, headers, status = http.request {
        url = "https://evolve-rp.ru/api/map.php",
        method = "GET",
        headers = {
			["Host"] = "evolve-rp.ru",
			["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
			["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
			["Accept-Language"] = "ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3",
			["Connection"] = "keep-alive",
			["Cookie"] = COOKIE,
			["Upgrade-Insecure-Requests"] = "1",
			["Sec-Fetch-Dest"] = "document",
			["Sec-Fetch-Mode"] = "navigate",
			["Sec-Fetch-Site"] = "none",
			["Sec-Fetch-User"] = "?1",
			["Sec-GPC"] = "1"
        },
        sink = ltn12.sink.table(respbody)
    }
	
	source = u8(table.concat(respbody))
	
	if mode == 1 then
		for house in string.gmatch(source, '<div class="house free" style="[^"]+" data%-hint="([^d]+%d+)">') do
			number = tonumber(house)
			sampAddChatMessage('House №'..number, 0xFFFF00)
			if not found then sampSendChat("/findhouse "..number) end
			found = true
		end
	end
	
	if mode == 2 then
		for house in string.gmatch(source, '<div class="house auction" style="[^"]+" data%-hint="([^d]+%d+)">') do
			number = tonumber(house)
			sampAddChatMessage('House №'..number..' for sale', 0xFFFF00)
			found = true
		end
	end
	
	if source:find('"success":false') then sampAddChatMessage('Cookie is expired', 0xFFFF00) return 1 end
	
	if source:find('Please turn JavaScript on and reload the page') then sampAddChatMessage('Error', 0xFFFF00) return 2 end
	
	if not found then sampAddChatMessage('House not found', 0xFFFF00) return end
end

function cookie_check()
	found = false
	lua_thread.create(function()
		local code = GETHouseNumber(1)
		if code == 1 or code == 2 then
			sampAddChatMessage('Invalid', 0xFFFF00)
		else
			sampAddChatMessage('Valid', 0xFFFF00)
		end
	end)
end

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	
	sampRegisterChatCommand("cookie", cookie_check)
	
	sampRegisterChatCommand("forsale", for_sale)

	while true do
		wait(0)
	end
end