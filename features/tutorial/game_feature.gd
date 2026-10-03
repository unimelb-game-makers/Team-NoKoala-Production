class_name GameFeature
extends RefCounted

## Every player-facing feature the tutorial can lock. Features that are not
## whitelisted by the current tutorial step are blocked.
enum Id {
	MOVE,
	JUMP,
	CAMERA,
	WORK,
	HOTBAR,
	NPC_COMMAND,
	ITEM_PICKUP,
	MACHINE_UI,
	BUILD_MENU,
	PLACE_MACHINE,
	ITEM_SPAWN,
}
