script_name("NewsHelper")
script_authors("Vlad")
script_description("Automated news helper")
script_version("v0.3") 

require ('lib.moonloader')
local samp = require('lib.samp.events')
local vkeys = require('vkeys')
local rkeys = require('rkeys')
local inicfg = require('inicfg')
local encoding = require('encoding')
local imgui = require('imgui')
imgui.HotKey = require('imgui_addons').HotKey
imgui.ToggleButton = require('imgui_addons').ToggleButton
encoding.default = 'CP1251'

u8 = encoding.UTF8
local MainWindow = imgui.ImBool(false)

cfg = {}
cfg['NewsHelper'] = inicfg.load({
    keys = {
		capture = encodeJson({VK_NUMPAD3}),
		notes = encodeJson({VK_NUMPAD2}),
		pustyshka = encodeJson({vkeys.VK_LCONTROL, vkeys.VK_1})
	},
	values = {
		delay = 125,
		pustyshka = "1",
		autocomplete = false,
		autosend = false,
		autopustyshka = false
	},
    dictionary = {
	}
}, "..\\config\\NewsHelper.ini")

function initDictionary(cfg_dictionary)
	local dictionary = {}
	local length = 0
	for dkey, dvalue in pairs(cfg_dictionary) do
		length = length + 1
		dictionary[tostring(dkey)] = tostring(dvalue)
	end
	return dictionary, length
end

local dictionary, dictionary_length = initDictionary(cfg['NewsHelper'].dictionary) --dictionary, string keys and value
local notes = {} local notes_length = 0 --temporary dictionary
local note = {text = nil, edited = nil}
local employees = {}
local delay = cfg['NewsHelper'].values.delay
local captureKey = decodeJson(cfg['NewsHelper'].keys.capture) --tuple
local notesKey = decodeJson(cfg['NewsHelper'].keys.notes) --tuple
local pustyshkaKey = decodeJson(cfg['NewsHelper'].keys.pustyshka) --tuple
local pustyshka_text = cfg['NewsHelper'].values.pustyshka
local autoComplete = cfg['NewsHelper'].values.autocomplete
local autoSend = cfg['NewsHelper'].values.autosend
local autoPustyshka = cfg['NewsHelper'].values.autopustyshka

function saveIni()
	local saved = inicfg.save(cfg['NewsHelper'], string.format('..\\config\\NewsHelper.ini'))
    if saved then
        return saved
    end
end

function msgIntro(text)
	sampAddChatMessage("[PLAY UA]: "..text.." {616060}"..thisScript().version, 0xD78E10)
end

function msgChat(text, color)
    sampAddChatMessage('[NewsHelper]: '..text, color)
end

function isValueInArray(array, value)
	for i, elem in ipairs(array) do
		if elem == value then
			return i
		end
	end
	return false
end

function rkeys.onHotKey(id, keys)
    if isPauseMenuActive() or isSampfuncsConsoleActive() or sampIsChatInputActive() or MainWindow.v
	or (sampIsDialogActive() and (dialogId ~= 20039 and dialogId ~= 20044 and dialogId ~= 20045 and dialogId ~= 20046)) then
        return false
    end
end

function capture_activation()
	if capture then msgChat("AdCapture is deactivated", 0xFF4040)
	else msgChat("AdCapture is activated...", 0x40FF40) end
	capture = not capture
end

function pustyshka_activation()
	if (sampIsDialogActive() and (dialogId == 20039 or dialogId == 20044)) or (not sampIsDialogActive()) then
		pustyshka = true
		capturing:terminate()
		sampSendDialogResponse(20044, 0, nil, nil)
		sampSendDialogResponse(20039, 0, nil, nil)
		sampSendChat("/ad "..pustyshka_text)
	end
end

function autoPustyshka_activation()
	autoPustyshka_loop = true
	autoPustyshka_looping:terminate()
	autoPustyshka_looping:run()
end
function autoPustyshka_deactivation()
	autoPustyshka_loop = false
	autoPustyshka_looping:terminate()
end

function members_update_activation()
	employees = {}
	membersUpdate = true
	sampSendChat("/members")
