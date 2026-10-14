<!---
* @file  enableHttpStatusCodes.cfm
* @description Enable HTTP status codes (HTTPStatusCodes) — multi-node CCS sync test
--->
<cfset testsuiteRelPath = replace(replace(CGI.SCRIPT_NAME, "\", "/", "all"), "/cfsuite/ccssuite/testsuite/", "")>
<cfoutput>
<h2>Enable HTTP status codes</h2>
<p>File: #testsuiteRelPath#</p>
</cfoutput>
<br>
<cfset SETTING_NAME = "HTTPStatusCodes">
<cftry>
	<cfscript>
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init(); 
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Server_Settings-Settings-#SETTING_NAME#">
		<cfscript>
			writeOutput(stUtil.getQatestResultMessage(syncTestResult.passed));
		</cfscript>
		<cf_expectedresults>
			setting values as expected<br>
		</cf_expectedresults>
	</cf_qatest>
	<cf_qatestEnd stats=true>

	<cfcatch type="any">
		<cfscript>
			writeOutput("<h3>Test error</h3>");
			writeOutput("<p><strong>Type:</strong> " & encodeForHTML(cfcatch.type) & "</p>");
			writeOutput("<p><strong>Message:</strong> " & encodeForHTML(cfcatch.message) & "</p>");
			if(len(trim(cfcatch.detail)))
				writeOutput("<p><strong>Detail:</strong> " & encodeForHTML(cfcatch.detail) & "</p>");
			if(structKeyExists(cfcatch, "stackTrace") AND len(trim(cfcatch.stackTrace)))
				writeOutput("<pre>" & encodeForHTML(cfcatch.stackTrace) & "</pre>");
			writeDump(cfcatch);
		</cfscript>
	</cfcatch>

	<cffinally>
		<cfscript>
			if(structKeyExists(variables, "stUtil") AND isObject(stUtil) AND structKeyExists(variables, "testDvr"))
				stUtil.restoreMultiNodeSyncTest(testDvr, syncTestResult, SETTING_NAME);
		</cfscript>
	</cffinally>
</cftry>