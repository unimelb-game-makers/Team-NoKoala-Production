class_name TutorialContext
extends RefCounted

## Emitted for every input event while the tutorial runs.
signal input_received(event: InputEvent)
## Emitted every physics frame while the tutorial runs.
signal ticked(delta: float)

var tree: SceneTree
var gate: FeatureGate
var factory: FactoryManager
var dialogue_coordinator: DialogueCoordinator
var player: Player
var camera: CameraController
var placement: MachinePlacementController
