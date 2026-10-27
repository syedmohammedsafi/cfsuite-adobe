<!---
* @file  chromaConfig.cfm
* @description Chroma Vector Store Configuration (full) — multi-node CCS sync test
--->
<h2>Chroma Vector Store Configuration</h2>
<p>File: chromaConfig.cfm</p>
<br>
<cftry>
	<cfscript>
		final TEST_ALIAS = "CCSTestChroma";
		testDvr = new cfsuite.ccssuite.testDriver();
		aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		syncTestResult = aiUtil.runFullVectorStoreSyncTest(testDvr, TEST_ALIAS, CGI.SCRIPT_NAME, aiUtil.getDefaultChromaConfig());
	</cfscript>

	<cf_qatest id="test-AI_Services-Vector_Stores-chromaConfig">
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
