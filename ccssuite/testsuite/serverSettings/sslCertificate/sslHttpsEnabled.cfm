<!---
* @file  sslHttpsEnabled.cfm
* @description Https "Enable" checkbox (SslHttpsEnabled) — server.xml round-trip test, synthetic
*
* The real Https checkbox controls whether the commented-out SSL <Connector> block in server.xml
* is activated. This test does NOT do that: it toggles a synthetic marker attribute
* (data-ccstest-https-enabled) on that connector's own opening tag instead, staying entirely
* inside the existing HTML comment. Deliberately not real — see i.cfm for why: the real connector
* references a keystore ("adminlocalhost") that almost certainly isn't a real file, and Tomcat
* commonly refuses to start at all with an invalid cert config, not just fail that one connector.
* Runs with nodesScope="all": pushed to same-cluster/environment peers only, same as the other
* SSL Certificate fields.
--->
<h2>Https</h2>
<p>File: sslHttpsEnabled.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "SslHttpsEnabled";
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
