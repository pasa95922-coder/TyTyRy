extends Control

const BACKGROUND := Color("101426")
const PANEL := Color("1a2140")
const PANEL_LIGHT := Color("252f59")
const TEXT := Color("eef3ff")
const MUTED := Color("aab9df")
const ACCENT := Color("4fe0ca")
const GOLD := Color("ffd36b")
const DANGER := Color("ff7892")
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

var balance_label: Label
var passive_summary_label: Label
var player_level_label: Label
var build_label: Label
var experience_bar: ProgressBar
var monster_title: Label
var monster_health_label: Label
var monster_health_bar: ProgressBar
var monster_button: Button
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
var passive_timer: Timer

func _ready() -> void:
	build_start_screen()

func build_start_screen() -> void:
	clear_screen()
	var page := make_page()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(500, 0)
	card.add_theme_stylebox_override("panel", panel_style(PANEL, 28))
	center.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.add_theme_constant_override("margin_left", 42)
	content.add_theme_constant_override("margin_right", 42)
	content.add_theme_constant_override("margin_top", 42)
	content.add_theme_constant_override("margin_bottom", 42)
	card.add_child(content)
	var eyebrow := make_label("ПРОТОТИП МОБИЛЬНОЙ ИГРЫ", 15, ACCENT)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)
	var title := make_label("MONSTER CLICKER", 44, TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var intro := make_label("Побеждайте монстров, зарабатывайте монеты\nи улучшайте силу удара и доход.", 19, MUTED)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	var start := make_button("Начать", 22, ACCENT)
	start.custom_minimum_size = Vector2(0, 62)
	start.pressed.connect(start_game)
	content.add_child(start)

func start_game() -> void:
	coins = 0
	click_power = 1
	passive_income = 0
	monster_level = 1
	click_upgrade_cost = 15
	passive_upgrade_cost = 25
	critical_chance = 0.0
	critical_multiplier = 2
	critical_upgrade_cost = 40
	player_level = 1
	player_experience = 0
	experience_to_next_level = 30
	skill_points = 1
	berserker_rank = 0
	fortune_rank = 0
	totem_rank = 0
	precision_rank = 0
	rage_cooldown = 0
	fangs = 0
	crystals = 0
	equipped_weapon = ""
	spawn_monster()
	build_game_screen()

func build_game_screen() -> void:
	clear_screen()
	var page := make_page()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	page.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 16)
	scroll.add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	layout.add_child(header)
	var game_title := make_label("MONSTER CLICKER", 25, TEXT)
	game_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(game_title)
	balance_label = make_label("", 20, GOLD)
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(balance_label)
	passive_summary_label = make_label("", 15, MUTED)
	layout.add_child(passive_summary_label)
	player_level_label = make_label("", 15, ACCENT)
	layout.add_child(player_level_label)
	build_label = make_label("", 14, MUTED)
	layout.add_child(build_label)
	experience_bar = ProgressBar.new()
	experience_bar.custom_minimum_size = Vector2(0, 14)
	experience_bar.show_percentage = false
	experience_bar.add_theme_stylebox_override("background", panel_style(Color("10172d"), 8))
	experience_bar.add_theme_stylebox_override("fill", panel_style(ACCENT, 8))
	layout.add_child(experience_bar)
	layout.add_child(HSeparator.new())
	var monster_card := PanelContainer.new()
	monster_card.add_theme_stylebox_override("panel", panel_style(PANEL, 22))
	layout.add_child(monster_card)
	var monster_content := VBoxContainer.new()
	monster_content.add_theme_constant_override("separation", 12)
	monster_content.add_theme_constant_override("margin_left", 26)
	monster_content.add_theme_constant_override("margin_right", 26)
	monster_content.add_theme_constant_override("margin_top", 24)
	monster_content.add_theme_constant_override("margin_bottom", 24)
	monster_card.add_child(monster_content)
	monster_title = make_label("", 24, TEXT)
	monster_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monster_content.add_child(monster_title)
	monster_health_label = make_label("", 16, MUTED)
	monster_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monster_content.add_child(monster_health_label)
	monster_health_bar = ProgressBar.new()
	monster_health_bar.custom_minimum_size = Vector2(0, 24)
	monster_health_bar.show_percentage = false
	monster_health_bar.add_theme_stylebox_override("background", panel_style(Color("10172d"), 12))
	monster_health_bar.add_theme_stylebox_override("fill", panel_style(DANGER, 12))
	monster_content.add_child(monster_health_bar)
	monster_button = make_button("", 26, PANEL_LIGHT)
	monster_button.custom_minimum_size = Vector2(0, 150)
	monster_button.tooltip_text = "Нажмите, чтобы нанести урон монстру"
	monster_button.pressed.connect(attack_monster)
	monster_content.add_child(monster_button)
	status_label = make_label("", 15, ACCENT)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monster_content.add_child(status_label)
	var upgrade_heading := make_label("Улучшения", 22, TEXT)
	layout.add_child(upgrade_heading)
	var upgrades := VBoxContainer.new()
	upgrades.add_theme_constant_override("separation", 10)
	layout.add_child(upgrades)
	click_upgrade_button = make_upgrade_button()
	click_upgrade_button.pressed.connect(buy_click_upgrade)
	upgrades.add_child(click_upgrade_button)
	passive_upgrade_button = make_upgrade_button()
	passive_upgrade_button.pressed.connect(buy_passive_upgrade)
	upgrades.add_child(passive_upgrade_button)
	critical_upgrade_button = make_upgrade_button()
	critical_upgrade_button.pressed.connect(buy_critical_upgrade)
	upgrades.add_child(critical_upgrade_button)
	var forge_heading := make_label("Кузница", 22, TEXT)
	layout.add_child(forge_heading)
	var forge_card := PanelContainer.new()
	forge_card.add_theme_stylebox_override("panel", panel_style(Color("20264b"), 18))
	layout.add_child(forge_card)
	var forge_content := VBoxContainer.new()
	forge_content.add_theme_constant_override("separation", 9)
	forge_content.add_theme_constant_override("margin_left", 18)
	forge_content.add_theme_constant_override("margin_right", 18)
	forge_content.add_theme_constant_override("margin_top", 16)
	forge_content.add_theme_constant_override("margin_bottom", 16)
	forge_card.add_child(forge_content)
	ingredients_label = make_label("", 15, GOLD)
	forge_content.add_child(ingredients_label)
	weapon_label = make_label("", 15, ACCENT)
	weapon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forge_content.add_child(weapon_label)
	common_forge_button = make_upgrade_button()
	common_forge_button.pressed.connect(forge_weapon.bind("common"))
	forge_content.add_child(common_forge_button)
	rare_forge_button = make_upgrade_button()
	rare_forge_button.pressed.connect(forge_weapon.bind("rare"))
	forge_content.add_child(rare_forge_button)
	epic_forge_button = make_upgrade_button()
	epic_forge_button.pressed.connect(forge_weapon.bind("epic"))
	forge_content.add_child(epic_forge_button)
	var talents_heading := make_label("Путь героя", 22, TEXT)
	layout.add_child(talents_heading)
	var talents_hint := make_label("Очки талантов даются за уровни. Выберите направление и соберите свой билд.", 14, MUTED)
	talents_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(talents_hint)
	var talents := VBoxContainer.new()
	talents.add_theme_constant_override("separation", 10)
	layout.add_child(talents)
	berserker_button = make_upgrade_button()
	berserker_button.pressed.connect(buy_talent.bind("berserker"))
	talents.add_child(berserker_button)
	fortune_button = make_upgrade_button()
	fortune_button.pressed.connect(buy_talent.bind("fortune"))
	talents.add_child(fortune_button)
	totem_button = make_upgrade_button()
	totem_button.pressed.connect(buy_talent.bind("totem"))
	talents.add_child(totem_button)
	precision_button = make_upgrade_button()
	precision_button.pressed.connect(buy_talent.bind("precision"))
	talents.add_child(precision_button)
	rage_button = make_button("", 18, Color("5a386f"))
	rage_button.custom_minimum_size = Vector2(0, 66)
	rage_button.pressed.connect(use_rage)
	talents.add_child(rage_button)
	var hint := make_label("Каждый 10-й монстр — босс: у него больше здоровья, зато награда заметно выше.", 14, MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hint)
	passive_timer = Timer.new()
	passive_timer.wait_time = 1.0
	passive_timer.timeout.connect(on_passive_tick)
	add_child(passive_timer)
	passive_timer.start()
	update_game_ui()

