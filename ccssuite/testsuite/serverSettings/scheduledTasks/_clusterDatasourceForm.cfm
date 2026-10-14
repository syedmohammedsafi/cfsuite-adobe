<cfscript>
clusterConfigUtil = new cfsuite.ccssuite.utils.scheduledTasksConfigUtil().init();
datasourceNames = clusterConfigUtil.getDatasourceNames();
submittedDsn = structKeyExists(form, "testDsn") ? trim(form.testDsn)
        : (structKeyExists(url, "testDsn") ? trim(url.testDsn) : "");
approvedDsn = structKeyExists(form, "approvedDisposable") AND form.approvedDisposable EQ "yes";
createsTables = structKeyExists(request, "createSchedulerTables") AND request.createSchedulerTables;
canRunDatasourceTest = len(submittedDsn) AND (approvedDsn OR (NOT createsTables AND structKeyExists(url, "testDsn")));
if(canRunDatasourceTest){
        if(NOT arrayFindNoCase(datasourceNames, submittedDsn)){
                cfheader(statusCode=400);
                writeOutput("The selected datasource is not configured on this instance. No configuration was changed.");
                abort;
        }
}
</cfscript>
<cfif NOT canRunDatasourceTest>
<cfoutput>
        <h2>Scheduled Tasks - <cfif createsTables>Create Tables for Cluster Setup<cfelse>Select Datasource</cfif></h2>
        <form method="post" action="#encodeForHTMLAttribute(CGI.SCRIPT_NAME)#">
                <p>
                        <label for="testDsn">Select Datasource</label>
                        <select id="testDsn" name="testDsn" required>
                                <option value="">Select a disposable test datasource</option>
                                <cfloop array="#datasourceNames#" index="datasourceName">
                                        <option value="#encodeForHTMLAttribute(datasourceName)#">#encodeForHTML(datasourceName)#</option>
                                </cfloop>
                        </select>
                </p>
                <p>
                        <label><input type="checkbox" name="approvedDisposable" value="yes" required> I confirm this datasource and the participating CCS instances are disposable test resources.</label>
                </p>
                <cfif createsTables>
                        <p>Scheduler tables may be created or replaced. Database schema changes are retained after the scheduler datasource is restored.</p>
                <cfelse>
                        <p>The datasource must already contain compatible scheduler cluster tables and be configured on every participating CCS node. This test does not create tables.</p>
                </cfif>
                <button type="submit"><cfif createsTables>Create Tables and Test<cfelse>Run Datasource Test</cfif></button>
        </form>
</cfoutput>
<cfabort>
</cfif>