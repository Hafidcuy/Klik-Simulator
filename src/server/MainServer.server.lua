--[[
	============================================================
	KLIK SIMULATOR - Script Server Utama
	Tempat : ServerScriptService (Script, nama bebas, mis. "MainServer")
	Isi    : Leaderstats, DataStore (save otomatis), sistem klik,
	         upgrade, telur pet, rebirth, dan pembuat map otomatis.
	============================================================
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==================== KONFIGURASI GAME ====================
local EGG_COST = 500              -- harga 1 telur pet
local BASE_REBIRTH_COST = 10000   -- harga rebirth pertama
local MAX_EQUIPPED_PETS = 3       -- pet terbaik yang aktif memberi bonus
local AUTOSAVE_SECONDS = 120      -- simpan otomatis tiap 2 menit

-- Daftar pet: Bonus = tambahan pengali klik dari pet ini bila terpasang.
-- Chance = peluang keluar dari telur (%). Total peluang = 100.
local PETS = {
	{ Name = "Anjing Noob",  Rarity = "Common",    Chance = 35,  Bonus = 1  },
	{ Name = "Kucing Oren",  Rarity = "Common",    Chance = 30,  Bonus = 2  },
	{ Name = "Kelinci",      Rarity = "Rare",      Chance = 18,  Bonus = 4  },
	{ Name = "Rubah Api",    Rarity = "Epic",      Chance = 10,  Bonus = 9  },
	{ Name = "Panda Sakti",  Rarity = "Epic",      Chance = 5,   Bonus = 14 },
	{ Name = "Naga Emas",    Rarity = "Legendary", Chance = 1.5, Bonus = 29 },
	{ Name = "Phoenix Abadi", Rarity = "Mythic",   Chance = 0.5, Bonus = 59 },
}

local PET_BY_NAME = {}
for _, pet in ipairs(PETS) do
	PET_BY_NAME[pet.Name] = pet
end

-- ==================== RUMUS HARGA ====================
local function upgradeCost(level)
	-- level 0 -> 100, lalu naik x1.6 tiap level (dibulatkan ke 10 terdekat)
	return math.floor(100 * (1.6 ^ level) / 10 + 0.5) * 10
end

local function rebirthCost(rebirths)
	return math.floor(BASE_REBIRTH_COST * ((rebirths + 1) ^ 1.5) / 100 + 0.5) * 100
end

local function rollPet()
	local roll = math.random() * 100
	local cumulative = 0
	for _, pet in ipairs(PETS) do
		cumulative = cumulative + pet.Chance
		if roll <= cumulative then
			return pet
		end
	end
	return PETS[1]
end

-- ==================== REMOTES ====================
local remotes = Instance.new("Folder")
remotes.Name = "KlikSimRemotes"
remotes.Parent = ReplicatedStorage

local clickEvent = Instance.new("RemoteEvent")
clickEvent.Name = "DoClick"
clickEvent.Parent = remotes

local buyUpgradeFunc = Instance.new("RemoteFunction")
buyUpgradeFunc.Name = "BuyUpgrade"
buyUpgradeFunc.Parent = remotes

local hatchEggFunc = Instance.new("RemoteFunction")
hatchEggFunc.Name = "HatchEgg"
hatchEggFunc.Parent = remotes

local rebirthFunc = Instance.new("RemoteFunction")
rebirthFunc.Name = "DoRebirth"
rebirthFunc.Parent = remotes

-- ==================== DATASTORE ====================
local store = nil
local okStore, errStore = pcall(function()
	store = DataStoreService:GetDataStore("KlikSim_v1")
end)
if not okStore then
	warn("[KlikSim] DataStore tidak tersedia: " .. tostring(errStore))
end

local sessionPets = {}  -- [player] = { "Anjing Noob", "Kelinci", ... }
local lastClick = {}    -- [player] = tick terakhir (anti auto-click exploit)

local function computeDerived(player)
	local stats = player:FindFirstChild("SimData")
	local leaderstats = player:FindFirstChild("leaderstats")
	if not stats or not leaderstats then return end

	local level = stats:GetAttribute("UpgradeLevel") or 0
	local rebirths = leaderstats.Rebirths.Value

	-- Bonus pet: jumlahkan Bonus dari pet terbaik (maks 3)
	local bonuses = {}
	for _, petName in ipairs(sessionpets[player] or {}) do
		local pet = PET_BY_NAME[petName]
		if pet then
			table.insert(bonuses, pet.Bonus)
		end
	end
	table.sort(bonuses, function(a, b) return a > b end)
	local petBonus = 0
	for i = 1, math.min(MAX_EQUIPPED_PETS, #bonuses) do
		petBonus = petBonus + bonuses[i]
	end

	stats.ClickPower.Value = 1 + level
	stats.Multiplier.Value = (1 + petBonus) * (1 + rebirths)
	stats.UpgradeCost.Value = upgradeCost(level)
	stats.RebirthCost.Value = rebirthCost(rebirths)
	stats.EggCost.Value = EGG_COST
	stats.PetCount.Value = #(sessionpets[player] or {})

	local list = {}
	for _, petName in ipairs(sessionpets[player] or {}) do
		table.insert(list, petName)
	end
	stats.PetsList.Value = table.concat(list, ",")
end

local function savePlayer(player)
	if not store then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	local stats = player:FindFirstChild("SimData")
	if not leaderstats or not stats then return end

	local data = {
		Clicks = leaderstats.Clicks.Value,
		Rebirths = leaderstats.Rebirths.Value,
		UpgradeLevel = stats:GetAttribute("UpgradeLevel") or 0,
		Pets = sessionpets[player] or {},
	}

	local ok, err = pcall(function()
		store:SetAsync("player_" .. player.UserId, data)
	end)
	if not ok then
		warn("[KlikSim] Gagal menyimpan data " .. player.Name .. ": " .. tostring(err))
	end
end

local function loadPlayer(player)
	local data = nil
	if store then
		local ok, result = pcall(function()
			return store:GetAsync("player_" .. player.UserId)
		end)
		if ok then
			data = result
		else
			warn("[KlikSim] Gagal memuat data " .. player.Name .. ": " .. tostring(result))
			warn("[KlikSim] Jika di Studio: aktifkan Game Settings > Security > Enable Studio Access to API Services.")
		end
	end
	return data
end

-- ==================== PEMAIN MASUK / KELUAR ====================
local function onPlayerAdded(player)
	local data = loadPlayer(player) or {}

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local clicks = Instance.new("IntValue")
	clicks.Name = "Clicks"
	clicks.Value = data.Clicks or 0
	clicks.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = data.Rebirths or 0
	rebirths.Parent = leaderstats

	local stats = Instance.new("Folder")
	stats.Name = "SimData"
	stats.Parent = player
	stats:SetAttribute("UpgradeLevel", data.UpgradeLevel or 0)

	local function makeInt(name, value)
		local v = Instance.new("IntValue")
		v.Name = name
		v.Value = value
		v.Parent = stats
		return v
	end

	makeInt("ClickPower", 1)
	makeInt("Multiplier", 1)
	makeInt("UpgradeCost", upgradeCost(data.UpgradeLevel or 0))
	makeInt("RebirthCost", rebirthCost(data.Rebirths or 0))
	makeInt("EggCost", EGG_COST)
	makeInt("PetCount", 0)

	local petsList = Instance.new("StringValue")
	petsList.Name = "PetsList"
	petsList.Value = ""
	petsList.Parent = stats

	-- Saring pet tersimpan: hanya yang masih ada di daftar pet
	sessionpets[player] = {}
	if type(data.Pets) == "table" then
		for _, petName in ipairs(data.Pets) do
			if PET_BY_NAME[petName] then
				table.insert(sessionpets[player], petName)
			end
		end
	end

	computeDerived(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	if not player:FindFirstChild("leaderstats") then
		onPlayerAdded(player)
	end
end

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	sessionpets[player] = nil
	lastClick[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayer(player)
	end
end)

-- Simpan otomatis berkala
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayer(player)
		end
	end
end)

-- ==================== AKSI PEMAIN ====================
clickEvent.OnServerEvent:Connect(function(player)
	-- Anti exploit: batasi maks ~20 klik per detik
	local now = os.clock()
	if lastClick[player] and now - lastClick[player] < 0.05 then
		return
	end
	lastClick[player] = now

	local leaderstats = player:FindFirstChild("leaderstats")
	local stats = player:FindFirstChild("SimData")
	if not leaderstats or not stats then return end

	leaderstats.Clicks.Value = leaderstats.Clicks.Value + stats.ClickPower.Value * stats.Multiplier.Value
end)

buyUpgradeFunc.OnServerInvoke = function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stats = player:FindFirstChild("SimData")
	if not leaderstats or not stats then
		return false, "Data belum siap."
	end

	local level = stats:GetAttribute("UpgradeLevel") or 0
	local cost = upgradeCost(level)
	if leaderstats.Clicks.Value < cost then
		return false, "Klik tidak cukup! Butuh " .. cost .. " klik."
	end

	leaderstats.Clicks.Value = leaderstats.Clicks.Value - cost
	stats:SetAttribute("UpgradeLevel", level + 1)
	computeDerived(player)
	return true, "Upgrade berhasil! Kekuatan klik sekarang " .. stats.ClickPower.Value
end

hatchEggFunc.OnServerInvoke = function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false, "Data belum siap."
	end
	if leaderstats.Clicks.Value < EGG_COST then
		return false, "Klik tidak cukup! Telur berharga " .. EGG_COST .. " klik."
	end

	leaderstats.Clicks.Value = leaderstats.Clicks.Value - EGG_COST
	local pet = rollPet()
	sessionpets[player] = sessionpets[player] or {}
	table.insert(sessionpets[player], pet.Name)
	computeDerived(player)
	return true, pet.Name .. "|" .. pet.Rarity .. "|" .. tostring(pet.Bonus)
end

rebirthFunc.OnServerInvoke = function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stats = player:FindFirstChild("SimData")
	if not leaderstats or not stats then
		return false, "Data belum siap."
	end

	local cost = rebirthCost(leaderstats.Rebirths.Value)
	if leaderstats.Clicks.Value < cost then
		return false, "Klik tidak cukup! Rebirth butuh " .. cost .. " klik."
	end

	-- Rebirth: klik & level upgrade direset, pet TETAP disimpan,
	-- sebagai gantinya pengali permanen naik (lihat computeDerived).
	leaderstats.Clicks.Value = 0
	stats:SetAttribute("UpgradeLevel", 0)
	leaderstats.Rebirths.Value = leaderstats.Rebirths.Value + 1
	computeDerived(player)
	return true, "REBIRTH! Pengali permanenmu sekarang x" .. stats.Multiplier.Value
end

-- ==================== PEMBUAT MAP OTOMATIS ====================
-- Map hanya dibuat bila belum ada folder "KlikSimMap" di Workspace,
-- jadi aman dijalankan berulang kali.
local function makePart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeSign(parent, name, position, text, bgColor)
	local post = makePart(parent, name .. "_Tiang", Vector3.new(1, 8, 1), position + Vector3.new(0, 4, 0), Color3.fromRGB(101, 67, 33), Enum.Material.Wood)
	local board = makePart(parent, name, Vector3.new(16, 6, 1), position + Vector3.new(0, 10, 0), bgColor, Enum.Material.SmoothPlastic)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return post, board
end

local function makeTree(parent, x, z)
	local trunk = makePart(parent, "BatangPohon", Vector3.new(2, 8, 2), Vector3.new(x, 4, z), Color3.fromRGB(101, 67, 33), Enum.Material.Wood)
	local leaves = Instance.new("Part")
	leaves.Name = "DaunPohon"
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(10, 10, 10)
	leaves.Position = Vector3.new(x, 12, z)
	leaves.Anchored = true
	leaves.Color = Color3.fromRGB(44, 160, 60)
	leaves.Material = Enum.Material.SmoothPlastic
	leaves.Parent = parent
	return trunk, leaves
end

local function buildMap()
	if workspace:FindFirstChild("KlikSimMap") then return end

	local map = Instance.new("Folder")
	map.Name = "KlikSimMap"
	map.Parent = workspace

	-- Pulau utama
	makePart(map, "Pulau", Vector3.new(220, 2, 220), Vector3.new(0, -1, 0), Color3.fromRGB(86, 190, 80), Enum.Material.Grass)
	-- Jalan tengah
	makePart(map, "Jalan", Vector3.new(24, 0.4, 200), Vector3.new(0, 0.2, 0), Color3.fromRGB(210, 190, 150), Enum.Material.Sand)
	-- Plaza spawn
	makePart(map, "Plaza", Vector3.new(50, 0.4, 50), Vector3.new(0, 0.2, 40), Color3.fromRGB(170, 170, 180), Enum.Material.Concrete)

	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnKlikSim"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.8, 40)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(0, 170, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = map

	-- Papan-papan petunjuk
	makeSign(map, "PapanJudul", Vector3.new(0, 0, 18), "KLIK SIMULATOR", Color3.fromRGB(0, 120, 215))
	makeSign(map, "PapanToko", Vector3.new(-30, 0, -30), "TOKO UPGRADE -> lewat GUI", Color3.fromRGB(230, 140, 0))
	makeSign(map, "PapanTelur", Vector3.new(30, 0, -30), "TELUR PET -> lewat GUI", Color3.fromRGB(160, 60, 200))

	-- Telur raksasa pajangan
	local egg = Instance.new("Part")
	egg.Name = "TelurRaksasa"
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(14, 18, 14)
	egg.Position = Vector3.new(38, 9, -52)
	egg.Anchored = true
	egg.Color = Color3.fromRGB(255, 220, 250)
	egg.Material = Enum.Material.SmoothPlastic
	egg.Parent = map
	makePart(map, "AlasTelur", Vector3.new(20, 2, 20), Vector3.new(38, 1, -52), Color3.fromRGB(120, 80, 160), Enum.Material.SmoothPlastic)

	-- Portal rebirth pajangan
	makePart(map, "PortalKiri", Vector3.new(3, 20, 3), Vector3.new(-42, 10, -52), Color3.fromRGB(140, 0, 255), Enum.Material.Neon)
	makePart(map, "PortalKanan", Vector3.new(3, 20, 3), Vector3.new(-24, 10, -52), Color3.fromRGB(140, 0, 255), Enum.Material.Neon)
	makePart(map, "PortalAtas", Vector3.new(21, 3, 3), Vector3.new(-33, 20, -52), Color3.fromRGB(140, 0, 255), Enum.Material.Neon)

	-- Pohon-pohon (posisi tetap agar map selalu sama)
	math.randomseed(12345)
	for _ = 1, 18 do
		local x = math.random(-100, 100)
		local z = math.random(-100, 100)
		if math.abs(x) > 18 or z < 10 then
			makeTree(map, x, z)
		end
	end

	-- Pencahayaan cerah siang hari
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14
	lighting.Brightness = 2

	print("[KlikSim] Map otomatis selesai dibuat.")
end

buildMap()