end

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	msgIntro('{3767b8}Settings: {FFFFFF}/news. {3767b8}Commands: {FFFFFF}/nad /ndel /notedel /nmem /nmemcl /nmemadd /ntog.')
	
	_, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	myNick = sampGetPlayerNickname(myId)
	
	sampRegisterChatCommand("ntog", ad_toggle)
	sampRegisterChatCommand("nmem", members_update_activation)
	sampRegisterChatCommand("nmemcl", membersClear)
	sampRegisterChatCommand("news", function()   MainWindow.v = not MainWindow.v   end)
	
	captureRegId = rkeys.registerHotKey(captureKey, 1, capture_activation)
	notesRegId = rkeys.registerHotKey(notesKey, 1, function() if note.edited ~= nil and #note.edited >= 5 and #note.edited <= 80 and addNotes(note.text, note.edited) then
													msgChat("Ad added to notes: ["..note.text.."] - ".."["..note.edited.."]", 0x40FF40)
													else msgChat("Key is null or already existing!", 0xFF4040) end end)
	pustyshkaRegId = rkeys.registerHotKey(pustyshkaKey, 1, pustyshka_activation)

	while true do
		wait(0)
		
		imgui.Process = MainWindow.v
	end
end

function ad_toggle()
	adToggle = true
	sampSendChat("/mm"); 		
	sampSendDialogResponse(10411, 1, 2, nil)
	sampSendDialogResponse(10414, 1, 8, nil)
	sampSendDialogResponse(32700, 1, 5, nil)
	sampSendDialogResponse(32700, 0, nil, nil)
	sampSendDialogResponse(10414, 0, nil, nil)
	sampSendDialogResponse(10411, 0, nil, nil) 
end

function takeScreen()
    memory.setuint8(sampGetBase() + 0x119CBC, 1)
end

function membersClear()
	employees = {}
	msgChat("Members cleared", 0xFF4040)
end

function membersAdd(name)
	if name == nil or isValueInArray(employees, name) then  return false  end
	table.insert(employees, name)
	return true
end

function membersDel(name)
	local elem_ind = isValueInArray(employees, name)
	if name == nil or not elem_ind then  return false  end
	table.remove(employees, elem_ind)
	return true
end

function addNotes(key, value)
	if key == nil or notes[key] ~= nil then  return false  end
	notes[key] = value
	notes_length = notes_length + 1
	return true
end

function deleteNotes(key)
	if key == nil then  return false  end
	notes[key] = nil
	notes_length = notes_length - 1
	return true
end

function addDictionary(key, value)
	if key == nil or dictionary[key] ~= nil then  return false  end
	dictionary[key] = value
	dictionary_length = dictionary_length + 1
	cfg['NewsHelper'].dictionary = dictionary
	return true
end

function deleteDictionary(key)
	if key == nil then  return false  end
	dictionary[key] = nil
	dictionary_length = dictionary_length - 1
	cfg['NewsHelper'].dictionary = dictionary
	return true
end

function employees_ad(line)
	for i, nick in ipairs(employees) do
		if line:find(nick) then
			return false
		end
	end	
	return true
end

function search_free_ad(content, gmatch_regex, text)
	local num = -1
    for line in content:gmatch(gmatch_regex) do
		num = num + 1
		if line:find(text) and employees_ad(line) then
			return num
		end
    end
	return false
end

capturing = lua_thread.create_suspended(
	function()
		local adnum = search_free_ad(capturing_text, '[^\n]+', '{ff0000}')
				
		if adnum then
			sampSendDialogResponse(20044, 1, adnum - 1, nil)
			if autoSend then  sampSendDialogResponse(20045, 1, 2, nil)  end
			msgChat("Ad was captured!", 0x40FF40)
		else
			wait(delay)
			sampSendDialogResponse(20044, 0, nil, nil)
			sampSendDialogResponse(20039, 1, 0, nil)
			--[[_, updatenum = rowByText(text, '[^\n]+', '-')
			if updatenum then
				sampSendDialogResponse(20044, 1, updatenum - 1, nil)
			else
				sampAddChatMessage("Ad line is full. AdCapture is deactivated", 0xFF4040)
				adCapture = false
			end]]
		end
	end)

