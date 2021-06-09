function GetPackagesFrom-File {
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        [string] $ProjectFilePath, 
        [Parameter(Mandatory = $false)]
        [bool] $IncludeMicrosoftPackages = $false
    )

    $projectcontent = Get-Content -Path $ProjectFilePath

    ## Get List of packages
    $packagelist = $projectcontent |  Find "<PackageReference Include"  | Sort-Object -Unique
    
    ## Walk Through packages
    foreach ($package in $packagelist) {
        
        $packagesplit = $package.Split('"')
        $packagename = $packagesplit[1]
        $packageversion = $packagesplit[3]
        
        ## Find info about package
        $packageinfo = Find-Package -ProviderName nuget -Name $packagename -RequiredVersion $packageversion -ErrorAction SilentlyContinue

        ## Return licensed packages by looking at requireLicenseAcceptance="True"
        if ($packageinfo) {
            
            $text = [xml]$packageinfo.SwidTagText
            $licenseacceptance = $text.GetElementsByTagName("Meta").requireLicenseAcceptance

            $Authors = $text.GetElementsByTagName("Meta").Authors

            if ($licenseacceptance -eq "True" ) {

                $licenseuri = $text.GetElementsByTagName("Link").href | where{$_ -like "*license*"}

                if ($IncludeMicrosoftPackages) {
                    
                    Write-Output "Package $($packagename) version $($packageversion) requires license published at $($licenseuri)"
                }
                else {
                    if ($Authors) {
                        if ($Authors.contains("Microsoft")) {
    
                        }
                        else {
                            Write-Output "Package $($packagename) version $($packageversion) requires license published at $($licenseuri)"
                        }
    
                    }
                    else {
                        Write-Output "Package $($packagename) version $($packageversion) requires license published at $($licenseuri)"
                    }
                }
                
            }
        }

    }
    
}

function Find-LicensedPackages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ParameterSetName = 'FilePath',
            HelpMessage = 'Enter csproj file name',
            Position = 0)]
        [string] $FilePath,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'DirectoryPath',
            HelpMessage = 'Enter Directory Path'
        )]
        [string] $DirectoryPath,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'DirectoryPath'
        )]
        [Parameter(Mandatory = $false,
            ParameterSetName = 'FilePath') ]
        [bool] $IncludeMSPackages = $false

    )
    
    begin {
        
        ## Check ig nuget provider is available on the machine
        if (!(Get-PackageProvider).Name.contains("NuGet")) {
            ## If not install it 
            Install-PackageProvider -Name "NuGet" -RequiredVersion "3.0.0.1" -Force
        }
    }
    
    process {

        ## Check if FileName parameter was passed
        if ($PSBoundParameters.ContainsKey('FilePath')) {
            ## Process for single file
            GetPackagesFrom-File -ProjectFilePath $FilePath -IncludeMicrosoftPackages $IncludeMSPackages
        }

        ## Check if DirectoryPat was passed
        if ($PSBoundParameters.ContainsKey('DirectoryPath')) {

            ## Process for the directory
            ## Get List of project files (.csproj)
            $projectfiles = Get-ChildItem -Path $DirectoryPath | where { $_.Extension -eq ".csproj" }

            ## Walk through each project file
            foreach ($projectfile in $projectfiles) {
                GetPackagesFrom-File -ProjectFilePath $projectfile.FullName -IncludeMicrosoftPackages $IncludeMSPackages
            }

        }        
    }
    
    end {
        
    }
}

Export-ModuleMember -Function Find-LicensedPackages
