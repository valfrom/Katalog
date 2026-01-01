# This script is an autoload, that can be accessed from any other script!

extends Node2D

signal hero_changed(hero_id)

const HERO_SELECT_SCENE_PATH := "res://Scenes/HeroSelect/HeroSelect.tscn"
const HERO_FOUND_SCENE_PATH := "res://Scenes/HeroSelect/HeroFound.tscn"

const HERO_ROSTER := [
{"id": "scarlet", "name": "Scarlet", "color": Color(0.91, 0.26, 0.32), "portrait_path": "res://Assets/Sprites/Portraits/Pirate.png"},
{"id": "bolt", "name": "Bolt", "color": Color(0.97, 0.71, 0.2), "portrait_path": "res://Assets/Sprites/Portraits/Mechanic.png"},
{"id": "ivy", "name": "Ivy", "color": Color(0.32, 0.73, 0.39), "portrait_path": "res://Assets/Sprites/Portraits/Mage.png"},
{"id": "frost", "name": "Frost", "color": Color(0.4, 0.71, 0.93), "portrait_path": "res://Assets/Sprites/Portraits/Cyborg.png"},
{"id": "ember", "name": "Ember", "color": Color(0.93, 0.48, 0.32), "portrait_path": "res://Assets/Sprites/Portraits/Ranger.png"},
{"id": "void", "name": "Void", "color": Color(0.65, 0.58, 0.9), "portrait_path": "res://Assets/Sprites/Portraits/Vampire.png"}
]

var score : int = 0
var saved_scene_path: String = ""
var saved_player_position: Vector2 = Vector2.ZERO
var restore_player_position: bool = false
var pending_level_scene: String = ""

var unlocked_heroes: Array[String] = []
var current_hero_queue: Array[String] = []
var current_hero_id: String = ""
var _active_level_player: Node = null
var recently_unlocked_hero: String = ""
var hero_unlock_return_scene: String = ""
var _initial_hero_selection_active: bool = false
var _initial_unlock_snapshot: Array[String] = []

func _ready():
	randomize()
	_ensure_default_hero()

# Adds 1 to score variable
func add_score():
	score += 1

# Loads next level
func load_next_level(next_scene : PackedScene):
	get_tree().change_scene_to_packed(next_scene)

func save_player_state(scene_path: String, player_position: Vector2):
	saved_scene_path = scene_path
	saved_player_position = player_position
	restore_player_position = false

func mark_restore_player_position():
	restore_player_position = true

func consume_restore_flag() -> bool:
	var should_restore := restore_player_position
	restore_player_position = false
	return should_restore

func _ensure_default_hero() -> void:
        if unlocked_heroes.is_empty():
                unlocked_heroes.append(HERO_ROSTER[0]["id"])
                current_hero_id = HERO_ROSTER[0]["id"]

func unlock_all_heroes() -> void:
        unlocked_heroes.clear()
        for hero in HERO_ROSTER:
                unlocked_heroes.append(hero["id"])

func begin_initial_hero_selection() -> void:
        _initial_unlock_snapshot = unlocked_heroes.duplicate()
        _initial_hero_selection_active = true
        unlock_all_heroes()

func get_hero_definition(hero_id: String) -> Dictionary:
	for hero in HERO_ROSTER:
		if hero["id"] == hero_id:
			return hero
	return {}

func prepare_hero_run(selected_hero: String) -> void:
        _ensure_default_hero()
        if !unlocked_heroes.has(selected_hero):
                selected_hero = unlocked_heroes[0]

        if _initial_hero_selection_active:
                unlocked_heroes.clear()
                unlocked_heroes.append(selected_hero)
                _initial_hero_selection_active = false
                if _initial_unlock_snapshot.size() > 0:
                        unlocked_heroes = _initial_unlock_snapshot.duplicate()
                        if !unlocked_heroes.has(selected_hero):
                                unlocked_heroes.push_front(selected_hero)
        _initial_unlock_snapshot.clear()

	current_hero_queue = unlocked_heroes.duplicate()
	current_hero_queue.erase(selected_hero)
	current_hero_queue.push_front(selected_hero)
	current_hero_id = selected_hero
	emit_signal("hero_changed", current_hero_id)

func advance_to_next_hero() -> bool:
	if current_hero_queue.size() <= 1:
		current_hero_queue.clear()
		current_hero_id = ""
		return false

	current_hero_queue.pop_front()
	current_hero_id = current_hero_queue[0]
	emit_signal("hero_changed", current_hero_id)
	return true

func unlock_random_locked_hero() -> String:
	var locked: Array[String] = []
	for hero in HERO_ROSTER:
		if !unlocked_heroes.has(hero["id"]):
			locked.append(hero["id"])

	if locked.is_empty():
		return ""

	var newly_unlocked := locked[randi() % locked.size()]
	unlocked_heroes.append(newly_unlocked)
	recently_unlocked_hero = newly_unlocked
	return newly_unlocked

func prepare_hero_unlock(hero_id: String, return_scene: String) -> void:
	recently_unlocked_hero = hero_id
	hero_unlock_return_scene = return_scene

func consume_unlocked_hero() -> String:
	var hero_id := recently_unlocked_hero
	recently_unlocked_hero = ""
	return hero_id

func consume_hero_unlock_return_scene() -> String:
	var target_scene := hero_unlock_return_scene
	hero_unlock_return_scene = ""
	return target_scene

func register_level_player(player: Node) -> void:
	_ensure_default_hero()
	_active_level_player = player
	if current_hero_queue.is_empty() and !unlocked_heroes.is_empty():
		current_hero_queue = unlocked_heroes.duplicate()
		current_hero_id = unlocked_heroes[0]
	if !hero_changed.is_connected(_apply_current_hero):
		hero_changed.connect(_apply_current_hero)
	_apply_current_hero(current_hero_id)

func _apply_current_hero(_hero_id: String) -> void:
	if _active_level_player == null:
		return

	var hero_id := _hero_id if _hero_id != "" else current_hero_id
	var hero := get_hero_definition(hero_id)
	if hero.is_empty():
		return

	if _active_level_player.has_method("apply_hero"):
		_active_level_player.apply_hero(hero)

func handle_level_player_death(player: Node) -> void:
	await player.death_tween()

	if advance_to_next_hero():
		_apply_current_hero(current_hero_id)
		await player.play_respawn()
		return

	current_hero_queue.clear()
	current_hero_id = ""

	if saved_scene_path != "":
		mark_restore_player_position()
		SceneTransition.load_scene(saved_scene_path)
	else:
		await player.play_respawn()
