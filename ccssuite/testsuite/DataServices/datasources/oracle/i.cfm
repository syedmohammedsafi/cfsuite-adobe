<h2>Data Sources - Add: Oracle</h2>
<p>Run only on disposable CCS instances. Each case registers a reserved loopback baseline, changes its selected field, and restores the original per-node state.</p>
<table border="1" cellpadding="5" cellspacing="0">
	<thead><tr><th>Setting / Field Label</th><th>Internal ID</th><th>Type</th><th>Test File</th></tr></thead>
	<tbody>
		<tr><td>CF Data Source Name</td><td>dsn</td><td>text</td><td><a href="dsn.cfm">dsn.cfm</a></td></tr>
		<tr><td>SID Name</td><td>sid</td><td>text</td><td><a href="sid.cfm">sid.cfm</a></td></tr>
		<tr><td>Service Name</td><td>servicename</td><td>text</td><td><a href="serviceName.cfm">serviceName.cfm</a></td></tr>
		<tr><td>Server</td><td>host</td><td>text</td><td><a href="host.cfm">host.cfm</a></td></tr>
		<tr><td>Port</td><td>port</td><td>text</td><td><a href="port.cfm">port.cfm</a></td></tr>
		<tr><td>User name</td><td>username</td><td>text</td><td><a href="username.cfm">username.cfm</a></td></tr>
		<tr><td>Password</td><td>password</td><td>password</td><td><a href="password.cfm">password.cfm</a></td></tr>
		<tr><td>Description</td><td>description</td><td>textarea</td><td><a href="description.cfm">description.cfm</a></td></tr>
	</tbody>
</table>
<p>The service-name case switches the reserved fixture from SID mode to Service Name mode. Connection validation is disabled; no Oracle connection is attempted.</p>
<p><a href="../i.cfm">Data Sources</a> | <a href="../_validate.cfm">Read-only validation</a></p>
