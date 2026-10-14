<!---
* @file  externalAuthNone.cfm
* @description External Authentication — NONE (disable SAML/LDAP, fall back to the CF Administrator's own
* username/password login) — multi-node CCS sync test.
*
* Sets via coldfusion.server.SecurityService.setExternalAuth("None", struct) directly (confirmed by
* reflection to exist even though CFIDE.adminapi.security does not expose it, and the CF2025 Admin UI's own
* "External Authentication" radio group on this exact page saves through the same method). See
* securityConfigUtil.cfc's EXTERNAL_AUTH_NONE_SETTING alias and setExternalAuthType() for why this uses a
* dedicated alias name rather than the generic ExternalAuth setting: the generic sync engine only ever
* computes "current -> the other value", which can't express "always land on NONE" for a 3-way setting.
*
* This is the lowest-risk of the three ExternalAuth tests: NONE disables external auth rather than pointing
* live admin login at an external SAML/LDAP source, so there's no window where a real login could be forced
* through a config that isn't ready to authenticate anyone.
--->
<h2>External Authentication — NONE</h2>
<p>File: security/administrator/externalAuthNone.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "ExternalAuthNone";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runAdministratorSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-Administrator-#SETTING_NAME#">
		<cfscript>
			writeOutput(secUtil.getQatestResultMessage(syncTestResult.passed));
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
			secUtil.restoreSecuritySyncTest(testDvr, syncTestResult);
		</cfscript>
	</cffinally>
</cftry>
