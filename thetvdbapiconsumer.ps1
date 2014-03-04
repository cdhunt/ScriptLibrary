Import-Module PowerYaml
# http://thetvdb.com/wiki/index.php?title=Programmers_API
$apikey = '123'

$mirrors = irm "http://thetvdb.com/api/$apikey/mirrors.xml"
$mirrorpath = $mirrors.Mirrors.Mirror.mirrorpath

$languages = irm "$mirrorpath/api/$apikey/languages.xml"
$english = $languages.Languages.Language | ? name -eq English

$currenttime = irm "http://thetvdb.com/api/Updates.php?type=none"

$series = get-yaml -FromFile C:\Dropbox\Projects\tvdbshows.yaml

$Data = foreach ($s in $series.keys.GetEnumerator())
{
    $eposodes = irm "$mirrorpath/api/$apikey/series/$($series[$s])/all/" | select -expandproperty Data
}



