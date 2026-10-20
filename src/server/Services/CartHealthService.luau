local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Shared.CartConfig)
local Constants = require(ReplicatedStorage.Shared.CartConstants)
local CartExplosionService = require(script.Parent.CartExplosionService)

local CartHealthService = {}
local onDepleted

function CartHealthService.Start(callback)
	onDepleted = callback
end

local function getHealthGui(root: BasePart): BillboardGui
	local gui = root:FindFirstChild(Constants.HealthGui)
	if gui and not gui:IsA("BillboardGui") then
		gui:Destroy()
		gui = nil
	end
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = Constants.HealthGui
		gui.Adornee = root
		gui.AlwaysOnTop = true
		gui.LightInfluence = 0
		gui.MaxDistance = Config.HealthBarMaxDistance
		gui.Size = UDim2.fromOffset(Config.HealthBarSize.X, Config.HealthBarSize.Y)
		gui.StudsOffsetWorldSpace = Vector3.new(0, Config.HealthBarHeight, 0)
		gui.Parent = root

		local background = Instance.new("Frame")
		background.Name = "Background"
		background.AnchorPoint = Vector2.new(0.5, 0.5)
		background.Position = UDim2.fromScale(0.5, 0.5)
		background.Size = UDim2.fromScale(1, 0.58)
		background.BackgroundColor3 = Color3.fromRGB(37, 20, 20)
		background.BorderSizePixel = 0
		background.Parent = gui
		local backgroundCorner = Instance.new("UICorner")
		backgroundCorner.CornerRadius = UDim.new(0, 5)
		backgroundCorner.Parent = background

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(91, 220, 95)
		fill.BorderSizePixel = 0
		fill.Parent = background
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 5)
		fillCorner.Parent = fill
	end
	local oldText = gui:FindFirstChild("Value", true)
	if oldText then
		oldText:Destroy()
	end
	return gui
end

local function updateGui(record)
	local health = record.model:GetAttribute(Constants.HealthAttribute) or Config.CartMaxHealth
	local maxHealth = record.model:GetAttribute(Constants.MaxHealthAttribute) or Config.CartMaxHealth
	local ratio = math.clamp(health / math.max(maxHealth, 1), 0, 1)
	local gui = getHealthGui(record.root)
	gui.Enabled = health < maxHealth
	local background = gui:FindFirstChild("Background")
	local fill = background and background:FindFirstChild("Fill")
	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.fromScale(ratio, 1)
		fill.BackgroundColor3 = Color3.fromHSV(ratio * 0.33, 0.72, 0.9)
	end
end

local function getDamageSource(part: BasePart): Instance?
	local current: Instance? = part
	while current and current ~= workspace do
		if CollectionService:HasTag(current, Config.DamageTag) then
			return current
		end
		current = current.Parent
	end
	return nil
end

function CartHealthService.Damage(record, amount: number?): boolean
	local health = record.model:GetAttribute(Constants.HealthAttribute) or Config.CartMaxHealth
	if health <= 0 then
		return false
	end
	local newHealth = math.max(0, health - (amount or Config.DamagePerHit))
	record.model:SetAttribute(Constants.HealthAttribute, newHealth)
	updateGui(record)
	if newHealth <= 0 and not record.exploded then
		CartHealthService.Explode(record)
	end
	return true
end

-- Used when the puller dies. Keep the detonation path identical to normal
-- cart damage so cleanup, VFX, and scheduled replacement stay centralized.
function CartHealthService.Explode(record): boolean
	if record.exploded or not record.model.Parent then
		return false
	end
	record.exploded = true
	record.model:SetAttribute("Exploded", true)
	if onDepleted then
		onDepleted(record)
	end
	CartExplosionService.Explode(record)
	return true
end

local function beginDamageContact(record, source: Instance)
	if record.activeDamageParts[source] then
		record.activeDamageParts[source] = os.clock()
		return
	end
	record.activeDamageParts[source] = os.clock()
	CartHealthService.Damage(record)
end

local function watchCollider(record, collider: BasePart)
	collider.CanTouch = true
	table.insert(
		record.connections,
		collider.Touched:Connect(function(hit)
			if hit:IsA("BasePart") then
				local source = getDamageSource(hit)
				if source then
					beginDamageContact(record, source)
				end
			end
		end)
	)
end

function CartHealthService.Setup(record)
	record.model:SetAttribute(Constants.MaxHealthAttribute, Config.CartMaxHealth)
	record.model:SetAttribute(Constants.HealthAttribute, Config.CartMaxHealth)
	record.activeDamageParts = {}
	updateGui(record)
	local damageProxy = record.model:FindFirstChild(Constants.DamageProxy)
	if damageProxy and damageProxy:IsA("BasePart") then
		watchCollider(record, damageProxy)
	end
end

function CartHealthService.Update(record)
	if record.exploded or not record.model.Parent then
		return
	end
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { record.model }
	local damageProxy = record.model:FindFirstChild(Constants.DamageProxy)
	local currentDamageParts = {}
	if damageProxy and damageProxy:IsA("BasePart") then
		for _, hit in ipairs(workspace:GetPartsInPart(damageProxy, overlapParams)) do
			local source = getDamageSource(hit)
			if source then
				currentDamageParts[source] = true
			end
		end
	end
	local now = os.clock()
	for hit in pairs(currentDamageParts) do
		beginDamageContact(record, hit)
	end
	for hit, lastSeen in pairs(record.activeDamageParts) do
		if not hit.Parent or (not currentDamageParts[hit] and now - lastSeen >= Config.DamageExitGrace) then
			record.activeDamageParts[hit] = nil
		end
	end
end

return CartHealthService
