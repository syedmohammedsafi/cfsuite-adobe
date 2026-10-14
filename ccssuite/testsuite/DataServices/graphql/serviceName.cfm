<!---
* @file  serviceName.cfm
* @description Add/Edit GraphQL Service Configuration - Service Name — create, verify sync across
* nodes, then remove, using a fixed test name "CCSTestGraphqlServiceName" (kept separate from
* "CCSTestGraphqlService", the fixture the Configuration Alias test lazily creates, so the two
* never interfere with each other).
*
* CFIDE.adminapi.graphql.setServiceConfiguration()/getServiceConfiguration()/
* deleteServiceConfiguration() manage Service Configurations. Unlike Client Configurations, these
* are IN-MEMORY ONLY — confirmed via direct testing that a registered service is retrievable
* across many separate requests, yet never appears anywhere in neo-graphql-config.xml or its CCS
* version history. setServiceConfiguration() does not attempt to reach SERVICE_URL (confirmed via
* direct testing), so a fake URL is safe to use; it also throws "already exists" for a duplicate
* name and deleteServiceConfiguration() throws "Servicename absent in Config." for a missing one —
* both confirmed via direct testing and handled defensively in graphqlConfigUtil.cfc.
*
* Multi-node via active push, same as Configuration Alias: serverSettingsApiUtil.
* requiresPeerInstancePropagation() already flags the whole "graphql" area, so testDriver.cfc
* actively re-applies the same setServiceConfiguration()/deleteServiceConfiguration() call on each
* peer node directly — which, since Service Configurations are in-memory per node anyway, is the
* only way this could ever reach a peer regardless of CCS behavior.
--->
<h2>Add/Edit GraphQL Service Configuration - Service Name (create, verify sync, remove)</h2>
<p>File: serviceName.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestGraphqlServiceName";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-GraphQL-serviceName">
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
