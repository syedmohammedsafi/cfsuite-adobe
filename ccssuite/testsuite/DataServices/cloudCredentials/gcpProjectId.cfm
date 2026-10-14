<!---
* @file  gcpProjectId.cfm
* @description Add/Edit Cloud Credentials - Project Id (GCP) — create, verify sync across nodes,
* then remove, using a fixed, dedicated test alias "CCSTestGcpProjectId" (kept separate from every
* AWS/Azure Cloud Credentials field test so none of them interfere with each other). The tracked
* value here is the projectId string itself for that alias.
*
* GCP's Cloud Vendor has its own field set too — confirmed via direct testing that
* addCredential() accepts just alias/vendorName="GCP"/projectId and persists correctly (no
* region/accessKeyId/secretAccessKey/sessionToken/connectionString needed for this vendor).
* Unlike AWS's Access Key/Secret Key and Azure's Connection String, projectId is stored in PLAIN
* TEXT in neo-cloudcredential.xml (confirmed directly) — it's an identifier, not a secret — so
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
<h2>Add/Edit Cloud Credentials - Project Id (create, verify sync, remove)</h2>
<p>File: gcpProjectId.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestGcpProjectId";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Credentials-gcpProjectId">
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
