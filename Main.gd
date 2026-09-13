extends Control

const BACKGROUND := Color("0b1020")
const PANEL := Color("171f3b")
const PANEL_LIGHT := Color("222d52")
const TEXT := Color("f3f6ff")
const MUTED := Color("aab9df")
const ACCENT := Color("4fe0ca")
const GOLD := Color("ffd36b")
const DANGER := Color("ff7892")
const VIOLET := Color("8e7dff")
const WEAPON_RECIPES := {
	"common": {"title": "Обычное оружие", "level": 1, "coins": 40, "fangs": 4, "crystals": 0},
	"rare": {"title": "Редкое оружие", "level": 4, "coins": 120, "fangs": 8, "crystals": 3},
	"epic": {"title": "Эпическое оружие", "level": 8, "coins": 320, "fangs": 14, "crystals": 8}
}

var coins := 0
var click_power := 1
var passive_income := 0
var monster_level := 1
var monster_health := 0
var monster_max_health := 0
var click_upgrade_cost := 15
var passive_upgrade_cost := 25
var critical_chance := 0.0
var critical_multiplier := 2
var critical_upgrade_cost := 40
var player_level := 1
var player_experience := 0
var experience_to_next_level := 30
var skill_points := 1
var berserker_rank := 0
var fortune_rank := 0
var totem_rank := 0
var precision_rank := 0
var rage_cooldown := 0
var fangs := 0
var crystals := 0
var equipped_weapon := ""
var monster_frame_index := 0
var monster_frames: Array[Texture2D] = []
var tab_pages: Dictionary = {}
var tab_buttons: Dictionary = {}

var balance_label: Label
var passive_summary_label: Label
var player_level_label: Label
var build_label: Label
var experience_bar: ProgressBar
var monster_title: Label
var monster_health_label: Label
var monster_health_bar: ProgressBar
var monster_button: Button
var monster_sprite: TextureRect
var damage_layer: Control
var status_label: Label
var click_upgrade_button: Button
var passive_upgrade_button: Button
var critical_upgrade_button: Button
var berserker_button: Button
var fortune_button: Button
var totem_button: Button
var precision_button: Button
var rage_button: Button
var ingredients_label: Label
var weapon_label: Label
var common_forge_button: Button
var rare_forge_button: Button
var epic_forge_button: Button

func _ready() -> void:
	build_start_screen()

