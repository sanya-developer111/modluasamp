script_name("Trade Analytics Studio")
script_author("dev_alex")
script_version("10")

require "lib.moonloader"
local dlstatus = require("moonloader").download_status
local vkeys = require "vkeys"
local imgui = require "mimgui"
local sampev = require "lib.samp.events"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- ============================ [ ВЕРСИЯ ] ============================
local SCRIPT_VERSION = 10
local SCRIPT_URL = "https://raw.githubusercontent.com/sanya-developer111/modluasamp/refs/heads/main/mod.lua"
local update_checking = false
-- ================================================================

local renderMenu = imgui.new.bool(false)
local currentTab = imgui.new.int(0)
local currentTheme = imgui.new.int(0)
local qAutoCooldown = false

-- ============================ [ ТЕМЫ ] ============================

local function applyTheme(id)
    local style = imgui.GetStyle()
    local colors = style.Colors

    style.WindowRounding = 10.0
    style.FrameRounding = 8.0
    style.ChildRounding = 8.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.FramePadding = imgui.ImVec2(10, 6)
    style.ItemSpacing = imgui.ImVec2(10, 8)

    if id == 0 then
        -- 🔥 Modern Dark Blue
        colors[imgui.Col.WindowBg] = imgui.ImVec4(0.07,0.09,0.13,0.98)
        colors[imgui.Col.ChildBg] = imgui.ImVec4(0.10,0.12,0.18,1.00)
        colors[imgui.Col.TitleBg] = imgui.ImVec4(0.10,0.25,0.45,1.00)
        colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.15,0.35,0.65,1.00)
        colors[imgui.Col.Button] = imgui.ImVec4(0.15,0.35,0.65,1.00)
        colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.25,0.50,0.85,1.00)
        colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.12,0.28,0.55,1.00)
        colors[imgui.Col.Text] = imgui.ImVec4(0.92,0.95,1.00,1.00)

    elseif id == 1 then
        -- 🟣 Purple Neon
        colors[imgui.Col.WindowBg] = imgui.ImVec4(0.08,0.07,0.12,0.98)
        colors[imgui.Col.ChildBg] = imgui.ImVec4(0.13,0.10,0.18,1.00)
        colors[imgui.Col.TitleBg] = imgui.ImVec4(0.30,0.10,0.50,1.00)
        colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.45,0.15,0.75,1.00)
        colors[imgui.Col.Button] = imgui.ImVec4(0.40,0.15,0.70,1.00)
        colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.55,0.25,0.90,1.00)
        colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.30,0.12,0.55,1.00)
        colors[imgui.Col.Text] = imgui.ImVec4(0.95,0.90,1.00,1.00)

    elseif id == 2 then
        -- 🟢 Emerald Modern
        colors[imgui.Col.WindowBg] = imgui.ImVec4(0.06,0.10,0.09,0.98)
        colors[imgui.Col.ChildBg] = imgui.ImVec4(0.08,0.14,0.12,1.00)
        colors[imgui.Col.TitleBg] = imgui.ImVec4(0.10,0.35,0.25,1.00)
        colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.15,0.55,0.40,1.00)
        colors[imgui.Col.Button] = imgui.ImVec4(0.10,0.45,0.32,1.00)
        colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.15,0.65,0.45,1.00)
        colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.08,0.35,0.25,1.00)
        colors[imgui.Col.Text] = imgui.ImVec4(0.90,1.00,0.95,1.00)
    end
end

imgui.OnInitialize(function()
    applyTheme(0)
end)

-- ============================ [ UI ] ============================

imgui.OnFrame(function() return renderMenu[0] end, function()

    imgui.SetNextWindowSize(imgui.ImVec2(720, 420), imgui.Cond.FirstUseEver)
    imgui.Begin(u8"TRADE ANALYTICS STUDIO", renderMenu, imgui.WindowFlags.NoCollapse)

    -- Левая панель
    imgui.BeginChild("Sidebar", imgui.ImVec2(180, -1), true)

    if imgui.Selectable(u8"📊 Средние цены", currentTab[0] == 0) then
        currentTab[0] = 0
    end

    if imgui.Selectable(u8"⚙ Настройки", currentTab[0] == 1) then
        currentTab[0] = 1
    end

    imgui.EndChild()
    imgui.SameLine()

    -- Правая часть
    imgui.BeginChild("Content", imgui.ImVec2(-1, -1), true)

    if currentTab[0] == 0 then

        imgui.Text(u8"Средние цены по рынку")
        imgui.Separator()
        imgui.Spacing()

        imgui.BeginChild("Items", imgui.ImVec2(-1, 250), true)

        imgui.Text(u8"Лён")
        imgui.SameLine(400)
        imgui.TextColored(imgui.ImVec4(0.3,1.0,0.6,1.0), u8"3.000 $")

        imgui.Spacing()
        imgui.Text(u8"Металл")
        imgui.SameLine(400)
        imgui.TextColored(imgui.ImVec4(0.3,1.0,0.6,1.0), u8"37.000 $")

        imgui.EndChild()

    elseif currentTab[0] == 1 then

        imgui.Text(u8"Настройки")
        imgui.Separator()
        imgui.Spacing()

        imgui.Text(u8"Смена темы:")
        imgui.Spacing()

        if imgui.RadioButton(u8"Modern Dark Blue", currentTheme[0] == 0) then
            currentTheme[0] = 0
            applyTheme(0)
        end

        if imgui.RadioButton(u8"Purple Neon", currentTheme[0] == 1) then
            currentTheme[0] = 1
            applyTheme(1)
        end

        if imgui.RadioButton(u8"Emerald Modern", currentTheme[0] == 2) then
            currentTheme[0] = 2
            applyTheme(2)
        end

    end

    imgui.EndChild()
    imgui.End()
end)

-- ============================ [ MAIN ] ============================

function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}Загружено. Версия: "..SCRIPT_VERSION, -1)

    while true do
        wait(0)

        if isKeyJustPressed(vkeys.VK_F5) then
            renderMenu[0] = not renderMenu[0]
        end

        -- Авто /q
        if not qAutoCooldown
            and (isKeyJustPressed(vkeys.VK_F6) or isKeyJustPressed(vkeys.VK_T))
            and not sampIsChatInputActive()
            and not sampIsDialogActive() then

            qAutoCooldown = true
            lua_thread.create(function()
                wait(50)
                sampSetChatInputText("/q")
                wait(10)
                sampSendChat("/q")
                wait(400)
                qAutoCooldown = false
            end)
        end
    end
end
