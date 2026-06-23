-- ============================================================
-- ADLEX.LUA v2.6 - С ПРОВЕРКОЙ WHITELIST
-- ============================================================

local P, U, R, H = game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService"), game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- ============================================================
-- ПРОВЕРКА WHITELIST С GITHUB
-- ============================================================

local WHITELIST_URL = "https://raw.githubusercontent.com/Yuka2241/adlex-whitelist/main/whitelist.json"

local function checkWhitelist()
    local userId = P.LocalPlayer.UserId
    local success, result = pcall(function()
        return H:GetAsync(WHITELIST_URL)
    end)
    
    if success then
        local data = H:JSONDecode(result)
        local isAllowed = false
        
        -- Проверяем whitelist (массив userId)
        if data.whitelist then
            for _, allowedId in ipairs(data.whitelist) do
                if allowedId == userId then
                    isAllowed = true
                    break
                end
            end
        end
        
        if not isAllowed then
            -- Показываем окно ошибки
            local errorGui = Instance.new("ScreenGui", P.LocalPlayer:WaitForChild("PlayerGui"))
            errorGui.ResetOnSpawn = false
            errorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            
            local frame = Instance.new("Frame", errorGui)
            frame.Size = UDim2.new(0, 350, 0, 150)
            frame.Position = UDim2.new(0.5, -175, 0.5, -75)
            frame.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
            local stroke = Instance.new("UIStroke", frame)
            stroke.Color = Color3.fromRGB(255, 50, 50)
            stroke.Thickness = 2
            
            local title = Instance.new("TextLabel", frame)
            title.Size = UDim2.new(1, 0, 0, 40)
            title.BackgroundTransparency = 1
            title.Text = "⛔ ДОСТУП ЗАПРЕЩЕН"
            title.TextColor3 = Color3.fromRGB(255, 80, 80)
            title.Font = Enum.Font.GothamBlack
            title.TextSize = 20
            
            local msg = Instance.new("TextLabel", frame)
            msg.Size = UDim2.new(1, -20, 0, 60)
            msg.Position = UDim2.new(0, 10, 0, 45)
            msg.BackgroundTransparency = 1
            msg.Text = "Вас нет в whitelist\n\nВаш UserId: " .. userId .. "\n\nОбратитесь к разработчику"
            msg.TextColor3 = Color3.fromRGB(200, 200, 200)
            msg.Font = Enum.Font.GothamMedium
            msg.TextSize = 13
            msg.TextWrapped = true
            msg.TextYAlignment = Enum.TextYAlignment.Top
            
            -- Удаляем GUI через 5 секунд
            task.delay(5, function()
                errorGui:Destroy()
            end)
            
            -- Останавливаем скрипт
            error("Whitelist check failed - user not authorized")
        end
    else
        -- Если GitHub недоступен - показываем предупреждение но продолжаем
        warn("[Adlex] Не удалось загрузить whitelist с GitHub")
        -- Можешь изменить на error() если хочешь блокировать при недоступности
    end
end

-- Запускаем проверку
checkWhitelist()

-- ============================================================
-- ОСНОВНОЙ КОД ADLEX
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
_G.menuBinding = false
_G.chamsColor = Color3.fromRGB(128, 128, 128)

