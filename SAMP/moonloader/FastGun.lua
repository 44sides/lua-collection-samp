script_name('Fast fsafe&getgun for ERP')
script_author('Franchesko & Vlad')
require("lib.moonloader")
local inicfg = require ('inicfg')
local imgui = require ("imgui")
imgui.HotKey = require('imgui_addons').HotKey
local encoding = require ('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8
local sampev = require ('samp.events')
local vkeys = require ('vkeys')
local rkeys = require ('rkeys')

safeNumbers = {}
safeGunsTD = {}
fsGunStatus = {}
inputFsafeCode = false
fhouseExist = false
fsClickExist = false

local main_window_state = imgui.ImBool(false)
local swidth, sheight = getScreenResolution()
local fsafe = false
local fslastd = false

local fgg = false
local arm = false
local ggak2 = 0
local ggm42 = 0
local ggde2 = 0
local ggri2 = 0
local ggsh2 = 0

local path_ini = '..\\config\\fsafe&getgun.ini'
local mainIni = inicfg.load({
	general = {
		m4key = encodeJson({VK_MENU,VK_1}),
		m4ammo = 75,
		dekey = encodeJson({VK_MENU,VK_2}),
		deammo = 15
	},
    fsafe = {      
		key = encodeJson({VK_M,VK_K}),
		code1 = 0,
		code2 = 1,
		code3 = 2,
		code4 = 3,
		ak = 0,
		m4 = 100,
		de = 30,
		ri = 0,
		sh = 5,
		delay = 100
    },
	getgun = {      
		key = encodeJson({VK_F11}),
		ak = 0,
		m4 = 2,
		de = 1,
		ri = 1,
		sh = 0,
		arm = true
    }
},path_ini)

function saveIniFile()
    local inicfgsaveparam = inicfg.save(mainIni,path_ini)
end
saveIniFile()

local m4key = {v = decodeJson(mainIni.general.m4key)}
local m4ammo = imgui.ImInt(mainIni.general.m4ammo)
local dekey = {v = decodeJson(mainIni.general.dekey)}
local deammo = imgui.ImInt(mainIni.general.deammo)

local fskey = {v = decodeJson(mainIni.fsafe.key)}
local fsdelay = imgui.ImInt(mainIni.fsafe.delay)
local code1 = imgui.ImInt(mainIni.fsafe.code1)
local code2 = imgui.ImInt(mainIni.fsafe.code2)
local code3 = imgui.ImInt(mainIni.fsafe.code3)
local code4 = imgui.ImInt(mainIni.fsafe.code4)
local fsakkol = imgui.ImInt(mainIni.fsafe.ak)
local fsm4kol = imgui.ImInt(mainIni.fsafe.m4)
local fsdekol = imgui.ImInt(mainIni.fsafe.de)
local fsrikol = imgui.ImInt(mainIni.fsafe.ri)
local fsshkol = imgui.ImInt(mainIni.fsafe.sh)

local ggkey = {v = decodeJson(mainIni.getgun.key)}
local ggakkol = imgui.ImInt(mainIni.getgun.ak)
local ggm4kol = imgui.ImInt(mainIni.getgun.m4)
local ggdekol = imgui.ImInt(mainIni.getgun.de)
local ggrikol = imgui.ImInt(mainIni.getgun.ri)
local ggshkol = imgui.ImInt(mainIni.getgun.sh)
local ggarm = imgui.ImBool(mainIni.getgun.arm)

function rkeys.onHotKey(id, keys)
    if isPauseMenuActive() or isSampfuncsConsoleActive() or sampIsChatInputActive() or sampIsDialogActive() then
        return false
    end
end

function fsafe_activation()
	sampSendChat("/fsafe")
	fclick = true
	nextFsGun = false
	fsGunStatus = {["1"] = false, ["2"] = false, ["3"] = false, ["4"] = false, ["5"] = false, ["6"] = false, ["7"] = false} -- DE, SD, M4, AK, SHOT, MP5, RIFLE
	fsGunAmount = {["1"] = mainIni.fsafe.de, ["2"] = 0, ["3"] = mainIni.fsafe.m4, ["4"] = mainIni.fsafe.ak, ["5"] = mainIni.fsafe.sh, ["6"] = 0, ["7"] = mainIni.fsafe.ri}
	fsafe = true
end

function getgun_activation()
	sampSendChat("/healme")
	fgg = true
	arm = true
	ggak2 = mainIni.getgun.ak
	ggm42 = mainIni.getgun.m4
	ggde2 = mainIni.getgun.de
	ggri2 = mainIni.getgun.ri
	ggsh2 = mainIni.getgun.sh
	wait(1000)
	sampSendChat("/getgun")
end

function mde_activation(num)
	ammo = tonumber(num)
	if not ammo or ammo > 200 then printStringNow("~r~Up to x200", 500) return end
	de = true
	sampSendChat("/mystorage")
	printStringNow("Deagle x"..ammo.." ...", 500)
end
function mm4_activation(num)
	ammo = tonumber(num)
	if not ammo or ammo > 200 then printStringNow("~r~Up to x200", 500) return end
	m4 = true
	sampSendChat("/mystorage")
	printStringNow("M4 x"..ammo.." ...", 500)
end
function mri_activation(num)
	ammo = tonumber(num)
	if not ammo or ammo > 200 then printStringNow("~r~Up to x200", 500) return end
	ri = true
	sampSendChat("/mystorage")
	printStringNow("Rifle x"..ammo.." ...", 500)
end
function msh_activation(num)
	ammo = tonumber(num)
	if not ammo or ammo > 200 then printStringNow("~r~Up to x200", 500) return end
	sh = true
	sampSendChat("/mystorage")
	printStringNow("Shotgun x"..ammo.." ...", 500)
end

function fm4ak_activation(args)
	local arg1, arg2 = args:match("^(.+)%s(.+)$")
	ammo, fmove_delay = tonumber(arg1), tonumber(arg2)
	if fm4ak then
		sampAddChatMessage("{f83e3e}[fsafe&getgun] {ffffff}Перенос оружия отменен", -1)
		fmoveprocess, ffirsttake, fsecondtake, fsecondput = false, false, false, false
		fm4ak = false
		return
	elseif not ammo or not fmove_delay then
		sampAddChatMessage("{f83e3e}[fsafe&getgun] {ffffff}/fm4ak <количество> <задержка> (def. 3000)", -1)
		return
	end
	fm4ak = true
	sampAddChatMessage("{f83e3e}[fsafe&getgun] {ffffff}M4 ("..ammo.."пт) -> AK активировано с задержкой "..fmove_delay.."мс. Введите /fsafe", -1)
end

function fakm4_activation(args)
	local arg1, arg2 = args:match("^(.+)%s(.+)$")
	ammo, fmove_delay = tonumber(arg1), tonumber(arg2)
	if fakm4 then
		sampAddChatMessage("{f83e3e}[fsafe&getgun] {ffffff}Перенос оружия отменен", -1)
		fmoveprocess, ffirsttake, fsecondtake, fsecondput = false, false, false, false
		fakm4 = false
		return
	elseif not ammo or not fmove_delay then
		sampAddChatMessage("{f83e3e}[fsafe&getgun] {ffffff}/fakm4 <количество> <задержка> (def. 3000)", -1)
		return
	end
	fakm4 = true
	sampAddChatMessage("{f83e3e}[fsafe&getgun] {ffffff}AK ("..ammo.."пт) -> M4 активировано с задержкой "..fmove_delay.."мс. Введите /fsafe", -1)
end

function m4_activation()
	ammo = mainIni.general.m4ammo
	if not ammo or ammo > 200 then printStringNow("~r~Up to x200", 500) return end
	m4 = true
	sampSendChat("/mystorage")
	printStringNow("M4 x"..ammo.." ...", 500)
end
function de_activation()
	ammo = mainIni.general.deammo
	if not ammo or ammo > 200 then printStringNow("~r~Up to x200", 500) return end
	de = true
	sampSendChat("/mystorage")
	printStringNow("Deagle x"..ammo.." ...", 500)
end


function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
	sampRegisterChatCommand("fgg", function() main_window_state.v = not main_window_state.v end)
	
	sampRegisterChatCommand("mde", mde_activation)
	sampRegisterChatCommand("mm4", mm4_activation)
	sampRegisterChatCommand("mri", mri_activation)
	sampRegisterChatCommand("msh", msh_activation)
	
	sampRegisterChatCommand("fm4ak", fm4ak_activation)
	sampRegisterChatCommand("fakm4", fakm4_activation)
	
	fskeyRegId = rkeys.registerHotKey(fskey.v, 1, fsafe_activation)
	ggkeyRegId = rkeys.registerHotKey(ggkey.v, 1, getgun_activation)
	
	m4keyRegId = rkeys.registerHotKey(m4key.v, 1, m4_activation)
	dekeyRegId = rkeys.registerHotKey(dekey.v, 1, de_activation)

    addEventHandler("onWindowMessage", function (msg, wparam, lparam) -- закрытие окна на ESC
		if (msg == 256 or msg == 257) and wparam == vkeys.VK_ESCAPE and imgui.Process and not isPauseMenuActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and not sampIsChatInputActive() then
			consumeWindowMessage(true, false)
			if msg == 257 then
				main_window_state.v = false
			end
		end
	end)

    while true do
        wait(0)
		imgui.Process = main_window_state.v
		if (fsafe or fm4ak or fakm4) and inputFsafeCode then
			wait(mainIni.fsafe.delay)
			sampSendClickTextdraw(safeNumbers[tostring(mainIni.fsafe.code1)])
			wait(mainIni.fsafe.delay)
			sampSendClickTextdraw(safeNumbers[tostring(mainIni.fsafe.code2)])
			wait(mainIni.fsafe.delay)
			sampSendClickTextdraw(safeNumbers[tostring(mainIni.fsafe.code3)])
			wait(mainIni.fsafe.delay)
			sampSendClickTextdraw(safeNumbers[tostring(mainIni.fsafe.code4)])
			wait(mainIni.fsafe.delay)
			sampSendClickTextdraw(safeNumbers["Enter"])
			inputFsafeCode = false
		end
		if fsClickExist then
			for i = 1, 7 do
				if fsGunStatus[tostring(i)] and fclick then
					nextFsGun = false
					fsTakeAmount = fsGunAmount[tostring(i)]
					fsGunStatus[tostring(i)] = false
					sampSendClickTextdraw(safeGunsTD[tostring(i)])
					wait(mainIni.fsafe.delay)
					sampSendClickTextdraw(safeGunsTD["Take"])
					while not nextFsGun do wait(0) end
				end
				if i == 7 then
					fclick = false
					fsClickExist = false
				end
			end
		end
    end
end


function imgui.OnDrawFrame()
    if main_window_state.v then 
        imgui.SetNextWindowPos(imgui.ImVec2(swidth / 2, sheight / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(450, 535), imgui.Cond.FirstUseEver)
		imgui.Begin("Fast fsafe&getgun for ERP", main_window_state, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        imgui.Separator()
        imgui.SetCursorPosX((450 - imgui.CalcTextSize('mystorage (/mde /mm4 /mri /msh)').x) / 2)
		imgui.Text(u8"mystorage (/mde /mm4 /mri /msh)")
		imgui.Separator()
		imgui.Text(u8"Mystorage M4: ")
		imgui.SameLine()
		if imgui.HotKey("##m4key", m4key) then
			mainIni.general.m4key = encodeJson(m4key.v)
			rkeys.changeHotKey(m4keyRegId, m4key.v)
			saveIniFile()
		end
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt("##m4ammo", m4ammo) then
			mainIni.general.m4ammo = tonumber(m4ammo.v)
			saveIniFile()
		end
        imgui.PopItemWidth()
	
		imgui.Text(u8"Mystorage Deagle: ")
		imgui.SameLine()
		if imgui.HotKey("##dekey", dekey) then
			mainIni.general.dekey = encodeJson(dekey.v)
			rkeys.changeHotKey(dekeyRegId, dekey.v)
			saveIniFile()
		end
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt("##deammo", deammo) then
			mainIni.general.deammo = tonumber(deammo.v)
			saveIniFile()
		end
        imgui.PopItemWidth()
	
        imgui.Separator()
        imgui.SetCursorPosX((450 - imgui.CalcTextSize('fsafe (/fakm4 /fm4ak)').x) / 2)
		imgui.Text(u8"fsafe (/fakm4 /fm4ak)")
		imgui.Separator()
		imgui.Text(u8"Код клавиши активации: ")
		imgui.SameLine()
		if imgui.HotKey("##fskey", fskey) then
			mainIni.fsafe.key = encodeJson(fskey.v)
			rkeys.changeHotKey(fskeyRegId, fskey.v)
			saveIniFile()
		end
		imgui.Text(u8"Пин-код сейфа: ")
		imgui.SameLine()
		imgui.PushItemWidth(15)
        if imgui.InputInt(u8"##code1", code1, 0, 0) then
			mainIni.fsafe.code1 = tonumber(code1.v)
			saveIniFile()
        end
		imgui.SameLine()
		if imgui.InputInt(u8"##code2", code2, 0, 0) then
			mainIni.fsafe.code2 = tonumber(code2.v)
			saveIniFile()
        end
		imgui.SameLine()
		if imgui.InputInt(u8"##code3", code3, 0, 0) then
			mainIni.fsafe.code3 = tonumber(code3.v)
			saveIniFile()
        end
		imgui.SameLine()
		if imgui.InputInt(u8"##code4", code4, 0, 0) then
			mainIni.fsafe.code4 = tonumber(code4.v)
			saveIniFile()
        end
        imgui.PopItemWidth()
		imgui.Text(u8"Количество патронов АК (0 для отключения): ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##fsakkol", fsakkol) then
			mainIni.fsafe.ak = tonumber(fsakkol.v)
			saveIniFile()
		end
        imgui.PopItemWidth()
		imgui.Text(u8"Количество патронов M4 (0 для отключения): ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##fsm4kol", fsm4kol) then
			mainIni.fsafe.m4 = tonumber(fsm4kol.v)
			saveIniFile()
        end
        imgui.PopItemWidth()
		imgui.Text(u8"Количество патронов Deagle (0 для отключения): ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##fsdekol", fsdekol) then
			mainIni.fsafe.de = tonumber(fsdekol.v)
			saveIniFile()
        end
        imgui.PopItemWidth()
		imgui.Text(u8"Количество патронов Rifle (0 для отключения): ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##fsrikol", fsrikol) then
			mainIni.fsafe.ri = tonumber(fsrikol.v)
			saveIniFile()
        end
        imgui.PopItemWidth()
		imgui.Text(u8"Количество патронов Shotgun (0 для отключения): ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##fsshkol", fsshkol) then
			mainIni.fsafe.sh = tonumber(fsshkol.v)
			saveIniFile()
        end
        imgui.PopItemWidth()
		imgui.Text(u8"Задержка: ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##fsdelay", fsdelay, 50) then
			mainIni.fsafe.delay = tonumber(fsdelay.v)
			saveIniFile()
        end
        imgui.PopItemWidth()
		
		imgui.Separator()
		imgui.SetCursorPosX((450 - imgui.CalcTextSize('getgun').x) / 2)
		imgui.Text(u8"getgun")
		imgui.Separator()
		imgui.Text(u8"Код клавиши активации: ")
		imgui.SameLine()
		imgui.PushItemWidth(80)
		if imgui.HotKey("##ggkey", ggkey) then
			mainIni.getgun.key = encodeJson(ggkey.v)
			rkeys.changeHotKey(ggkeyRegId, ggkey.v)
			saveIniFile()
		end
        imgui.PopItemWidth()
		imgui.Text(u8"Сколько раз брать АК (0 для отключения): ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##ggakkol", ggakkol) then
			mainIni.getgun.ak = tonumber(ggakkol.v)
			ggak2 = tonumber(ggakkol.v)
			saveIniFile()
		end
        imgui.PopItemWidth()
		imgui.Text(u8"Сколько раз брать M4 (0 для отключения): ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##ggm4kol", ggm4kol) then
			mainIni.getgun.m4 = tonumber(ggm4kol.v)
			ggm42 = tonumber(ggm4kol.v)
			saveIniFile()
        end
        imgui.PopItemWidth()
		imgui.Text(u8"Сколько раз брать Deagle (0 для отключения): ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##ggdekol", ggdekol) then
			mainIni.getgun.de = tonumber(ggdekol.v)
			ggde2 = tonumber(ggdekol.v)
			saveIniFile()
        end
        imgui.PopItemWidth()
		imgui.Text(u8"Сколько раз брать Rifle (0 для отключения): ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##ggrikol", ggrikol) then
			mainIni.getgun.ri = tonumber(ggrikol.v)
			ggri2 = tonumber(ggrikol.v)
			saveIniFile()
        end
        imgui.PopItemWidth()
		imgui.Text(u8"Сколько раз брать Shotgun (0 для отключения): ")
		imgui.SameLine()
		imgui.PushItemWidth(100)
        if imgui.InputInt(u8"##ggshkol", ggshkol) then
			mainIni.getgun.sh = tonumber(ggshkol.v)
			ggsh2 = tonumber(ggshkol.v)
			saveIniFile()
        end
        imgui.PopItemWidth()
		if imgui.Checkbox(u8"Брать броню", ggarm) then
			mainIni.getgun.arm = ggarm.v
			saveIniFile()
        end
		imgui.End()
    end
end


function closedialog()
    wait(250)
	sampCloseCurrentDialogWithButton(0)
	wait(250)
	sampCloseCurrentDialogWithButton(0)
end

function sampev.onShowDialog(dialogId, dialogStyle, dialogTitle, okButtonText, cancelButtonText, dialogText)
	if dialogTitle:find("%{......%}Сейф | %{......%}Взять") and fsafe then
		sampSendDialogResponse(dialogId, 1, _, fsTakeAmount)
		fsTakeAmount = false
		nextFsGun = true
		return false
	end
	
	if dialogId == 6053 and fslastd then
		fslastd = false
		fsafe = false
		lua_thread.create(closedialog)
    end
	
	if dialogTitle:find("%{......%}Сейф | %{......%}Взять") and (fm4ak or fakm4) and not ffirsttake then
		ffirsttake = true
		sampSendDialogResponse(dialogId, 1, _, ammotakeput)
		return false
	elseif dialogTitle:find("%{......%}Сейф | %{......%}Взять") and (fm4ak or fakm4) and not fsecondtake then
		fsecondtake = true
		sampSendDialogResponse(dialogId, 1, _, ammotakeput)
		return false
	elseif dialogTitle:find("%{......%}Сейф | %{......%}Положить") and (fm4ak or fakm4) and not fsecondput then
		fmoveprocess, ffirsttake, fsecondtake, fsecondput = false, false, false, false
		sampSendDialogResponse(dialogId, 1, _, ammotakeput)
		return false
	end
	
	if fgg then
        if dialogTitle:find("Взять оружие со склада .+") and (ggde2 > 0) then
            sampSendDialogResponse(dialogId, 1, 0, -1)
			ggde2 = ggde2 - 1
			return false
        end
		if dialogTitle:find("Взять оружие со склада .+") and (ggm42 > 0) then
            sampSendDialogResponse(dialogId, 1, 3, -1)
			ggm42 = ggm42 - 1
			return false
        end
		if dialogTitle:find("Взять оружие со склада .+") and (ggri2 > 0) then
            sampSendDialogResponse(dialogId, 1, 2, -1)
			ggri2 = ggri2 - 1
            return false
        end
		if dialogTitle:find("Взять оружие со склада .+") and (ggak2 > 0) then
            sampSendDialogResponse(dialogId, 1, 4, -1)
			ggak2 = ggak2 - 1
            return false
        end
		if dialogTitle:find("Взять оружие со склада .+") and (ggsh2 > 0) then
            sampSendDialogResponse(dialogId, 1, 1, -1)
			ggsh2 = ggsh2 - 1
            return false
        end
		if dialogTitle:find("Взять оружие со склада .+") and arm and mainIni.getgun.arm then
            sampSendDialogResponse(dialogId, 1, 7, -1)
			arm = false
            return false
		else
			arm = false
        end
		if dialogTitle:find("Взять оружие со склада .+") and not arm and (ggak2 == 0) and (ggm42 == 0) and (ggde2 == 0) and (ggri2 == 0) and (ggsh2 == 0) then
			fgg = false
			lua_thread.create(function()
				wait(200)
				sampCloseCurrentDialogWithButton(0)
			end)
		end
    end

	if dialogTitle:find("{FFFFFF}Хранилище | {AE433D}Предметы") and (m4 or de or ri or sh) then
		local num = -2
		for line in dialogText:gmatch('[^\n]+') do
			num = num + 1
			if (m4 and line:find('{FFFFFF}M4\t')) or (de and line:find('{FFFFFF}Deagle\t')) or (ri and line:find('{FFFFFF}Rifle\t')) or (sh and line:find('{FFFFFF}Shotgun\t')) then
				sampSendDialogResponse(dialogId, 1, num, -1)
				return false
			end
		end
		sampSendDialogResponse(dialogId, 0, nil, nil)
		m4, de, ri, sh = false
		printStringNow("~r~No item", 500)
		return false
	end
	if dialogTitle:find("{FFFFFF}Хранилище | {AE433D}Действие с предметом") and (m4 or de or ri or sh) then
		sampSendDialogResponse(dialogId, 1, 0, -1)
		return false
	end
	if dialogTitle:find("{FFFFFF} Хранилище | {AE433D}Забрать предмет") and (m4 or de or ri or sh) then
		sampSendDialogResponse(dialogId, 1, 0, ammo)
		m4, de, ri, sh = false
		return false
	end
end

function sampev.onServerMessage(color, text)
	if fsafe and string.find(text, "Вы должны находиться в привязанном к семье доме") and color == -1347440726 then
		fclick = false
		fsafe = false
	end
	if fsafe and string.find(text, "Семейный склад закрыт") or string.find(text, "Вы не можете взять со склада более") or string.find(text, "Недостаточно патронов") or string.find(text, "Ваша семья не приобрела улучшение") then
		fclick = false
		fsafe = false
		fsak = false
		sfm4 = false
		sfde = false
		fsri = false
		fssh = false
		return true
	end
	if fgg and string.find(text, "Склад закрыт") then
		fgg = false
		arm = false
		return true
	end

	if fsafe and (text:find("Пин%-код не совпал") or text:find('Не флуди!')) and color == -858993409 then
		lua_thread.create(function()
			wait(500)
			inputFsafeCode = true
			sampSendChat("/fsafe")
		end)
    end

	if fsafe and text:find("Вы далеко от сейфа") and color == -86 then
		fsafe = false
		inputFsafeCode = false
		fclick = false
	end
	
	if (m4 or de or ri or sh) and (text:find("^ Хранилище пустое$") or text:find('^ Не флуди!$')) then
		m4, de, ri, sh = false
	end
	
	if (fm4ak or fakm4) and (text:find("^ Слишком быстро, подождите$") or text:find("^ В инвентарь не поместится столько патронов") or text:find("^ До полной заполненности необходимо") or text:find("^ В сейфе нет столько") or text:find("^ Некорректно введено значение")) then
		sampAddChatMessage("{f83e3e}[fsafe&getgun] {ffffff}Перенос оружия отменен", -1)
		fmoveprocess, ffirsttake, fsecondtake, fsecondput = false, false, false, false
		fm4ak, fakm4 = false
	end
end

function safeItemAction(num, item, action, delay)
	ammotakeput = num
	sampSendClickTextdraw(item)
	wait(delay)
	if action == 0 then sampSendClickTextdraw(safeGunsTD["Take"]) else sampSendClickTextdraw(safeGunsTD["Take"] + 2) end 
end

function sampev.onShowTextDraw(id, data)
    if data.text:find("1____2____3") and (fsafe or fm4ak or fakm4) then
        safeNumbers["1"] = id + 11
        safeNumbers["2"] = id + 12
        safeNumbers["3"] = id + 13
        safeNumbers["4"] = id + 14
        safeNumbers["5"] = id + 15
        safeNumbers["6"] = id + 16
        safeNumbers["7"] = id + 17
        safeNumbers["8"] = id + 18
        safeNumbers["9"] = id + 19
        safeNumbers["0"] = id + 21
        safeNumbers["Enter"] = id + 22
		inputFsafeCode = true
    end
	
	if data.modelId == 348 and (fsafe or fm4ak or fakm4) then
		safeGunsTD["1"] = id -- de
		safeGunsTD["2"] = id + 3 -- sd
		safeGunsTD["3"] = id + 6 -- m4
		safeGunsTD["4"] = id + 9 -- ak
		safeGunsTD["5"] = id + 12 -- shot
		safeGunsTD["6"] = id + 15 -- mp5
		safeGunsTD["7"] = id + 18 -- rifle
		safeGunsTD["Take"] = id + 40
	end
	
	if safeGunsTD["3"] and id == (safeGunsTD["3"] - 2) and fm4ak and not fmoveprocess then
		if tonumber(data.text:sub(1, 4)) > 0 and ammo > 0 then
			if ammo >= 199 then ammo_safe = 199 else ammo_safe = ammo end
			ammo = ammo - ammo_safe
			fmoveprocess = true
		else
			fm4ak = false
			sampAddChatMessage("{f83e3e}[fsafe&getgun] {ffffff}Перенос оружия выполнен", -1)
		end
	end
	if safeGunsTD["4"] and id == (safeGunsTD["4"] - 2) and fakm4 and not fmoveprocess then
		if tonumber(data.text:sub(1, 4)) > 0 and ammo > 0 then
			if ammo >= 199 then ammo_safe = 199 else ammo_safe = ammo end
			ammo = ammo - ammo_safe
			fmoveprocess = true
		else
			fakm4 = false
			sampAddChatMessage("{f83e3e}[fsafe&getgun] {ffffff}Перенос оружия выполнен", -1)
		end
	end
	
	--брать ган по иду моделей
	if data.text:find("TAKE") and fsafe then
		if mainIni.fsafe.de > 0 then
			fsGunStatus["1"] = true
		end
		if mainIni.fsafe.m4 > 0 then
			fsGunStatus["3"] = true
		end
		if mainIni.fsafe.ak > 0 then
			fsGunStatus["4"] = true
		end		
		if mainIni.fsafe.sh > 0 then
			fsGunStatus["5"] = true
		end
		if mainIni.fsafe.ri > 0 then
			fsGunStatus["7"] = true
		end
		fsClickExist = true
		if fclick == false and fsafe then
			sampSendClickTextdraw(65535)
			fsafe = false
		end
	end
	
	if not safeItemAction_thread or safeItemAction_thread:status() == 'dead' then
		if data.text:find("TAKE") and fm4ak and not ffirsttake then
			safeItemAction_thread = lua_thread.create(safeItemAction, ammo_safe, safeGunsTD["3"], 0, 100)
		elseif data.text:find("TAKE") and fm4ak and not fsecondtake then
			safeItemAction_thread = lua_thread.create(safeItemAction, 1, safeGunsTD["4"], 0, fmove_delay)
		elseif data.text:find("TAKE") and fm4ak and not fsecondput then
			safeItemAction_thread = lua_thread.create(safeItemAction, ammo_safe + 1, safeGunsTD["4"], 1, 100)
		end
		if data.text:find("TAKE") and fakm4 and not ffirsttake then
			safeItemAction_thread = lua_thread.create(safeItemAction, ammo_safe, safeGunsTD["4"], 0, 100)
		elseif data.text:find("TAKE") and fakm4 and not fsecondtake then
			safeItemAction_thread = lua_thread.create(safeItemAction, 1, safeGunsTD["3"], 0, fmove_delay)
		elseif data.text:find("TAKE") and fakm4 and not fsecondput then
			safeItemAction_thread = lua_thread.create(safeItemAction, ammo_safe + 1, safeGunsTD["3"], 1, 100)
		end
	end
end

function apply_custom_style()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	style.WindowRounding = 1.5
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ChildWindowRounding = 1.5
	style.FrameRounding = 1.0
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

function getParseTable(n)
    local t = {}
    local n = tostring(n)
    for i = 1, #n do
        t[#t + 1] = n:sub(i, i)
    end
    return t
end