func build_start_screen() -> void:
	clear_screen()
	var page := make_page()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 0)
	card.add_theme_stylebox_override("panel", panel_style(PANEL, 28))
	center.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	set_box_margins(content, 42)
	card.add_child(content)
	var eyebrow := make_label("ПИКСЕЛЬНОЕ ПРИКЛЮЧЕНИЕ", 15, ACCENT)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)
	var title := make_label("MONSTER CLICKER", 44, TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var intro := make_label("Охотьтесь, крафтите оружие и собирайте свой билд.", 18, MUTED)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(intro)
	var start := make_button("Начать охоту", 21, ACCENT)
	start.custom_minimum_size = Vector2(0, 64)
	start.pressed.connect(start_game)
	content.add_child(start)

func start_game() -> void:
	coins = 0; click_power = 1; passive_income = 0; monster_level = 1
	click_upgrade_cost = 15; passive_upgrade_cost = 25; critical_chance = 0.0; critical_upgrade_cost = 40
	player_level = 1; player_experience = 0; experience_to_next_level = 30; skill_points = 1
	berserker_rank = 0; fortune_rank = 0; totem_rank = 0; precision_rank = 0; rage_cooldown = 0
	fangs = 0; crystals = 0; equipped_weapon = ""
	spawn_monster()
	build_game_screen()

func build_game_screen() -> void:
	clear_screen()
	var page := make_page()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	page.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)
	title_stack.add_child(make_label("MONSTER CLICKER", 25, TEXT))
	build_label = make_label("", 13, MUTED)
	title_stack.add_child(build_label)
	var coin_card := PanelContainer.new()
	coin_card.add_theme_stylebox_override("panel", panel_style(Color("293452"), 14))
	header.add_child(coin_card)
	balance_label = make_label("", 21, GOLD)
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_card.add_child(balance_label)
	var player_row := HBoxContainer.new()
	player_row.add_theme_constant_override("separation", 12)
	layout.add_child(player_row)
	player_level_label = make_label("", 14, ACCENT)
	player_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_row.add_child(player_level_label)
	passive_summary_label = make_label("", 14, MUTED)
	passive_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	player_row.add_child(passive_summary_label)
	experience_bar = make_progress_bar(12, ACCENT)
	layout.add_child(experience_bar)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 10)
	layout.add_child(navigation)
	add_tab_button(navigation, "hunt", "⚔  Охота")
	add_tab_button(navigation, "forge", "⚒  Кузница")
	add_tab_button(navigation, "talents", "✦  Таланты")
	var content_frame := PanelContainer.new()
	content_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_frame.add_theme_stylebox_override("panel", panel_style(Color("111a32"), 22))
	layout.add_child(content_frame)
	var content_host := Control.new()
	content_host.custom_minimum_size = Vector2(0, 490)
	content_frame.add_child(content_host)
	build_hunt_page(content_host)
	build_forge_page(content_host)
	build_talents_page(content_host)
	status_label = make_label("", 14, ACCENT)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(status_label)
	var passive_timer := Timer.new()
	passive_timer.wait_time = 1.0
	passive_timer.timeout.connect(on_passive_tick)
	add_child(passive_timer)
	passive_timer.start()
	load_monster_frames()
	var animation_timer := Timer.new()
	animation_timer.wait_time = 0.16
	animation_timer.timeout.connect(advance_monster_frame)
	add_child(animation_timer)
	animation_timer.start()
	switch_tab("hunt")
	update_game_ui()

