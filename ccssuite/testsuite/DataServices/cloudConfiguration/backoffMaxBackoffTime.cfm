<!---
* @file  backoffMaxBackoffTime.cfm
* @description Add AWS Configuration (S3) - Request Config - Max Backoff Time — mirrors Base Delay
* exactly, tracking clientOverrideConfig.retryPolicy.backoffStrategy.strategy.maxBackoffTime
* ("5000"/"10000") instead, paired with the same type="EqualJitter". Dedicated test alias
* "CCSTestCloudConfigBackoffMaxBackoffTime" keeps this separate from the other Cloud Configuration
* test fixtures.
--->
<h2>Add AWS Configuration (S3) - Backoff Strategy Max Backoff Time (create, verify sync, remove)</h2>
<p>File: backoffMaxBackoffTime.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigBackoffMaxBackoffTime";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-backoffMaxBackoffTime">
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
