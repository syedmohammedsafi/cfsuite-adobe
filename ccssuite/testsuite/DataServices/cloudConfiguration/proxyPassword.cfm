<!---
* @file  proxyPassword.cfm
* @description Add AWS Configuration (S3) - Client Config - Proxy - Password — cycles
* httpClientConfig.proxyConfiguration.password ("ccsProxyPass1"/"ccsProxyPass2") for a fixed,
* dedicated test alias ("CCSTestCloudConfigProxyPassword" — kept separate from the other Cloud
* Configuration test fixtures). Confirmed via direct testing that this is stored in PLAIN TEXT
* (no auto-encryption, unlike mail's password field), so a plain exact-match comparison is used.
* Mirrors proxyUsername.cfm.
*
* Multi-node via organic CCS replication, same as the other Cloud Configuration tests — no
* requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - Proxy Password (create, verify sync, remove)</h2>
<p>File: proxyPassword.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigProxyPassword";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-proxyPassword">
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
