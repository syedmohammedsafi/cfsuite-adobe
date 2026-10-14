<!---
* @file  apiCallTimeout.cfm
* @description Add AWS Configuration (S3) - Request Config - API Call Timeout — cycles
* clientOverrideConfig.apiCallTimeout ("30s"/"60s") for a fixed, dedicated test alias
* ("CCSTestCloudConfigApiCallTimeout" — kept separate from the other Cloud Configuration test
* fixtures, including API Call Attempt Timeout's own). Mirrors apiCallAttemptTimeout.cfm exactly;
* see that file / cloudConfigConfigUtil.cfc for the confirmed nested-struct API behavior.
*
* Multi-node via organic CCS replication, same as Config Alias / Service Name / API Call Attempt
* Timeout — no requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - API Call Timeout (create, verify sync, remove)</h2>
<p>File: apiCallTimeout.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigApiCallTimeout";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-apiCallTimeout">
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
