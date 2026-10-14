<!---
* @file  useSingleRdsPassword.cfm
* @description RDS Authentication — Use a single password only (default) — multi-node CCS sync test.
* Uses the RdsSinglePasswordOnly alias (securityConfigUtil.cfc) rather than the bare UseSingleRdsPassword
* setting: the generic sync engine's getNewSetValueForSetting() only ever computes "current -> the OTHER
* value" from whatever state happens to be live when the test runs, so sharing the bare setting name with
* useSeparateRdsUserAuth.cfm wouldn't actually guarantee THIS option gets set and verified across all nodes
* on every run -- only whichever direction the toggle happened to go. The alias forces true regardless of
* current state; useSeparateRdsUserAuth.cfm's alias forces false the same way.
--->
<h2>RDS Authentication — Single Password Only</h2>
<p>File: security/rds/useSingleRdsPassword.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "RdsSinglePasswordOnly";
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