function samp.onShowDialog(id, style, title, button1, button2, text)
	dialogId = id

	if id == 20047 and autoComplete then
		local adtext = text:match("{BBBBBB}Текст отправления: {FFFFFF}([^\n]+)")
		
		if dictionary[adtext] ~= nil then
			msgChat("Ad autocompleting... ["..adtext.."] -> ["..dictionary[adtext].."]", 0x40FF40)
			sampSendDialogResponse(20047, 1, nil, dictionary[adtext])	
		elseif notes[adtext] ~= nil then
			msgChat("Ad autocompleting... ["..adtext.."] -> ["..notes[adtext].."]", 0x40FF40)
			sampSendDialogResponse(20047, 1, nil, notes[adtext])
		end
		sampSendDialogResponse(20046, 1, nil, nil)
		
		if autoSend then  sampSendDialogResponse(20045, 1, 0, nil)  end	
	end
	
	if id == 20046 then
		if cacheNote then
			note.text = text:match("{BBBBBB}Текст отправления: {FFFFFF}([^\n]+)")
			note.edited = text:match("{BBBBBB}Отредактированный текст: {FFFFFF}([^\n]+)")
			cacheNote = false
		end
	end

	if capture and id == 20044 then
		capturing_text = text
		capturing:run()
	end
	
	if pustyshka and id == 20043 then
		lua_thread.create(
			function()
				wait(1200)
				sampSendDialogResponse(20043, 1, nil, nil)
				if capture then
					sampSendChat("/n")
					sampSendDialogResponse(20039, 1, 0, nil)
				end
				pustyshka = false
			end)
		printStringNow("Sending ad...", 1200)
		return false
	end
	
	if id == 10411 and adToggle then
		if menuClose then adToggle = false menuClose = false end
		return false
	end
	if id == 10414 and adToggle then
		return false
	end
	if id == 32700 and adToggle then
		if menuClose then
			if text:find("явления	{008000}Включено{FFFFFF}") then msgChat("Ad toggled", 0x40FF40) else msgChat("Ad toggled", 0xFF4040) end
		end
		menuClose = true
		return false
	end
end

function samp.onSendDialogResponse(id, button, listId, input)
	if id == 20047 and button == 1 and input ~= '' then
		cacheNote = true
	end
end

autoPustyshka_looping = lua_thread.create_suspended(
	function()
		while autoPustyshka_loop do
			local timer = os.time() + 60
			while (timer - os.time() >= 0) or (sampIsDialogActive() and (dialogId ~= 20039 and dialogId ~= 20044)) or (MainWindow.v) do wait(0) end
			pustyshka_activation()
		end
	end)

function samp.onServerMessage(color, text)
	if membersUpdate then
		local nick = text:match('ID: %d+ | %d%d:%d%d %d%d%.%d%d%.%d%d%d%d | (%a+_%a+)')
		if nick and nick ~= myNick then
			table.insert(employees, nick)
		elseif text:match('^ Всего: %d+ человек') then
			membersUpdate = false
			msgChat("Members updated", 0x40FF40)
		end
	end
	
	if pustyshka and (color == -1077886209 or color == -1347440726) and (text:match("явление можно будет отправить только через %d+ секунд!")
	or text:match("В редакции, на данный момент, нет свободного места для вашего")) then
		lua_thread.create(
			function()
				wait(1000)
				if capture then
					sampSendChat("/n")
					sampSendDialogResponse(20039, 1, 0, nil)
				end
				pustyshka = false
			end)
	end
	
	if autoPustyshka and color == -86 and text:match("явление будет подано после проверки") then
		autoPustyshka_activation()
	end
end

