Add-Type -Path "C:\Program Files (x86)\MongoDB\CSharpDriver 1.0\MongoDB.Bson.dll"
Add-Type -Path "C:\Program Files (x86)\MongoDB\CSharpDriver 1.0\MongoDB.Driver.dll"

$connectionString = "mongodb://localhost/test"

try {
    [MongoDB.Driver.MongoDatabase] $db = [MongoDB.Driver.MongoDatabase]::Create($connectionString);
    [MongoDB.Bson.BsonDocument] $doc2 = @{};
    $doc2["_id"] = [MongoDB.Bson.ObjectId]::GenerateNewId();
    $doc2["FirstName"] = "Justin2";
    $doc2["LastName"] = "Dearing2";
    $doc2["PhoneNumbers"] = [MongoDB.Bson.BsonDocument] @{
        'Home'= '718-641-20982';
        'Mobile'= '646-288-56212';
    };
    $doc;
    # Download Invoke-GenericMethod.ps1 from http://pastebin.com/dRqZd0AA modified version of script available here http://www.leeholmes.com/blog/2007/06/19/invoking-generic-methods-on-non-generic-classes-in-powershell/    
    Invoke-GenericMethod $db["test"] Find MongoDB.Bson.BsonDocument $query;

} catch [Exception] {
    $_.Exception.ToString();
}

