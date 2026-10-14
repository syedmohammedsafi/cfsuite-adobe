<!---
* @file  enableSecureProfile.cfm
* @description Enable Secure Profile — multi-node CCS sync test
*
* Secure Profile bundles ~10 unrelated settings into one toggle (RDS auth, admin userid required,
* internal Java component access, session timeout, post size, flash policy server, etc.). Some of
* those live outside neo-security.xml, so there's no single-file snapshot to restore from — the
* finally block below just re-toggles the flag back via the same Admin API call, same as every
* other boolean setting in this suite. If that leaves any of the bundled settings changed on a
* node, it has to be fixed by hand on that node's Administrator > Secure Profile page.
--->
<h2>Enable Secure Profile (Security)</h2>
<p>File: security/secureProfile/enableSecureProfile.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "SecureProfileEnabled";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runSecureProfileSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-SecureProfile-#SETTING_NAME#">
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
