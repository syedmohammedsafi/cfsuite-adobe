<!---
* @file  clientCertSubjectHeader.cfm
* @description Client certificate subject header name — multi-node CCS sync test
--->
<h2>Subject Header Name</h2>
<p>File: security/settings/clientCertSubjectHeader.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "ClientCertSubjectHeader";
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