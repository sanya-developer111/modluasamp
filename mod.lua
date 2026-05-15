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
local SCRIPT_VERSION = 12
local SCRIPT_URL = "https://raw.githubusercontent.com/sanya-developer111/modluasamp/refs/heads/main/mod.lua"
local update_checking = false
-- ==================================================================================

local renderMenu = imgui.new.bool(false)
local waitingForReport = false
local currentTab = 0 -- 0 = Средние цены, 1 = Настройки
local currentTheme = 0 -- 0 = Dark Navy, 1 = Emerald, 2 = Crimson
local quickQuitRunning = false

-- ============================ [ ТЕМЫ ] ============================
local themes = {
    [0] = {
        name = u8"🌑 Dark Navy",
        WindowBg        = imgui.ImVec4(0.05, 0.08, 0.12, 0.97),
        TitleBg         = imgui.ImVec4(0.08, 0.20, 0.38, 1.00),
        TitleBgActive   = imgui.ImVec4(0.12, 0.35, 0.65, 1.00),
        FrameBg         = imgui.ImVec4(0.10, 0.15, 0.25, 1.00),
        Button          = imgui.ImVec4(0.15, 0.40, 0.75, 1.00),
        ButtonHovered   = imgui.ImVec4(0.25, 0.55, 0.90, 1.00),
        ButtonActive    = imgui.ImVec4(0.10, 0.30, 0.60, 1.00),
        Text            = imgui.ImVec4(0.95, 0.97, 1.00, 1.00),
        Separator       = imgui.ImVec4(0.15, 0.40, 0.75, 0.50),
        ChildBg         = imgui.ImVec4(0.08, 0.12, 0.18, 1.00),
        TabActive       = imgui.ImVec4(0.15, 0.40, 0.75, 1.00),
        TabInactive     = imgui.ImVec4(0.08, 0.15, 0.28, 1.00),
        TabText         = imgui.ImVec4(0.95, 0.97, 1.00, 1.00),
        TabTextInactive = imgui.ImVec4(0.55, 0.65, 0.80, 1.00),
        Accent          = imgui.ImVec4(0.3, 0.8, 1.0, 1.0),
        HeaderBg        = imgui.ImVec4(0.12, 0.22, 0.40, 1.00),
        PriceBg         = imgui.ImVec4(0.10, 0.18, 0.30, 1.00),
    },
    [1] = {
        name = u8"🌿 Emerald",
        WindowBg        = imgui.ImVec4(0.04, 0.10, 0.07, 0.97),
        TitleBg         = imgui.ImVec4(0.06, 0.25, 0.15, 1.00),
        TitleBgActive   = imgui.ImVec4(0.10, 0.45, 0.25, 1.00),
        FrameBg         = imgui.ImVec4(0.08, 0.18, 0.12, 1.00),
        Button          = imgui.ImVec4(0.12, 0.50, 0.28, 1.00),
        ButtonHovered   = imgui.ImVec4(0.20, 0.70, 0.40, 1.00),
        ButtonActive    = imgui.ImVec4(0.08, 0.35, 0.20, 1.00),
        Text            = imgui.ImVec4(0.90, 1.00, 0.93, 1.00),
        Separator       = imgui.ImVec4(0.12, 0.50, 0.28, 0.50),
        ChildBg         = imgui.ImVec4(0.06, 0.14, 0.09, 1.00),
        TabActive       = imgui.ImVec4(0.12, 0.50, 0.28, 1.00),
        TabInactive     = imgui.ImVec4(0.06, 0.20, 0.12, 1.00),
        TabText         = imgui.ImVec4(0.90, 1.00, 0.93, 1.00),
        TabTextInactive = imgui.ImVec4(0.45, 0.70, 0.52, 1.00),
        Accent          = imgui.ImVec4(0.3, 1.0, 0.55, 1.0),
        HeaderBg        = imgui.ImVec4(0.10, 0.30, 0.18, 1.00),
        PriceBg         = imgui.ImVec4(0.07, 0.20, 0.13, 1.00),
    },
    [2] = {
        name = u8"🔴 Crimson",
        WindowBg        = imgui.ImVec4(0.10, 0.04, 0.05, 0.97),
        TitleBg         = imgui.ImVec4(0.30, 0.06, 0.08, 1.00),
        TitleBgActive   = imgui.ImVec4(0.55, 0.10, 0.14, 1.00),
        FrameBg         = imgui.ImVec4(0.22, 0.07, 0.09, 1.00),
        Button          = imgui.ImVec4(0.65, 0.10, 0.15, 1.00),
        ButtonHovered   = imgui.ImVec4(0.85, 0.20, 0.25, 1.00),
        ButtonActive    = imgui.ImVec4(0.45, 0.08, 0.10, 1.00),
        Text            = imgui.ImVec4(1.00, 0.93, 0.93, 1.00),
        Separator       = imgui.ImVec4(0.65, 0.10, 0.15, 0.50),
        ChildBg         = imgui.ImVec4(0.14, 0.05, 0.06, 1.00),
        TabActive       = imgui.ImVec4(0.65, 0.10, 0.15, 1.00),
        TabInactive     = imgui.ImVec4(0.22, 0.06, 0.08, 1.00),
        TabText         = imgui.ImVec4(1.00, 0.93, 0.93, 1.00),
        TabTextInactive = imgui.ImVec4(0.75, 0.45, 0.48, 1.00),
        Accent          = imgui.ImVec4(1.0, 0.4, 0.45, 1.0),
        HeaderBg        = imgui.ImVec4(0.35, 0.08, 0.10, 1.00),
        PriceBg         = imgui.ImVec4(0.20, 0.06, 0.08, 1.00),
    },
}

