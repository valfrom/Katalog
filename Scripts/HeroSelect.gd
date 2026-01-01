extends Node2D

@onready var gallery: Node2D = $Gallery
@onready var camera: Camera2D = $Camera2D
@onready var cursor_frame: Node2D = $Gallery/CursorFrame
@onready var cursor_panel: Panel = $Gallery/CursorFrame/Frame
@onready var info_label: Label = $UI/Panel/Info

var portrait_entries: Array = []
var portrait_size: Vector2 = Vector2.ZERO
var selected_index := 0
var move_tween: Tween = null
const CURSOR_MOVE_TIME := 0.2

func _ready() -> void:
    _build_gallery()
    _update_selection()

func _build_gallery() -> void:
    for child in gallery.get_children():
        if child != cursor_frame:
            child.queue_free()
    portrait_entries.clear()

    var viewport_height := get_viewport_rect().size.y
    portrait_size.y = viewport_height * 0.8
    portrait_size.x = portrait_size.y * 0.75
    var spacing := portrait_size.x * 0.4

    var x_offset := 0.0
    for hero in GameManager.HERO_ROSTER:
        var unlocked := GameManager.unlocked_heroes.has(hero["id"])

        var card := Node2D.new()
        card.position = Vector2(x_offset, 0)

        var portrait := ColorRect.new()
        portrait.size = portrait_size
        portrait.position = -portrait_size / 2.0
        portrait.color = hero.get("color", Color.WHITE) if unlocked else Color(0.2, 0.2, 0.2)
        portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(portrait)

        var name_label := Label.new()
        name_label.text = hero.get("name", "Hero") if unlocked else "?"
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        name_label.size = Vector2(portrait_size.x, 40)
        name_label.position = Vector2(-portrait_size.x / 2.0, portrait_size.y / 2.0 + 16.0)
        name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(name_label)

        gallery.add_child(card)
        portrait_entries.append({
            "hero_id": hero["id"],
            "node": card,
            "unlocked": unlocked
        })

        x_offset += portrait_size.x + spacing

    cursor_panel.size = portrait_size + Vector2(32.0, 32.0)
    if info_label:
        info_label.text = "Unlocked: %d / %d" % [GameManager.unlocked_heroes.size(), GameManager.HERO_ROSTER.size()]

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_left"):
        _move_selection(-1)
    elif event.is_action_pressed("ui_right"):
        _move_selection(1)
    elif event.is_action_pressed("ui_accept"):
        _select_current_hero()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _try_select_with_pointer(get_global_mouse_position())

func _move_selection(direction: int) -> void:
    if portrait_entries.is_empty():
        return
    selected_index = clamp(selected_index + direction, 0, portrait_entries.size() - 1)
    _update_selection()

func _try_select_with_pointer(world_position: Vector2) -> void:
    for i in portrait_entries.size():
        var entry: Dictionary = portrait_entries[i]
        var rect := Rect2(entry["node"].global_position - portrait_size / 2.0, portrait_size)
        if rect.has_point(world_position):
            selected_index = i
            _update_selection()
            _select_current_hero()
            return

func _update_selection() -> void:
    if portrait_entries.is_empty():
        return

    selected_index = clamp(selected_index, 0, portrait_entries.size() - 1)
    var entry: Dictionary = portrait_entries[selected_index]
    var target_position: Vector2 = entry["node"].global_position

    if move_tween:
        move_tween.kill()
    move_tween = create_tween()
    move_tween.tween_property(cursor_frame, "position", target_position, CURSOR_MOVE_TIME)
    move_tween.parallel().tween_property(cursor_panel, "position", -cursor_panel.size / 2.0, CURSOR_MOVE_TIME)
    move_tween.set_trans(Tween.TRANS_CUBIC)
    move_tween.set_ease(Tween.EASE_OUT)

    camera.position = target_position

func _select_current_hero() -> void:
    if portrait_entries.is_empty():
        return

    var entry: Dictionary = portrait_entries[selected_index]
    if !entry.get("unlocked", false):
        return

    _select_hero(entry["hero_id"])

func _select_hero(hero_id: String) -> void:
    GameManager.prepare_hero_run(hero_id)
    var target_scene := GameManager.pending_level_scene
    if target_scene == "":
        target_scene = GameManager.saved_scene_path
    if target_scene == "":
        return
    SceneTransition.load_scene(target_scene)
