script_name("Trade Analytics Studio")
script_author("dev_alex")
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
local SCRIPT_VERSION = 10
local SCRIPT_URL = "https://raw.githubusercontent.com/sanya-developer111/modluasamp/refs/heads/main/mod.lua"

local update_checking = false

-- ============================ [ НАСТРОЙКИ АВТОМАТИКИ (разработчик задает) ] ============================
local auto_check_update_on_start = true   -- Авто проверка обновлений при старте игры
local auto_rep_report = false             -- Авто /rep, /report
local auto_q_command = false              -- Авто ввод /q при открытии чата клавишами F6 или T

-- ============================ [ ТЕМЫ ИНТЕРФЕЙСА ] ============================
local current_theme = 1
-- 1 = Dark Blue Modern
-- 2 = Purple Neon
-- 3 = Ocean Blue

local function apply_theme(theme_id)
    theme_id = math.max(1, math.min(3, theme_id or 1))
    current_theme = theme_id
    
    local style = imgui.GetStyle()
    local colors = style.Colors
    
    -- Общие стили
    style.WindowRounding = 12.0
    style.FrameRounding = 8.0
    style.ChildRounding = 10.0
    style.PopupRounding = 8.0
    style.ScrollbarRounding = 9.0
    style.GrabRounding = 6.0
    style.WindowBorderSize = 0.0
    style.FrameBorderSize = 0.0
    style.TabRounding = 8.0
    
    if theme_id == 1 then
        -- Dark Blue Modern
        colors[imgui.Col.WindowBg]              = imgui.ImVec4(0.07, 0.09, 0.13, 0.98)
        colors[imgui.Col.TitleBg]               = imgui.ImVec4(0.09, 0.15, 0.25, 1.00)
        colors[imgui.Col.TitleBgActive]         = imgui.ImVec4(0.12, 0.28, 0.55, 1.00)
        colors[imgui.Col.FrameBg]               = imgui.ImVec4(0.12, 0.16, 0.24, 1.00)
        colors[imgui.Col.FrameBgHovered]        = imgui.ImVec4(0.16, 0.22, 0.32, 1.00)
        colors[imgui.Col.FrameBgActive]         = imgui.ImVec4(0.18, 0.26, 0.40, 1.00)
        colors[imgui.Col.Button]                = imgui.ImVec4(0.16, 0.34, 0.65, 1.00)
        colors[imgui.Col.ButtonHovered]         = imgui.ImVec4(0.22, 0.45, 0.80, 1.00)
        colors[imgui.Col.ButtonActive]          = imgui.ImVec4(0.13, 0.28, 0.55, 1.00)
        colors[imgui.Col.Text]                  = imgui.ImVec4(0.95, 0.97, 1.00, 1.00)
        colors[imgui.Col.TextDisabled]          = imgui.ImVec4(0.55, 0.60, 0.65, 1.00)
        colors[imgui.Col.Header]                = imgui.ImVec4(0.16, 0.34, 0.65, 0.85)
        colors[imgui.Col.HeaderHovered]         = imgui.ImVec4(0.22, 0.45, 0.80, 0.90)
        colors[imgui.Col.HeaderActive]          = imgui.ImVec4(0.13, 0.28, 0.55, 0.95)
        colors[imgui.Col.Separator]             = imgui.ImVec4(0.16, 0.34, 0.65, 0.50)
        colors[imgui.Col.ChildBg]               = imgui.ImVec4(0.05, 0.07, 0.10, 1.00)
        colors[imgui.Col.Tab]                   = imgui.ImVec4(0.12, 0.16, 0.24, 1.00)
        colors[imgui.Col.TabHovered]            = imgui.ImVec4(0.16, 0.34, 0.65, 1.00)
        colors[imgui.Col.TabActive]             = imgui.ImVec4(0.16, 0.34, 0.65, 1.00)
        colors[imgui.Col.TabUnfocused]          = imgui.ImVec4(0.10, 0.13, 0.18, 1.00)
        colors[imgui.Col.TabUnfocusedActive]    = imgui.ImVec4(0.14, 0.20, 0.28, 1.00)
        
    elseif theme_id == 2 then
        -- Purple Neon
        colors[imgui.Col.WindowBg]              = imgui.ImVec4(0.08, 0.06, 0.12, 0.98)
        colors[imgui.Col.TitleBg]               = imgui.ImVec4(0.18, 0.10, 0.30, 1.00)
        colors[imgui.Col.TitleBgActive]         = imgui.ImVec4(0.35, 0.15, 0.60, 1.00)
        colors[imgui.Col.FrameBg]               = imgui.ImVec4(0.15, 0.12, 0.22, 1.00)
        colors[imgui.Col.FrameBgHovered]        = imgui.ImVec4(0.22, 0.18, 0.32, 1.00)
        colors[imgui.Col.FrameBgActive]         = imgui.ImVec4(0.28, 0.22, 0.42, 1.00)
        colors[imgui.Col.Button]                = imgui.ImVec4(0.45, 0.20, 0.85, 1.00)
        colors[imgui.Col.ButtonHovered]         = imgui.ImVec4(0.55, 0.25, 0.95, 1.00)
        colors[imgui.Col.ButtonActive]          = imgui.ImVec4(0.35, 0.15, 0.70, 1.00)
        colors[imgui.Col.Text]                  = imgui.ImVec4(0.98, 0.96, 1.00, 1.00)
        colors[imgui.Col.Header]                = imgui.ImVec4(0.45, 0.20, 0.85, 0.85)
        colors[imgui.Col.HeaderHovered]         = imgui.ImVec4(0.55, 0.25, 0.95, 0.90)
        colors[imgui.Col.HeaderActive]          = imgui.ImVec4(0.35, 0.15, 0.70, 0.95)
        colors[imgui.Col.Separator]             = imgui.ImVec4(0.45, 0.20, 0.85, 0.50)
        colors[imgui.Col.ChildBg]               = imgui.ImVec4(0.06, 0.04, 0.10, 1.00)
        
    elseif theme_id == 3 then
        -- Ocean Blue
        colors[imgui.Col.WindowBg]              = imgui.ImVec4(0.05, 0.10, 0.15, 0.98)
        colors[imgui.Col.TitleBg]               = imgui.ImVec4(0.06, 0.18, 0.28, 1.00)
        colors[imgui.Col.TitleBgActive]         = imgui.ImVec4(0.08, 0.35, 0.55, 1.00)
        colors[imgui.Col.FrameBg]               = imgui.ImVec4(0.08, 0.14, 0.20, 1.00)
        colors[imgui.Col.FrameBgHovered]        = imgui.ImVec4(0.12, 0.20, 0.28, 1.00)
        colors[imgui.Col.FrameBgActive]         = imgui.ImVec4(0.14, 0.24, 0.36, 1.00)
        colors[imgui.Col.Button]                = imgui.ImVec4(0.10, 0.45, 0.75, 1.00)
        colors[imgui.Col.ButtonHovered]         = imgui.ImVec4(0.16, 0.55, 0.85, 1.00)
        colors[imgui.Col.ButtonActive]          = imgui.ImVec4(0.08, 0.35, 0.60, 1.00)
        colors[imgui.Col.Text]                  = imgui.ImVec4(0.92, 0.96, 1.00, 1.00)
        colors[imgui.Col.Header]                = imgui.ImVec4(0.10, 0.45, 0.75, 0.85)
        colors[imgui.Col.HeaderHovered]         = imgui.ImVec4(0.16, 0.55, 0.85, 0.90)
        colors[imgui.Col.HeaderActive]          = imgui.ImVec4(0.08, 0.35, 0.60, 0.95)
        colors[imgui.Col.Separator]             = imgui.ImVec4(0.10, 0.45, 0.75, 0.50)
        colors[imgui.Col.ChildBg]               = imgui.ImVec4(0.04, 0.08, 0.12, 1.00)
    end
