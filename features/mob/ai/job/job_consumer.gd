class_name JobConsumer
extends Node

@export var job_priorities: Dictionary[StringName, int]

var actor: Node3D
var movement: Movement
var inventory_owner: InventoryOwner
var fixed_clock: FixedClock
var job_board: JobBoard
var reservation_manager: ReservationManager
var faith_manager: FaithManager
var grid: Grid
var current_job: Job = null
var current_driver: JobDriver = null
var current_provider: JobProvider = null
var current_request: JobRequest = null


func configure(
	p_actor: Node3D,
	p_movement: Movement,
	p_inventory_owner: InventoryOwner,
	p_fixed_clock: FixedClock,
	p_job_board: JobBoard,
	p_reservation_manager: ReservationManager,
	p_grid: Grid,
	p_faith_manager: FaithManager,
) -> void:
	actor = p_actor
	movement = p_movement
	inventory_owner = p_inventory_owner
	fixed_clock = p_fixed_clock
	job_board = p_job_board
	reservation_manager = p_reservation_manager
	grid = p_grid
	faith_manager = p_faith_manager
	_connect_faith_manager()

func _connect_faith_manager() -> void:
	if faith_manager == null:
		return
	if not faith_manager.faith_depleted.is_connected(_on_faith_depleted):
		faith_manager.faith_depleted.connect(_on_faith_depleted)

func _on_faith_depleted() -> void:
	pass
	# interrupt_job() # TO DO: guard this with only factory workers

func _ready() -> void:
	if not fixed_clock.tick.is_connected(_on_tick):
		fixed_clock.tick.connect(_on_tick)


func _on_tick(delta: float, _ticks_due: int, _tick_count: int) -> void:
	if current_job == null:
		find_new_job()
		return

	if current_driver:
		var result := current_driver.tick(delta)

		if result == JobDriver.Status.SUCCESS:
			finish_job()
		elif result == JobDriver.Status.FAILURE:
			cancel_job()


func find_new_job() -> void:
	var candidates: Array[JobCandidate] = []
	var discovery_order := 0

	for provider in job_board.get_providers():
		for request in provider.get_available_requests(self):
			candidates.append(
				JobCandidate.new(
					provider,
					request,
					self,
					discovery_order,
				)
			)
			discovery_order += 1

	candidates.sort_custom(
		func(a: JobCandidate, b: JobCandidate) -> bool:
			return a.is_preferred_to(b)
	)

	for candidate in candidates:
		var job := candidate.provider.try_claim(candidate.request, self)
		if job != null:
			return _start_job(job, candidate.provider, candidate.request)


func get_job_priority(job_type: StringName) -> int:
	return job_priorities.get(job_type, 0)


func finish_job() -> void:
	_end_job(true)


func cancel_job() -> void:
	_end_job(false)


func interrupt_job() -> void:
	if current_job != null:
		cancel_job()


## Assign a specific provider request, transferring it from another consumer
## when necessary. Manual commands still respect disabled job types.
func assign_request(
	provider: JobProvider,
	request: JobRequest,
	item: FactoryItem = null,
) -> bool:
	if provider == null or request == null:
		return false
	if get_job_priority(request.job_type()) <= 0:
		return false

	var previous_owner := provider.get_active_consumer(request)
	if previous_owner == self:
		return true
	if previous_owner != null:
		previous_owner.interrupt_job()

	# Interruption restores the old request before the new claim. Do this only
	# after eligibility checks so an invalid command does not disturb work.
	interrupt_job()

	var job: Job
	if item != null:
		job = provider.try_claim_item(request, self, item)
	else:
		job = provider.try_claim(request, self)
	if job == null:
		return false

	return _start_job(job, provider, request)


func _start_job(
	job: Job,
	provider: JobProvider,
	request: JobRequest,
) -> bool:
	current_job = job
	current_provider = provider
	current_request = request
	current_driver = job.create_driver(self)

	var result := current_driver.start()
	if result == JobDriver.Status.FAILURE:
		print("Start job driver failed: ", current_driver)
		cancel_job()
		return false
	return true


func _end_job(completed: bool) -> void:
	if not completed and current_driver != null:
		current_driver.cancel()

	# A consumer runs one job at a time, so releasing everything it holds is
	# enough to free this job's item and destination cell.
	reservation_manager.release_all(self)
	if current_provider != null and is_instance_valid(current_provider):
		if completed:
			current_provider.complete_request(current_request, self)
		else:
			current_provider.cancel_request(current_request, self)
	current_job = null
	current_driver = null
	current_provider = null
	current_request = null


func _exit_tree() -> void:
	if fixed_clock != null and fixed_clock.tick.is_connected(_on_tick):
		fixed_clock.tick.disconnect(_on_tick)
	# Despawning mid-job must not leave its targets reserved forever.
	if current_job != null:
		cancel_job()
	elif reservation_manager != null:
		reservation_manager.release_all(self)
