<!---
* @file  solrHome.cfm
* @description Solr Home (solrhome) — per-instance path setting, tested on the local node only.
* Toggles between the real solrhome path and a dedicated alt test directory (created if
* missing), same pattern as the Charting cache path test. Confirmed via direct polling
* (18s across 6 checks) that real CCS never replicates this field to peer nodes — every
* other Solr Server scalar field (solrhost, username, ports, etc.) genuinely does propagate,
* but solrhome is a filesystem path local to each instance, so nodesScope is restricted to
* "currentPort" here rather than reporting a false failure on peers that legitimately never change.
--->
<h2>Solr Home</h2>
<p>File: solrHome.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "solrhome";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME, true, "currentPort", true);
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
