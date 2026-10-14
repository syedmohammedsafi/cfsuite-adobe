<!---
* @file  awsAccessKey.cfm
* @description Add/Edit Cloud Credentials - AWS Access Key — create, verify sync across nodes,
* then remove, using a fixed, dedicated test alias "CCSTestCloudAccessKey" (kept separate from
* the other Cloud Credentials field tests so none of them interfere with each other). The tracked
* value here is the accessKeyId string itself for that alias, not the Cloud Vendor/AWS Region/
* Secret Key/Session Token fields — addCredential() still needs a full credential body to
* register with, so fixed fake AWS values are used internally for that, but those field values
* aren't what this test verifies.
*
* accessKeyId is auto-encrypted on disk (confirmed directly: neo-cloudcredential.xml stores it as
* an opaque blob, not the plaintext set here) — but unlike mail's password field elsewhere in
* this suite, CFIDE.adminapi.cloud.getCredential() decrypts it back to the real plaintext on read
* (confirmed via direct testing), so this uses a plain exact-match comparison rather than the
* changed-to-non-empty leniency mail's password test needs — see cloudCredentialConfigUtil.cfc.
*
* Multi-node via active push, not organic CCS replication: confirmed via direct testing that a
* newly-added credential never appears anywhere in the prime node's own CCS version history —
* real CCS does not track this file at all in this environment. serverSettingsApiUtil.
* requiresPeerInstancePropagation() flags the "cloudCredentials" area (for every setting name
* within it, including this one) so testDriver.cfc actively re-applies the same
* addCredential()/deleteCredential() call on each peer node directly, instead of passively
* waiting on CCS.
--->
<h2>Add/Edit Cloud Credentials - AWS Access Key (create, verify sync, remove)</h2>
<p>File: awsAccessKey.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudAccessKey";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Credentials-awsAccessKey">
		<cfscript>
			writeOutput(stUtil.getQatestResultMessage(syncTestResult.passed));
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
			stUtil.restoreMultiNodeSyncTest(testDvr, syncTestResult, SETTING_NAME);
		</cfscript>
	</cffinally>
</cftry>
