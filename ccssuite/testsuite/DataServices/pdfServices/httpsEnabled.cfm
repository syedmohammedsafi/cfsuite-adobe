<!---
* @file  httpsEnabled.cfm
* @description Add/Edit PDF Service - HTTPS Enabled — create, verify sync across nodes, then remove, using fixed test alias "CCSTestPDFHttpsEnabled".
--->
<h2>Add/Edit PDF Service - HTTPS Enabled (create, verify sync, remove)</h2>
<p>File: httpsEnabled.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestPDFHttpsEnabled";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-PDF_Services-httpsEnabled">
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
