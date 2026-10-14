<h2>Maintain connection to mail server</h2>
<p>File: mailMaintainConnections.cfm</p>
<br>
<cftry>
        <cfscript>
                final SETTING_NAME = "maintainconnections";
                testDvr = new cfsuite.ccssuite.testDriver();
                stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
                syncTestResult = {};
                syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
        </cfscript>

        <cf_qatest id="test-Server_Settings-Mail-#SETTING_NAME#">
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
                        stUtil.restoreMultiNodeSyncTest(testDvr, syncTestResult, SETTING_NAME);
                </cfscript>
        </cffinally>
</cftry>