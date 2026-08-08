# RAMManager.gd
# Manages RAM budget for the current level
extends Node

var current_ram: int = 150
var max_ram: int     = 150
var total_earned: int = 0
var total_spent: int  = 0

signal ram_changed(current: int, max: int)

func initialize(starting_ram: int) -> void:
	current_ram = starting_ram
	max_ram     = starting_ram
	total_earned = 0
	total_spent  = 0
	ram_changed.emit(current_ram, max_ram)

func can_afford(cost: int) -> bool:
	return current_ram >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		SoundManager.play_error()
		return false
	SoundManager.play_ram_spend()
	current_ram -= cost
	total_spent  += cost
	ram_changed.emit(current_ram, max_ram)
	return true

func earn(amount: int) -> void:
	var before = current_ram
	current_ram = min(current_ram + amount, max_ram * 2)
	total_earned += amount
	ram_changed.emit(current_ram, max_ram)

func get_current() -> int:
	return current_ram

# Utilization-based RAM efficiency (0..1):
#   1.0 = the player kept right at the budget ceiling (spent aggressively, no idle RAM)
#   0.0 = all earned RAM is sitting untouched in the pool (never spent on towers)
func get_efficiency() -> float:
	if total_spent + current_ram <= 0:
		return 0.0
	return clamp(float(total_spent) / float(total_spent + current_ram), 0.0, 1.0)
