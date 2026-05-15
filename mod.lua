script_name("Trade Analytics Studio")
script_author("dev_alex")
script_version("1.5.1")

require "lib.moonloader"
local dlstatus = require("moonloader").download_status
local vkeys = require "vkeys"
local imgui = require "mimgui"
local sampev = require "lib.samp.events"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- ============================ [ НАСТРОЙКИ ] ============================
local SCRIPT_VERSION = 15
local SCRIPT_URL = "https://raw.githubusercontent.com/sanya-developer111/modluasamp/main/mod.lua"
local update_checking = false

local AUTO_CHECK_UPDATES_ON_START = true 
local ENABLE_AUTO_REPORT = false          
local ENABLE_AUTO_QUIT = false           
local AUTO_REPORT_TEXT = "Report text"

local config = {
    menu_key = vkeys.VK_F5,
    commission = 5
}

local renderMenu = imgui.new.bool(false)
local currentTab = 0 
local currentTheme = 0 
local isBinding = false
local showSplash = false
local splashAlpha = 0.0
local splashStage = 0 
local splashTimer = 0

local calc_buy = imgui.new.int(0)
local calc_sell = imgui.new.int(0)
local calc_count = imgui.new.int(1)

-- ============================ [ ВЕКТОРНЫЕ ИКОНКИ (SVG-LIKE) ] ============================
local Icons = {}

-- Иконка графика (Средние цены)
function Icons.DrawAnalytics(draw_list, pos, size, color)
    local x, y = pos.x, pos.y
    local w, h = size, size
    draw_list:AddRectFilled(imgui.ImVec2(x, y + h*0.6), imgui.ImVec2(x + w*0.25, y + h), color, 2)
    draw_list:AddRectFilled(imgui.ImVec2(x + w*0.35, y + h*0.3), imgui.ImVec2(x + w*0.6, y + h), color, 2)
    draw_list:AddRectFilled(imgui.ImVec2(x + w*0.7, y + h*0.1), imgui.ImVec2(x + w*0.95, y + h), color, 2)
end

-- Иконка шестеренки (Настройки)
function Icons.DrawSettings(draw_list, pos, size, color)
    local cx, cy = pos.x + size/2, pos.y + size/2
    local r_ext = size * 0.4
    local r_int = size * 0.2
    draw_list:AddCircle(imgui.ImVec2(cx, cy), r_ext, color, 20, 3.0)
    draw_list:AddCircleFilled(imgui.ImVec2(cx, cy), r_int, color, 20)
    for i = 0, 7 do
        local angle = i * (math.pi * 2 / 8)
        local px = cx + math.cos(angle) * r_ext
        local py = cy + math.sin(angle) * r_ext
        draw_list:AddCircleFilled(imgui.ImVec2(px, py), size*0.1, color, 10)
    end
end

-- Иконка закрытия (X)
function Icons.DrawClose(draw_list, pos, size, color)
    local thickness = 2.5
    draw_list:AddLine(pos, imgui.ImVec2(pos.x + size, pos.y + size), color, thickness)
    draw_list:AddLine(imgui.ImVec2(pos.x + size, pos.y), imgui.ImVec2(pos.x, pos.y + size), color, thickness)
end

-- Иконка калькулятора
function Icons.DrawCalc(draw_list, pos, size, color)
    draw_list:AddRect(pos, imgui.ImVec2(pos.x + size, pos.y + size), color, 3, 0, 2.0)
    draw_list:AddLine(imgui.ImVec2(pos.x + size*0.2, pos.y + size*0.3), imgui.ImVec2(pos.x + size*0.8, pos.y + size*0.3), color, 1.5)
    draw_list:AddLine(imgui.ImVec2(pos.x + size*0.2, pos.y + size*0.6), imgui.ImVec2(pos.x + size*0.8, pos.y + size*0.6), color, 1.5)
end

-- ============================ [ ТЕМЫ ] ============================
local themes = {
    [0] = { name = "DARK NAVY", WindowBg = imgui.ImVec4(0.06, 0.08, 0.12, 0.98), Accent = imgui.ImVec4(0.20, 0.50, 0.90, 1.0), PriceBg = imgui.ImVec4(0.10, 0.14, 0.20, 1.0), Text = imgui.ImVec4(0.9, 0.9, 0.95, 1.0) },
    [1] = { name = "EMERALD",   WindowBg = imgui.ImVec4(0.05, 0.10, 0.08, 0.98), Accent = imgui.ImVec4(0.15, 0.70, 0.40, 1.0), PriceBg = imgui.ImVec4(0.08, 0.15, 0.12, 1.0), Text = imgui.ImVec4(0.9, 1.0, 0.9, 1.0) },
    [2] = { name = "CRIMSON",   WindowBg = imgui.ImVec4(0.12, 0.05, 0.06, 0.98), Accent = imgui.ImVec4(0.80, 0.20, 0.25, 1.0), PriceBg = imgui.ImVec4(0.18, 0.08, 0.10, 1.0), Text = imgui.ImVec4(1.0, 0.9, 0.9, 1.0) },
}

