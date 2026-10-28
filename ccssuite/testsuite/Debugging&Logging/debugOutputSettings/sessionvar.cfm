<!---
* @file  sessionvar.cfm
* @description Session Variables (sessionvar) — multi-node CCS sync test
--->
<h2>Session Variables</h2>
<p>File: sessionvar.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "sessionvar";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Debugging_Logging-DebugOutputSettings-#SETTING_NAME#">
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
			try { stUtil.restoreMultiNodeSyncTest(testDvr, syncTestResult, SETTING_NAME); } catch (any e) {}
		</cfscript>
	</cffinally>
</cftry>
