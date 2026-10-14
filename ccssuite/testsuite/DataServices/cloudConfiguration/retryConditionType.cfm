<!---
* @file  retryConditionType.cfm
* @description Add AWS Configuration (S3) - Request Config - Retry Conditions (AND/OR dropdown) —
* cycles clientOverrideConfig.retryPolicy.retryCondition.type ("AND"/"OR") for a fixed, dedicated
* test alias ("CCSTestCloudConfigRetryConditionType" — kept separate from the other Cloud
* Configuration test fixtures). Confirmed via direct testing that retryCondition.type can be set on
* its own, without a conditions array.
--->
<h2>Add AWS Configuration (S3) - Retry Conditions Type (create, verify sync, remove)</h2>
<p>File: retryConditionType.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigRetryConditionType";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-retryConditionType">
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
