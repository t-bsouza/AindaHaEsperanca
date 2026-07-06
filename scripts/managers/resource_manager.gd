class_name ResourceManager
extends Node

signal resources_changed(resources: Dictionary)

const ARTEMISIA := "artemisia"
const VALERIANA := "valeriana"
const SALVIA    := "salvia"

const DEFAULT_ARTEMISIA := 3
const DEFAULT_VALERIANA := 3
const DEFAULT_SALVIA    := 3

const COLLECT_AMOUNT := 1
const COLLECT_TIME_COST := 3

var artemisia: int = DEFAULT_ARTEMISIA
var valeriana: int = DEFAULT_VALERIANA
var salvia: int    = DEFAULT_SALVIA


func reset() -> void:
	artemisia = DEFAULT_ARTEMISIA
	valeriana = DEFAULT_VALERIANA
	salvia    = DEFAULT_SALVIA
	resources_changed.emit(get_snapshot())


func get_resource(herb: String) -> int:
	match herb:
		ARTEMISIA: return artemisia
		VALERIANA: return valeriana
		SALVIA:    return salvia
		_: return 0


func add_resource(herb: String, amount: int) -> void:
	match herb:
		ARTEMISIA: artemisia += amount
		VALERIANA: valeriana += amount
		SALVIA:    salvia    += amount
	resources_changed.emit(get_snapshot())


func collect_herbs() -> void:
	artemisia += COLLECT_AMOUNT
	valeriana += COLLECT_AMOUNT
	salvia    += COLLECT_AMOUNT
	resources_changed.emit(get_snapshot())


# location: "porto" | "floresta" | "campo"
func collect_from_location(location: String) -> void:
	match location:
		"porto":    artemisia += 2; salvia    += 1
		"floresta": valeriana += 2; salvia    += 1
		"campo":    salvia    += 2; artemisia += 1
	resources_changed.emit(get_snapshot())


# combination is an ordered Array[String] of herb names, length == 3.
# multiplier doubles consumption for special patients (e.g. Nara).
func can_apply_combination(combination: Array, multiplier: int = 1) -> bool:
	if combination.size() != 3:
		return false
	var counts := _count_herbs(combination)
	for herb in counts:
		if get_resource(herb) < counts[herb] * multiplier:
			return false
	return true


func consume_combination(combination: Array, multiplier: int = 1) -> bool:
	if not can_apply_combination(combination, multiplier):
		return false
	var counts := _count_herbs(combination)
	for herb in counts:
		match herb:
			ARTEMISIA: artemisia -= counts[herb] * multiplier
			VALERIANA: valeriana -= counts[herb] * multiplier
			SALVIA:    salvia    -= counts[herb] * multiplier
	resources_changed.emit(get_snapshot())
	return true


func get_snapshot() -> Dictionary:
	return { ARTEMISIA: artemisia, VALERIANA: valeriana, SALVIA: salvia }


func describe_combination(combination: Array) -> String:
	if combination.size() != 3:
		return "mistura inválida"
	var names := { ARTEMISIA: "Artemísia", VALERIANA: "Valeriana", SALVIA: "Sálvia" }
	var parts: Array[String] = []
	for herb in combination:
		parts.append(str(names.get(herb, herb)))
	return " → ".join(parts)


func _count_herbs(combination: Array) -> Dictionary:
	var counts := {}
	for herb in combination:
		counts[herb] = counts.get(herb, 0) + 1
	return counts
