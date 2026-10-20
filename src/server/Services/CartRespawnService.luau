local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.CartConfig)
local Constants = require(ReplicatedStorage.Shared.CartConstants)

local CartRespawnService = {}

local templateFolder = ServerStorage:FindFirstChild("CarryCartTemplates")
if not templateFolder then
	templateFolder = Instance.new("Folder")
	templateFolder.Name = "CarryCartTemplates"
	templateFolder.Parent = ServerStorage
end

function CartRespawnService.CreateTemplate(model: Model): Model?
	local originalArchivable = model.Archivable
	model.Archivable = true
	local success, template = pcall(function()
		return model:Clone()
	end)
	model.Archivable = originalArchivable
	if not success or not template then
		warn("Tidak dapat membuat template respawn cart:", model:GetFullName())
		return nil
	end
	template.Name = model.Name .. "_Template"
	CollectionService:RemoveTag(template, Constants.Tag)
	template.Parent = templateFolder
	return template
end

function CartRespawnService.Schedule(record, ownerUserId: number?)
	if record.respawnScheduled or not record.respawnTemplate then
		return
	end
	record.respawnScheduled = true
	local template = record.respawnTemplate
	local name = record.model.Name
	local spawnCFrame = record.spawnCFrame
	task.delay(Config.CartRespawnDelay, function()
		if not template.Parent then
			return
		end
		local cart = template:Clone()
		cart.Name = name
		cart:SetAttribute("CartId", nil)
		cart:SetAttribute("Exploded", nil)
		cart:SetAttribute("RespawnOwnerUserId", ownerUserId)
		CollectionService:RemoveTag(cart, Constants.Tag)
		cart.Parent = workspace
		cart:PivotTo(spawnCFrame)
		CollectionService:AddTag(cart, Constants.Tag)
	end)
end

return CartRespawnService
