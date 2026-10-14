<!--- Monitoring Settings test index — covers the Performance Monitoring Toolset admin page --->
<cfoutput>
	<h2>Monitoring Settings Tests</h2>
	<p><a href="../i.cfm">&larr; Performance Monitoring Toolset</a></p>
	<ul>
		<li><a href="hostname.cfm">ColdFusion Hostname (hostname)</a></li>
	</ul>
	<p><em>Not CCS-sync-testable — these are read-only/computed status fields on the admin
	page, not persisted settings a "set" can change:</em></p>
	<ul>
		<li><em>Monitoring Shared Secret</em> — the instance's generated UUID, not user-editable</li>
		<li><em>Connected to datastore</em> — live connectivity status</li>
		<li><em>Monitoring Enabled</em> — computed status, not an independent toggle</li>
	</ul>
</cfoutput>
