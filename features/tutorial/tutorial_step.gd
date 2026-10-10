class_name TutorialStep
extends Resource

## Stable identifier, useful for saving progress and debugging.
@export var id: StringName
## Shown in the objective panel while the step is active.
@export_multiline var objective_text: String
## Optional dialogue cue played through the DialogueCoordinator when the step starts.
@export var dialogue_cue: StringName
## Features the player may use during this step. Everything else is blocked.
@export var allowed_features: Array[GameFeature.Id] = []
## Optional group name of a Control to spotlight. Add the Control to this group.
@export var highlight_group: StringName
## Finishes the step. A step without one completes immediately.
@export var complete_when: TutorialCondition
## Optional. When met, the tutorial returns to the previous step. It should not already
## hold when this step is entered, otherwise the tutorial bounces back immediately.
@export var back_when: TutorialCondition