function samp.onSendCommand(command)
	local key_add, value_add = command:match("^/nadd \"(.+)\" \"(.+)\"$")
	if key_add and value_add then
		if #value_add >= 5 and #value_add <= 80 and addDictionary(key_add, value_add) then
			msgChat("Ad added to dictionary: ["..key_add.."] - ".."["..value_add.."]", 0x40FF40)
		else
			msgChat("Key is null or already existing!", 0xFF4040)
		end
	elseif command:match("^/nadd$") then
		msgChat("/nadd \"key\" \"value\"", 0xFF4040)
	end
	
	local key_del = command:match("^/ndel \"(.+)\"$")
	if key_del then
		if deleteDictionary(key_del) then
			msgChat("Ad deleted from dictionary: ["..key_del.."]", 0xFF4040)			
		end
	elseif command:match("^/ndel$") then
		msgChat("/ndel \"key\"", 0xFF4040)
	end
	
	local key_del_notes = command:match("^/notedel \"(.+)\"$")
	if key_del_notes then
		if deleteNotes(key_del_notes) then
			msgChat("Ad deleted from notes: ["..key_del_notes.."]", 0xFF4040)		
		end
	elseif command:match("^/notedel$") then
		msgChat("/notedel \"key\"", 0xFF4040)
	end
	
	local employee_add = command:match("^/nmemadd \"(.+)\"$")
	if employee_add then
		if membersAdd(employee_add) then
			msgChat("Member added: ["..employee_add.."]", 0x40FF40)
		else
			msgChat("Member is already existing!", 0xFF4040)
		end
	elseif command:match("^/nmemadd$") then
		msgChat("/nmemadd \"Nick_Name\"", 0xFF4040)
	end
	
	local employee_del = command:match("^/nmemdel \"(.+)\"$")
	if employee_del then
		if membersDel(employee_del) then
			msgChat("Member deleted: ["..employee_del.."]", 0x40FF40)
		else
			msgChat("Member doesn't exist!", 0xFF4040)
		end
	elseif command:match("^/nmemdel$") then
		msgChat("/nmemdel \"Nick_Name\"", 0xFF4040)
	end
end

------------------------------------------------------------ImGUI------------------------------------------------------------
local sw, sh = getScreenResolution()

local delay_imgui = imgui.ImInt(delay)
local captureKey_imgui = { v = captureKey }
local notesKey_imgui = { v = notesKey }
local pustyshkaKey_imgui = { v = pustyshkaKey }
local captureLastKeys_imgui = {}
local notesLastKeys_imgui = {}
local pustyshkaLastKeys_imgui = {}
local pustyshka_imgui = imgui.ImBuffer(u8(pustyshka_text), 80)
local autoComplete_imgui = imgui.ImBool(autoComplete)
local autoSend_imgui = imgui.ImBool(autoSend)
local autoPustyshka_imgui = imgui.ImBool(autoPustyshka)

