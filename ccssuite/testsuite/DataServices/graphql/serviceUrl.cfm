<!---
* @file  serviceUrl.cfm
* @description Add/Edit GraphQL Service Configuration - Service URL — cycles the service_url
* field ("http://localhost/ccssuite-test/schema1.graphql"/"...schema2.graphql") for a fixed,
* dedicated test service ("CCSTestGraphqlServiceUrl" — kept separate from
* "CCSTestGraphqlService"/"CCSTestGraphqlServiceName"/"CCSTestGraphqlRootPackage"/
* "CCSTestGraphqlSchemaPath"/"CCSTestGraphqlSchemaPathEnabled" used by the other GraphQL tests).
* Uses the same delete-then-recreate pattern as Schema Path / Root Package Name.
*
* Mirrors Schema Path's test exactly, for the other side of that mutually exclusive pair —
* confirmed via direct testing that setServiceConfiguration() does not attempt to reach
* SERVICE_URL, so a fake, unreachable URL is safe here (no hang/reachability risk, unlike Web
* Services' setWebService()).
*
* Same in-memory-only Service Configuration behavior and non-idempotent API quirks as the other
* GraphQL Service Configuration tests. Multi-node via active push: serverSettingsApiUtil.
* requiresPeerInstancePropagation() already flags the whole "graphql" area.
--->
<h2>Add/Edit GraphQL Service Configuration - Service URL (create, verify sync, remove)</h2>
<p>File: serviceUrl.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestGraphqlServiceUrl";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-GraphQL-serviceUrl">
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
