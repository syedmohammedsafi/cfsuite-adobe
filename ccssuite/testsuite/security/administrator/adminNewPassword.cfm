<!---
* @file  adminNewPassword.cfm
* @description Administrator Authentication — Password Updation Process — dynamic per-instance test.
* Tests the full password updation process:
* 1. Dynamic verification of current administrator password.
* 2. Dynamic validation of old password (acceptance & rejection).
* 3. Dynamic validation of confirm password matching/mismatch blocking.
* 4. Dynamic application of new password on local instance via SecurityService.setAdminPassword().
* 5. Dynamic verification that sub-instances DO NOT sync (per-instance credential, matching UI behavior).
* 6. Dynamic rollback/restoration of original password.
--->
<h2>Administrator Authentication — Password Updation Process</h2>
<p>File: security/administrator/adminNewPassword.cfm</p>
<br>
<cfscript>
	SETTING_NAME = "AdminNewPassword";
	syncTestResult = {};
	testDvr = new cfsuite.ccssuite.testDriver();
	secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
</cfscript>
<cftry>
	<cfscript>
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
			if(structKeyExists(variables, "secUtil") AND structKeyExists(variables, "testDvr") AND structKeyExists(variables, "syncTestResult")){
				secUtil.restoreSecuritySyncTest(testDvr, syncTestResult);
			}
		</cfscript>
	</cffinally>
</cftry>
