<!---
* @file  gcpPubsub_subSystemExecutorProviderThreadNamePrefix.cfm
* @description Add Cloud Configuration (GCP PubSub - System Executor Provider Thread Name Prefix (Subscriber)) - cycles setting for dedicated test alias (CCSTestCloudConfigPubsubSubSystemExecutorProviderThreadNamePrefix).
--->
<h2>Add Cloud Configuration - GCP PubSub - System Executor Provider Thread Name Prefix (Subscriber) (create, verify sync, remove)</h2>
<p>File: gcpPubsub_subSystemExecutorProviderThreadNamePrefix.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigPubsubSubSystemExecutorProviderThreadNamePrefix";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-gcpPubsub_subSystemExecutorProviderThreadNamePrefix">
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
