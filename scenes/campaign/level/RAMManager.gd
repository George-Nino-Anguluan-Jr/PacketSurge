# RAMManager.gd
# Manages RAM budget for the current level
extends Node

var current_ram: int = 150
var max_ram: int     = 150

signal ram_changed(current: int, max: int)

func initialize(starting_ram: int) -> void:
	current_ram = starting_ram
	max_ram     = starting_ram
	ram_changed.emit(current_ram, max_ram)

func can_afford(cost: int) -> bool:
	return current_ram >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	current_ram -= cost
	ram_changed.emit(current_ram, max_ram)
	return true

func earn(amount: int) -> void:
	current_ram = min(current_ram + amount, max_ram * 2)
	ram_changed.emit(current_ram, max_ram)

func get_current() -> int:
	return current_ram
