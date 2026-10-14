<!---
* @file  retryCondition2StatusCodes.cfm
* @description Add AWS Configuration (S3) - Request Config - Retry Conditions - Condition 2's
* Status Codes text box — mirrors Condition 1's Status Codes exactly, tracking
* clientOverrideConfig.retryPolicy.retryCondition.conditions[2].statusCodes instead, with
* Condition 1's row filled with a fixed placeholder ("999"). Dedicated test alias
* "CCSTestCloudConfigRetryCondition2StatusCodes" keeps this separate from the other Cloud
* Configuration test fixtures.
--->
<h2>Add AWS Configuration (S3) - Retry Conditions - Condition 2 Status Codes (create, verify sync, remove)</h2>
<p>File: retryCondition2StatusCodes.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigRetryCondition2StatusCodes";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-retryCondition2StatusCodes">
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
