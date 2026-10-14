# ============================================================
# CCS Docker Sub Instance Setup  (run on the HOST, not inside a container)
# ============================================================
#
# Container "cf2025-all" already exists and is running the CF2025 image's
# main "cfusion" instance (port 8500). This script creates the bundled
# "testInstanceDocker" sub instance (if missing) and starts it.
#
# Run:  powershell -ExecutionPolicy Bypass -File .\ccsDockerAllInOneSetup.ps1
#
# Idempotent: safe to re-run. Skips creation if the instance already exists,
# skips start if it's already running.
# ============================================================

$ErrorActionPreference = "Continue"

$container      = "cf2025-all"
$subBin         = "/opt/coldfusion/testInstanceDocker/bin"
$subInstanceDir = "/opt/coldfusion/testInstanceDocker"
$adminPw        = "password"
$webroot        = "/app"

function Section($t){ Write-Host "`n===== $t =====" -ForegroundColor Cyan }

function Wait-CFReady($name, $bin, $tries = 48){
    for ($i=0; $i -lt $tries; $i++){
        $s = docker exec $name "$bin/coldfusion" status 2>$null
        if ($s -match "running"){ return $true }
        Start-Sleep -Seconds 5
    }
    return $false
}

function Wait-DirExists($name, $path, $tries = 36){
    for ($i=0; $i -lt $tries; $i++){
        docker exec $name test -d $path 2>$null
        if ($LASTEXITCODE -eq 0){ return $true }
        Start-Sleep -Seconds 5
    }
    return $false
}

# Write a file inside a container from a PowerShell string (stdin pipe avoids
# all nested-shell quote mangling).
function Write-FileInContainer($name, $path, [string]$content){
    ($content -replace "`r`n","`n") | docker exec -i $name sh -c "cat > $path"
}


# ============================================================
# 1. Create the "testInstanceDocker" sub instance if it doesn't exist yet
#    (same createServerInstance() admin-API call as setup_instances.cfm,
#    just triggered over HTTP inside the container instead of on the host).
# ============================================================
Section "testInstanceDocker sub instance"
docker exec $container test -d $subInstanceDir 2>$null
if ($LASTEXITCODE -eq 0){
    Write-Host "  testInstanceDocker already exists" -ForegroundColor Yellow
}
else {
    $cfm = "<cfsetting requestTimeout='150'><cfscript>" +
        "admin=createObject('component','CFIDE.adminapi.administrator');admin.login('$adminPw');" +
        "srvInst=createObject('component','CFIDE.adminapi.serverinstance');" +
        "existing=srvInst.getServerInstances();" +
        "if(NOT structKeyExists(existing,'testInstanceDocker')){srvInst.createServerInstance('testInstanceDocker');writeOutput('CREATED');}" +
        "else{writeOutput('EXISTS');}" +
        "</cfscript>"
    Write-FileInContainer $container "$webroot/_ccsCreateSubInstance.cfm" $cfm
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:8500/_ccsCreateSubInstance.cfm" -UseBasicParsing -TimeoutSec 160
        Write-Host "  $($r.Content.Trim())" -ForegroundColor Green
    } catch { Write-Host "  request failed: $($_.Exception.Message)" -ForegroundColor Red }
    finally { docker exec $container rm -f "$webroot/_ccsCreateSubInstance.cfm" | Out-Null }

    Write-Host "  waiting for instance directory to be created (can take 1-2 min)..."
    if (-not (Wait-DirExists $container $subInstanceDir)){ throw "testInstanceDocker directory never appeared" }
    Write-Host "  testInstanceDocker: directory created" -ForegroundColor Green
}


# ============================================================
# 2. Start the sub instance
# ============================================================
Section "Starting testInstanceDocker"
docker exec $container "$subBin/coldfusion" start
if (-not (Wait-CFReady $container $subBin)){ Write-Host "  testInstanceDocker did NOT come up (check 'docker logs $container')" -ForegroundColor Red }
else { Write-Host "  testInstanceDocker: READY" -ForegroundColor Green }

Section "Done"
Write-Host "testInstanceDocker    docker exec $container `"$subBin/coldfusion`" status"
