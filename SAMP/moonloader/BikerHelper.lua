script_name('BikersHelper for ERP')
script_author('Franchesko & Vlad')
require("lib.moonloader")
local inicfg = require ('inicfg')
local vkeys = require ('vkeys')
local rkeys = require 'rkeys'
local imgui = require "imgui"
imgui.HotKey = require('imgui_addons').HotKey
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local sampev = require 'samp.events'

local main_window_state = imgui.ImBool(false)
local second_window_state = imgui.ImBool(false)
local sw, sh = getScreenResolution()
local fsafeactive = false
local fbankactive = false
local captureactive = false
local activeautoload = false
local proccesautoload = false
local changedlivpos = false
local admins = ""
local dlivtimer = 0
local offmembers = {}
local offmembersrangs = {}

local path_ini = '..\\config\\bikershelper.ini'
local mainIni = inicfg.load({
    maincfg = {
		spawncar = false,
		ctrlspawncar = false,
		slot1 = true,
		slot2 = true,
		slot3 = true,
		slot4 = true,
		slot5 = true,
		fsafecmd = "fswl",
		fbankcmd = "fbwl",
		automget = "automget",
		captoalarm = false,
		deletekiy = false,
		smskontr = false,
		uvedkontr = false,
		autobar = false,
		autodrugs = false,
		admcopyid = false,
		autom4g = false,
		autodrugsdeath = false,
		autodrugsdeath_delay = 1000,
		autodrugsspawn = false,
		dtimer = false,
		dtimertext = "Длив",
		capturekey = encodeJson({VK_F1}),
		menukey = encodeJson({VK_LCONTROL}),
		dlivposx = 20,
		dlivposy = 400,
		dlivtime = 118,
		dlivcolor = -16776961,
		dlivrazmer = 11,
		ctime = 200,
		clist = 1
    }
},path_ini)

function saveIniFile()
    local inicfgsaveparam = inicfg.save(mainIni,path_ini)
end
saveIniFile()

function join_argb(a, r, g, b)
  local argb = b  -- b
  argb = bit.bor(argb, bit.lshift(g, 8))  -- g
  argb = bit.bor(argb, bit.lshift(r, 16)) -- r
  argb = bit.bor(argb, bit.lshift(a, 24)) -- a
  return argb
end

function explode_argb(argb)
  local a = bit.band(bit.rshift(argb, 24), 0xFF)
  local r = bit.band(bit.rshift(argb, 16), 0xFF)
  local g = bit.band(bit.rshift(argb, 8), 0xFF)
  local b = bit.band(argb, 0xFF)
  return a, r, g, b
end

function alarmSoundOn()
	sampAddChatMessage("{008080}[BikersHelper] {FFFF00}Флуд /capture Флуд /capture Флуд /capture", -1)
	addOneOffSound(0, 0, 0, 1138)
	addOneOffSound(0, 0, 0, 1076)
	return true
end
function alarmSoundOff()
	addOneOffSound(0, 0, 0, 1077)
	return false
end

function captoCalculation(tp)
	local h, m, s = tonumber(os.date("%H", os.time())), tonumber(os.date("%M", os.time())), tonumber(os.date("%S", os.time()))
	local diff_sec = ((h + (h % 2 == tp and (m >= 25 and 2 or 0) or 1)) * 3600 + 25 * 60) - (h * 3600 + m * 60 + s)
	return os.time() + diff_sec
end

function captoAlarmTimer()
	local ctime = captoCalculation(tp)
	while true do wait(1000)
		if os.time() - ctime >= 0 then
			sound = alarmSoundOn()
			ctime = captoCalculation(tp)
		end
	end
end captoalarm_thread = lua_thread.create_suspended(captoAlarmTimer)

function sampev.onSetPlayerTime(sh, sm)
	if not tp and getActiveInterior() == 0 then
		if sh % 2 == os.date("%H", os.time()) % 2 then
			tp = 0
		else
			tp = 1
		end
		
		if mainIni.maincfg.captoalarm then
			captoalarm_thread:run()
		end
	end
end

-- Транспортное средство используется
-- Парковка данного транспорта доступна с Кандидат в президенти[6] ранга вашей семьи

