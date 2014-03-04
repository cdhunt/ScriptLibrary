# http://thetvdb.com/wiki/index.php?title=Programmers_API
$apikey = '123'

$mirrors = irm "http://thetvdb.com/api/$apikey/mirrors.xml"
$mirrorpath = $mirrors.Mirrors.Mirror.mirrorpath

$languages = irm "$mirrorpath/api/$apikey/languages.xml"
$english = $languages.Languages.Language | ? name -eq English

$currenttime = irm "http://thetvdb.com/api/Updates.php?type=none"

$series = [ordered]@{
    "Alpha House" =  77666
    "The Amazing Race" =  269008
    "The Walking Dead" = 153021
    "Almost Human" = 267702
    "Survivor" = 76733
    "Revolution" = 258823
}

$Data = foreach ($s in $series.keys.GetEnumerator())
{
    $episodes = irm "$mirrorpath/api/$apikey/series/$($series[$s])/all/" | select -expandproperty Data
    $episodes.Episode | select @{l="Series";e={$s}}, @{l="FirstAired";e={Get-Date $_.FirstAired}}, SeasonNumber, EpisodeName | Write-Output
}

