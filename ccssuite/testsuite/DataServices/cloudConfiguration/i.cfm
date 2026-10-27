<!--- Cloud Configuration test index - covers the Data & Services > Cloud Configuration admin page --->
<cfoutput>
	<h2>Cloud Configuration Tests</h2>
	<p><a href="../i.cfm">&larr; Data &amp; Services</a></p>

	<h3>Common &amp; AWS S3 Tests</h3>
	<ul>
		<li><a href="configAlias.cfm">Config Alias (registration)</a></li>
		<li><a href="serviceName.cfm">Service Name</a></li>
		<li><a href="apiCallAttemptTimeout.cfm">API Call Attempt Timeout (S3)</a></li>
		<li><a href="apiCallTimeout.cfm">API Call Timeout (S3)</a></li>
		<li><a href="pathStyleAccessEnabled.cfm">Path Style Access Enabled (S3)</a></li>
		<li><a href="accelerateModeEnabled.cfm">Accelerate Mode Enabled (S3)</a></li>
		<li><a href="dualStackEnabled.cfm">Dual Stack Enabled (S3)</a></li>
		<li><a href="checksumValidationEnabled.cfm">Checksum Validation Enabled (S3)</a></li>
		<li><a href="chunkedEncodingEnabled.cfm">Chunked Encoding Enabled (S3)</a></li>
		<li><a href="connectionAcquisitionTimeout.cfm">Connection Acquisition Timeout (S3)</a></li>
		<li><a href="connectionMaxIdleTime.cfm">Connection Max Idle Time (S3)</a></li>
		<li><a href="connectionTimeout.cfm">Connection Timeout (S3)</a></li>
		<li><a href="connectionTimeToLive.cfm">Connection Time to Live (S3)</a></li>
		<li><a href="expectContinueEnabled.cfm">Expect continue enabled (S3)</a></li>
		<li><a href="maxConnections.cfm">Max connections (S3)</a></li>
		<li><a href="socketTimeout.cfm">Socket Timeout (S3)</a></li>
		<li><a href="nonProxyHosts.cfm">Non proxy hosts (S3)</a></li>
		<li><a href="ntlmDomain.cfm">Ntlm Domain (S3)</a></li>
		<li><a href="ntlmWorkstation.cfm">Ntlm Workstation (S3)</a></li>
		<li><a href="proxyUsername.cfm">Proxy Username (S3)</a></li>
		<li><a href="proxyPassword.cfm">Proxy Password (S3)</a></li>
		<li><a href="proxyEndpoint.cfm">Proxy Endpoint (S3)</a></li>
		<li><a href="numberOfRetries.cfm">Number of Retries (S3)</a></li>
		<li><a href="retryConditionType.cfm">Retry Conditions (AND/OR) (S3)</a></li>
		<li><a href="retryConditions.cfm">Retry Conditions (Condition 1 &amp; 2) (S3)</a></li>
		<li><a href="retryCondition1StatusCodes.cfm">Retry Conditions - Condition 1 Status Codes (S3)</a></li>
		<li><a href="retryCondition2StatusCodes.cfm">Retry Conditions - Condition 2 Status Codes (S3)</a></li>
		<li><a href="backoffStrategyType.cfm">Backoff Strategy Type (S3)</a></li>
		<li><a href="backoffBaseDelay.cfm">Backoff Strategy - Base Delay (S3)</a></li>
		<li><a href="backoffMaxBackoffTime.cfm">Backoff Strategy - Max Backoff Time (S3)</a></li>
		<li><a href="backoffFixedDelay.cfm">Backoff Strategy - Fixed Delay (S3)</a></li>
		<li><a href="throttleBackoffStrategyType.cfm">Throttle Backoff Strategy Type (S3)</a></li>
		<li><a href="throttleBackoffBaseDelay.cfm">Throttle Backoff Strategy - Base Delay (S3)</a></li>
		<li><a href="throttleBackoffMaxBackoffTime.cfm">Throttle Backoff Strategy - Max Backoff Time (S3)</a></li>
		<li><a href="throttleBackoffFixedDelay.cfm">Throttle Backoff Strategy - Fixed Delay (S3)</a></li>
	</ul>

	<h3>AWS SQS Tests (18 fields)</h3>
	<ul>
		<li><a href="awsSqs_apiCallAttemptTimeout.cfm">SQS - API Call Attempt Timeout</a></li>
		<li><a href="awsSqs_apiCallTimeout.cfm">SQS - API Call Timeout</a></li>
		<li><a href="awsSqs_connectionAcquisitionTimeout.cfm">SQS - Connection Acquisition Timeout</a></li>
		<li><a href="awsSqs_connectionMaxIdleTime.cfm">SQS - Connection Max Idle Time</a></li>
		<li><a href="awsSqs_connectionTimeout.cfm">SQS - Connection Timeout</a></li>
		<li><a href="awsSqs_connectionTimeToLive.cfm">SQS - Connection Time to Live</a></li>
		<li><a href="awsSqs_expectContinueEnabled.cfm">SQS - Expect continue enabled</a></li>
		<li><a href="awsSqs_maxConnections.cfm">SQS - Max connections</a></li>
		<li><a href="awsSqs_socketTimeout.cfm">SQS - Socket Timeout</a></li>
		<li><a href="awsSqs_useIdleConnectionReaper.cfm">SQS - Use Idle Connection Reaper</a></li>
		<li><a href="awsSqs_nonProxyHosts.cfm">SQS - Non proxy hosts</a></li>
		<li><a href="awsSqs_ntlmDomain.cfm">SQS - Ntlm Domain</a></li>
		<li><a href="awsSqs_ntlmWorkstation.cfm">SQS - Ntlm Workstation</a></li>
		<li><a href="awsSqs_proxyUsername.cfm">SQS - Username</a></li>
		<li><a href="awsSqs_proxyPassword.cfm">SQS - Password</a></li>
		<li><a href="awsSqs_proxyEndpoint.cfm">SQS - Endpoint</a></li>
		<li><a href="awsSqs_preemptiveBasicAuthEnabled.cfm">SQS - Preemptive basic Auth Enabled</a></li>
		<li><a href="awsSqs_numRetries.cfm">SQS - Number of Retries</a></li>
	</ul>

	<h3>AWS SNS Tests (18 fields)</h3>
	<ul>
		<li><a href="awsSns_apiCallAttemptTimeout.cfm">SNS - API Call Attempt Timeout</a></li>
		<li><a href="awsSns_apiCallTimeout.cfm">SNS - API Call Timeout</a></li>
		<li><a href="awsSns_connectionAcquisitionTimeout.cfm">SNS - Connection Acquisition Timeout</a></li>
		<li><a href="awsSns_connectionMaxIdleTime.cfm">SNS - Connection Max Idle Time</a></li>
		<li><a href="awsSns_connectionTimeout.cfm">SNS - Connection Timeout</a></li>
		<li><a href="awsSns_connectionTimeToLive.cfm">SNS - Connection Time to Live</a></li>
		<li><a href="awsSns_expectContinueEnabled.cfm">SNS - Expect continue enabled</a></li>
		<li><a href="awsSns_maxConnections.cfm">SNS - Max connections</a></li>
		<li><a href="awsSns_socketTimeout.cfm">SNS - Socket Timeout</a></li>
		<li><a href="awsSns_useIdleConnectionReaper.cfm">SNS - Use Idle Connection Reaper</a></li>
		<li><a href="awsSns_nonProxyHosts.cfm">SNS - Non proxy hosts</a></li>
		<li><a href="awsSns_ntlmDomain.cfm">SNS - Ntlm Domain</a></li>
		<li><a href="awsSns_ntlmWorkstation.cfm">SNS - Ntlm Workstation</a></li>
		<li><a href="awsSns_proxyUsername.cfm">SNS - Username</a></li>
		<li><a href="awsSns_proxyPassword.cfm">SNS - Password</a></li>
		<li><a href="awsSns_proxyEndpoint.cfm">SNS - Endpoint</a></li>
		<li><a href="awsSns_preemptiveBasicAuthEnabled.cfm">SNS - Preemptive basic Auth Enabled</a></li>
		<li><a href="awsSns_numRetries.cfm">SNS - Number of Retries</a></li>
	</ul>

	<h3>AWS DynamoDB Tests (18 fields)</h3>
	<ul>
		<li><a href="awsDynamo_apiCallAttemptTimeout.cfm">DYNAMODB - API Call Attempt Timeout</a></li>
		<li><a href="awsDynamo_apiCallTimeout.cfm">DYNAMODB - API Call Timeout</a></li>
		<li><a href="awsDynamo_connectionAcquisitionTimeout.cfm">DYNAMODB - Connection Acquisition Timeout</a></li>
		<li><a href="awsDynamo_connectionMaxIdleTime.cfm">DYNAMODB - Connection Max Idle Time</a></li>
		<li><a href="awsDynamo_connectionTimeout.cfm">DYNAMODB - Connection Timeout</a></li>
		<li><a href="awsDynamo_connectionTimeToLive.cfm">DYNAMODB - Connection Time to Live</a></li>
		<li><a href="awsDynamo_expectContinueEnabled.cfm">DYNAMODB - Expect continue enabled</a></li>
		<li><a href="awsDynamo_maxConnections.cfm">DYNAMODB - Max connections</a></li>
		<li><a href="awsDynamo_socketTimeout.cfm">DYNAMODB - Socket Timeout</a></li>
		<li><a href="awsDynamo_useIdleConnectionReaper.cfm">DYNAMODB - Use Idle Connection Reaper</a></li>
		<li><a href="awsDynamo_nonProxyHosts.cfm">DYNAMODB - Non proxy hosts</a></li>
		<li><a href="awsDynamo_ntlmDomain.cfm">DYNAMODB - Ntlm Domain</a></li>
		<li><a href="awsDynamo_ntlmWorkstation.cfm">DYNAMODB - Ntlm Workstation</a></li>
		<li><a href="awsDynamo_proxyUsername.cfm">DYNAMODB - Username</a></li>
		<li><a href="awsDynamo_proxyPassword.cfm">DYNAMODB - Password</a></li>
		<li><a href="awsDynamo_proxyEndpoint.cfm">DYNAMODB - Endpoint</a></li>
		<li><a href="awsDynamo_preemptiveBasicAuthEnabled.cfm">DYNAMODB - Preemptive basic Auth Enabled</a></li>
		<li><a href="awsDynamo_numRetries.cfm">DYNAMODB - Number of Retries</a></li>
	</ul>

	<h3>Azure Blob Storage Tests (16 fields)</h3>
	<ul>
		<li><a href="azureBlob_concReqCount.cfm">Azure Blob - Concurrent Request Count</a></li>
		<li><a href="azureBlob_singleBlobPutThresholdInBytes.cfm">Azure Blob - Single block size in bytes</a></li>
		<li><a href="azureBlob_timeoutIntervalInMs.cfm">Azure Blob - Timeout Interval (ms)</a></li>
		<li><a href="azureBlob_maximumExecutionTimeInMs.cfm">Azure Blob - Maximum Execution time (ms)</a></li>
		<li><a href="azureBlob_locationMode.cfm">Azure Blob - Location mode</a></li>
		<li><a href="azureBlob_useTransContentMD5.cfm">Azure Blob - Use Transactional Content</a></li>
		<li><a href="azureBlob_disableContentMD5Validation.cfm">Azure Blob - Disable content validation</a></li>
		<li><a href="azureBlob_storeBlobContentMD5.cfm">Azure Blob - Store BLOB content</a></li>
		<li><a href="azureBlob_absorbConditionalErrorsOnRetry.cfm">Azure Blob - Absorb Conditional Errors on Retry</a></li>
		<li><a href="azureBlob_skipEtagLocking.cfm">Azure Blob - Skip Etag Locking</a></li>
		<li><a href="azureBlob_retryPolicyType.cfm">Azure Blob - Retry Policy Type</a></li>
		<li><a href="azureBlob_deltaBackoffIntervalInMs.cfm">Azure Blob - Delta Backoff Interval (ms)</a></li>
		<li><a href="azureBlob_maximumAttempts.cfm">Azure Blob - Maximum attempts</a></li>
		<li><a href="azureBlob_resolvedMinBackoff.cfm">Azure Blob - Resolved Minimum backoff (ms)</a></li>
		<li><a href="azureBlob_resolvedMaxBackoff.cfm">Azure Blob - Resolved Maximum Backoff (ms)</a></li>
		<li><a href="azureBlob_enableLogging.cfm">Azure Blob - Enable logging</a></li>
	</ul>

	<h3>Azure Service Bus Tests (2 fields)</h3>
	<ul>
		<li><a href="azureSb_opTimeout.cfm">Azure Service Bus - Operation Timeout</a></li>
		<li><a href="azureSb_retryPolicyType.cfm">Azure Service Bus - Retry Policy</a></li>
	</ul>

	<h3>GCP Firestore Tests (15 fields)</h3>
	<ul>
		<li><a href="gcpFs_host.cfm">GCP Firestore - Host</a></li>
		<li><a href="gcpFs_databaseId.cfm">GCP Firestore - Database Id</a></li>
		<li><a href="gcpFs_emulatorHost.cfm">GCP Firestore - Emulator Host</a></li>
		<li><a href="gcpFs_initialRetryDelay.cfm">GCP Firestore - Initial Retry Delay</a></li>
		<li><a href="gcpFs_maxRetryDelay.cfm">GCP Firestore - Max Retry Delay</a></li>
		<li><a href="gcpFs_retryDelayMultiplier.cfm">GCP Firestore - Retry Delay Multiplier</a></li>
		<li><a href="gcpFs_initialRpcTimeout.cfm">GCP Firestore - Initial RPC Timeout</a></li>
		<li><a href="gcpFs_maxRpcTimeout.cfm">GCP Firestore - Max RPC Timeout</a></li>
		<li><a href="gcpFs_rpcTimeoutMultiplier.cfm">GCP Firestore - RPC Timeout Multiplier</a></li>
		<li><a href="gcpFs_maxAttempts.cfm">GCP Firestore - Max Attempts</a></li>
		<li><a href="gcpFs_totalTimeout.cfm">GCP Firestore - Total Timeout</a></li>
		<li><a href="gcpFs_keepAliveTime.cfm">GCP Firestore - Keep Alive Time</a></li>
		<li><a href="gcpFs_keepAliveTimeout.cfm">GCP Firestore - Keep Alive Timeout</a></li>
		<li><a href="gcpFs_keepAliveWithoutCalls.cfm">GCP Firestore - Keep Alive Without Calls</a></li>
		<li><a href="gcpFs_maxInboundMessageSize.cfm">GCP Firestore - Max Inbound Message Size</a></li>
	</ul>

	<h3>GCP Storage Tests (11 fields)</h3>
	<ul>
		<li><a href="gcpStorage_host.cfm">GCP Storage - Host</a></li>
		<li><a href="gcpStorage_connectTimeout.cfm">GCP Storage - Connect Timeout</a></li>
		<li><a href="gcpStorage_readTimeout.cfm">GCP Storage - Read Timeout</a></li>
		<li><a href="gcpStorage_initialRetryDelay.cfm">GCP Storage - Initial Retry Delay</a></li>
		<li><a href="gcpStorage_maxRetryDelay.cfm">GCP Storage - Max Retry Delay</a></li>
		<li><a href="gcpStorage_retryDelayMultiplier.cfm">GCP Storage - Retry Delay Multiplier</a></li>
		<li><a href="gcpStorage_initialRpcTimeout.cfm">GCP Storage - Initial RPC Timeout</a></li>
		<li><a href="gcpStorage_maxRpcTimeout.cfm">GCP Storage - Max RPC Timeout</a></li>
		<li><a href="gcpStorage_rpcTimeoutMultiplier.cfm">GCP Storage - RPC Timeout Multiplier</a></li>
		<li><a href="gcpStorage_maxAttempts.cfm">GCP Storage - Max Attempts</a></li>
		<li><a href="gcpStorage_totalTimeout.cfm">GCP Storage - Total Timeout</a></li>
	</ul>

	<h3>GCP Pubsub Tests (34 fields)</h3>
	<ul>
		<li><a href="gcpPubsub_publisherEndpoint.cfm">GCP PubSub - Publisher Endpoint</a></li>
		<li><a href="gcpPubsub_isCompressionEnabled.cfm">GCP PubSub - Enable Compression</a></li>
		<li><a href="gcpPubsub_compressionBytesThreshold.cfm">GCP PubSub - Compression Bytes Threshold</a></li>
		<li><a href="gcpPubsub_isMessageOrderingEnabled.cfm">GCP PubSub - Enable Message Ordering</a></li>
		<li><a href="gcpPubsub_executorProviderThreadCount.cfm">GCP PubSub - Executor Provider Thread Count (Publisher)</a></li>
		<li><a href="gcpPubsub_executorProviderThreadNamePrefix.cfm">GCP PubSub - Executor Provider Thread Name Prefix (Publisher)</a></li>
		<li><a href="gcpPubsub_isBatchingSettingsEnabled.cfm">GCP PubSub - Enable Batching</a></li>
		<li><a href="gcpPubsub_batchingSettingsDelayThreshold.cfm">GCP PubSub - Delay Threshold</a></li>
		<li><a href="gcpPubsub_batchingSettingsElementCountThreshold.cfm">GCP PubSub - Element Count Threshold</a></li>
		<li><a href="gcpPubsub_batchingSettingsRequestByteThreshold.cfm">GCP PubSub - Request Byte Threshold</a></li>
		<li><a href="gcpPubsub_flowControlSettingsLimitExceededBehavior.cfm">GCP PubSub - Limit Exceeded Behavior (Publisher)</a></li>
		<li><a href="gcpPubsub_flowControlSettingsMaxOutstandingElementCount.cfm">GCP PubSub - Max Outstanding Element Count (Publisher)</a></li>
		<li><a href="gcpPubsub_flowControlSettingsMaxOutstandingRequestBytes.cfm">GCP PubSub - Max Outstanding Request Bytes (Publisher)</a></li>
		<li><a href="gcpPubsub_initialRetryDelay.cfm">GCP PubSub - Initial Retry Delay (Publisher)</a></li>
		<li><a href="gcpPubsub_maxRetryDelay.cfm">GCP PubSub - Max Retry Delay (Publisher)</a></li>
		<li><a href="gcpPubsub_retryDelayMultiplier.cfm">GCP PubSub - Retry Delay Multiplier (Publisher)</a></li>
		<li><a href="gcpPubsub_initialRpcTimeout.cfm">GCP PubSub - Initial RPC Timeout (Publisher)</a></li>
		<li><a href="gcpPubsub_maxRpcTimeout.cfm">GCP PubSub - Max RPC Timeout (Publisher)</a></li>
		<li><a href="gcpPubsub_rpcTimeoutMultiplier.cfm">GCP PubSub - RPC Timeout Multiplier (Publisher)</a></li>
		<li><a href="gcpPubsub_maxAttempts.cfm">GCP PubSub - Max Attempts (Publisher)</a></li>
		<li><a href="gcpPubsub_totalTimeout.cfm">GCP PubSub - Total Timeout (Publisher)</a></li>
		<li><a href="gcpPubsub_subscriberEndpoint.cfm">GCP PubSub - Subscriber Endpoint</a></li>
		<li><a href="gcpPubsub_parallelPullCount.cfm">GCP PubSub - Parallel Pull Count</a></li>
		<li><a href="gcpPubsub_subExecutorProviderThreadCount.cfm">GCP PubSub - Executor Provider Thread Count (Subscriber)</a></li>
		<li><a href="gcpPubsub_subExecutorProviderThreadNamePrefix.cfm">GCP PubSub - Executor Provider Thread Name Prefix (Subscriber)</a></li>
		<li><a href="gcpPubsub_subSystemExecutorProviderThreadCount.cfm">GCP PubSub - System Executor Provider Thread Count (Subscriber)</a></li>
		<li><a href="gcpPubsub_subSystemExecutorProviderThreadNamePrefix.cfm">GCP PubSub - System Executor Provider Thread Name Prefix (Subscriber)</a></li>
		<li><a href="gcpPubsub_maxAckExtensionPeriod.cfm">GCP PubSub - Max Ack Extension Period</a></li>
		<li><a href="gcpPubsub_minDurationPerAckExtensionPeriod.cfm">GCP PubSub - Min Duration Per Ack Extension Period</a></li>
		<li><a href="gcpPubsub_maxDurationPerAckExtensionPeriod.cfm">GCP PubSub - Max Duration Per Ack Extension Period</a></li>
		<li><a href="gcpPubsub_subFlowControlSettingsLimitExceededBehavior.cfm">GCP PubSub - Limit Exceeded Behavior (Subscriber)</a></li>
		<li><a href="gcpPubsub_subFlowControlSettingsMaxOutstandingElementCount.cfm">GCP PubSub - Max Outstanding Element Count (Subscriber)</a></li>
		<li><a href="gcpPubsub_subFlowControlSettingsMaxOutstandingRequestBytes.cfm">GCP PubSub - Max Outstanding Request Bytes (Subscriber)</a></li>
		<li><a href="gcpPubsub_useLegacyFlowControl.cfm">GCP PubSub - Use Legacy Flow Control</a></li>
	</ul>
</cfoutput>
