<!---
* @file  jdkPath.cfm
* @description Java and JVM - Java Home (jdkPath) — multi-node CCS sync test
--->
<h2>Java and JVM - Java Home</h2>
<p>File: jdkPath.cfm</p>
<br>
<cftry>
	<cfscript>
		SETTING_NAME = "jdkPath";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Server_Settings-Java_and_JVM-#SETTING_NAME#">
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
			stUtil.cleanupJdkTestPath();
		</cfscript>
	</cffinally>
</cftry>
