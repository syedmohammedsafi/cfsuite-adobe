<!---
* @file  generateSp.cfm
* @description Generate Service Provider from template — multi-node CCS sync test
--->
<h2>Generate Service Provider (SP Configuration)</h2>
<p>File: security/spConfiguration/generateSp.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "SpGenerate";
		syncTestResult = { apiArea = "spconfiguration", settingName = SETTING_NAME, scriptPath = CGI.SCRIPT_NAME };
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runSpSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-SpConfiguration-#SETTING_NAME#">
		<cfscript>
			writeOutput(secUtil.getQatestResultMessage(syncTestResult.passed));
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
			secUtil.restoreSecuritySyncTest(testDvr, syncTestResult);
		</cfscript>
	</cffinally>
</cftry>
