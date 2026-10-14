<!---
* @file  schemaPath.cfm
* @description Add/Edit GraphQL Service Configuration - Schema Path — cycles the schema_path
* field ("schema/ccsTestPath1.json"/"schema/ccsTestPath2.json") for a fixed, dedicated test
* service ("CCSTestGraphqlSchemaPath" — kept separate from "CCSTestGraphqlService"/
* "CCSTestGraphqlServiceName"/"CCSTestGraphqlRootPackage" used by the other GraphQL tests). Uses
* the same delete-then-recreate pattern as Root Package Name / Service Name.
*
* This is the real, storable setting behind the admin UI's "Schema Path Enabled" checkbox —
* confirmed via direct testing that checkbox has NO backend representation at all (dumping the
* complete key list of a schema-path-based service config returns only service_name/
* root_package_name/schema_path; no enabled flag exists in any casing) and via the real admin UI
* source (service.cfm's gql_schemaPathEnabled variable is used purely client-side, to decide
* whether the form sends SCHEMA_PATH or SERVICE_URL — never itself transmitted to the backend).
* SCHEMA_PATH and SERVICE_URL are mutually exclusive on the wire; this test creates the service
* with SCHEMA_PATH only (no SERVICE_URL), confirmed via direct testing to persist and read back
* correctly on its own.
*
* Same in-memory-only Service Configuration behavior and non-idempotent API quirks as the other
* GraphQL Service Configuration tests (see graphqlConfigUtil.cfc). Multi-node via active push:
* serverSettingsApiUtil.requiresPeerInstancePropagation() already flags the whole "graphql" area.
--->
<h2>Add/Edit GraphQL Service Configuration - Schema Path (create, verify sync, remove)</h2>
<p>File: schemaPath.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestGraphqlSchemaPath";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-GraphQL-schemaPath">
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
