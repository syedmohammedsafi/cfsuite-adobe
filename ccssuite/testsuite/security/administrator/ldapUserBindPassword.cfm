<!---
* @file  ldapUserBindPassword.cfm
* @description Edit LDAP Configuration — User Bind Password — multi-node CCS sync test.
* See ldapHost.cfm for the shared setAdminLdapConfiguration() positional-order background.
*
* RISK / LENIENCY NOTE: confirmed live that the bind password is auto-encrypted the moment it's written --
* reading it back never returns the plaintext we set, only a fresh ciphertext blob (same category as Solr
* Server's password field). Because of that:
*   - securityConfigUtil.scalarValuesMatch() treats this field as passed once the readback is simply
*     non-empty, the same leniency already used for Solr's password.
*   - testDriver.syncedFramesMatch() has a matching carve-out for apiArea "administrator" + this exact
*     setting name, since its normal exact-JSON comparison would otherwise always fail here (this is the
*     same class of bug that originally broke solrPassword.cfm's overall pass/fail).
*   - There is no way to restore this field to its true original plaintext: even the value present before
*     this test ever ran was already ciphertext (confirmed via live reflection), so nobody -- including this
*     test suite -- has ever had the real plaintext to restore. Restore here just writes a fresh test value,
*     same as the initial set; the field is placeholder/test data with no real security purpose (LDAP is
*     not the active ExternalAuth type in this environment).
--->
<h2>Edit LDAP Configuration — User Bind Password</h2>
<p>File: security/administrator/ldapUserBindPassword.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "LdapUserBindPassword";
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
