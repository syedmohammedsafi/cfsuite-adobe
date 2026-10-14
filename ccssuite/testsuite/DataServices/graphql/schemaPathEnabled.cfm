<!---
* @file  schemaPathEnabled.cfm
* @description Add/Edit GraphQL Service Configuration - Schema Path Enabled — for a fixed,
* dedicated test service ("CCSTestGraphqlSchemaPathEnabled"), cycles between "schema path mode"
* (schema_path populated, checkbox checked) and "service URL mode" (service_url populated,
* checkbox unchecked), then removes the service.
*
* IMPORTANT — read before assuming this tracks a literal boolean setting: "Schema Path Enabled"
* has NO backend field of its own. Confirmed via direct testing: dumping the complete, unfiltered
* key list of a schema-path-based service config returns only service_name/root_package_name/
* schema_path — no enabled/schemaPathEnabled key exists in any casing — and the real admin UI
* source (CFIDE/administrator/graphql/service.cfm) uses its gql_schemaPathEnabled variable purely
* client-side, to decide whether the submitted form contains SCHEMA_PATH or SERVICE_URL; that
* variable itself is never sent to or stored by the backend. What IS real and persisted is which
* of those two mutually-exclusive fields the service was created with — that presence/absence IS
* the checkbox's actual, observable effect, so that's what this test tracks: "true" recreates the
* service with schema_path set, "false" recreates it with service_url set instead. See
* schemaPath.cfm for the test that tracks the schema_path VALUE itself, and
* graphqlConfigUtil.cfc's getGraphqlSchemaPathEnabledSetting()/setGraphqlSchemaPathEnabledSetting()
* for the implementation.
*
* Same in-memory-only Service Configuration behavior and non-idempotent API quirks as the other
* GraphQL Service Configuration tests. Multi-node via active push: serverSettingsApiUtil.
* requiresPeerInstancePropagation() already flags the whole "graphql" area.
--->
<h2>Add/Edit GraphQL Service Configuration - Schema Path Enabled (create, verify sync, remove)</h2>
<p>File: schemaPathEnabled.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestGraphqlSchemaPathEnabled";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-GraphQL-schemaPathEnabled">
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
