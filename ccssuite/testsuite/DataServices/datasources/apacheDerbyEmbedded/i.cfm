<h2>Data Sources - Add: Apache Derby Embedded</h2>
<p>Run only on disposable CCS instances. Each case captures original node state, prepares a reserved baseline, changes one field, and restores datasource registrations.</p>
<table border="1" cellpadding="5" cellspacing="0">
        <thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
        <tbody>
                <tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="dsn.cfm">dsn.cfm</a></td></tr>
                <tr><td>Database Folder</td><td>database</td><td>text</td><td><a href="database.cfm">database.cfm</a></td></tr>
                <tr><td>Create Database</td><td>isnewdb</td><td>checkbox</td><td><a href="createDatabase.cfm">createDatabase.cfm</a></td></tr>
                <tr><td>Description</td><td>description</td><td>textarea</td><td><a href="description.cfm">description.cfm</a></td></tr>
        </tbody>
</table>
<p>Create Database tests the creation flag, not database contents. The API may create files in the reserved test folder; cleanup unregisters the datasource but never deletes database files. Existing reserved folders stop new fixture registration.</p>
<p>CCS assertions remain strict. Only reserved names beginning CCSSUITE_DERBYEMBEDDED_ and suite-owned folder paths are accepted.</p>
<p><a href="../i.cfm">Data Sources</a> | <a href="../_validate.cfm">Read-only validation</a></p>