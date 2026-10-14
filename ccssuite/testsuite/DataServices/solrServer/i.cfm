<!--- Solr Server test index — covers the Data & Services > Solr Server admin page --->
<cfoutput>
	<h2>Solr Server Tests</h2>
	<p><a href="../i.cfm">&larr; Data &amp; Services</a></p>
	<ul>
		<li><a href="solrHost.cfm">Solr Host Name (solrhost)</a></li>
		<!--- <li><a href="solrHome.cfm">Solr Home (solrhome)</a> — per-instance path, nodesScope="currentPort"</li> --->
		<li><a href="solrAdminPort.cfm">Solr Admin Port (solrport)</a></li>
		<li><a href="solrUsername.cfm">User name (username)</a></li>
		<!--- <li><a href="solrPassword.cfm">Password (password)</a> — auto-encrypted by CF at rest, tested leniently like mail passwords</li> --->
		<li><a href="solrConnection.cfm">Solr Connection - Use HTTPS (httpsenabled)</a></li>
		<li><a href="solrAdminHttpsPort.cfm">Solr Admin HTTPS Port (solrhttpsport)</a></li>
		<li><a href="solrWebapp.cfm">Solr Webapp (solrwebapp)</a></li>
		<li><a href="solrBufferLimit.cfm">Solr Buffer Limit (solrbuffersize)</a></li>
		<li><a href="indexingLanguage.cfm">Indexing Language add/remove (New language / New language suffix)</a></li>
	</ul>
	<p><em>Note:</em> solrhost/solrport are the live connection every CF instance on this box
	currently shares (confirmed empirically: all point at the same localhost:8997 Solr
	server) — the value is only wrong for the brief guaranteed-by-cffinally window between
	set and restore, same risk profile as this suite's existing mail/websocket port tests.</p>
	<p><em>Note — solrhome vs. the other fields:</em> confirmed via direct polling that
	solrhost, username, password, ports, webapp, and the "languages" array all genuinely
	replicate to peer nodes via real CCS cluster sync (same cluster/environment). solrhome
	does not — it's a per-instance filesystem path (each instance has its own jetty/multicore
	directory) and is never part of the CCS Solr Server sync payload, so its test is scoped
	to nodesScope="currentPort" like the Charting cache path test, rather than reporting a
	false failure on peers that legitimately never change.</p>
</cfoutput>
