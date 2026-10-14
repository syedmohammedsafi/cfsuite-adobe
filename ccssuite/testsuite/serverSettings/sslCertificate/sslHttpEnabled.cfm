<!---
* @file  sslHttpEnabled.cfm
* @description Http "Enable" checkbox (SslHttpEnabled) — server.xml round-trip test, synthetic
*
* The real Http checkbox controls the live <Connector protocol="HTTP/1.1" port="8500" .../> —
* the one THIS admin session runs on. This test never touches that connector. Instead it toggles
* a synthetic marker attribute (data-ccstest-http-enabled) on a completely different, always-
* commented "shared thread pool" HTTP <Connector> template a few lines above it in server.xml —
* a block Tomcat never uses regardless of anything in this file. Deliberately not real — see
* i.cfm for why: disabling the live connector for real risks locking out admin access on the next
* restart. Runs with nodesScope="all": pushed to same-cluster/environment peers only, same as the
* other SSL Certificate fields.
--->
<h2>Http</h2>
<p>File: sslHttpEnabled.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "SslHttpEnabled";
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
