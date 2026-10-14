<!---
* @file  llmConfig.cfm
* @description Full LLM configuration (all option groups) — multi-node CCS sync test
--->
<h2>LLM Configuration (full)</h2>
<p>File: llmConfig.cfm</p>
<br>
<cftry>
	<cfscript>
		final TEST_ALIAS = "CCSTestLLM";
		testDvr = new cfsuite.ccssuite.testDriver();
		aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		syncTestResult = aiUtil.runFullLLMSyncTest(testDvr, TEST_ALIAS, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-AI_Services-LLMs-fullConfig">
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
			aiUtil.restoreLLMSyncTest(testDvr, syncTestResult, TEST_ALIAS);
		</cfscript>
	</cffinally>
</cftry>
