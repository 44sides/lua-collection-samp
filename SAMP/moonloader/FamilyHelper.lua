script_name("FamilyHelper")
script_authors("Vlad")
script_description("Family helper")
script_version("v0.25") 

require ('lib.moonloader')
local samp = require('lib.samp.events')
local vkeys = require('vkeys')
local rkeys = require('rkeys')
local ffi = require('ffi')
local inicfg = require('inicfg')
local encoding = require('encoding')
local imgui = require('imgui')
imgui.HotKey = require('imgui_addons').HotKey
encoding.default = 'CP1251'

u8 = encoding.UTF8
local MainWindow = imgui.ImBool(false)

cfg = {}
cfg['FamilyHelper'] = inicfg.load({
    keys = {
        box = encodeJson({VK_B}),
		trunk = encodeJson({VK_N})
    },
    values = {
        box = 1.15
    }
}, "..\\config\\FamilyHelper.ini")

local closeAtmNums = {38, 39, 40, 41, 42, 36, 47, 2, 1, 44, 3, 4, 50, 5, 61, 10, 32, 31, 30, 37, 16, 7, 46, 43, 28, 29, 26, 49, 22, 35, 23, 27, 8, 21, 20, 15, 56, 57, 58, 59, 60, 24, 9, 25, 33, 14, 6, 11, 18, 45, 34, 48, 51, 52, 53, 54, 55, 19, 12, 17, 13} -- ATMs ordered
local boxKey = decodeJson(cfg['FamilyHelper'].keys.box) --tuple
local trunkKey = decodeJson(cfg['FamilyHelper'].keys.trunk) --tuple
local boxDist = cfg['FamilyHelper'].values.box
local gribFont = renderCreateFont('Arial', 8, 7)

function saveIni()
	local saved = inicfg.save(cfg['FamilyHelper'], string.format('..\\config\\FamilyHelper.ini'))
    if saved then
        return saved
    end
end

function msgIntro(text)
    --sampAddChatMessage("[PLAY UA]: "..text.." {616060}Authors: "..unpack(thisScript().authors).." "..thisScript().version, 0xD78E10)
	sampAddChatMessage("[PLAY UA]: "..text.." {616060}"..thisScript().version, 0xD78E10)
end

function msgChat(text, color)
    sampAddChatMessage('[FamilyHelper]: '..text, color)
end

function rkeys.onHotKey(id, keys)
    if isPauseMenuActive() or isSampfuncsConsoleActive() or sampIsChatInputActive() or sampIsDialogActive() then
        return false
    end
end

function top_output()
	sampSendChat("/fpanel")
	ftop = true
	top = false
end

function contract_output()
	sampSendChat("/fpanel")
	fcon = true
	con = false
end

function loadfamily_input()
	sampSendChat("/loadfamily")
end

function trunk_activation()
	family = true
	trunk = false
	sampSendChat("/en")
end

function box_activation()
	box = not box
	if box then printStringNow("~g~Box is activated", 1000)
	else printStringNow("~r~Box is deactivated", 1000) end
end

function grib_activation()
	grib = not grib
	if grib then printStringNow("Grib ~g~ON", 1000)
	else printStringNow("Grib ~r~OFF", 1000) end
end

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	msgIntro('{3767b8}Settings: {FFFFFF}/family. {3767b8}Commands: {FFFFFF}/tr /ld /fcon /ftop /grib.')
	
	sampRegisterChatCommand("ftop", top_output)
	sampRegisterChatCommand("fcon", contract_output)
	sampRegisterChatCommand("tr", trunk_activation)
	sampRegisterChatCommand("ld", loadfamily_input)
	sampRegisterChatCommand('grib', grib_activation)
	
	boxRegId = rkeys.registerHotKey(boxKey, 1, box_activation)
	trunkRegId = rkeys.registerHotKey(trunkKey, 1, trunk_activation)
	
	sampRegisterChatCommand("family", function()   MainWindow.v = not MainWindow.v   end)

	while true do
		wait(0)
		
		imgui.Process = MainWindow.v
		
		if grib then grib_render() end
	end
end

function distance_object(modelid)
	for _, OBJECT_HANDLE in ipairs(getAllObjects()) do
		local mid = getObjectModel(OBJECT_HANDLE)
			if mid == modelid then
				local x, y, z = getCharCoordinates(playerPed)
				local _, ox, oy, oz = getObjectCoordinates(OBJECT_HANDLE)
				return getDistanceBetweenCoords3d(x, y, z, ox, oy, oz)
			end
	end
end

function get_Pickup_Model(id)
	local PICKUP_POOL = sampGetPickupPoolPtr()
    return ffi.cast("int *", (id * 20 + 61444) + PICKUP_POOL)[0]
end

