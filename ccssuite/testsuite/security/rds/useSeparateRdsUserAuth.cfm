<!---
* @file  useSeparateRdsUserAuth.cfm
* @description RDS Authentication — Separate user name and password authentication (allows multiple users)
* — multi-node CCS sync test. Uses the RdsSeparateUserAuth alias (securityConfigUtil.cfc) rather than the
* bare UseSingleRdsPassword setting -- see useSingleRdsPassword.cfm for why: this alias forces false
* regardless of current state, so this option is genuinely set and verified across all nodes on every run,
* not just whichever direction the bare setting's toggle happened to go.
--->
<h2>RDS Authentication — Separate User Name and Password</h2>
<p>File: security/rds/useSeparateRdsUserAuth.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "RdsSeparateUserAuth";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
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
			secUtil.restoreSecuritySyncTest(testDvr, syncTestResult);
		</cfscript>
	</cffinally>
</cftry>
