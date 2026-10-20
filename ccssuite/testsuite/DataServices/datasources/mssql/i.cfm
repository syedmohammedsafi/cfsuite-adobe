<h2>Data Sources - Add: Microsoft SQL Server</h2>
<p>Run only on disposable CCS instances. Each case registers a reserved baseline, changes its selected field, and restores the original per-node state.</p>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="dsn.cfm">dsn.cfm</a></td></tr>
                <tr><td>Database</td><td>database</td><td>text</td><td><a href="database.cfm">database.cfm</a></td></tr>
                <tr><td>Server</td><td>host</td><td>text</td><td><a href="host.cfm">host.cfm</a></td></tr>
                <tr><td>Port</td><td>port</td><td>text</td><td><a href="port.cfm">port.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="username.cfm">username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="password.cfm">password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="description.cfm">description.cfm</a></td></tr>
        </tbody>
</table>
<p>All cases retain strict CCS expectations. Reserved loopback fixtures use connection validation disabled; no real SQL Server connection is attempted.</p>
<p><a href="../i.cfm">Data Sources</a> | <a href="../_validate.cfm">Read-only validation</a></p>
