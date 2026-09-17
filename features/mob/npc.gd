class_name Npc
extends CharacterBody3D

@export var job_consumer: JobConsumer
@export var idle_job_provider: IdleJobProvider
@export var movement: Movement
@export var inventory_owner: InventoryOwner


func configure(
	clock: FixedClock,
	jobs: JobBoard,
	reservations: ReservationManager,
	grid: Grid,
	pathfinder: Pathfinder,
) -> void:
	job_consumer.configure(
		self,
		movement,
		inventory_owner,
		clock,
		jobs,
		reservations,
		grid,
	)
	idle_job_provider.configure(jobs)
	movement.configure(pathfinder)
