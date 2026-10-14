<!---
* @file  connectionAcquisitionTimeout.cfm
* @description Add AWS Configuration (S3) - Client Config - Connection Acquisition Timeout —
* cycles httpClientConfig.connectionAcquisitionTimeout ("10s"/"20s") for a fixed, dedicated test
* alias ("CCSTestCloudConfigConnAcqTimeout" — kept separate from the other Cloud Configuration
* test fixtures). Confirmed via direct testing that addServiceConfig() requires this nested under
* an httpClientConfig struct (Client Config section, distinct from clientOverrideConfig/
* s3Configuration used by the Request Config / S3 specific sections).
*
* Multi-node via organic CCS replication, same as the other Cloud Configuration tests — no
* requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - Connection Acquisition Timeout (create, verify sync, remove)</h2>
<p>File: connectionAcquisitionTimeout.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigConnAcqTimeout";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-connectionAcquisitionTimeout">
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