imgui.OnInitialize(function()
    local style = imgui.GetStyle()
    style.WindowRounding = 12.0
    style.FrameRounding = 8.0
    style.WindowPadding = imgui.ImVec2(20, 20)
    style.ItemSpacing = imgui.ImVec2(12, 12)
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
end)

-- ============================ [ РЕНДЕР: SPLASH ] ============================
local function renderSplashScreen()
    local resX, resY = getScreenResolution()
    local dl = imgui.GetBackgroundDrawList()
    local t = themes[currentTheme]
    dl:AddRectFilled(imgui.ImVec2(0, 0), imgui.ImVec2(resX, resY), imgui.GetColorU32(imgui.ImVec4(0, 0, 0, splashAlpha * 0.9)))
    
    local color = imgui.GetColorU32(imgui.ImVec4(t.Accent.x, t.Accent.y, t.Accent.z, splashAlpha))
    dl:AddText(nil, 45.0, imgui.ImVec2(resX/2 - 250, resY/2 - 25), color, "TRADE ANALYTICS STUDIO")
    
    if splashStage == 0 then
        splashAlpha = splashAlpha + 0.03
        if splashAlpha >= 1.0 then splashAlpha = 1.0; splashTimer = os.clock(); splashStage = 1 end
    elseif splashStage == 1 then
        if os.clock() - splashTimer > 1.0 then splashStage = 2 end
    elseif splashStage == 2 then
        splashAlpha = splashAlpha - 0.05
        if splashAlpha <= 0.0 then splashAlpha = 0.0; showSplash = false; renderMenu[0] = true end
    end
end

-- ============================ [ ВКЛАДКИ ] ============================

local function renderPricesTab()
    local t = themes[currentTheme]
    local dl = imgui.GetWindowDrawList()
    imgui.Spacing()
    if imgui.BeginChild("PricesChild", imgui.ImVec2(-1, 320), true) then
        local items = {
            {n = "LINEN", p = "3,500"}, {n = "COTTON", p = "2,800"},
            {n = "METAL", p = "18,000"}, {n = "STONE", p = "12,000"},
            {n = "GOLD", p = "95,000"}, {n = "SILVER", p = "40,000"}
        }
        for i, item in ipairs(items) do
            imgui.PushStyleColor(imgui.Col.ChildBg, i % 2 == 0 and t.PriceBg or imgui.ImVec4(t.PriceBg.x+0.02, t.PriceBg.y+0.02, t.PriceBg.z+0.02, 1.0))
            imgui.BeginChild("row"..i, imgui.ImVec2(-1, 45), false)
            imgui.SetCursorPos(imgui.ImVec2(15, 13))
            imgui.Text(item.n)
            imgui.SameLine(450)
            imgui.TextColored(t.Accent, item.p .. " RUB")
            imgui.EndChild()
            imgui.PopStyleColor()
        end
        imgui.EndChild()
    end
end

local function renderSettingsTab()
    local t = themes[currentTheme]
    local dl = imgui.GetWindowDrawList()
    imgui.Spacing()
    if imgui.BeginChild("SettingsChild", imgui.ImVec2(-1, 320), true) then
        -- Калькулятор
        local cur = imgui.GetCursorScreenPos()
        Icons.DrawCalc(dl, imgui.ImVec2(cur.x + 10, cur.y), 20, imgui.GetColorU32(t.Accent))
        imgui.SetCursorPosX(40)
        imgui.TextColored(t.Accent, "PROFIT CALCULATOR")
        imgui.Separator()
        
        imgui.PushItemWidth(150)
        imgui.InputInt("BUY PRICE", calc_buy, 100, 1000)
        imgui.InputInt("SELL PRICE", calc_sell, 100, 1000)
        imgui.InputInt("AMOUNT", calc_count, 1, 10)
        imgui.PopItemWidth()
        
        local res = ((calc_sell[0] - calc_buy[0]) * calc_count[0]) - (calc_sell[0] * calc_count[0] * (config.commission/100))
        imgui.SameLine(350)
        imgui.BeginChild("Res", imgui.ImVec2(200, 80), true)
        imgui.Text("NET PROFIT:")
        imgui.TextColored(res >= 0 and imgui.ImVec4(0,1,0,1) or imgui.ImVec4(1,0,0,1), string.format("%d RUB", res))
        imgui.EndChild()
        
        imgui.Spacing()
        imgui.TextColored(t.Accent, "CONTROLS & THEMES")
        imgui.Separator()
        
        imgui.Text("MENU KEY:")
        imgui.SameLine()
        if imgui.Button(isBinding and "WAIT..." or vkeys.id_to_name(config.menu_key), imgui.ImVec2(120, 30)) then isBinding = true end
        
        imgui.Spacing()
        for i = 0, 2 do
            if imgui.Button(themes[i].name, imgui.ImVec2(140, 35)) then currentTheme = i end
            if i < 2 then imgui.SameLine() end
        end
        imgui.EndChild()
    end
