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
            <#
            Set-SCPFile -ComputerName $remote_machine -Credential $credential `
            -LocalFile $local_folder -RemotePath $remote_folder -AcceptKey $true -EA Stop
            #>

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

            return $true
            
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
        return $false
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
        return $true
    }
    catch 
    {
        logging -message "Error occured while deleting the zipped folder $_" -level "Error"
        return $false
    }
}

#####################
#   Main Program    #
#####################

try
{
    $source_folder="D:\Sample\"
    $zip_store="D:\Backup_Scripts\"
    $linux_server="10.10.41.199"
    $ssh_key="D:\AWS\janatemp-ssh.pem"
    $linux_folder="/home/ec2-user"
    $linux_user="ec2-user"
    #$cred=Get-credential

    logging -message "Backup Script initiated" -level "Info"

    #Compress the folder
    $zip_name=compress -sourcepath $source_folder -destinationpath $zip_store

    if($zip_name -ne $null)
    {

        #With SSH key
        
        $result=upload -local_folder $zip_name -remote_folder $linux_folder `
        -remote_machine $linux_server -keyfile $ssh_key -username $linux_user
        

        #With Username and Password
        <#
        $result=upload -local_folder $zip_name -remote_folder $linux_folder `
        -remote_machine $linux_server -credential $cred
        #>

        #Delete zipped folder after upload
        $del_result=delete_zipfolder $zip_name

        if($result -and $del_result)
        {
            logging -message "Script completed successfully" -level "Info"
        }
        else 
        {
            logging -message "Script does not completed successfully" -level "Warning"    
        }
    
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