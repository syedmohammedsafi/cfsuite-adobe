<!---
* @file  jcsdsnname.cfm
* @description JCS JDBC auxiliary cache datasource - multi-node CCS sync test
--->
<h2>JCS JDBC Auxiliary Cache Datasource</h2>
<p>File: jcsdsnname.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "jcsdsnname";
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
			writeOutput(stUtil.getQatestResultMessage(syncTestResult.passed, SETTING_NAME,
				structKeyExists(syncTestResult, "tested") AND NOT syncTestResult.tested ? "Not tested." : ""));
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