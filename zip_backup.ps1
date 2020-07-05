<#
Purpose - To Zip a folder and upload it to a destination Linux machine
Requirements - 
    1. SSH key to Linux server or username/password to login
    2. Posh-SSH Module [Install-Module -Name Posh-SSH]

Developer - K.Janarthanan
Date - 5/7/2020
Version - 1

#>

function logging
{
    param(
    [string] $message,
    [string] $level
    )

    if(!(Test-Path -path 'C:\Temp'))
    {
        mkdir -Path 'C:\Temp'
    }
    
    $current_time = Get-Date -Format "dd-MM-yyyy hh:mm:ss tt"
    "$current_time [$level] : $message" >> C:\Temp\Zip_Backup.log
}

function compress
{
    param(
        [string] $sourcepath,
        [string] $destinationpath
    )

    try
    {
        $temp_name = Get-Date -Format "dd-MM-yyyy-hh-mm-ss-tt"
        $zipped_folder = $destinationpath+$temp_name+".zip"

        logging -message "Zipped folder will be named as $zipped_folder" -level "Info"
        logging -message "Starting to compress folder" -level "Info"
        Compress-Archive -Path $sourcepath -DestinationPath $zipped_folder -EA Stop
        logging -message "Finished compressing folder" -level "Info"

        return $zipped_folder
    }
    catch
    {
        $error_msg="Compressing folder has failed $_"
        logging -message $error_msg -level "Error"
        return $null
    }
   
}

function upload
{
    param(
        [string] $local_folder,
        [string] $remote_folder,
        [string] $remote_machine,
        [pscredential] $credential,
        [string] $keyfile,
        [string] $username
    )

    try 
    {
        if (Get-Module -ListAvailable -Name "Posh-SSH") 
        {
            #######################
            #   With Credential   #
            #######################
            #Set-SCPFile -ComputerName $remote_machine -Credential $credential `
            #-LocalFile $local_folder -RemotePath $remote_folder -AcceptKey $true -EA Stop

            #################
            #   With Key    #
            #################
            <#
            Even with SSH key, the username of the remote server must be supplied as PSCredential object. 
            Since this object can't be created without password argument, creating a dummy password. 
            #>
            $password= ConvertTo-SecureString -String "Null" -AsPlainText -Force
            [pscredential]$user_server= New-Object System.Management.Automation.PSCredential ($username,$password)

            Set-SCPFile -ComputerName $remote_machine -Credential $user_server `
            -KeyFile $keyfile -LocalFile $local_folder -RemotePath $remote_folder `
            -AcceptKey $true -EA Stop
        } 
        else 
        {
            throw "Module Posh-SSH is not installed, Please install it"
        }
    }
    catch 
    {
        $error_msg="Upload folder has failed $_"
        logging -message $error_msg -level "Error"
    }

}

function delete_zipfolder
{
    param(
        [string] $zipfolder
    )
    
    try 
    {
        Remove-Item -path $zipfolder -Confirm:$false -Force -EA Stop
        logging -message "Deleted the Zipped folder from the source location" -level "Info"
    }
    catch 
    {
        logging -message "Error occured while deleting the zipped folder $_" -level "Error"
    }
}

#####################
#   Main Program    #
#####################

try
{
    logging -message "Backup Script initiated" -level "Info"
    $zip_name=compress -sourcepath "D:\Backup_Scripts\Demo\" -destinationpath "D:\Backup_Scripts\"

    if($zip_name -ne $null)
    {
        #$cre=Get-credential

        #With SSH key
        upload -local_folder $zip_name -remote_folder "/home/ec2-user" `
        -remote_machine "54.251.167.26" -keyfile "D:\AWS\jana-ssh.pem" -username "ec2-user"

        delete_zipfolder $zip_name
    }
    else 
    {
        throw "Unable to upload the folder to destination because Compression stage has failed"
    }

}
catch
{
    logging -message "Error occured $_" -level "Error"
}