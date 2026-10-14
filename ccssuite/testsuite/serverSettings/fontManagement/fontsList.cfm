<h2>Font Management - Font data list</h2>
<cftry>
        <cfscript>
                rows = new cfsuite.ccssuite.utils.fontManagementConfigUtil().init().getFontRows(true);
                columns = ["family", "face", "postscriptName", "fontType", "usableIn", "path"];
                valid = true;
                for(row in rows){
                        for(column in columns){
                                if(NOT structKeyExists(row, column) OR NOT isSimpleValue(row[column]))
                                        valid = false;
                        }
                }
        </cfscript>
        <cf_qatest id="test-Server_Settings-Font_Management-fontsList">
                <cfscript>
                        writeOutput(valid ? "font list columns as expected<br>" : "font list columns NOT as expected<br>");
                </cfscript>
                <cf_expectedresults>
                        font list columns as expected<br>
                </cf_expectedresults>
        </cf_qatest>
        <cf_qatestEnd stats=true>
        <table border="1" cellpadding="5" cellspacing="0">
                <thead><tr><th>Font Family</th><th>Font Face</th><th>Postscript Name</th><th>Font Type</th><th>Usable In</th><th>Path</th></tr></thead>
                <tbody>
                        <cfoutput>
                                <cfloop array="#rows#" index="row">
                                        <tr><cfloop array="#columns#" index="column"><td>#encodeForHTML("" & row[column])#</td></cfloop></tr>
                                </cfloop>
                                <cfif NOT arrayLen(rows)><tr><td colspan="6">No registered fonts.</td></tr></cfif>
                        </cfoutput>
                </tbody>
        </table>
        <cfcatch type="any">
                <cfoutput><p>An error occurred in the test: #encodeForHTML(cfcatch.message & " " & cfcatch.detail)#</p></cfoutput>
        </cfcatch>
</cftry>