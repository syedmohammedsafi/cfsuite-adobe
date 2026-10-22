<!---
* @file  rdsOldPassword.cfm
* @description Old RDS Password — multi-node CCS sync test
--->
<h2>Old RDS Password</h2>
<p>File: security/rds/rdsOldPassword.cfm</p>
<br>
<cfscript>
	SETTING_NAME = "RdsOldPassword";
	syncTestResult = {};
	testDvr = new cfsuite.ccssuite.testDriver();
	secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
</cfscript>
<cftry>
	<cfscript>
		syncTestResult = secUtil.runSecuritySyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-RDS-#SETTING_NAME#">
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
			if(structKeyExists(variables, "secUtil") AND structKeyExists(variables, "testDvr") AND structKeyExists(variables, "syncTestResult")){
				secUtil.restoreSecuritySyncTest(testDvr, syncTestResult);
			}
		</cfscript>
	</cffinally>
</cftry>
