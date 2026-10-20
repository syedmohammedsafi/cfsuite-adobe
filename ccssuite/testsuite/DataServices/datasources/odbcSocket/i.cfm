<h2>Data Sources - Add: ODBC Socket</h2>
<p>Run only on disposable CCS instances. Each case registers a reserved datasource fixture, changes its selected field, and restores the original per-node state.</p>
<p>An existing ColdFusion ODBC DSN must be present on every node. The ODBC DSN field test requires two existing DSNs; this suite does not create or modify Windows ODBC DSNs. Connection validation is disabled.</p>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="dsn.cfm">dsn.cfm</a></td></tr>
                <tr><td>ODBC DSN</td><td>datasource</td><td>select-one</td><td><a href="datasource.cfm">datasource.cfm</a></td></tr>
                <tr><td>Trusted Connection</td><td>UseTrustedConnection</td><td>checkbox</td><td><a href="trustedConnection.cfm">trustedConnection.cfm</a></td></tr>
                <tr><td>User name</td><td>username</td><td>text</td><td><a href="username.cfm">username.cfm</a></td></tr>
                <tr><td>Password</td><td>password</td><td>password</td><td><a href="password.cfm">password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="description.cfm">description.cfm</a></td></tr>
        </tbody>
</table>
<p><a href="../i.cfm">Data Sources</a> | <a href="../_validate.cfm">Read-only validation</a></p>