func attack_monster() -> void:
	var critical := randf() < total_critical_chance()
	var damage := manual_damage() * (critical_multiplier if critical else 1)
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

func on_passive_tick() -> void:
	if rage_cooldown > 0:
		rage_cooldown -= 1
	var income := effective_passive_income()
	if income <= 0:
		update_game_ui()
		return
	coins += income
	status_label.text = "+%d монет пассивного дохода." % income
	update_game_ui()

func buy_click_upgrade() -> void:
	if coins < click_upgrade_cost:
		status_label.text = "Недостаточно монет для силы удара."
		return
	coins -= click_upgrade_cost
	click_power += 1
	click_upgrade_cost = int(ceil(float(click_upgrade_cost) * 1.6))
	status_label.text = "Сила удара увеличена до %d." % click_power
	update_game_ui()

func buy_passive_upgrade() -> void:
	if coins < passive_upgrade_cost:
		status_label.text = "Недостаточно монет для пассивного дохода."
		return
	coins -= passive_upgrade_cost
	passive_income += 1
	passive_upgrade_cost = int(ceil(float(passive_upgrade_cost) * 1.7))
	status_label.text = "Пассивный доход увеличен до %d/с." % passive_income
	update_game_ui()

func buy_critical_upgrade() -> void:
	if coins < critical_upgrade_cost:
		status_label.text = "Недостаточно монет для критического удара."
		return
	coins -= critical_upgrade_cost
	critical_chance = min(critical_chance + 0.05, 0.50)
	critical_upgrade_cost = int(ceil(float(critical_upgrade_cost) * 1.85))
	status_label.text = "Шанс критического удара: %d%%." % int(critical_chance * 100.0)
	update_game_ui()

