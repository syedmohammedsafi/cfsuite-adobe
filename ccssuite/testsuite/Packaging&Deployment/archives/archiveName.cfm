<!---
* @file  archiveName.cfm
* @description Archive Name / Archive Definition List (archiveName) - Packaging & Deployment (Sync: NO)
--->
<h2>Archive Name (ColdFusion Archives)</h2>
<p>File: packaging/archives/archiveName.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "ArchiveName";
		syncTestResult = {};
		testDvr = new cfsuite.ccssuite.testDriver();
		pkgTestUtil = new cfsuite.ccssuite.utils.packagingTestUtil().init();
		syncTestResult = pkgTestUtil.runPackagingSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Packaging-Archives-#SETTING_NAME#">
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
