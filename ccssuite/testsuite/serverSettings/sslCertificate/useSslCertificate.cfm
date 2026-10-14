<!---
* @file  useSslCertificate.cfm
* @description Use SSL Certificate (UseSslCertificate) — server.xml round-trip test
*
* The Existing/Create radio itself has no real persisted state in CF admin — it's a pure UI
* selector, never written to server.xml as a separate flag. This test uses a synthetic stand-in:
* whether the <Certificate .../> element exists at all inside the still-commented <SSLHostConfig>
* block (present = an existing cert configured, absent = none). It is NOT the literal radio state,
* just a safe, inert boolean to exercise the same round-trip pattern as the other three fields.
* Adding/removing the element stays entirely inside the comment — never uncomments the SSL
* connector, never touches the live port-8500 HTTP connector. Runs with nodesScope="all": pushed
* to same-cluster/environment peers only (see certificateLocation.cfm), same as the other fields.
--->
<h2>Use SSL Certificate</h2>
<p>File: useSslCertificate.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "UseSslCertificate";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME, true, "all", true);
	</cfscript>

	<cf_qatest id="test-Server_Settings-SSL_Certificate-#SETTING_NAME#">
		<cfscript>
			writeOutput(stUtil.getQatestResultMessage(syncTestResult.passed));
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
			stUtil.restoreMultiNodeSyncTest(testDvr, syncTestResult, SETTING_NAME);
		</cfscript>
	</cffinally>
</cftry>
