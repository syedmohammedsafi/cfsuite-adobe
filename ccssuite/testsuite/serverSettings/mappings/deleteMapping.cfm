<h2>Mappings - Delete Mapping</h2>
<p>File: deleteMapping.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "deleteMapping";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		mappingUtil = new cfsuite.ccssuite.utils.mappingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = mappingUtil.runSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>
	<cf_qatest id="test-Server_Settings-Mappings-#SETTING_NAME#">
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
			<p>An error occurred in the test: #encodeForHTML(cfcatch.message & " " & cfcatch.detail)#</p>
		</cfoutput>
	</cfcatch>
	<cffinally>
		<cfscript>
			mappingUtil.restoreSyncTest(testDvr, syncTestResult, SETTING_NAME);
		</cfscript>
	</cffinally>
</cftry>