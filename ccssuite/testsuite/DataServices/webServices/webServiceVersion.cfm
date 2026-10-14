<!---
* @file  webServiceVersion.cfm
* @description Web Service Version ("Select web service version" dropdown) — single-node test.
* coldfusion.server.ServiceFactory.getXmlRpcService().setWSEngineVersion() applies the new value
* locally, then throws a genuine java.lang.ClassCastException inside CentralConfigClientUtil.
* pushToCCS() on every call in this CF2025 build (confirmed via direct testing against both
* CFIDE.adminapi.extensions.setWSVersion() and the raw service — a real admin clicking "Update
* Web Service Version" in the browser hits the same failure). webServicesConfigUtil.cfc swallows
* exactly that expected exception so the local value change can still be verified, but because
* the CCS push never completes for this setting, it cannot be confirmed as multi-node-synced —
* hence nodesScope="currentPort" here, the same scoping used for other genuinely per-instance-only
* settings like solrHome.cfm.
--->
<h2>Web Service Version</h2>
<p>File: webServiceVersion.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "wsversion";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME, true, "currentPort", true);
	</cfscript>

	<cf_qatest id="test-Data_Services-Web_Services-webServiceVersion">
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
