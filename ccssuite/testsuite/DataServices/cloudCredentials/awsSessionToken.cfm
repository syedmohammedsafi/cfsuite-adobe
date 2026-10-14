<!---
* @file  awsSessionToken.cfm
* @description Add/Edit Cloud Credentials - AWS Session Token — create, verify sync across nodes,
* then remove, using a fixed, dedicated test alias "CCSTestCloudSessionToken" (kept separate from
* the other Cloud Credentials field tests so none of them interfere with each other). The tracked
* value here is the sessionToken string itself for that alias, not the Cloud Vendor/AWS Region/
* Access Key/Secret Key fields — addCredential() still needs a full credential body to register
* with, so fixed fake AWS values are used internally for that, but those field values aren't what
* this test verifies.
*
* Unlike AWS Access Key/Secret Key, Session Token is optional and, confirmed via direct testing,
* is stored in PLAIN TEXT in neo-cloudcredential.xml (not auto-encrypted) — so this uses a plain
* exact-match comparison, same as Cloud Vendor/AWS Region — see cloudCredentialConfigUtil.cfc.
*
* Multi-node via active push, not organic CCS replication: confirmed via direct testing that a
* newly-added credential never appears anywhere in the prime node's own CCS version history —
* real CCS does not track this file at all in this environment. serverSettingsApiUtil.
* requiresPeerInstancePropagation() flags the "cloudCredentials" area (for every setting name
* within it, including this one) so testDriver.cfc actively re-applies the same
* addCredential()/deleteCredential() call on each peer node directly, instead of passively
* waiting on CCS.
--->
<h2>Add/Edit Cloud Credentials - AWS Session Token (create, verify sync, remove)</h2>
<p>File: awsSessionToken.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudSessionToken";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Credentials-awsSessionToken">
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
