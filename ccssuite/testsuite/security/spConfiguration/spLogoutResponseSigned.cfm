<!---
* @file  spLogoutResponseSigned.cfm
* @description SP Logout Response Signed — multi-node CCS sync test
--->
<h2>SP Logout Response Signed (SP Configuration)</h2>
<p>File: security/spConfiguration/spLogoutResponseSigned.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "SpLogoutResponseSigned";
		syncTestResult = { apiArea = "spconfiguration", settingName = SETTING_NAME, scriptPath = CGI.SCRIPT_NAME, isSpFieldTest = true };
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runSpFieldSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
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
