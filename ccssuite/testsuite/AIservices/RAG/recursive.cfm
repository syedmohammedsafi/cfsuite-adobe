<!---
* @file  recursive.cfm
* @description RAG Include Subdirectories (recursive) â€” multi-node CCS sync test
--->
<h2>Recursive</h2>
<p>File: recursive.cfm</p>
<br>
<cftry>
	<cfscript>
		final TEST_ALIAS = "CCSTestRAG";
		final FIELD_NAME = "recursive";
		testDvr = new cfsuite.ccssuite.testDriver();
		aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		syncTestResult = aiUtil.runRagFieldSyncTest(testDvr, TEST_ALIAS, FIELD_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-AI_Services-RAG-#FIELD_NAME#">
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
			aiUtil.restoreRagSyncTest(testDvr, syncTestResult, TEST_ALIAS);
		</cfscript>
	</cffinally>
</cftry>