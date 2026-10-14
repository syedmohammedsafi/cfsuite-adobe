<h2>Data Sources - Data list</h2>
<cftry>
        <cfscript>
                configUtil = new cfsuite.ccssuite.utils.datasourceConfigUtil().init();
                rows = configUtil.getDatasourceRows();
                columns = ["actions", "dsn", "driver", "status"];
                valid = configUtil.listColumnsMatch(rows);
        </cfscript>
        <cf_qatest id="test-Data_Services-Data_Sources-datasourceList">
                <cfscript>
                        writeOutput(valid ? "datasource list columns as expected<br>" : "datasource list columns NOT as expected<br>");
                </cfscript>
                <cf_expectedresults>
                        datasource list columns as expected<br>
                </cf_expectedresults>
        </cf_qatest>
        <cf_qatestEnd stats=true>
        <table border="1" cellpadding="5" cellspacing="0">
                <thead><tr><th>Actions</th><th>Data Source Name</th><th>Driver</th><th>Status</th></tr></thead>
                <tbody>
                        <cfoutput>
                                <cfloop array="#rows#" index="row">
                                        <tr><cfloop array="#columns#" index="column"><td>#encodeForHTML("" & row[column])#</td></cfloop></tr>
                                </cfloop>
                                <cfif NOT arrayLen(rows)><tr><td colspan="4">No registered datasources.</td></tr></cfif>
                        </cfoutput>
                </tbody>
        </table>
        <cfcatch type="any">
                <cfoutput><p>An error occurred in the test: #encodeForHTML(cfcatch.message & " " & cfcatch.detail)#</p></cfoutput>
        </cfcatch>
</cftry>