<cfscript>
SETTING_NAME = structKeyExists(request, "fontManagementSetting") ? request.fontManagementSetting : "";
if(NOT listFindNoCase("fontPath,fontDirectory", SETTING_NAME)){
        cfheader(statusCode=400);
        writeOutput("Unsupported font registration setting.");
        abort;
}
testDvr = new cfsuite.ccssuite.testDriver();
stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
fontUtil = new cfsuite.ccssuite.utils.fontManagementTestUtil().init();
syncTestResult = {};
</cfscript>
<cfoutput><h2>Font Management - <cfif SETTING_NAME EQ "fontPath">New Font<cfelse>New Font Directory</cfif></h2></cfoutput>
<cftry>
        <cfscript>
                syncTestResult = fontUtil.runSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
        </cfscript>
        <cf_qatest id="test-Server_Settings-Font_Management-#SETTING_NAME#">
                <cfscript>
                        writeOutput(stUtil.getQatestResultMessage(syncTestResult.passed, SETTING_NAME, "Font registration did not match the CCS synchronization expectation."));
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
                        fontUtil.restoreSyncTest(testDvr, syncTestResult, SETTING_NAME);
                </cfscript>
        </cffinally>
</cftry>