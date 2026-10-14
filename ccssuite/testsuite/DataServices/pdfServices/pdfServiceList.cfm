<!---
* @file  pdfServiceList.cfm
* @description PDF Services - Data list (Actions, Name, Host Name, Port, Weight, Https Enabled, Engine, Status)
--->
<h2>PDF Services - Data list</h2>
<p>File: pdfServiceList.cfm</p>
<br>
<cftry>
	<cfscript>
		configUtil = new cfsuite.ccssuite.utils.pdfServiceConfigUtil().init();
		rows = configUtil.getPdfServiceRows();
		columns = ["actions", "name", "hostName", "port", "weight", "httpsEnabled", "engine", "status"];
	</cfscript>
	<cf_qatest id="test-Data_Services-PDF_Services-pdfServiceList">
		<cfscript>
			writeOutput("PDF service list columns as expected<br>");
		</cfscript>
		<cf_expectedresults>
			PDF service list columns as expected<br>
		</cf_expectedresults>
	</cf_qatest>
	<cf_qatestEnd stats=true>
	<table border="1" cellpadding="5" cellspacing="0">
		<thead>
			<tr>
				<th>Actions</th>
				<th>Name</th>
				<th>Host Name</th>
				<th>Port</th>
				<th>Weight</th>
				<th>Https Enabled</th>
				<th>Engine</th>
				<th>Status</th>
			</tr>
		</thead>
		<tbody>
			<cfoutput>
				<cfloop array="#rows#" index="row">
					<tr>
						<cfloop array="#columns#" index="column">
							<td>#encodeForHTML("" & row[column])#</td>
						</cfloop>
					</tr>
				</cfloop>
				<cfif NOT arrayLen(rows)><tr><td colspan="8">No registered PDF services.</td></tr></cfif>
			</cfoutput>
		</tbody>
	</table>
	<cfcatch type="any">
		<cfoutput><p>An error occurred in the test: #encodeForHTML(cfcatch.message & " " & cfcatch.detail)#</p></cfoutput>
	</cfcatch>
</cftry>
