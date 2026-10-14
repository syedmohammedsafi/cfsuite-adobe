<!--- Vector Stores testsuite index --->
<cfoutput>
	<h2>Vector Store Tests</h2>
	<p><a href="../i.cfm">&larr; AI Services</a></p>
	<h3>Full configuration</h3>
	<ul>
		<li><a href="vectorstoreConfig.cfm">Vector Store Configuration (all fields)</a></li>
	</ul>
	<h3>Basic configuration</h3>
	<ul>
		<li><a href="provider.cfm">Provider</a></li>
		<li><a href="url.cfm">URL</a></li>
		<li><a href="dimension.cfm">Dimension</a></li>
		<li><a href="collectionName.cfm">Collection Name</a></li>
		<li><a href="databaseName.cfm">Database Name</a></li>
		<li><a href="metricType.cfm">Metric Type</a></li>
		<li><a href="indexType.cfm">Index Type</a></li>
		<li><a href="apiKey.cfm">API Key</a></li>
		<li><a href="username.cfm">Username</a></li>
		<li><a href="password.cfm">Password</a></li>
		<li><a href="topK.cfm">Top K</a></li>
		<li><a href="minScore.cfm">Min Score</a></li>
		<li><a href="embeddingModel.cfm">Embedding Model</a></li>
	</ul>
	<h3>Connection settings</h3>
	<ul>
		<li><a href="callTimeout.cfm">Call Timeout (ms)</a></li>
		<li><a href="connectionTimeout.cfm">Connection Timeout (ms)</a></li>
		<li><a href="keepAlive.cfm">Keep Alive</a></li>
		<li><a href="keepAliveTime.cfm">Keep Alive Time (ms)</a></li>
		<li><a href="keepAliveTimeout.cfm">Keep Alive Timeout (ms)</a></li>
		<li><a href="idleTimeout.cfm">Idle Timeout (ms)</a></li>
		<li><a href="deadline.cfm">Deadline (ms)</a></li>
	</ul>
	<h3>Retry settings</h3>
	<ul>
		<li><a href="maxRetries.cfm">Max Retries</a></li>
		<li><a href="retryOnRateLimit.cfm">Retry On Rate Limit</a></li>
		<li><a href="initialBackoff.cfm">Initial Backoff (ms)</a></li>
		<li><a href="maxBackoff.cfm">Max Backoff (ms)</a></li>
		<li><a href="backOffMultiplier.cfm">Backoff Multiplier</a></li>
	</ul>
</cfoutput>