<!--- REST Services test index — covers the Data & Services > REST Services admin page --->
<cfoutput>
	<h2>REST Services Tests</h2>
	<p><a href="../i.cfm">&larr; Data &amp; Services</a></p>
	<p><strong>Caution:</strong> registering/deleting any REST service (via
	<code>CFIDE.adminapi.extensions.registerRESTService()</code>/<code>deleteRESTService()</code>)
	actually deploys/undeploys the target folder as a live REST application, and confirmed real
	CCS attempts to replicate <code>neo-jaxrs.xml</code> across nodes in the background on its own
	— unpredictably and, in this environment, sometimes incorrectly. Multiple test designs were
	tried in the past and caused real damage to this suite's own live "ccs" REST mapping (rooted at
	.../ccssuite/restCFCs, registered at application startup and used internally throughout this
	suite):</p>
	<ul>
		<li>An active-push design (pushing the create to peer nodes, each registering against its
		own local path) hung CF's entire JAX-RS/REST layer outright after a small number of
		register/deploy cycles, requiring a full server restart to clear.</li>
		<li>The same design, retried once after a restart, completed without hanging but silently
		corrupted a peer node's live "ccs" mapping — its root path got overwritten to point at a
		different instance's restCFCs folder, with no visible error.</li>
		<li>A single-node-only design with no active push at all — just one local register+delete
		on the prime node, using the same tolerant "mail-style" verification this suite already
		uses for CCS's unpredictable mail-sync timing — was confirmed, via a passive file monitor
		running before/during/after the test with nothing else touching the file, to still trigger
		the same cross-instance corruption at the time.</li>
	</ul>
	<p>The tests below (Root Path, Host, Service Mapping, Set as default application) all use the
	same single-node, no-active-push design as the third bullet above, targeting a dedicated test
	path/mapping ("CCSTestRestService") that is never the live "ccs" mapping. They're included
	despite the history above at explicit request; if the "ccs" mapping's own entry in
	neo-jaxrs.xml on any instance is ever found altered after running these, treat it as the same
	class of CCS bug documented here, not a regression in the test code, and repair
	neo-jaxrs.xml/verify "ccs" on all instances before trusting this suite's own REST-based
	behavior again.</p>
	<ul>
		<li><a href="restServiceRootPath.cfm">Root Path</a></li>
		<li><a href="restServiceHost.cfm">Host [:Port]</a></li>
		<li><a href="restServiceMapping.cfm">Service Mapping</a></li>
		<li><a href="restServiceIsDefault.cfm">Set as default application</a></li>
	</ul>
</cfoutput>
