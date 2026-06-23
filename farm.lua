-- ============================================================
-- GITHUB WHITELIST CHECK (БЕЗ КИКА)
-- ============================================================

local WHITELIST_URL = "https://raw.githubusercontent.com/Yuka2241/adlex-whitelist/main/whitelist.json"

local function checkWhitelist()
    local userId = _G.lp.UserId
    local httpService = game:GetService("HttpService")
    
    local success, result = pcall(function()
        return httpService:GetAsync(WHITELIST_URL)
    end)
    
    if success then
        local data = httpService:JSONDecode(result)
        local isAllowed = false
        
        for _, allowedId in ipairs(data.whitelist) do
            if allowedId == userId then
                isAllowed = true
                break
            end
        end
        
        if not isAllowed then
            -- Просто показываем ошибку и удаляем GUI
            local errorGui = Instance.new("ScreenGui", _G.lp:WaitForChild("PlayerGui"))
            local frame = Instance.new("Frame", errorGui)
            frame.Size = UDim2.new(0, 350, 0, 120)
            frame.Position = UDim2.new(0.5, -175, 0.5, -60)
            frame.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
            local stroke = Instance.new("UIStroke", frame)
            stroke.Color = Color3.fromRGB(255, 50, 50)
            stroke.Thickness = 2
            
            local title = Instance.new("TextLabel", frame)
            title.Size = UDim2.new(1, 0, 0, 30)
            title.BackgroundTransparency = 1
            title.Text = "⛔ ДОСТУП ЗАПРЕЩЕН"
            title.TextColor3 = Color3.fromRGB(255, 80, 80)
            title.Font = Enum.Font.GothamBlack
            title.TextSize = 18
            
            local msg = Instance.new("TextLabel", frame)
            msg.Size = UDim2.new(1, -20, 0, 50)
            msg.Position = UDim2.new(0, 10, 0, 35)
            msg.BackgroundTransparency = 1
            msg.Text = "Вас нет в whitelist\n\nВаш UserId: " .. userId
            msg.TextColor3 = Color3.fromRGB(200, 200, 200)
            msg.Font = Enum.Font.GothamMedium
            msg.TextSize = 13
            msg.TextWrapped = true
            
            -- Удаляем основной GUI
            if _G.sg then _G.sg:Destroy() end
            
            -- Ждем и удаляем сообщение об ошибке
            task.wait(5)
            errorGui:Destroy()
            
            -- Останавливаем скрипт
            error("Whitelist check failed - user not authorized")
        end
    else
        warn("[Adlex] Не удалось загрузить whitelist с GitHub")
        -- Если GitHub недоступен — разрешаем доступ (или можешь поменять на false)
    end
end

-- Запускаем проверку
checkWhitelist()

-- ============================================================
-- ADLEX.LUA v2.6 — ПОЛНАЯ ВЕРСИЯ
-- ============================================================

local P = game:GetService("Players")
local U = game:GetService("UserInputService")
local R = game:GetService("RunService")
local H = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")

-- ============================================================
-- СИСТЕМА ЗАЩИТЫ
-- ============================================================

_G.ADLEX_FINGERPRINT = "ADLEX-v2.6-" .. os.clock() .. "-" .. math.random(1000, 9999)
local _ADLEX_WATERMARK_2026 = "AdlexScript|v2.6|Protected|Fingerprint:" .. _G.ADLEX_FINGERPRINT
local _hidden_marker = {
    __version = "2.6.0",
    __author = "Adlex",
    __build = os.time(),
    __integrity = true,
    __protected = true
}

local function crc32(str)
    local crc = 0xFFFFFFFF
    local crc_table = {}
    for i = 0, 255 do
        local c = i
        for j = 0, 7 do
            if c % 2 == 1 then
                c = bit32.bxor(0xEDB88320, bit32.rshift(c, 1))
            else
                c = bit32.rshift(c, 1)
            end
        end
        crc_table[i] = c
    end
    for i = 1, #str do
        local byte = string.byte(str, i)
        crc = bit32.bxor(bit32.rshift(crc, 8), crc_table[bit32.band(bit32.bxor(crc, byte), 0xFF)])
    end
    return bit32.bxor(crc, 0xFFFFFFFF)
end

local function fnv1a_hash(str)
    local hash = 0xcbf29ce484222325
    local prime = 0x100000001b3
    for i = 1, #str do
        hash = bit32.bxor(hash, string.byte(str, i))
        hash = (hash * prime) % (2^64)
    end
    return string.format("%016X", hash)
end

local _ADLEX_CODE_HASH = fnv1a_hash(_ADLEX_WATERMARK_2026 .. _G.ADLEX_FINGERPRINT)
local _ADLEX_CRC = crc32(_ADLEX_WATERMARK_2026)

local _honeypot_log = {}
local function honeypot_trap(func_name)
    return function(...)
        table.insert(_honeypot_log, {
            time = os.time(),
            func = func_name,
            args = {...},
            caller = debug.getinfo and debug.getinfo(2, "S") and debug.getinfo(2, "S").short_src or "unknown"
        })
        return nil
    end
end

_G.getscript = honeypot_trap("getscript")
_G.getscripts = honeypot_trap("getscripts")
_G.getloadedmodules = honeypot_trap("getloadedmodules")
_G.decompile = honeypot_trap("decompile")
_G.hookfunction = honeypot_trap("hookfunction")
_G.getrawmetatable = honeypot_trap("getrawmetatable")

local integrity_checks = {}
integrity_checks[1] = function() return _G.ADLEX_FINGERPRINT:find("ADLEX%-v2.6%-") ~= nil end
integrity_checks[2] = function() return _hidden_marker.__protected == true end
integrity_checks[3] = function() return type(_G.getscript) == "function" end
integrity_checks[4] = function() return crc32(_ADLEX_WATERMARK_2026) == _ADLEX_CRC end

local function runIntegrityChecks()
    local failed = {}
    for i, check in ipairs(integrity_checks) do
        local success, result = pcall(check)
        if not success or not result then
            table.insert(failed, i)
        end
    end
    return #failed == 0, failed
end

local function scheduleDelayedCheck()
    local delay = math.random(30, 120)
    task.delay(delay, function()
        local ok, failed = runIntegrityChecks()
        if not ok then
            warn("[Adlex] Integrity check failed at parts: " .. table.concat(failed, ", "))
        end
        scheduleDelayedCheck()
    end)
end
scheduleDelayedCheck()

task.spawn(function()
    while task.wait(60) do
        local ok, failed = runIntegrityChecks()
        if not ok then
            warn("[Adlex] Periodic integrity check failed: " .. table.concat(failed, ", "))
        end
    end
end)

-- ============================================================
-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ============================================================

_G.lp = P.LocalPlayer
_G.tabs = {}
_G.curTab = nil
_G.isAuto = false
_G.frz = false
_G.noclippedPlayers = false
_G.coords = {x = "0.00", y = "0.00", z = "0.00"}
_G.flyActive = false
_G.flyKey = Enum.KeyCode.B
_G.flyBinding = false
_G.menuKey = Enum.KeyCode.RightShift
_G.streamKey = Enum.KeyCode.F6
_G.menuBinding = false
_G.chamsColor = Color3.fromRGB(128, 128, 128)
_G.antiScreenshotMode = false
_G.streamMode = false
_G.drawingElements = {}
_G.scriptStartTime = os.clock()

-- ============================================================
-- КОНТЕЙНЕР GUI
-- ============================================================