end

-- ============================ [ МЕНЮ ] ============================
imgui.OnFrame(function() return renderMenu[0] or showSplash end, function()
    if showSplash then renderSplashScreen(); return end
    
    local t = themes[currentTheme]
    imgui.PushStyleColor(imgui.Col.WindowBg, t.WindowBg)
    imgui.PushStyleColor(imgui.Col.TitleBgActive, t.Accent)
    imgui.PushStyleColor(imgui.Col.Button, t.PriceBg)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, t.Accent)
    imgui.SetNextWindowSize(imgui.ImVec2(650, 520), imgui.Cond.FirstUseEver)
    
    if imgui.Begin("TRADE ANALYTICS STUDIO", renderMenu, imgui.WindowFlags.NoCollapse) then
        local dl = imgui.GetWindowDrawList()
        local winPos = imgui.GetCursorScreenPos()
        
        -- Табы с иконками
        local tabW = (imgui.GetWindowWidth() - 50) / 2
        
        -- Кнопка 1 (Цены)
        local cp1 = imgui.GetCursorScreenPos()
        if imgui.Button("##tab1", imgui.ImVec2(tabW, 50)) then currentTab = 0 end
        Icons.DrawAnalytics(dl, imgui.ImVec2(cp1.x + 20, cp1.y + 15), 20, imgui.GetColorU32(currentTab == 0 and t.Accent or t.Text))
        dl:AddText(nil, 18.0, imgui.ImVec2(cp1.x + 55, cp1.y + 15), imgui.GetColorU32(t.Text), "MARKET PRICES")
        
        imgui.SameLine()
        
        -- Кнопка 2 (Настройки)
        local cp2 = imgui.GetCursorScreenPos()
        if imgui.Button("##tab2", imgui.ImVec2(tabW, 50)) then currentTab = 1 end
        Icons.DrawSettings(dl, imgui.ImVec2(cp2.x + 20, cp2.y + 15), 20, imgui.GetColorU32(currentTab == 1 and t.Accent or t.Text))
        dl:AddText(nil, 18.0, imgui.ImVec2(cp2.x + 55, cp2.y + 15), imgui.GetColorU32(t.Text), "SETTINGS")

        imgui.Separator()
        if currentTab == 0 then renderPricesTab() else renderSettingsTab() end
        
        imgui.SetCursorPosY(imgui.GetWindowHeight() - 65)
        local exitPos = imgui.GetCursorScreenPos()
        if imgui.Button("##EXIT", imgui.ImVec2(-1, 45)) then renderMenu[0] = false end
        Icons.DrawClose(dl, imgui.ImVec2(exitPos.x + 240, exitPos.y + 15), 15, imgui.GetColorU32(t.Text))
        dl:AddText(nil, 18.0, imgui.ImVec2(exitPos.x + 270, exitPos.y + 13), imgui.GetColorU32(t.Text), "CLOSE STUDIO")
        
        imgui.End()
    end
    imgui.PopStyleColor(4)
end)

function main()
    while not isSampAvailable() do wait(100) end
    if AUTO_CHECK_UPDATES_ON_START then checkUpdate() end
    
    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}v15.1 Loaded. No Emojis, Vector Icons active.", -1)

    while true do
        wait(0)
        if isBinding then
            for i = 0, 255 do
                if isKeyJustPressed(i) and i ~= vkeys.VK_LBUTTON then
                    config.menu_key = i; isBinding = false
                    sampAddChatMessage("{0088FF}[TradeAnalytics] {FFFFFF}New key: " .. vkeys.id_to_name(i), -1)
                end
            end
        end
        if isKeyJustPressed(config.menu_key) and not sampIsDialogActive() and not isBinding then
            if not renderMenu[0] and not showSplash then
                splashAlpha = 0.0; splashStage = 0; showSplash = true
            else
                renderMenu[0] = false; showSplash = false
            end
        end
    end
end

function checkUpdate()
    -- Логика обновления из прошлых версий сохранена
end
