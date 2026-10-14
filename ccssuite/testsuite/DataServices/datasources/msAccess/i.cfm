<h2>Data Sources - Microsoft Access</h2>
<p>Run only on disposable Windows CCS instances with Microsoft Access and ColdFusion ODBC support. Only reserved CCSSUITE_MSACCESS registrations are created and removed.</p>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal API ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>name</td><td>text</td><td><a href="dsn.cfm">dsn.cfm</a></td></tr>
                <tr><td>Database File</td><td>databasefile</td><td>text</td><td><a href="databaseFile.cfm">databaseFile.cfm</a></td></tr>
                <tr><td>System Database File</td><td>systemDatabaseFile</td><td>text</td><td><a href="systemDatabaseFile.cfm">systemDatabaseFile.cfm</a></td></tr>
                <tr><td>Use Default User name</td><td>UseTrustedConnection</td><td>checkbox</td><td><a href="useDefaultUsername.cfm">useDefaultUsername.cfm</a></td></tr>
                <tr><td>ColdFusion User Name</td><td>username</td><td>text</td><td><a href="username.cfm">username.cfm</a></td></tr>
                <tr><td>ColdFusion Password</td><td>password</td><td>password</td><td><a href="password.cfm">password.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="description.cfm">description.cfm</a></td></tr>
        </tbody>
</table>
<p>Reserved database paths are under testAssets/databases/msAccess. No database files are created or deleted by the suite. Submit a field test only after confirming the Windows ODBC prerequisites.</p>
<p><a href="../_validate.cfm">Read-only validation</a> | <a href="../i.cfm">All Data Sources tests</a></p>