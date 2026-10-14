<!---
* @file  throttleBackoffStrategyType.cfm
* @description Add AWS Configuration (S3) - Request Config - Throttle Backoff Strategy dropdown —
* mirrors Backoff Strategy Type exactly, cycling
* clientOverrideConfig.retryPolicy.throttlingBackoffStrategy.type ("EqualJitter"/"FullJitter") for
* a fixed, dedicated test alias ("CCSTestCloudConfigThrottleBackoffStrategyType").
--->
<h2>Add AWS Configuration (S3) - Throttle Backoff Strategy Type (create, verify sync, remove)</h2>
<p>File: throttleBackoffStrategyType.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigThrottleBackoffStrategyType";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-throttleBackoffStrategyType">
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
