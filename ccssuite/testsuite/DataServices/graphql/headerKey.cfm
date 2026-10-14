<!---
* @file  headerKey.cfm
* @description Add/Edit GraphQL Service Configuration - HTTP Headers (Header Key) — create,
* verify sync across nodes, then remove, using a fixed test header key "CCSTestHeaderKey" (mapped
* to a fixed value "ccsTestHeaderValue") inside the HEADERS struct of a fixed, dedicated test
* service ("CCSTestGraphqlHeaderKey" — kept separate from the other GraphQL test fixtures). The
* tracked value here is the header key's presence/absence, not its value.
*
* CFIDE.adminapi.graphql.setServiceConfiguration() accepts HEADERS as a real struct parameter that
* round-trips exactly as given (confirmed via direct testing, e.g. {Authorization: "Bearer ..."}
* persists and reads back unchanged). setClientConfiguration() silently accepts a HEADERS argument
* too but never persists it (confirmed via direct testing — the returned client config never
* includes a headers key when set this way) — so this test targets Service Configuration's HEADERS
* specifically, which is well-behaved, matching the "HTTP Headers" section's actual position on
* the admin page (part of Add GraphQL Service Configuration, after Service URL).
*
* Same in-memory-only Service Configuration behavior and non-idempotent API quirks as the other
* GraphQL Service Configuration tests. Multi-node via active push: serverSettingsApiUtil.
* requiresPeerInstancePropagation() already flags the whole "graphql" area.
--->
<h2>Add/Edit GraphQL Service Configuration - HTTP Headers / Header Key (create, verify sync, remove)</h2>
<p>File: headerKey.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestGraphqlHeaderKey";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-GraphQL-headerKey">
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
