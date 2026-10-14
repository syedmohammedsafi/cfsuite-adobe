<!---
* @file  retryConditions.cfm
* @description Add AWS Configuration (S3) - Request Config - Retry Conditions Condition 1 +
* Condition 2 rows (shown when the AND/OR dropdown has a value) — tracks presence of the pair
* together for a fixed, dedicated test alias ("CCSTestCloudConfigRetryConditions"): absent (no
* conditions array) vs. both rows present with type=StatusCode. Both rows only ever offer one real
* type in the admin UI ("Status Codes"), so there's no second value to cycle either row to on its
* own — confirmed via direct testing that the backend doesn't validate the type string at all, so a
* "second value" would be fabricated rather than something reachable from the admin UI.
--->
<h2>Add AWS Configuration (S3) - Retry Conditions - Condition 1 &amp; 2 (create, verify sync, remove)</h2>
<p>File: retryConditions.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigRetryConditions";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-retryConditions">
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
