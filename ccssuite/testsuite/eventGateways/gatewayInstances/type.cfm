<!---
* @file  type.cfm
* @description Gateway Instance Type — multi-node CCS sync test
--->
<h2>Gateway Type (Gateway Instance)</h2>
<p>File: gatewayInstances/type.cfm</p>
<br>
<cftry>
	<cfscript>
		final FIELD_NAME = "type";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		egUtil = new cfsuite.ccssuite.utils.eventGatewaysTestUtil().init();
		syncTestResult = egUtil.runGatewayInstanceFieldSyncTest(testDvr, FIELD_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Event_Gateways-Gateway_Instances-#FIELD_NAME#">
		<cfscript>
			writeOutput(egUtil.getQatestResultMessage(syncTestResult.passed));
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
			egUtil.restoreEventGatewaysSyncTest(testDvr, syncTestResult);
		</cfscript>
	</cffinally>
</cftry>
