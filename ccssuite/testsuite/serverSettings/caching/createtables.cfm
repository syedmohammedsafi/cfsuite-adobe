<!---
* @file  createtables.cfm
* @description JCS table override - non-persisted action, not a CCS sync setting
--->
<h2>JCS Override Table If Already Exists</h2>
<p>File: createtables.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "createtables";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cfif NOT syncTestResult.passed AND structKeyExists(syncTestResult, "failureMessage")>
		<cfoutput>
			<p>#encodeForHTML(syncTestResult.failureMessage)#</p>
		</cfoutput>
	</cfif>

	<cf_qatest id="test-Server_Settings-Caching-#SETTING_NAME#">
		<cfscript>
			writeOutput(stUtil.getQatestResultMessage(syncTestResult.passed, SETTING_NAME));
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