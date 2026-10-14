<!---
* @file  ldapHost.cfm
* @description Edit LDAP Configuration — Host — multi-node CCS sync test.
*
* Sets via coldfusion.server.SecurityService.setAdminLdapConfiguration(13 positional args) directly (not
* exposed by CFIDE.adminapi.security). The positional order was NOT documented anywhere -- Java reflection
* only exposes parameter types, not names -- so it was determined empirically by writing distinct sentinel
* values to a live (test/placeholder) LDAP config and reading back which struct key each one landed in. See
* securityConfigUtil.cfc's setLdapConfigField()/getLdapConfigFieldKey() for the confirmed order: host,
* tcpPort, userBaseContext, groupBaseContext, userbindDN, password, isSSLEnabled, isStartTLSEnabled,
* userConfig, usernameAttr, groupConfig, groupnameAttr, timeout.
*
* setLdapConfigField() always reads the full current config first and only overwrites this one field, so
* the other 12 (including the 6 sibling fields covered by their own test files) are preserved untouched.
* This field is plain text, unlike the bind password -- no encryption leniency needed.
--->
<h2>Edit LDAP Configuration — Host</h2>
<p>File: security/administrator/ldapHost.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "LdapHost";
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