function findIndex(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

function repairer_atm(rows)
	for i, num in ipairs(closeAtmNums) do
		if rows[num]:find("Повреждён") or rows[num]:find("Сломан") then 
			return num
		end
	end
	return false
end

function collector_atm(rows)
	for i, num in ipairs(closeAtmNums) do
		if rows[num]:find("Заканчивается") or rows[num]:find("Пустой") then 
			return num
		end
	end
	return false
end

function grib_render()
    local objects = getAllObjects()
    for i, v in ipairs(objects) do
        if doesObjectExist(v) then
            local result, x, y, z = getObjectCoordinates(v)
            if result then
                local model = getObjectModel(v)
				if model == 1603 then
					local screenX, screenY = convert3DCoordsToScreen(x, y, z)
					local dist = math.floor(getDistanceBetweenCoords3d(x, y, z, getCharCoordinates(playerPed)))
					if isObjectOnScreen(v) then
						renderFontDrawText(gribFont, '[' .. dist .. 'm]', screenX, screenY, 0xffff0000)
					end
				end
            end
        end
    end
end

function samp.onSendPlayerSync(data)
	if box then
		local dist = distance_object(19832)
		if dist ~= nil and dist <= boxDist then
			if not HkeyDown then
				data.keysData = 0
				data.specialKey = 3
				HkeyDown = true
			else
				--data.keysData = 8
				data.specialKey = 0
				HkeyDown = false
			end
		end
	end
end

--[[function samp.onSendPlayerSync(data) --- continuous specialKey = 3
	if box then
		local dist = distance_object(19832)
		if dist ~= nil and dist <= boxDist then
				data.keysData = 0
				data.specialKey = 3
		end
	end
end]]

function samp.onApplyPlayerAnimation(pid, _, name, _, _, _, _, _, _)
	local _, myid = sampGetPlayerIdByCharHandle(playerPed)
	if (name == "LIFTUP" or name == "PUTDWN") and pid == myid and box then
		lua_thread.create(
			function()
				wait(0)
				taskPlayAnimNonInterruptable(playerPed, "HANDSUP", "PED", 4.0, false, false, false, false, 5)
			end)
    end
end

function samp.onCreatePickup(id, model, ptype, position)
	if grib and model == 1603 then printStringNow("~g~New grib", 1500) end
end

function samp.onShowDialog(id, style, title, button1, button2, text)
	if id == 372 and family then
		if text:find("Багажник	{008000}Открыт{FFFFFF}") then   trunk = true   end
				
		if not trunk then 
			sampSendDialogResponse(372, 1, 1, nil)
			trunk = true
			closing = true
			printStringNow("~g~Trunk opened", 1000)
		else
			if not closing then printStringNow("~r~Trunk is already open!", 1000) end
			sampSendDialogResponse(372, 0, nil, nil)
			family = false
			closing = false
			--wait(650)
			--sampSendChat("/loadfamily")
		end
		return false
	end
	
	if id == 32700 and ftop then
		if not top then
			sampSendDialogResponse(32700, 1, 21, nil)
			top = true
		else
			sampSendDialogResponse(32700, 1, 0, nil)
			ftop = false
		end
		return false
	end
	
	if id == 32700 and fcon then
		if not con then
			sampSendDialogResponse(32700, 1, 19, nil)
			con = true
		else
			sampSendDialogResponse(32700, 1, 1, nil)
			fcon = false
		end
		return false
	end
	
	if id == 1100 and title:find("Банкоматы") then
		local idcar = getCarModel(storeCarCharIsInNoSave(playerPed))
		lua_thread.create(
			function()
				local rows = {}; local ind = 0
				
				if idcar == 422 then
					for line in text:gmatch("[^\n]+") do 
						rows[ind] = line; ind = ind + 1
					end
					local num = repairer_atm(rows)
					if num then
						sampSendDialogResponse(1100, 1, num - 1, nil)
						msgChat("ATM "..num.." picked".." ("..findIndex(closeAtmNums,num).."th)", 0x40AF40)
						local alternum = collector_atm(rows)
						if alternum then msgChat("Alternative ATM "..alternum.." ("..findIndex(closeAtmNums,alternum).."th)".." exists for collector", 0x40AF40) end
						return
					end
					msgChat("There are no close ATMs", 0xFF4040)
				end
				
				if idcar == 428 then
					for line in text:gmatch("[^\n]+") do 
						rows[ind] = line; ind = ind + 1
					end
					local num = collector_atm(rows)
					if num then
						sampSendDialogResponse(1100, 1, num - 1, nil)
						msgChat("ATM "..num.." picked".." ("..findIndex(closeAtmNums,num).."th)", 0x40AF40)
						local alternum = repairer_atm(rows)
						if alternum then msgChat("Alternative ATM "..alternum.." ("..findIndex(closeAtmNums,alternum).."th)".." exists for repairer", 0x40AF40) end
						return
					end
					msgChat("There are no close ATMs", 0xFF4040)
				end
			end)
	end
	
	if id == 1344 and title:find("TAXI | {ae433d}GPS%-навигатор") then
		sampSendDialogResponse(1344, 0, nil, nil)
		return false	
	end
end

function samp.onServerMessage(color, text)
	if text == (' Отнесите ящик к транспорту') then return false end
end

function samp.onSendCommand(command)
	if command:match("^/bdist [123456789]+%.%d+") or command:match("^/bdist 0%.%d+") then
		for number in command:gmatch('%d+%.%d+') do
			boxDist = tonumber(number)
			cfg['FamilyHelper'].values.box = boxDist
			msgChat("Trigger distance changed to "..number, 0x40FF40)
			break
		end
	elseif command:match("^/bdist$") then
		msgChat("/bdist \"value\"", 0xFF4040)
	end
end

------------------------------------------------------------ImGUI------------------------------------------------------------
local sw, sh = getScreenResolution()

local boxKey_imgui = { v = boxKey }
local trunkKey_imgui = { v = trunkKey }
local boxLastKeys_imgui = {}
local trunkLastKeys_imgui = {}

function imgui.OnDrawFrame()
    if MainWindow.v then
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(280, 140), imgui.Cond.FirstUseEver)
		imgui.Begin("FamilyHelper for ERP", MainWindow, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
        imgui.Separator()
        imgui.SetCursorPosX((280 - imgui.CalcTextSize('Keys').x) / 2)
		imgui.Text(u8"Keys")
		imgui.Separator()
		
		imgui.Text(u8"Box activation: ")
		imgui.SameLine(280 - 80 - 10)
		imgui.PushItemWidth(100)
		if imgui.HotKey("##boxKey_imgui", boxKey_imgui, boxLastKeys_imgui, 80) then
			boxKey = boxKey_imgui.v
			cfg['FamilyHelper'].keys.box = encodeJson(boxKey)
			rkeys.changeHotKey(boxRegId, boxKey)
		end
		imgui.PopItemWidth()
		
		imgui.Text(u8"Trunk activation: ")
		imgui.SameLine(280 - 80 - 10) 
		imgui.PushItemWidth(100)
		if imgui.HotKey("##trunkKey_imgui", trunkKey_imgui, trunkLastKeys_imgui, 80) then
			trunkKey = trunkKey_imgui.v
			cfg['FamilyHelper'].keys.trunk = encodeJson(trunkKey)
			rkeys.changeHotKey(trunkRegId, trunkKey)
		end
		imgui.PopItemWidth()
		
		imgui.End()
    end
end

function ImGuiStyleApply()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2

	style.WindowPadding = ImVec2(15, 15)
	style.WindowRounding = 6.0
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.FramePadding = ImVec2(5, 5)
	style.FrameRounding = 4.0
	style.ItemSpacing = ImVec2(12, 8)
	style.ItemInnerSpacing = ImVec2(8, 6)
	style.IndentSpacing = 25.0
	style.ScrollbarSize = 15.0
	style.ScrollbarRounding = 9.0
	style.GrabMinSize = 5.0
	style.GrabRounding = 3.0

	colors[clr.Text] = ImVec4(0.80, 0.80, 0.83, 1.00)
	colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
	colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
	colors[clr.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
	colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
	colors[clr.Border] = ImVec4(0.80, 0.80, 0.83, 0.88)
	colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0.00)
	colors[clr.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
	colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
	colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
	colors[clr.TitleBg] = ImVec4(0.76, 0.31, 0.00, 1.00)
	colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
	colors[clr.TitleBgActive] = ImVec4(0.80, 0.33, 0.00, 1.00)
	colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
	colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
	colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
	colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
	colors[clr.CheckMark] = ImVec4(1.00, 0.42, 0.00, 0.53)
	colors[clr.SliderGrab] = ImVec4(1.00, 0.42, 0.00, 0.53)
	colors[clr.SliderGrabActive] = ImVec4(1.00, 0.42, 0.00, 1.00)
	colors[clr.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
	colors[clr.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
	colors[clr.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
	colors[clr.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
	colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
	colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	colors[clr.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
	colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
	colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.55)
	colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
	colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
	colors[clr.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
	colors[clr.PlotLinesHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
	colors[clr.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
	colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
	colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
	colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

ImGuiStyleApply()
------------------------------------------------------------ImGUI------------------------------------------------------------

function onWindowMessage(m, p)	
    if MainWindow.v and p == VK_ESCAPE and not sampIsChatInputActive() then
        consumeWindowMessage()
		if m == 257 then
			MainWindow.v = false
		end
    end
end

function onScriptTerminate(name,bool)
	if  name == thisScript() then
		if saveIni() then print("Settings has been saved.") end
	end
end