func build_hunt_page(host: Control) -> void:
	var page := make_tab_page(host, "hunt")
	var content := HBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 16)
	page.add_child(content)
	var arena_card := PanelContainer.new()
	arena_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena_card.size_flags_stretch_ratio = 1.35
	arena_card.add_theme_stylebox_override("panel", panel_style(PANEL, 18))
	content.add_child(arena_card)
	var arena_box := VBoxContainer.new()
	arena_box.add_theme_constant_override("separation", 9)
	set_box_margins(arena_box, 18)
	arena_card.add_child(arena_box)
	monster_title = make_label("", 22, TEXT)
	monster_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arena_box.add_child(monster_title)
	monster_health_label = make_label("", 15, MUTED)
	monster_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arena_box.add_child(monster_health_label)
	monster_health_bar = make_progress_bar(18, DANGER)
	arena_box.add_child(monster_health_bar)
	monster_button = Button.new()
	monster_button.custom_minimum_size = Vector2(0, 290)
	monster_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	monster_button.tooltip_text = "Нажмите на монстра, чтобы атаковать"
	monster_button.add_theme_stylebox_override("normal", panel_style(Color("101934"), 16))
	monster_button.add_theme_stylebox_override("hover", panel_style(Color("17244a"), 16))
	monster_button.add_theme_stylebox_override("pressed", panel_style(Color("263561"), 16))
	monster_button.pressed.connect(attack_monster)
	arena_box.add_child(monster_button)
	monster_sprite = TextureRect.new()
	monster_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	monster_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monster_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monster_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	monster_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	monster_button.add_child(monster_sprite)
	damage_layer = Control.new()
	damage_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	monster_button.add_child(damage_layer)
	var tap_hint := make_label("Нажмите на монстра, чтобы атаковать", 14, ACCENT)
	tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arena_box.add_child(tap_hint)
	var upgrades_card := PanelContainer.new()
	upgrades_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_card.add_theme_stylebox_override("panel", panel_style(PANEL, 18))
	content.add_child(upgrades_card)
	var upgrades := VBoxContainer.new()
	upgrades.add_theme_constant_override("separation", 12)
	set_box_margins(upgrades, 18)
	upgrades_card.add_child(upgrades)
	upgrades.add_child(make_label("Лагерь охотника", 21, TEXT))
	var hint := make_label("Усиливайте героя и добывайте ингредиенты в бою.", 14, MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrades.add_child(hint)
	click_upgrade_button = make_upgrade_button(); click_upgrade_button.pressed.connect(buy_click_upgrade); upgrades.add_child(click_upgrade_button)
	passive_upgrade_button = make_upgrade_button(); passive_upgrade_button.pressed.connect(buy_passive_upgrade); upgrades.add_child(passive_upgrade_button)
	critical_upgrade_button = make_upgrade_button(); critical_upgrade_button.pressed.connect(buy_critical_upgrade); upgrades.add_child(critical_upgrade_button)
	var boss_hint := make_label("Каждый 10-й монстр — босс: он выносливее, но щедрее на добычу.", 14, GOLD)
	boss_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrades.add_child(boss_hint)

func build_forge_page(host: Control) -> void:
	var page := make_tab_page(host, "forge")
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 16)
	page.add_child(box)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(titles)
	titles.add_child(make_label("Кузница охотника", 24, TEXT))
	titles.add_child(make_label("Оружие растёт вместе с уровнем героя.", 14, MUTED))
	var material_card := PanelContainer.new()
	material_card.add_theme_stylebox_override("panel", panel_style(Color("26314f"), 14))
	heading.add_child(material_card)
	ingredients_label = make_label("", 15, GOLD)
	ingredients_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	material_card.add_child(ingredients_label)
	var weapon_card := PanelContainer.new()
	weapon_card.add_theme_stylebox_override("panel", panel_style(Color("202b4c"), 16))
	box.add_child(weapon_card)
	weapon_label = make_label("", 16, ACCENT)
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_card.add_child(weapon_label)
	var recipes := HBoxContainer.new()
	recipes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	recipes.add_theme_constant_override("separation", 12)
	box.add_child(recipes)
	common_forge_button = make_forge_button(Color("45536e")); common_forge_button.pressed.connect(forge_weapon.bind("common")); recipes.add_child(common_forge_button)
	rare_forge_button = make_forge_button(VIOLET); rare_forge_button.pressed.connect(forge_weapon.bind("rare")); recipes.add_child(rare_forge_button)
	epic_forge_button = make_forge_button(Color("b45fff")); epic_forge_button.pressed.connect(forge_weapon.bind("epic")); recipes.add_child(epic_forge_button)
	var note := make_label("Клыки и осколки выпадают из монстров. Боссы приносят больше материалов.", 14, MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)

func build_talents_page(host: Control) -> void:
	var page := make_tab_page(host, "talents")
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 14)
	page.add_child(box)
	box.add_child(make_label("Путь героя", 24, TEXT))
	box.add_child(make_label("За каждый уровень вы получаете очко таланта. Соберите собственный билд.", 14, MUTED))
	var talents := GridContainer.new()
	talents.columns = 2
	talents.size_flags_vertical = Control.SIZE_EXPAND_FILL
	talents.add_theme_constant_override("h_separation", 12)
	talents.add_theme_constant_override("v_separation", 12)
	box.add_child(talents)
	berserker_button = make_talent_button(Color("643d65")); berserker_button.pressed.connect(buy_talent.bind("berserker")); talents.add_child(berserker_button)
	fortune_button = make_talent_button(Color("6b5733")); fortune_button.pressed.connect(buy_talent.bind("fortune")); talents.add_child(fortune_button)
	totem_button = make_talent_button(Color("245d67")); totem_button.pressed.connect(buy_talent.bind("totem")); talents.add_child(totem_button)
	precision_button = make_talent_button(Color("3b4d7e")); precision_button.pressed.connect(buy_talent.bind("precision")); talents.add_child(precision_button)
	rage_button = make_button("", 17, Color("5a386f"))
	rage_button.custom_minimum_size = Vector2(0, 64)
	rage_button.pressed.connect(use_rage)
	box.add_child(rage_button)

