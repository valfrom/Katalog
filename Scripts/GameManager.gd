# This script is an autoload, that can be accessed from any other script!

extends Node2D

const HERO_SELECT_SCENE_PATH := "res://Scenes/Managers/HeroSelect.tscn"

var score: int = 0
var saved_scene_path: String = ""
var saved_player_position: Vector2 = Vector2.ZERO
var restore_player_position: bool = false

var pending_level_path: String = ""
var current_level_path: String = ""
var unlocked_heroes: Array[int] = [0]
var current_run_queue: Array[int] = []
var current_hero_position: int = 0

const HEROES := [
    {
        "name": "Rookie",
        "color": Color("c4f1be"),
        "portrait": preload("res://Assets/Sprites/black_cat.png"),
    },
    {
        "name": "Blazer",
        "color": Color("f9c74f"),
        "portrait": preload("res://Assets/Sprites/black_cat.png"),
    },
    {
        "name": "Phantom",
        "color": Color("bde0fe"),
        "portrait": preload("res://Assets/Sprites/black_cat.png"),
    },
    {
        "name": "Nova",
        "color": Color("ffafcc"),
        "portrait": preload("res://Assets/Sprites/black_cat.png"),
    },
    {
        "name": "Titan",
        "color": Color("90e0ef"),
        "portrait": preload("res://Assets/Sprites/black_cat.png"),
    },
]

# Adds 1 to score variable
func add_score():
    score += 1

func get_heroes() -> Array:
    return HEROES

func is_hero_unlocked(index: int) -> bool:
    return unlocked_heroes.has(index)

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

func set_pending_level(path: String) -> void:
    pending_level_path = path
    current_level_path = ""
    reset_run_state()

func prepare_run(selected_index: int) -> void:
    if !is_hero_unlocked(selected_index):
        selected_index = unlocked_heroes[0]
    current_run_queue.clear()
    current_run_queue.append(selected_index)
    for index in unlocked_heroes:
        if index != selected_index:
            current_run_queue.append(index)
    current_hero_position = 0
    current_level_path = pending_level_path

func ensure_run_initialized(level_path: String) -> void:
    if current_run_queue.is_empty():
        prepare_run(unlocked_heroes[0])
    current_level_path = level_path

func get_current_hero() -> Dictionary:
    if current_run_queue.is_empty():
        return HEROES[0]
    return HEROES[current_run_queue[current_hero_position]]

func advance_to_next_hero() -> bool:
    current_hero_position += 1
    return current_hero_position < current_run_queue.size()

func heroes_remaining_after_current() -> int:
    return max(current_run_queue.size() - current_hero_position - 1, 0)

func reset_run_state() -> void:
    current_run_queue.clear()
    current_hero_position = 0
    current_level_path = ""

func apply_current_hero(player) -> void:
    if player == null:
        return
    player.apply_hero_visual(get_current_hero())

func handle_player_death(player) -> void:
    await player.death_tween()
    if advance_to_next_hero():
        player.respawn_with_hero(get_current_hero())
        return
    reset_run_state()
    pending_level_path = ""
    current_level_path = ""
    if saved_scene_path == "":
        player.respawn_with_hero(get_current_hero())
        return
    mark_restore_player_position()
    SceneTransition.load_scene(saved_scene_path)

func handle_level_completed() -> void:
    _unlock_random_hero()
    reset_run_state()
    pending_level_path = ""
    current_level_path = ""

func _unlock_random_hero() -> void:
    var locked := []
    for i in HEROES.size():
        if !is_hero_unlocked(i):
            locked.append(i)
    if locked.is_empty():
        return
    var random_index: int = locked[randi() % locked.size()]
    unlocked_heroes.append(random_index)
