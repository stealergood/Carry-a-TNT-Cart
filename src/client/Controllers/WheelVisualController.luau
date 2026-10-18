local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.CartConfig)
local Constants = require(ReplicatedStorage.Shared.CartConstants)

local WheelVisualController = {}
local states = {}

local function getMotors(model)
	local result = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant.Name == Constants.WheelMotor then
			table.insert(result, descendant)
		end
	end
	return result
end

local function updateModel(model, dt)
	local root = model:FindFirstChild(Constants.PhysicsRoot)
	if not root or not root:IsA("BasePart") or not model:IsDescendantOf(workspace) then
		states[model] = nil
		return
	end

	local state = states[model]
	if not state then
		state = {
			angle = 0,
			motors = getMotors(model),
		}
		states[model] = state
	end
	if #state.motors == 0 or not state.motors[1].Parent then
		state.motors = getMotors(model)
	end

	local forwardSpeed = root.AssemblyLinearVelocity:Dot(root.CFrame.RightVector)
	state.angle += forwardSpeed / Config.WheelVisualRadius * Config.WheelVisualSpinMultiplier * dt
	if math.abs(state.angle) > math.pi * 2 then
		state.angle %= math.pi * 2
	end
	local rotation = CFrame.Angles(0, 0, -state.angle)
	for _, motor in ipairs(state.motors) do
		motor.Transform = rotation
	end
end

function WheelVisualController.Start()
	RunService.RenderStepped:Connect(function(dt)
		local active = {}
		for _, model in ipairs(CollectionService:GetTagged(Constants.Tag)) do
			active[model] = true
			updateModel(model, dt)
		end
		for model in pairs(states) do
			if not active[model] then
				states[model] = nil
			end
		end
	end)
end

return WheelVisualController
