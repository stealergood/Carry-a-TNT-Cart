local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.CartConfig)
local Constants = require(game.ReplicatedStorage.Shared.CartConstants)

local CartValidationService = {}

function CartValidationService.GetCharacterRoot(player)
	if player.Parent ~= Players then
		return nil
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil
	end
	return root, humanoid
end

function CartValidationService.CanClaim(record, player, activeByPlayer)
	if record.partyId or player:GetAttribute("PartyId") then
		return false
	end
	if record.state ~= Constants.States.Idle or record.puller or activeByPlayer[player] then
		return false
	end
	if not record.model:IsDescendantOf(workspace) or record.root.Anchored then
		return false
	end
	local characterRoot = CartValidationService.GetCharacterRoot(player)
	if not characterRoot then
		return false
	end
	local attachment = record.root:FindFirstChild(Constants.PullAttachment)
	if not attachment or not attachment:IsA("Attachment") then
		return false
	end
	return (characterRoot.Position - attachment.WorldPosition).Magnitude <= Config.MaxClaimDistance
end

function CartValidationService.CheckActive(record)
	if record.partyId then
		if
			not record.model:IsDescendantOf(workspace)
			or record.root.Anchored
			or not record.participants
			or #record.participants == 0
		then
			return false, "party cart invalid"
		end
		for _, member in ipairs(record.participants) do
			local characterRoot = CartValidationService.GetCharacterRoot(member.player)
			if
				not characterRoot
				or not member.rope.Parent
				or not member.beam.Parent
				or not member.handAttachment.Parent
				or not member.attachment.Parent
			then
				return false, "party member invalid"
			end
			if (characterRoot.Position - member.attachment.WorldPosition).Magnitude > Config.MaxReleaseDistance then
				return false, "party rope too far"
			end
		end
		return true
	end
	local player = record.puller
	if not player or not record.model:IsDescendantOf(workspace) or record.root.Anchored then
		return false, "cart invalid"
	end
	local characterRoot = CartValidationService.GetCharacterRoot(player)
	if not characterRoot then
		return false, "character invalid"
	end
	local pull = record.root:FindFirstChild(Constants.PullAttachment)
	if not pull or not pull:IsA("Attachment") then
		return false, "attachment hilang"
	end
	if
		not record.rope
		or not record.rope.Parent
		or not record.beam
		or not record.beam.Parent
		or not record.handAttachment
		or not record.handAttachment.Parent
	then
		return false, "tali hilang"
	end
	if (characterRoot.Position - pull.WorldPosition).Magnitude > Config.MaxReleaseDistance then
		return false, "tali terlalu jauh"
	end
	return true
end

function CartValidationService.IsTeleport(record, now, maxSpeed)
	local dt = math.max(now - record.lastCheck, Config.ValidationInterval)
	local delta = (record.root.Position - record.lastPosition).Magnitude
	local windowDuration = math.max(now - record.windowStartTime, Config.ValidationInterval)
	local windowDelta = (record.root.Position - record.windowStartPosition).Magnitude
	return delta > maxSpeed * dt + Config.MaxTeleportSlack
		or windowDelta > maxSpeed * windowDuration + Config.MaxTeleportSlack
end

return CartValidationService
