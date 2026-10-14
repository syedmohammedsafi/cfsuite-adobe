<!---
* @file  retryCondition1StatusCodes.cfm
* @description Add AWS Configuration (S3) - Request Config - Retry Conditions - Condition 1's
* Status Codes text box (next to the fixed "Status Codes" dropdown) — cycles
* clientOverrideConfig.retryPolicy.retryCondition.conditions[1].statusCodes ("500,503"/"429,502")
* for a fixed, dedicated test alias ("CCSTestCloudConfigRetryCondition1StatusCodes"). Condition 2's
* row is filled with a fixed placeholder ("999") so the array always has the 2 entries the admin
* API requires once "AND"/"OR" is chosen.
--->
<h2>Add AWS Configuration (S3) - Retry Conditions - Condition 1 Status Codes (create, verify sync, remove)</h2>
<p>File: retryCondition1StatusCodes.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigRetryCondition1StatusCodes";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-retryCondition1StatusCodes">
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