end

apply_theme(current_theme)

-- ============================ [ GUI VARIABLES ] ============================
local renderMenu = imgui.bool(false)
local current_tab = 1 -- 1 = Средние цены, 2 = Настройки

-- Флаг для авто-репорта
local waitingForReport = false

-- ============================ [ ИНИЦИАЛИЗАЦИЯ IMGUI ] ============================
imgui.OnInitialize(function()
    -- тема уже применена при загрузке
end)

-- ============================ [ ОТРИСОВКА МЕНЮ ] ============================
local function draw_main_menu()
    if imgui.Begin(u8"Trade Analytics Studio", renderMenu, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.AlwaysAutoResize)) then
        
        -- Вкладки
        if imgui.BeginTabBar("##main_tabs", imgui.TabBarFlags.None) then
            
            -- Tab 1: Средние цены
            if imgui.BeginTabItem(u8"Средние цены") then
                current_tab = 1
                imgui.Text(u8"Информация о средних ценах ресурсов:")
                imgui.Separator()
                imgui.Spacing()
                
                imgui.PushStyleColor(imgui.Col.ChildBg, imgui.GetStyle().Colors[imgui.Col.ChildBg])
                if imgui.BeginChild("PricesList", imgui.ImVec2(0, 180), true) then
                    imgui.Text(u8"Лен:  3000 $ за шт.")
                    imgui.Text(u8"Нефть:  5000 $ за баррель")
                    imgui.Text(u8"Сталь:  1200 $ за кг.")
                    imgui.Text(u8"Древесина:  800 $ за ед.")
                    imgui.Text(u8"Металл:  2000 $ за кг.")
                    imgui.EndChild()
                end
                imgui.PopStyleColor()
                
                imgui.EndTabItem()
            end
            
            -- Tab 2: Настройки
            if imgui.BeginTabItem(u8"Настройки") then
                current_tab = 2
                imgui.Text(u8"Настройки скрипта")
                imgui.Separator()
                imgui.Spacing()
                
                -- Смена темы
                imgui.Text(u8"Тема интерфейса:")
                imgui.SameLine()
                local themes_list = {u8"Dark Blue Modern", u8"Purple Neon", u8"Ocean Blue"}
                local combo_val = current_theme - 1
                if imgui.Combo("##theme_combo", combo_val, themes_list, #themes_list) then
                    current_theme = combo_val + 1
                end
                imgui.SameLine()
                if imgui.Button(u8"Применить", imgui.ImVec2(120, 0)) then
                    apply_theme(current_theme)
                end
                
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()
                
                imgui.TextDisabled(u8"Примечание: автоматические функции (авто-обновление, авто-/rep, авто-/q) управляются только в коде разработчиком.")
                
                imgui.EndTabItem()
            end
            
            imgui.EndTabBar()
        end
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        if imgui.Button(u8"Закрыть меню", imgui.ImVec2(-1, 35)) then
            renderMenu[0] = false
        end
        
        imgui.End()
    end
end

imgui.OnFrame(function() return renderMenu[0] end, draw_main_menu)

-- ============================ [ ОСНОВНОЙ ЦИКЛ ] ============================
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    
    -- Авто проверка обновлений при старте, если включено
    if auto_check_update_on_start then
        checkUpdate()
    end
    
    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Скрипт загружен! Версия: " .. SCRIPT_VERSION, -1)
    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}F5 - меню | F6 или T - авто /q (если включено) | Ctrl+F5 - проверить обновления", -1)
    
    while true do
        wait(0)
        
        -- Открыть/закрыть меню F5
        if isKeyJustPressed(vkeys.VK_F5) and not isKeyDown(vkeys.VK_CONTROL) and not sampIsChatInputActive() and not sampIsDialogActive() then
            renderMenu[0] = not renderMenu[0]
        end
        
        -- Ручная проверка обновлений Ctrl+F5
        if isKeyDown(vkeys.VK_CONTROL) and isKeyJustPressed(vkeys.VK_F5) then
            sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Проверка обновлений...", -1)
            checkUpdate()
        end
        
        -- Авто /q при открытии чата клавишами F6 или T
        if auto_q_command then
            if sampIsChatInputActive() then
                -- Нажатие F6
                if isKeyJustPressed(vkeys.VK_F6) then
                    lua_thread.create(function()
                        wait(10)
                        -- Установить текст /q и отправить
                        sampSetCurrentChatText("/q")
                        wait(60)
                        sampSendChat("/q")
                    end)
                end
                -- Нажатие T (но не если зажаты Ctrl/Alt)
                if isKeyJustPressed(vkeys.VK_T) and not isKeyDown(vkeys.VK_LCONTROL) and not isKeyDown(vkeys.VK_RCONTROL) and not isKeyDown(vkeys.VK_LMENU) and not isKeyDown(vkeys.VK_RMENU) then
                    lua_thread.create(function()
                        wait(10)
                        sampSetCurrentChatText("/q")
                        wait(60)
                        sampSendChat("/q")
                    end)
                end
            end
        end
    end
