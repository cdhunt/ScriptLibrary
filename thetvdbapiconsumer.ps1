# http://thetvdb.com/wiki/index.php?title=Programmers_API
$apikey = '123'

# Separate the mirrors using the typemask field, as documented for mirrors.xml.
# 1 xml files
# 2 banner files
# 4 zip files
# Select a random mirror from each array (denoted as <mirrorpath_xml>, <mirrorpath_banners>, and <mirrorpath_zip> for rest of example.
$mirrors = irm "http://thetvdb.com/api/$apikey/mirrors.xml"
$mirrorpath = $mirrors.Mirrors.Mirror | ? {$_.typemask -band 1} | Get-Random | select -ExpandProperty mirrorpath

# Save this in your code and allow your users to select their language (denoted as <language> for rest of example). 
# Note: You may also grab this dynamically when needed, but it'll rarely be changed.
$languages = irm "$mirrorpath/api/$apikey/languages.xml"
$english = $languages.Languages.Language | ? name -eq English

# Store this value for later use (denoted as <previoustime> for rest of example)
$currenttime = irm "http://thetvdb.com/api/Updates.php?type=none"

$series = [ordered]@{
    "Alpha House" =  77666
    "The Amazing Race" =  269008
    "The Walking Dead" = 153021
    "Almost Human" = 267702
    "Survivor" = 76733
    "Revolution" = 258823
}

foreach ($s in $series.keys.GetEnumerator())
{
    try
    {
        $episodes = irm "$mirrorpath/api/$apikey/series/$($series[$s])/all/$($english.abbreviation).xml" | select -expandproperty Data
        $episodes.Episode | select @{l="Series";e={$s}}, @{l="FirstAired";e={Get-Date $_.FirstAired}}, SeasonNumber, EpisodeName | Write-Output
    }
    catch
    {
        Write-Warning "Could not access details for $s"
    }
}
