<!---
* @file  azureConnectionString.cfm
* @description Add/Edit Cloud Credentials - Azure Connection String — create, verify sync across
* nodes, then remove, using a fixed, dedicated test alias "CCSTestAzureConnectionString" (kept
* separate from every AWS-vendor Cloud Credentials field test so none of them interfere with each
* other). The tracked value here is the connectionString string itself for that alias.
*
* Azure's Cloud Vendor has a completely different field set than AWS's — confirmed via direct
* testing that addCredential() accepts alias/vendorName="Azure"/connectionString and persists
* correctly (no region/accessKeyId/secretAccessKey/sessionToken needed for this vendor).
* connectionString is auto-encrypted on disk (confirmed directly, same as AWS's Access Key/Secret
* Key) but CFIDE.adminapi.cloud.getCredential() decrypts it back to the real plaintext on read, so
* this uses a plain exact-match comparison — see cloudCredentialConfigUtil.cfc.
*
* Multi-node via active push, not organic CCS replication: confirmed via direct testing (for the
* Cloud Credentials area generally) that a newly-added credential never appears anywhere in the
* prime node's own CCS version history — real CCS does not track this file at all in this
* environment. serverSettingsApiUtil.requiresPeerInstancePropagation() flags the
* "cloudCredentials" area (for every setting name within it, including this one) so testDriver.cfc
* actively re-applies the same addCredential()/deleteCredential() call on each peer node directly,
* instead of passively waiting on CCS.
--->
<h2>Add/Edit Cloud Credentials - Azure Connection String (create, verify sync, remove)</h2>
<p>File: azureConnectionString.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestAzureConnectionString";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Credentials-azureConnectionString">
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
