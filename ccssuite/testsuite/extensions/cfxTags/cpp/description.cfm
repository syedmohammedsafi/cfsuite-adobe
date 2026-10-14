<!---
* @file  description.cfm
* @description C++ CFX Description (description) — multi-node CCS sync test
--->
<h2>Description (C++ CFX)</h2>
<p>File: cfxTags/cpp/description.cfm</p>
<br>
<cftry>
	<cfscript>
		final FIELD_NAME = "description";
		testDvr = new cfsuite.ccssuite.testDriver();
		extUtil = new cfsuite.ccssuite.utils.extensionsTestUtil().init();
		syncTestResult = extUtil.runCppCfxFieldSyncTest(testDvr, FIELD_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Extensions-CFX_Tags-Cpp-#FIELD_NAME#">
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
