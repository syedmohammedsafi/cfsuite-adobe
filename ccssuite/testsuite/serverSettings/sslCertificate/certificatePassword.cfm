<!---
* @file  certificatePassword.cfm
* @description Password (CertificatePassword) — server.xml round-trip test
*
* Maps to the certificateKeystorePassword attribute of the <Certificate> element inside the SSL
* Connector block in runtime/conf/server.xml. That block ships commented out, so editing this
* attribute's text is inert to the running Tomcat instance (comments are skipped by its parser) —
* this never uncomments the connector. Written here as plain text (this suite writes the raw XML
* attribute directly, bypassing any admin-side encryption), so an exact-match comparison is valid.
* Runs with nodesScope="currentPort" (see i.cfm): server.xml is per-instance and never replicated
* by CCS, so peer nodes are out of scope for this setting.
--->
<h2>Password</h2>
<p>File: certificatePassword.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CertificatePassword";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME, true, "all", true);
	</cfscript>

	<cf_qatest id="test-Server_Settings-SSL_Certificate-#SETTING_NAME#">
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
			<p>An error occurred in the test: #cfcatch.message# #cfcatch.detail#</p>
		</cfoutput>
	</cfcatch>

	<cffinally>
		<cfscript>
			stUtil.restoreMultiNodeSyncTest(testDvr, syncTestResult, SETTING_NAME);
		</cfscript>
	</cffinally>
</cftry>
