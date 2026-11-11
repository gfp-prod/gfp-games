extends RefCounted
## One accelerated world calendar. Real seconds drive hours; time skipping
## advances whole calendar days without rendering skipped animation frames.
const SECONDS_PER_DAY: float = 240.0
const DAYS_PER_YEAR: int = 36
const DAYS_PER_SEASON: int = 9
const MONTH_NAMES := ["Dawnrise","Highsun","Leafturn","Longnight"]
var elapsed: float = 90.0
var day: int = 0

func advance(delta: float) -> int:
	elapsed += maxf(0.0,delta)
	var passed: int=int(floor(elapsed/SECONDS_PER_DAY))
	if passed>0:
		elapsed-=float(passed)*SECONDS_PER_DAY
		day+=passed
	return passed

func advance_days(count: int) -> void:
	day += maxi(0,count)

func fraction() -> float:
	return clampf(elapsed/SECONDS_PER_DAY,0.0,1.0)

func hour() -> int:
	return clampi(int(floor(fraction()*24.0)),0,23)

func year() -> int:
	return int(day/DAYS_PER_YEAR)+1

func day_of_year() -> int:
	return posmod(day,DAYS_PER_YEAR)+1

func season() -> String:
	return MONTH_NAMES[mini(3,int((day_of_year()-1)/DAYS_PER_SEASON))]

func is_night() -> bool:
	return hour()<6 or hour()>=19

func darkness() -> float:
	# Smooth solar elevation without blackening daytime sky for a sudden
	# binary transition. Noon is bright, 22:00–04:00 fully dark.
	var hour_of_day: float=fraction()*24.0
	return 1.0-smoothstep(-.22,.22,sin((hour_of_day-6.0)*TAU/24.0))

func describe() -> String:
	return "Year %d · %s %d · %02d:00" % [year(),season(),day_of_year(),hour()]

func snapshot() -> Dictionary:
	return {"version":1,"day":day,"elapsed":elapsed}

func restore(record: Dictionary) -> bool:
	if record.is_empty(): return true
	if int(record.get("version",0))!=1: return false
	var next_day: int=int(record.get("day",-1))
	var next_elapsed: float=float(record.get("elapsed",-1.0))
	if next_day<0 or next_day>3600000 or next_elapsed<0.0 or next_elapsed>=SECONDS_PER_DAY:
		return false
	day=next_day
	elapsed=next_elapsed
	return true
