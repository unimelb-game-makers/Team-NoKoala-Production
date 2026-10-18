class_name TutorialCondition
extends Resource

## Emitted once the condition is met. [method start] may emit it synchronously
## if the condition already holds.
signal satisfied
## Emitted with a 0..1 ratio while the condition is partway done. Only meaningful
## when [method has_progress] is true.
signal progress_changed(ratio: float)


## Whether this condition reports [signal progress_changed], so the UI can show a bar.
func has_progress() -> bool:
	return false


## Begins listening. Implementations must reset any state from a previous run.
func start(_ctx: TutorialContext) -> void:
	pass


## Stops listening and disconnects from everything [method start] connected to.
func stop() -> void:
	pass
