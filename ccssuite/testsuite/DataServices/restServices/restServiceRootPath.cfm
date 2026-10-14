<!---
* @file  restServiceRootPath.cfm
* @description Add/Edit REST Service — Root Path (create, verify, then remove), using a fixed
* test mapping name "CCSTestRestService" registered against a dedicated test folder (this same
* directory, via ping.cfc — a minimal component rest="true" CFC).
*
* CFIDE.adminapi.extensions.registerRESTService()/deleteRESTService() reliably create/delete
* entries in neo-jaxrs.xml. Verification reads neo-jaxrs.xml directly rather than the live
* getRESTServices() API — that call does reflect writes immediately, but repeatedly logging in/out
* of the admin API on every poll was too slow for this suite's retry-verification loop.
*
* Registration actually initializes the target as a REST application (deploys it), so the target
* folder must exist and contain a real, valid `component rest="true"` CFC — an empty folder or
* nonexistent path throws and aborts registration, analogous to Web Services needing a real,
* reachable WSDL. ping.cfc alongside this file satisfies that requirement.
*
* CRITICAL: this suite's own REST mapping ("ccs", rooted at .../ccssuite/restCFCs) is live
* infrastructure registered at application startup and used internally by this whole test suite
* — restServicesConfigUtil.cfc only ever targets the dedicated test path above, never touching
* that mapping.
*
* No active push (requiresPeerInstancePropagation returns false for "restservices") — a single
* register on the prime node only, verified with this suite's mail-style tolerant comparison
* (testDriver.syncedFramesMatch): a peer node passes whether it picked up the change via CCS's
* own background replication or stayed at its prior value, since that replication's timing isn't
* something this test controls.
--->
<h2>Add/Edit REST Service - Root Path (create, verify, remove)</h2>
<p>File: restServiceRootPath.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestRestService";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-REST_Services-restServiceRootPath">
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
