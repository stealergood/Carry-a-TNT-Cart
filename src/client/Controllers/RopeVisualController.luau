local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.CartConfig)
local Constants = require(ReplicatedStorage.Shared.CartConstants)

local RopeVisualController = {}
local beams = {}
local connections = {}

local function trackDescendant(descendant)
	if descendant:IsA("Beam") and descendant.Name == Constants.Beam then
		beams[descendant] = true
	end
end

local function trackModel(model)
	if connections[model] then
		return
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		trackDescendant(descendant)
	end
	connections[model] = model.DescendantAdded:Connect(trackDescendant)
end

local function untrackModel(model)
	local connection = connections[model]
	if connection then
		connection:Disconnect()
	end
	connections[model] = nil
	for beam in pairs(beams) do
		if beam:IsDescendantOf(model) then
			beams[beam] = nil
		end
	end
end

function RopeVisualController.Start()
	for _, model in ipairs(CollectionService:GetTagged(Constants.Tag)) do
		trackModel(model)
	end
	CollectionService:GetInstanceAddedSignal(Constants.Tag):Connect(trackModel)
	CollectionService:GetInstanceRemovedSignal(Constants.Tag):Connect(untrackModel)
	RunService.RenderStepped:Connect(function()
		for beam in pairs(beams) do
			local a = beam.Attachment0
			local b = beam.Attachment1
			if not beam.Parent or not a or not b or not b.Parent then
				beams[beam] = nil
			else
				local distance = (a.WorldPosition - b.WorldPosition).Magnitude
				local slack = math.max(0, Config.RopeSlackLength - distance)
				local sag = math.min(slack * 0.12, 0.8)
				beam.CurveSize0 = -sag
				beam.CurveSize1 = sag
			end
		end
	end)
end

return RopeVisualController
