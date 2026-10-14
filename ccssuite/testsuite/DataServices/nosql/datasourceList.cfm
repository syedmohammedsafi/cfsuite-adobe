<cfscript>
passed = false;
summary = {};
try {
        summary = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init().getListSummary();
        passed = summary.configurationWrites EQ false AND summary.mongodbCount LTE summary.datasourceCount;
}
catch(any failure){}
stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
</cfscript>
<h2>NoSQL Data Sources - List</h2>
<cf_qatest id="test-Data_Services-NoSQL-list">
        <cfscript>
                writeOutput(stUtil.getQatestResultMessage(passed, "NoSQL datasource list",
                        "Read-only NoSQL list API failed; configuration and exception details withheld."));
        </cfscript>
        <cf_expectedresults>
                setting values as expected<br>
        </cf_expectedresults>
</cf_qatest>
<cf_qatestEnd stats=true>