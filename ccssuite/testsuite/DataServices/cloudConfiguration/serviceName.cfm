<!---
* @file  serviceName.cfm
* @description Add/Edit Cloud Service Configuration - Service Name — create, verify sync across
* nodes, then remove, using a fixed test alias "CCSTestCloudConfigServiceName" (kept separate from
* "CCSTestCloudConfigAlias" used by the Config Alias test so the two tests never interfere with
* each other). Cycles between two of AWS's real Service Name dropdown options ("S3"/"SQS") rather
* than toggling presence/absence, since serviceName is a required field with no blank state — see
* cloudConfigConfigUtil.cfc.
*
* Multi-node via ORGANIC CCS replication, same as Config Alias: neo-cloud-config.xml is confirmed
* to be tracked by real CCS (unlike Cloud Credentials' neo-cloudcredential.xml), so this test uses
* the default "all" nodesScope with no requiresPeerInstancePropagation() entry needed.
--->
<h2>Add/Edit Cloud Service Configuration - Service Name (create, verify sync, remove)</h2>
<p>File: serviceName.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestCloudConfigServiceName";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Cloud_Configuration-serviceName">
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
