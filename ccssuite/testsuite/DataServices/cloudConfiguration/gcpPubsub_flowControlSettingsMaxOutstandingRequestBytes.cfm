<!---
* @file  gcpPubsub_flowControlSettingsMaxOutstandingRequestBytes.cfm
* @description Add Cloud Configuration (GCP PubSub - Max Outstanding Request Bytes (Publisher)) - cycles setting for dedicated test alias (CCSTestCloudConfigPubsubFlowControlSettingsMaxOutstandingRequestBytes).
--->
<h2>Add Cloud Configuration - GCP PubSub - Max Outstanding Request Bytes (Publisher) (create, verify sync, remove)</h2>
<p>File: gcpPubsub_flowControlSettingsMaxOutstandingRequestBytes.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigPubsubFlowControlSettingsMaxOutstandingRequestBytes";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-gcpPubsub_flowControlSettingsMaxOutstandingRequestBytes">
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
