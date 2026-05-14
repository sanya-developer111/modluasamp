script_name("PriceSimulator & AutoRep")
script_authors("AI Assistant")
script_version("1.0")

require "lib.moonloader"
local imgui = require 'mimgui'
local encoding = require 'encoding'
local sampev = require 'samp.events'

encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- ================= НАСТРОЙКИ ОБНОВЛЕНИЯ =================
local CURRENT_VERSION = "1.2" -- Меняй при релизе
local UPDATE_URL = "https://raw.githubusercontent.com/sanya-developer111/modluasamp/main/version.txt"
local UPDATE_SCRIPT_URL = "https://raw.githubusercontent.com/sanya-developer111/modluasamp/main/mod.lua"
-- =======================================================

-- Переменные состояния
local show_menu = imgui.new.bool(false)
local waiting_for_report = false
local updateBusy = false

-- Оформление mimgui (Красно-Черная тема)
imgui.OnInitialize(function()
    local style = imgui.GetStyle()
    local colors = style.Colors
    
    style.WindowRounding = 8.0
    style.FrameRounding = 6.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.08, 0.08, 0.08, 0.95)
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.50, 0.05, 0.05, 1.00)
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.75, 0.10, 0.10, 1.00)
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[imgui.Col.Separator] = imgui.ImVec4(0.75, 0.10, 0.10, 0.50)
    colors[imgui.Col.Text] = imgui.ImVec4(0.95, 0.95, 0.95, 1.00)
end)

-- Рендер меню (F5)
local newFrame = imgui.OnFrame(function() return show_menu[0] end, function(player)
    imgui.SetNextWindowSize(imgui.ImVec2(450, 200), imgui.Cond.FirstUseEver)
    if imgui.Begin(u8"Система средних цен | Инвентарь", show_menu, imgui.WindowFlags.NoCollapse) then
        
        imgui.Spacing()
        imgui.TextColored(imgui.ImVec4(0.8, 0.8, 0.8, 1.0), u8"Ваши ресурсы из инвентаря:")
        imgui.Separator()
        imgui.Spacing()
        
        if imgui.BeginChild("ItemBox", imgui.ImVec2(0, 80), true) then
            imgui.TextUnformatted(u8"Точильный камень")
            imgui.SameLine(200)
            imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"средняя цена:")
            imgui.SameLine(310)
            imgui.TextColored(imgui.ImVec4(1.0, 0.2, 0.2, 1.0), u8"$ 50 000")
            imgui.EndChild()
        end
        
        imgui.Spacing()
        if imgui.Button(u8"Закрыть меню", imgui.ImVec2(-1, 35)) then
            show_menu[0] = false
        end
        
        imgui.End()
    end
end)

-- Отслеживание отправки команды /rep
function sampev.onSendCommand(cmd)
    if cmd == "/rep" or cmd == "/report" then
        waiting_for_report = true
    end
end

