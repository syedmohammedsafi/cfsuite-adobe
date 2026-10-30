<!---
* @file  rdsNoAuth.cfm
* @description RDS Authentication - No authentication needed (not recommended) - multi-node CCS sync test
--->
<h2>RDS Authentication - No authentication needed (not recommended)</h2>
<p>File: security/rds/rdsNoAuth.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "RdsSecurityEnabled";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runSecuritySyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-RDS-#SETTING_NAME#-NoAuth">
		<cfscript>
			writeOutput(secUtil.getQatestResultMessage(syncTestResult.passed, SETTING_NAME));
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
