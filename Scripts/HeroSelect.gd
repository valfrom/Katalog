extends Control

@onready var hero_list: VBoxContainer = %HeroList
@onready var info_label: Label = %Info

func _ready() -> void:
    _build_hero_buttons()

func _build_hero_buttons() -> void:
    for child in hero_list.get_children():
        child.queue_free()

    var viewport_height := get_viewport_rect().size.y
    var portrait_height := viewport_height * 0.8

    for hero in GameManager.HERO_ROSTER:
        var unlocked := GameManager.unlocked_heroes.has(hero["id"])
        var card := Button.new()
        card.toggle_mode = true
        card.text = ""
        card.disabled = !unlocked
        card.focus_mode = Control.FOCUS_ALL
        card.custom_minimum_size = Vector2(0, portrait_height)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

        var layout := VBoxContainer.new()
        layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
        layout.custom_minimum_size = Vector2(0, portrait_height)
        layout.alignment = BoxContainer.ALIGNMENT_CENTER

        var portrait := ColorRect.new()
        portrait.color = hero.get("color", Color.WHITE) if unlocked else Color(0.2, 0.2, 0.2)
        portrait.custom_minimum_size = Vector2(0, portrait_height)
        portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        portrait.size_flags_vertical = Control.SIZE_FILL
        portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
        layout.add_child(portrait)

        var name_label := Label.new()
        name_label.text = hero.get("name", "Hero") if unlocked else "?"
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        layout.add_child(name_label)

        card.add_child(layout)
        card.pressed.connect(func():
            _select_hero(hero["id"])
        )
        hero_list.add_child(card)

    if info_label:
        info_label.text = "Unlocked: %d / %d" % [GameManager.unlocked_heroes.size(), GameManager.HERO_ROSTER.size()]

func _select_hero(hero_id: String) -> void:
    GameManager.prepare_hero_run(hero_id)
    var target_scene := GameManager.pending_level_scene
    if target_scene == "":
        target_scene = GameManager.saved_scene_path
    if target_scene == "":
        return
    SceneTransition.load_scene(target_scene)
