param(
	# Каталог с xml-календарями
	[string]$folderxml = '.\calendars\xml'
)
function set-listnonworking {
	param (
		[string]$path = '.\calendars\kaz\calendar_2023_kaz.xml'
	)
	[xml]$xml = gc $path -enc utf8
	$y = $xml.calendar.year
	$cty = $xml.calendar.country
	if(!$cty){
		write-host Атрибут COUNTRY пустой -for green
		write-host Файл: $path -for yellow
		break
		#$cty = $ctry
	}
	$lang = $xml.calendar.lang
	$listpath = '.\Calendars\' + $cty
	if(!(test-path -path $listpath -patht Container)){$null = md $listpath}
	# путь и наименование выходного файла .txt со списком
	$file = $listpath + '\' + 'calendar_' + $y + '_' + $cty + '-' + $lang + '.txt'
	if (test-path $file -patht leaf) {
		write-host Файл $file уже существует -for red
		return
	}
	$w,$h = @(1,2,3,4,5), @(6,0)
	$start = get-date($($y + '.01.01'))
	$end = get-date($($y + '.12.31'))
	$x = ($end.date - $start.date).days
	$we = @()
	for ($i=0;$i -le $x;$i++){
		# выборка выходных $h из григорианского календаря
		if($start.adddays($i).dayofweek.value__ -in $h){
			$we += $start.adddays($i).date
		}
	}
	# конвертируем формат
	$weekends = $we|%{get-date($_) -f 'yyyy.MM.dd'}
	# выборка перенесенных рабочих дней на выходные:
	$workweek = ($xml.selectnodes('//day')|? t -in @(2,3)).d|%{$y + ".$_"}
	# праздники - возможно совпадение по датам с выходными:
	$holiday = ($xml.selectnodes('//day')|? t -eq 1).d|%{$y + ".$_"}
	# окончательное формирование списка с удалением дублей (выходной-праздник)
	($weekends|?{$_ -notin $workweek}) + $holiday|sort -uni|
	out-file $file -enc utf8
}

dir $folderxml -filter '*.xml' -file|%{set-listnonworking -path ($_.fullname )}
