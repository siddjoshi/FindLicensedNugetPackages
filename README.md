# FindLicensedNugetPackages
PowerShell Script to find licensed nuget packages used in a visual studio project

## It can be used with the .csproj file or the directory containing the .csproject files. 

First import the module 
Import-Module .\Find-LicensedPackages.psm1

After importing , you can run Find-LicensedPackages -FilePath .\test.csproj 
To include Microsoft packages you can run Find-LicensedPackages -FilePath .\test.csproj  -IncludeMSPackages $true

To run it on directory, Find-LicensedPackages -DirectoryPath c:\mytestproject 