local container = (gethui and gethui()) or CoreGui or _G.lp:WaitForChild("PlayerGui")
if container:FindFirstChild("AdlexMenu") then container.AdlexMenu:Destroy() end
_G.sg = Instance.new("ScreenGui", container)
_G.sg.Name = "AdlexMenu"
_G.sg.ResetOnSpawn = false
_G.sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ============================================================
-- НЕСКРЫВАЕМЫЙ WATERMARK (В CoreGui)
-- ============================================================

local wmGui = Instance.new("ScreenGui", CoreGui)
wmGui.Name = "Adlex_WM_Core"
wmGui.ResetOnSpawn = false
wmGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local wmFrame = Instance.new("Frame", wmGui)
wmFrame.Size = UDim2.new(0, 220, 0, 32)
wmFrame.Position = UDim2.new(1, -230, 0, 10)
wmFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
wmFrame.BorderSizePixel = 0
Instance.new("UICorner", wmFrame).CornerRadius = UDim.new(0, 6)
local wmStroke = Instance.new("UIStroke", wmFrame)
wmStroke.Color = Color3.fromRGB(60, 60, 65)
wmStroke.Thickness = 1

local wmLogo = Instance.new("TextLabel", wmFrame)
wmLogo.Size = UDim2.new(0, 32, 1, 0)
wmLogo.BackgroundTransparency = 1
wmLogo.Text = "A"
wmLogo.TextColor3 = Color3.fromRGB(114, 9, 183)
wmLogo.Font = Enum.Font.GothamBlack
wmLogo.TextSize = 16

local wmText = Instance.new("TextLabel", wmFrame)
wmText.Size = UDim2.new(1, -35, 1, 0)
wmText.Position = UDim2.new(0, 32, 0, 0)
wmText.BackgroundTransparency = 1
wmText.Text = "Adlex v2.6 | Loading..."
wmText.TextColor3 = Color3.fromRGB(220, 220, 225)
wmText.Font = Enum.Font.Code
wmText.TextSize = 11
wmText.TextXAlignment = Enum.TextXAlignment.Left

local wmUptime = Instance.new("TextLabel", wmFrame)
wmUptime.Size = UDim2.new(1, -10, 0, 12)
wmUptime.Position = UDim2.new(0, 5, 1, -12)
wmUptime.BackgroundTransparency = 1
wmUptime.Text = "Uptime: 00:00"
wmUptime.TextColor3 = Color3.fromRGB(120, 120, 125)
wmUptime.Font = Enum.Font.Code
wmUptime.TextSize = 9
wmUptime.TextXAlignment = Enum.TextXAlignment.Right

task.spawn(function()
    local start = os.clock()
    while task.wait(1) do
        if wmText then wmText.Text = "Adlex v2.6 | " .. os.date("%H:%M:%S") end
        if wmUptime then
            local diff = os.clock() - start
            local m = math.floor(diff / 60)
            local s = math.floor(diff % 60)
            wmUptime.Text = string.format("Uptime: %02d:%02d", m, s)
        end
    end
end)

-- ============================================================
-- STREAMER ALERT (REC DETECTED)
-- ============================================================

local streamAlert = Instance.new("Frame", wmGui)
streamAlert.Size = UDim2.new(0, 140, 0, 28)
streamAlert.Position = UDim2.new(1, -380, 0, 10)
streamAlert.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
streamAlert.BorderSizePixel = 0
streamAlert.Visible = false
Instance.new("UICorner", streamAlert).CornerRadius = UDim.new(0, 6)
local saStroke = Instance.new("UIStroke", streamAlert)
saStroke.Color = Color3.fromRGB(255, 50, 50)
saStroke.Thickness = 1

local saText = Instance.new("TextLabel", streamAlert)
saText.Size = UDim2.new(1, 0, 1, 0)
saText.BackgroundTransparency = 1
saText.Text = " REC DETECTED"
saText.TextColor3 = Color3.fromRGB(255, 80, 80)
saText.Font = Enum.Font.GothamBold
saText.TextSize = 12

task.spawn(function()
    while task.wait(0.8) do
        if streamAlert.Visible then
            TweenService:Create(saStroke, TweenInfo.new(0.4), {Color = Color3.fromRGB(255, 0, 0)}):Play()
            TweenService:Create(saText, TweenInfo.new(0.4), {TextColor3 = Color3.fromRGB(255, 0, 0)}):Play()
            task.wait(0.4)
            TweenService:Create(saStroke, TweenInfo.new(0.4), {Color = Color3.fromRGB(100, 0, 0)}):Play()
            TweenService:Create(saText, TweenInfo.new(0.4), {TextColor3 = Color3.fromRGB(255, 80, 80)}):Play()
        end
    end
end)

-- ============================================================
-- KICK WARNING
-- ============================================================

local kickOverlay = Instance.new("Frame", _G.sg)
kickOverlay.Size = UDim2.new(1, 0, 1, 0)
kickOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
kickOverlay.BackgroundTransparency = 0.85
kickOverlay.Visible = false
kickOverlay.ZIndex = 999

local kickBox = Instance.new("Frame", kickOverlay)
kickBox.Size = UDim2.new(0, 400, 0, 150)
kickBox.Position = UDim2.new(0.5, -200, 0.5, -75)
kickBox.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
kickBox.BorderSizePixel = 0
Instance.new("UICorner", kickBox).CornerRadius = UDim.new(0, 8)
local kbStroke = Instance.new("UIStroke", kickBox)
kbStroke.Color = Color3.fromRGB(255, 0, 0)
kbStroke.Thickness = 2

local kickTitle = Instance.new("TextLabel", kickBox)
kickTitle.Size = UDim2.new(1, 0, 0, 40)
kickTitle.BackgroundTransparency = 1
kickTitle.Text = "⚠ CONNECTION LOST"
kickTitle.TextColor3 = Color3.fromRGB(255, 50, 50)
kickTitle.Font = Enum.Font.GothamBlack
kickTitle.TextSize = 20

local kickReason = Instance.new("TextLabel", kickBox)
kickReason.Size = UDim2.new(1, -20, 0, 40)
kickReason.Position = UDim2.new(0, 10, 0, 40)
kickReason.BackgroundTransparency = 1
kickReason.Text = "You have been kicked from the server."
kickReason.TextColor3 = Color3.fromRGB(200, 200, 200)
kickReason.Font = Enum.Font.GothamMedium
kickReason.TextSize = 14

local kickTimer = Instance.new("TextLabel", kickBox)
kickTimer.Size = UDim2.new(1, 0, 0, 30)
kickTimer.Position = UDim2.new(0, 0, 1, -40)
kickTimer.BackgroundTransparency = 1
kickTimer.Text = "Reconnecting in 5..."
kickTimer.TextColor3 = Color3.fromRGB(255, 100, 100)
kickTimer.Font = Enum.Font.Code
kickTimer.TextSize = 16

function showKickWarning(reason)
    kickReason.Text = reason or "Unknown reason"
    kickOverlay.Visible = true
    kickOverlay.BackgroundTransparency = 1
    TweenService:Create(kickOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.85}):Play()
    for i = 5, 1, -1 do
        kickTimer.Text = string.format("Reconnecting in %d...", i)
        task.wait(1)
    end
    kickTimer.Text = "Reconnecting..."
    task.wait(1)
    kickOverlay.Visible = false
end

-- ============================================================
-- KEYBIND HINT
-- ============================================================

local keybindHint = Instance.new("Frame", _G.sg)
keybindHint.Size = UDim2.new(0, 180, 0, 40)
keybindHint.Position = UDim2.new(1, -190, 1, -50)
keybindHint.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
keybindHint.BackgroundTransparency = 1
keybindHint.Visible = false
keybindHint.ZIndex = 100
Instance.new("UICorner", keybindHint).CornerRadius = UDim.new(0, 8)
local khStroke = Instance.new("UIStroke", keybindHint)
khStroke.Color = Color3.fromRGB(60, 60, 65)
khStroke.Thickness = 1

