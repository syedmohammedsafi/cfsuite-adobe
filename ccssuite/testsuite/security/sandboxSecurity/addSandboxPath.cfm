<!---
* @file  addSandboxPath.cfm
* @description Add Security Sandbox directory path — multi-node CCS sync test
--->
<h2>Add Security Sandbox Path</h2>
<p>File: security/sandboxSecurity/addSandboxPath.cfm</p>
<br>
<cftry>
	<cfscript>
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runSandboxPathAddSyncTest(testDvr, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-SandboxSecurity-AddSandboxPath">
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
			secUtil.cleanupTestSandboxPathAfterAddTest(testDvr, CGI.SCRIPT_NAME);
		</cfscript>
	</cffinally>
</cftry>
