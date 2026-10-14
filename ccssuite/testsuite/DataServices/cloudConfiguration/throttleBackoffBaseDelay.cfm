<!---
* @file  throttleBackoffBaseDelay.cfm
* @description Add AWS Configuration (S3) - Request Config - Throttle Backoff Strategy Base Delay
* — mirrors Backoff Strategy's Base Delay exactly, cycling
* clientOverrideConfig.retryPolicy.throttlingBackoffStrategy.strategy.baseDelay ("100"/"200") for a
* fixed, dedicated test alias ("CCSTestCloudConfigThrottleBackoffBaseDelay"), paired with
* type="EqualJitter".
--->
<h2>Add AWS Configuration (S3) - Throttle Backoff Strategy Base Delay (create, verify sync, remove)</h2>
<p>File: throttleBackoffBaseDelay.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigThrottleBackoffBaseDelay";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-throttleBackoffBaseDelay">
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
