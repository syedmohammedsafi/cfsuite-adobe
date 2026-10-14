<!---
* @file  mcpServerConfig.cfm
* @description MCP Server Configuration — multi-node CCS sync test
--->
<h2>MCP Server Configuration (full)</h2>
<p>File: mcpServerConfig.cfm</p>
<br>
<cftry>
	<cfscript>
		testDvr = new cfsuite.ccssuite.testDriver();
		aiUtil = new cfsuite.ccssuite.utils.aiServicesTestUtil().init();
		syncTestResult = aiUtil.runFullMcpServerSyncTest(testDvr, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-AI_Services-MCP_Servers-fullConfig">
		<cfscript>
			writeOutput(aiUtil.getQatestResultMessage(syncTestResult.passed));
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
			aiUtil.restoreMcpServerSyncTest(testDvr, syncTestResult);
		</cfscript>
	</cffinally>
</cftry>
