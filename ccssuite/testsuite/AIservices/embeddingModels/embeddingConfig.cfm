<!---
* @file  embeddingConfig.cfm
* @description Full Embedding Model configuration — multi-node CCS sync test
--->
<h2>Embedding Model Configuration (full)</h2>
<p>File: embeddingConfig.cfm</p>
<br>
<cftry>
	<cfscript>
		final TEST_ALIAS = "CCSTestEmbedding";
		testDvr = new cfsuite.ccssuite.testDriver();
		aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		syncTestResult = aiUtil.runFullEmbeddingSyncTest(testDvr, TEST_ALIAS, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-AI_Services-Embedding_Models-fullConfig">
		<cfscript>
			writeOutput(aiUtil.getQatestResultMessage(syncTestResult.passed));
		</cfscript>
		<cf_expectedresults>
			setting values as expected<br>
		</cf_expectedresults>
	</cf_qatest>
	<cf_qatestEnd stats=true>

	<cfcatch type="any">
		<cfoutput>
			<p>An error occurred in the test: #cfcatch.message# #cfcatch.detail#</p>
		</cfoutput>
	</cfcatch>

	<cffinally>
		<cfscript>
			aiUtil.restoreEmbeddingSyncTest(testDvr, syncTestResult, TEST_ALIAS);
		</cfscript>
	</cffinally>
</cftry>