-- ============================ [ ПРИМЕНЕНИЕ ТЕМЫ ] ============================
local function applyTheme(t)
    local style = imgui.GetStyle()
    local colors = style.Colors

    colors[imgui.Col.WindowBg]              = t.WindowBg
    colors[imgui.Col.TitleBg]               = t.TitleBg
    colors[imgui.Col.TitleBgActive]         = t.TitleBgActive
    colors[imgui.Col.FrameBg]               = t.FrameBg
    colors[imgui.Col.FrameBgHovered]        = t.ButtonHovered
    colors[imgui.Col.Button]                = t.Button
    colors[imgui.Col.ButtonHovered]         = t.ButtonHovered
    colors[imgui.Col.ButtonActive]          = t.ButtonActive
    colors[imgui.Col.Text]                  = t.Text
    colors[imgui.Col.Separator]             = t.Separator
    colors[imgui.Col.ScrollbarBg]           = t.ChildBg
    colors[imgui.Col.ScrollbarGrab]         = t.Button
    colors[imgui.Col.ScrollbarGrabHovered]  = t.ButtonHovered
    colors[imgui.Col.Header]                = t.TabActive
    colors[imgui.Col.HeaderHovered]         = t.ButtonHovered
    colors[imgui.Col.HeaderActive]          = t.ButtonActive
end

imgui.OnInitialize(function()
    local style = imgui.GetStyle()

    style.WindowRounding    = 10.0
    style.FrameRounding     = 7.0
    style.GrabRounding      = 7.0
    style.ScrollbarRounding = 7.0
    style.WindowTitleAlign  = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign   = imgui.ImVec2(0.5, 0.5)
    style.WindowPadding     = imgui.ImVec2(14, 14)
    style.ItemSpacing       = imgui.ImVec2(10, 8)
    style.FramePadding      = imgui.ImVec2(10, 6)

    applyTheme(themes[currentTheme])
end)

-- ============================ [ ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ РЕНДЕРА ] ============================
local function renderTabBar()
    local t = themes[currentTheme]
    local tabLabels = {u8"  📊 Средние цены  ", u8"  ⚙ Настройки  "}
    local winW = imgui.GetWindowWidth()
    local tabW = (winW - 28) / 2
    local tabH = 32

    imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 7.0)

    for i = 0, 1 do
        if i == currentTab then
            imgui.PushStyleColor(imgui.Col.Button,        t.TabActive)
            imgui.PushStyleColor(imgui.Col.ButtonHovered, t.ButtonHovered)
            imgui.PushStyleColor(imgui.Col.ButtonActive,  t.ButtonActive)
            imgui.PushStyleColor(imgui.Col.Text,          t.TabText)
        else
            imgui.PushStyleColor(imgui.Col.Button,        t.TabInactive)
            imgui.PushStyleColor(imgui.Col.ButtonHovered, t.ButtonHovered)
            imgui.PushStyleColor(imgui.Col.ButtonActive,  t.TabActive)
            imgui.PushStyleColor(imgui.Col.Text,          t.TabTextInactive)
        end

        if imgui.Button(tabLabels[i + 1], imgui.ImVec2(tabW, tabH)) then
            currentTab = i
        end

        imgui.PopStyleColor(4)

        if i == 0 then
            imgui.SameLine(0, 4)
        end
    end

    imgui.PopStyleVar()
end

