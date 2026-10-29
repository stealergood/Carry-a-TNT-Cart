-- Party state is session-only. Studio owns the UI, zones and cart template.
return table.freeze({
	MaxPlayers = 4,
	DefaultCapacity = 1,
	MaxCheckpoint = 4,
	CountdownSeconds = 15,
	ConfigureTimeout = 60,
	TickInterval = 0.1,
	ReentryCooldown = 2,
	RequestInterval = 0.25,
	FriendRetryInterval = 3,
	CharacterReadyTimeout = 30,
	SpawnRetryInterval = 1,
	SpawnClearRadius = 12,
	CheckpointHeight = 10,
	TemplateName = "PartyCartTemplate",
	RemoteFolder = "PartyRemotes",
	AdminUsernames = table.freeze({
		"xintaroze",
	}),
	AttachmentNames = table.freeze({
		"PullAttachment",
		"PullAttachmentBack",
		"PullAttachmentRight",
		"PullAttachmentLeft",
	}),
	AttachmentOffsets = table.freeze({
		Vector3.new(2.2, 0.35, 0),
		Vector3.new(-2.2, 0.35, 0),
		Vector3.new(0, 0.35, 1.7),
		Vector3.new(0, 0.35, -1.7),
	}),
	CartSpawnRotation = CFrame.Angles(0, math.rad(90), 0),
	-- Track runs along -Z. With cart rotated 90 deg (CartSpawnRotation), front is -Z,
	-- back is +Z, right side is +X, and left side is -X.
	MemberOffsets = table.freeze({
		Vector3.new(0, 2, -5.5),
		Vector3.new(0, 2, 5.5),
		Vector3.new(4.5, 2, 0),
		Vector3.new(-4.5, 2, 0),
	}),
})
