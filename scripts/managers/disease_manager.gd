class_name DiseaseManager
extends Node

const DEFAULT_DISEASES_PATH := "res://data/characters/diseases.json"

# Herb short codes used in ordered mixture keys
const CODE_ARTEMISIA := "A"
const CODE_VALERIANA := "V"
const CODE_SALVIA    := "S"

var diseases: Dictionary = {}


func load_from_json(path: String = DEFAULT_DISEASES_PATH) -> void:
	var data := JsonDataLoader.load_json(path)
	diseases = data.get("diseases", {})


func has_disease(disease_id: String) -> bool:
	return diseases.has(disease_id)


func get_disease(disease_id: String) -> Dictionary:
	return diseases.get(disease_id, {})


# Main lookup. combination is an ordered Array[String] of herb full-names,
# e.g. ["artemisia", "valeriana", "salvia"].
# patient is used to decide whether to look up plague or underlying disease.
func get_effect(patient: Patient, combination: Array) -> Dictionary:
	if combination.size() != 3:
		return _unknown_effect()

	var key := _combination_key(combination)

	if patient.has_plague:
		var plague_id := "praga_mutada" if patient.plague_mutated else "praga"
		return _lookup_recipe(plague_id, key)

	return _lookup_recipe(patient.disease_name, key)


func get_combination_key_for_display(combination: Array) -> String:
	return _combination_key(combination)


func herb_name_to_code(herb_name: String) -> String:
	match herb_name:
		ResourceManager.ARTEMISIA:
			return CODE_ARTEMISIA
		ResourceManager.VALERIANA:
			return CODE_VALERIANA
		ResourceManager.SALVIA:
			return CODE_SALVIA
		_:
			return "?"


func get_disease_display_name(disease_id: String) -> String:
	var disease: Dictionary = diseases.get(disease_id, {})
	return str(disease.get("display_name", disease_id))


func get_disease_symptoms(disease_id: String) -> Array:
	var disease: Dictionary = diseases.get(disease_id, {})
	return disease.get("symptoms", [])


# Returns all diseases with known_to_player: true, formatted for the Receituário.
func get_known_diseases() -> Array:
	var result: Array = []
	for disease_id in diseases:
		var d: Dictionary = diseases[disease_id]
		if not d.get("known_to_player", false):
			continue
		var recipes: Dictionary = d.get("recipes", {})
		var recipe_key: String = str(recipes.keys()[0]) if not recipes.is_empty() else ""
		result.append({
			"id": disease_id,
			"display_name": str(d.get("display_name", disease_id)),
			"symptoms": d.get("symptoms", []),
			"recipe_key": recipe_key,
		})
	return result


func _combination_key(combination: Array) -> String:
	var codes: Array[String] = []
	for herb_name in combination:
		codes.append(herb_name_to_code(str(herb_name)))
	return "|".join(codes)


func _lookup_recipe(disease_id: String, key: String) -> Dictionary:
	var disease_data: Dictionary = diseases.get(disease_id, {})
	var recipes: Dictionary = disease_data.get("recipes", {})

	if recipes.has(key):
		return recipes[key].duplicate()

	return _unknown_effect()


func _unknown_effect() -> Dictionary:
	return {
		"display_name": "mistura desconhecida",
		"outcome": "bad",
	}
