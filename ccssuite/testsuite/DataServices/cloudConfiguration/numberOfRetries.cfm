<!---
* @file  numberOfRetries.cfm
* @description Add AWS Configuration (S3) - Request Config - Number of Retries — cycles
* clientOverrideConfig.retryPolicy.numRetries ("3"/"5") for a fixed, dedicated test alias
* ("CCSTestCloudConfigNumRetries" — kept separate from the other Cloud Configuration test
* fixtures). Confirmed via direct testing that addServiceConfig() requires numRetries nested under
* clientOverrideConfig.retryPolicy (same nested-struct requirement as API Call Attempt/Call
* Timeout, one level deeper).
--->
<h2>Add AWS Configuration (S3) - Number of Retries (create, verify sync, remove)</h2>
<p>File: numberOfRetries.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigNumRetries";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-numberOfRetries">
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
