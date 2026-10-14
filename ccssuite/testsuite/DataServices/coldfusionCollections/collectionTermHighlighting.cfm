<!---
* @file  collectionTermHighlighting.cfm
* @description ColdFusion Collections Configuration — creates a Solr collection (existing
* value starts empty, matching the AI Services LLM/Vector Store full-config tests), verifies
* the created collection's config across CCS nodes, then deletes it. Same-cluster/environment
* peers are checked normally (in this environment all instances share one physical Solr server,
* so a same-cluster peer genuinely does show the new collection); a different-cluster/environment
* node is never reported as updated regardless — see coldfusionCollectionsConfigUtil.cfc.
--->
<h2>ColdFusion Collections Configuration (full)</h2>
<p>File: collectionTermHighlighting.cfm</p>
<br>
<cftry>
	<cfscript>
		testDvr = new cfsuite.ccssuite.testDriver();
		dsUtil = new cfsuite.ccssuite.utils.dataServicesTestUtil().init();
		syncTestResult = dsUtil.runFullCollectionSyncTest(testDvr, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-ColdFusion_Collections-fullConfig">
		<cfscript>
			writeOutput(dsUtil.getQatestResultMessage(syncTestResult.passed));
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
			dsUtil.restoreCollectionSyncTest(testDvr, syncTestResult);
		</cfscript>
	</cffinally>
</cftry>
