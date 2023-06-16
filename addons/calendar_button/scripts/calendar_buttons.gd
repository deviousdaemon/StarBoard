class_name CalendarButtons

const BUTTONS_COUNT = 42
var calendar = (load("res://addons/calendar_button/class/calendar.gd") as GDScript).new()
var buttons_container : GridContainer

func _init(calendar_script, _buttons_container : GridContainer):
	buttons_container = _buttons_container
	setup_button_signals(calendar_script)

func setup_button_signals(calendar_script):
	for i in range(BUTTONS_COUNT):
		var btn_node: Button = buttons_container.get_node("btn_" + str(i)) as Button
		btn_node.pressed.connect(calendar_script.day_selected.bind(btn_node))
#		btn_node.connect("pressed", calendar_script, "day_selected", [btn_node])

func update_calendar_buttons(selected_date : Date):
	_clear_calendar_buttons()
	
	var days_in_month : int = calendar.get_days_in_month(selected_date.get_month(), selected_date.get_year())
	var start_day_of_week : int = calendar.get_weekday(1, selected_date.get_month(), selected_date.get_year())
	var current_day: int = calendar.get_day()
	var current_month: int = calendar.get_month()
	var current_year: int = calendar.get_year()
	for i in range(days_in_month):
		var btn_node : Button = buttons_container.get_node("btn_" + str(i + start_day_of_week))
		btn_node.set_text(str(i + 1))
		
		if selected_date.year <= current_year and selected_date.month <= current_month and i < current_day - 1:
			btn_node.set_disabled(true)
		else:
			btn_node.set_disabled(false)
		
		# If the day entered is "today"
		if(i + 1 == calendar.get_day() && selected_date.get_year() == calendar.get_year() && selected_date.get_month() == calendar.get_month() ):
			btn_node.set_flat(true)
		else:
			btn_node.set_flat(false)

func _clear_calendar_buttons():
	for i in range(BUTTONS_COUNT):
		var btn_node : Button = buttons_container.get_node("btn_" + str(i))
		btn_node.set_text("")
		btn_node.set_disabled(true)
		btn_node.set_flat(false)
