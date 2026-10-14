<!---
* @file  ntlmDomain.cfm
* @description Add AWS Configuration (S3) - Client Config - Proxy - Ntlm Domain — cycles
* httpClientConfig.proxyConfiguration.ntlmdomain ("CCSTESTDOMAIN1"/"CCSTESTDOMAIN2", plain string
* unlike Non proxy hosts' array) for a fixed, dedicated test alias
* ("CCSTestCloudConfigNtlmDomain" — kept separate from the other Cloud Configuration test
* fixtures). Same double-nested struct as nonProxyHosts.cfm.
*
* Multi-node via organic CCS replication, same as the other Cloud Configuration tests — no
* requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - Ntlm Domain (create, verify sync, remove)</h2>
<p>File: ntlmDomain.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigNtlmDomain";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-ntlmDomain">
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
