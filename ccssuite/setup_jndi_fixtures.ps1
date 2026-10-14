[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$Verify,
    [switch]$ConfirmDisposableInstances,
    [string]$InstallRoot = 'C:\ColdFusion2025'
)

$ErrorActionPreference = 'Stop'
if ($Apply -and $Verify) {
    throw 'Use either -Apply or -Verify, not both.'
}

$instances = @(
    @{ Name = 'cfusion'; Port = 8500; Service = 'ColdFusion 2025 Application Server' },
    @{ Name = 'ccsnode8501'; Port = 8501; Service = 'ColdFusion 2025 Application Server ccsnode8501' },
    @{ Name = 'ccsnode8502'; Port = 8502; Service = 'ColdFusion 2025 Application Server ccsnode8502' },
    @{ Name = 'ccsnode8503'; Port = 8503; Service = 'ColdFusion 2025 Application Server ccsnode8503' }
)
$resourceNames = @('DSN', 'JNDINAME', 'JNDINAME_UPDATED', 'USERNAME', 'PASSWORD', 'DESCRIPTION') |
    ForEach-Object { 'jdbc/CCSSUITE_JNDI_' + $_ }

if ($Verify) {
    foreach ($instance in $instances) {
        $uri = 'http://localhost:{0}/cfsuite/ccssuite/testsuite/DataServices/datasources/_validate.cfm' -f $instance.Port
        $result = Invoke-RestMethod -Uri $uri -TimeoutSec 60
        if (-not $result.PASSED -or $result.CONFIGURATIONWRITES -or $result.CASES.Count -lt 25) {
            throw "Read-only datasource validation failed on port $($instance.Port)."
        }
        $statuses = @($result.JNDIPREREQUISITES.PSObject.Properties |
            ForEach-Object { $_.Value } | ForEach-Object { $_ })
        foreach ($name in $resourceNames) {
            $matching = @($statuses | Where-Object {
                $_.NAME -ceq ('java:comp/env/' + $name) -and $_.AVAILABLE -eq $true -and $_.DATASOURCE -eq $true
            })
            if ($matching.Count -eq 0) {
                throw "Port $($instance.Port): binding unavailable or not javax.sql.DataSource: java:comp/env/$name"
            }
        }
        "PASS $($instance.Port): six JNDI resources resolve; $($result.CASES.Count) read-only cases pass. CCS sync is not verified."
    }
    return
}

if ($Apply) {
    if (-not $ConfirmDisposableInstances) {
        throw 'Live container changes require -ConfirmDisposableInstances.'
    }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this script directly in Windows PowerShell opened with Run as administrator. No changes made.'
    }
}

$driverSource = Join-Path $InstallRoot 'bundles\repo\derby-combined-10.16.1.0.jar'
$driverHash = (Get-FileHash -LiteralPath $driverSource -Algorithm SHA256).Hash
Add-Type -AssemblyName System.IO.Compression.FileSystem
$driverArchive = [IO.Compression.ZipFile]::OpenRead($driverSource)
try {
    foreach ($class in @('org/apache/derby/jdbc/EmbeddedDriver.class', 'org/apache/derby/shared/common/error/StandardException.class')) {
        if (-not $driverArchive.GetEntry($class)) {
            throw "Installed Derby bundle is missing required class: $class"
        }
    }
}
finally {
    $driverArchive.Dispose()
}

