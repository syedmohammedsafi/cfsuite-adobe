<!---
* @file  serverlessRegion.cfm
* @description Vector Store Region (serverlessRegion) — multi-node CCS sync test
--->
<h2>Region</h2>
<p>File: serverlessRegion.cfm</p>
<br>
<cftry>
	<cfscript>
		final TEST_ALIAS = "CCSTestPinecone";
		final FIELD_NAME = "serverlessRegion";
		testDvr = new cfsuite.ccssuite.testDriver();
		aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		syncTestResult = aiUtil.runVectorStoreFieldSyncTest(testDvr, TEST_ALIAS, FIELD_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-AI_Services-Vector_Stores-#FIELD_NAME#">
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