-- ================= СИСТЕМА ОБНОВЛЕНИЙ (С ТАЙМАУТОМ) =================
function checkUpdate()
    if updateBusy then
        sampAddChatMessage("{800000}[Мод]{FFFFFF} Обновление уже выполняется...", -1)
        return
    end
    updateBusy = true
    sampAddChatMessage("{800000}[Мод]{FFFFFF} Проверка обновлений...", -1)
    
    local path_to_script = thisScript().path
    local tmp_version = path_to_script .. ".ver.tmp"
    
    -- Таймаут 10 секунд (автоматический сброс, если зависнет)
    local timeoutTimer
    timeoutTimer = setTimer(function()
        if updateBusy then
            sampAddChatMessage("{800000}[Мод]{FFFFFF} Превышено время ожидания (10 сек). Проверьте сетевое соединение.", -1)
            updateBusy = false
            os.remove(tmp_version)
            timeoutTimer = nil
        end
    end, 10000, 1)
    
    downloadUrlToFile(UPDATE_URL, tmp_version, function(id, status)
        -- Сбрасываем таймер
        if timeoutTimer then
            clearTimer(timeoutTimer)
            timeoutTimer = nil
        end
        
        -- Отладка: показываем статус
        sampAddChatMessage("{800000}[Мод]{FFFFFF} Статус загрузки: " .. tostring(status), -1)
        
        if status == 2 then -- STATUS_ENDDOWNLOADDATA = 2
            local f = io.open(tmp_version, "r")
            if f then
                local remote_version = f:read("*a"):gsub("%s+", "")
                f:close()
                os.remove(tmp_version)
                
                sampAddChatMessage("{800000}[Мод]{FFFFFF} Удаленная версия: " .. tostring(remote_version), -1)
                
                if remote_version and remote_version ~= CURRENT_VERSION then
                    sampAddChatMessage(string.format("{800000}[Мод]{FFFFFF} Найдена новая версия: %s (ваша: %s). Скачиваю...", remote_version, CURRENT_VERSION), -1)
                    downloadUpdate(path_to_script)
                else
                    sampAddChatMessage("{800000}[Мод]{FFFFFF} У вас установлена последняя версия.", -1)
                    updateBusy = false
                end
            else
                sampAddChatMessage("{800000}[Мод]{FFFFFF} Ошибка чтения файла версии.", -1)
                updateBusy = false
            end
        elseif status == 1 then -- STATUS_ERROR = 1
            sampAddChatMessage("{800000}[Мод]{FFFFFF} Ошибка сети. Проверьте интернет и URL.", -1)
            updateBusy = false
        else
            sampAddChatMessage("{800000}[Мод]{FFFFFF} Неизвестный статус: " .. tostring(status), -1)
            updateBusy = false
        end
    end)
end

function downloadUpdate(script_path)
    local tmp_script = script_path .. ".new.lua"
    
    -- Таймаут 30 секунд для скачивания скрипта
    local timeoutTimer
    timeoutTimer = setTimer(function()
        if updateBusy then
            sampAddChatMessage("{800000}[Мод]{FFFFFF} Превышено время скачивания (30 сек).", -1)
            updateBusy = false
            os.remove(tmp_script)
            timeoutTimer = nil
        end
    end, 30000, 1)
    
    downloadUrlToFile(UPDATE_SCRIPT_URL, tmp_script, function(id, status)
        if timeoutTimer then
            clearTimer(timeoutTimer)
            timeoutTimer = nil
        end
        
        if status == 2 then -- STATUS_ENDDOWNLOADDATA
            os.remove(script_path .. ".old")
            os.rename(script_path, script_path .. ".old")
            os.rename(tmp_script, script_path)
            
            sampAddChatMessage("{800000}[Мод]{FFFFFF} Обновление установлено! Перезагрузка...", -1)
            updateBusy = false
            thisScript():reload()
            
        elseif status == 1 then -- STATUS_ERROR
            os.remove(tmp_script)
            sampAddChatMessage("{800000}[Мод]{FFFFFF} Ошибка скачивания файла.", -1)
            updateBusy = false
        else
            sampAddChatMessage("{800000}[Мод]{FFFFFF} Неизвестный статус при скачивании: " .. tostring(status), -1)
            updateBusy = false
        end
    end)
end
-- =======================================================

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{800000}[Мод]{FFFFFF} Загружен! F5 - Меню, Ctrl+F5 - Обновление", -1)

    while true do
        wait(0)
        
        if wasKeyPressed(VK_F5) then
            if isKeyDown(VK_LCONTROL) or isKeyDown(VK_RCONTROL) then
                checkUpdate()
            elseif not sampIsChatInputActive() and not sampIsDialogActive() then
                show_menu[0] = not show_menu[0]
            end
        end

        if waiting_for_report and sampIsDialogActive() then
            wait(50)
            sampSetCurrentDialogEditboxText(u8"Всем привет!")
            wait(100)
            sampCloseCurrentDialogWithButton(1)
            waiting_for_report = false
        end
    end
end