func make_tab_page(host: Control, tab_id: String) -> Control:
	var page := Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.offset_left = 18; page.offset_right = -18; page.offset_top = 18; page.offset_bottom = -18
	host.add_child(page)
	tab_pages[tab_id] = page
	return page

func add_tab_button(parent: Container, tab_id: String, title: String) -> void:
	var button := make_button(title, 16, PANEL_LIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 46)
	button.pressed.connect(switch_tab.bind(tab_id))
	parent.add_child(button)
	tab_buttons[tab_id] = button

func switch_tab(tab_id: String) -> void:
	for key in tab_pages:
		tab_pages[key].visible = key == tab_id
	for key in tab_buttons:
		var button: Button = tab_buttons[key]
		var color: Color = ACCENT if key == tab_id else PANEL_LIGHT
		button.add_theme_stylebox_override("normal", panel_style(color, 14))
		button.add_theme_stylebox_override("hover", panel_style(color.lightened(0.10), 14))

func load_monster_frames() -> void:
	monster_frames.clear()
	for index in range(8):
		var texture := load("res://assets/monsters/beast_idle_%02d.png" % index) as Texture2D
		if texture != null: monster_frames.append(texture)
	advance_monster_frame()

func advance_monster_frame() -> void:
	if monster_sprite == null or monster_frames.is_empty(): return
	monster_sprite.texture = monster_frames[monster_frame_index]
	monster_frame_index = (monster_frame_index + 1) % monster_frames.size()

func attack_monster() -> void:
	var critical := randf() < total_critical_chance()
	var damage := manual_damage() * (critical_multiplier if critical else 1)
	show_damage_popup(damage, critical)
	flash_monster(critical)
	monster_health = max(monster_health - damage, 0)
	if monster_health <= 0:
		var reward := monster_reward()
		coins += reward
		gain_experience(monster_level * 3)
		var loot_text := roll_ingredients()
		monster_level += 1
		spawn_monster()
		status_label.text = "+%d монет. %s" % [reward, loot_text]
	else:
		status_label.text = ("КРИТИЧЕСКИЙ УДАР на %d!" if critical else "Удар на %d урона.") % damage
	update_game_ui()

func show_damage_popup(damage: int, critical: bool) -> void:
	if damage_layer == null: return
	var popup := make_label(("КРИТ ×%d\n%d" % [critical_multiplier, damage]) if critical else "-%d" % damage, 24 if critical else 20, GOLD if critical else TEXT)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(130 + randi_range(-42, 42), 105 + randi_range(-24, 30))
	popup.custom_minimum_size = Vector2(120, 48)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_layer.add_child(popup)
	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 76.0, 0.58)
	tween.tween_property(popup, "modulate:a", 0.0, 0.48).set_delay(0.10)
	tween.chain().tween_callback(popup.queue_free)

func flash_monster(critical: bool) -> void:
	if monster_sprite == null: return
	monster_sprite.modulate = GOLD if critical else Color("ffcad6")
	monster_sprite.create_tween().tween_property(monster_sprite, "modulate", Color.WHITE, 0.16)

func on_passive_tick() -> void:
	if rage_cooldown > 0: rage_cooldown -= 1
	var income := effective_passive_income()
	if income > 0:
		coins += income
		status_label.text = "+%d монет пассивного дохода." % income
	update_game_ui()

func buy_click_upgrade() -> void:
	if coins < click_upgrade_cost:
		status_label.text = "Недостаточно монет для силы удара."; return
	coins -= click_upgrade_cost; click_power += 1
	click_upgrade_cost = int(ceil(float(click_upgrade_cost) * 1.6))
	status_label.text = "Сила удара увеличена до %d." % click_power
	update_game_ui()

func buy_passive_upgrade() -> void:
	if coins < passive_upgrade_cost:
		status_label.text = "Недостаточно монет для пассивного дохода."; return
	coins -= passive_upgrade_cost; passive_income += 1
	passive_upgrade_cost = int(ceil(float(passive_upgrade_cost) * 1.7))
	status_label.text = "Пассивный доход увеличен до %d/с." % passive_income
	update_game_ui()

