<!---
* @file  azureBlob_maximumExecutionTimeInMs.cfm
* @description Add Cloud Configuration (Azure Blob - Maximum Execution time (ms)) - cycles setting for dedicated test alias (CCSTestCloudConfigBlobMaximumExecutionTimeInMs).
--->
<h2>Add Cloud Configuration - Azure Blob - Maximum Execution time (ms) (create, verify sync, remove)</h2>
<p>File: azureBlob_maximumExecutionTimeInMs.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigBlobMaximumExecutionTimeInMs";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-azureBlob_maximumExecutionTimeInMs">
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
