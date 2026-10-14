<!---
* @file  mailVerifyServerConnection.cfm
* @description Verify mail server connection - TCP reachability check (not a persisted setting)
--->
<h2>Verify mail server connection (TCP)</h2>
<p>File: mailVerifyServerConnection.cfm</p>
<br>
<cftry>
	<cfscript>
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		verifyResult = stUtil.verifyMailServerConnection();
	</cfscript>

	<cf_qatest id="test-Server_Settings-Mail-verify-server-connection">
		<cfscript>
			writeOutput(verifyResult.success ? "mail server TCP connection verified<br>" : "mail server TCP connection failed<br>");
		</cfscript>
		<cf_expectedresults>
			mail server TCP connection verified<br>
		</cf_expectedresults>
	</cf_qatest>

	<cfoutput>
		<p>
			<cfif verifyResult.success>
				TCP connection established to #encodeForHTML(verifyResult.server)#:#verifyResult.port#.
			<cfelse>
				Could not establish a TCP connection to #encodeForHTML(verifyResult.server)#:#verifyResult.port#: #encodeForHTML(verifyResult.message)#
			</cfif>
		</p>
	</cfoutput>

	<cf_qatestEnd stats=true>

	<cfcatch type="any">
		<cfoutput>
			<p>An error occurred in the test: #cfcatch.message# #cfcatch.detail#</p>
		</cfoutput>
	</cfcatch>
</cftry>
