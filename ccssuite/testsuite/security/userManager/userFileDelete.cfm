<!---
* @file  userFileDelete.cfm
* @description File Permission: Delete - multi-node CCS sync test
--->
<h2>File Permission: Delete (User Manager)</h2>
<p>File: security/userManager/userFileDelete.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "UserFileDelete";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runUserManagerSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-UserManager-#SETTING_NAME#">
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
