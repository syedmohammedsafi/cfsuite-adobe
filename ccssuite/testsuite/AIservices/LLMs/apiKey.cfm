<!---
* @file  apiKey.cfm
* @description LLM API Key (apiKey) — multi-node CCS sync test
--->
<h2>API Key</h2>
<p>File: apiKey.cfm</p>
<br>
<cftry>
	<cfscript>
		final TEST_ALIAS = "CCSTestLLM";
		final FIELD_NAME = "apiKey";
		testDvr = new cfsuite.ccssuite.testDriver();
		aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		syncTestResult = aiUtil.runLLMFieldSyncTest(testDvr, TEST_ALIAS, FIELD_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-AI_Services-LLMs-#FIELD_NAME#">
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
			if(structKeyExists(variables, "aiUtil") AND isObject(aiUtil)
					AND structKeyExists(variables, "testDvr") AND isObject(testDvr)
					AND structKeyExists(variables, "syncTestResult") AND isStruct(syncTestResult))
				aiUtil.restoreLLMSyncTest(testDvr, syncTestResult, TEST_ALIAS);
		</cfscript>
	</cffinally>
</cftry>