function sampev.onServerMessage(color, text)
	if (string.find(text, "Данный дом не привязан к Вашей семье")) then
		autoclose = true
		return true
	end
	
	if (string.find(text, "Отправитель: Контрабандист")) and mainIni.maincfg.smskontr then
		return false
	end
	if (string.find(text, "Сообщает: Контрабандист")) and mainIni.maincfg.uvedkontr then
		return false
	end
	
	-- if text:find("Несите ящик в фургон") and activeautoload then
		-- lua_thread.create(function()
			-- proccesautoload = false
		-- end)
	-- end
	-- if text:find("Несите канистру в фургон") and activeautoload then
		-- lua_thread.create(function()
			-- proccesautoload = false
		-- end)
	-- end
	-- if text:find("Вы уронили ящик") and activeautoload then
		-- lua_thread.create(function()
			-- proccesautoload = true
		-- end)
	-- end
	-- if text:find("Вы уронили канистру") and activeautoload then
		-- lua_thread.create(function()
			-- proccesautoload = true
		-- end)
	-- end
	-- if text:find("Вы положили в фургон") and activeautoload then
		-- lua_thread.create(function()
			-- proccesautoload = true
		-- end)
	-- end

	if string.find(text, "Админы Online:") and mainIni.maincfg.admcopyid then
		admins = ""
		return true
	end
	if text:find(" | ID%: (%d+) | Level") and mainIni.maincfg.admcopyid then
		local aId = text:match(" | ID%: (%d+) | Level")
		admins = admins .. aId .. " "
		setClipboardText(admins)
	end

	if(string.find(text, "продлена на 2 минуты")) then
 		dlivtimer = os.time() + mainIni.maincfg.dlivtime
 		return true
 	end

	if text:find("%[8%] %[(%w+_%w+)%]") or text:find("%[7%] %[(%w+_%w+)%]") or text:find("%[6%] %[(%w+_%w+)%]") then
		lua_thread.create(function()
			wait(1000)
			local rang, nick = text:match("%[(%d)%] %[(%w+_%w+)%]")
			offmembers[#offmembers + 1] = nick
			offmembersrangs[#offmembersrangs + 1] = rang
		end)
	end
	
	if text:find("%[Внимание%]: .+ спровоцировала войну с .+ за территорию .+. Инициатор: .+$") then
		sound = alarmSoundOff()
	end
	
	if activeautoload and text:find("^ Материалов в фургоне: 15000 / 15000") then
		lua_thread.create(function() wait(0) automget_activation() end)
	end
end

local capturekey = {v = decodeJson(mainIni.maincfg.capturekey)}
local menukey = {v = decodeJson(mainIni.maincfg.menukey)}
local spawncar = imgui.ImBool(mainIni.maincfg.spawncar)
local ctrlspawncar = imgui.ImBool(mainIni.maincfg.ctrlspawncar)
local slot1 = imgui.ImBool(mainIni.maincfg.slot1)
local slot2 = imgui.ImBool(mainIni.maincfg.slot2)
local slot3 = imgui.ImBool(mainIni.maincfg.slot3)
local slot4 = imgui.ImBool(mainIni.maincfg.slot4)
local slot5 = imgui.ImBool(mainIni.maincfg.slot5)
local fsafecmd = imgui.ImBuffer(u8(mainIni.maincfg.fsafecmd), 265)
local fbankcmd = imgui.ImBuffer(u8(mainIni.maincfg.fbankcmd), 265)
local automget = imgui.ImBuffer(u8(mainIni.maincfg.automget), 265)
local captoalarm = imgui.ImBool(mainIni.maincfg.captoalarm)
local deletekiy = imgui.ImBool(mainIni.maincfg.deletekiy)
local smskontr = imgui.ImBool(mainIni.maincfg.smskontr)
local uvedkontr = imgui.ImBool(mainIni.maincfg.uvedkontr)
local autobar = imgui.ImBool(mainIni.maincfg.autobar)
local autodrugs = imgui.ImBool(mainIni.maincfg.autodrugs)
local ctime = imgui.ImInt(mainIni.maincfg.ctime)
local clist = imgui.ImInt(mainIni.maincfg.clist)
local admcopyid = imgui.ImBool(mainIni.maincfg.admcopyid)
local autom4g = imgui.ImBool(mainIni.maincfg.autom4g)
local autodrugsdeath = imgui.ImBool(mainIni.maincfg.autodrugsdeath)
local autodrugsdeath_delay = imgui.ImInt(mainIni.maincfg.autodrugsdeath_delay)
local autodrugsspawn = imgui.ImBool(mainIni.maincfg.autodrugsspawn)
local dtimer = imgui.ImBool(mainIni.maincfg.dtimer)
local dlivtime = imgui.ImInt(mainIni.maincfg.dlivtime)
local dlivposx = imgui.ImInt(mainIni.maincfg.dlivposx)
local dlivposy = imgui.ImInt(mainIni.maincfg.dlivposy)
local dtimertext = imgui.ImBuffer(u8(mainIni.maincfg.dtimertext), 265)
local dlivcolor = imgui.ImFloat4(imgui.ImColor(explode_argb(mainIni.maincfg.dlivcolor)):GetFloat4())
local dlivrazmer = imgui.ImInt(mainIni.maincfg.dlivrazmer)
local dlivrender = renderCreateFont("Arial Black", mainIni.maincfg.dlivrazmer, FCR_BORDER + FCR_BOLD)

function rkeys.onHotKey(id, keys)
    if id == capturekeyRegId and not captureactive and (isSampfuncsConsoleActive() or sampIsChatInputActive() or sampIsDialogActive()) then
        return false
	end
    if id == menukeyRegId and (not isCharOnFoot(PLAYER_PED) or isSampfuncsConsoleActive() or sampIsChatInputActive() or sampIsDialogActive()) then
        return false
	end
end

function automget_activation(arg)
	activeautoload = not activeautoload 
	if activeautoload then
		automget_delay = tonumber(arg)
		if not automget_delay then
			automget_delay = 1000
			sampAddChatMessage("{008080}[BikersHelper] {ffffff}Флуд /materials get и /bput запущен.", -1) 
		else
			sampAddChatMessage("{008080}[BikersHelper] {ffffff}Флуд /materials get и /bput запущен с задержкой "..automget_delay.."мс.", -1) 
		end
	else
		sampAddChatMessage("{008080}[BikersHelper] {ffffff}Флуд /materials get и /bput остановлен.", -1)
	end
end

function capture_activation()
	captureactive = not captureactive
	if captureactive then
		sampAddChatMessage("{008080}[BikersHelper] {ffffff}Флудер /capture запущен. Для отключения нажмите клавишу еще раз.", -1)
	else
		sampAddChatMessage("{008080}[BikersHelper] {ffffff}Флудер /capture остановлен.", -1)
	end
end

function menu_activation()
	if mainIni.maincfg.spawncar then
		pressRawKey(1024)
		pressRawKey(0)
	end
end

function main()
    while not isSampAvailable() do wait(100) end
		sampRegisterChatCommand("bhelper", function() main_window_state.v = not main_window_state.v end)
		sampRegisterChatCommand(mainIni.maincfg.fsafecmd, function() sampSendChat("/fpanel"); fsafeactive = true end)
		sampRegisterChatCommand(mainIni.maincfg.fbankcmd, function() sampSendChat("/fpanel"); fbankactive = true end)
		sampRegisterChatCommand(mainIni.maincfg.automget, automget_activation)

		capturekeyRegId = rkeys.registerHotKey(capturekey.v, 1, capture_activation)
		menukeyRegId = rkeys.registerHotKey(menukey.v, 3, menu_activation)

		addEventHandler("onWindowMessage", function (msg, wparam) -- закрытие окна на ESC
			if imgui.Process and wparam == vkeys.VK_ESCAPE and not sampIsChatInputActive() then
				consumeWindowMessage(true, false)
				if msg == 257 then
					main_window_state.v = false
				end
			end
		end)
		
		while true do
        wait(0)
				imgui.Process = main_window_state.v or second_window_state.v
				if wasKeyReleased(vkeys.VK_LCONTROL) then
					LCONTROL = true
				end
				if wasKeyReleased(vkeys.VK_LMENU) then
					LCONTROL = false
				end
				if mainIni.maincfg.deletekiy then
					local weapon = getCurrentCharWeapon(PLAYER_PED)
					if weapon == 7 then
						removeWeaponFromChar(PLAYER_PED, weapon)
					end
				end
				if captureactive then
					sampSendChat("/capture")
					sampSendDialogResponse(32700, 1, mainIni.maincfg.clist - 1, -1)
					wait(mainIni.maincfg.ctime)
				end
				if activeautoload then
					sampSendChat("/materials get")
					wait(automget_delay)
				end
				if activeautoload then 
					sampSendChat("/bput")
					wait(automget_delay)
				end
				if isKeyJustPressed(71) and isPlayerPlaying(PLAYER_HANDLE) and mainIni.maincfg.autom4g and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() then
					setCurrentCharWeapon(PLAYER_PED, 31)
				end
				if mainIni.maincfg.autodrugsspawn and getCharHealth(PLAYER_PED) == 0 then
					repeat wait(0) until getCharHealth(PLAYER_PED) ~= 0
					autodrugsspawnsbiv = true
					sampSendChat("/usedrugs 8")
					lua_thread.create(function()
						wait(1000)
						autodrugsspawnsbiv = false
					end)
				end
				if mainIni.maincfg.autodrugsdeath and getCharHealth(PLAYER_PED) == 0 then
					wait(mainIni.maincfg.autodrugsdeath_delay)
					sampSendChat("/usedrugs 16")
					repeat wait(0) until getCharHealth(PLAYER_PED) ~= 0
				end
				if mainIni.maincfg.dtimer then
					local dcolor1, dcolor2, dcolor3, dcolor4 = explode_argb(mainIni.maincfg.dlivcolor)
					if (dlivtimer >= os.time()) then
						local timer = dlivtimer - os.time()
						local minute, second = math.floor(timer / 60), timer % 60
						local text = string.format(mainIni.maincfg.dtimertext .. ": %02d:%02d", minute, second)
						if changedlivpos then
							showCursor(true, true)
							local X, Y = getCursorPos()
							renderFontDrawText(dlivrender, text, X, Y, join_argb(dcolor4, dcolor1, dcolor2, dcolor3))
							if isKeyJustPressed(13) then
								mainIni.maincfg.dlivposx = X
								mainIni.maincfg.dlivposy = Y
								changedlivpos = false
								showCursor(false, false)
								main_window_state.v = true
								saveIniFile()
								sampAddChatMessage("{008080}[BikersHelper] {ffffff}Новая позиция таймера длива успешно сохранена.", -1)
							end
						else
							renderFontDrawText(dlivrender, text, mainIni.maincfg.dlivposx, mainIni.maincfg.dlivposy, join_argb(dcolor4, dcolor1, dcolor2, dcolor3))
						end
					elseif changedlivpos then
						showCursor(true, true)
						local X, Y = getCursorPos()
						renderFontDrawText(dlivrender, mainIni.maincfg.dtimertext .. ": 0:0", X, Y, join_argb(dcolor4, dcolor1, dcolor2, dcolor3))
						if isKeyJustPressed(13) then
							mainIni.maincfg.dlivposx = X
							mainIni.maincfg.dlivposy = Y
							changedlivpos = false
							showCursor(false, false)
							main_window_state.v = true
							saveIniFile()
							sampAddChatMessage("{008080}[BikersHelper] {ffffff}Новая позиция таймера длива успешно сохранена.", -1)
						end
					end
				end
    end
end


function imgui.OnDrawFrame()
		local tLastKeys = {}
    if main_window_state.v then
      	imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(450, 735), imgui.Cond.FirstUseEver)
				imgui.Begin("BikersHelper for ERP", main_window_state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
        imgui.Separator()
				imgui.CenterText(u8"Настройки функций для семьи")
				imgui.Separator()
				if imgui.Checkbox(u8"Автоспавн семейной машины", spawncar) then
						mainIni.maincfg.spawncar = spawncar.v
						saveIniFile()
				end
				imgui.SameLine()
				if imgui.Checkbox(u8"на Ctrl", ctrlspawncar) then
					if ctrlspawncar.v then 
						mainIni.maincfg.menukey = encodeJson({VK_LCONTROL})
						rkeys.changeHotKey(menukeyRegId, {VK_LCONTROL})
					else
						mainIni.maincfg.menukey = encodeJson({})
						rkeys.changeHotKey(menukeyRegId, {})
					end
					mainIni.maincfg.ctrlspawncar = ctrlspawncar.v
					saveIniFile()
				end
				imgui.Text(u8'Слоты: ')
				imgui.SameLine()
				if imgui.Checkbox(u8"[1]", slot1) then
						mainIni.maincfg.slot1 = slot1.v
						saveIniFile()
				end
				imgui.SameLine()
				if imgui.Checkbox(u8"[2]", slot2) then
						mainIni.maincfg.slot2 = slot2.v
						saveIniFile()
				end
				imgui.SameLine()
				if imgui.Checkbox(u8"[3]", slot3) then
						mainIni.maincfg.slot3 = slot3.v
						saveIniFile()
				end
				imgui.SameLine()
				if imgui.Checkbox(u8"[4]", slot4) then
						mainIni.maincfg.slot4 = slot4.v
						saveIniFile()
				end
				imgui.SameLine()
				if imgui.Checkbox(u8"[5]", slot5) then
						mainIni.maincfg.slot5 = slot5.v
						saveIniFile()
				end
				imgui.Text(u8'Команда открытия/закрытия сейфа семьи: ')
				imgui.SameLine()
				imgui.PushItemWidth(50)
				if imgui.InputText(u8"##fsafecmd", fsafecmd) then
					sampUnregisterChatCommand(mainIni.maincfg.fsafecmd)
					mainIni.maincfg.fsafecmd = tostring(u8:decode(fsafecmd.v))
					saveIniFile()
					sampRegisterChatCommand(mainIni.maincfg.fsafecmd, function() sampSendChat("/fpanel"); fsafeactive = true end)
				end
				imgui.PopItemWidth()
				imgui.Text(u8'Команда открытия/закрытия банка семьи: ')
				imgui.SameLine()
				imgui.PushItemWidth(50)
				if imgui.InputText(u8"##fbankcmd", fbankcmd) then
					sampUnregisterChatCommand(mainIni.maincfg.fbankcmd)
					mainIni.maincfg.fbankcmd = tostring(u8:decode(fbankcmd.v))
					saveIniFile()
					sampRegisterChatCommand(mainIni.maincfg.fbankcmd, function() sampSendChat("/fpanel"); fbankactive = true end)
				end
				imgui.PopItemWidth()
				imgui.Separator()
				imgui.CenterText(u8"Настройки общих функций для байкеров")
				imgui.Separator()
				if imgui.Checkbox(u8"Каптобудильник", captoalarm) then
						mainIni.maincfg.captoalarm = captoalarm.v
						if mainIni.maincfg.captoalarm then
							if tp then
								captoalarm_thread:run()
							end
						else
							sound = alarmSoundOff()
							captoalarm_thread:terminate()
						end
						saveIniFile()
        end
				if imgui.Checkbox(u8"Удалять кий", deletekiy) then
						mainIni.maincfg.deletekiy = deletekiy.v
						saveIniFile()
        end
				if imgui.Checkbox(u8"Не показывать SMS от Контрабандиста", smskontr) then
						mainIni.maincfg.smskontr = smskontr.v
						saveIniFile()
        end
				if imgui.Checkbox(u8"Не показывать уведомления о поставках Контрабандиста", uvedkontr) then
						mainIni.maincfg.uvedkontr = uvedkontr.v
						saveIniFile()
        end
				if imgui.Checkbox(u8"При открытии меню бара автопополнение до фулла", autobar) then
						mainIni.maincfg.autobar = autobar.v
						saveIniFile()
        end
				if imgui.Checkbox(u8"Автовзятие нарко со склада до максимума", autodrugs) then
						mainIni.maincfg.autodrugs = autodrugs.v
						saveIniFile()
        end
				if imgui.Checkbox(u8"Автоматически копировать id админов из /admins", admcopyid) then
						mainIni.maincfg.admcopyid = admcopyid.v
						saveIniFile()
        end
				if imgui.Checkbox(u8"Автоматически брать в руки m4 при посадке на пассажирку", autom4g) then
						mainIni.maincfg.autom4g = autom4g.v
						saveIniFile()
        end
				if imgui.Checkbox(u8"Автоюз и сбив нарко после спавна", autodrugsspawn) then
						mainIni.maincfg.autodrugsspawn = autodrugsspawn.v
						saveIniFile()
        end
				if imgui.Checkbox(u8"Автоюз нарко после смерти: ", autodrugsdeath) then
						mainIni.maincfg.autodrugsdeath = autodrugsdeath.v
						saveIniFile()
        end
				imgui.SameLine()
				imgui.PushItemWidth(100)
				if imgui.InputInt(u8"##autodrugsdeath_delay", autodrugsdeath_delay) then
						mainIni.maincfg.autodrugsdeath_delay = tonumber(autodrugsdeath_delay.v)
						saveIniFile()
        end
				imgui.PopItemWidth()
				imgui.SameLine()
				imgui.Text(u8"мс")
				imgui.Text(u8'Команда флуда /materials get и /bput: ')
				imgui.SameLine()
				imgui.PushItemWidth(70)
				if imgui.InputText(u8"##automget", automget) then
					sampUnregisterChatCommand(mainIni.maincfg.automget)
					mainIni.maincfg.automget = tostring(u8:decode(automget.v))
					saveIniFile()
					sampRegisterChatCommand(mainIni.maincfg.automget, automget_activation)
				end
				imgui.PopItemWidth()
				imgui.SameLine()
				imgui.Text(u8'<задержка>')
				imgui.Separator()
				imgui.CenterText(u8"Настройки таймера длива")
				imgui.Separator()
				if imgui.Checkbox(u8"Таймер длива", dtimer) then
						mainIni.maincfg.dtimer = dtimer.v
						saveIniFile()
        end
				imgui.SameLine()
				imgui.SetCursorPosX(150)
				if imgui.Button(u8"Изменить позицию таймера") then
					if mainIni.maincfg.dtimer then
						changedlivpos = true
						main_window_state.v = false
						sampAddChatMessage("{008080}[BikersHelper] {ffffff}Для сохранения позиции нажмите Enter.", -1)
					end
				end
				imgui.Text(u8'Текст таймера: ')
				imgui.SameLine()
				imgui.PushItemWidth(100)
				if imgui.InputText(u8"##dtimertext", dtimertext) then
					mainIni.maincfg.dtimertext = tostring(u8:decode(dtimertext.v))
					saveIniFile()
				end
        imgui.PopItemWidth()
				imgui.SameLine()
				imgui.Text(u8"Размер: ")
				imgui.SameLine()
				imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##dlivrazmer", dlivrazmer) then
					mainIni.maincfg.dlivrazmer = tonumber(dlivrazmer.v)
					dlivrender = renderCreateFont("Arial Black", mainIni.maincfg.dlivrazmer, FCR_BORDER + FCR_BOLD)
					saveIniFile()
        end
				imgui.PopItemWidth()
				imgui.Text(u8"Время до длива в секундах: ")
				imgui.SameLine()
				imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##dlivtime", dlivtime) then
					mainIni.maincfg.dlivtime = tonumber(dlivtime.v)
					saveIniFile()
        end
				imgui.PopItemWidth()
				if imgui.ColorEdit4(u8"Цвет", dlivcolor) then
					mainIni.maincfg.dlivcolor = join_argb(dlivcolor.v[1] * 255, dlivcolor.v[2] * 255, dlivcolor.v[3] * 255, dlivcolor.v[4] * 255)
					saveIniFile()
				end
				imgui.Separator()
				imgui.CenterText(u8"Настройки автокаптера для байкеров")
				imgui.Separator()
				imgui.Text(u8("Старт/стоп флуд: "))
				imgui.SameLine()
				if imgui.HotKey('##capturekey', capturekey) then
					mainIni.maincfg.capturekey = encodeJson(capturekey.v)
					rkeys.changeHotKey(capturekeyRegId, capturekey.v)
					saveIniFile()
				end
				imgui.Text(u8"Задержка: ")
				imgui.SameLine()
				imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##ctime", ctime) then
					mainIni.maincfg.ctime = tonumber(ctime.v)
					saveIniFile()
        end
        imgui.PopItemWidth()
				imgui.Text(u8"Номер бизнеса: ")
				imgui.SameLine()
				imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##clist", clist) then
					mainIni.maincfg.clist = tonumber(clist.v)
					saveIniFile()
        end
        imgui.PopItemWidth()
				imgui.Separator()
				imgui.CenterText(u8"Функции для лидера")
				imgui.Separator()
				imgui.Text(u8"Управление оффлайн мемберсом в байкерах: ")
				imgui.SameLine()
				if imgui.Button(u8"Открыть настройки") then
					second_window_state.v = not second_window_state.v
				end
				imgui.End()
		    end
				if second_window_state.v then
					imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	        imgui.SetNextWindowSize(imgui.ImVec2(400, 450), imgui.Cond.FirstUseEver)
					imgui.Begin(u8"BikersHelper || Функции для лидера", second_window_state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
	        imgui.Separator()
					imgui.CenterText(u8"Offline members 6-8 ранги")
					imgui.Separator()
					if #offmembers == 0 then
						imgui.CenterText(u8"Пусто. Для заполнения нажмите кнопку «Заполнить/обновить».")
					else
						for i = 1, #offmembers do
			          imgui.Text(u8(i .. ". " .. offmembers[i] .. " - Ранг: " .. offmembersrangs[i]))
								imgui.SameLine()
								if imgui.Button(u8" Понизить до 5 ранга ##" .. i) then
									sampSendChat("/offgiverank " .. offmembers[i] .. " 5")
									sampAddChatMessage("{008080}[BikersHelper] {ffffff}" .. offmembers[i] .. " был успешно понижен до 5 ранга. Нажмите кнопку «Заполнить/обновить» для обновления списка.", -1)
								end
			      end
					end
					imgui.Separator()
					imgui.SetCursorPosX(110)
					if imgui.Button(u8" Заполнить/обновить offmembers ") then
						offmembers = {}
						offmembersrangs = {}
						sampAddChatMessage("{008080}[BikersHelper] {ffffff}Запущено обновление 6-8 рангов в оффлайне. Подождите пару секунд.", -1)
						sampSendChat("/offmembers")
					end
					imgui.Separator()
					imgui.End()
				end
	end

function setCurrentDialogItem(id, item)
	repeat wait(0) until sampGetCurrentDialogId() == id and sampIsDialogActive()
	sampSetCurrentDialogListItem(item)
end

function sampev.onShowDialog(dialogId, dialogStyle, dialogTitle, okButtonText, cancelButtonText, dialogText)
	--spawncar
	if dialogId == 6700 and mainIni.maincfg.spawncar and (not mainIni.maincfg.ctrlspawncar or LCONTROL) and not autoclose then
		sampSendDialogResponse(6700, 1, 7, -1)
		return false
	elseif dialogId == 6700 and mainIni.maincfg.spawncar and (not mainIni.maincfg.ctrlspawncar or LCONTROL) and autoclose then
		sampSendDialogResponse(6700, 0, -1, -1)
		autoclose = false
		nodialog = false
		return false
	end
		
	if dialogId == 6707 and mainIni.maincfg.spawncar and (not mainIni.maincfg.ctrlspawncar or LCONTROL) and not autoclose then
		local n = -2
		for line in string.gmatch(dialogText, "[^\r\n]+") do
			n = n + 1
			if mainIni.maincfg['slot'..n+1] and line:find('На парковке') then
				sampSendDialogResponse(6707, 1, n, -1)
				return false
			end
		end
		for i=1,5 do if mainIni.maincfg['slot'..i] then lua_thread.create(setCurrentDialogItem, dialogId, i-1) return end end
	elseif dialogId == 6707 and mainIni.maincfg.spawncar and (not mainIni.maincfg.ctrlspawncar or LCONTROL) and autoclose then
		if nodialog then
			sampSendDialogResponse(6707, 0, -1, -1)
			return false
		else
			lua_thread.create(function() wait(250) sampCloseCurrentDialogWithButton(0) end)
		end
	end
		
	if dialogId == 6708 and mainIni.maincfg.spawncar and (not mainIni.maincfg.ctrlspawncar or LCONTROL) then
		autoclose = true
		sampSendDialogResponse(6708, 1, 0, -1)
		return false
	end
		
	if dialogId == 6709 and mainIni.maincfg.spawncar and (not mainIni.maincfg.ctrlspawncar or LCONTROL) then
		sampSendDialogResponse(6709, 1, 0, -1)
		nodialog = true
		return false
	end

		--warelock fsafe/fbank
	if dialogTitle:find("Панель | {ae433d}Семья") and fsafeactive then
		sampSendDialogResponse(dialogId, 1, 6, -1)
		return false
	end
	if dialogTitle:find("Склад | {ae433d}Семья") and fsafeactive then
		fsafeactive = false
		sampSendDialogResponse(dialogId, 1, 0, -1)
		lua_thread.create(closedialog)
	end
	if dialogTitle:find("Панель | {ae433d}Семья") and fbankactive then
		sampSendDialogResponse(dialogId, 1, 7, -1)
		return false
	end
	if dialogTitle:find("Банк | {ae433d}Семья") and fbankactive then
		fbankactive = false
		sampSendDialogResponse(dialogId, 1, 0, -1)
		lua_thread.create(closedialog)
	end

		--autobar
	if dialogId == 32700 and dialogTitle:find("Меню бара") and mainIni.maincfg.autobar then
		lua_thread.create(function()
			sampSendDialogResponse(dialogId, 1, 0, -1)
			wait(300)
			sampSendDialogResponse(dialogId, 1, 0, -1)
			wait(300)
			sampSendDialogResponse(dialogId, 1, 0, -1)
			wait(300)
			sampSendDialogResponse(dialogId, 1, 0, -1)
			wait(300)
			sampCloseCurrentDialogWithButton(0)
		end)
	end

	--autodrugs
	if dialogTitle:find('Склад наркотиков') and dialogText:find('Наркотиков на руках') and mainIni.maincfg.autodrugs then
		local currentDrugs, maxDrugs = dialogText:match('Наркотиков на руках: {......}(%d+) {FFFFFF}/ {......}(%d+)')
		if tonumber(maxDrugs) > tonumber(currentDrugs) then
			sampSendDialogResponse(dialogId, 1, 0, maxDrugs - currentDrugs)
			lua_thread.create(closedialog)
		end
	end
end
	
function sampev.onSendDialogResponse(id, button, listid, input)
	if id == 6707 and button == 0 and mainIni.maincfg.spawncar and (not mainIni.maincfg.ctrlspawncar or LCONTROL) then autoclose = true end
end

function sampev.onSendPlayerSync(data)
	if rawKey then
		data.keysData = rawKey
		rawKey = nil
    end
end

function sampev.onApplyPlayerAnimation(pid, _, name, _, _, _, _, _, _)
	if mainIni.maincfg.autodrugsspawn and autodrugsspawnsbiv and name == "M_smk_drag" and pid == select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)) then
		autodrugsspawnsbiv = false
		lua_thread.create(function()
			wait(0)
			taskPlayAnimNonInterruptable(playerPed, "HANDSUP", "PED", 4.0, false, false, false, false, 5)
		end)
    end
end

function closedialog()
	wait(250)
	sampCloseCurrentDialogWithButton(0)
	wait(250)
	sampCloseCurrentDialogWithButton(0)
end

function pressRawKey(id)
	rawKey = id
    sampForceOnfootSync()
end


function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local height = imgui.GetWindowHeight()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end


function apply_custom_style()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	style.WindowRounding = 5
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ChildWindowRounding = 5
	style.FrameRounding = 2.0
	style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
	style.ScrollbarSize = 13.0
	style.ScrollbarRounding = 0
	style.GrabMinSize = 8.0
	style.GrabRounding = 1.0
	style.WindowPadding = imgui.ImVec2(4.0, 4.0)
	style.FramePadding = imgui.ImVec2(2.5, 3.5)
	style.ButtonTextAlign = imgui.ImVec2(0.02, 0.4)
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg]               = imgui.ImColor(20, 20, 20, 255):GetVec4()
	colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.ComboBg]                = colors[clr.PopupBg]
	colors[clr.Border]                 = imgui.ImColor(40, 142, 110, 90):GetVec4()
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg]                = imgui.ImColor(40, 142, 110, 113):GetVec4()
	colors[clr.FrameBgHovered]         = imgui.ImColor(40, 142, 110, 164):GetVec4()
	colors[clr.FrameBgActive]          = imgui.ImColor(40, 142, 110, 255):GetVec4()
	colors[clr.TitleBg]                = imgui.ImColor(40, 142, 110, 236):GetVec4()
	colors[clr.TitleBgActive]          = imgui.ImColor(40, 142, 110, 236):GetVec4()
	colors[clr.TitleBgCollapsed]       = ImVec4(0.05, 0.05, 0.05, 0.79)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = imgui.ImColor(40, 142, 110, 236):GetVec4()
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.CheckMark]              = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.28, 0.28, 0.28, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.35, 0.35, 0.35, 1.00)
	colors[clr.Button]                 = imgui.ImColor(35, 35, 35, 255):GetVec4()
	colors[clr.ButtonHovered]          = imgui.ImColor(35, 121, 93, 174):GetVec4()
	colors[clr.ButtonActive]           = imgui.ImColor(44, 154, 119, 255):GetVec4()
	colors[clr.Header]                 = imgui.ImColor(40, 142, 110, 255):GetVec4()
	colors[clr.HeaderHovered]          = ImVec4(0.34, 0.34, 0.35, 0.89)
	colors[clr.HeaderActive]           = ImVec4(0.12, 0.12, 0.12, 0.94)
	colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.ResizeGrip]             = imgui.ImColor(40, 142, 110, 255):GetVec4()
	colors[clr.ResizeGripHovered]      = imgui.ImColor(35, 121, 93, 174):GetVec4()
	colors[clr.ResizeGripActive]       = imgui.ImColor(44, 154, 119, 255):GetVec4()
	colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
	colors[clr.ModalWindowDarkening]   = ImVec4(0.10, 0.10, 0.10, 0.35)
end
apply_custom_style()
