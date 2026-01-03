extends Control

@onready var score_texture = %ScoreTexture
@onready var score_label = %ScoreLabel
@onready var current_hero_icon = %CurrentHeroIcon
@onready var hero_lives_label = %HeroLivesLabel
@onready var available_heroes_icons = %AvailableHeroesIcons

func _ready():
    _update_hero_display()

func _process(_delta):
    score_label.text = "x %d" % GameManager.score
    _update_hero_display()

func _update_hero_display() -> void:
    var hero_definition := GameManager.get_hero_definition(GameManager.current_hero_id)
    var hero_name := "None"
    if not hero_definition.is_empty():
        hero_name = hero_definition.get("name", GameManager.current_hero_id.capitalize())

    var hero_portrait := _get_hero_portrait(GameManager.current_hero_id, hero_definition)
    if current_hero_icon != null:
        current_hero_icon.texture = hero_portrait if hero_portrait != null else score_texture.texture
        current_hero_icon.tooltip_text = hero_name

    _populate_available_hero_icons()

    var lives := GameManager.get_hero_lives(GameManager.current_hero_id)
    hero_lives_label.text = "x %d" % lives

func _populate_available_hero_icons() -> void:
    if available_heroes_icons == null:
        return

    for child in available_heroes_icons.get_children():
        child.queue_free()

    if GameManager.unlocked_heroes.is_empty():
        var none_label := Label.new()
        none_label.text = "None"
        available_heroes_icons.add_child(none_label)
        return

    for hero_id in GameManager.unlocked_heroes:
        var hero_definition := GameManager.get_hero_definition(hero_id)
        var hero_name := hero_id.capitalize()
        if not hero_definition.is_empty():
            hero_name = hero_definition.get("name", hero_name)

        var hero_portrait := _get_hero_portrait(hero_id, hero_definition)
        var portrait_rect := TextureRect.new()
        portrait_rect.custom_minimum_size = Vector2(32, 32)
        portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        portrait_rect.tooltip_text = hero_name

        if hero_portrait != null:
            portrait_rect.texture = hero_portrait
        else:
            portrait_rect.texture = score_texture.texture

        available_heroes_icons.add_child(portrait_rect)

func _get_hero_portrait(hero_id: String, hero_definition: Dictionary = {}) -> Texture2D:
    if hero_definition.is_empty():
        hero_definition = GameManager.get_hero_definition(hero_id)
    if hero_definition.is_empty():
        return null

    var portrait_path: String = hero_definition.get("portrait_path", "")
    if portrait_path == "":
        return null

    var portrait = load(portrait_path)
    if portrait is Texture2D:
        return portrait

    return null