local khKey = Instance.new("TextLabel", keybindHint)
khKey.Size = UDim2.new(0, 30, 0, 24)
khKey.Position = UDim2.new(0, 8, 0.5, -12)
khKey.BackgroundColor3 = Color3.fromRGB(114, 9, 183)
khKey.Text = "B"
khKey.TextColor3 = Color3.fromRGB(255, 255, 255)
khKey.Font = Enum.Font.GothamBold
khKey.TextSize = 12
Instance.new("UICorner", khKey).CornerRadius = UDim.new(0, 4)

local khAction = Instance.new("TextLabel", keybindHint)
khAction.Size = UDim2.new(1, -45, 1, 0)
khAction.Position = UDim2.new(0, 45, 0, 0)
khAction.BackgroundTransparency = 1
khAction.Text = "Fly Activated"
khAction.TextColor3 = Color3.fromRGB(240, 240, 245)
khAction.Font = Enum.Font.GothamMedium
khAction.TextSize = 12
khAction.TextXAlignment = Enum.TextXAlignment.Left

function showKeybindHint(keyName, actionName)
    khKey.Text = keyName
    khAction.Text = actionName
    keybindHint.Visible = true
    keybindHint.BackgroundTransparency = 1
    keybindHint.Position = UDim2.new(1, -190, 1, -30)
    TweenService:Create(keybindHint, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
        Position = UDim2.new(1, -190, 1, -50)
    }):Play()
    task.delay(2, function()
        TweenService:Create(keybindHint, TweenInfo.new(0.3), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -190, 1, -70)
        }):Play()
        task.wait(0.3)
        keybindHint.Visible = false
    end)
end

-- ============================================================
-- УЛУЧШЕННЫЕ ТОСТЫ
-- ============================================================

local toastContainer = Instance.new("Frame", _G.sg)
toastContainer.Size = UDim2.new(0, 220, 1, -20)
toastContainer.Position = UDim2.new(1, -230, 0, 50)
toastContainer.BackgroundTransparency = 1
toastContainer.ZIndex = 50

local toastList = Instance.new("UIListLayout", toastContainer)
toastList.Padding = UDim.new(0, 8)
toastList.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastList.SortOrder = Enum.SortOrder.LayoutOrder
toastList.VerticalAlignment = Enum.VerticalAlignment.Bottom

function showToast(type, titleText, descText)
    local toast = Instance.new("Frame", toastContainer)
    toast.Size = UDim2.new(1, 0, 0, 60)
    toast.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    toast.BorderSizePixel = 0
    toast.LayoutOrder = 1
    toast.ZIndex = 51
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 6)
    
    local tStroke = Instance.new("UIStroke", toast)
    tStroke.Color = Color3.fromRGB(40, 40, 45)
    tStroke.Thickness = 1
    
    local accentColor = Color3.fromRGB(0, 102, 204)
    local icon = ""
    if type == "success" then accentColor = Color3.fromRGB(40, 167, 69); icon = "✓"
    elseif type == "warning" then accentColor = Color3.fromRGB(220, 150, 0); icon = "⚠"
    elseif type == "error" then accentColor = Color3.fromRGB(220, 53, 69); icon = "✕"
    end
    
    local accentBar = Instance.new("Frame", toast)
    accentBar.Size = UDim2.new(0, 4, 1, -10)
    accentBar.Position = UDim2.new(0, 5, 0, 5)
    accentBar.BackgroundColor3 = accentColor
    accentBar.BorderSizePixel = 0
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)
    
    local tIcon = Instance.new("TextLabel", toast)
    tIcon.Size = UDim2.new(0, 20, 0, 20)
    tIcon.Position = UDim2.new(0, 15, 0, 10)
    tIcon.BackgroundTransparency = 1
    tIcon.Text = icon
    tIcon.TextColor3 = accentColor
    tIcon.Font = Enum.Font.GothamBold
    tIcon.TextSize = 14
    
    local tT = Instance.new("TextLabel", toast)
    tT.Size = UDim2.new(1, -45, 0, 20)
    tT.Position = UDim2.new(0, 40, 0, 8)
    tT.BackgroundTransparency = 1
    tT.Text = titleText
    tT.TextColor3 = Color3.fromRGB(255, 255, 255)
    tT.Font = Enum.Font.GothamBold
    tT.TextSize = 12
    tT.TextXAlignment = Enum.TextXAlignment.Left
    
    local dT = Instance.new("TextLabel", toast)
    dT.Size = UDim2.new(1, -45, 0, 20)
    dT.Position = UDim2.new(0, 40, 0, 28)
    dT.BackgroundTransparency = 1
    dT.Text = descText
    dT.TextColor3 = Color3.fromRGB(160, 160, 165)
    dT.Font = Enum.Font.GothamMedium
    dT.TextSize = 10
    dT.TextXAlignment = Enum.TextXAlignment.Left
    
    local progressBar = Instance.new("Frame", toast)
    progressBar.Size = UDim2.new(1, -10, 0, 2)
    progressBar.Position = UDim2.new(0, 5, 1, -4)
    progressBar.BackgroundColor3 = accentColor
    progressBar.BorderSizePixel = 0
    Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 1)
    
    toast.Position = UDim2.new(1, 20, 0, 0)
    TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, 0, 0, 0)
    }):Play()
    
    TweenService:Create(progressBar, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()
    
    task.delay(2.5, function()
        TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, 20, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.3)
        toast:Destroy()
    end)
end

-- ============================================================
-- ANTI-SCREENSHOT СИСТЕМА
-- ============================================================

local function detectRecordingSoftware()
    local detected = {}
    local signatures = {
        "obs64", "obs32", "OBSStudio", "Discord", "discord_overlay",
        "nvcontainer", "nvidia", "ShadowPlay", "xboxgamebar", "GameBar",
        "bandicam", "Bandicam", "fraps", "Fraps", "camtasia", "Camtasia", "xsplit", "XSplit"
    }
    if getgc then
        local gc = getgc()
        for _, obj in ipairs(gc) do
            if type(obj) == "table" then
                for sig, name in pairs(signatures) do
                    if rawget(obj, name) or tostring(obj):lower():find(name:lower()) then
                        detected[name] = true
                    end
                end
            end
        end
    end
    return detected
end

local function createDrawingElement(type, props)
    if not Drawing then return nil end
    local el = Drawing.new(type)
    for k, v in pairs(props) do
        pcall(function() el[k] = v end)
    end
    table.insert(_G.drawingElements, el)
    return el
end

local function enableAntiScreenshot()
    _G.antiScreenshotMode = true
    if _G.mf then
        _G.mf.BackgroundTransparency = 1
        for _, child in ipairs(_G.mf:GetDescendants()) do
            if child:IsA("GuiObject") then
                child.BackgroundTransparency = 1
                child.TextTransparency = 1
                if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
                    child.Visible = false
                end
            end
        end
    end
    if Drawing then
        _G.drawingWatermark = createDrawingElement("Text", {
            Text = "Adlex.lua | PROTECTED | " .. os.date("%H:%M:%S"),
            Size = 14, Center = false, Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Color = Color3.fromRGB(255, 255, 255),
            Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X - 260, 10),
            Visible = true, Font = 2
        })
        _G.drawingCoords = createDrawingElement("Text", {
            Text = "X: 0.00 | Y: 0.00 | Z: 0.00",
            Size = 13, Center = false, Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Color = Color3.fromRGB(0, 255, 128),
            Position = Vector2.new(10, 30), Visible = true, Font = 2
        })
        _G.drawingStatus = createDrawingElement("Text", {
            Text = "Fly: OFF | Freeze: OFF | Noclip: OFF",
            Size = 12, Center = false, Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Color = Color3.fromRGB(255, 200, 0),
            Position = Vector2.new(10, 50), Visible = true, Font = 2
        })
    end
    showToast("success", "Anti-Screenshot", "Режим защиты активирован")
