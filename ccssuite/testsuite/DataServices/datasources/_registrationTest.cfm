<cfscript>
SETTING_NAME = structKeyExists(request, "datasourceSetting") ? request.datasourceSetting : "";
configUtil = new cfsuite.ccssuite.utils.datasourceConfigUtil().init();
if(NOT listFindNoCase("dsn,driver", SETTING_NAME) AND NOT configUtil.isPreparedDatasourceSetting(SETTING_NAME)){
        cfheader(statusCode=400);
        writeOutput("Unsupported Data Sources setting.");
        abort;
}
testDvr = new cfsuite.ccssuite.testDriver();
stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
dsUtil = new cfsuite.ccssuite.utils.dataServicesTestUtil().init();
syncTestResult = {};
</cfscript>
<cfoutput><h2>Data Sources - #encodeForHTML(configUtil.getSettingLabel(SETTING_NAME))#</h2></cfoutput>
<cfif SETTING_NAME EQ "derbyEmbeddedCreateDatabase">
        <p>The API may create files in a reserved test folder. Cleanup removes only datasource registrations, not database files. Run only on disposable instances.</p>
</cfif>
<cftry>
        <cfscript>
                syncTestResult = dsUtil.runDatasourceSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
        </cfscript>
        <cf_qatest id="test-Data_Services-Data_Sources-#SETTING_NAME#">
                <cfscript>
                        writeOutput(stUtil.getQatestResultMessage(syncTestResult.passed, SETTING_NAME,
                                "Datasource registration did not match the CCS synchronization expectation."));
                </cfscript>
                <cf_expectedresults>
                        setting values as expected<br>
                </cf_expectedresults>
        </cf_qatest>
        <cf_qatestEnd stats=true>
        <cfcatch type="any">
                <cfoutput><p>An error occurred in the test: #encodeForHTML(cfcatch.message & " " & cfcatch.detail)#</p></cfoutput>
        </cfcatch>
        <cffinally>
                <cfscript>
                        dsUtil.restoreDatasourceSyncTest(testDvr, syncTestResult, SETTING_NAME);
                </cfscript>
        </cffinally>
</cftry>