<!---
* @file  rootPackageName.cfm
* @description Add/Edit GraphQL Service Configuration - Root Package Name — cycles the
* root_package_name field ("root"/"rootPackage2") for a fixed, dedicated test service
* ("CCSTestGraphqlRootPackage" — kept separate from "CCSTestGraphqlService"/
* "CCSTestGraphqlServiceName" used by the other two GraphQL tests so none interfere with each
* other). ROOT_PACKAGE_NAME is a required field with no blank state, so this uses the same
* delete-then-recreate pattern as Cloud Configuration's Service Name field test, rather than
* toggling presence/absence.
*
* Same in-memory-only Service Configuration behavior and API quirks as Service Name (see
* graphqlConfigUtil.cfc): setServiceConfiguration() throws "already exists" for a duplicate,
* deleteServiceConfiguration() throws "Servicename absent in Config." for a missing name — both
* confirmed via direct testing and handled defensively.
*
* Multi-node via active push, same as Configuration Alias / Service Name: serverSettingsApiUtil.
* requiresPeerInstancePropagation() already flags the whole "graphql" area.
--->
<h2>Add/Edit GraphQL Service Configuration - Root Package Name (create, verify sync, remove)</h2>
<p>File: rootPackageName.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestGraphqlRootPackage";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-GraphQL-rootPackageName">
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
