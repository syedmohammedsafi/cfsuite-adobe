<!---
* @file  chunkedEncodingEnabled.cfm
* @description Add AWS Configuration (S3) - S3 specific - Chunked Encoding Enabled — cycles
* s3Configuration.chunkedEncodingEnabled (true/false, real boolean) for a fixed, dedicated test
* alias ("CCSTestCloudConfigChunkedEncoding" — kept separate from the other Cloud Configuration
* test fixtures). Mirrors checksumValidationEnabled.cfm exactly. Last of the S3 specific section
* (Path Style Access / Accelerate Mode / Dual Stack / Checksum Validation / Chunked Encoding).
*
* Multi-node via organic CCS replication, same as the other Cloud Configuration tests — no
* requiresPeerInstancePropagation() entry needed.
--->
<h2>Add AWS Configuration (S3) - Chunked Encoding Enabled (create, verify sync, remove)</h2>
<p>File: chunkedEncodingEnabled.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigChunkedEncoding";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-chunkedEncodingEnabled">
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
