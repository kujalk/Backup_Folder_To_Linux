# Backup_Folder_To_Linux

This script is used to zip and upload a folder from Windows machine to destination Linux machine

I have written the script and tested it against an AWS EC2 Linux server and verified it's working properly.

Requirements,

1. Install PoSH-SSH module in PowerShell
- Open Powershell as Administrator
- Install-Module -Name Posh-SSH

2. Change the following parameters inside the script [Line no - 137 - 143 ]
    - $source_folder="D:\Backup_Scripts\Demo\"
    - $zip_store="D:\Backup_Scripts\"
    - $linux_server="54.251.167.26"
    - $ssh_key="D:\AWS\jana-ssh.pem" -> If you want to use SSH key
    - $linux_folder="/home/ec2-user"
    - $linux_user="ec2-user" -> If you want to use SSH key (username to connect with server)
    - $cred=Get-credential -> Only if you want to authenticate with Username and Password

+ source folder - Folder you want to take backup (Make sure to include "\" at the end)
+ zip_store - Folder where you want to store the compress folder
+ linux_server= DNS name / IP address of your linux server
+ linux_folder= Linux folder location where you want to store the compressed folder
+ ssh_key=SSH key to connect with user
+ linux_user= If you want to use SSH key (username to connect with server)
+ cred= It will auto-prompt to feed  your linux username and password (If SSH is not used)

Additional Notes -

1. Log will be stored under "C:\Temp" location [If folder does not exist, it will create it]

2. The script can support 
* Username and Password authentication (Disabled at the moment)
*  SSH key (Enabled at the moment)

3. Better approach, to use SSH key for authentication. If username/password is going to be used, then uncomment the section in upload function in the script.

4. After uploading the compressed  folder to destination, the script will delete the compressed folder from source location.

Best Regards,
Jana

