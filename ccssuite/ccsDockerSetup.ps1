# ============================================================
# CCS Docker Nodes Setup  (run on the HOST, not inside a container)
# ============================================================
#
# Brings up 4 ColdFusion 2025 docker nodes (docker-compose.yml here) and
# registers them with the CCS server running inside the existing hub
# container "cf2025-test".
#
# Run:  powershell -ExecutionPolicy Bypass -File .\ccsDockerSetup.ps1
#
# --- Hard-won facts baked in below (verified against the live image) ---
#  * Hub = container "cf2025-test" (image adobecoldfusion/coldfusion2025),
#    on docker network "cf2025-network", CF home /opt/coldfusion/cfusion,
#    admin password "admin", CCS tool bin/ccs.sh, webroot /app.
#  * ccs.sh: only "startServer" works non-interactively. addnode/listnodes
#    require the INTERACTIVE CLI, and the server runs IN-PROCESS -- so
#    startServer + every addnode must share ONE stdin stream, with a delay
#    after startServer, and that process must stay alive (server dies with
#    its session). Done via `docker exec -d bash -c '{...; sleep BIG} | ccs.sh'`.
#  * The image entrypoint (start-coldfusion.sh -> updateWebroot) appends a
#    <Context> to server.xml on EVERY start and is NOT idempotent: a plain
#    `docker restart` adds a 2nd empty-path Context -> "Child name [] is not
#    unique" -> Tomcat never binds 8500. So to restart a node we first
#    `touch /opt/startup/disableScripts` (image's own skip-setup marker),
#    which makes the entrypoint start CF without re-mutating server.xml.
#    (In-container `coldfusion restart` / pkill+start proved unreliable:
#    `coldfusion status` reports "running" while nothing is listening.)
#  * Nodes must be reachable from the hub at add time (addnode validates),
#    so we wait for each node's CF to actually be up before registering.
# ============================================================

# NOTE: not "Stop" -- native exes (keytool, docker) write normal progress to
# stderr, and in Windows PowerShell 5.1 that becomes a terminating error under
# Stop. We check $LASTEXITCODE explicitly where it matters instead.
$ErrorActionPreference = "Continue"
$composeFile = Join-Path $PSScriptRoot "docker-compose.yml"

$hub     = "cf2025-test"
$cfHome  = "/opt/coldfusion/cfusion"
$ccsSh   = "$cfHome/bin/ccs.sh"
$ccsProps= "$cfHome/lib/ccs/ccs.properties"
$serverXml = "$cfHome/runtime/conf/server.xml"
$keystore  = "$cfHome/runtime/conf/ssl.keystore"
$keytool = "/opt/coldfusion/jre/bin/keytool"
$adminPw = "admin"

# name | host http port | cluster | env | sandbox | ssl
$nodes = @(
    @{ name="cf-plain";    port=8600; cluster="_CF_DEFAULT"; env="development"; sandbox=$false; ssl=$false }
    @{ name="cf-lockdown"; port=8601; cluster="_CF_DEFAULT"; env="production";  sandbox=$false; ssl=$false }
    @{ name="cf-sandbox";  port=8602; cluster="testcluster"; env="development"; sandbox=$true;  ssl=$false }
    @{ name="cf-ssl";      port=8603; cluster="_CF_DEFAULT"; env="production";  sandbox=$false; ssl=$true  }
)

function Section($t){ Write-Host "`n===== $t =====" -ForegroundColor Cyan }

