<!---
* @file  ntlmWorkstation.cfm
* @description Add AWS Configuration (S3) - Client Config - Proxy - Ntlm Workstation — cycles
* httpClientConfig.proxyConfiguration.ntlmWorkstation ("CCSTESTWS1"/"CCSTESTWS2") for a fixed,
* dedicated test alias ("CCSTestCloudConfigNtlmWorkstation" — kept separate from the other Cloud
* Configuration test fixtures). Mirrors ntlmDomain.cfm exactly.
*
* Multi-node via organic CCS replication, same as the other Cloud Configuration tests — no
* requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - Ntlm Workstation (create, verify sync, remove)</h2>
<p>File: ntlmWorkstation.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigNtlmWorkstation";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-ntlmWorkstation">
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
