<!---
* @file  nonProxyHosts.cfm
* @description Add AWS Configuration (S3) - Client Config - Proxy - Non proxy hosts — cycles
* httpClientConfig.proxyConfiguration.nonProxyHosts ("localhost"/"127.0.0.1") for a fixed,
* dedicated test alias ("CCSTestCloudConfigNonProxyHosts" — kept separate from the other Cloud
* Configuration test fixtures).
*
* Double-nested struct — confirmed via direct testing that Proxy Configuration nests under
* Client Config (httpClientConfig.proxyConfiguration), one level deeper than the other
* httpClientConfig fields. nonProxyHosts is an ARRAY, not a string — confirmed via direct testing
* that a plain string throws "Object of type class java.lang.String cannot be used as an array";
* a single-element array round-trips correctly. See cloudConfigConfigUtil.cfc.
*
* Multi-node via organic CCS replication, same as the other Cloud Configuration tests — no
* requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - Non proxy hosts (create, verify sync, remove)</h2>
<p>File: nonProxyHosts.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigNonProxyHosts";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-nonProxyHosts">
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
