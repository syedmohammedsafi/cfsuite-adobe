<!--- ColdFusion Collections test index — covers the Data & Services > ColdFusion Collections admin page (Solr) --->
<cfoutput>
	<h2>ColdFusion Collections Tests</h2>
	<p><a href="../i.cfm">&larr; Data &amp; Services</a></p>
	<ul>
		<li><a href="collectionTermHighlighting.cfm">Term Highlighting (create, toggle, verify, delete)</a></li>
	</ul>
	<p><em>Note:</em> collections are physical Solr indexes on local disk
	(<code>cfusion/jetty/multicore/collections/&lt;name&gt;</code>) — confirmed a collection
	created on one instance is not visible on a peer instance, so this test is scoped to
	<code>nodesScope="currentPort"</code>, same as the Charting cache path test. The test
	creates a fresh <code>CCSTestCollection</code>, toggles its Term Highlighting setting via
	<code>CFIDE.adminapi.collections</code> and verifies the change, then deletes the
	collection entirely in a <code>cffinally</code> block.</p>
</cfoutput>
