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
<cflock name="ccssuite-nosql-reserved-fixtures" type="exclusive" timeout="30">
        <cftry>
                <cfscript>
                        syncTestResult = testUtil.runSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
                        passed = syncTestResult.passed;
                </cfscript>
                <cfcatch type="any">
                        <cfscript>
                                diagnostic = SETTING_NAME EQ "mongo_maxStaleness"
                                        ? "UNSUPPORTED: installed setMongoDataSource has no maxStalenessSeconds parameter; no configuration changed."
                                        : "NoSQL API, fixture baseline, or synchronization failed; exception details withheld.";
                        </cfscript>
                </cfcatch>
                <cffinally>
                        <cftry>
                                <cfset testUtil.restoreSyncTest(testDvr, syncTestResult, SETTING_NAME)>
                                <cfcatch type="any">
                                        <cfset passed = false>
                                        <cfset diagnostic = "FAILED: reserved MongoDB fixture cleanup could not be verified on every captured node.">
                                </cfcatch>
                        </cftry>
                </cffinally>
        </cftry>
        <cf_qatest id="test-Data_Services-NoSQL-#SETTING_NAME#">
                <cfscript>
                        writeOutput(stUtil.getQatestResultMessage(passed, SETTING_NAME, diagnostic));
                </cfscript>
                <cf_expectedresults>
                        setting values as expected<br>
                </cf_expectedresults>
        </cf_qatest>
        <cf_qatestEnd stats=true>
</cflock>