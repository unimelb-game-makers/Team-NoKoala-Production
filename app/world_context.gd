class_name WorldContext
extends RefCounted

signal player_changed(player: Player)

var grid: Grid
var clock: FixedClock
var factory: FactoryManager
var faith: FaithManager
var jobs: JobBoard
var reservations: ReservationManager
var pathfinder: Pathfinder
var player: Player
var placement: MachinePlacementController


func set_player(new_player: Player) -> void:
	if player == new_player:
		return
	player = new_player
	player_changed.emit(player)
