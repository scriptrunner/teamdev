﻿#Requires -Version 4.0
#Requires -Modules ActiveDirectory

<#
    .SYNOPSIS
        Creates a user in the OU path
    
    .DESCRIPTION  

    .NOTES
        This PowerShell script was developed and optimized for ScriptRunner. The use of the scripts requires ScriptRunner. 
        The customer or user is authorized to copy the script from the repository and use them in ScriptRunner. 
        The terms of use for ScriptRunner do not apply to this script. In particular, AppSphere AG assumes no liability for the function, 
        the use and the consequences of the use of this freely available script.
        PowerShell is a product of Microsoft Corporation. ScriptRunner is a product of AppSphere AG.
        © AppSphere AG

    .COMPONENT
        Requires Module ActiveDirectory

    .LINK
        https://github.com/scriptrunner/ActionPacks/tree/master/ActiveDirectory/Users

    .Parameter OUPath
        Specifies the AD path

    .Parameter GivenName
        Specifies the user's given name

    .Parameter Surname
        Specifies the user's last name or surname

    .Parameter Password
        Specifies a new password value for an account

    .Parameter DomainAccount
        Active Directory Credential for remote execution without CredSSP

    .Parameter SAMAccountName
        Specifies the Security Account Manager (SAM) account name of the user

    .Parameter UserPrincipalname
        Specifies the user principal name (UPN) in the format <user>@<DNS-domain-name>
        
    .Parameter UserName
        Specifies the name of the new user

    .Parameter DisplayName
        Specifies the display name of the user
    
    .Parameter Description
        Specifies a description of the user

    .Parameter EmailAddress
        Specifies the user's e-mail address

    .Parameter ChangePasswordAtLogon
        Specifies whether a password must be changed during the next logon attempt

    .Parameter CannotChangePassword
        Specifies whether the account password can be changed

    .Parameter PasswordNeverExpires
        Specifies whether the password of an account can expire

    .Parameter Department
        Specifies the user's department

    .Parameter Company
        Specifies the user's company

    .Parameter PostalCode
        Specifies the user's postal code or zip code

    .Parameter City
        Specifies the user's town or city

    .Parameter Street
        Specifies the user's street address

    .Parameter DomainName
        Name of Active Directory Domain
    
    .Parameter AuthType
        Specifies the authentication method to use
#>

param(    
    [Parameter(Mandatory = $true,ParameterSetName = "Local or Remote DC")]
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [string]$OUPath,   
    [Parameter(Mandatory = $true,ParameterSetName = "Local or Remote DC")]
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [string]$GivenName,
    [Parameter(Mandatory = $true,ParameterSetName = "Local or Remote DC")]
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [string]$Surname,
    [Parameter(Mandatory = $true,ParameterSetName = "Local or Remote DC")]
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [string]$Password,
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [PSCredential]$DomainAccount,    
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$SAMAccountName,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$UserPrincipalname,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$Username,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$DisplayName,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$Description,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$EmailAddress,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [switch]$ChangePasswordAtLogon,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [switch]$CannotChangePassword,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [switch]$PasswordNeverExpires,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$Department,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$Company,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$PostalCode,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$City,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$Street,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$DomainName,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [ValidateSet('Basic', 'Negotiate')]
    [string]$AuthType="Negotiate"
)

Import-Module ActiveDirectory

