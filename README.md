ScriptLibrary
=============

A random collection of unrelated scripts I have thrown together over 10 years of messing around with Powershell.

tl;dr Use at your own risk.

I don't make any promsies that any of these scripts work as expected. They are the result of hacking sessions to understand how feature of Powershell or 3rd party components work.

You might find one of these snippets a useful starting point for some problem you have, but the code most likely does not conform with best practices and was probably not performance tested.


### Files

* **Compress-Files.psm1**: Simple 7zip command line wrapper
* **Copy-SQLDatabase.ps1**: Copy a SQL DB using the SMO TransferData method.
* **CouchDB.psm1**: Working with CouchDB API.
* **Create-CertRequest.ps1**: Generate a new Certificate Signing Request using CertReq.exe.
* **Create-Database.ps1**: Create a new SQL DB using SMO.
* **Example-MongoDb.ps1**: Working with BSOD documents in MongoDB with the CSharpDriver.
* **Functions-SSL.ps1**: Wrapper for OpenSSL to generate new SSL certificates.
* **Humanizer.psm1**: Some functions to quickly enable [Humanizer](http://humanizr.net/ "Humanizer") functionality in Powershell.
* **Invoke-GenericMethod.ps1**: Invoke a generic method on a non-generic type.
* **New-GenericObject.ps1**: Creates an object of a generic type.
* **Note-WinSCP.ps1**: Working with WinSCP API.
* **Notes-DateFormats.ps1**: Example of DateTime format strings.
* **Notes-ESENT.ps1**: Basic example of working with [ESENT](http://en.wikipedia.org/wiki/ESENT "Extensible Storage Engine") data storage engine.
* **Notes-S3Sync.ps1**: Messing with AWSPowerShell.
* **Notes-SubnetCalculator.ps1**: Not very useful Subnet calculator.
* **OneTimeSecret.psm1**: OneTimeSecret.com create API.
* **thetvdbapiconsumer**: Working with [TheTVDB.com](http://thetvdb.com/wiki/index.php?title=Programmers_API) XML API and using [SimpleDB](https://bitbucket.org/gfkeogh/simpledb/wiki/Home "SimpleDB"), an [ESENT](http://en.wikipedia.org/wiki/ESENT "Extensible Storage Engine") based datastore.