end

local function disableAntiScreenshot()
    _G.antiScreenshotMode = false
    if _G.mf then
        _G.mf.BackgroundTransparency = 0
        for _, child in ipairs(_G.mf:GetDescendants()) do
            if child:IsA("GuiObject") then
                child.BackgroundTransparency = 0
                child.TextTransparency = 0
                if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
                    child.Visible = true
                end
            end
        end
    end
    for _, el in ipairs(_G.drawingElements) do
        pcall(function() el:Remove() end)
    end
    _G.drawingElements = {}
    _G.drawingWatermark = nil
    _G.drawingCoords = nil
    _G.drawingStatus = nil
    showToast("success", "Anti-Screenshot", "Режим защиты отключен")
end

local function toggleStreamMode()
    _G.streamMode = not _G.streamMode
    if _G.sg then _G.sg.Enabled = not _G.streamMode end
    for _, el in ipairs(_G.drawingElements) do
        pcall(function() el.Visible = not _G.streamMode end)
    end
    if _G.streamMode then
        showToast("warning", "Stream Mode", "GUI скрыт")
    else
        showToast("success", "Stream Mode", "GUI восстановлен")
    end
end

-- ============================================================
-- ADLEX RECOGNITION (СКРЫТЫЙ)
-- ============================================================

local ADLEX_MARKER_NAME = "_AdlexMarker_"
local ADLEX_TAG_NAME = "AdlexTag_Local"
local adlexUsers = {}

local function createInvisibleMarker(character)
    if not character then return end
    local old = character:FindFirstChild(ADLEX_MARKER_NAME)
    if old then old:Destroy() end
    local marker = Instance.new("Part")
    marker.Name = ADLEX_MARKER_NAME
    marker.Size = Vector3.new(0.1, 0.1, 0.1)
    marker.Transparency = 1
    marker.CanCollide = false
    marker.Anchored = true
    marker.Parent = character
    local head = character:FindFirstChild("Head")
    if head then marker.CFrame = head.CFrame + Vector3.new(0, 3, 0) end
    marker:SetAttribute("AdlexUser", true)
    marker:SetAttribute("Version", "2.6")
end

local function createLocalTag(player)
    if not player or not player.Character then return end
    local old = player.Character:FindFirstChild(ADLEX_TAG_NAME)
    if old then old:Destroy() end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = ADLEX_TAG_NAME
    billboard.Adornee = head
    billboard.Parent = player.Character
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.ResetOnSpawn = false
    billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(114, 9, 183)
    stroke.Thickness = 1.5
    local logo = Instance.new("TextLabel", frame)
    logo.Size = UDim2.new(0, 25, 1, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "A"
    logo.TextColor3 = Color3.fromRGB(114, 9, 183)
    logo.Font = Enum.Font.GothamBlack
    logo.TextSize = 18
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -25, 0, 20)
    label.Position = UDim2.new(0, 25, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = "ADLEX"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    local version = Instance.new("TextLabel", frame)
    version.Size = UDim2.new(1, -25, 0, 14)
    version.Position = UDim2.new(0, 25, 0, 20)
    version.BackgroundTransparency = 1
    version.Text = "v2.6 • Active"
    version.TextColor3 = Color3.fromRGB(40, 167, 69)
    version.Font = Enum.Font.Code
    version.TextSize = 9
    version.TextXAlignment = Enum.TextXAlignment.Left
    local statusDot = Instance.new("Frame", frame)
    statusDot.Size = UDim2.new(0, 6, 0, 6)
    statusDot.Position = UDim2.new(1, -12, 0.5, -3)
    statusDot.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
    statusDot.BorderSizePixel = 0
    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
    task.spawn(function()
        while billboard and billboard.Parent do
            TweenService:Create(statusDot, TweenInfo.new(0.8), {
                BackgroundTransparency = 0.7,
                Size = UDim2.new(0, 10, 0, 10),
                Position = UDim2.new(1, -14, 0.5, -5)
            }):Play()
            task.wait(0.8)
            TweenService:Create(statusDot, TweenInfo.new(0.8), {
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 6, 0, 6),
                Position = UDim2.new(1, -12, 0.5, -3)
            }):Play()
            task.wait(0.8)
        end
    end)
end

local function scanForAdlexUsers()
    for _, player in ipairs(P:GetPlayers()) do
        if player ~= _G.lp and player.Character then
            local marker = player.Character:FindFirstChild(ADLEX_MARKER_NAME)
            if marker and marker:GetAttribute("AdlexUser") == true and not adlexUsers[player.UserId] then
                adlexUsers[player.UserId] = true
                showToast("success", "Adlex User Detected", player.Name .. " тоже использует Adlex!")
                createLocalTag(player)
                local hl = player.Character:FindFirstChildOfClass("Highlight")
                if hl then hl.OutlineColor = Color3.fromRGB(114, 9, 183) end
            elseif not marker and adlexUsers[player.UserId] then
                adlexUsers[player.UserId] = nil
                local tag = player.Character:FindFirstChild(ADLEX_TAG_NAME)
                if tag then tag:Destroy() end
            end
        end
    end
end

local function setupSelfMarker()
    if _G.lp.Character then createInvisibleMarker(_G.lp.Character) end
    _G.lp.CharacterAdded:Connect(function(char)
        char:WaitForChild("Head", 5)
        task.wait(0.5)
        createInvisibleMarker(char)
    end)
end

task.spawn(function()
    while task.wait(3) do scanForAdlexUsers() end
end)

P.PlayerRemoving:Connect(function(player)
    if adlexUsers[player.UserId] then adlexUsers[player.UserId] = nil end
end)

-- ============================================================
-- ОСНОВНОЙ GUI
-- ============================================================

_G.mf = Instance.new("Frame", _G.sg)
_G.mf.Size = UDim2.new(0, 520, 0, 300)
_G.mf.Position = UDim2.new(0.5, -260, 0.5, -150)
_G.mf.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
_G.mf.BorderSizePixel = 0
_G.mf.BackgroundTransparency = 1
Instance.new("UICorner", _G.mf).CornerRadius = UDim.new(0, 6)
local menuStroke = Instance.new("UIStroke", _G.mf)
menuStroke.Color = Color3.fromRGB(40, 40, 45)
menuStroke.Thickness = 1

_G.sb = Instance.new("Frame", _G.mf)
_G.sb.Size = UDim2.new(0, 150, 1, 0)
_G.sb.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
_G.sb.BorderSizePixel = 0
Instance.new("UICorner", _G.sb).CornerRadius = UDim.new(0, 6)

_G.logoContainer = Instance.new("Frame", _G.sb)
_G.logoContainer.Size = UDim2.new(1, 0, 0, 50)
_G.logoContainer.BackgroundTransparency = 1
local letters = {"A", "D", "L", "E", "X"}
for i, l in ipairs(letters) do
    local lbl = Instance.new("TextLabel", _G.logoContainer)
    lbl.Size = UDim2.new(0, 15, 1, 0)
    lbl.Position = UDim2.new(0, 15 + (i-1)*16, 0, 0)
    lbl.Text = l
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 18
    lbl.Font = Enum.Font.GothamBold
    lbl.BackgroundTransparency = 1
    lbl.TextTransparency = 1
    task.spawn(function()
        task.wait(0.2 * i)
        TweenService:Create(lbl, TweenInfo.new(0.6), {TextTransparency = 0}):Play()
    end)
