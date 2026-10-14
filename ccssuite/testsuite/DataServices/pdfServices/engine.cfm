<!---
* @file  engine.cfm
* @description Add/Edit PDF Service - Engine (Option 1.0, 2.0) — create with Option 1.0, update to Option 2.0, verify sync across nodes, then remove, using fixed test alias "CCSTestPDFEngine".
--->
<h2>Add/Edit PDF Service - Engine (Option 1.0, 2.0) (create, verify sync, remove)</h2>
<p>File: engine.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestPDFEngine";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		syncTestResult1 = {};
		syncTestResult2 = {};

		// Pass 1: Test Engine Option 1.0 (WebKit)
		writeOutput("<h3>Engine: Option 1.0</h3>");
		syncTestResult1 = stUtil.runMultiNodeSettingSyncTest(
			testDvr,
			SETTING_NAME,
			CGI.SCRIPT_NAME,
			"1.0",
			stUtil.initTestFrame(testDvr, SETTING_NAME, CGI.SCRIPT_NAME, true)
		);

		// Pass 2: Test Engine Option 2.0 (PdfReactor)
		writeOutput("<br/><br/><h3>Engine: Option 2.0</h3>");
		syncTestResult2 = stUtil.runMultiNodeSettingSyncTest(
			testDvr,
			SETTING_NAME,
			CGI.SCRIPT_NAME,
			"2.0",
			stUtil.initTestFrame(testDvr, SETTING_NAME, CGI.SCRIPT_NAME, true)
		);
	</cfscript>

	<cf_qatest id="test-Data_Services-PDF_Services-engine">
		<cfscript>
			writeOutput(stUtil.getQatestResultMessage(syncTestResult1.passed AND syncTestResult2.passed));
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
			stUtil.restoreMultiNodeSyncTest(testDvr, syncTestResult1, SETTING_NAME);
		</cfscript>
	</cffinally>
</cftry>