end

-- ============================ [ ОБРАБОТКА КОМАНД И ДИАЛОГОВ ] ============================
function sampev.onSendCommand(cmd)
    if auto_rep_report then
        if cmd:lower():sub(1, 4) == "/rep" then
            waitingForReport = true
        end
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if auto_rep_report and waitingForReport and (style == 1 or style == 3) then
        waitingForReport = false
        lua_thread.create(function()
            wait(100)
            sampSetCurrentDialogEditboxText("вы чмони, сосо")
            wait(50)
            sampCloseCurrentDialogWithButton(1)
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
                        sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Найдена новая версия (" .. remote_ver .. "). Установка...", -1)
                        
                        local decoded_content = u8:decode(content)
                        local main_script_path = thisScript().path
                        local script_file = io.open(main_script_path, "wb")
                        if script_file then
                            script_file:write(decoded_content)
                            script_file:close()
                        end
                        os.remove(temp_path)
                        sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Обновление завершено! Скрипт перезагружен.", -1)
                        thisScript():reload()
                    else
                        sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Установлена актуальная версия.", -1)
                        os.remove(temp_path)
                    end
                else
                    os.remove(temp_path)
                end
            end
            update_checking = false
        elseif status == dlstatus.STATUS_ERRORDOWNLOADDATA then
            sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Ошибка соединения с сервером обновлений.", -1)
            update_checking = false
        end
    end)
end
