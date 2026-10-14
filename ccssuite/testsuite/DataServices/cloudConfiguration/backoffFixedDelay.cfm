<!---
* @file  backoffFixedDelay.cfm
* @description Add AWS Configuration (S3) - Request Config - Fixed Delay (shown for the Fixed
* Delay backoff strategy) — cycles
* clientOverrideConfig.retryPolicy.backoffStrategy.strategy.fixedDelay ("200"/"400") for a fixed,
* dedicated test alias ("CCSTestCloudConfigBackoffFixedDelay"). Paired with type="FixedDelay" so
* the config matches what the admin UI would actually send when this field is visible.
--->
<h2>Add AWS Configuration (S3) - Backoff Strategy Fixed Delay (create, verify sync, remove)</h2>
<p>File: backoffFixedDelay.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigBackoffFixedDelay";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-backoffFixedDelay">
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
