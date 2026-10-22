<!---
* @file  ldapTimeout.cfm
* @description Edit LDAP Configuration — Server Timeout — multi-node CCS sync test.
* See ldapHost.cfm for the shared setAdminLdapConfiguration() positional-order background.
--->
<h2>Edit LDAP Configuration — Server Timeout</h2>
<p>File: security/administrator/ldapTimeout.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "LdapTimeout";
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