$plans = @()
foreach ($instance in $instances) {
    $root = Join-Path $InstallRoot $instance.Name
    $contextPath = Join-Path $root 'runtime\conf\context.xml'
    $driverTarget = Join-Path $root 'runtime\lib\ccssuite-jndi-derby-combined-10.16.1.0.jar'
    $existingDriver = Test-Path -LiteralPath $driverTarget
    if ($existingDriver -and (Get-FileHash -LiteralPath $driverTarget -Algorithm SHA256).Hash -ne $driverHash) {
        throw "Refusing to overwrite an unexpected fixture driver in $($instance.Name)."
    }
    $factoryArchive = [IO.Compression.ZipFile]::OpenRead((Join-Path $root 'runtime\lib\tomcat-dbcp.jar'))
    try {
        if (-not $factoryArchive.GetEntry('org/apache/tomcat/dbcp/dbcp2/BasicDataSourceFactory.class')) {
            throw "Tomcat datasource factory missing in $($instance.Name)."
        }
    }
    finally {
        $factoryArchive.Dispose()
    }
    $service = Get-Service -Name $instance.Service
    if ($service.Status -ne 'Running') {
        throw "Expected a running disposable instance: $($instance.Service)."
    }
    $contextHash = (Get-FileHash -LiteralPath $contextPath).Hash
    $document = New-Object System.Xml.XmlDocument
    $document.XmlResolver = $null
    $document.PreserveWhitespace = $true
    $document.Load($contextPath)
    if ($document.DocumentElement.Name -ne 'Context') {
        throw "Unexpected context XML in $($instance.Name)."
    }
    $added = 0
    foreach ($name in $resourceNames) {
        $databasePath = (Join-Path $root ('runtime\ccssuite-jndi\' + ($name -replace '^jdbc/', ''))).Replace('\', '/')
        $attributes = [ordered]@{
            name = $name
            auth = 'Container'
            type = 'javax.sql.DataSource'
            factory = 'org.apache.tomcat.dbcp.dbcp2.BasicDataSourceFactory'
            driverClassName = 'org.apache.derby.jdbc.EmbeddedDriver'
            url = 'jdbc:derby:' + $databasePath + ';create=true'
            username = 'ccssuite_jndi_fixture'
            initialSize = '0'
            minIdle = '0'
            maxTotal = '2'
            maxIdle = '1'
            description = 'CCSSUITE isolated JNDI fixture managed by setup_jndi_fixtures.ps1'
        }
        $existing = @($document.SelectNodes('//Resource | //ResourceLink') | Where-Object { $_.GetAttribute('name') -ieq $name })
        if ($existing.Count) {
            if ($existing.Count -ne 1 -or $existing[0].Name -ne 'Resource') {
                throw "Conflicting reserved resource in $($instance.Name): $name"
            }
            foreach ($attribute in $attributes.GetEnumerator()) {
                if ($existing[0].GetAttribute($attribute.Key) -cne $attribute.Value) {
                    throw "Refusing to replace a nonmatching resource in $($instance.Name): $name"
                }
            }
            continue
        }
        if (Test-Path -LiteralPath $databasePath) {
            throw "Refusing to reuse existing unowned database files: $databasePath"
        }
        $resource = $document.CreateElement('Resource')
        foreach ($attribute in $attributes.GetEnumerator()) {
            $resource.SetAttribute($attribute.Key, $attribute.Value)
        }
        [void]$document.DocumentElement.AppendChild($document.CreateWhitespace("`r`n    "))
        [void]$document.DocumentElement.AppendChild($resource)
        [void]$document.DocumentElement.AppendChild($document.CreateWhitespace("`r`n"))
        $added++
    }
    $roundTrip = New-Object System.Xml.XmlDocument
    $roundTrip.XmlResolver = $null
    $roundTrip.LoadXml($document.OuterXml)
    $plans += [pscustomobject]@{
        Instance = $instance; Root = $root; ContextPath = $contextPath; ContextHash = $contextHash
        Document = $document; DriverTarget = $driverTarget; ExistingDriver = $existingDriver; Added = $added
    }
    "$($instance.Name): add $added reserved bindings; isolated Derby driver required = $(-not $existingDriver)."
}

if (-not $Apply) {
    'PLAN ONLY: no files, configuration, database connections, or services changed.'
    'To provision, run from elevated Windows PowerShell: .\setup_jndi_fixtures.ps1 -Apply -ConfirmDisposableInstances'
    return
}

foreach ($plan in $plans) {
    if ((Get-FileHash -LiteralPath $plan.ContextPath).Hash -ne $plan.ContextHash) {
        throw "Context changed during planning on $($plan.Instance.Name); no changes applied."
    }
}
$backupRoot = Join-Path $InstallRoot ('config\ccssuite-jndi-backups\' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $backupRoot)
foreach ($plan in $plans) {
    Copy-Item -LiteralPath $plan.ContextPath -Destination (Join-Path $backupRoot ($plan.Instance.Name + '-context.xml'))
}
"Context backups: $backupRoot"
foreach ($plan in $plans) {
    if (-not $plan.ExistingDriver) {
        Copy-Item -LiteralPath $driverSource -Destination $plan.DriverTarget
    }
    [void](New-Item -ItemType Directory -Path (Join-Path $plan.Root 'runtime\ccssuite-jndi') -Force)
    if ($plan.Added) {
        $plan.Document.Save($plan.ContextPath)
    }
}
foreach ($plan in $plans) {
    if ($plan.Added -or -not $plan.ExistingDriver) {
        Restart-Service -Name $plan.Instance.Service
        $service = Get-Service -Name $plan.Instance.Service
        $service.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromMinutes(2))
        "Restarted $($plan.Instance.Name)."
    }
}
'After ColdFusion finishes starting, run: .\setup_jndi_fixtures.ps1 -Verify'
'No Administrator datasource registrations were changed. Database files may be created when fixtures are used.'