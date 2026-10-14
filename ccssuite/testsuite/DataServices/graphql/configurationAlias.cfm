<!---
* @file  configurationAlias.cfm
* @description Add/Edit GraphQL Client Configuration - Configuration Alias — create, verify sync
* across nodes, then remove, using a fixed test alias "CCSTestGraphqlClientAlias". The tracked
* value here is the alias itself (registered/not registered), not the Service Name field —
* setClientConfiguration() still needs a valid, already-registered Service Name to register
* against, so a dedicated fixed test service ("CCSTestGraphqlService") is lazily created on
* whichever node runs the set to satisfy that requirement — see graphqlConfigUtil.cfc.
*
* CFIDE.adminapi.graphql.setClientConfiguration()/getClientConfiguration()/
* deleteClientConfiguration() reliably create/read/delete entries in neo-graphql-config.xml, keyed
* by client name (confirmed via direct testing). setClientConfiguration() takes named arguments
* (CLIENT_NAME/SERVICE_NAME), not a struct — confirmed via direct testing.
*
* Multi-node via active push, not organic CCS replication: confirmed via direct testing that a
* newly-added client configuration creates a real CCS version on the prime node but never appears
* in a peer node's own neo-graphql-config.xml even after ~80 seconds of direct polling, with
* nothing logged on the peer either. serverSettingsApiUtil.requiresPeerInstancePropagation() flags
* the "graphql" area so testDriver.cfc actively re-applies the same
* setClientConfiguration()/deleteClientConfiguration() call on each peer node directly, instead of
* passively waiting on CCS.
--->
<h2>Add/Edit GraphQL Client Configuration - Configuration Alias (create, verify sync, remove)</h2>
<p>File: configurationAlias.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestGraphqlClientAlias";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-GraphQL-configurationAlias">
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
