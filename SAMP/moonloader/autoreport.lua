require("lib.moonloader")
local samp = require("lib.samp.events")
local vkeys = require('vkeys')
local imgui = require('imgui')
MainWindow = imgui.ImBool(false)
local encoding = require('encoding')
encoding.default, u8 = 'CP1251', encoding.UTF8
local inicfg = require('inicfg')
math.randomseed(os.time())

cfg = {}
cfg['autoreport'] = inicfg.load({
	main = {
		first = VK_RBUTTON,
		second = VK_XBUTTON2,
		reason = 'סבטג'
	}
}, "..\\config\\autoreport.ini")

local TID = -1

function split(str, sep)
	local words = {}
    for m in str:gmatch('[^'..sep..']+') do
        table.insert(words, m)
    end
	return words
end

function main()
	while not isSampAvailable() do wait(100) end
	sampRegisterChatCommand("arep", function() MainWindow.v = not MainWindow.v end)
    while true do
        wait(0)
		
		imgui.Process = MainWindow.v
		
		local result, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
		if result then
			local result, id = sampGetPlayerIdByCharHandle(ped)
			if result then
				TID = id
			end
		end
		
		if cfg['autoreport'].main.second == 0 then
			if isKeyJustPressed(cfg['autoreport'].main.first) then
				reasons = split(cfg['autoreport'].main.reason, '|')
				sampSendChat('/report '..TID..' '..reasons[math.random(1, #reasons)])
			end
		else
			if isKeyDown(cfg['autoreport'].main.first) then
				if isKeyJustPressed(cfg['autoreport'].main.second) then
					reasons = split(cfg['autoreport'].main.reason, '|')
					sampSendChat('/report '..TID..' '..reasons[math.random(1, #reasons)])
				end
			end
		end
    end
end

function samp.onSendGiveDamage(playerId)
	TID = playerId
end

------------------------------------------------------------ImGUI------------------------------------------------------------
local sw, sh = getScreenResolution()

local keyNames = {
	'',
	'Left Button',
	'Right Button',
	'Break',
	'Middle Button',
	'X Button 1',
	'X Button 2',
	'Backspace',
	'Tab',
	'Clear',
	'Enter',
	'Shift',
	'Ctrl',
	'Alt',
	'Pause',
	'Caps Lock',
	'Kana',
	'Junja',
	'Final',
	'Kanji',
	'Esc',
	'Convert',
	'Non Convert',
	'Accept',
	'Mode Change',
	'Space',
	'Page Up',
	'Page Down',
	'End',
	'Home',
	'Arrow Left',
	'Arrow Up',
	'Arrow Right',
	'Arrow Down',
	'Select',
	'Print',
	'Execute',
	'Print Screen',
	'Insert',
	'Delete',
	'Help',
	'0',
	'1',
	'2',
	'3',
	'4',
	'5',
	'6',
	'7',
	'8',
	'9',
	'A',
	'B',
	'C',
	'D',
	'E',
	'F',
	'G',
	'H',
	'I',
	'J',
	'K',
	'L',
	'M',
	'N',
	'O',
	'P',
	'Q',
	'R',
	'S',
	'T',
	'U',
	'V',
	'W',
	'X',
	'Y',
	'Z',
	'Left Win',
	'Right Win',
	'Context Menu',
	'Sleep',
	'Numpad 0',
	'Numpad 1',
	'Numpad 2',
	'Numpad 3',
	'Numpad 4',
	'Numpad 5',
	'Numpad 6',
	'Numpad 7',
	'Numpad 8',
	'Numpad 9',
	'Numpad *',
	'Numpad +',
	'Separator',
	'Num -',
	'Numpad .',
	'Numpad /',
	'F1',
	'F2',
	'F3',
	'F4',
	'F5',
	'F6',
	'F7',
	'F8',
	'F9',
	'F10',
	'F11',
	'F12',
	'F13',
	'F14',
	'F15',
	'F16',
	'F17',
	'F18',
	'F19',
	'F20',
	'F21',
	'F22',
	'F23',
	'F24',
	'Num Lock',
	'Scrol Lock',
	'Jisho',
	'Mashu',
	'Touroku',
	'Loya',
	'Roya',
	'Left Shift',
	'Right Shift',
	'Left Ctrl',
	'Right Ctrl',
	'Left Alt',
	'Right Alt',
	'Browser Back',
	'Browser Forward',
	'Browser Refresh',
	'Browser Stop',
	'Browser Search',
	'Browser Favorites',
	'Browser Home',
	'Volume Mute',
	'Volume Down',
	'Volume Up',
	'Next Track',
	'Previous Track',
	'Stop',
	'Play / Pause',
	'Mail',
	'Media',
	'App1',
	'App2',
	';',
	'=',
	',',
	'-',
	'.',
	'/',
	'`',
	'Abnt C1',
	'Abnt C2',
	'[',
	'\'',
	']',
	'\'',
	'!',
	'Ax',
	'> <',
	'IcoHlp',
	'Process',
	'IcoClr',
	'Packet',
	'Reset',
	'Jump',
	'OemPa1',
	'OemPa2',
	'OemPa3',
	'WsCtrl',
	'Cu Sel',
	'Oem Attn',
	'Finish',
	'Copy',
	'Auto',
	'Enlw',
	'Back Tab',
	'Attn',
	'Cr Sel',
	'Ex Sel',
	'Er Eof',
	'Play',
	'Zoom',
	'Pa1',
	'OemClr'
}

function name_to_index(name)
	for i, v in ipairs(keyNames) do
		if name == v then
			return i
		end
	end
	return 1
end

local firstKey_ImInt = imgui.ImInt(name_to_index(vkeys.id_to_name(cfg['autoreport'].main.first)) - 1)
local secondKey_ImInt = imgui.ImInt(name_to_index(vkeys.id_to_name(cfg['autoreport'].main.second)) - 1)
local reason_ImBuffer = imgui.ImBuffer(u8(cfg['autoreport'].main.reason), 256)

function imgui.OnDrawFrame()
    if MainWindow.v then
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(280, 115), imgui.Cond.FirstUseEver)
		imgui.Begin("Autoreport (target: "..TID..")", MainWindow, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		
		imgui.Text("First key: ")
		imgui.SameLine(280 - 120 - 10)
        imgui.PushItemWidth(120)
        if imgui.Combo('##firstKey_ImInt', firstKey_ImInt, keyNames) then
			keyId = vkeys.name_to_id(keyNames[firstKey_ImInt.v + 1])
			cfg['autoreport'].main.first = keyId and keyId or 0
			saveIni()
		end
        imgui.PopItemWidth()
		
		imgui.Text("Second key: ")
		imgui.SameLine(280 - 120 - 10)
        imgui.PushItemWidth(120)
        if imgui.Combo('##secondKey_ImInt', secondKey_ImInt, keyNames) then
			local keyId = vkeys.name_to_id(keyNames[secondKey_ImInt.v + 1])
			cfg['autoreport'].main.second = keyId and keyId or 0
			saveIni()
		end
        imgui.PopItemWidth()
		
		imgui.NewLine()
		
		imgui.Text("Reason: ")
		imgui.SameLine(280 - 120 - 10)
		imgui.PushItemWidth(120)
		if imgui.InputText('##reason_ImBuffer', reason_ImBuffer) then
			cfg['autoreport'].main.reason = u8:decode(reason_ImBuffer.v)
			saveIni()
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
    style.WindowPadding = imgui.ImVec2(9, 5)
    style.WindowRounding = 10
    style.ChildWindowRounding = 10
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 6.0
    style.ItemSpacing = imgui.ImVec2(9.0, 3.0)
    style.ItemInnerSpacing = imgui.ImVec2(9.0, 3.0)
    style.IndentSpacing = 21
    style.ScrollbarSize = 6.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 17.0
    style.GrabRounding = 16.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)


    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]           = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.Border]                 = ImVec4(0.82, 0.77, 0.78, 1.00)
    colors[clr.BorderShadow]           = ImVec4(0.35, 0.35, 0.35, 0.66)
    colors[clr.FrameBg]                = ImVec4(1.00, 1.00, 1.00, 0.28)
    colors[clr.FrameBgHovered]         = ImVec4(0.68, 0.68, 0.68, 0.67)
    colors[clr.FrameBgActive]          = ImVec4(0.79, 0.73, 0.73, 0.62)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.46, 0.46, 0.46, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.MenuBarBg]              = ImVec4(0.00, 0.00, 0.00, 0.80)
    colors[clr.ScrollbarBg]            = ImVec4(0.00, 0.00, 0.00, 0.60)
    colors[clr.ScrollbarGrab]          = ImVec4(1.00, 1.00, 1.00, 0.87)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(1.00, 1.00, 1.00, 0.79)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.80, 0.50, 0.50, 0.40)
    colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.99, 0.99, 0.99, 0.52)
    colors[clr.SliderGrab]             = ImVec4(1.00, 1.00, 1.00, 0.42)
    colors[clr.SliderGrabActive]       = ImVec4(0.76, 0.76, 0.76, 1.00)
    colors[clr.Button]                 = ImVec4(0.51, 0.51, 0.51, 0.60)
    colors[clr.ButtonHovered]          = ImVec4(0.68, 0.68, 0.68, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.67, 0.67, 0.67, 1.00)
    colors[clr.Header]                 = ImVec4(0.72, 0.72, 0.72, 0.54)
    colors[clr.HeaderHovered]          = ImVec4(0.92, 0.92, 0.95, 0.77)
    colors[clr.HeaderActive]           = ImVec4(0.82, 0.82, 0.82, 0.80)
    colors[clr.Separator]              = ImVec4(0.73, 0.73, 0.73, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.81, 0.81, 0.81, 1.00)
    colors[clr.SeparatorActive]        = ImVec4(0.74, 0.74, 0.74, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.80, 0.80, 0.80, 0.30)
    colors[clr.ResizeGripHovered]      = ImVec4(0.95, 0.95, 0.95, 0.60)
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 1.00, 1.00, 0.90)
    colors[clr.CloseButton]            = ImVec4(0.45, 0.45, 0.45, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.70, 0.70, 0.90, 0.60)
    colors[clr.CloseButtonActive]      = ImVec4(0.70, 0.70, 0.70, 1.00)
    colors[clr.PlotLines]              = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 1.00, 1.00, 0.35)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.88, 0.88, 0.88, 0.35)
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

function saveIni()
	return inicfg.save(cfg['autoreport'], string.format('..\\config\\autoreport.ini'))
end