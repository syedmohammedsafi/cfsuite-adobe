<!---
* @file  solrAdminPort.cfm
* @description Solr Admin Port (solrport) — multi-node CCS sync test.
* NOTE: every CF instance on this box currently connects to the same shared Solr server via
* this exact host:port (localhost:8997, confirmed empirically) — the value is only wrong for
* the brief window between set and restore (guaranteed by cffinally), same risk profile as
* the existing mail/websocket port tests in this suite.
--->
<h2>Solr Admin Port</h2>
<p>File: solrAdminPort.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "solrport";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Solr_Server-#SETTING_NAME#">
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
