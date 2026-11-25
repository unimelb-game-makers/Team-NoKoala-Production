class_name Npc
extends CharacterBody3D

@export var job_consumer: JobConsumer
@export var idle_job_provider: IdleJobProvider
@export var movement: Movement
@export var inventory_owner: InventoryOwner

@export var definition: NPCDefinition
@export var ui_panels: Array[PackedScene] = []

signal enabled_work_types_changed

func configure(
	clock: FixedClock,
	jobs: JobBoard,
	reservations: ReservationManager,
	grid: Grid,
	faith_manager: FaithManager,
) -> void:
	# ensures all npcs get unique definition
	definition = definition.duplicate(true)
	job_consumer.configure(
		self,
		movement,
		inventory_owner,
		clock,
		jobs,
		reservations,
		grid,
		definition,
		faith_manager,
	)
	idle_job_provider.configure(jobs)
	movement.configure(grid.pathfinder)
	
func work_types_changed(type: WorkType.Value) -> void:
	definition.worker_capability.change_work_type(type)
	enabled_work_types_changed.emit()
	
func get_ui_panels() -> Array[PackedScene]:
	return ui_panels
