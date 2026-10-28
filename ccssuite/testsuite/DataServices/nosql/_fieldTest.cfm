<cfscript>
SETTING_NAME = structKeyExists(request, "nosqlSetting") ? request.nosqlSetting : "";
apiUtil = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init();
apiUtil.requireSetting(SETTING_NAME);
testDvr = new cfsuite.ccssuite.testDriver();
testUtil = new cfsuite.ccssuite.utils.nosqlDatasourceTestUtil().init();
stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
syncTestResult = {};
passed = false;
diagnostic = "MongoDB configuration did not match the strict CCS synchronization expectation.";
</cfscript>
<cfoutput><h2>NoSQL Data Sources - #encodeForHTML(SETTING_NAME)#</h2></cfoutput>
<cflock name="ccssuite-nosql-sync-test" type="exclusive" timeout="60">
	<cftry>
		<cfscript>
			syncTestResult = testUtil.runSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
			passed = structKeyExists(syncTestResult, "passed") AND syncTestResult.passed;
		</cfscript>
		<cf_qatest id="test-Data_Services-NoSQL-#SETTING_NAME#">
			<cfscript>
				writeOutput(stUtil.getQatestResultMessage(passed, SETTING_NAME, diagnostic));
			</cfscript>
			<cf_expectedresults>
				setting values as expected<br>
			</cf_expectedresults>
		</cf_qatest>
		<cf_qatestEnd stats=true>
		<cfcatch type="any">
			<cfscript>
				diagnostic = SETTING_NAME EQ "mongo_maxStaleness"
					? "UNSUPPORTED: installed setMongoDataSource has no maxStalenessSeconds parameter; no configuration changed."
					: "NoSQL API or synchronization failed; " & cfcatch.message & " " & cfcatch.detail;
			</cfscript>
			<cf_qatest id="test-Data_Services-NoSQL-#SETTING_NAME#">
				<cfoutput>setting values NOT as expected. #encodeForHTML(diagnostic)#<br></cfoutput>
				<cf_expectedresults>
					setting values as expected<br>
				</cf_expectedresults>
			</cf_qatest>
			<cf_qatestEnd stats=true>
			<cfoutput>
				<p>An error occurred in the test: #encodeForHTML(cfcatch.message & " " & cfcatch.detail)#</p>
			</cfoutput>
		</cfcatch>
		<cffinally>
			<cftry>
				<cfset testUtil.restoreSyncTest(testDvr, syncTestResult, SETTING_NAME)>
				<cfcatch type="any">
					<cfoutput><p>Restore warning: #encodeForHTML(cfcatch.message)#</p></cfoutput>
				</cfcatch>
			</cftry>
		</cffinally>
	</cftry>
</cflock>