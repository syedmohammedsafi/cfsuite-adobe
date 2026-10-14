<!---
* @file  distinguishedName.cfm
* @description Distinguished Name (DistinguishedName) — server.xml round-trip test, synthetic
*
* The Create radio's Distinguished Name field (e.g. "CN=host,OU=...") has no real persisted state
* to test at all — unlike Https/Http, there isn't even an existing real element to represent it.
* It only ever exists transiently in the Create form, consumed by generateKeyAndCertificate() to
* build a brand-new self-signed cert — the same certificate-generation risk already excluded from
* real testing (see i.cfm). This is a synthetic string-value round-trip only: a custom attribute
* (data-ccstest-distinguished-name) added to/updated on the same already-inert commented
* <Certificate .../> tag the Existing fields use. Still 100% inert — never uncomments the SSL
* connector, never touches the live port-8500 HTTP connector. Runs with nodesScope="all": pushed
* to same-cluster/environment peers only, same as the other SSL Certificate fields.
--->
<h2>Distinguished Name</h2>
<p>File: distinguishedName.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "DistinguishedName";
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
