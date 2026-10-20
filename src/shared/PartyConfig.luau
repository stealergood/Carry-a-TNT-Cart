-- Party state is session-only. Studio owns the UI, zones and cart template.
return table.freeze({
	MaxPlayers = 4,
	DefaultCapacity = 2,
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
	-- Front is +X on the existing cart, so its right side is +Z.
	MemberOffsets = table.freeze({
		Vector3.new(6, 2, 0),
		Vector3.new(-6, 2, 0),
		Vector3.new(0, 2, 5.5),
		Vector3.new(0, 2, -5.5),
	}),
})
