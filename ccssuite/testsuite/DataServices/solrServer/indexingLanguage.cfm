<!---
* @file  indexingLanguage.cfm
* @description Configure Indexing Languages - New language / New language suffix / Add
* (languages array, keyed by suffix "cxt", a suffix guaranteed not to collide with any of
* the real stemmer languages) — multi-node CCS sync test. Adds a test language entry,
* verifies the update and status across CCS nodes (confirmed this field IS part of real CCS
* cluster replication, unlike solrhome), then removes it. CCS replication timing can vary
* run to run (same as mail settings elsewhere in this suite), so cleanup retries a few times
* to make sure the entry is genuinely gone rather than trusting a single delete attempt.
--->
<h2>Solr Server - Indexing Language (add, verify, remove)</h2>
<p>File: indexingLanguage.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "cxt";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Solr_Server-indexingLanguage">
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
			// Safety net: CCS replication timing can leave this array entry behind even after
			// a reported-successful restore, so verify directly and retry until it's really gone.
			solrUtil = new cfsuite.ccssuite.utils.solrServerConfigUtil().init();
			for(cleanupAttempt = 1; cleanupAttempt LTE 5; cleanupAttempt++){
				if(NOT len(trim(solrUtil.getLanguageSetting(SETTING_NAME))))
					break;
				solrUtil.setLanguageSetting(SETTING_NAME, "");
				sleep(200);
			}
		</cfscript>
	</cffinally>
</cftry>
