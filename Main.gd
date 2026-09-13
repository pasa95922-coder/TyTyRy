extends Control

const BACKGROUND := Color("101426")
const PANEL := Color("1a2140")
const PANEL_LIGHT := Color("252f59")
const TEXT := Color("eef3ff")
const MUTED := Color("aab9df")
const ACCENT := Color("4fe0ca")
const GOLD := Color("ffd36b")
const DANGER := Color("ff7892")

var coins := 0
var click_power := 1
var passive_income := 0
var monster_level := 1
var monster_health := 0
var monster_max_health := 0
var click_upgrade_cost := 15
var passive_upgrade_cost := 25

var balance_label: Label
var passive_summary_label: Label
var monster_title: Label
var monster_health_label: Label
var monster_health_bar: ProgressBar
var monster_button: Button
var status_label: Label
var click_upgrade_button: Button
var passive_upgrade_button: Button
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
	var hint := make_label("Совет: чем выше уровень монстра, тем больше здоровье и награда.", 14, MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hint)
	passive_timer = Timer.new()
	passive_timer.wait_time = 1.0
	passive_timer.timeout.connect(on_passive_tick)
	add_child(passive_timer)
	passive_timer.start()
	update_game_ui()

func attack_monster() -> void:
	monster_health = max(monster_health - click_power, 0)
	if monster_health <= 0:
		var reward := monster_reward()
		coins += reward
		monster_level += 1
		spawn_monster()
		status_label.text = "+%d монет! Появился монстр уровня %d." % [reward, monster_level]
	else:
		status_label.text = "Удар на %d урона." % click_power
	update_game_ui()

func on_passive_tick() -> void:
	if passive_income <= 0:
		return
	coins += passive_income
	status_label.text = "+%d монет пассивного дохода." % passive_income
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

func spawn_monster() -> void:
	monster_max_health = 18 + monster_level * 12 + monster_level * monster_level * 4
	monster_health = monster_max_health

func monster_reward() -> int:
	return 6 + monster_level * 5

func update_game_ui() -> void:
	if balance_label == null:
		return
	balance_label.text = "◈ %d" % coins
	passive_summary_label.text = "Пассивный доход: %d монет/с · Удар: %d" % [passive_income, click_power]
	monster_title.text = "Монстрик · уровень %d" % monster_level
	monster_health_label.text = "Здоровье: %d / %d" % [monster_health, monster_max_health]
	monster_health_bar.max_value = monster_max_health
	monster_health_bar.value = monster_health
	monster_button.text = "◉\nАТАКОВАТЬ\nурон: %d" % click_power
	click_upgrade_button.text = "Усилить удар  +1\nСтоимость: %d монет" % click_upgrade_cost
	passive_upgrade_button.text = "Пассивный доход  +1/с\nСтоимость: %d монет" % passive_upgrade_cost
	click_upgrade_button.disabled = coins < click_upgrade_cost
	passive_upgrade_button.disabled = coins < passive_upgrade_cost

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