local container = (gethui and gethui()) or game:GetService("CoreGui") or _G.lp:WaitForChild("PlayerGui")
if container:FindFirstChild("AdlexMenu") then container.AdlexMenu:Destroy() end
_G.sg = Instance.new("ScreenGui", container)
_G.sg.Name = "AdlexMenu"
_G.sg.ResetOnSpawn = false
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
TweenService:Create(_G.mf, TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -260, 0.5, -150), BackgroundTransparency = 0}):Play()
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
function _G.cBtn(parent, text, pos, size, color, tooltipText)
local b = Instance.new("TextButton", parent)
b.Size, b.Position, b.BackgroundColor3, b.Text = size, pos, color, text
b.TextColor3, b.Font, b.TextSize, b.ZIndex, b.ClipsDescendants = Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, 13, 5, true
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
local stroke = Instance.new("UIStroke", b)
stroke.Color, stroke.Thickness, stroke.Enabled = Color3.fromRGB(255, 255, 255), 1.5, false
b.MouseEnter:Connect(function()
TweenService:Create(b, TweenInfo.new(0.2), {Size = UDim2.new(size.X.Scale, size.X.Offset + 4, size.Y.Scale, size.Y.Offset + 4), Position = UDim2.new(pos.X.Scale, pos.X.Offset - 2, pos.Y.Scale, pos.Y.Offset - 2)}):Play()
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
TweenService:Create(ripple, TweenInfo.new(0.4), {Size = UDim2.new(0, size.X.Offset * 2.5, 0, size.X.Offset * 2.5), Position = UDim2.new(0, relativeX - size.X.Offset * 1.25, 0, relativeY - size.X.Offset * 1.25), BackgroundTransparency = 1}):Play()
game:GetService("Debris"):AddItem(ripple, 0.4)
end)
return b, stroke
end
function _G.addTab(name, title)
local count = 0 for _ in pairs(_G.tabs) do count = count + 1 end
local b = _G.cBtn(_G.sb, "  "..name, UDim2.new(0, 10, 0, 60 + count * 40), UDim2.new(1, -20, 0, 35), Color3.fromRGB(22, 22, 26))
b.TextColor3, b.TextXAlignment, b.Font = Color3.fromRGB(150, 150, 155), 0, Enum.Font.GothamMedium
local f = Instance.new("Frame", _G.ca) f.Size, f.BackgroundTransparency, f.Visible = UDim2.new(1, 0, 1, 0), 1, false
local t = Instance.new("TextLabel", f) t.Size, t.BackgroundTransparency, t.Text = UDim2.new(1, 0, 0, 30), 1, string.upper(title)
t.TextColor3, t.TextSize, t.Font, t.TextXAlignment = Color3.fromRGB(130, 130, 135), 11, Enum.Font.GothamBold, Enum.TextXAlignment.Left
_G.tabs[name] = {b = b, f = f, name = name}
b.MouseButton1Click:Connect(function()
for _, v in pairs(_G.tabs) do v.f.Visible, v.b.BackgroundColor3, v.b.TextColor3 = false, _G.sb.BackgroundColor3, Color3.fromRGB(150, 150, 155) end
f.Visible, b.BackgroundColor3, b.TextColor3, _G.curTab = true, Color3.fromRGB(42, 42, 48), Color3.fromRGB(255, 255, 255), name
end)
if not _G.curTab then f.Visible, b.BackgroundColor3, b.TextColor3, _G.curTab = true, Color3.fromRGB(42, 42, 48), Color3.fromRGB(255, 255, 255), name end return f
end
local drag, dInp, dragStart, startPos
_G.mf.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 then
drag = true dragStart = i.Position startPos = _G.mf.Position
i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
end
end)
_G.mf.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dInp = i end end)
U.InputChanged:Connect(function(i) if i == dInp and drag then local d = i.Position - dragStart _G.mf.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)
_G.p1 = _G.addTab("Coordinates", "Position Computation")
_G.p2 = _G.addTab("Teleportation", "Vector3 Matrix Teleport")
_G.p3 = _G.addTab("Settings", "Interface Customization")
local wmFrame = Instance.new("Frame", _G.sg)
wmFrame.Size = UDim2.new(0, 240, 0, 25)
wmFrame.Position = UDim2.new(1, -250, 0, 10)
wmFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
wmFrame.BorderSizePixel = 0
Instance.new("UICorner", wmFrame).CornerRadius = UDim.new(0, 4)
local wmStroke = Instance.new("UIStroke", wmFrame)
wmStroke.Color = Color3.fromRGB(40, 40, 45)
wmStroke.Thickness = 1
local wmText = Instance.new("TextLabel", wmFrame)
wmText.Size = UDim2.new(1, -10, 1, 0)
wmText.Position = UDim2.new(0, 10, 0, 0)
wmText.BackgroundTransparency = 1
wmText.TextColor3 = Color3.fromRGB(240, 240, 245)
wmText.Font = Enum.Font.Code
wmText.TextSize = 11
wmText.TextXAlignment = Enum.TextXAlignment.Left
task.spawn(function()
while task.wait(1) do
if wmText then wmText.Text = "Adlex.lua | " .. os.date("%d.%m.%Y - %X") end
end
end)
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
local bx, bxStr = _G.cBtn(_G.p1, "Copy X", UDim2.new(0, 0, 0, 165), UDim2.new(0, 100, 0, 35), Color3.fromRGB(0, 102, 204), "Скопировать координату X")
local by, byStr = _G.cBtn(_G.p1, "Copy Y", UDim2.new(0, 110, 0, 165), UDim2.new(0, 100, 0, 35), Color3.fromRGB(0, 102, 204), "Скопировать координату Y")
local bz, bzStr = _G.cBtn(_G.p1, "Copy Z", UDim2.new(0, 220, 0, 165), UDim2.new(0, 100, 0, 35), Color3.fromRGB(0, 102, 204), "Скопировать координату Z")
_G.bx, _G.by, _G.bz = bx, by, bz
bx.MouseButton1Click:Connect(function() 
if setclipboard then setclipboard(tostring(_G.coords.x)) showToast("Copied", "X: " .. _G.coords.x) end
end)
by.MouseButton1Click:Connect(function() 
if setclipboard then setclipboard(tostring(_G.coords.y)) showToast("Copied", "Y: " .. _G.coords.y) end
end)
bz.MouseButton1Click:Connect(function() 
if setclipboard then setclipboard(tostring(_G.coords.z)) showToast("Copied", "Z: " .. _G.coords.z) end
end)
local fz, fzStr = _G.cBtn(_G.p1, "Freeze Character: OFF", UDim2.new(0, 0, 0, 215), UDim2.new(0, 160, 0, 35), Color3.fromRGB(40, 40, 45), "Заморозить положение персонажа")
fz.TextColor3 = Color3.fromRGB(180, 180, 185)
_G.fz, _G.fzStr = fz, fzStr
local flb, flbStr = _G.cBtn(_G.p1, "Fly: OFF [B]", UDim2.new(0, 170, 0, 215), UDim2.new(0, 160, 0, 35), Color3.fromRGB(40, 40, 45), "Активировать режим полета")
flb.TextColor3 = Color3.fromRGB(180, 180, 185)
_G.flb, _G.flbStr = flb, flbStr
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
return b
end
_G.ix = cInp(_G.p2, "X", UDim2.new(0, 0, 0, 40), Color3.fromRGB(220, 53, 69))
_G.iy = cInp(_G.p2, "Y", UDim2.new(0, 115, 0, 40), Color3.fromRGB(40, 167, 69))
_G.iz = cInp(_G.p2, "Z", UDim2.new(0, 230, 0, 40), Color3.fromRGB(0, 102, 204))
local tp, tpStr = _G.cBtn(_G.p2, "Instant Teleport", UDim2.new(0, 0, 0, 95), UDim2.new(0, 160, 0, 35), Color3.fromRGB(114, 9, 183), "Мгновенно переместиться")
local at, atStr = _G.cBtn(_G.p2, "Auto Teleport: OFF", UDim2.new(0, 170, 0, 95), UDim2.new(0, 160, 0, 35), Color3.fromRGB(40, 40, 45), "Бесконечный авто-телепорт")
at.TextColor3 = Color3.fromRGB(180, 180, 185)
_G.tp, _G.at, _G.atStr = tp, at, atStr
local noclipBtn, noclipStr = _G.cBtn(_G.p2, "Noclip Players: OFF", UDim2.new(0, 0, 0, 145), UDim2.new(0, 160, 0, 35), Color3.fromRGB(40, 40, 45), "Отключить коллизию игроков")
noclipBtn.TextColor3 = Color3.fromRGB(180, 180, 185)
_G.noclipBtn, _G.noclipStr = noclipBtn, noclipStr
local function doTp()
local r = _G.lp.Character and _G.lp.Character:FindFirstChild("HumanoidRootPart")
if r then
local oA = r.Anchored r.Anchored = false
r.CFrame = CFrame.new(tonumber(_G.ix.Text) or 0, tonumber(_G.iy.Text) or 0, tonumber(_G.iz.Text) or 0)
if oA or _G.frz then task.wait() r.Anchored = true end
end
end
_G.tp.MouseButton1Click:Connect(doTp)
local function uAt(s)
_G.isAuto = s
_G.at.Text = _G.isAuto and "Auto Teleport: ON" or "Auto Teleport: OFF"
_G.at.BackgroundColor3 = _G.isAuto and Color3.fromRGB(30, 120, 50) or Color3.fromRGB(40, 40, 45)
_G.at.TextColor3 = _G.isAuto and Color3.fromRGB(220, 220, 225) or Color3.fromRGB(180, 180, 185)
_G.atStr.Enabled = _G.isAuto
end
_G.at.MouseButton1Click:Connect(function()
uAt(not _G.isAuto)
if _G.isAuto then task.spawn(function() while _G.isAuto do doTp() task.wait(0.1) end end) end
end)
_G.noclipBtn.MouseButton1Click:Connect(function()
_G.noclippedPlayers = not _G.noclippedPlayers
_G.noclipBtn.Text = _G.noclippedPlayers and "Noclip Players: ON" or "Noclip Players: OFF"
_G.noclipBtn.BackgroundColor3 = _G.noclippedPlayers and Color3.fromRGB(30, 120, 50) or Color3.fromRGB(40, 40, 45)
_G.noclipBtn.TextColor3 = _G.noclippedPlayers and Color3.fromRGB(220, 220, 225) or Color3.fromRGB(180, 180, 185)
_G.noclipStr.Enabled = _G.noclippedPlayers
end)
local function uFlV()
_G.flb.Text = "Fly: " .. (_G.flyActive and "ON" or "OFF") .. " [" .. _G.flyKey.Name .. "]"
_G.flb.BackgroundColor3 = _G.flyActive and Color3.fromRGB(30, 120, 50) or Color3.fromRGB(40, 40, 45)
_G.flb.TextColor3 = _G.flyActive and Color3.fromRGB(220, 220, 225) or Color3.fromRGB(180, 180, 185)
_G.flbStr.Enabled = _G.flyActive
end
local function tgFl()
local c = _G.lp.Character
local r = c and c:FindFirstChild("HumanoidRootPart")
if r then
_G.flyActive = not _G.flyActive uFlV()
if not _G.flyActive then r.Velocity = Vector3.new(0, 0, 0) end
end
end
_G.flb.MouseButton1Click:Connect(tgFl)
_G.flb.MouseButton2Click:Connect(function() _G.flyBinding = true _G.bindOverlay.Visible = true end)
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
local c = _G.lp.Character local r = c and c:FindFirstChild("HumanoidRootPart")
if _G.flyActive and r then
local cam = workspace.CurrentCamera.CFrame local m = Vector3.new(0, 0, 0)
if U:IsKeyDown(Enum.KeyCode.W) then m = m + cam.LookVector end
if U:IsKeyDown(Enum.KeyCode.S) then m = m - cam.LookVector end
if U:IsKeyDown(Enum.KeyCode.A) then m = m - cam.RightVector end
if U:IsKeyDown(Enum.KeyCode.D) then m = m + cam.RightVector end
if U:IsKeyDown(Enum.KeyCode.Space) then m = m + Vector3.new(0, 1, 0) end
if U:IsKeyDown(Enum.KeyCode.LeftShift) then m = m - Vector3.new(0, 1, 0) end
if m.Magnitude ~= 0 then r.Velocity = m.Unit * 50 else r.Velocity = Vector3.new(0, 0.1, 0) end
end
end)
local function uFr(s)
_G.frz = s local r = _G.lp.Character and _G.lp.Character:FindFirstChild("HumanoidRootPart")
_G.fz.Text = _G.frz and "Freeze Character: ON" or "Freeze Character: OFF"
_G.fz.BackgroundColor3 = _G.frz and Color3.fromRGB(160, 40, 50) or Color3.fromRGB(40, 40, 45)
_G.fz.TextColor3 = _G.frz and Color3.fromRGB(220, 220, 225) or Color3.fromRGB(180, 180, 185)
_G.fzStr.Enabled = _G.frz
if r then r.Anchored = _G.frz end
end
_G.fz.MouseButton1Click:Connect(function() uFr(not _G.frz) end)
_G.lp.CharacterAdded:Connect(function(c)
if _G.frz then local r = c:WaitForChild("HumanoidRootPart", 5) if r then r.Anchored = true end end
if _G.flyActive then _G.flyActive = false uFlV() end
end)
local function showToast(titleText, descText)
local toast = Instance.new("Frame", _G.sg)
toast.Size = UDim2.new(0, 200, 0, 50)
toast.Position = UDim2.new(1, 20, 1, -60)
toast.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 5)
local tS = Instance.new("UIStroke", toast) tS.Color = Color3.fromRGB(50, 50, 55)
local tT = Instance.new("TextLabel", toast) tT.Size = UDim2.new(1, -10, 0, 20) tT.Position = UDim2.new(0, 10, 0, 5) tT.Text = titleText tT.TextColor3 = Color3.fromRGB(255, 255, 255) tT.Font = Enum.Font.GothamBold tT.TextSize = 12 tT.BackgroundTransparency, tT.TextXAlignment = 1, 0
local dT = Instance.new("TextLabel", toast) dT.Size = UDim2.new(1, -10, 0, 20) dT.Position = UDim2.new(0, 10, 0, 22) dT.Text = descText dT.TextColor3 = Color3.fromRGB(160, 160, 165) dT.Font = Enum.Font.GothamMedium dT.TextSize = 10 dT.BackgroundTransparency, dT.TextXAlignment = 1, 0
TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -220, 1, -60)}):Play()
task.delay(2.5, function()
if toast then
TweenService:Create(toast, TweenInfo.new(0.3), {Position = UDim2.new(1, 20, 1, -60), BackgroundTransparency = 1}):Play()
game:GetService("Debris"):AddItem(toast, 0.3)
end
end)
end
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
local Themes = {
Black = {bg = Color3.fromRGB(15, 15, 18), side = Color3.fromRGB(22, 22, 26), text = Color3.fromRGB(255, 255, 255)},
Gray = {bg = Color3.fromRGB(35, 35, 40), side = Color3.fromRGB(45, 45, 50), text = Color3.fromRGB(240, 240, 245)},
Light = {bg = Color3.fromRGB(240, 240, 245), side = Color3.fromRGB(225, 225, 230), text = Color3.fromRGB(20, 20, 25)}
}
local curTheme = Themes.Black
local function uTheme()
_G.mf.BackgroundColor3 = curTheme.bg 
_G.sb.BackgroundColor3 = curTheme.side
wmFrame.BackgroundColor3 = curTheme.bg
for _, v in pairs(_G.tabs) do 
if v.b then 
v.b.BackgroundColor3 = curTheme.side 
if _G.curTab == v.name then v.b.BackgroundColor3 = Color3.fromRGB(42,42,48) end 
end 
end
end
local function updateMenuKeyUI() 
if _G.tabs["Settings"] and _G.tabs["Settings"].f then
local btn = _G.tabs["Settings"].f:FindFirstChild("MKeyBtn")
if btn then btn.Text = "Menu Key: [" .. _G.menuKey.Name .. "]" end
end
end
local dropContainer = Instance.new("Frame", _G.p3)
dropContainer.Size, dropContainer.Position, dropContainer.BackgroundColor3, dropContainer.BorderSizePixel, dropContainer.ZIndex = UDim2.new(0, 160, 0, 35), UDim2.new(0, 0, 0, 40), Color3.fromRGB(28, 28, 33), 0, 6
Instance.new("UICorner", dropContainer).CornerRadius = UDim.new(0, 5)
local dropMainBtn = Instance.new("TextButton", dropContainer)
dropMainBtn.Size, dropMainBtn.BackgroundTransparency, dropMainBtn.Text, dropMainBtn.TextColor3, dropMainBtn.Font, dropMainBtn.TextSize, dropMainBtn.ZIndex = UDim2.new(1, 0, 1, 0), 1, "Select Theme v", Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, 13, 7
local dropListFrame = Instance.new("Frame", dropContainer)
dropListFrame.Size, dropListFrame.Position, dropListFrame.BackgroundColor3, dropListFrame.BorderSizePixel, dropListFrame.Visible, dropListFrame.ZIndex = UDim2.new(1, 0, 0, 95), UDim2.new(0, 0, 1, 5), Color3.fromRGB(24, 24, 28), 0, false, 8
Instance.new("UICorner", dropListFrame).CornerRadius = UDim.new(0, 5)
local dropListLayout = Instance.new("UIListLayout", dropListFrame) dropListLayout.Padding = UDim.new(0, 2)
local function createDropElement(themeKey, displayName)
local b = _G.cBtn(dropListFrame, displayName, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 28), Color3.fromRGB(32, 32, 38))
b.ZIndex = 9
b.MouseButton1Click:Connect(function() curTheme = Themes[themeKey] uTheme() dropMainBtn.Text = displayName .. " v" dropListFrame.Visible = false showToast("Theme Changed", "Новая тема успешно применена") end)
end
createDropElement("Black", "Dark Theme")
createDropElement("Gray", "Gray Theme")
createDropElement("Light", "Light Theme")
dropMainBtn.MouseButton1Click:Connect(function() dropListFrame.Visible = not dropListFrame.Visible end)
local function cInpLocal(p, ph, pos)
local b = Instance.new("TextBox", p) b.Size, b.Position, b.BackgroundColor3, b.PlaceholderText, b.Text, b.ZIndex = UDim2.new(0, 80, 0, 35), pos, Color3.fromRGB(28, 28, 33), ph, "", 5
b.TextColor3, b.PlaceholderColor3, b.TextSize, b.Font, b.ClearTextOnFocus = Color3.fromRGB(255, 255, 255), Color3.fromRGB(100, 100, 105), 14, Enum.Font.Code, false Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5) return b
end
local opacityInput = cInpLocal(_G.p3, "% (0-100)", UDim2.new(0, 0, 0, 95))
local applyOpacityBtn = _G.cBtn(_G.p3, "Set Opacity", UDim2.new(0, 90, 0, 95), UDim2.new(0, 110, 0, 35), Color3.fromRGB(0, 102, 204), "Установить прозрачность")
applyOpacityBtn.MouseButton1Click:Connect(function()
local number = tonumber(opacityInput.Text)
if number then
if number < 0 then number = 0 elseif number > 100 then number = 100 end
local value = number / 100
_G.mf.BackgroundTransparency = value _G.sb.BackgroundTransparency = value
showToast("Opacity Set", "Прозрачность установлена на " .. number .. "%")
else
opacityInput.Text = "Error" task.wait(0.6) opacityInput.Text = ""
end
end)
local chamsInput = cInpLocal(_G.p3, "R,G,B", UDim2.new(0, 0, 0, 150))
chamsInput.Size = UDim2.new(0, 110, 0, 35)
local applyChamsBtn = _G.cBtn(_G.p3, "Set Chams Color", UDim2.new(0, 120, 0, 150), UDim2.new(0, 140, 0, 35), Color3.fromRGB(0, 102, 204), "Изменить цвет подсветки игроков")
applyChamsBtn.MouseButton1Click:Connect(function()
local r, g, b = chamsInput.Text:match("(%d+),(%d+),(%d+)")
if r and g and b then
_G.chamsColor = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
for _, pl in pairs(P:GetPlayers()) do
if pl.Character and pl.Character:FindFirstChildOfClass("Highlight") then
pl.Character:FindFirstChildOfClass("Highlight").FillColor = _G.chamsColor
end
end
showToast("Chams Updated", "Цвет подсветки успешно изменен")
else
chamsInput.Text = "Format: 255,0,0" task.wait(1.5) chamsInput.Text = ""
end
end)
local mkb = _G.cBtn(_G.p3, "Menu Key: [RightShift]", UDim2.new(0, 0, 0, 205), UDim2.new(0, 200, 0, 35), Color3.fromRGB(114, 9, 183), "Изменить кнопку меню") mkb.Name = "MKeyBtn"
mkb.MouseButton1Click:Connect(function() _G.menuBinding = true _G.bindOverlay.Text = "Нажмите клавишу для закрытия меню..." _G.bindOverlay.Visible = true end)
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
U.InputBegan:Connect(function(i, g)
if _G.flyBinding and i.KeyCode ~= Enum.KeyCode.Unknown and i.UserInputType == Enum.UserInputType.Keyboard then _G.flyKey = i.KeyCode _G.flyBinding = false _G.bindOverlay.Visible = false uFlV() return end
if _G.menuBinding and i.KeyCode ~= Enum.KeyCode.Unknown and i.UserInputType == Enum.UserInputType.Keyboard then _G.menuKey = i.KeyCode _G.menuBinding = false _G.bindOverlay.Visible = false updateMenuKeyUI() return end
if g then return end if i.KeyCode == _G.flyKey then tgFl() end if i.KeyCode == _G.menuKey then _G.mf.Visible = not _G.mf.Visible end
end)
game:GetService("TestService"):Message("[Adlex]: Loaded with whitelist protection")
