<!---
* @file  backoffStrategyType.cfm
* @description Add AWS Configuration (S3) - Request Config - Backoff Strategy dropdown — cycles
* clientOverrideConfig.retryPolicy.backoffStrategy.type ("EqualJitter"/"FullJitter") for a fixed,
* dedicated test alias ("CCSTestCloudConfigBackoffStrategyType"). Confirmed via direct testing that
* backoffStrategy.type can be set on its own, without a strategy struct.
--->
<h2>Add AWS Configuration (S3) - Backoff Strategy Type (create, verify sync, remove)</h2>
<p>File: backoffStrategyType.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigBackoffStrategyType";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-backoffStrategyType">
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
