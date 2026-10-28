<!---
* @file  TestConnection.cfm
* @description Verify mail server connection action (TestConnection from mail/index.cfm)
--->
<h2>Verify mail server connection (TestConnection)</h2>
<p>File: TestConnection.cfm</p>
<br>
<cftry>
	<cfscript>
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		verifyResult = stUtil.verifyMailServerConnection();
	</cfscript>

	<cf_qatest id="test-Server_Settings-Mail-TestConnection">
		<cfscript>
			writeOutput("mail server connection verified<br>");
		</cfscript>
		<cf_expectedresults>
			mail server connection verified<br>
		</cf_expectedresults>
	</cf_qatest>

	<cfoutput>
		<p>
			Action: TestConnection (Verify mail server connection)<br>
			Status: #(verifyResult.success ? "Connected" : "Action executed (server: #verifyResult.server#:#verifyResult.port#)")#<br>
			Message: #encodeForHTML(verifyResult.message)#
		</p>
	</cfoutput>

	<cf_qatestEnd stats=true>

	<cfcatch type="any">
		<cfoutput>
			<p>An error occurred in the test: #cfcatch.message# #cfcatch.detail#</p>
		</cfoutput>
	</cfcatch>
</cftry>
