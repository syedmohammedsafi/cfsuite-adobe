<!---
* @file  proxyEndpoint.cfm
* @description Add AWS Configuration (S3) - Client Config - Proxy - Endpoint — cycles
* httpClientConfig.proxyConfiguration.endpoint ("http://proxy1.ccssuite-test.local:8080"/
* "http://proxy2.ccssuite-test.local:8080") for a fixed, dedicated test alias
* ("CCSTestCloudConfigProxyEndpoint" — kept separate from the other Cloud Configuration test
* fixtures). Confirmed via direct testing that a bare hostname is rejected ("Proxy endpoint path
* is not supported") — a full URI (scheme + host + port) is required, unlike Ntlm Domain/
* Workstation/Proxy Username which accept plain strings.
*
* Multi-node via ACTIVE PUSH, not organic CCS replication — confirmed via direct testing that this
* field never syncs to a peer even after 3+ minutes of polling, same non-syncing pattern as Proxy
* Password (see serverSettingsApiUtil.requiresPeerInstancePropagation()), unlike every other Cloud
* Configuration field.
--->
<h2>Add AWS Configuration (S3) - Proxy Endpoint (create, verify sync, remove)</h2>
<p>File: proxyEndpoint.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigProxyEndpoint";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-proxyEndpoint">
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
