<!---
* @file  pathStyleAccessEnabled.cfm
* @description Add AWS Configuration (S3) - S3 specific - Path Style Access Enabled — cycles
* s3Configuration.pathStyleAccessEnabled (true/false, stored as a real boolean) for a fixed,
* dedicated test alias ("CCSTestCloudConfigPathStyleAccess" — kept separate from the other Cloud
* Configuration test fixtures). Uses the same delete-then-recreate pattern as the other fields.
*
* CFIDE.adminapi.cloud.addServiceConfig() requires this nested under an s3Configuration struct —
* confirmed via direct testing: {alias, serviceName, s3Configuration:{pathStyleAccessEnabled}}
* round-trips exactly, same nesting requirement as clientOverrideConfig for the timeout fields.
*
* Multi-node via organic CCS replication, same as the other Cloud Configuration tests — no
* requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - Path Style Access Enabled (create, verify sync, remove)</h2>
<p>File: pathStyleAccessEnabled.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigPathStyleAccess";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-pathStyleAccessEnabled">
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
