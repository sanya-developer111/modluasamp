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
local CURRENT_VERSION = "1.1" -- Текущая версия мода
-- Вставь сюда свои ссылки (RAW):
local UPDATE_URL = "https://raw.githubusercontent.com/sanya-developer111/modluasamp/refs/heads/main/version.txt"
local UPDATE_SCRIPT_URL = "https://github.com/sanya-developer111/modluasamp/raw/refs/heads/main/mod.lua"
-- =======================================================

-- Переменные состояния
local show_menu = imgui.new.bool(false)
local waiting_for_report = false

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
        
        -- Блок с имитацией товара
        if imgui.BeginChild("ItemBox", imgui.ImVec2(0, 80), true) then
            imgui.TextUnformatted(u8"?? Точильный камень")
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

-- ================= СИСТЕМА ОБНОВЛЕНИЙ =================
function checkUpdate()
    sampAddChatMessage("{800000}[Мод]{FFFFFF} Проверка обновлений...", -1)
    
    local path_to_script = thisScript().path
    local local_version = CURRENT_VERSION
    local tmp_version = path_to_script .. ".ver.txt"
    
    downloadUrlToFile(UPDATE_URL, tmp_version, function(id, status, p1, p2)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            local f = io.open(tmp_version, "r")
            if f then
                local remote_version = f:read("*a"):gsub("\n", "") -- Читаем версию и убираем пробелы
                f:close()
                os.remove(tmp_version)
                
                if remote_version and remote_version ~= local_version then
                    sampAddChatMessage(string.format("{800000}[Мод]{FFFFFF} Найдена новая версия: %s (ваша: %s). Обновление...", remote_version, local_version), -1)
                    downloadUpdate(path_to_script)
                else
                    sampAddChatMessage("{800000}[Мод]{FFFFFF} У вас установлена последняя версия.", -1)
                end
            else
                sampAddChatMessage("{800000}[Мод]{FFFFFF} Ошибка чтения файла версии.", -1)
            end
        elseif status == dlstatus.STATUS_ERROR then
            sampAddChatMessage("{800000}[Мод]{FFFFFF} Не удалось проверить версию. Проверьте интернет.", -1)
        end
    end)
end

function downloadUpdate(script_path)
    local tmp_script = script_path .. ".new.lua"
    
    downloadUrlToFile(UPDATE_SCRIPT_URL, tmp_script, function(id, status, p1, p2)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            -- Создаем бэкап на случай ошибки
            os.rename(script_path, script_path .. ".old")
            os.rename(tmp_script, script_path)
            
            sampAddChatMessage("{800000}[Мод]{FFFFFF} Обновление успешно установлено! Перезагрузка...", -1)
            thisScript():reload()
            
        elseif status == dlstatus.STATUS_ERROR then
            sampAddChatMessage("{800000}[Мод]{FFFFFF} Ошибка скачивания файла обновления.", -1)
        end
    end)
end
-- =======================================================

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{800000}[Мод]{FFFFFF} Скрипт загружен! F5 - Меню, Ctrl+F5 - Обновление", -1)

    while true do
        wait(0)
        
        -- Обработка клавиш
        if wasKeyPressed(VK_F5) then
            -- Если зажат Ctrl (любой), проверяем обновления
            if isKeyDown(VK_LCONTROL) or isKeyDown(VK_RCONTROL) then
                checkUpdate()
            -- Иначе открываем меню (если чат закрыт)
            elseif not sampIsChatInputActive() and not sampIsDialogActive() then
                show_menu[0] = not show_menu[0]
            end
        end

        -- Автоматический ввод в диалог репорта
        if waiting_for_report and sampIsDialogActive() then
            wait(50) 
            sampSetCurrentDialogEditboxText(u8:decode("Всем привет!"))
            wait(100) 
            sampCloseCurrentDialogWithButton(1)
            waiting_for_report = false
        end
    end
end