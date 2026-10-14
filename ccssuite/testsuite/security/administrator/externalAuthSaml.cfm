<!---
* @file  externalAuthSaml.cfm
* @description External Authentication — SAML — multi-node CCS sync test.
*
* Sets via coldfusion.server.SecurityService.setExternalAuth("SAML", samlConfigStruct) directly (see
* externalAuthNone.cfm for why this bypasses CFIDE.adminapi.security, which doesn't expose this method).
* Reuses whatever SamlConfig (idpName/spName/groupName) is already configured on this node
* (ss.getAdminSamlConfig(), currently idp_own/okta_sp/admin124) rather than fabricating a new IDP/SP pairing
* -- this test only flips which auth type is ACTIVE, it doesn't create or modify IDP/SP definitions (that's
* covered separately by testsuite/security/idpConfiguration and spConfiguration).
*
* RISK NOTE: while SAML is the active ExternalAuth type, any *new* admin console login attempt on this node
* would be routed through the SAML flow instead of username/password, for as long as that state lasts. The
* window here is bounded by this single request's cftry/cffinally -- restoreSecuritySyncTest() always runs in
* cffinally and puts ExternalAuth back to whatever it was before this test ran -- but if that restore step
* itself were interrupted (e.g. a server crash exactly mid-test), a subsequent admin login would need SAML
* to complete rather than a plain password. This is the same bounded-exposure-window pattern already used by
* every other setting in this suite (e.g. AllowConcurrentAdminLogin), just on a setting where the mid-flight
* state briefly changes how login itself works rather than a passive config value.
--->
<h2>External Authentication — SAML</h2>
<p>File: security/administrator/externalAuthSaml.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "ExternalAuthSaml";
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
