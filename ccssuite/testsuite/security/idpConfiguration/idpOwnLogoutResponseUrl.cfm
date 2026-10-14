<!---
* @file  idpOwnLogoutResponseUrl.cfm
* @description Own SAML definition Logout Response URL — multi-node CCS sync test
--->
<h2>IDP Logout Response URL (Own SAML Definition)</h2>
<p>File: security/idpConfiguration/idpOwnLogoutResponseUrl.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "IdpOwnLogoutResponseUrl";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runIdpOwnFieldSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-IdpConfiguration-#SETTING_NAME#">
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
