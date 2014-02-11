#Exception calling "TransferData" with "0" argument(s): "ERROR : errorCode=-1071636471 description=SSIS Error Code DTS_E
#_OLEDBERROR.  An OLE DB error has occurred. Error code: 0x80004005.
#An OLE DB record is available.  Source: "Microsoft SQL Server Native Client 10.0"  Hresult: 0x80004005  Description: "T
#he statement has been terminated.".
#An OLE DB record is available.  
#Source: "Microsoft SQL Server Native Client 10.0"  Hresult: 0x80004005  
#Description: "Cannot create a row of size 8170 which is greater than the allowable maximum row size of 8060.".
# helpFile=dtsmsg100.rll helpContext=0 idofInterfaceWithError={C81DFC5A-3B22-4DA3-BD3B-10BF861A7F9C}"
#At line:1 char:35
#+ Measure-Command {$xfr.TransferData <<<< ()}
#    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
#    + FullyQualifiedErrorId : DotNetMethodException

Import-Module SQLPS

$SrcSrv = "12.34.56.78"
$DstSrv = "12.34.56.79"

$Ssrv = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Server $SrcSrv
$Dsrv = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Server $DstSrv
$dbExceptions = "[<AnyDBYouDontWantTransferred]",...
#$ssrvdbs = $Ssrv.Databases | Where-Object {$_.name -eq "<SingleDBToTranfer>"}
$ssrvdbs = $Ssrv.Databases # All DBs.
$DataDriveList = @('D','E','F','G') #Data Drives


$sdb = $null
$sdb = 'working'
# "Option Explicit" 
set-psdebug -strict

