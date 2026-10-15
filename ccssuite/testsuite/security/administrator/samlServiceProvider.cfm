<h2>External Authentication - SAML - Service Provider</h2>
<cfscript>
    SETTING_NAME = "AdminSamlServiceProvider";
    syncTestResult = {};
    testDvr = new cfsuite.ccssuite.testDriver();
    secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
</cfscript>
<cftry>
    <cfscript>
        secUtil.runAdministratorSamlSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME, syncTestResult);
    </cfscript>
    <cf_qatest id="test-Security-Administrator-#SETTING_NAME#">
        <cfscript>
            writeOutput(secUtil.getQatestResultMessage(syncTestResult.passed));
        </cfscript>
        <cf_expectedresults>
            setting values as expected<br>
        </cf_expectedresults>
    </cf_qatest>
    <cf_qatestEnd stats=true>
    <cfcatch type="any">
        <cfoutput><p>An error occurred in the test: #encodeForHTML(cfcatch.message)# #encodeForHTML(cfcatch.detail)#</p></cfoutput>
    </cfcatch>
    <cffinally>
        <cfscript>
            secUtil.restoreSecuritySyncTest(testDvr, syncTestResult);
        </cfscript>
    </cffinally>
</cftry>