func buy_critical_upgrade() -> void:
	if coins < critical_upgrade_cost:
		status_label.text = "Недостаточно монет для критического удара."; return
	coins -= critical_upgrade_cost; critical_chance = min(critical_chance + 0.05, 0.50)
	critical_upgrade_cost = int(ceil(float(critical_upgrade_cost) * 1.85))
	status_label.text = "Шанс критического удара: %d%%." % int(critical_chance * 100.0)
	update_game_ui()

func buy_talent(talent: String) -> void:
	if skill_points <= 0:
		status_label.text = "Нужно новое очко таланта: получите уровень игрока."; return
	if talent_rank(talent) >= 5:
		status_label.text = "Этот талант уже развит до максимума."; return
	skill_points -= 1
	match talent:
		"berserker": berserker_rank += 1
		"fortune": fortune_rank += 1
		"totem": totem_rank += 1
		"precision": precision_rank += 1
	status_label.text = "Талант улучшен: " + talent_title(talent) + "."
	update_game_ui()

func forge_weapon(rarity: String) -> void:
	var recipe: Dictionary = WEAPON_RECIPES[rarity]
	if player_level < recipe["level"]:
		status_label.text = "Кузнице нужен уровень игрока %d." % recipe["level"]; return
	if weapon_rank(rarity) <= weapon_rank(equipped_weapon):
		status_label.text = "Уже экипировано оружие не ниже этой редкости."; return
	if coins < recipe["coins"] or fangs < recipe["fangs"] or crystals < recipe["crystals"]:
		status_label.text = "Не хватает монет или ингредиентов для ковки."; return
	coins -= recipe["coins"]; fangs -= recipe["fangs"]; crystals -= recipe["crystals"]
	equipped_weapon = rarity
	status_label.text = "Выковано: %s! Урон оружия растёт с уровнем героя." % recipe["title"]
	update_game_ui()

func use_rage() -> void:
	if berserker_rank < 3:
		status_label.text = "Ярость откроется на 3 ранге Когтей берсерка."; return
	if rage_cooldown > 0: return
	var damage := manual_damage() * 8
	show_damage_popup(damage, true); flash_monster(true)
	monster_health = max(monster_health - damage, 0); rage_cooldown = 15
	if monster_health <= 0:
		var reward := monster_reward()
		coins += reward; gain_experience(monster_level * 3)
		var loot_text := roll_ingredients()
		monster_level += 1; spawn_monster()
		status_label.text = "ЯРОСТЬ уничтожила цель! +%d монет. %s" % [reward, loot_text]
	else: status_label.text = "ЯРОСТЬ нанесла %d урона." % damage
	update_game_ui()

func spawn_monster() -> void:
	monster_max_health = 18 + monster_level * 12 + monster_level * monster_level * 4
	if is_boss(): monster_max_health *= 3
	monster_health = monster_max_health

func monster_reward() -> int:
	var reward := int(round(float(6 + monster_level * 5) * (1.0 + 0.18 * fortune_rank)))
	return reward * 4 if is_boss() else reward

func roll_ingredients() -> String:
	var gained_fangs := 0
	var gained_crystals := 0
	if randf() < (0.95 if is_boss() else 0.62):
		gained_fangs = randi_range(1, 2) + (1 if is_boss() else 0); fangs += gained_fangs
	if randf() < (0.70 if is_boss() else 0.28):
		gained_crystals = 1 + (1 if is_boss() else 0); crystals += gained_crystals
	if gained_fangs == 0 and gained_crystals == 0: return "Ингредиенты не выпали."
	var parts: Array[String] = []
	if gained_fangs > 0: parts.append("+%d клыка" % gained_fangs)
	if gained_crystals > 0: parts.append("+%d осколка" % gained_crystals)
	return "Добыча: " + ", ".join(parts)

func is_boss() -> bool: return monster_level % 10 == 0

