<!---
* @file  ragVectorStoreVisibility.cfm
* @description RAG has no settings of its own — it consumes the Vector Store config
* through coldfusion.server.VectorStoreService. This test writes a full Vector Store
* config and, on every CCS node, reads it back through that live service (not the raw
* neo-vectorstore.xml file) to confirm the RAG ingestion page will actually see it.
--->
<h2>RAG - Vector Store Visibility (full config, multi-node CCS sync)</h2>
<p>File: ragVectorStoreVisibility.cfm</p>
<br>
<cftry>
	<cfscript>
		final TEST_ALIAS = new cfsuite.ccssuite.utils.aiServicesTestUtil().init().getVectorStoreTestAlias();
		testDvr = new cfsuite.ccssuite.testDriver();
		aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		syncTestResult = aiUtil.runFullVectorStoreSyncTest(testDvr, TEST_ALIAS, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-AI_Services-RAG-vectorStoreVisibility">
		<cfscript>
			writeOutput(aiUtil.getQatestResultMessage(syncTestResult.passed));
		</cfscript>
		<cf_expectedresults>
			Vector Store config is visible via the live VectorStoreService on every CCS node<br>
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
			aiUtil.restoreVectorStoreSyncTest(testDvr, syncTestResult, TEST_ALIAS);
		</cfscript>
	</cffinally>
</cftry>
