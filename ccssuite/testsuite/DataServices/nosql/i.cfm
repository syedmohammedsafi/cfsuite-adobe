<h2>Data &amp; Services - NoSQL Data Sources: MongoDB</h2>
<p>Registration tests require disposable CCS instances and matching code on every node. Run serially. Only reserved loopback fixtures are created and removed.</p>
<p><a href="../i.cfm">Data &amp; Services</a> | <a href="datasourceList.cfm">Datasource list (read-only)</a> | <a href="_validate.cfm">API metadata and synthetic checks (read-only)</a></p>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Field</th><th>Internal ID</th><th>Type</th><th>Admin API Property</th><th>Test</th></tr></thead>
        <tbody>
                <tr><td>Data Source Name</td><td>dsnName</td><td>text</td><td>name</td><td><a href="dsnName.cfm">dsnName.cfm</a></td></tr>
                <tr><td>Driver</td><td>driverName</td><td>select-one</td><td>type (mongodb)</td><td><a href="driverName.cfm">driverName.cfm</a></td></tr>
                <tr><td>Host</td><td>mongo_host</td><td>text</td><td>host</td><td><a href="mongo_host.cfm">mongo_host.cfm</a></td></tr>
                <tr><td>Port</td><td>mongo_port</td><td>text</td><td>port</td><td><a href="mongo_port.cfm">mongo_port.cfm</a></td></tr>
                <tr><td>Replica Set Name</td><td>mongo_replicaSetName</td><td>text</td><td>replicaSet</td><td><a href="mongo_replicaSetName.cfm">mongo_replicaSetName.cfm</a></td></tr>
                <tr><td>SSL</td><td>mongo_enableSSL</td><td>boolean</td><td>ssl</td><td><a href="mongo_enableSSL.cfm">mongo_enableSSL.cfm</a></td></tr>
                <tr><td>DNS Seed List</td><td>mongo_DnsSeedlist</td><td>boolean</td><td>dnsSeedList</td><td><a href="mongo_DnsSeedlist.cfm">mongo_DnsSeedlist.cfm</a></td></tr>
                <tr><td>Authentication Mechanism</td><td>mongo_authMechanism</td><td>enum</td><td>authMechanism</td><td><a href="mongo_authMechanism.cfm">mongo_authMechanism.cfm</a></td></tr>
                <tr><td>Authentication Username</td><td>mongo_authUsername</td><td>text</td><td>username</td><td><a href="mongo_authUsername.cfm">mongo_authUsername.cfm</a></td></tr>
                <tr><td>Authentication Password</td><td>mongo_authPassword</td><td>sensitive</td><td>password</td><td><a href="mongo_authPassword.cfm">mongo_authPassword.cfm</a></td></tr>
                <tr><td>Authentication Source</td><td>mongo_authSource</td><td>text</td><td>authSource</td><td><a href="mongo_authSource.cfm">mongo_authSource.cfm</a></td></tr>
                <tr><td>GSSAPI Service Name</td><td>mongo_gssapiServiceName</td><td>text</td><td>gssapiServiceName</td><td><a href="mongo_gssapiServiceName.cfm">mongo_gssapiServiceName.cfm</a></td></tr>
                <tr><td>Read Concern</td><td>mongo_readConcern</td><td>enum</td><td>readConcern</td><td><a href="mongo_readConcern.cfm">mongo_readConcern.cfm</a></td></tr>
                <tr><td>Read Preference</td><td>mongo_readPref</td><td>enum</td><td>readPreference</td><td><a href="mongo_readPref.cfm">mongo_readPref.cfm</a></td></tr>
                <tr><td>Max Staleness</td><td>mongo_maxStaleness</td><td>numeric</td><td>maxStalenessSeconds: unsupported by installed setter</td><td><a href="mongo_maxStaleness.cfm">mongo_maxStaleness.cfm</a> (explicit failure)</td></tr>
                <tr><td>Write Concern</td><td>mongo_w</td><td>text</td><td>w</td><td><a href="mongo_w.cfm">mongo_w.cfm</a></td></tr>
                <tr><td>Write Timeout</td><td>mongo_writeTimeout</td><td>numeric</td><td>wtimeout</td><td><a href="mongo_writeTimeout.cfm">mongo_writeTimeout.cfm</a></td></tr>
                <tr><td>Journal</td><td>mongo_j</td><td>boolean</td><td>j</td><td><a href="mongo_j.cfm">mongo_j.cfm</a></td></tr>
                <tr><td>Connection Timeout</td><td>mongo_connTimeout</td><td>numeric</td><td>connectTimeout</td><td><a href="mongo_connTimeout.cfm">mongo_connTimeout.cfm</a></td></tr>
                <tr><td>Max Connection Pool Size</td><td>mongo_maxConnPoolSize</td><td>numeric</td><td>maxPoolSize</td><td><a href="mongo_maxConnPoolSize.cfm">mongo_maxConnPoolSize.cfm</a></td></tr>
                <tr><td>Min Connection Pool Size</td><td>mongo_minConnPoolSize</td><td>numeric</td><td>minPoolSize</td><td><a href="mongo_minConnPoolSize.cfm">mongo_minConnPoolSize.cfm</a></td></tr>
                <tr><td>Max Connection Lifetime</td><td>mongo_maxConnLifeTime</td><td>numeric</td><td>maxConnectionLifeTime</td><td><a href="mongo_maxConnLifeTime.cfm">mongo_maxConnLifeTime.cfm</a></td></tr>
                <tr><td>Max Connection Idle Time</td><td>mongo_maxConnIdleTime</td><td>numeric</td><td>maxConnectionIdleTime</td><td><a href="mongo_maxConnIdleTime.cfm">mongo_maxConnIdleTime.cfm</a></td></tr>
                <tr><td>Max Connection Pool Wait Time</td><td>mongo_maxConnPoolWaitTime</td><td>numeric</td><td>maxWaitQueueTimeout</td><td><a href="mongo_maxConnPoolWaitTime.cfm">mongo_maxConnPoolWaitTime.cfm</a></td></tr>
                <tr><td>Max Connection Pool Wait Size</td><td>mongo_maxConnPoolWaitSize</td><td>numeric</td><td>maxWaitQueueSize</td><td><a href="mongo_maxConnPoolWaitSize.cfm">mongo_maxConnPoolWaitSize.cfm</a></td></tr>
                <tr><td>Heartbeat Frequency</td><td>mongo_heartbeatFreq</td><td>numeric</td><td>heartbeatFrequency</td><td><a href="mongo_heartbeatFreq.cfm">mongo_heartbeatFreq.cfm</a></td></tr>
                <tr><td>Min Heartbeat Frequency</td><td>mongo_minHeartbeatFreq</td><td>numeric</td><td>minHeartbeatFrequency</td><td><a href="mongo_minHeartbeatFreq.cfm">mongo_minHeartbeatFreq.cfm</a></td></tr>
        </tbody>
</table>