end

_G.ca = Instance.new("Frame", _G.mf)
_G.ca.Size = UDim2.new(1, -165, 1, -20)
_G.ca.Position = UDim2.new(0, 165, 0, 10)
_G.ca.BackgroundTransparency = 1

_G.mf.Position = UDim2.new(0.5, -260, 0.3, -150)
TweenService:Create(_G.mf, TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -260, 0.5, -150),
    BackgroundTransparency = 0
}):Play()

-- Tooltip
local tooltipLabel = Instance.new("TextLabel", _G.sg)
tooltipLabel.Size = UDim2.new(0, 180, 0, 25)
tooltipLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
tooltipLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
tooltipLabel.Font = Enum.Font.GothamMedium
tooltipLabel.TextSize = 11
tooltipLabel.Visible = false
tooltipLabel.ZIndex = 100
Instance.new("UICorner", tooltipLabel).CornerRadius = UDim.new(0, 4)
local tooltipStroke = Instance.new("UIStroke", tooltipLabel)
tooltipStroke.Color = Color3.fromRGB(60, 60, 65)

local function showTooltip(text)
    tooltipLabel.Text = text
    tooltipLabel.Visible = true
    local connection
    connection = R.RenderStepped:Connect(function()
        if not tooltipLabel.Visible then connection:Disconnect() return end
        local mousePos = U:GetMouseLocation()
        tooltipLabel.Position = UDim2.new(0, mousePos.X + 15, 0, mousePos.Y - 35)
    end)
end
local function hideTooltip() tooltipLabel.Visible = false end

-- Конструктор кнопок
function _G.cBtn(parent, text, pos, size, color, tooltipText)
    local b = Instance.new("TextButton", parent)
    b.Size, b.Position, b.BackgroundColor3, b.Text = size, pos, color, text
    b.TextColor3, b.Font, b.TextSize, b.ZIndex, b.ClipsDescendants = Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, 13, 5, true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local stroke = Instance.new("UIStroke", b)
    stroke.Color, stroke.Thickness, stroke.Enabled = Color3.fromRGB(255, 255, 255), 1.5, false
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.2), {
            Size = UDim2.new(size.X.Scale, size.X.Offset + 4, size.Y.Scale, size.Y.Offset + 4),
            Position = UDim2.new(pos.X.Scale, pos.X.Offset - 2, pos.Y.Scale, pos.Y.Offset - 2)
        }):Play()
        if tooltipText then showTooltip(tooltipText) end
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.2), {Size = size, Position = pos}):Play()
        hideTooltip()
    end)
    b.MouseButton1Down:Connect(function()
        local mousePos = U:GetMouseLocation()
        local relativeX = mousePos.X - b.AbsolutePosition.X
        local relativeY = (mousePos.Y - 36) - b.AbsolutePosition.Y
        local ripple = Instance.new("Frame", b)
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.6
        ripple.Position = UDim2.new(0, relativeX, 0, relativeY)
        Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
        TweenService:Create(ripple, TweenInfo.new(0.4), {
            Size = UDim2.new(0, size.X.Offset * 2.5, 0, size.X.Offset * 2.5),
            Position = UDim2.new(0, relativeX - size.X.Offset * 1.25, 0, relativeY - size.X.Offset * 1.25),
            BackgroundTransparency = 1
        }):Play()
        Debris:AddItem(ripple, 0.4)
    end)
    return b, stroke
end

-- Вкладки
function _G.addTab(name, title)
    local count = 0
    for _ in pairs(_G.tabs) do count = count + 1 end
    local b = _G.cBtn(_G.sb, "  "..name, UDim2.new(0, 10, 0, 60 + count * 40), UDim2.new(1, -20, 0, 35), Color3.fromRGB(22, 22, 26))
    b.TextColor3, b.TextXAlignment, b.Font = Color3.fromRGB(150, 150, 155), 0, Enum.Font.GothamMedium
    local f = Instance.new("Frame", _G.ca)
    f.Size, f.BackgroundTransparency, f.Visible = UDim2.new(1, 0, 1, 0), 1, false
    local t = Instance.new("TextLabel", f)
    t.Size, t.BackgroundTransparency, t.Text = UDim2.new(1, 0, 0, 30), 1, string.upper(title)
    t.TextColor3, t.TextSize, t.Font, t.TextXAlignment = Color3.fromRGB(130, 130, 135), 11, Enum.Font.GothamBold, Enum.TextXAlignment.Left
    _G.tabs[name] = {b = b, f = f, name = name}
    b.MouseButton1Click:Connect(function()
        for _, v in pairs(_G.tabs) do
            v.f.Visible, v.b.BackgroundColor3, v.b.TextColor3 = false, _G.sb.BackgroundColor3, Color3.fromRGB(150, 150, 155)
        end
        f.Visible, b.BackgroundColor3, b.TextColor3, _G.curTab = true, Color3.fromRGB(42, 42, 48), Color3.fromRGB(255, 255, 255), name
    end)
    if not _G.curTab then
        f.Visible, b.BackgroundColor3, b.TextColor3, _G.curTab = true, Color3.fromRGB(42, 42, 48), Color3.fromRGB(255, 255, 255), name
    end
    return f
end

-- Drag система
local drag, dInp, dragStart, startPos
_G.mf.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true
        dragStart = i.Position
        startPos = _G.mf.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then drag = false end
        end)
    end
end)
_G.mf.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement then dInp = i end
end)
U.InputChanged:Connect(function(i)
    if i == dInp and drag then
        local d = i.Position - dragStart
        _G.mf.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

-- Создание вкладок
_G.p1 = _G.addTab("Coordinates", "Position Computation")
_G.p2 = _G.addTab("Teleportation", "Vector3 Matrix Teleport")
_G.p3 = _G.addTab("Settings", "Interface Customization")

-- ============================================================
-- ВКЛАДКА COORDINATES
-- ============================================================

_G.disp = Instance.new("TextLabel", _G.p1)
_G.disp.Size = UDim2.new(1, -15, 0, 110)
_G.disp.Position = UDim2.new(0, 0, 0, 40)
_G.disp.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
_G.disp.TextColor3 = Color3.fromRGB(240, 240, 245)
_G.disp.TextSize = 16
_G.disp.Font = Enum.Font.Code
_G.disp.LineHeight = 1.4
_G.disp.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", _G.disp).CornerRadius = UDim.new(0, 5)

local bx = _G.cBtn(_G.p1, "Copy X", UDim2.new(0, 0, 0, 165), UDim2.new(0, 100, 0, 35), Color3.fromRGB(0, 102, 204), "Copy X")
local by = _G.cBtn(_G.p1, "Copy Y", UDim2.new(0, 110, 0, 165), UDim2.new(0, 100, 0, 35), Color3.fromRGB(0, 102, 204), "Copy Y")
local bz = _G.cBtn(_G.p1, "Copy Z", UDim2.new(0, 220, 0, 165), UDim2.new(0, 100, 0, 35), Color3.fromRGB(0, 102, 204), "Copy Z")

bx.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(tostring(_G.coords.x))
        showToast("success", "Copied", "X: " .. _G.coords.x)
    end
end)
by.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(tostring(_G.coords.y))
        showToast("success", "Copied", "Y: " .. _G.coords.y)
    end
end)
bz.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(tostring(_G.coords.z))
        showToast("success", "Copied", "Z: " .. _G.coords.z)
    end
end)

