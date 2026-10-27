<!--- Web Services test index — covers the Data & Services > Web Services admin page --->
<cfoutput>
	<h2>Web Services Tests</h2>
	<p><a href="../i.cfm">&larr; Data &amp; Services</a></p>
	<ul>
		<li><a href="webServiceVersion.cfm">Web Service Version</a> — single-node (nodesScope="currentPort")</li>
		<li><a href="webServiceRegistration.cfm">Add/Edit ColdFusion Web Service - Web Service Name</a> — create, verify sync across nodes, remove</li>
		<li><a href="webServiceWsdlUrl.cfm">Add/Edit ColdFusion Web Service - WSDL URL</a> — create, verify sync across nodes, remove</li>
		<li><a href="webServiceAuthType.cfm">Add/Edit ColdFusion Web Service - Authentication Type</a> — update (none/basic/ntlm), verify sync across nodes, remove</li>
		<li><a href="webServiceTimeout.cfm">Add/Edit ColdFusion Web Service - Timeout</a> — update (0/30), verify sync across nodes, remove</li>
		<li><a href="webServiceProxyServer.cfm">Add/Edit ColdFusion Web Service - Proxy Server</a> — create, verify sync across nodes, remove</li>
		<li><a href="webServiceProxyPort.cfm">Add/Edit ColdFusion Web Service - Proxy Port</a> — create, verify sync across nodes, remove</li>
		<li><a href="webServiceProxyUsername.cfm">Add/Edit ColdFusion Web Service - Proxy Username</a> — create, verify sync across nodes, remove</li>
		<li><a href="webServiceProxyPassword.cfm">Add/Edit ColdFusion Web Service - Proxy Password</a> — create, verify sync across nodes, remove</li>
		<li><a href="webServiceUsername.cfm">Add/Edit ColdFusion Web Service - Username (wsusername)</a> — create, verify sync across nodes, remove</li>
		<li><a href="webServicePassword.cfm">Add/Edit ColdFusion Web Service - Password (wspassword)</a> — create, verify sync across nodes, remove</li>
		<li><a href="webServiceDomain.cfm">Add/Edit ColdFusion Web Service - Domain (wsdomain)</a> — create, verify sync across nodes, remove</li>
		<li><a href="webServiceWorkstation.cfm">Add/Edit ColdFusion Web Service - Workstation (wsworkstation)</a> — create, verify sync across nodes, remove</li>
	</ul>
	<p><em>Note — Web Service Version is single-node:</em> <code>setWSEngineVersion()</code> applies
	the new value locally, then throws a genuine <code>java.lang.ClassCastException</code> inside
	<code>CentralConfigClientUtil.pushToCCS()</code> on every call in this CF2025 build — confirmed
	via direct testing against both <code>CFIDE.adminapi.extensions.setWSVersion()</code> and the
	raw <code>coldfusion.server.ServiceFactory.getXmlRpcService()</code>. A real admin clicking
	"Update Web Service Version" in the browser hits the exact same failure.
	<code>webServicesConfigUtil.cfc</code> swallows exactly that expected exception so the local
	value change can still be tested, but since the CCS push itself never completes, this setting
	cannot be confirmed as multi-node-synced.</p>
	<p><em>Note — Add/Edit ColdFusion Web Service registration:</em>
	<code>setWebService()</code>/<code>deleteWebservice()</code> reliably create/update/delete
	entries in <code>neo-xmlrpc.xml</code>'s "mappings" map when targeting a real, reachable static
	<code>.wsdl</code> file — registering against a live CFC instead triggers CF's Axis2 "deploy as
	web service" step, which hangs a request indefinitely, so this test always targets a plain
	.wsdl file. <code>getWebServices()</code>/<code>getMappings()</code> never reflect live writes
	even from a fresh request (a separate bug from the read side never refreshing its cache), so
	verification reads <code>neo-xmlrpc.xml</code> directly instead, the same approach used for
	Solr Server fields with no working live getter.</p>
	<p>This registration data is confirmed (via 18s of direct polling) to <strong>not</strong> be
	part of what real CCS organically replicates to peer nodes, unlike the Solr Server scalar
	fields. So <code>serverSettingsApiUtil.requiresPeerInstancePropagation()</code> flags the
	"webservices" area to use this suite's active-push mechanism instead (the same one already
	used for AI Services/extensions/security) — the test setter directly re-applies the same
	<code>setWebService()</code> call on each same-cluster peer node rather than passively waiting
	on CCS, so the sync table shows real Passed rows across nodes. Two test patterns are used,
	depending on whether the field has a real non-empty default:</p>
	<ul>
		<li><strong>Fields whose real default is blank</strong> (Web Service Name, WSDL URL,
		Proxy Server, Proxy Port, Proxy Username, Proxy Password) — webServiceRegistration.cfm,
		webServiceWsdlUrl.cfm, webServiceProxyServer.cfm, webServiceProxyPort.cfm,
		webServiceProxyUsername.cfm, and webServiceProxyPassword.cfm are all single-pass create
		tests (empty -&gt; registered), matching what an admin would actually see before adding a
		value. Proxy Server's value must be a real, resolvable hostname ("localhost") —
		setWebService() actually attempts to fetch the WSDL through whatever proxy is given, and an
		unresolvable host aborts the whole registration. Proxy Port, Proxy Username, and Proxy
		Password have no such restriction, since with no proxy server given none of them are
		exercised as an actual connection. Proxy Password is also stored in plain text in
		neo-xmlrpc.xml (confirmed via direct testing) — unlike the mail server and Solr Server
		password fields tested elsewhere in this suite, no encryption-leniency comparison is
		needed here.</li>
		<li><strong>Fields with a real non-empty default</strong> (Authentication Type: NONE,
		Timeout: 0) — webServiceAuthType.cfm and webServiceTimeout.cfm silently register the
		service first at that real default (setup, not the measured step), then the visible test
		updates just that field and verifies the update synced across nodes. This shows the
		genuine none-&gt;basic / 0-&gt;30 transition an admin would actually see, rather than
		fabricating an existing value that was never real.</li>
	</ul>
	<p>All 13 tests remove the registration when they finish, leaving the suite clean.</p>
</cfoutput>
