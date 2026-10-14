<!---
* @file  apiCallAttemptTimeout.cfm
* @description Add AWS Configuration (S3) - Request Config - API Call Attempt Timeout — cycles
* clientOverrideConfig.apiCallAttemptTimeout ("10s"/"20s") for a fixed, dedicated test alias
* ("CCSTestCloudConfigApiCallAttemptTimeout" — kept separate from the other Cloud Configuration
* test fixtures). Uses the same delete-then-recreate pattern as Service Name.
*
* CFIDE.adminapi.cloud.addServiceConfig() only exposes this via a NESTED clientOverrideConfig
* struct — confirmed via direct testing: top-level apiCallAttemptTimeout/requestConfig/
* requestConfiguration keys are all rejected as unknown fields; {alias, serviceName,
* clientOverrideConfig:{apiCallAttemptTimeout}} round-trips exactly. modifyServiceConfig() was
* also confirmed to reject the same top-level keys, so add (delete-then-recreate) is used instead.
*
* Multi-node via organic CCS replication, same as Config Alias / Service Name (neo-cloud-config.xml
* is confirmed CCS-tracked) — no requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - API Call Attempt Timeout (create, verify sync, remove)</h2>
<p>File: apiCallAttemptTimeout.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigApiCallAttemptTimeout";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-apiCallAttemptTimeout">
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