func buy_talent(talent: String) -> void:
	if skill_points <= 0:
		status_label.text = "Нужно новое очко таланта: получите уровень игрока."
		return
	if talent_rank(talent) >= 5:
		status_label.text = "Этот талант уже развит до максимума."
		return
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
	var required_level: int = recipe["level"]
	var required_coins: int = recipe["coins"]
	var required_fangs: int = recipe["fangs"]
	var required_crystals: int = recipe["crystals"]
	if player_level < required_level:
		status_label.text = "Кузнице нужен уровень игрока %d." % required_level
		return
	if weapon_rank(rarity) <= weapon_rank(equipped_weapon):
		status_label.text = "Уже экипировано оружие не ниже этой редкости."
		return
	if coins < required_coins or fangs < required_fangs or crystals < required_crystals:
		status_label.text = "Не хватает монет или ингредиентов для ковки."
		return
	coins -= required_coins
	fangs -= required_fangs
	crystals -= required_crystals
	equipped_weapon = rarity
	status_label.text = "Выковано: %s! Урон оружия растёт с уровнем героя." % recipe["title"]
	update_game_ui()

func use_rage() -> void:
	if berserker_rank < 3:
		status_label.text = "Ярость откроется на 3 ранге Когтей берсерка."
		return
	if rage_cooldown > 0:
		return
	var damage := manual_damage() * 8
	monster_health = max(monster_health - damage, 0)
	rage_cooldown = 15
	if monster_health <= 0:
		var reward := monster_reward()
		coins += reward
		gain_experience(monster_level * 3)
		var loot_text := roll_ingredients()
		monster_level += 1
		spawn_monster()
		status_label.text = "ЯРОСТЬ уничтожила цель! +%d монет. %s" % [reward, loot_text]
	else:
		status_label.text = "ЯРОСТЬ нанесла %d урона." % damage
	update_game_ui()

