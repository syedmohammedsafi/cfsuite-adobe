<!---
* @file  externalAuthLdap.cfm
* @description External Authentication — LDAP — multi-node CCS sync test.
*
* Sets via coldfusion.server.SecurityService.setExternalAuth("LDAP", struct) directly (see
* externalAuthNone.cfm for why this bypasses CFIDE.adminapi.security, which doesn't expose this method).
* Passes an empty config struct: LDAP connection details (host/port/bind DN/etc, confirmed via
* ss.getAdminLdapConfiguration()) are managed separately through setAdminLdapConfiguration() -- exactly how
* the real Admin UI's own "Edit LDAP Configuration" dialog on this page works, separately from the radio
* button itself. This test only flips which auth type is ACTIVE; it does not touch the stored LDAP
* connection details.
*
* RISK NOTE: the LDAP connection currently stored in neo-security.xml on this node is placeholder/test data
* (127.0.0.1:455, "test" base contexts) -- not a reachable directory server. See externalAuthSaml.cfm for the
* general bounded-exposure-window reasoning (restoreSecuritySyncTest always runs in cffinally); the added risk
* here specifically is that while LDAP is active, a *new* admin login attempt on this node would be routed
* through that unreachable placeholder LDAP server and would fail outright, rather than merely using a
* different-but-working auth path like the SAML case. If this test's restore step is ever interrupted, fixing
* login access requires manually resetting ExternalAuth (e.g. via neo-security.xml) server-side.
--->
<h2>External Authentication — LDAP</h2>
<p>File: security/administrator/externalAuthLdap.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "ExternalAuthLdap";
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
