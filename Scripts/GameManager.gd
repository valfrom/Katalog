# This script is an autoload, that can be accessed from any other script!

extends Node2D

signal hero_changed(hero_id)

const HERO_SELECT_SCENE_PATH := "res://Scenes/HeroSelect/HeroSelect.tscn"
const HERO_FOUND_SCENE_PATH := "res://Scenes/HeroSelect/HeroFound.tscn"
const HERO_LIVES := 3
const PORTRAIT_DIR_PATH := "res://Assets/Sprites/Portraits"

var HERO_ROSTER: Array = []

var score: int = 0
var saved_scene_path: String = ""
var saved_player_position: Vector2 = Vector2.ZERO
var restore_player_position: bool = false
var pending_level_scene: String = ""

var unlocked_heroes: Array[String] = []
var current_hero_queue: Array[String] = []
var current_hero_id: String = ""
var hero_lives: Dictionary = {}
var _active_level_player: Node = null
var recently_unlocked_hero: String = ""
var hero_unlock_return_scene: String = ""
var selecting_initial_hero: bool = false
var discovered_levels: Array[String] = []

func _ready():
    _build_hero_roster()
    randomize()
    _ensure_default_hero()

func _build_hero_roster() -> void:
    HERO_ROSTER.clear()

    var portraits := DirAccess.open(PORTRAIT_DIR_PATH)
    if portraits == null:
        push_warning("Could not open portraits directory: %s" % PORTRAIT_DIR_PATH)
        return

    portraits.list_dir_begin()
    while true:
        var file_name := portraits.get_next()
        if file_name == "":
            break
        if portraits.current_is_dir():
            continue
        if !file_name.to_lower().ends_with(".png"):
            continue

        var base_name := file_name.get_basename()
        var hero_id := base_name.to_lower()
        HERO_ROSTER.append({
            "id": hero_id,
            "name": base_name,
            "portrait_path": "%s/%s" % [PORTRAIT_DIR_PATH, file_name],
            "color": _color_from_name(hero_id)
        })

    portraits.list_dir_end()
    HERO_ROSTER.sort_custom(Callable(self, "_sort_heroes_by_name"))

func _sort_heroes_by_name(a: Dictionary, b: Dictionary) -> bool:
    return a.get("name", "") < b.get("name", "")

func _color_from_name(hero_id: String) -> Color:
    var hash_value = abs(hash(hero_id))
    var hue := float(hash_value % 360) / 360.0
    var saturation = clamp(0.6 + float((hash_value / 360) % 40) / 100.0, 0.6, 0.95)
    return Color.from_hsv(hue, saturation, 0.9)

func _get_starting_hero_id() -> String:
    if HERO_ROSTER.is_empty():
        return ""
    return HERO_ROSTER[0].get("id", "")

# Adds 1 to score variable
func add_score():
    score += 1

# Loads next level
func load_next_level(next_scene: PackedScene):
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
    var starting_hero := _get_starting_hero_id()
    if starting_hero == "":
        return

    if unlocked_heroes.is_empty():
        unlocked_heroes.append(starting_hero)
        current_hero_id = starting_hero

func start_new_game() -> void:
    var starting_hero := _get_starting_hero_id()
    if starting_hero == "":
        return

    unlocked_heroes.clear()
    unlocked_heroes.append(starting_hero)
    current_hero_queue = unlocked_heroes.duplicate()
    current_hero_id = starting_hero
    _reset_hero_lives()
    saved_scene_path = ""
    saved_player_position = Vector2.ZERO
    restore_player_position = false
    pending_level_scene = "res://Scenes/Maps/Map_01.tscn"
    recently_unlocked_hero = ""
    hero_unlock_return_scene = ""
    selecting_initial_hero = false
    discovered_levels.clear()

func finalize_initial_hero_selection(hero_id: String) -> void:
    if !selecting_initial_hero:
        return

    var target_hero := hero_id
    if get_hero_definition(target_hero).is_empty():
        target_hero = _get_starting_hero_id()
    if target_hero == "":
        return

    unlocked_heroes = [target_hero]
    current_hero_queue.clear()
    current_hero_id = target_hero
    selecting_initial_hero = false

func get_hero_definition(hero_id: String) -> Dictionary:
    for hero in HERO_ROSTER:
        if hero["id"] == hero_id:
            return hero
    return {}

func prepare_hero_run(selected_hero: String) -> void:
    _ensure_default_hero()
    if !unlocked_heroes.has(selected_hero):
        selected_hero = unlocked_heroes[0]

    current_hero_queue = unlocked_heroes.duplicate()
    current_hero_queue.erase(selected_hero)
    current_hero_queue.push_front(selected_hero)
    current_hero_id = selected_hero
    _reset_hero_lives()
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

func mark_level_discovered(scene_path: String) -> void:
    var normalized_path := _normalize_scene_path(scene_path)
    if normalized_path == "":
        return

    if !discovered_levels.has(normalized_path):
        discovered_levels.append(normalized_path)

func is_level_discovered(scene_path: String) -> bool:
    var normalized_path := _normalize_scene_path(scene_path)
    if normalized_path == "":
        return false

    return discovered_levels.has(normalized_path)

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
    _ensure_hero_lives_initialized()
    if not hero_changed.is_connected(_apply_current_hero):
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

    _ensure_hero_lives_initialized()
    var remaining_lives := _decrement_hero_life(current_hero_id)
    if remaining_lives > 0:
        await player.play_respawn()
        return

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

func _normalize_scene_path(scene_path: String) -> String:
    if scene_path == "":
        return ""

    if scene_path.begins_with("uid://"):
        return scene_path

    var uid := ResourceLoader.get_resource_uid(scene_path)
    if uid != 0:
        return ResourceUID.id_to_text(uid)

    return scene_path

func _reset_hero_lives() -> void:
    hero_lives.clear()
    for hero_id in current_hero_queue:
        hero_lives[hero_id] = HERO_LIVES

func _ensure_hero_lives_initialized() -> void:
    if current_hero_queue.is_empty():
        return

    if hero_lives.is_empty():
        _reset_hero_lives()
        return

    for hero_id in current_hero_queue:
        if not hero_lives.has(hero_id):
            hero_lives[hero_id] = HERO_LIVES

func get_hero_lives(hero_id: String) -> int:
    _ensure_hero_lives_initialized()

    if hero_id == "":
        return 0

    if hero_lives.has(hero_id):
        return hero_lives[hero_id]

    return 0

func _decrement_hero_life(hero_id: String) -> int:
    if hero_id == "":
        return 0

    if not hero_lives.has(hero_id):
        hero_lives[hero_id] = HERO_LIVES

    hero_lives[hero_id] -= 1
    return hero_lives[hero_id]