func spawn_monster() -> void:
	monster_max_health = 18 + monster_level * 12 + monster_level * monster_level * 4
	if is_boss():
		monster_max_health *= 3
	monster_health = monster_max_health

func monster_reward() -> int:
	var reward := 6 + monster_level * 5
	reward = int(round(float(reward) * (1.0 + 0.18 * fortune_rank)))
	return reward * 4 if is_boss() else reward

func roll_ingredients() -> String:
	var fang_chance: float = 0.62 if not is_boss() else 0.95
	var crystal_chance: float = 0.28 if not is_boss() else 0.70
	var gained_fangs := 0
	var gained_crystals := 0
	if randf() < fang_chance:
		gained_fangs = randi_range(1, 2) + (1 if is_boss() else 0)
		fangs += gained_fangs
	if randf() < crystal_chance:
		gained_crystals = 1 + (1 if is_boss() else 0)
		crystals += gained_crystals
	if gained_fangs == 0 and gained_crystals == 0:
		return "Ингредиенты не выпали."
	var parts: Array[String] = []
	if gained_fangs > 0:
		parts.append("+%d клыка" % gained_fangs)
	if gained_crystals > 0:
		parts.append("+%d осколка" % gained_crystals)
	return "Добыча: " + ", ".join(parts)

func is_boss() -> bool:
	return monster_level % 10 == 0

func gain_experience(amount: int) -> void:
	player_experience += amount
	while player_experience >= experience_to_next_level:
		player_experience -= experience_to_next_level
		player_level += 1
		experience_to_next_level = int(ceil(float(experience_to_next_level) * 1.45))
		skill_points += 1
		status_label.text = "Уровень игрока повышен до %d! +1 очко таланта." % player_level

func manual_damage() -> int:
	return int(round(float(click_power + weapon_damage()) * (1.0 + 0.22 * berserker_rank)))

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

func weapon_title() -> String:
	if equipped_weapon.is_empty():
		return "Оружие не экипировано"
	return WEAPON_RECIPES[equipped_weapon]["title"]

func effective_passive_income() -> int:
	return int(round(float(passive_income) * (1.0 + 0.25 * totem_rank)))

func total_critical_chance() -> float:
	return min(critical_chance + 0.03 * precision_rank, 0.75)

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
	if highest == 0:
		return "Свободный охотник"
	if berserker_rank == highest:
		return "Берсерк"
	if fortune_rank == highest:
		return "Золотой охотник"
	if totem_rank == highest:
		return "Шаман добычи"
	return "Точный хищник"

