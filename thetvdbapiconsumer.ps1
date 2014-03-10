# https://bitbucket.org/gfkeogh/simpledb/wiki/Home
Add-Type -Path C:\Scripts\Modules\SimpleDb\SimpleDb.Esent.dll

# Data Model
$episodeClass = @"
using System;
public class Episode
{
    public string Series { get; set; }
    public int Id { get; set; }
    public int SeriesId { get; set; }    
    public DateTime? FirstAired { get; set; }
    public int? SeasonNumber { get; set; }
    public string EpisodeName { get; set; }
    public int? PreviousTime { get; set; }
}
"@
Add-Type -TypeDefinition $episodeClass -Language CSharp

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

$db = New-Object SimpleDb.SimpleDatabase
$db.Open('C:\temp\simpledb')

try
    {

    foreach ($s in $series.keys.GetEnumerator())
    {
        try
        {
            $episodes = irm "$mirrorpath/api/$apikey/series/$($series[$s])/all/$($english.abbreviation).xml" | select -expandproperty Data
            #$episodes.Episode | select @{l="Series";e={$s}}, @{l="FirstAired";e={Get-Date $_.FirstAired}}, SeasonNumber, EpisodeName | Write-Output
            foreach ($e in $episodes.Episode)
            {
                $episodeObject = New-Object Episode
                $episodeObject.Series = $s
                $episodeObject.Id = $e.id
                $episodeObject.SeriesId = $series[$s]
                try {$episodeObject.FirstAired = Get-Date $e.FirstAired} catch {$null}
                $episodeObject.SeasonNumber = $e.SeasonNumber
                $episodeObject.EpisodeName = $e.EpisodeName
                $episodeObject.PreviousTime = $currenttime.Items.Time

                $episodeObject | Write-Output
                # True if the key already existed. False if a new key was inserted.
                $newKey = $db.Put($e.id, $episodeObject)
            }
        }
        catch
        {
            Write-Warning "Could not access details for $s"
            $_
        }
    }

    # Get by Episode ID
    # $idById =  $db.GetType().GetMethod("Get").MakeGenericMethod([Episode])
    # $idById.invoke($db, 4808568)

    # Gets all objects that contain an SeasonNumber field
    # $fieldSearch =  $db.GetType().GetMethod("ListByName").MakeGenericMethod([Episode])
    # $fieldSearch.invoke($db, "SeasonNumber")

    # Search by Episode ID, same as above basically
    # $idSearch = $db.GetType().GetMethod("ListByNameFiltered").MakeGenericMethod([Episode],[int])
    # $idSearch.Invoke($db, @("Id", [predicate[int]]{ param([int]$num); $num -eq 4808568 }))

    # Search by Series Name
    # $seriesSearch = $db.GetType().GetMethod("ListByNameFiltered").MakeGenericMethod([Episode],[string])
    # $seriesSearch.Invoke($db, @("Series", [predicate[string]]{ param([string]$str); $str -eq 'Revolution' }))

}
catch
{
    $_
}
finally
{
    $db.Dispose()
}