func gain_experience(amount: int) -> void:
	player_experience += amount
	while player_experience >= experience_to_next_level:
		player_experience -= experience_to_next_level
		player_level += 1
		experience_to_next_level = int(ceil(float(experience_to_next_level) * 1.45))
		skill_points += 1
		status_label.text = "Уровень игрока повышен до %d! +1 очко таланта." % player_level

func manual_damage() -> int: return int(round(float(click_power + weapon_damage()) * (1.0 + 0.22 * berserker_rank)))
func weapon_damage() -> int:
	match equipped_weapon:
		"common": return 3 + player_level * 2
		"rare": return 10 + player_level * 4
		"epic": return 26 + player_level * 7
	return 0
func weapon_rank(rarity: String) -> int:
	match rarity:
		"common": return 1
		"rare": return 2
		"epic": return 3
	return 0
func weapon_title() -> String: return "Оружие не экипировано" if equipped_weapon.is_empty() else WEAPON_RECIPES[equipped_weapon]["title"]
func effective_passive_income() -> int: return int(round(float(passive_income) * (1.0 + 0.25 * totem_rank)))
func total_critical_chance() -> float: return min(critical_chance + 0.03 * precision_rank, 0.75)
func talent_rank(talent: String) -> int:
	match talent:
		"berserker": return berserker_rank
		"fortune": return fortune_rank
		"totem": return totem_rank
		"precision": return precision_rank
	return 0
func talent_title(talent: String) -> String:
	match talent:
		"berserker": return "Когти берсерка"
		"fortune": return "Золотой след"
		"totem": return "Тотем добычи"
		"precision": return "Точный удар"
	return "Талант"
func build_name() -> String:
	var highest: int = max(max(berserker_rank, fortune_rank), max(totem_rank, precision_rank))
	if highest == 0: return "Свободный охотник"
	if berserker_rank == highest: return "Берсерк"
	if fortune_rank == highest: return "Золотой охотник"
	if totem_rank == highest: return "Шаман добычи"
	return "Точный хищник"

func update_game_ui() -> void:
	if balance_label == null: return
	balance_label.text = "◈ %d" % coins
	passive_summary_label.text = "Доход %d/с · Удар %d · Крит %d%%" % [effective_passive_income(), manual_damage(), int(total_critical_chance() * 100.0)]
	player_level_label.text = "Ур. %d · опыт %d / %d · талантов: %d" % [player_level, player_experience, experience_to_next_level, skill_points]
	build_label.text = "Билд: " + build_name()
	experience_bar.max_value = experience_to_next_level; experience_bar.value = player_experience
	monster_title.text = ("БОСС · древний монстрик" if is_boss() else "Лесной монстрик") + " · ур. %d" % monster_level
	monster_health_label.text = "Здоровье  %d / %d" % [monster_health, monster_max_health]
	monster_health_bar.max_value = monster_max_health; monster_health_bar.value = monster_health
	monster_button.tooltip_text = "Атаковать · урон %d" % manual_damage()
	click_upgrade_button.text = "⚔  Сила удара  +1\n%d монет" % click_upgrade_cost
	passive_upgrade_button.text = "◌  Пассивный доход  +1/с\n%d монет" % passive_upgrade_cost
	critical_upgrade_button.text = "✦  Критический удар  +5%%\n×%d урон · %d монет" % [critical_multiplier, critical_upgrade_cost]
	ingredients_label.text = "Клыки  %d   ·   Осколки  %d" % [fangs, crystals]
	weapon_label.text = "Экипировано: %s  ·  бонус урона: +%d" % [weapon_title(), weapon_damage()]
	common_forge_button.text = forge_button_text("common"); rare_forge_button.text = forge_button_text("rare"); epic_forge_button.text = forge_button_text("epic")
	berserker_button.text = "Когти берсерка  %d/5\n+22%% к урону кликов" % berserker_rank
	fortune_button.text = "Золотой след  %d/5\n+18%% к награде" % fortune_rank
	totem_button.text = "Тотем добычи  %d/5\n+25%% к пассивному доходу" % totem_rank
	precision_button.text = "Точный удар  %d/5\n+3%% к шансу крита" % precision_rank
	rage_button.text = ("Ярость берсерка · ×8 урона" if berserker_rank >= 3 else "Ярость берсерка — закрыто · нужно 3/5 Когтей") + (" · %d с" % rage_cooldown if rage_cooldown > 0 else "")
	click_upgrade_button.disabled = coins < click_upgrade_cost; passive_upgrade_button.disabled = coins < passive_upgrade_cost; critical_upgrade_button.disabled = coins < critical_upgrade_cost
	berserker_button.disabled = skill_points <= 0 or berserker_rank >= 5; fortune_button.disabled = skill_points <= 0 or fortune_rank >= 5
	totem_button.disabled = skill_points <= 0 or totem_rank >= 5; precision_button.disabled = skill_points <= 0 or precision_rank >= 5
	rage_button.disabled = berserker_rank < 3 or rage_cooldown > 0
	common_forge_button.disabled = not can_forge("common"); rare_forge_button.disabled = not can_forge("rare"); epic_forge_button.disabled = not can_forge("epic")

