<!---
* @file  customTagPath.cfm
* @description Custom Tag Path — multi-node CCS sync test
--->
<h2>Custom Tag Path</h2>
<p>File: customTagPaths/customTagPath.cfm</p>
<br>
<cftry>
	<cfscript>
		testDvr = new cfsuite.ccssuite.testDriver();
		extUtil = new cfsuite.ccssuite.utils.extensionsTestUtil().init();
		syncTestResult = extUtil.runCustomTagPathSyncTest(testDvr, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Extensions-Custom_Tag_Paths-customTagPath">
		<cfscript>
			writeOutput(extUtil.getQatestResultMessage(syncTestResult.passed));
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
			extUtil.restoreExtensionsSyncTest(testDvr, syncTestResult);
		</cfscript>
	</cffinally>
</cftry>
