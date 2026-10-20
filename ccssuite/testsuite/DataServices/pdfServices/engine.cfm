<!---
* @file  engine.cfm
* @description Add/Edit PDF Service - Engine (Option 2.0) — create with Option 2.0, verify sync across nodes, then remove, using fixed test alias "CCSTestPDFEngine".
--->
<h2>Add/Edit PDF Service - Engine (Option 2.0) (create, verify sync, remove)</h2>
<p>File: engine.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestPDFEngine";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		syncTestResult = {};

		// Test Engine Option 2.0 (PdfReactor)
		syncTestResult = stUtil.runMultiNodeSettingSyncTest(
			testDvr,
			SETTING_NAME,
			CGI.SCRIPT_NAME,
			"2.0",
			stUtil.initTestFrame(testDvr, SETTING_NAME, CGI.SCRIPT_NAME, true)
		);
	</cfscript>

	<cf_qatest id="test-Data_Services-PDF_Services-engine">
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