local fz = _G.cBtn(_G.p1, "Freeze: OFF", UDim2.new(0, 0, 0, 215), UDim2.new(0, 160, 0, 35), Color3.fromRGB(40, 40, 45), "Freeze")
fz.TextColor3 = Color3.fromRGB(180, 180, 185)

local flb = _G.cBtn(_G.p1, "Fly: OFF [B]", UDim2.new(0, 170, 0, 215), UDim2.new(0, 160, 0, 35), Color3.fromRGB(40, 40, 45), "Fly")
flb.TextColor3 = Color3.fromRGB(180, 180, 185)

-- ============================================================
-- ВКЛАДКА TELEPORTATION
-- ============================================================

-- Валидация полей ввода
local function validateCoordInput(textBox)
    local function filterText()
        local text = textBox.Text
        local filtered = text:gsub("[^%d%-%+%.]", "")
        filtered = filtered:gsub("%-%-", "-")
        filtered = filtered:gsub("%+%+", "+")
        filtered = filtered:gsub("%.%.", ".")
        local dotCount = 0
        local result = ""
        for i = 1, #filtered do
            local c = filtered:sub(i, i)
            if c == "." then
                dotCount = dotCount + 1
                if dotCount > 1 then continue end
            end
            result = result .. c
        end
        if result ~= text then textBox.Text = result end
    end
    textBox:GetPropertyChangedSignal("Text"):Connect(filterText)
    textBox.FocusLost:Connect(filterText)
end

local function cInp(p, ph, pos, accentColor)
    local b = Instance.new("TextBox", p)
    b.Size = UDim2.new(0, 100, 0, 35)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
    b.PlaceholderText = ph
    b.Text = ""
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.PlaceholderColor3 = Color3.fromRGB(100, 100, 105)
    b.TextSize = 14
    b.Font = Enum.Font.Code
    b.ClearTextOnFocus = false
    b.ZIndex = 5
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local indicator = Instance.new("Frame", b)
    indicator.Size = UDim2.new(1, 0, 0, 2)
    indicator.Position = UDim2.new(0, 0, 1, -2)
    indicator.BackgroundColor3 = accentColor
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 6
    validateCoordInput(b)
    return b
end

_G.ix = cInp(_G.p2, "X", UDim2.new(0, 0, 0, 40), Color3.fromRGB(220, 53, 69))
_G.iy = cInp(_G.p2, "Y", UDim2.new(0, 115, 0, 40), Color3.fromRGB(40, 167, 69))
_G.iz = cInp(_G.p2, "Z", UDim2.new(0, 230, 0, 40), Color3.fromRGB(0, 102, 204))

local tp = _G.cBtn(_G.p2, "Instant TP", UDim2.new(0, 0, 0, 95), UDim2.new(0, 160, 0, 35), Color3.fromRGB(114, 9, 183), "TP")
local at = _G.cBtn(_G.p2, "Auto TP: OFF", UDim2.new(0, 170, 0, 95), UDim2.new(0, 160, 0, 35), Color3.fromRGB(40, 40, 45), "Auto TP")
at.TextColor3 = Color3.fromRGB(180, 180, 185)

local noclipBtn = _G.cBtn(_G.p2, "Noclip: OFF", UDim2.new(0, 0, 0, 145), UDim2.new(0, 160, 0, 35), Color3.fromRGB(40, 40, 45), "Noclip")
noclipBtn.TextColor3 = Color3.fromRGB(180, 180, 185)

local function doTp()
    local r = _G.lp.Character and _G.lp.Character:FindFirstChild("HumanoidRootPart")
    if r then
        local oA = r.Anchored
        r.Anchored = false
        r.CFrame = CFrame.new(
            tonumber(_G.ix.Text) or 0,
            tonumber(_G.iy.Text) or 0,
            tonumber(_G.iz.Text) or 0
        )
        if oA or _G.frz then task.wait() r.Anchored = true end
    end
end
tp.MouseButton1Click:Connect(doTp)

at.MouseButton1Click:Connect(function()
    _G.isAuto = not _G.isAuto
    at.Text = _G.isAuto and "Auto TP: ON" or "Auto TP: OFF"
    at.BackgroundColor3 = _G.isAuto and Color3.fromRGB(30, 120, 50) or Color3.fromRGB(40, 40, 45)
    at.TextColor3 = _G.isAuto and Color3.fromRGB(220, 220, 225) or Color3.fromRGB(180, 180, 185)
    if _G.isAuto then
        task.spawn(function()
            while _G.isAuto do
                doTp()
                task.wait(0.1)
            end
        end)
    end
end)

noclipBtn.MouseButton1Click:Connect(function()
    _G.noclippedPlayers = not _G.noclippedPlayers
    noclipBtn.Text = _G.noclippedPlayers and "Noclip: ON" or "Noclip: OFF"
    noclipBtn.BackgroundColor3 = _G.noclippedPlayers and Color3.fromRGB(30, 120, 50) or Color3.fromRGB(40, 40, 45)
    noclipBtn.TextColor3 = _G.noclippedPlayers and Color3.fromRGB(220, 220, 225) or Color3.fromRGB(180, 180, 185)
end)

-- ============================================================
-- RENDERSTEPPED
-- ============================================================

local nUp = 0
R.RenderStepped:Connect(function()
    if os.clock() >= nUp then
        nUp = os.clock() + 0.1
        local r = _G.lp.Character and _G.lp.Character:FindFirstChild("HumanoidRootPart")
        if r and _G.disp then
            _G.coords.x = string.format("%.2f", r.Position.X)
            _G.coords.y = string.format("%.2f", r.Position.Y)
            _G.coords.z = string.format("%.2f", r.Position.Z)
            _G.disp.Text = "  X: " .. _G.coords.x .. "\n  Y: " .. _G.coords.y .. "\n  Z: " .. _G.coords.z
        end
    end
    
    if _G.noclippedPlayers and _G.lp.Character then
        local myRoot = _G.lp.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then
            for _, pl in pairs(P:GetPlayers()) do
                if pl ~= _G.lp and pl.Character then
                    local otherRoot = pl.Character:FindFirstChild("HumanoidRootPart")
                    if otherRoot and (myRoot.Position - otherRoot.Position).Magnitude < 4 then
                        myRoot.CFrame = myRoot.CFrame + (myRoot.Position - otherRoot.Position).Unit * 0.1
                    end
                end
            end
        end
    end
    
    local c = _G.lp.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if _G.flyActive and r then
        local cam = workspace.CurrentCamera.CFrame
        local m = Vector3.new(0, 0, 0)
        if U:IsKeyDown(Enum.KeyCode.W) then m = m + cam.LookVector end
        if U:IsKeyDown(Enum.KeyCode.S) then m = m - cam.LookVector end
        if U:IsKeyDown(Enum.KeyCode.A) then m = m - cam.RightVector end
        if U:IsKeyDown(Enum.KeyCode.D) then m = m + cam.RightVector end
        if U:IsKeyDown(Enum.KeyCode.Space) then m = m + Vector3.new(0, 1, 0) end
        if U:IsKeyDown(Enum.KeyCode.LeftShift) then m = m - Vector3.new(0, 1, 0) end
        if m.Magnitude ~= 0 then
            r.Velocity = m.Unit * 50
        else
            r.Velocity = Vector3.new(0, 0.1, 0)
        end
    end
    
    if _G.antiScreenshotMode then
        if _G.drawingWatermark then
            _G.drawingWatermark.Text = "Adlex.lua | PROTECTED | " .. os.date("%H:%M:%S")
            _G.drawingWatermark.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X - 260, 10)
        end
        if _G.drawingCoords and _G.lp.Character then
            local root = _G.lp.Character:FindFirstChild("HumanoidRootPart")
            if root then
                _G.drawingCoords.Text = string.format("X: %.2f | Y: %.2f | Z: %.2f",
                    root.Position.X, root.Position.Y, root.Position.Z)
            end
        end
        if _G.drawingStatus then
            _G.drawingStatus.Text = string.format("Fly: %s | Freeze: %s | Noclip: %s",
                _G.flyActive and "ON" or "OFF",
                _G.frz and "ON" or "OFF",
                _G.noclippedPlayers and "ON" or "OFF")
        end
    end