func update_game_ui() -> void:
	if balance_label == null:
		return
	balance_label.text = "◈ %d" % coins
	passive_summary_label.text = "Пассивный доход: %d/с · Удар: %d · Крит: %d%%" % [effective_passive_income(), manual_damage(), int(total_critical_chance() * 100.0)]
	player_level_label.text = "Игрок — уровень %d · опыт %d / %d · очки талантов: %d" % [player_level, player_experience, experience_to_next_level, skill_points]
	build_label.text = "Текущий билд: " + build_name()
	experience_bar.max_value = experience_to_next_level
	experience_bar.value = player_experience
	monster_title.text = ("БОСС: древний монстрик" if is_boss() else "Монстрик") + " · уровень %d" % monster_level
	monster_health_label.text = "Здоровье: %d / %d" % [monster_health, monster_max_health]
	monster_health_bar.max_value = monster_max_health
	monster_health_bar.value = monster_health
	monster_button.text = ("☠" if is_boss() else "◉") + "\nАТАКОВАТЬ\nурон: %d" % manual_damage()
	click_upgrade_button.text = "Усилить удар  +1\nСтоимость: %d монет" % click_upgrade_cost
	passive_upgrade_button.text = "Пассивный доход  +1/с\nСтоимость: %d монет" % passive_upgrade_cost
	critical_upgrade_button.text = "Критический удар  +5%%\nУрон ×%d · стоимость: %d монет" % [critical_multiplier, critical_upgrade_cost]
	ingredients_label.text = "Ингредиенты: клыки %d · осколки %d" % [fangs, crystals]
	weapon_label.text = "Экипировано: %s · урон оружия: +%d (растёт с уровнем)" % [weapon_title(), weapon_damage()]
	common_forge_button.text = forge_button_text("common")
	rare_forge_button.text = forge_button_text("rare")
	epic_forge_button.text = forge_button_text("epic")
	berserker_button.text = "Когти берсерка  %d/5\n+22%% к урону от кликов" % berserker_rank
	fortune_button.text = "Золотой след  %d/5\n+18%% к награде за убийство" % fortune_rank
	totem_button.text = "Тотем добычи  %d/5\n+25%% к пассивному доходу" % totem_rank
	precision_button.text = "Точный удар  %d/5\n+3%% к шансу крита" % precision_rank
	rage_button.text = ("Ярость берсерка\nНаносит ×8 урона" if berserker_rank >= 3 else "Ярость берсерка — закрыто\nНужно 3/5 Когтей берсерка") + (" · %d с" % rage_cooldown if rage_cooldown > 0 else "")
	click_upgrade_button.disabled = coins < click_upgrade_cost
	passive_upgrade_button.disabled = coins < passive_upgrade_cost
	critical_upgrade_button.disabled = coins < critical_upgrade_cost
	berserker_button.disabled = skill_points <= 0 or berserker_rank >= 5
	fortune_button.disabled = skill_points <= 0 or fortune_rank >= 5
	totem_button.disabled = skill_points <= 0 or totem_rank >= 5
	precision_button.disabled = skill_points <= 0 or precision_rank >= 5
	rage_button.disabled = berserker_rank < 3 or rage_cooldown > 0
	common_forge_button.disabled = not can_forge("common")
	rare_forge_button.disabled = not can_forge("rare")
	epic_forge_button.disabled = not can_forge("epic")

func forge_button_text(rarity: String) -> String:
	var recipe: Dictionary = WEAPON_RECIPES[rarity]
	return "%s · уровень %d+\n%d монет · %d клыков · %d осколков" % [recipe["title"], recipe["level"], recipe["coins"], recipe["fangs"], recipe["crystals"]]

func can_forge(rarity: String) -> bool:
	var recipe: Dictionary = WEAPON_RECIPES[rarity]
	return player_level >= recipe["level"] and coins >= recipe["coins"] and fangs >= recipe["fangs"] and crystals >= recipe["crystals"] and weapon_rank(rarity) > weapon_rank(equipped_weapon)

func clear_screen() -> void:
	for child in get_children():
		child.queue_free()
	passive_timer = null

func make_page() -> ColorRect:
	var page := ColorRect.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.color = BACKGROUND
	add_child(page)
	return page

func make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func make_button(value: String, font_size: int, color: Color) -> Button:
	var button := Button.new()
	button.text = value
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", panel_style(color, 16))
	button.add_theme_stylebox_override("hover", panel_style(color.lightened(0.12), 16))
	button.add_theme_stylebox_override("pressed", panel_style(color.darkened(0.10), 16))
	button.add_theme_stylebox_override("disabled", panel_style(Color("303854"), 16))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return button

func make_upgrade_button() -> Button:
	var button := make_button("", 17, PANEL_LIGHT)
	button.custom_minimum_size = Vector2(0, 78)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button

func panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
