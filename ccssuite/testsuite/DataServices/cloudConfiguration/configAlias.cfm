<!---
* @file  configAlias.cfm
* @description Add/Edit Cloud Service Configuration - Config Alias — create, verify sync across
* nodes, then remove, using a fixed test alias "CCSTestCloudConfigAlias". The tracked value here
* is the alias itself (registered/not registered), not the Service Name field — addServiceConfig()
* still needs a Service Name to register with, so a fixed default ("S3") is used internally for
* that, but it isn't what this test verifies.
*
* CFIDE.adminapi.cloud.addServiceConfig()/getServiceConfig()/deleteServiceConfig() reliably
* create/read/delete entries in neo-cloud-config.xml, keyed by alias (confirmed via direct
* testing). addServiceConfig() only accepts two fields — "alias" and "serviceName" — confirmed via
* direct testing; the admin UI's "Cloud Vendor" dropdown is purely a client-side filter for which
* Service Name options are shown and is NOT itself a stored/accepted field (vendorName/vendor/
* cloudVendor are all rejected as unknown fields) — see cloudConfigConfigUtil.cfc.
*
* Multi-node via ORGANIC CCS replication, unlike Cloud Credentials: confirmed via direct testing
* that adding a config alias on the prime node creates a real CCS version and the new alias
* appears in a peer node's own neo-cloud-config.xml on disk shortly after, with no active push
* needed — the same passive-replication behavior mail's basic scalar fields (server, port,
* username) have. So this test uses the default "all" nodesScope with no
* requiresPeerInstancePropagation() entry, unlike every Cloud Credentials field test.
--->
<h2>Add/Edit Cloud Service Configuration - Config Alias (create, verify sync, remove)</h2>
<p>File: configAlias.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigAlias";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-configAlias">
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
