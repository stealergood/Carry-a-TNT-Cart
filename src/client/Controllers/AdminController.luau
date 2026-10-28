local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.PartyConfig)

local AdminController = {}
local player = Players.LocalPlayer
local started = false

local function isRegisteredAdmin(targetPlayer: Player): boolean
	if targetPlayer:GetAttribute("IsAdmin") == true then
		return true
	end
	local lowerName = string.lower(targetPlayer.Name)
	for _, adminName in ipairs(Config.AdminUsernames) do
		if string.lower(adminName) == lowerName then
			return true
		end
	end
	return false
end

function AdminController.Start()
	if started then
		return
	end
	started = true

	local playerGui = player:WaitForChild("PlayerGui")
	local hudGui = playerGui:WaitForChild("AdminHudGui", 15)
	local menuGui = playerGui:WaitForChild("MenuAdmin", 15)
	if not hudGui or not menuGui then
		return
	end

	if not isRegisteredAdmin(player) then
		hudGui.Enabled = false
		menuGui.Enabled = false
		return
	end

	local remotes = ReplicatedStorage:WaitForChild(Config.RemoteFolder, 15)
	local requestRemote = remotes and remotes:WaitForChild("Request", 10)
	local Motion = require(ReplicatedStorage:WaitForChild("StudMotion"))

	local hudSounds = hudGui:WaitForChild("Sons")
	local menuSounds = menuGui:WaitForChild("Sons")
	Motion.CreateSounds(hudSounds)
	Motion.CreateSounds(menuSounds)

	local adminContainer = hudGui:WaitForChild("AdminContainer")
	local hudScale = adminContainer:WaitForChild("WindowScale")
	local adminButton = adminContainer:WaitForChild("AdminButton")
	Motion.BindResponsive(hudScale, 0.85)

	local fenetre = menuGui:WaitForChild("Fenetre")
	local entete = fenetre:WaitForChild("Entete")
	local headerIcon = entete:FindFirstChild("Icone")
	if headerIcon and headerIcon:IsA("GuiObject") then
		Motion.Sway(headerIcon, 3, 1.6)
	end

	local corps = fenetre:WaitForChild("Corps")
	local content = corps:WaitForChild("Content")
	local statusBanner = content:WaitForChild("StatusBanner")
	local currentCpLabel = statusBanner:WaitForChild("CurrentCPLabel") :: TextLabel
	local cpGrid = content:WaitForChild("CPGrid")
	local lobbyButton = content:WaitForChild("TeleportLobby") :: GuiButton

	local cpButtons: { GuiButton } = {}
	for cp = 1, Config.MaxCheckpoint do
		local btn = cpGrid:WaitForChild("TeleportCP" .. cp, 5)
		if btn and btn:IsA("GuiButton") then
			table.insert(cpButtons, btn)
		end
	end

	local function updateStatusLabel()
		local activeCp = player:GetAttribute("PartyCheckpoint") or player:GetAttribute("Checkpoint") or 0
		if typeof(activeCp) ~= "number" or activeCp <= 0 then
			currentCpLabel.Text = "CURRENT: LOBBY (CP 0)"
		else
			currentCpLabel.Text = string.format("CURRENT: CHECKPOINT %d / %d", activeCp, Config.MaxCheckpoint)
		end
	end

	player:GetAttributeChangedSignal("Checkpoint"):Connect(updateStatusLabel)
	player:GetAttributeChangedSignal("PartyCheckpoint"):Connect(updateStatusLabel)
	updateStatusLabel()

	local menu = Motion.Window(menuGui, fenetre, {
		Keep = {
			PartyGui = true,
		},
		OnOpen = function()
			updateStatusLabel()
			for index, btn in ipairs(cpButtons) do
				task.delay((index - 1) * 0.04, function()
					if fenetre.Visible and btn.Parent then
						Motion.PopIn(btn, 0.3)
					end
				end)
			end
			task.delay(#cpButtons * 0.04, function()
				if fenetre.Visible and lobbyButton.Parent then
					Motion.PopIn(lobbyButton, 0.3)
				end
			end)
		end,
	})

	Motion.BindButton(adminButton, 1.04, hudSounds, function()
		menu.Toggle()
	end)

	local nextTeleportTime = 0
	local function bindTeleportButton(button: GuiButton, targetCp: number)
		Motion.BindButton(button, 1.05, menuSounds, function()
			local now = os.clock()
			if now < nextTeleportTime then
				return
			end
			nextTeleportTime = now + Config.RequestInterval + 0.05
			if requestRemote then
				Motion.Play(menuSounds, "Achat")
				requestRemote:FireServer("AdminTeleportCP", targetCp)
				menu.Close()
			end
		end)
	end

	for cp = 1, Config.MaxCheckpoint do
		local btn = cpGrid:FindFirstChild("TeleportCP" .. cp)
		if btn and btn:IsA("GuiButton") then
			bindTeleportButton(btn, cp)
		end
	end
	bindTeleportButton(lobbyButton, 0)

	hudGui.Enabled = true
	menuGui.Enabled = true
end

return AdminController
