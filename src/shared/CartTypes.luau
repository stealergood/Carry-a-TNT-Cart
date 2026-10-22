export type CartState = "Idle" | "Claiming" | "Pulling" | "Releasing" | "Disabled"

export type CartRecord = {
	partyId: string?,
	participants: {
		{
			player: Player,
			slot: number,
			handAttachment: Attachment,
			attachment: Attachment,
			beam: Beam,
		}
	}?,
	model: Model,
	root: BasePart,
	prompt: ProximityPrompt,
	state: CartState,
	puller: Player?,
	rope: RopeConstraint?,
	beam: Beam?,
	handAttachment: Attachment?,
	connections: { RBXScriptConnection },
	claimConnections: { RBXScriptConnection },
	lastPosition: Vector3,
	lastCFrame: CFrame,
	lastCheck: number,
	lastClaim: number,
	exploded: boolean,
	respawnScheduled: boolean,
	respawnTemplate: Model?,
	respawnOwnerUserId: number?,
	spawnCFrame: CFrame,
	activeDamageParts: { [Instance]: number },
	windowStartPosition: Vector3,
	windowStartTime: number,
}

return table.freeze({})
