<!--- RAG testsuite index --->
<cfoutput>
	<h2>RAG Tests</h2>
	<p><a href="../i.cfm">&larr; AI Services</a></p>
	<p>RAG (ingestion.cfm) has no persisted settings of its own — it consumes the Vector
	Store config through coldfusion.server.VectorStoreService. This test verifies that
	config is correctly synced and visible via the live service on every CCS node.</p>
	<ul>
		<li><a href="ragVectorStoreVisibility.cfm">Vector Store Visibility (via live VectorStoreService)</a></li>
	</ul>
</cfoutput>
