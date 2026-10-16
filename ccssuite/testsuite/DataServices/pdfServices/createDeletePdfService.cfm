<!---
* @file  createDeletePdfService.cfm
* @description Create and Delete PDF Service with multi-node CCS synchronization verification.
*              Pass delete=1 or delete=true in the URL to delete the service;
*              omitting delete or passing delete=0/false creates/registers the service.
--->
<cfsetting requesttimeout="120">

<cfscript>
	// Parse delete argument: supports delete=1, delete=true, delete=yes
	isDelete = false;
	if(structKeyExists(url, "delete")){
		dVal = trim(lCase(url.delete));
		if(dVal EQ "1" OR dVal EQ "true" OR dVal EQ "yes" OR (isBoolean(dVal) AND dVal)){
			isDelete = true;
		}
	}

	// Service name: configurable via url.name / url.serviceName, defaulting to "CCSTestPDFService"
	serviceName = "CCSTestPDFService";
	if(structKeyExists(url, "name") AND len(trim(url.name))){
		serviceName = trim(url.name);
	}
	else if(structKeyExists(url, "serviceName") AND len(trim(url.serviceName))){
		serviceName = trim(url.serviceName);
	}

	actionLabel = isDelete ? "DELETE" : "CREATE";
	targetValue = isDelete ? "" : serviceName;
	configUtil = new cfsuite.ccssuite.utils.pdfServiceConfigUtil().init();
</cfscript>

<cfoutput>
<h2>PDF Services — #actionLabel# Service (CCS Verification)</h2>
<p>File: createDeletePdfService.cfm</p>

<div style="background:##f4f6f8; border-left:4px solid #(isDelete ? '##d9534f' : '##5cb85c')#; padding:10px 14px; margin-bottom:15px; font-family:Segoe UI, Arial, sans-serif;">
	<strong>Current Action:</strong> <span style="color:#(isDelete ? '##c9302c' : '##398439')#; font-weight:bold;">#actionLabel#</span><br>
	<strong>Target Service Name:</strong> <code>#encodeForHTML(serviceName)#</code><br>
	<strong>Quick Action Switcher:</strong>
	<cfif isDelete>
		<a href="createDeletePdfService.cfm?name=#urlEncodedFormat(serviceName)#" style="margin-left:8px; color:##2b6cb0; font-weight:600;">&rarr; Switch to CREATE service (?delete=0)</a>
	<cfelse>
		<a href="createDeletePdfService.cfm?delete=1&name=#urlEncodedFormat(serviceName)#" style="margin-left:8px; color:##c9302c; font-weight:600;">&rarr; Switch to DELETE service (?delete=1)</a>
	</cfif>
	| <a href="pdfServiceList.cfm" style="margin-left:8px; color:##4a5568;">View PDF Service List &rarr;</a>
</div>
</cfoutput>

<cftry>
	<cfscript>
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		testDvr = new cfsuite.ccssuite.testDriver();

		initedTestFrame = stUtil.initTestFrame(testDvr, serviceName, CGI.SCRIPT_NAME, true);

		// Run multi-node sync test:
		// When isDelete is true, targetValue = "" (deletes the service across nodes).
		// When isDelete is false, targetValue = serviceName (creates/registers the service across nodes).
		syncTestResult = stUtil.runMultiNodeSettingSyncTest(
			testDvr,
			serviceName,
			CGI.SCRIPT_NAME,
			targetValue,
			initedTestFrame
		);
	</cfscript>

	<!--- QA Test Report Block with graceful custom-tag fallback --->
	<cftry>
		<cf_qatest id="test-Data_Services-PDF_Services-#isDelete ? 'delete' : 'create'#">
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
				<h3>id= test-Data_Services-PDF_Services-#isDelete ? 'delete' : 'create'#</h3>
				#stUtil.getQatestResultMessage(syncTestResult.passed)#
				<cfif syncTestResult.passed>
					<font color="##008000"><strong>Passed!</strong></font>
				<cfelse>
					<font color="##ff0000"><strong>Failed!</strong></font>
				</cfif>
			</cfoutput>
		</cfcatch>
	</cftry>

	<!--- Live PDF Services Table on current node for verification --->
	<cfscript>
		rows = configUtil.getPdfServiceRows();
		columns = ["actions", "name", "hostName", "port", "weight", "httpsEnabled", "engine", "status"];
	</cfscript>
	<br>
	<h3>Current PDF Services on Current Node:</h3>
	<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse; font-family:Segoe UI, Arial, sans-serif;">
		<thead>
			<tr bgcolor="##f0f0f0">
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
					<tr <cfif row.name EQ serviceName>style="background:##e6fffa; font-weight:bold;"</cfif>>
						<cfloop array="#columns#" index="col">
							<td>#encodeForHTML("" & row[col])#</td>
						</cfloop>
					</tr>
				</cfloop>
				<cfif NOT arrayLen(rows)>
					<tr><td colspan="8">No registered PDF services.</td></tr>
				</cfif>
			</cfoutput>
		</tbody>
	</table>

	<cfcatch type="any">
		<cfoutput>
			<p>An error occurred in the test: #encodeForHTML(cfcatch.message & " " & cfcatch.detail)#</p>
		</cfoutput>
	</cfcatch>
</cftry>