func forge_button_text(rarity: String) -> String:
	var recipe: Dictionary = WEAPON_RECIPES[rarity]
	return "%s\nуровень %d+\n%d ◈ · %d клыков · %d осколков" % [recipe["title"], recipe["level"], recipe["coins"], recipe["fangs"], recipe["crystals"]]
func can_forge(rarity: String) -> bool:
	var recipe: Dictionary = WEAPON_RECIPES[rarity]
	return player_level >= recipe["level"] and coins >= recipe["coins"] and fangs >= recipe["fangs"] and crystals >= recipe["crystals"] and weapon_rank(rarity) > weapon_rank(equipped_weapon)

func clear_screen() -> void:
	for child in get_children(): child.queue_free()
	tab_pages.clear(); tab_buttons.clear()
func make_page() -> ColorRect:
	var page := ColorRect.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.color = BACKGROUND
	add_child(page)
	return page
func make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value; label.add_theme_font_size_override("font_size", font_size); label.add_theme_color_override("font_color", color)
	return label
func make_button(value: String, font_size: int, color: Color) -> Button:
	var button := Button.new()
	button.text = value; button.add_theme_font_size_override("font_size", font_size); button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", panel_style(color, 14)); button.add_theme_stylebox_override("hover", panel_style(color.lightened(0.10), 14))
	button.add_theme_stylebox_override("pressed", panel_style(color.darkened(0.10), 14)); button.add_theme_stylebox_override("disabled", panel_style(Color("303854"), 14))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return button
func make_upgrade_button() -> Button:
	var button := make_button("", 17, PANEL_LIGHT); button.custom_minimum_size = Vector2(0, 82); button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button
func make_forge_button(color: Color) -> Button:
	var button := make_button("", 16, color); button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.custom_minimum_size = Vector2(0, 180)
	return button
func make_talent_button(color: Color) -> Button:
	var button := make_button("", 16, color); button.custom_minimum_size = Vector2(0, 104); button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button
func make_progress_bar(height: int, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, height); bar.show_percentage = false
	bar.add_theme_stylebox_override("background", panel_style(Color("0d1429"), height / 2)); bar.add_theme_stylebox_override("fill", panel_style(color, height / 2))
	return bar
func panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius; style.corner_radius_top_right = radius; style.corner_radius_bottom_left = radius; style.corner_radius_bottom_right = radius
	style.border_width_left = 1; style.border_width_right = 1; style.border_width_top = 1; style.border_width_bottom = 1; style.border_color = color.lightened(0.16)
	style.content_margin_left = 16; style.content_margin_right = 16; style.content_margin_top = 12; style.content_margin_bottom = 12
	return style
func set_box_margins(box: BoxContainer, margin: int) -> void:
	box.add_theme_constant_override("margin_left", margin); box.add_theme_constant_override("margin_right", margin)
	box.add_theme_constant_override("margin_top", margin); box.add_theme_constant_override("margin_bottom", margin)
