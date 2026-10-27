<!---
* @file  gcpPubsub_subExecutorProviderThreadCount.cfm
* @description Add Cloud Configuration (GCP PubSub - Executor Provider Thread Count (Subscriber)) - cycles setting for dedicated test alias (CCSTestCloudConfigPubsubSubExecutorProviderThreadCount).
--->
<h2>Add Cloud Configuration - GCP PubSub - Executor Provider Thread Count (Subscriber) (create, verify sync, remove)</h2>
<p>File: gcpPubsub_subExecutorProviderThreadCount.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigPubsubSubExecutorProviderThreadCount";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-gcpPubsub_subExecutorProviderThreadCount">
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