local function renderPricesTab()
    local t = themes[currentTheme]

    imgui.Spacing()

    imgui.PushStyleColor(imgui.Col.ChildBg, t.PriceBg)
    if imgui.BeginChild("PricesChild", imgui.ImVec2(-1, 150), true) then

        imgui.PushStyleColor(imgui.Col.ChildBg, t.HeaderBg)
        if imgui.BeginChild("TableHeader", imgui.ImVec2(-1, 26), false) then
            imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
            imgui.TextColored(t.Accent, u8"  Ресурс")
            imgui.SameLine(220)
            imgui.TextColored(t.Accent, u8"Средняя цена")
            imgui.EndChild()
        end
        imgui.PopStyleColor()

        imgui.Spacing()

        local items = {
            {name = u8"🌾  Лён", price = u8"3 000 ₽ / шт."},
        }

        for i, item in ipairs(items) do
            imgui.PushStyleColor(
                imgui.Col.ChildBg,
                i % 2 == 0 and t.PriceBg or imgui.ImVec4(
                    t.PriceBg.x + 0.02,
                    t.PriceBg.y + 0.03,
                    t.PriceBg.z + 0.04,
                    1.0
                )
            )

            if imgui.BeginChild("row_" .. i, imgui.ImVec2(-1, 28), false) then
                imgui.SetCursorPosY(imgui.GetCursorPosY() + 5)
                imgui.TextColored(t.Text, item.name)
                imgui.SameLine(220)
                imgui.TextColored(t.Accent, item.price)
                imgui.EndChild()
            end

            imgui.PopStyleColor()
        end

        imgui.EndChild()
    end
    imgui.PopStyleColor()
end

local function renderSettingsTab()
    local t = themes[currentTheme]

    imgui.Spacing()

    imgui.PushStyleColor(imgui.Col.ChildBg, t.PriceBg)
    if imgui.BeginChild("SettingsChild", imgui.ImVec2(-1, 150), true) then

        imgui.Spacing()
        imgui.TextColored(t.Accent, u8"  🎨 Смена темы")
        imgui.Spacing()

        imgui.PushStyleColor(imgui.Col.Separator, t.Separator)
        imgui.Separator()
        imgui.PopStyleColor()

        imgui.Spacing()

        local themeButtonW = (imgui.GetWindowWidth() - 30) / 3

        imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 8.0)

        for i = 0, 2 do
            local th = themes[i]

            if i == currentTheme then
                imgui.PushStyleColor(imgui.Col.Button,        th.TabActive)
                imgui.PushStyleColor(imgui.Col.ButtonHovered, th.ButtonHovered)
                imgui.PushStyleColor(imgui.Col.ButtonActive,  th.ButtonActive)
                imgui.PushStyleColor(imgui.Col.Text,          th.TabText)
            else
                imgui.PushStyleColor(imgui.Col.Button,        th.TabInactive)
                imgui.PushStyleColor(imgui.Col.ButtonHovered, th.ButtonHovered)
                imgui.PushStyleColor(imgui.Col.ButtonActive,  th.TabActive)
                imgui.PushStyleColor(imgui.Col.Text,          th.TabTextInactive)
            end

            if imgui.Button(th.name, imgui.ImVec2(themeButtonW, 38)) then
                currentTheme = i
                applyTheme(themes[currentTheme])
            end

            imgui.PopStyleColor(4)

            if i < 2 then
                imgui.SameLine(0, 5)
            end
        end

        imgui.PopStyleVar()

        imgui.Spacing()

        imgui.SetCursorPosX((imgui.GetWindowWidth() - 200) / 2)
        imgui.TextColored(t.TabTextInactive, u8"Активна: " .. themes[currentTheme].name)

        imgui.EndChild()
    end
    imgui.PopStyleColor()
end

