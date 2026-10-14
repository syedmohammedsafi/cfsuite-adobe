<!---
* @file  socketTimeout.cfm
* @description Add AWS Configuration (S3) - Client Config - Socket Timeout — cycles
* httpClientConfig.socketTimeout ("30s"/"60s") for a fixed, dedicated test alias
* ("CCSTestCloudConfigSocketTimeout" — kept separate from the other Cloud Configuration test
* fixtures). Mirrors connectionTimeout.cfm exactly. Last of the Client Config section
* (Connection Acquisition Timeout / Connection Max Idle Time / Connection Timeout / Connection
* Time to Live / Expect continue enabled / Max connections / Socket Timeout).
*
* Multi-node via organic CCS replication, same as the other Cloud Configuration tests — no
* requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - Socket Timeout (create, verify sync, remove)</h2>
<p>File: socketTimeout.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigSocketTimeout";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-socketTimeout">
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