try{
    $Script:Pwd = ConvertTo-SecureString $Password -AsPlainText -Force
    $Script:User 
    $Script:Domain
    $Script:Properties =@('GivenName','Surname','SAMAccountName','UserPrincipalname','Name','DisplayName','Description','EmailAddress', 'CannotChangePassword','PasswordNeverExpires' `
                            ,'Department','Company','PostalCode','City','StreetAddress','DistinguishedName')

    if([System.String]::IsNullOrWhiteSpace($SAMAccountName)){
        $SAMAccountName= $GivenName + '.' + $Surname 
    }
    if([System.String]::IsNullOrWhiteSpace($Username)){
        $Username= $GivenName + '_' + $Surname 
    }
    if([System.String]::IsNullOrWhiteSpace($DisplayName)){
        $DisplayName= $GivenName + ', ' + $Surname 
    }
    if($UserPrincipalname.StartsWith('@')){
    $UserPrincipalname = $GivenName + '.' + $Surname + $UserPrincipalname
    }
    if($EmailAddress.StartsWith('@')){
    $EmailAddress = $GivenName + '.' + $Surname + $EmailAddress
    }
    if($PSCmdlet.ParameterSetName  -eq "Remote Jumphost"){
        if([System.String]::IsNullOrWhiteSpace($DomainName)){
            $Script:Domain = Get-ADDomain -Current LocalComputer -AuthType $AuthType -Credential $DomainAccount -ErrorAction Stop
        }
        else{
            $Script:Domain = Get-ADDomain -Identity $DomainName -AuthType $AuthType -Credential $DomainAccount -ErrorAction Stop
        }
    }
    else{
        if([System.String]::IsNullOrWhiteSpace($DomainName)){
            $Script:Domain = Get-ADDomain -Current LocalComputer -AuthType $AuthType  -ErrorAction Stop
        }
        else{
            $Script:Domain = Get-ADDomain -Identity $DomainName -AuthType $AuthType  -ErrorAction Stop
        }
    }
    if($PSCmdlet.ParameterSetName  -eq "Remote Jumphost"){
        $Script:User = New-ADUser -Credential $DomainAccount -Server $Script:Domain.PDCEmulator -Name $UserName -Path $OUPath -Confirm:$false -AuthType $AuthType `
                            -Description $Description -DisplayName $DisplayName -SamAccountName $SAMAccountName -GivenName $GivenName -Surname $Surname `
                            -AccountPassword $Pwd -EmailAddress $EmailAddress -Department $Department -Company $Company -City $City -PostalCode $PostalCode `
                                -ChangePasswordAtLogon $ChangePasswordAtLogon.ToBool() -PasswordNeverExpires $PasswordNeverExpires.ToBool() -CannotChangePassword $CannotChangePassword.ToBool() `
                                -UserPrincipalName $UserPrincipalname -StreetAddress $Street -Enable $true -PassThru -ErrorAction Stop
    }
    else {
        $Script:User = New-ADUser -Server $Script:Domain.PDCEmulator -Name $UserName -Path $OUPath -Confirm:$false -AuthType $AuthType `
                            -Description $Description -DisplayName $DisplayName -SamAccountName $SAMAccountName -GivenName $GivenName -Surname $Surname `
                            -AccountPassword $Pwd -EmailAddress $EmailAddress -Department $Department -Company $Company -City $City -PostalCode $PostalCode `
                            -ChangePasswordAtLogon $ChangePasswordAtLogon.ToBool() -PasswordNeverExpires $PasswordNeverExpires.ToBool() -CannotChangePassword $CannotChangePassword.ToBool() `
                            -UserPrincipalName $UserPrincipalname -StreetAddress $Street -Enable $true  -PassThru -ErrorAction Stop
    }
    if($Script:User){
        Start-Sleep -Seconds 5 # wait
        if($PSCmdlet.ParameterSetName  -eq "Remote Jumphost"){
            $Script:User = Get-ADUser -Identity $SAMAccountName -Properties $Script:Properties -Credential $DomainAccount -AuthType $AuthType -Server $Script:Domain.PDCEmulator
        }
        else{
            $Script:User = Get-ADUser -Identity $SAMAccountName -Properties $Script:Properties -AuthType $AuthType -Server $Script:Domain.PDCEmulator
        }    $res=New-Object 'System.Collections.Generic.Dictionary[string,string]'
        $tmp=($Script:User.DistinguishedName  -split ",",2)[1]
        $res.Add('Path:', $tmp)
        foreach($item in $Script:Properties){
            if(-not [System.String]::IsNullOrWhiteSpace($Script:User[$item])){
                $res.Add($item + ':', $Script:User[$item])
            }
        }
        $Out =@()
        $Out +="User $($GivenName) $($Surname) with follow properties created:"
        $Out +=$res | Format-Table -HideTableHeaders
        if($SRXEnv) {
            $SRXEnv.ResultMessage = $Out
        }
        else {
            Write-Output $Out 
        }    
    }    
}
catch{
    throw
}
finally{
}