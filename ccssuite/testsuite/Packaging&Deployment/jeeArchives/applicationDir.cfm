<!---
* @file  applicationDir.cfm
* @description Application Directory (application_dir) - Packaging & Deployment (Sync: NO)
--->
<h2>Application Directory (JEE Archives)</h2>
<p>File: packaging/jeeArchives/applicationDir.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "ApplicationDir";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		pkgTestUtil = new cfsuite.ccssuite.utils.packagingTestUtil().init();
		syncTestResult = pkgTestUtil.runPackagingSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Packaging-JeeArchives-#SETTING_NAME#">
		<cfscript>
			writeOutput(pkgTestUtil.getQatestResultMessage(syncTestResult.passed));
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
			pkgTestUtil.restorePackagingSyncTest(testDvr, syncTestResult);
		</cfscript>
	</cffinally>
</cftry>
