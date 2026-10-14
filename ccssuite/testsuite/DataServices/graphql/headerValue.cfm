<!---
* @file  headerValue.cfm
* @description Add/Edit GraphQL Service Configuration - HTTP Headers (Header Value) — cycles the
* value ("ccsTestHeaderValue1"/"ccsTestHeaderValue2") mapped to a fixed test header key
* ("CCSTestHeaderKey") inside the HEADERS struct of a fixed, dedicated test service
* ("CCSTestGraphqlHeaderValue" — kept separate from "CCSTestGraphqlHeaderKey" and the other
* GraphQL test fixtures). Uses the same delete-then-recreate pattern as Root Package Name /
* Service URL, rather than toggling presence/absence, since the tracked value here is the header's
* VALUE, not its key.
*
* See headerKey.cfm for the confirmed HEADERS behavior: real, storable struct parameter on
* setServiceConfiguration() (round-trips exactly as given), unlike setClientConfiguration() where
* it's silently accepted but never persisted.
*
* Same in-memory-only Service Configuration behavior and non-idempotent API quirks as the other
* GraphQL Service Configuration tests. Multi-node via active push: serverSettingsApiUtil.
* requiresPeerInstancePropagation() already flags the whole "graphql" area.
--->
<h2>Add/Edit GraphQL Service Configuration - HTTP Headers / Header Value (create, verify sync, remove)</h2>
<p>File: headerValue.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestGraphqlHeaderValue";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-GraphQL-headerValue">
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
