extends RefCounted
class_name Date

var day : int : set = set_day
var month : int :  set = set_month
var year : int : set = set_year

func _init(day : int = Time.get_datetime_dict_from_system()["day"], 
		month : int = Time.get_datetime_dict_from_system()["month"], 
		year : int = Time.get_datetime_dict_from_system()["year"]):
	self.day = day
	self.month = month
	self.year = year

# Supported Date Formats:
# DD : Two digit day of month
# MM : Two digit month
# YY : Two digit year
# YYYY : Four digit year
func date(date_format = "DD-MM-YY") -> String:
	if("DD".is_subsequence_of(date_format)):
		date_format = date_format.replace("DD", str(get_day()).pad_zeros(2))
	if("MM".is_subsequence_of(date_format)):
		date_format = date_format.replace("MM", str(get_month()).pad_zeros(2))
	if("YYYY".is_subsequence_of(date_format)):
		date_format = date_format.replace("YYYY", str(get_year()))
	elif("YY".is_subsequence_of(date_format)):
		date_format = date_format.replace("YY", str(get_year()).substr(2,3))
	return date_format

func get_date_dict() -> Dictionary:
	return {
		day=day,
		month=month,
		year=year
	}

func get_day() -> int:
	return day

func get_month() -> int:
	return month

func get_year() -> int:
	return year

func set_day(_day : int):
	day = _day

func set_month(_month : int):
	month = _month

func set_year(_year : int):
	year = _year

func change_to_prev_month():
	var selected_month = get_month()
	selected_month -= 1
	if(selected_month < 1):
		set_month(12)
		set_year(get_year() - 1)
	else:
		set_month(selected_month)

func change_to_next_month():
	var selected_month = get_month()
	selected_month += 1
	if(selected_month > 12):
		set_month(1)
		set_year(get_year() + 1)
	else:
		set_month(selected_month)

func change_to_prev_year():
	set_year(get_year() - 1)

func change_to_next_year():
	set_year(get_year() + 1)
