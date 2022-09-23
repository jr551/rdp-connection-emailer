
$event = Get-WinEvent -FilterXml ([xml](Get-Content rdp_query.xml)) | where {$_.Id -eq 302} | where { $_.TimeCreated -gt (Get-Date).AddHours(-24) }
$event | Format-Table
$ntDomain = "MAHCOMPANY"
$yourEmailDomain = "itsmycompany.co.uk"

Remove-Item "$($env:TEMP)\*.login_email_temp"

foreach ($ev in $event)
{

    $line = $ev.Message
        Write-Host $line
        #if ($line.ToString().Contains("Account Name:") -And (-Not $line.ToString().Contains("$")) -And (-Not $line.ToString().Contains("-")) -And (-Not $line.ToString().Contains("SYSTEM"))  ){
            $index1 = $line.IndexOf($ntDomain) 

            $index2 = $line.IndexOf('"', $index1)
            $index3 = $line.IndexOf(", connected") 

            $index1 = $index1 + 10
            $cleanUsername = $line.Substring($index1,($index2-$index1) )

            $line = $line.Substring(0, $index3)

            $tempPath = "$($env:TEMP)\$($cleanUsername).login_email_temp"
            if (Test-Path -Path $tempPath)
            {

               "<i>Time of Login:</i><br> $($ev.TimeCreated) - $($line)<br><hr>"  | Out-File -FilePath $tempPath -Append
            }
            else
            {

                New-Item $tempPath
                "<i>Time of Login:</i><br> $($ev.TimeCreated) - $($line)<br><hr>" | Out-File -FilePath $tempPath
            }


}

Rename-Item "$($env:TEMP)\administrator.login_email_temp" "$($env:TEMP)\ict_support.login_email_temp"

$files = Get-ChildItem -Path $($env:TEMP) -Filter *.login_email_temp

foreach ($file in $files)
{
    $email = $file.Name.Replace(".login_email_temp", "") + "@" + $yourEmailDomain
    Write-Host $email
   
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }


    $EmailFrom = "Remote Desktop Usage.<remotedesktopservice@"+ $yourEmailDomain+ ">"
    $EmailTo = $email

    if ($EmailTo -eq "ict_support@"+$yourEmailDomain){
        $Subject = "Administrator Logged in Alert for IT DEPT"}
    else{
        $Subject = "You recently connected?"}

    $Body = "<h1>You connected to remote desktop recently.</h1><br>Your connection history is below for the last 24 hours.<br><h2><span style='color:red'>If this was not you</b> contact IT Dept ASAP</h2></span><br><b>This is for your information only, <u>by reviewing the below you are helping to keep the network safer.</u></b> You will only get sent this email if you connect and only once a day.<br>I got this from github <br><br>"
    $Body = $Body + (Get-Content -Path "$($env:TEMP)\\$($file)")

    

    $SMTPServer = "srv-smtp01"
    $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)   
    $SMTPClient.EnableSsl = $true    

    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential("hi", "sausages") 
      
    $mail = New-Object System.Net.Mail.Mailmessage $EmailFrom, $EmailTo, $Subject, $Body
    $mail.IsBodyHTML=$true

    $SMTPClient.Send($mail)

}
