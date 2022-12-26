# Пример работы со временем. Учет времени только в рабочее время (например 9:00 - 19:00),
# исключая выходные и праздничные дни по производственному календарю.
# в данном варианте использовались календари в текстовом виде, со списком выходных и праздничных
# дней. (http://xmlcalendar.ru/data/ru/2023/calendar.txt) (http://xmlcalendar.ru/)
# .\script_calendar.ps1 -stime $(get-date("21.12.2022 19:50")) -etime $(get-date("22.12.2022 17:00"))
param (
	[datetime]$stime = $(get-date("21.12.2022 8:00")),
	[datetime]$etime = $(get-date("22.12.2022 8:00")),
	[timespan]$startwork = $(new-timespan -h 9 -min 0),
	[timespan]$endwork = $(new-timespan -h 19 -min 0),
	[string]$calendarpath = '.\Calendars\KAZ'
)
function get-timework {
	param (
		[datetime]$stt, # старт
		[datetime]$ett, # стоп
		[timespan]$start, # начало рабочего периода
		[timespan]$end, # конец рабочего периода
		# Каталог календарей в виде текстового списка (*.txt) с датами формата YYYY.MM.DD
		[string]$pathcr = '.\Calendars\KAZ' 
	)
	if ($ett -le $stt) {
		write-host Ошибка! Проверьте данные '$stt - старт/ $ett - стоп' -for red
		break
	}
	$x = ($ett.date - $stt.date).days # количество дней между стартом и стопом
	# Считываем производственные календари (списки выходных и праздничных дней)
	$cal = gc ($pathcr + '\' + '*.txt')|%{get-date($_)}
	if ($stt.year -notin $cal.year -or $ett.year -notin $cal.year){
		write-host Отсутствует производственный календарь на год начала или конца периода! -for red
		break
	}
	$m = new-timespan -h ($end - $start).totalhours # Вычисляем рабочее время за день
	# укорачиваем код до названия переменных:
	$rs,$re = $stt.timeofday.totalminutes,$ett.timeofday.totalminutes
	$s,$e = $start.totalminutes,$end.totalminutes
	$minutes = $m.totalminutes
	# Если старт в вых. или праздник, перенос на ближайший р.день в большую сторону
	# и время обнуляется
	if ($x -and $stt.date -in $cal){
		$stt = $stt.addminutes(-$rs)
		while ($stt.date -in $cal){
			$stt = $stt.adddays(1)
		}
	}
	# Если стоп в вых. или праздник, перенос на ближайший р.день в большую сторону
	# и время обнуляется
	if ($x -and $ett.date -in $cal){
		$ett = $ett.addminutes(-$re)
		while ($ett.date -in $cal){
			$ett = $ett.adddays(1)
		}
	}
	# переинициализация старта и стопа
	$rs,$re = $stt.timeofday.totalminutes,$ett.timeofday.totalminutes
	$x = ($ett.date - $stt.date).days # пересчет дней между стартом и стопом 
	$j = 0
	for ($i = 0; $i -le $x;$i++){
		#счетчик вых. и празд. по календарю
		if ($stt.adddays($i).date -in $cal){
			$j++
		}
	}
	# Вычисляем окончательное количество рабочих дней
	$x = $x - $j
	# Реализация логики подсчета для будней:
	if (!$x -and $re -ge $rs){
		# Если и старт, и стоп в один день
		if($rs -lt $s -and $re -gt $e){
			$time = new-timespan -min ($minutes)
		} elseif (($rs -ge $s -and $rs -le $e) -and $re -gt $e){
			$time = new-timespan -min ($e - $rs)
		} elseif (($rs -gt $e -and $re -gt $e) -or ($rs -lt $s -and $re -lt $s)){
			$time = new-timespan
		} elseif ($rs -lt $s -and ($re -ge $s -and $re -le $e)) {
			$time = new-timespan -min ($re - $s)
		} elseif (($rs -ge $s -and $rs -le $e) -and ($re -ge $s -and $re -le $e)){
			$time = new-timespan -min ($re - $rs)
		}
	} elseif ($x) {
		# Если старт и стоп в разные дни,
		if ($rs -lt $s -and $re -gt $e){
			$time = new-timespan -min ($minutes * ($x+1))
		} elseif (($rs -ge $s -and $rs -le $e) -and $re -gt $e){
			$time = new-timespan -min ($e - $rs + $minutes*$x)
		} elseif (($rs -gt $e -and $re -gt $e) -or ($rs -lt $s -and $re -lt $s)){
			$time = new-timespan -min ($minutes * $x)
		} elseif ($rs -lt $s -and ($re -ge $s -and $re -le $e)){
			$time = new-timespan -min ($re - $s + $minutes*$x)
		} elseif (($rs -ge $s -and $rs -le $e) -and ($re -ge $s -and $re -le $e)){
			$time = new-timespan -min ($re - $s + $e - $rs + $minutes*($x-1))
		} elseif ($rs -gt $e -and ($re -ge $s -and $re -le $e)) {
			$time = new-timespan -min ($re - $s + $minutes*($x-1))
		} elseif (($rs -ge $s -and $rs -le $e) -and $re -lt $s){
			$time = new-timespan -min ($e - $rs + $minutes*($x-1))
		} elseif ($rs -gt $e -and $re -lt $s) {
			$time = new-timespan -min ($minutes*($x-1))
		} 
	} else {
		write-host Условия не сработали... для будущей разработки. -for cyan
	}
	return $time
}

get-timework -stt $stime -ett $etime -start $startwork -end $endwork -pathcr $calendarpath
