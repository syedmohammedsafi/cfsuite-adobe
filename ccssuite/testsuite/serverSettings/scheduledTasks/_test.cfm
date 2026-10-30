<cfscript>
SETTING_NAME = structKeyExists(request, "scheduledTaskSetting") ? request.scheduledTaskSetting
        : (structKeyExists(url, "setting") ? trim(url.setting) : "");
configUtil = new cfsuite.ccssuite.utils.scheduledTasksConfigUtil().init();
taskUtil = new cfsuite.ccssuite.utils.scheduledTasksTestUtil().init();
stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
testDvr = new cfsuite.ccssuite.testDriver();
syncTestResult = {};
fields = configUtil.getFields();
if(NOT structKeyExists(fields, SETTING_NAME) AND SETTING_NAME NEQ "dsnname"){
        cfheader(statusCode=400);
        writeOutput("Unsupported scheduled task field.");
        abort;
}
createSchedulerTables = structKeyExists(request, "createSchedulerTables") AND request.createSchedulerTables;
label = createSchedulerTables ? "Create Tables for Cluster Setup"
        : (SETTING_NAME EQ "dsnname" ? "Select Datasource" : fields[SETTING_NAME]);
</cfscript>
<cfoutput><h2>Scheduled Tasks - #encodeForHTML(label)#</h2></cfoutput>
<cftry>
        <cfscript>
                testDsn = structKeyExists(form, "testDsn") ? trim(form.testDsn)
                        : (structKeyExists(url, "testDsn") ? trim(url.testDsn) : "");
                syncTestResult = taskUtil.runSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME, testDsn, createSchedulerTables);
        </cfscript>
        <cfif structKeyExists(syncTestResult, "skipped") AND syncTestResult.skipped>
                <cfoutput><p>SKIPPED: #encodeForHTML(syncTestResult.message)#</p></cfoutput>
        <cfelse>
                <cf_qatest id="test-Server_Settings-Scheduled_Tasks-#createSchedulerTables ? 'createtables' : SETTING_NAME#">
                        <cfscript>
                                writeOutput(stUtil.getQatestResultMessage(syncTestResult.passed, SETTING_NAME, "Scheduled task CCS synchronization expectation was not satisfied."));
                        </cfscript>
                        <cf_expectedresults>
                                setting values as expected<br>
                        </cf_expectedresults>
                </cf_qatest>
                <cf_qatestEnd stats=true>
                <cfif createSchedulerTables>
                        <p>The scheduler datasource is restored during cleanup. Database table changes are retained.</p>
                </cfif>
        </cfif>
        <cfcatch type="any">
                <cfoutput><p>An error occurred in the test: #encodeForHTML(cfcatch.message & " " & cfcatch.detail)#</p></cfoutput>
        </cfcatch>
        <cffinally>
                <cfscript>
                        taskUtil.restoreSyncTest(testDvr, syncTestResult, SETTING_NAME);
                </cfscript>
        </cffinally>
</cftry>