function imgui.OnDrawFrame()
    if MainWindow.v then
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(600, 308), imgui.Cond.FirstUseEver)
		imgui.Begin("NewsHelper for Evolve-Rp", MainWindow, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		
        imgui.Separator()
        imgui.SetCursorPosX((600 - imgui.CalcTextSize('/nad /ndel /notedel /nmem(cl/add/del) /ntog').x) / 2)
		imgui.Text("/nad /ndel /notedel /nmem(cl/add/del) /ntog")
		imgui.Separator()
		
		imgui.Text("Delay")
		imgui.SameLine((600 - 40)/12)
		imgui.PushItemWidth(40)
		if imgui.InputInt("##delay_imgui", delay_imgui, 0, 0) then
			delay = tonumber(delay_imgui.v)
			cfg['NewsHelper'].values.delay = delay
		end
		imgui.PopItemWidth()
		imgui.SameLine(98)
		imgui.Text("Pustyshka")
		imgui.SameLine(160)
		imgui.PushItemWidth(50)
		if imgui.HotKey("##pustyshkaKey_imgui", pustyshkaKey_imgui, pustyshkaLastKeys_imgui, 50) then
			pustyshkaKey = pustyshkaKey_imgui.v
			cfg['NewsHelper'].keys.pustyshka = encodeJson(pustyshkaKey)
			rkeys.changeHotKey(pustyshkaRegId, pustyshkaKey)
		end
		imgui.PopItemWidth()
		imgui.SameLine(220)
		imgui.Text("Text")
		imgui.SameLine(252)
		imgui.PushItemWidth(132)
		if imgui.InputText("##pustyshka_imgui", pustyshka_imgui) then
			pustyshka_text = u8:decode(pustyshka_imgui.v)
			cfg['NewsHelper'].values.pustyshka = pustyshka_text
		end
		imgui.PopItemWidth()
		imgui.SameLine(394)
		imgui.Text("Capture")
		imgui.SameLine(445)
		imgui.PushItemWidth(50)
		if imgui.HotKey("##captureKey_imgui", captureKey_imgui, captureLastKeys_imgui, 50) then
			captureKey = captureKey_imgui.v
			cfg['NewsHelper'].keys.capture = encodeJson(captureKey)
			rkeys.changeHotKey(captureRegId, captureKey)
		end
		imgui.PopItemWidth()
		imgui.SameLine(507)
		imgui.Text("Note")
		imgui.SameLine(540)
		imgui.PushItemWidth(50)
		if imgui.HotKey("##notesKey_imgui", notesKey_imgui, notesLastKeys_imgui, 50) then
			notesKey = notesKey_imgui.v
			cfg['NewsHelper'].keys.notes = encodeJson(notesKey)
			rkeys.changeHotKey(notesRegId, notesKey)
		end
		imgui.PopItemWidth()
		
		imgui.Text("Autocomplete")
		imgui.SameLine(95)
		if imgui.Checkbox("##autoComplete_imgui", autoComplete_imgui) then
			autoComplete = autoComplete_imgui.v
			cfg['NewsHelper'].values.autocomplete = autoComplete
		end
		imgui.SameLine(125)
		imgui.Text("Autosend")
		imgui.SameLine(185)
		if imgui.Checkbox("##autoSend_imgui", autoSend_imgui) then
			autoSend = autoSend_imgui.v
			cfg['NewsHelper'].values.autosend = autoSend
		end
		imgui.SameLine(215)
		imgui.Text("Autopustyshka")
		imgui.SameLine(305)
		if imgui.Checkbox("##autoPustyshka_imgui", autoPustyshka_imgui) then
			autoPustyshka = autoPustyshka_imgui.v
			cfg['NewsHelper'].values.autopustyshka = autoPustyshka
			if not autoPustyshka then autoPustyshka_deactivation() end
		end

        imgui.Separator()
        imgui.SetCursorPosX((600 - imgui.CalcTextSize('Dictionary').x) / 2)
		imgui.Text("Dictionary")
		imgui.Separator()
		
		local key, value = nil
		for i = 1, dictionary_length do
			key, value = next(dictionary, key) 
			key, value = tostring(key), tostring(value)
			key_u8 = u8(key)
			value_u8 = u8(value)
			if imgui.Button(value_u8.."##"..i, imgui.ImVec2(440, 17)) then
				imgui.SetClipboardText(value_u8)
			end
			imgui.SameLine(480-3)
			if imgui.Button(key_u8.."##"..i, imgui.ImVec2(112, 17)) then
				imgui.SetClipboardText(key_u8)
			end
		end
		
		imgui.Separator()
        imgui.SetCursorPosX((600 - imgui.CalcTextSize('Notes').x) / 2)
		imgui.Text("Notes")
		imgui.Separator()
		
		local key, value = nil
		for i = 1, notes_length do
			key, value = next(notes, key) 
			key, value = tostring(key), tostring(value)
			key_u8 = u8(key)
			value_u8 = u8(value)
			if imgui.Button(value_u8.."##"..i, imgui.ImVec2(440, 17)) then
				imgui.SetClipboardText(value_u8)
			end
			imgui.SameLine(480-3)
			if imgui.Button(key_u8.."##"..i, imgui.ImVec2(112, 17)) then
				imgui.SetClipboardText(key_u8)
			end
		end
		
		imgui.End()
    end
end

function ImGuiStyleApply()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 2.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 2.0
    style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0
	style.ButtonTextAlign = imgui.ImVec2(0, 0.5)

    colors[clr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.00) -- keys, values click
    colors[clr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 0.20)
    colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 0.40)
    colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
    colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
    colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = colors[clr.PopupBg]
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

ImGuiStyleApply()
------------------------------------------------------------ImGUI------------------------------------------------------------

function onWindowMessage(m, p)
    if m == 0x100 or m == 0x101 then
        if p == vkeys.VK_ESCAPE and MainWindow.v and not isPauseMenuActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and not sampIsChatInputActive() then
            consumeWindowMessage()
            if m == 0x101 then
                MainWindow.v = false
            end
        end
    end
end

function onScriptTerminate(name,bool)
	if  name == thisScript() then
		if saveIni() then print("Settings has been saved.") end
	end
end