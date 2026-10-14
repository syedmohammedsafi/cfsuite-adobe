<!---
* @file  isGroup.cfm
* @description "Group" checkbox (Add/Edit User) — multi-node CCS sync test.
*
* Confirmed live via setUser(isGroup=true)/getUser().ISGROUP that this round-trips as a plain flag with no
* external identity configuration required -- unlike isLdap/isSaml (the LDAP/SAML radio options on the same
* form), which threw an unrecoverable error when set without a real external LDAP/SAML source configured.
* That's why isGroup gets its own test here while External User/LDAP/SAML remain excluded (see i.cfm).
--->
<h2>Group (User Manager)</h2>
<p>File: security/userManager/isGroup.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "IsGroup";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runUserManagerSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-UserManager-#SETTING_NAME#">
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
