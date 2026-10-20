<h2>Data Sources - Add: Other JDBC Driver</h2>
<p>Run only on disposable CCS instances. Each case registers a reserved loopback datasource baseline, changes one field, and restores the original per-node state.</p>
<table border="1" cellpadding="5" cellspacing="0">
	<thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
	<tbody>
		<tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="dsn.cfm">dsn.cfm</a></td></tr>
		<tr><td>JDBC URL</td><td>url</td><td>textarea</td><td><a href="jdbcUrl.cfm">jdbcUrl.cfm</a></td></tr>
		<tr><td>Driver Class</td><td>class</td><td>text</td><td><a href="driverClass.cfm">driverClass.cfm</a></td></tr>
		<tr><td>Driver Name</td><td>driver</td><td>text</td><td><a href="driverName.cfm">driverName.cfm</a></td></tr>
		<tr><td>User name</td><td>username</td><td>text</td><td><a href="username.cfm">username.cfm</a></td></tr>
		<tr><td>Password</td><td>password</td><td>password</td><td><a href="password.cfm">password.cfm</a></td></tr>
		<tr><td>Description</td><td>description</td><td>textarea</td><td><a href="description.cfm">description.cfm</a></td></tr>
	</tbody>
</table>
<p>Connection validation is disabled and the reserved URL points at loopback port 1. No JDBC connection is attempted.</p>
<p><a href="../i.cfm">Data Sources</a> | <a href="../_validate.cfm">Read-only validation</a></p>
