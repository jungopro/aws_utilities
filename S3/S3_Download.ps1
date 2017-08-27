<#
    .SYNOPSIS
        Download Data from a folder inside S3 bucket to a local folder

    .DESCRIPTION
        Download Data from a folder inside S3 bucket to a local folder

    .PARAMETER AccessKey
        Your account access key - must have read access to your S3 Bucket

    .PARAMETER SecretKey
        Your account secret access key

    .PARAMETER Region
        The region associated with your bucket e.g. eu-west-1, us-east-1 etc.
        (see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-regions)

    .PARAMETER BucketName
        The name of your S3 Bucket

    .PARAMETER KeyPrefix
        Path to the folder to download on the S3 bucket. Use /path/to/folder syntax

    .PARAMETER LocalPath
        Path to local folder on your machine to download the data to. User C:\Path\to\Folder syntax

    .PARAMETER logPath
        Location to save the script log file

    .INPUTS
      Parameters above

    .OUTPUTS
      Log file stored in $logPath

    .NOTES
      Version:        1.0
      Author:         Omer Barel
      Creation Date:  July 31, 2017
      Purpose/Change: Initial script development
    
    .EXAMPLE
      S3_Download.ps1 -AccessKey ABCDEFG -SecretKey HIJKLMNOP -Region us-east-1 - BucketName mybucket -KeyPrefix /mybucektfolder -LocalPath C:\Downloads -logPath C:\Logs\s3.log

#>

#Parameters
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)] # AWS Access Key
  [string]$AccessKey,
   
  [Parameter(Mandatory=$True,Position=2)] # AWS Secret Key
  [string]$SecretKey,

  [Parameter(Mandatory=$False,Position=3)] # Bucket Region
  [string]$Region,

  [Parameter(Mandatory=$True,Position=4)] # Bucket Name
  [string]$BucketName,

  [Parameter(Mandatory=$True,Position=5)] # Bucket Folder
  [string]$KeyPrefix,

  [Parameter(Mandatory=$True,Position=6)] # Local Folder
  [string]$LocalPath,

  [Parameter(Mandatory=$True,Position=7)] # Lg location
  [string]$logPath
)
function Write-Log {
    <#
        .Synopsis
        Write-Log writes a message to a specified log file with the current time stamp.
        .DESCRIPTION
        The Write-Log function is designed to add logging capability to other scripts.
        In addition to writing output and/or verbose you can write to a log file for
        later debugging.
        .NOTES
        Created by: Jason Wasser @wasserja
        Modified: 11/24/2015 09:30:19 AM  

        Changelog:
            * Code simplification and clarification - thanks to @juneb_get_help
            * Added documentation.
            * Renamed LogPath parameter to Path to keep it standard - thanks to @JeffHicks
            * Revised the Force switch to work as it should - thanks to @JeffHicks

        To Do:
            * Add error handling if trying to create a log file in a inaccessible location.
            * Add ability to write $Message to $Verbose or $Error pipelines to eliminate
            duplicates.
        .PARAMETER Message
        Message is the content that you wish to add to the log file. 
        .PARAMETER Path
        The path to the log file to which you would like to write. By default the function will 
        create the path and file if it does not exist. 
        .PARAMETER Level
        Specify the criticality of the log information being written to the log (i.e. Error, Warning, Informational)
        .PARAMETER NoClobber
        Use NoClobber if you do not wish to overwrite an existing file.
        .EXAMPLE
        Write-Log -Message 'Log message' 
        Writes the message to c:\Logs\PowerShellLog.log.
        .EXAMPLE
        Write-Log -Message 'Restarting Server.' -Path c:\Logs\Scriptoutput.log
        Writes the content to the specified log file and creates the path and file specified. 
        .EXAMPLE
        Write-Log -Message 'Folder does not exist.' -Path c:\Logs\Script.log -Level Error
        Writes the message to the specified log file as an error message, and writes the message to the error pipeline.
        .LINK
        https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path='C:\Logs\PowerShellLog.log',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level="Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        
        # If the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            # Nothing to see here yet.
            }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
                }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
                }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
                }
            }
        
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
}

Import-Module AWSPowerShell

Write-Log -Message 'Initialize Log.' -Path $logpath
Write-Log -Message 'Getting list of objects to download...' -Path $logpath
$objects = Get-S3Object -BucketName $BucketName -KeyPrefix $KeyPrefix -AccessKey $AccessKey -SecretKey $SecretKey -Region $Region

foreach($object in $objects) {
    $localFileName = $object.Key -replace $keyPrefix, ''
    if ($LocalFileName -ne '') {
        $LocalFilePath = Join-Path $LocalPath $LocalFileName
        Write-Log -Message "Copying $LocalFileName from $BucketName to $LocalFilePath " -Path $logpath
        try {
            Copy-S3Object -BucketName $BucketName -Key $object.Key -LocalFile $LocalFilePath -AccessKey $AccessKey -SecretKey $SecretKey -Region $Region
        }
        catch {
            Write-Log -Message "Couldn't copy $LocalFileName from $BucketName to $LocalFilePath " -Path $logpath
        }        
    }
}
$Time=Get-Date
Write-Log "Script run at $Time" -Path $logpath