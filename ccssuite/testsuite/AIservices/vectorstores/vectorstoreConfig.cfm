<!---
* @file  vectorstoreConfig.cfm
* @description Full Vector Store configuration — multi-node CCS sync test
--->
<h2>Milvus Vector Store Configuration</h2>
<p>File: vectorstoreConfig.cfm</p>
<br>
<cftry>
	<cfscript>
		final TEST_ALIAS = "CCSTestVectorStore";
		testDvr = new cfsuite.ccssuite.testDriver();
		aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		syncTestResult = aiUtil.runFullVectorStoreSyncTest(testDvr, TEST_ALIAS, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-AI_Services-Vector_Stores-fullConfig">
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
			aiUtil.restoreVectorStoreSyncTest(testDvr, syncTestResult, TEST_ALIAS);
		</cfscript>
	</cffinally>
</cftry>
