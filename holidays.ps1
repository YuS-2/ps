param(
	# Каталог с xml-календарями
	[string]$folderxml = '.\calendars\xml'
)
function get-holidays {
	param (
		[string]$path
	)
	[xml]$xml = gc $path -enc utf8
	$y = $xml.calendar.year
	$cty = $xml.calendar.country
	if(!$cty){
		write-host Атрибут COUNTRY пустой -for green
		write-host Файл: $path -for yellow
		break
	}
	$lang = $xml.calendar.lang
	$listpath = '.\Calendars\' + $cty
	if(!(test-path -path $listpath -patht Container)){$null = md $listpath}
	# путь и наименование выходного файла .txt со списком
	$file = $listpath + '\' + 'holidays_' + $y + '_' + $cty + '-' + $lang + '.txt'
	if (test-path $file -patht leaf) {
		write-host Файл $file уже существует -for red
		return
	}
	$w,$h = @(1), @(2,3)
	$start = get-date($($y + '.01.01'))
	$end = get-date($($y + '.12.31'))
	$x = $xml.calendar.days.day.d.count
	$we = @()
	for ($i=0;$i -lt $x;$i++){
		# выборка праздников и перенесенных из xml календаря
		if ($xml.calendar.days.day.t[$i] -eq 1) {
			$day = 'выходной день,'
		} elseif ($xml.calendar.days.day.t[$i] -eq 1){
			$day = 'сокращенный рабочий день,'
		} else {$day = 'рабочий день,'}
		if($xml.calendar.days.day.h[$i]){
			$title = ($xml.selectnodes("//holiday")|? id -eq $xml.calendar.days.day.h[$i]).title
			$we += (get-date($y + '.' +$xml.calendar.days.day.d[$i])).tostring("dd.MM.yyyy") + ' - ' + $day + ' ' + $title
		} else {
			$f = (get-date($y + '.' + $xml.calendar.days.day.f[$i])).tostring("dd.MM.yyyy")
			$we += (get-date($y + '.' + $xml.calendar.days.day.d[$i])).tostring("dd.MM.yyyy") + ' - ' + $day + ' перенесен с ' + $f
		}
	}
	$we|out-file $file -enc utf8
}

dir $folderxml -filter '*.xml' -file|%{get-holidays -path ($_.fullname)}
