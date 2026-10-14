<!---
* @file  systemProbeList.cfm
* @description System Probes - Data list (Actions, Probe Name, Status, Interval, URL)
--->
<h2>System Probes - Data list</h2>
<p>File: systemProbeList.cfm</p>
<br>
<cftry>
	<cfscript>
		configUtil = new cfsuite.ccssuite.utils.systemProbesConfigUtil().init();
		rows = configUtil.getProbeRows();
		columns = ["actions", "probe_name", "status", "interval", "url"];
	</cfscript>
	<cf_qatest id="test-Debugging_Logging-SystemProbes-systemProbeList">
		<cfscript>
			writeOutput("System probe list columns as expected<br>");
		</cfscript>
		<cf_expectedresults>
			System probe list columns as expected<br>
		</cf_expectedresults>
	</cf_qatest>
	<cf_qatestEnd stats=true>
	<table border="1" cellpadding="5" cellspacing="0">
		<thead>
			<tr>
				<th>Actions</th>
				<th>Probe Name</th>
				<th>Status</th>
				<th>Interval</th>
				<th>URL</th>
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
				<cfif NOT arrayLen(rows)><tr><td colspan="5">No probes are defined.</td></tr></cfif>
			</cfoutput>
		</tbody>
	</table>
	<cfcatch type="any">
		<cfoutput><p>An error occurred in the test: #encodeForHTML(cfcatch.message & " " & cfcatch.detail)#</p></cfoutput>
	</cfcatch>
</cftry>