foreach($sdb in $ssrvdbs) { 
    if (($dbExceptions -contains $sdb) -eq $false) # Skip DBs in the exception list.
    {
        $tTime = Get-Date

        #$dbname = "$sdb"
		$dbname = 'sandbox'
        $dbname = $dbname.Replace("[", "")
        $dbname = $dbname.Replace("]", "")
		#$sdbObject = $Ssrv.Databases["$dbname"]
		$sdbObject = $Ssrv.Databases["$sdb"]
        Write-host -ForegroundColor Yellow $tTime ": Starting DB: "$dbname

        #If destination db does not exist, create it
        $dstdb = $dsrv.Databases["$dbname"]
        if (!$dstdb)  
        {          			
			$sourceDataUsage = $sdbObject.DataSpaceUsage + $sdbObject.IndexSpaceUsage
					
			#Region Configure FileGroup
			$dataFileLocationFolder = ':\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\'
			$logFileLocation = 'H:\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\'

			# Instantiate the database object and add the filegroups
			$dbCopy = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Database -argumentlist $dsrv, "$dbname"
			$sysfg = new-object ('Microsoft.SqlServer.Management.Smo.FileGroup') ($dbCopy, 'PRIMARY')
			#$sysfg.IsDefault = $true		
			$dbCopy.FileGroups.Add($sysfg)
			
			[int]$n = 0
			foreach ($DriveLetter in $DataDriveList)
			{	
				$dataFileName = "$dbname$n"
				$dataFilePath = "$DriveLetter$dataFileLocationFolder$dataFileName.mdf"
				$dbdsysfile = new-object ('Microsoft.SqlServer.Management.Smo.DataFile') ($sysfg, $dataFileName)				
				$dbdsysfile.FileName = $dataFilePath
				$dbdsysfile.Size = $sourceDataUsage/($DataDriveList.count)
				$dbdsysfile.GrowthType = 'KB'
				$dbdsysfile.Growth = 102400.0
				#$dbdsysfile.IsPrimaryFile = 'True'			
				$sysfg.Files.Add($dbdsysfile)
				$n++
			}
			

			# Create the file for the log
			$logFileName = "$($dbname)_Log"
			$logFilePath = "$logFileLocation$logFileName.ldf"
			$dblfile = new-object ('Microsoft.SqlServer.Management.Smo.LogFile') ($dbCopy, $logFileName)	
			$dbCopy.LogFiles.Add($dblfile)	
			$dblfile.FileName = $logFilePath
			$dblfile.Size = [double](6.0 * 1024.0)  #in KB
			$dblfile.GrowthType = 'Percent'
			$dblfile.Growth = 10.0
					
			#Endregion
			
            $dbCopy.Create()
			
			#TODO: List Users, Let user select
#			USE [sandbox]
#			GO
#			CREATE USER [sandboxuser] FOR LOGIN [sandboxuser]
#			EXEC sp_addrolemember N'db_owner', N'sandboxuser'
#			GO

			$createLoginSQL = Invoke-sqlcmd -ServerInstance $Ssrv -Database 'master' -Query "exec sp_help_revlogin '$dbname'"
			if ($createLoginSQL -ne 'No login(s) found.')
			{
				Invoke-sqlcmd -ServerInstance $DstSrv -Database 'master' -Query $createLoginSQL
			}
			else
			{
				Write-Host -ForegroundColor Yellow "Couldn't find login name that matches DB name. You will have to create login manually."
			}			
			
            $dstdb = $dsrv.Databases["$dbname"]
        }
		
		
            
        # Set recovery mode to simple for the transfer
        $dstdb.DatabaseOptions.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple
		$dstdb.AutoUpdateStatisticsEnabled = $false

        # Set Quoted Identifiers
#        $dstdb.DatabaseOptions.QuotedIdentifiersEnabled = $true
#        $dstdb.DatabaseOptions.AnsiNullsEnabled = $true
#        $dstdb.DatabaseOptions.AnsiWarningsEnabled = $true
#        $dstdb.DatabaseOptions.ArithmeticAbortEnabled = $true
#        $dstdb.DatabaseOptions.ConcatenateNullYieldsNull = $true

        # Apply new settings
        $dstdb.Alter()

        # Here, do anything that needs to be done Pre-transfer on Source Server and/or Destination Server
        # For example, I had an unique constraint on a computed column. For whatever reason, this transfer class
        # connects with QuotedIdentifier OFF, which prevents the Unique constraint from being created (also, crashes
        # the transfer. So I drop the constraint at the source, and re-create it post transfer using Invoke-SqlCmd
        # on a SQL script.

		#http://msdn.microsoft.com/en-us/library/ms210363.aspx
		$Ssrv.SetDefaultInitFields($true)

        #Define a Transfer object and set the required options and properties.
        $xfr = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Transfer -argumentlist $sdbObject
		
        #Define a container for the objects to transfer.
        #$moving_box = New-Object -TypeName "System.Collections.ArrayList"

        # Set Destination options
        $xfr.DestinationDatabase = $dbname
        $xfr.DestinationServer = $Dsrv.Name
        $xfr.DestinationLoginSecure = $true

        #Transfer object properties
        $xfr.PreserveDbo = $true
        $xfr.DropDestinationObjectsFirst = $true
        $xfr.CopyAllObjects = $true
#        $xfr.CopyAllDatabaseTriggers = $true
#        $xfr.CopyAllDefaults = $true
#        $xfr.CopyAllStoredProcedures = $true
#        $xfr.CopyAllTables = $true
#        $xfr.CopyAllUserDefinedFunctions = $true
#        $xfr.CopyAllUserDefinedTableTypes = $true
#        $xfr.CopyAllViews = $false
#        $xfr.CopyData = $true
#        $xfr.CopyAllRoles = $true
#        $xfr.CopyAllSchemas = $false
#        $xfr.CopyAllLogins = $false
#        $xfr.CopyAllUsers = $false
#        $xfr.CopySchema = $false

        # Transfer object options
        $xfr.Options.DriAll = $true
        $xfr.Options.DriForeignKeys = $true
        $xfr.Options.DriUniqueKeys = $true
        $xfr.Options.DriChecks = $true
        $xfr.Options.DriUniqueKeys = $true
        $xfr.Options.Triggers = $true
        $xfr.Options.Permissions = $true
        $xfr.Options.ClusteredIndexes = $true
        $xfr.Options.NonClusteredIndexes = $true
        $xfr.Options.AllowSystemObjects = $false
#        $xfr.Options.IncludeDatabaseRoleMemberships = $false
        $xfr.Options.ContinueScriptingOnError = $true
        $xfr.Options.WithDependencies = $false

        # This section was necessary for a couple of reasons: simply setting the transfer object properties (the lines above
        # which are commented out, and begin with $xfr.CopyAllxxx) resulted in objects being scripted in the wrong order,
        # i.e., functions failing on create because the underlying tables had not yet been created.

        #Objects to copy
#        $sdb.Roles | where {$_.IsFixedRole -eq $false -and $_.name -ne "public"} | foreach {$null = $moving_box.Add($_)}
        #$sdb.Tables | where {$_.IsSystemObject -eq $false} | foreach {$null = $moving_box.Add($_)}
#        $sdb.UserDefinedFunctions | where {$_.IsSystemObject -eq $false} | foreach {$null = $moving_box.Add($_)}
#        $sdb.StoredProcedures | where {$_.IsSystemObject -eq $false} | foreach {$null = $moving_box.Add($_)}
#        $sdb.Views | where {$_.IsSystemObject -eq $false} | foreach {$null = $moving_box.Add($_)}

        #$xfr.ObjectList = $moving_box
        $xfr.TransferData()


        #Invoke-sqlcmd -ServerInstance $DstSrv -Database $dbname -Query $Command

        # Any post-transfer stuff goes here, for instance, my dropped Unique constraint from above, 
        # re-created on Source and Destination DBs.

        # Set recovery model back to Full, other DB options
        $dstdb.DatabaseOptions.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Full
		$dstdb.AutoUpdateStatisticsEnabled = $true
        $dstdb.Alter()
        
        $tTime = Get-Date
        Write-host -BackgroundColor Green $tTime ": Completed DB: "$dbname
        }
    }
