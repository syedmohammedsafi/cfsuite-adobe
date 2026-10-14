<!---
* @file  copyFromSandbox.cfm
* @description Add Security Sandbox — "New sandbox, or pick one to copy from" — multi-node CCS sync test.
*
* Adds a second, independent test sandbox (distinct from addSandboxPath.cfm's own test path, so the two
* never collide) whose permissions are copied from an existing real sandbox
* (securityConfigUtil.getCopyFromSourceSandboxPath() -- the CFIDE system sandbox, the same sandbox
* getDefaultSandboxPermissions() already uses elsewhere as a reasonable existing-sandbox template).
* Verifies the copy-target sandbox syncs to all cluster nodes AND that its permissions genuinely match the
* source sandbox's -- presence alone wouldn't catch a copy that silently landed on some other/default
* permission set instead of the one actually being copied.
*
* Add-only, same pattern as addSandboxPath.cfm: cleanup always deletes the copy-target path on all cluster
* nodes in the background (no delete verification table), with a final cleanup in cffinally as a safety net.
--->
<h2>Add Security Sandbox — Copy From Existing</h2>
<p>File: security/sandboxSecurity/copyFromSandbox.cfm</p>
<br>
<cftry>
	<cfscript>
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		secUtil = new cfsuite.ccssuite.utils.securityTestUtil().init();
		syncTestResult = secUtil.runSandboxPathCopyFromSyncTest(testDvr, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Security-SandboxSecurity-CopyFromSandbox">
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
			secUtil.cleanupSandboxCopyPathAfterTest(
				testDvr,
				CGI.SCRIPT_NAME,
				structKeyExists(syncTestResult, "wasPrimarySandboxPresent") ? syncTestResult.wasPrimarySandboxPresent : true
			);
		</cfscript>
	</cffinally>
</cftry>
