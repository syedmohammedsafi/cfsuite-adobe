<!---
* @file  clientCertRootAdminEnabled.cfm
* @description Client certificate auth for root admin — multi-node CCS sync test
--->
<h2>Enable for Root Admin</h2>
<p>File: security/settings/clientCertRootAdminEnabled.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "ClientCertRootAdminEnabled";
		syncTestResult = { apiArea = "settings", settingName = SETTING_NAME, scriptPath = CGI.SCRIPT_NAME };
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runSettingsSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-Settings-#SETTING_NAME#">
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