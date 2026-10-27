<!--- RAG testsuite index --->
<cfoutput>
	<h2>RAG Tests</h2>
	<p><a href="../i.cfm">&larr; AI Services</a></p>
	<p>RAG (<code>ai/rag/ingestion.cfm</code>) manages document ingestion pipelines into vector databases.
	These tests verify multi-node Central Config Server (CCS) replication and consistency across cluster instances.</p>

	<h3>Target Selection</h3>
	<ul>
		<li><a href="vectorStoreAlias.cfm">Vector Store Alias</a></li>
		<li><a href="embeddingModelOverride.cfm">Embedding Model Override</a></li>
	</ul>

	<h3>Source Configuration</h3>
	<ul>
		<li><a href="sourceType.cfm">Source Type</a></li>
		<li><a href="sourceTypeSingleFile.cfm">Source Type Single File</a></li>
		<li><a href="sourceTypeDirectory.cfm">Source Type Directory</a></li>
		<li><a href="sourceTypeUrl.cfm">Source Type URL</a></li>
		<li><a href="filePath.cfm">File Path</a></li>
		<li><a href="directoryPath.cfm">Directory Path</a></li>
		<li><a href="urlPath.cfm">URL Path</a></li>
	</ul>

	<h3>Parsing</h3>
	<ul>
		<li><a href="parserType.cfm">Parser Type</a></li>
		<li><a href="charset.cfm">Charset</a></li>
		<li><a href="maxFileSize.cfm">Max File Size</a></li>
		<li><a href="recursive.cfm">Recursive</a></li>
		<li><a href="filePattern.cfm">File Pattern</a></li>
		<li><a href="patternType.cfm">Pattern Type</a></li>
	</ul>

	<h3>Processing</h3>
	<ul>
		<li><a href="parallel.cfm">Parallel Processing</a></li>
		<li><a href="maxThreads.cfm">Max Threads</a></li>
		<li><a href="connectionTimeout.cfm">Connection Timeout</a></li>
		<li><a href="readTimeout.cfm">Read Timeout</a></li>
		<li><a href="urlMaxRetries.cfm">URL Max Retries</a></li>
		<li><a href="userAgent.cfm">User Agent</a></li>
	</ul>

	<h3>Chunking / Splitting</h3>
	<ul>
		<li><a href="splitterType.cfm">Splitter Type</a></li>
		<li><a href="chunkSize.cfm">Chunk Size</a></li>
		<li><a href="chunkOverlap.cfm">Chunk Overlap</a></li>
		<li><a href="regexPattern.cfm">Regex Pattern</a></li>
		<li><a href="customSeparators.cfm">Custom Separators</a></li>
		<li><a href="batchSize.cfm">Batch Size</a></li>
		<li><a href="continueOnError.cfm">Continue On Error</a></li>
	</ul>
</cfoutput>
