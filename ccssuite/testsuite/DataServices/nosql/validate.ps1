param([string]$BaseUrl = 'http://localhost:8500/cfsuite/ccssuite')

$ErrorActionPreference = 'Stop'
$suiteRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$apiSource = Get-Content (Join-Path $suiteRoot 'utils\nosqlDatasourceApiUtil.cfc') -Raw
$map = [regex]::Match($apiSource, 'return \{dsnName=.*?\};', [Text.RegularExpressions.RegexOptions]::Singleline).Value
$fields = [regex]::Matches($map, '\b(dsnName|driverName|mongo_\w+)="([^"]+)"')
if ($fields.Count -ne 27) { throw 'Expected 27 MongoDB field mappings.' }
$index = Get-Content (Join-Path $PSScriptRoot 'i.cfm') -Raw
foreach ($field in $fields) {
        $pageName = $field.Groups[1].Value + '.cfm'
        $page = Get-Content (Join-Path $PSScriptRoot $pageName) -Raw
        if ($page -notmatch ('^<cfset request\.nosqlSetting = "' + [regex]::Escape($field.Groups[1].Value) + '">\r?\n<cfinclude template="_fieldTest.cfm">\r?\n?$')) {
                throw "Invalid thin page: $pageName"
        }
        if ($index -notmatch ('href="' + [regex]::Escape($pageName) + '"')) { throw "Missing index link: $pageName" }
}
foreach ($pageName in @('Application.cfc', '_getter.cfm', '_setter.cfm', '_fieldTest.cfm', '_validate.cfm', 'datasourceList.cfm')) {
        $source = Get-Content (Join-Path $PSScriptRoot $pageName) -Raw
        if ($source -match '(cfcatch|failure|exception)\.(message|detail)|writeDump|registerRestService') { throw "Unsafe output or bootstrap: $pageName" }
}
$template = Get-Content (Join-Path $PSScriptRoot '_fieldTest.cfm') -Raw
if ($template -notmatch '<cffinally>' -or $template -notmatch '<cf_qatest ' -or $template -notmatch 'UNSUPPORTED:') { throw 'Missing harness or restore contract.' }
foreach ($pageName in @('_validate.cfm', 'datasourceList.cfm', 'Application.cfc')) {
        $source = Get-Content (Join-Path $PSScriptRoot $pageName) -Raw
        if ($source -match '\.(setMongoDataSource|deleteMongoDatasource|verifyMongoDatasource|getDatasource|setSetting|runSyncTest)\s*\(') { throw "Non-read-only validator: $pageName" }
}
$driverSource = Get-Content (Join-Path $suiteRoot 'testDriver.cfc') -Raw
$dispatchSource = Get-Content (Join-Path $suiteRoot 'utils\ccsApiUtil.cfc') -Raw
if ($driverSource -notmatch 'datasources,nosql' -or $dispatchSource -notmatch 'case "nosql":') { throw 'Missing NoSQL driver routing.' }
$parentIndex = Get-Content (Join-Path $PSScriptRoot '..\i.cfm') -Raw
if ($parentIndex -notmatch 'href="nosql/i.cfm"') { throw 'Missing NoSQL parent navigation.' }
Write-Output 'PASS: 27 mappings, thin pages, index links, masked outputs, write-free validation and driver routing.'

$metadataUrl = $BaseUrl.TrimEnd('/') + '/testsuite/DataServices/nosql/_validate.cfm'
$response = & curl.exe -sS --max-time 30 $metadataUrl
if ($LASTEXITCODE -ne 0) { throw 'Read-only validator connectivity failed.' }
$result = $response | ConvertFrom-Json
if ($result.ERROR) { throw ('Read-only validator failed at safe stage: ' + $result.STAGE) }
if ($result.CONFIGURATIONWRITES -ne $false -or $result.FIELDCOUNT -ne 27 -or $result.SUPPORTEDFIELDCOUNT -ne 26) { throw 'Installed API coverage mismatch.' }
if (@($result.UNSUPPORTEDFIELDS).Count -ne 1 -or $result.UNSUPPORTEDFIELDS[0] -ne 'mongo_maxStaleness') { throw 'Unexpected unsupported fields.' }
$failedChecks = @($result.SYNTHETIC.PSObject.Properties | Where-Object Value -ne $true)
if ($failedChecks.Count) { throw ('Synthetic checks failed: ' + (($failedChecks | ForEach-Object Name) -join ', ')) }
Write-Output ("PASS: read-only CF compilation and {0} synthetic comparison, selector and safety checks; 26 API-supported fields, one explicit unsupported field." -f @($result.SYNTHETIC.PSObject.Properties).Count)
if (-not $result.PASSWORDVERIFICATIONSUPPORTED) { Write-Warning 'Password verification API is unavailable; password regression must fail explicitly before writes.' }

$listUrl = $BaseUrl.TrimEnd('/') + '/testsuite/DataServices/nosql/datasourceList.cfm'
$body = (& curl.exe -sS --max-time 30 $listUrl) -join "`n"
if ($LASTEXITCODE -ne 0 -or $body -notmatch 'setting values as expected' -or $body -match 'NoSQL request failed|list API failed') { throw 'Read-only cf_qatest list check failed.' }
Write-Output 'PASS: read-only datasource list cf_qatest; no mutation pages, setters or restarts invoked.'