function Wait-CFReady($name, $tries = 48){
    for ($i=0; $i -lt $tries; $i++){
        $s = docker exec $name /opt/coldfusion/cfusion/bin/coldfusion status 2>$null
        if ($s -match "running"){ return $true }
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
# 1. Bring up the node containers
# ============================================================
Section "docker compose up"
docker compose -f $composeFile up -d
if ($LASTEXITCODE -ne 0){ throw "docker compose up failed" }

Section "Waiting for each node's CF to start (1-2 min each)"
foreach ($n in $nodes){
    if (Wait-CFReady $n.name){ Write-Host "  $($n.name): READY" -ForegroundColor Green }
    else { Write-Host "  $($n.name): NOT READY (check 'docker logs $($n.name)')" -ForegroundColor Red }
}


# ============================================================
# 2. Read each node's CF-generated CCS secret key
# ============================================================
Section "Reading CCS secret keys"
foreach ($n in $nodes){
    $line = docker exec $n.name grep -m1 "^ccssecretkey=" $ccsProps
    $n.secretKey = ($line -replace "^ccssecretkey=","").Trim()
    if ([string]::IsNullOrWhiteSpace($n.secretKey)){ Write-Host "  $($n.name): NO KEY" -ForegroundColor Red }
    else { Write-Host "  $($n.name): key read" -ForegroundColor Green }
}


# ============================================================
# 3. Configure each node: point ccs.properties at the hub, set
#    cluster/env; add SSL connector on the ssl node. (Applied on the
#    restart in step 4.)
# ============================================================
Section "Configuring nodes"
foreach ($n in $nodes){
    if (-not $n.secretKey){ continue }

    # server = hub container name (reachable on cf2025-network) so the
    # node's CCS client pulls config from the hub.
    $props = @"
ccssecretkey=$($n.secretKey)
clustername=$($n.cluster)
context=
currentversion=-1
enabled=true
environment=$($n.env)
excludefiles=jvm.config,neo-datasource.xml
hostname=$($n.name)
hostport=8500
loadenvfrom=$($n.env)
loadversionfrom=-1
port=7071
protocol=http
server=$hub
"@
    Write-FileInContainer $n.name $ccsProps $props
    Write-Host "  $($n.name): ccs.properties set (cluster=$($n.cluster), env=$($n.env))" -ForegroundColor Green

    if ($n.ssl){
        docker exec $n.name test -f $keystore 2>$null
        if ($LASTEXITCODE -ne 0){
            docker exec $n.name $keytool -genkeypair -alias ccsssl -keyalg RSA -keysize 2048 -validity 3650 `
                -dname "CN=localhost, OU=CCS, O=CCS, L=Local, ST=Local, C=US" `
                -keystore $keystore -storepass changeit -keypass changeit 2>&1 | Out-Null
        }

        $xml = (docker exec $n.name cat $serverXml) -join "`n"
        $lines = $xml -split "`n" | Where-Object { $_ -notmatch '<Connector port="8443"' }
        $conn = '    <Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol" maxThreads="150" SSLEnabled="true" scheme="https" secure="true"><SSLHostConfig><Certificate certificateKeystoreFile="' + $keystore + '" certificateKeystorePassword="changeit" type="RSA" /></SSLHostConfig></Connector>'
        $out = New-Object System.Collections.Generic.List[string]; $done=$false
        foreach ($l in $lines){ if (-not $done -and $l -match '</Service'){ $out.Add($conn); $done=$true }; $out.Add($l) }
        Write-FileInContainer $n.name $serverXml (($out -join "`n"))
        Write-Host "  $($n.name): self-signed keystore + SSL connector (8443)" -ForegroundColor Green
    }
}


# ============================================================
# 4. Restart nodes so ccs.properties / server.xml take effect.
#    disableScripts marker = restart WITHOUT the non-idempotent entrypoint
#    server.xml mutation (see header). Plain `docker restart` would break
#    the node.
# ============================================================
Section "Restarting nodes (safe: skip entrypoint mutation)"
foreach ($n in $nodes){
    if (-not $n.secretKey){ continue }
    docker exec $n.name touch /opt/startup/disableScripts | Out-Null
    docker restart $n.name | Out-Null
    if (Wait-CFReady $n.name){ Write-Host "  $($n.name): back up" -ForegroundColor Green }
    else { Write-Host "  $($n.name): did NOT come back" -ForegroundColor Red }
}


# ============================================================
# 5. Enable Sandbox Security on the sandbox node (admin API, persists in
#    neo-security.xml). Uses a throwaway cfm in the node webroot.
# ============================================================
foreach ($n in $nodes){
    if (-not $n.sandbox){ continue }
    Section "Enabling Sandbox Security on $($n.name)"
    $cfm = "<cfscript>try{a=createObject('component','CFIDE.adminapi.administrator');a.login('$adminPw');s=createObject('component','CFIDE.adminapi.security');s.setEnableSandboxSecurity(javaCast('boolean',true));writeOutput('SANDBOX='&s.getEnableSandboxSecurity());}catch(any e){writeOutput('ERROR:'&e.message);}</cfscript>"
    Write-FileInContainer $n.name "/app/_ccsSandboxEnable.cfm" $cfm
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:$($n.port)/_ccsSandboxEnable.cfm" -UseBasicParsing -TimeoutSec 25
        Write-Host "  $($r.Content.Trim())" -ForegroundColor Green
    } catch { Write-Host "  failed: $($_.Exception.Message)" -ForegroundColor Red }
    finally { docker exec $n.name rm -f /app/_ccsSandboxEnable.cfm | Out-Null }
}


# ============================================================
# 6. Register all nodes with CCS in ONE interactive session, kept alive.
#    (startServer + addnodes must share one stdin stream; server dies with
#    its session, so we hold it open with a long sleep and detach.)
# ============================================================
Section "Registering nodes with CCS"
docker exec $hub pkill -f CentralConfigServer 2>$null | Out-Null
Start-Sleep -Seconds 3

$cmds = "echo startServer; sleep 16; "
foreach ($n in $nodes){
    if (-not $n.secretKey){ continue }
    $cmds += "echo 'addnode $($n.name):8500 $($n.secretKey) false'; sleep 3; "
}
$cmds += "echo listnodes; sleep 86400;"
docker exec -d $hub bash -c "{ $cmds } | $ccsSh > /tmp/ccs.log 2>&1"

Write-Host "Waiting for server start + registration..."
Start-Sleep -Seconds 45
Section "CCS result"
docker exec $hub cat /tmp/ccs.log | Select-String -Pattern "successfully","not accessible","8500"


# ============================================================
# 7. Summary
# ============================================================
Section "Done"
Write-Host "cf-plain    http://localhost:8600"
Write-Host "cf-lockdown http://localhost:8601  (secure profile)"
Write-Host "cf-sandbox  http://localhost:8602  (sandbox security on)"
Write-Host "cf-ssl      http://localhost:8603  https://localhost:8643"
Write-Host "CCS server runs in $hub; verify: docker exec $hub cat $cfHome/lib/ccs/nodes.properties"
