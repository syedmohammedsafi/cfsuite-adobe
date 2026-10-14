<!---
* @file  gcpCredentialJsonFilepath.cfm
* @description Add/Edit Cloud Credentials - Credential JSON Filepath (GCP) — create, verify sync
* across nodes, then remove, using a fixed, dedicated test alias
* "CCSTestGcpCredentialJsonFilepath" (kept separate from every other Cloud Credentials field test
* so none of them interfere with each other). The tracked value here is the
* credentialJsonFilepath string itself for that alias, not the Project Id field —
* addCredential() still needs a full GCP credential body to register with, so a fixed Project Id
* is used internally for that, but it isn't what this test verifies.
*
* Confirmed via direct testing that addCredential() accepts credentialJsonFilepath alongside
* GCP's projectId, and that it's stored in PLAIN TEXT in neo-cloudcredential.xml (not encrypted)
* — it's just a filesystem path pointing at the actual service-account JSON key file, which this
* admin page never reads itself, so there's no secret content stored here to encrypt — see
* cloudCredentialConfigUtil.cfc.
*
* Multi-node via active push, not organic CCS replication: confirmed via direct testing (for the
* Cloud Credentials area generally) that a newly-added credential never appears anywhere in the
* prime node's own CCS version history — real CCS does not track this file at all in this
* environment. serverSettingsApiUtil.requiresPeerInstancePropagation() flags the
* "cloudCredentials" area (for every setting name within it, including this one) so testDriver.cfc
* actively re-applies the same addCredential()/deleteCredential() call on each peer node directly,
* instead of passively waiting on CCS.
--->
<h2>Add/Edit Cloud Credentials - Credential JSON Filepath (create, verify sync, remove)</h2>
<p>File: gcpCredentialJsonFilepath.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestGcpCredentialJsonFilepath";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Credentials-gcpCredentialJsonFilepath">
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
