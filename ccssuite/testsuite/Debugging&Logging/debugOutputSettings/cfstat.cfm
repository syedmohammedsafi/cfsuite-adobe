<!---
* @file  cfstat.cfm
* @description Enable CFSTAT (cfstat) — multi-node CCS sync test
--->
<h2>Enable CFSTAT</h2>
<p>File: cfstat.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "cfstat";
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
