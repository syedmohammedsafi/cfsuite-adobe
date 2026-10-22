<!---
* @file  seed.cfm
* @description ColdFusion Administrator — New Seed configuration — single-node test.
* Seed rotates encryption key material local to each instance (nodesScope="currentPort").
* Sets and verifies server seed via CFIDE.adminapi.security.setSeed().
--->
<h2>ColdFusion Administrator — New Seed (setSeed)</h2>
<p>File: security/administrator/seed.cfm</p>
<br>
<cfscript>
	SETTING_NAME = "Seed";
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
