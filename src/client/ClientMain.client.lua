--[[
	============================================================
	KLIK SIMULATOR - Script Client (GUI)
	Tempat : StarterGui (LocalScript, nama bebas, mis. "ClientMain")
	Isi    : Semua tampilan dibuat lewat kode — tidak perlu
	         menggambar GUI manual di Studio.
	============================================================
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("KlikSimRemotes")
local clickEvent = remotes:WaitForChild("DoClick")
local buyUpgradeFunc = remotes:WaitForChild("BuyUpgrade")
local hatchEggFunc = remotes:WaitForChild("HatchEgg")
local rebirthFunc = remotes:WaitForChild("DoRebirth")

local leaderstats = player:WaitForChild("leaderstats")
local stats = player:WaitForChild("SimData")
local clicksValue = leaderstats:WaitForChild("Clicks")
local rebirthsValue = leaderstats:WaitForChild("Rebirths")

-- ==================== BANTUAN ====================
local function formatNumber(n)
	n = math.floor(n)
	if n < 1000 then
		return tostring(n)
	end
	local units = { "K", "M", "B", "T", "Qa", "Qi" }
	local unit = -1
	while n >= 1000 and unit < #units do
		n = n / 1000
		unit = unit + 1
	end
	if unit < 0 then unit = 0 end
	return string.format("%.1f%s", n, units[unit + 1] or "")
end

local function addCorner(obj, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = obj
	return corner
end

local function makeLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position, bgColor)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = bgColor
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = parent
	addCorner(button, 12)
	return button
end

-- ==================== GUI UTAMA ====================
local gui = Instance.new("ScreenGui")
gui.Name = "KlikSimGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Bar atas: statistik pemain
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(0, 520, 0, 56)
topBar.Position = UDim2.new(0.5, -260, 0, 12)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
topBar.BackgroundTransparency = 0.15
topBar.Parent = gui
addCorner(topBar, 14)

local clicksLabel = makeLabel(topBar, "Clicks", "", UDim2.new(0, 200, 1, 0), UDim2.new(0, 16, 0, 0), 20)
local rebirthsLabel = makeLabel(topBar, "Rebirths", "", UDim2.new(0, 140, 1, 0), UDim2.new(0, 216, 0, 0), 20)
local multLabel = makeLabel(topBar, "Multiplier", "", UDim2.new(0, 140, 1, 0), UDim2.new(0, 368, 0, 0), 20)

-- Notifikasi (muncul di tengah atas, lalu memudar)
local notifyLabel = makeLabel(gui, "Notify", "", UDim2.new(0, 600, 0, 40), UDim2.new(0.5, -300, 0, 84), 22, Color3.fromRGB(255, 235, 150))
notifyLabel.TextXAlignment = Enum.TextXAlignment.Center
local notifyToken = 0
local function notify(text)
	notifyToken = notifyToken + 1
	local myToken = notifyToken
	notifyLabel.Text = text
	notifyLabel.TextTransparency = 0
	task.delay(2.2, function()
		if notifyToken == myToken then
			TweenService:Create(notifyLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
		end
	end)
end

-- ==================== TOMBOL KLIK BESAR ====================
local clickButton = makeButton(gui, "ClickButton", "KLIK!", UDim2.new(0, 170, 0, 170), UDim2.new(1, -210, 1, -230), Color3.fromRGB(255, 90, 90))
clickButton.TextSize = 34
addCorner(clickButton, 85)

local function floatingText(amount)
	local label = Instance.new("TextLabel")
	label.Text = "+" .. formatNumber(amount)
	label.Size = UDim2.new(0, 120, 0, 40)
	label.Position = UDim2.new(1, -260 + math.random(-50, 20), 1, -290 + math.random(-40, 10))
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 120)
	label.TextSize = 26
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	TweenService:Create(label, TweenInfo.new(0.9), {
		Position = label.Position - UDim2.new(0, 0, 0, 70),
		TextTransparency = 1,
	}):Play()
	task.delay(1, function()
		label:Destroy()
	end)
end

clickButton.MouseButton1Click:Connect(function()
	clickEvent:FireServer()
	local gain = stats.ClickPower.Value * stats.Multiplier.Value
	floatingText(gain)
	-- Efek memantul kecil
	clickButton.Size = UDim2.new(0, 158, 0, 158)
	TweenService:Create(clickButton, TweenInfo.new(0.12), { Size = UDim2.new(0, 170, 0, 170) }):Play()
end)

-- ==================== PANEL-PANEL ====================
local panels = {}
local function makePanel(name, title, height)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(0, 460, 0, height)
	frame.Position = UDim2.new(0.5, -230, 0.5, -height / 2)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	frame.Visible = false
	frame.Parent = gui
	addCorner(frame, 16)

	local titleLabel = makeLabel(frame, "Title", title, UDim2.new(1, -60, 0, 44), UDim2.new(0, 18, 0, 8), 24)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left

	local closeButton = makeButton(frame, "Close", "X", UDim2.new(0, 40, 0, 40), UDim2.new(1, -50, 0, 10), Color3.fromRGB(200, 60, 60))
	closeButton.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	panels[name] = frame
	return frame
end

local function togglePanel(frame)
	for _, other in pairs(panels) do
		if other ~= frame then
			other.Visible = false
		end
	end
	frame.Visible = not frame.Visible
end

-- Menu kiri
local shopButton = makeButton(gui, "ShopButton", "🛒 Toko", UDim2.new(0, 150, 0, 52), UDim2.new(0, 16, 0, 110), Color3.fromRGB(230, 140, 0))
local petButton = makeButton(gui, "PetButton", "🥚 Pet", UDim2.new(0, 150, 0, 52), UDim2.new(0, 16, 0, 174), Color3.fromRGB(160, 60, 200))
local rebirthButton = makeButton(gui, "RebirthButton", "♻️ Rebirth", UDim2.new(0, 150, 0, 52), UDim2.new(0, 16, 0, 238), Color3.fromRGB(0, 170, 120))

-- ----- Panel Toko -----
local shopPanel = makePanel("ShopPanel", "🛒 Toko Upgrade", 260)
local powerLabel = makeLabel(shopPanel, "Power", "", UDim2.new(1, -36, 0, 32), UDim2.new(0, 18, 0, 64), 19)
local shopCostLabel = makeLabel(shopPanel, "Cost", "", UDim2.new(1, -36, 0, 32), UDim2.new(0, 18, 0, 100), 19)
local buyButton = makeButton(shopPanel, "Buy", "Beli Upgrade (+1 Kekuatan Klik)", UDim2.new(1, -36, 0, 56), UDim2.new(0, 18, 0, 156), Color3.fromRGB(0, 150, 255))
buyButton.TextSize = 17

local buying = false
buyButton.MouseButton1Click:Connect(function()
	if buying then return end
	buying = true
	local success, msg = buyUpgradeFunc:InvokeServer()
	buying = false
	notify(msg)
	if success then
		refreshShop()
		refreshTop()
	end
end)

-- ----- Panel Pet -----
local petPanel = makePanel("PetPanel", "🥚 Telur & Pet", 380)
local eggInfoLabel = makeLabel(petPanel, "EggInfo", "", UDim2.new(1, -36, 0, 32), UDim2.new(0, 18, 0, 60), 19)
local hatchResultLabel = makeLabel(petPanel, "HatchResult", "", UDim2.new(1, -36, 0, 36), UDim2.new(0, 18, 0, 96), 21, Color3.fromRGB(255, 220, 120))
hatchResultLabel.TextXAlignment = Enum.TextXAlignment.Center
local hatchButton = makeButton(petPanel, "Hatch", "Buka Telur!", UDim2.new(1, -36, 0, 56), UDim2.new(0, 18, 0, 140), Color3.fromRGB(200, 80, 220))
local petListTitle = makeLabel(petPanel, "PetListTitle", "Pet milikmu (3 terbaik aktif):", UDim2.new(1, -36, 0, 28), UDim2.new(0, 18, 0, 212), 17)
local petListLabel = makeLabel(petPanel, "PetList", "-", UDim2.new(1, -36, 0, 130), UDim2.new(0, 18, 0, 242), 16, Color3.fromRGB(200, 220, 255))
petListLabel.TextYAlignment = Enum.TextYAlignment.Top
petListLabel.TextWrapped = true

local hatching = false
hatchButton.MouseButton1Click:Connect(function()
	if hatching then return end
	hatching = true
	local success, payload = hatchEggFunc:InvokeServer()
	hatching = false
	if success then
		-- payload format: Nama|Rarity|Bonus
		local parts = string.split(payload, "|")
		hatchResultLabel.Text = "🎉 " .. parts[1] .. " (" .. (parts[2] or "?") .. ", bonus +" .. (parts[3] or "?") .. ")"
		notify("Kamu dapat pet: " .. parts[1] .. "!")
	else
		hatchResultLabel.Text = ""
		notify(payload)
	end
	refreshPets()
end)

-- ----- Panel Rebirth -----
local rebirthPanel = makePanel("RebirthPanel", "♻️ Rebirth", 300)
local rebirthInfoLabel = makeLabel(rebirthPanel, "Info", "", UDim2.new(1, -36, 0, 90), UDim2.new(0, 18, 0, 60), 18)
rebirthInfoLabel.TextWrapped = true
rebirthInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
local doRebirthButton = makeButton(rebirthPanel, "DoRebirth", "REBIRTH SEKARANG", UDim2.new(1, -36, 0, 56), UDim2.new(0, 18, 0, 200), Color3.fromRGB(0, 190, 130))

local rebirthing = false
doRebirthButton.MouseButton1Click:Connect(function()
	if rebirthing then return end
	rebirthing = true
	local success, msg = rebirthFunc:InvokeServer()
	rebirthing = false
	notify(msg)
	refreshAll()
end)

-- ==================== REFRESH TAMPILAN ====================
function refreshShop()
	powerLabel.Text = "Kekuatan klik: " .. stats.ClickPower.Value .. "  |  Pengali total: x" .. stats.Multiplier.Value
	shopCostLabel.Text = "Harga upgrade berikutnya: " .. formatNumber(stats.UpgradeCost.Value) .. " klik"
	buyButton.Text = "Beli Upgrade — " .. formatNumber(stats.UpgradeCost.Value) .. " klik"
end

function refreshPets()
	eggInfoLabel.Text = "Harga telur: " .. formatNumber(stats.EggCost.Value) .. " klik  |  Pet dimiliki: " .. stats.PetCount.Value
	hatchButton.Text = "Buka Telur — " .. formatNumber(stats.EggCost.Value) .. " klik"
	local raw = stats.PetsList.Value
	if raw == "" then
		petListLabel.Text = "(belum ada pet — buka telur pertamamu!)"
	else
		local names = string.split(raw, ",")
		petListLabel.Text = table.concat(names, ",  ")
	end
end

function refreshRebirth()
	rebirthInfoLabel.Text = "Rebirth mereset Klik & level upgrade (pet tetap aman), "
		.. "tapi pengali permanen naik +x1 selamanya.\n\n"
		.. "Rebirth saat ini: " .. rebirthsValue.Value .. "\n"
		.. "Harga rebirth berikutnya: " .. formatNumber(stats.RebirthCost.Value) .. " klik"
	doRebirthButton.Text = "REBIRTH — " .. formatNumber(stats.RebirthCost.Value) .. " klik"
end

function refreshTop()
	clicksLabel.Text = "🖱️ " .. formatNumber(clicksValue.Value)
	rebirthsLabel.Text = "♻️ " .. formatNumber(rebirthsValue.Value)
	multLabel.Text = "✖ x" .. formatNumber(stats.Multiplier.Value)
end

function refreshAll()
	refreshTop()
	refreshShop()
	refreshPets()
	refreshRebirth()
end

shopButton.MouseButton1Click:Connect(function()
	refreshShop()
	togglePanel(shopPanel)
end)
petButton.MouseButton1Click:Connect(function()
	refreshPets()
	togglePanel(petPanel)
end)
rebirthButton.MouseButton1Click:Connect(function()
	refreshRebirth()
	togglePanel(rebirthPanel)
end)

clicksValue.Changed:Connect(refreshTop)
rebirthsValue.Changed:Connect(refreshAll)
stats.Multiplier.Changed:Connect(refreshAll)
stats.UpgradeCost.Changed:Connect(refreshShop)
stats.RebirthCost.Changed:Connect(refreshRebirth)
stats.PetsList.Changed:Connect(refreshPets)
stats.PetCount.Changed:Connect(refreshPets)

refreshAll()
notify("Selamat datang di Klik Simulator! Tekan tombol KLIK! 🎉")