end)

-- Freeze
fz.MouseButton1Click:Connect(function()
    _G.frz = not _G.frz
    fz.Text = _G.frz and "Freeze: ON" or "Freeze: OFF"
    fz.BackgroundColor3 = _G.frz and Color3.fromRGB(160, 40, 50) or Color3.fromRGB(40, 40, 45)
    fz.TextColor3 = _G.frz and Color3.fromRGB(220, 220, 225) or Color3.fromRGB(180, 180, 185)
    local r = _G.lp.Character and _G.lp.Character:FindFirstChild("HumanoidRootPart")
    if r then r.Anchored = _G.frz end
end)

_G.lp.CharacterAdded:Connect(function(c)
    if _G.frz then
        local r = c:WaitForChild("HumanoidRootPart", 5)
        if r then r.Anchored = true end
    end
    if _G.flyActive then
        _G.flyActive = false
        uFlV()
    end
end)

-- Chams
local function applyChams(player)
    if player == _G.lp then return end
    local function setup(char)
        if not char then return end
        local hl = char:FindFirstChildOfClass("Highlight") or Instance.new("Highlight", char)
        hl.FillColor = _G.chamsColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0.2
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
    setup(player.Character)
    player.CharacterAdded:Connect(setup)
end
for _, pl in pairs(P:GetPlayers()) do applyChams(pl) end
P.PlayerAdded:Connect(applyChams)

-- Fly
local function uFlV()
    flb.Text = "Fly: " .. (_G.flyActive and "ON" or "OFF") .. " [" .. _G.flyKey.Name .. "]"
    flb.BackgroundColor3 = _G.flyActive and Color3.fromRGB(30, 120, 50) or Color3.fromRGB(40, 40, 45)
    flb.TextColor3 = _G.flyActive and Color3.fromRGB(220, 220, 225) or Color3.fromRGB(180, 180, 185)
end

local function tgFl()
    local c = _G.lp.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if r then
        _G.flyActive = not _G.flyActive
        uFlV()
        if not _G.flyActive then r.Velocity = Vector3.new(0, 0, 0) end
    end
end
flb.MouseButton1Click:Connect(tgFl)
flb.MouseButton2Click:Connect(function()
    _G.flyBinding = true
    showToast("info", "Binding", "Нажмите клавишу для полёта")
end)

-- ============================================================
-- ВКЛАДКА SETTINGS (С СКРОЛЛИНГОМ)
-- ============================================================

-- Темы
local Themes = {
    Black = {bg = Color3.fromRGB(15, 15, 18), side = Color3.fromRGB(22, 22, 26), text = Color3.fromRGB(255, 255, 255), wmText = Color3.fromRGB(240, 240, 245)},
    Gray = {bg = Color3.fromRGB(35, 35, 40), side = Color3.fromRGB(45, 45, 50), text = Color3.fromRGB(240, 240, 245), wmText = Color3.fromRGB(240, 240, 245)},
    Light = {bg = Color3.fromRGB(240, 240, 245), side = Color3.fromRGB(225, 225, 230), text = Color3.fromRGB(20, 20, 25), wmText = Color3.fromRGB(20, 20, 25)}
}
local curTheme = Themes.Black

local function uTheme()
    _G.mf.BackgroundColor3 = curTheme.bg
    _G.sb.BackgroundColor3 = curTheme.side
    wmFrame.BackgroundColor3 = curTheme.bg
    wmText.TextColor3 = curTheme.wmText
    for _, v in pairs(_G.tabs) do
        if v.b then
            v.b.BackgroundColor3 = curTheme.side
            if _G.curTab == v.name then
                v.b.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
            end
        end
    end
end

local function updateMenuKeyUI()
    if _G.tabs["Settings"] and _G.tabs["Settings"].f then
        local btn = _G.tabs["Settings"].f:FindFirstChild("MKeyBtn")
        if btn then btn.Text = "Menu Key: [" .. _G.menuKey.Name .. "]" end
    end
end

-- Скроллинг для Settings
local settingsScroll = Instance.new("ScrollingFrame", _G.p3)
settingsScroll.Size = UDim2.new(1, 0, 1, -10)
settingsScroll.Position = UDim2.new(0, 0, 0, 10)
settingsScroll.BackgroundTransparency = 1
settingsScroll.BorderSizePixel = 0
settingsScroll.ScrollBarThickness = 6
settingsScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85)
settingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
settingsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
settingsScroll.ClipsDescendants = true

local settingsLayout = Instance.new("UIListLayout", settingsScroll)
settingsLayout.Padding = UDim.new(0, 8)
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Dropdown тем
local dropContainer = Instance.new("Frame", settingsScroll)
dropContainer.Size = UDim2.new(0, 160, 0, 35)
dropContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
dropContainer.BorderSizePixel = 0
dropContainer.ZIndex = 6
dropContainer.LayoutOrder = 1
Instance.new("UICorner", dropContainer).CornerRadius = UDim.new(0, 5)

local dropMainBtn = Instance.new("TextButton", dropContainer)
dropMainBtn.Size = UDim2.new(1, 0, 1, 0)
dropMainBtn.BackgroundTransparency = 1
dropMainBtn.Text = "Select Theme v"
dropMainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropMainBtn.Font = Enum.Font.GothamBold
dropMainBtn.TextSize = 13
dropMainBtn.ZIndex = 7

local dropListFrame = Instance.new("Frame", dropContainer)
dropListFrame.Size = UDim2.new(1, 0, 0, 95)
dropListFrame.Position = UDim2.new(0, 0, 1, 5)
dropListFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
dropListFrame.BorderSizePixel = 0
dropListFrame.Visible = false
dropListFrame.ZIndex = 8
Instance.new("UICorner", dropListFrame).CornerRadius = UDim.new(0, 5)

local dropListLayout = Instance.new("UIListLayout", dropListFrame)
dropListLayout.Padding = UDim.new(0, 2)

local function createDropElement(themeKey, displayName)
    local b = _G.cBtn(dropListFrame, displayName, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 28), Color3.fromRGB(32, 32, 38))
    b.ZIndex = 9
    b.MouseButton1Click:Connect(function()
        curTheme = Themes[themeKey]
        uTheme()
        dropMainBtn.Text = displayName .. " v"
        dropListFrame.Visible = false
        showToast("success", "Theme Changed", "Новая тема применена")
    end)
end
createDropElement("Black", "Dark Theme")
createDropElement("Gray", "Gray Theme")
createDropElement("Light", "Light Theme")
dropMainBtn.MouseButton1Click:Connect(function()
    dropListFrame.Visible = not dropListFrame.Visible
end)

-- Прозрачность
local function cInpLocal(p, ph, pos)
    local b = Instance.new("TextBox", p)
    b.Size = UDim2.new(0, 80, 0, 35)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
    b.PlaceholderText = ph
    b.Text = ""
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.PlaceholderColor3 = Color3.fromRGB(100, 100, 105)
    b.TextSize = 14
    b.Font = Enum.Font.Code
    b.ClearTextOnFocus = false
    b.ZIndex = 5
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end

