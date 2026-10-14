<!---
* @file  maxConnections.cfm
* @description Add AWS Configuration (S3) - Client Config - Max connections — cycles
* httpClientConfig.maxConnections ("50"/"100", numeric not a duration string) for a fixed,
* dedicated test alias ("CCSTestCloudConfigMaxConnections" — kept separate from the other Cloud
* Configuration test fixtures). Same delete-then-recreate pattern as the other httpClientConfig
* fields.
*
* Multi-node via organic CCS replication, same as the other Cloud Configuration tests — no
* requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - Max connections (create, verify sync, remove)</h2>
<p>File: maxConnections.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigMaxConnections";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-maxConnections">
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
