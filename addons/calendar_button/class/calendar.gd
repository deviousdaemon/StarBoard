extends RefCounted
class_name Calendar

enum Month { JAN = 1, FEB = 2, MAR = 3, APR = 4, MAY = 5, JUN = 6, JUL = 7,
		AUG = 8, SEP = 9, OCT = 10, NOV = 11, DEC = 12 }

const MONTH_NAME = [ 
		"Jan", "Feb", "Mar", "Apr", 
		"May", "Jun", "Jul", "Aug", 
		"Sep", "Oct", "Nov", "Dec" ]

const WEEKDAY_NAME = [ 
		"Sunday", "Monday", "Tuesday", "Wednesday", 
		"Thursday", "Friday", "Saturday" ]

func get_days_in_month(month : int, year : int) -> int:
	var number_of_days : int
	if(month == Month.APR || month == Month.JUN || month == Month.SEP
			|| month == Month.NOV):
		number_of_days = 30
	elif(month == Month.FEB):
		var is_leap_year = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
		if(is_leap_year):
			number_of_days = 29
		else:
			number_of_days = 28
	else:
		number_of_days = 31
	
	return number_of_days

func get_weekday(day : int, month : int, year : int) -> int:
	var t : Array = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
	if(month < 3):
		year -= 1
	return (year + year/4 - year/100 + year/400 + t[month - 1] + day) % 7

func get_weekday_name(day : int, month : int, year : int) -> String:
	var day_num = get_weekday(day, month, year)
	return WEEKDAY_NAME[day_num]

func get_month_name(month : int) -> String:
	return MONTH_NAME[month - 1]

func get_hour() -> int:
	return Time.get_datetime_dict_from_system()["hour"]

func get_minute() -> int:
	return Time.get_datetime_dict_from_system()["minute"]

func get_second() -> int:
	return Time.get_datetime_dict_from_system()["second"]

func get_day() -> int:
	return Time.get_datetime_dict_from_system()["day"]

func weekday() -> int:
	return Time.get_datetime_dict_from_system()["weekday"]

func get_month() -> int:
	return Time.get_datetime_dict_from_system()["month"]

func get_year() -> int:
	return Time.get_datetime_dict_from_system()["year"]

func daylight_savings_time() -> int:
	return dst()

func dst() -> int:
	return Time.get_datetime_dict_from_system()["dst"]
