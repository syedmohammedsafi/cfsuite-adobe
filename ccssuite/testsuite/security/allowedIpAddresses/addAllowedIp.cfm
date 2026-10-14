<!---
* @file  addAllowedIp.cfm
* @description Add allowed admin IP address (IP Address text field) — multi-node CCS sync test
--->
<h2>Add Allowed Admin IP (Allowed IP Addresses)</h2>
<p>File: security/allowedIpAddresses/addAllowedIp.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "AllowedAdminIpAdd";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runAllowedIpSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-AllowedIpAddresses-#SETTING_NAME#">
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