local opacityFrame = Instance.new("Frame", settingsScroll)
opacityFrame.Size = UDim2.new(0, 200, 0, 35)
opacityFrame.BackgroundTransparency = 1
opacityFrame.LayoutOrder = 2

local opacityInput = cInpLocal(opacityFrame, "% (0-100)", UDim2.new(0, 0, 0, 0))
local applyOpacityBtn = _G.cBtn(opacityFrame, "Set Opacity", UDim2.new(0, 90, 0, 0), UDim2.new(0, 110, 0, 35), Color3.fromRGB(0, 102, 204), "Set opacity")
applyOpacityBtn.MouseButton1Click:Connect(function()
    local number = tonumber(opacityInput.Text)
    if number then
        if number < 0 then number = 0 elseif number > 100 then number = 100 end
        local value = number / 100
        _G.mf.BackgroundTransparency = value
        _G.sb.BackgroundTransparency = value
        showToast("success", "Opacity Set", "Прозрачность: " .. number .. "%")
    else
        opacityInput.Text = "Error"
        task.wait(0.6)
        opacityInput.Text = ""
    end
end)

-- Chams color
local chamsFrame = Instance.new("Frame", settingsScroll)
chamsFrame.Size = UDim2.new(0, 260, 0, 35)
chamsFrame.BackgroundTransparency = 1
chamsFrame.LayoutOrder = 3

local chamsInput = cInpLocal(chamsFrame, "R,G,B", UDim2.new(0, 0, 0, 0))
chamsInput.Size = UDim2.new(0, 110, 0, 35)
local applyChamsBtn = _G.cBtn(chamsFrame, "Set Chams Color", UDim2.new(0, 120, 0, 0), UDim2.new(0, 140, 0, 35), Color3.fromRGB(0, 102, 204), "Set chams color")
applyChamsBtn.MouseButton1Click:Connect(function()
    local r, g, b = chamsInput.Text:match("(%d+),(%d+),(%d+)")
    if r and g and b then
        _G.chamsColor = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
        for _, pl in pairs(P:GetPlayers()) do
            if pl.Character and pl.Character:FindFirstChildOfClass("Highlight") then
                pl.Character:FindFirstChildOfClass("Highlight").FillColor = _G.chamsColor
            end
        end
        showToast("success", "Chams Updated", "Цвет обновлен")
    else
        chamsInput.Text = "Format: 255,0,0"
        task.wait(1.5)
        chamsInput.Text = ""
    end
end)

-- Кнопки защиты
local antiShotBtn = _G.cBtn(settingsScroll, "Anti-Screenshot: OFF", UDim2.new(0, 0, 0, 0), UDim2.new(0, 200, 0, 35), Color3.fromRGB(40, 40, 45), "Toggle anti-screenshot")
antiShotBtn.TextColor3 = Color3.fromRGB(180, 180, 185)
antiShotBtn.LayoutOrder = 4

antiShotBtn.MouseButton1Click:Connect(function()
    if _G.antiScreenshotMode then
        disableAntiScreenshot()
        antiShotBtn.Text = "Anti-Screenshot: OFF"
        antiShotBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        antiShotBtn.TextColor3 = Color3.fromRGB(180, 180, 185)
    else
        enableAntiScreenshot()
        antiShotBtn.Text = "Anti-Screenshot: ON"
        antiShotBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 50)
        antiShotBtn.TextColor3 = Color3.fromRGB(220, 220, 225)
    end
end)

local streamBtn = _G.cBtn(settingsScroll, "Stream Mode [F6]", UDim2.new(0, 0, 0, 0), UDim2.new(0, 200, 0, 35), Color3.fromRGB(114, 9, 183), "Toggle stream mode")
streamBtn.LayoutOrder = 5
streamBtn.MouseButton1Click:Connect(toggleStreamMode)

local detectBtn = _G.cBtn(settingsScroll, "Scan Recording Apps", UDim2.new(0, 0, 0, 0), UDim2.new(0, 200, 0, 35), Color3.fromRGB(220, 120, 0), "Scan for recording software")
detectBtn.LayoutOrder = 6
detectBtn.MouseButton1Click:Connect(function()
    local detected = detectRecordingSoftware()
    if next(detected) then
        local list = ""
        for name, _ in pairs(detected) do list = list .. name .. ", " end
        showToast("warning", "Detected", "Найдены: " .. list:sub(1, -3))
    else
        showToast("success", "Clean", "Программы записи не обнаружены")
    end
end)

local mkb = _G.cBtn(settingsScroll, "Menu Key: [RightShift]", UDim2.new(0, 0, 0, 0), UDim2.new(0, 200, 0, 35), Color3.fromRGB(114, 9, 183), "Change menu key")
mkb.Name = "MKeyBtn"
mkb.LayoutOrder = 7
mkb.MouseButton1Click:Connect(function()
    _G.menuBinding = true
    showToast("info", "Binding", "Нажмите клавишу для меню")
end)

-- Bind overlay
_G.bindOverlay = Instance.new("Frame", _G.sg)
_G.bindOverlay.Size = UDim2.new(0, 300, 0, 60)
_G.bindOverlay.Position = UDim2.new(0.5, -150, 0.5, -30)
_G.bindOverlay.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
_G.bindOverlay.BorderSizePixel = 0
_G.bindOverlay.Visible = false
_G.bindOverlay.ZIndex = 200
Instance.new("UICorner", _G.bindOverlay).CornerRadius = UDim.new(0, 6)
local boStroke = Instance.new("UIStroke", _G.bindOverlay)
boStroke.Color = Color3.fromRGB(80, 80, 90)
boStroke.Thickness = 1

-- ============================================================
-- ОБРАБОТКА КЛАВИШ
-- ============================================================

U.InputBegan:Connect(function(i, g)
    if _G.flyBinding and i.KeyCode ~= Enum.KeyCode.Unknown and i.UserInputType == Enum.UserInputType.Keyboard then
        _G.flyKey = i.KeyCode
        _G.flyBinding = false
        _G.bindOverlay.Visible = false
        uFlV()
        showToast("success", "Fly Key Set", "Клавиша: " .. _G.flyKey.Name)
        return
    end
    if _G.menuBinding and i.KeyCode ~= Enum.KeyCode.Unknown and i.UserInputType == Enum.UserInputType.Keyboard then
        _G.menuKey = i.KeyCode
        _G.menuBinding = false
        _G.bindOverlay.Visible = false
        updateMenuKeyUI()
        showToast("success", "Menu Key Set", "Клавиша: " .. _G.menuKey.Name)
        return
    end
    if g then return end
    if i.KeyCode == _G.flyKey then
        tgFl()
        showKeybindHint(_G.flyKey.Name, _G.flyActive and "Fly Activated" or "Fly Deactivated")
    end
    if i.KeyCode == _G.menuKey then
        _G.mf.Visible = not _G.mf.Visible
        showKeybindHint(_G.menuKey.Name, _G.mf.Visible and "Menu Opened" or "Menu Hidden")
    end
    if i.KeyCode == _G.streamKey then
        toggleStreamMode()
    end
end)

-- ============================================================
-- ЗАПУСК СИСТЕМ
-- ============================================================

setupSelfMarker()

local finalOk, finalFailed = runIntegrityChecks()
if finalOk then
    game:GetService("TestService"):Message("[Adlex]: Loaded | Fingerprint: " .. _G.ADLEX_FINGERPRINT)
else
    warn("[Adlex] Initial integrity check failed: " .. table.concat(finalFailed, ", "))
end

showToast("success", "Adlex v2.6", "Скрипт загружен успешно")
