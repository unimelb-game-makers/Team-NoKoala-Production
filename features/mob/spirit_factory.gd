class_name SpiritFactory

const DEMO_SPIRIT_SCENE = preload(
	"res://features/mob/spirit_scenes/demo_spirit.tscn"
)

static func create_spirit(world_context: WorldContext) -> Npc:
	var spirit := DEMO_SPIRIT_SCENE.instantiate() as Npc
	spirit.configure(
		world_context.clock,
		world_context.jobs,
		world_context.reservations,
		world_context.grid,
		world_context.pathfinder,
		world_context.faith,
	)
	return spirit
