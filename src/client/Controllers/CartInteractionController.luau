local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.CartConstants)

local CartInteractionController = {}
local function makeStatusGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CarryCartStatus"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local label = Instance.new("TextLabel")
	label.Name = "Status"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.fromScale(0.5, 0.96)
	label.Size = UDim2.fromOffset(330, 42)
	label.BackgroundColor3 = Color3.fromRGB(34, 28, 23)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.fromRGB(255, 239, 210)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Text = "Gerobak terhubung"
	label.Visible = false
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	return label
end

function CartInteractionController.Start()
	local player = Players.LocalPlayer
	local label = makeStatusGui()
	local activeValue

	local function refresh()
		activeValue = player:FindFirstChild(Constants.ActiveCartValue)
		local active = activeValue ~= nil and activeValue.Value ~= nil
		label.Visible = active
	end

	player.ChildAdded:Connect(function(child)
		if child.Name == Constants.ActiveCartValue then
			child:GetPropertyChangedSignal("Value"):Connect(refresh)
			refresh()
		end
	end)
	player.ChildRemoved:Connect(function(child)
		if child == activeValue then
			refresh()
		end
	end)
	local existing = player:FindFirstChild(Constants.ActiveCartValue)
	if existing then
		existing:GetPropertyChangedSignal("Value"):Connect(refresh)
	end
	refresh()
end

return CartInteractionController