-- ============================ [ ОКНО IMGUI ] ============================
local newFrame = imgui.OnFrame(
    function()
        return renderMenu[0]
    end,
    function(player)
        local t = themes[currentTheme]

        imgui.SetNextWindowSize(imgui.ImVec2(480, 310), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(imgui.ImVec2(480, 280), imgui.Cond.FirstUseEver)

        imgui.PushStyleColor(imgui.Col.WindowBg,      t.WindowBg)
        imgui.PushStyleColor(imgui.Col.TitleBg,       t.TitleBg)
        imgui.PushStyleColor(imgui.Col.TitleBgActive, t.TitleBgActive)
        imgui.PushStyleColor(imgui.Col.Text,          t.Text)
        imgui.PushStyleColor(imgui.Col.Separator,     t.Separator)

        if imgui.Begin(u8"  📈 Trade Analytics Studio  ", renderMenu, imgui.WindowFlags.NoCollapse) then

            renderTabBar()

            imgui.PushStyleColor(imgui.Col.Separator, t.Separator)
            imgui.Separator()
            imgui.PopStyleColor()

            if currentTab == 0 then
                renderPricesTab()
            elseif currentTab == 1 then
                renderSettingsTab()
            end

            imgui.Spacing()

            imgui.PushStyleColor(imgui.Col.Button,        t.Button)
            imgui.PushStyleColor(imgui.Col.ButtonHovered, t.ButtonHovered)
            imgui.PushStyleColor(imgui.Col.ButtonActive,  t.ButtonActive)
            imgui.PushStyleColor(imgui.Col.Text,          t.Text)

            if imgui.Button(u8"✕  Закрыть", imgui.ImVec2(-1, 30)) then
                renderMenu[0] = false
            end

            imgui.PopStyleColor(4)

            imgui.End()
        end

        imgui.PopStyleColor(5)
    end
)

-- ============================ [ БЫСТРЫЙ /Q ЧЕРЕЗ F6 / T ] ============================
local function pressEnterInChat()
    if type(setVirtualKeyDown) == "function" then
        setVirtualKeyDown(vkeys.VK_RETURN, true)
        wait(25)
        setVirtualKeyDown(vkeys.VK_RETURN, false)
    end
end

local function quickQuit()
    if quickQuitRunning then return end
    quickQuitRunning = true

    lua_thread.create(function()
        -- Ждём отпускания клавиши, чтобы штатное открытие чата F6/T не мешало.
        while isKeyDown(vkeys.VK_F6) or isKeyDown(vkeys.VK_T) do
            wait(0)
        end

        wait(20)

        -- Если чат ещё не открыт — открываем.
        if not sampIsChatInputActive() then
            sampSetChatInputEnabled(true)
            wait(60)
        end

        -- Вписываем /q.
        sampSetChatInputText("/q")
        wait(60)

        -- Основной вариант: реально имитируем Enter.
        pressEnterInChat()
        wait(120)

        -- Запасной вариант: если чат остался открыт, обрабатываем строку как ввод SA-MP.
        if sampIsChatInputActive() then
            if type(sampProcessChatInput) == "function" then
                pcall(sampProcessChatInput, "/q")
                wait(80)
            end
        end

        -- Если даже после этого чат висит активным — закрываем, чтобы F5/Ctrl+F5 снова работали.
        if sampIsChatInputActive() then
            sampSetChatInputEnabled(false)
        end

        quickQuitRunning = false
    end)
end

-- ============================ [ ОСНОВНОЙ КОД ] ============================
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    checkUpdate()

    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Скрипт аналитики загружен! Версия: " .. SCRIPT_VERSION, -1)
    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Открыть меню: {0088FF}F5 {FFFFFF}| Обновление: {0088FF}Ctrl+F5", -1)
    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Быстрый ввод /q: {0088FF}F6/T", -1)

    while true do
        wait(0)

        -- F5 / Ctrl+F5
        -- Если чат завис активным, сначала закрываем его, чтобы мод не "умирал".
        if isKeyJustPressed(vkeys.VK_F5) and not sampIsDialogActive() then
            if sampIsChatInputActive() then
                sampSetChatInputEnabled(false)
            end

            if isKeyDown(vkeys.VK_CONTROL) then
                sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Запрос к серверу обновлений...", -1)
                checkUpdate()
            else
                renderMenu[0] = not renderMenu[0]
            end
        end

        -- F6 или T — открыть чат, вписать /q и нажать Enter.
        if (isKeyJustPressed(vkeys.VK_F6) or isKeyJustPressed(vkeys.VK_T))
            and not sampIsChatInputActive()
            and not sampIsDialogActive()
            and not quickQuitRunning
        then
            quickQuit()
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

                        sampAddChatMessage("{0088FF}[TradeAnalytics] {00FF00}Обновление завершено! Перезагрузка...", -1)
                        thisScript():reload()
                    else
                        sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Установлена актуальная версия.", -1)
                        os.remove(temp_path)
                    end
                else
                    os.remove(temp_path)
                end
            else
                os.remove(temp_path)
            end

            update_checking = false
        elseif status == dlstatus.STATUS_ERRORDOWNLOADDATA then
            sampAddChatMessage("{0088FF}[TradeAnalytics] {FF0000}Ошибка соединения с сервером обновлений.", -1)
            update_checking = false
        end
    end)
end
