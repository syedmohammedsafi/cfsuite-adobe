<!---
* @file  maxQueueSize.cfm
* @description Maximum number of events to queue — multi-node CCS sync test
--->
<h2>Maximum number of events to queue</h2>
<p>File: settings/maxQueueSize.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "MaxQueueSize";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		egUtil = new cfsuite.ccssuite.utils.eventGatewaysTestUtil().init();
		syncTestResult = egUtil.runSettingsSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Event_Gateways-Settings-#SETTING_NAME#">
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
