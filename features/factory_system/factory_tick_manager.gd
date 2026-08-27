class_name FactoryTickManager
extends Node

@export var factory_manager: FactoryManager
@export_range(1.0, 60.0, 1.0) var tick_rate := 20
@export_range(1, 20) var max_catch_up_ticks := 4

var tick_count := 0
var _accumulator := 0.0


func _process(delta: float) -> void:
    if not is_instance_valid(factory_manager):
        return

    var tick_delta := 1.0 / tick_rate
    _accumulator += delta

    var catch_up_ticks := 0

    while (
        _accumulator >= tick_delta
        and catch_up_ticks < max_catch_up_ticks
    ):
        _accumulator -= tick_delta
        _tick_all(tick_delta)
        catch_up_ticks += 1

    if catch_up_ticks == max_catch_up_ticks:
        _accumulator = fmod(_accumulator, tick_delta)


func _tick_all(delta: float) -> void:
    tick_count += 1

    var machines := factory_manager.get_machines().duplicate()

    for machine in machines:
        if not _can_tick(machine):
            continue

        machine.factory_tick(delta, factory_manager)


func _can_tick(machine: Node) -> bool:
    return (
        is_instance_valid(machine)
        and not machine.is_queued_for_deletion()
        and factory_manager.is_machine_registered(machine)
    )


func reset_tick_count() -> void:
    tick_count = 0
    _accumulator = 0.0