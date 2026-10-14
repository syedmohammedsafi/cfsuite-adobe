<!---
* @file  webServiceWsdlUrl.cfm
* @description Add/Edit ColdFusion Web Service — WSDL URL (create, verify sync across nodes,
* then remove), using the same fixed test service name "CCSTestWebService" as
* webServiceRegistration.cfm.
*
* Same mechanism as webServiceRegistration.cfm: CFIDE.adminapi.extensions.setWebService()/
* deleteWebservice() reliably create/update/delete entries in neo-xmlrpc.xml's "mappings" map
* when targeting a real, reachable static .wsdl file. getWebServices()/getMappings() never
* reflect live writes, so verification reads neo-xmlrpc.xml directly (webServicesConfigUtil.cfc).
* This data is not part of what real CCS organically replicates (confirmed via direct polling),
* so serverSettingsApiUtil.requiresPeerInstancePropagation() flags the "webservices" area to use
* this suite's active-push mechanism (the same one used for AI Services/extensions/security)
* instead of passively waiting on CCS.
*
* Single-pass create, not the silent-setup-then-update pattern used by Authentication Type/
* Timeout: those fields have a real non-empty default (NONE / 0) worth updating away from, but
* a WSDL URL only exists once a service is registered — there's no meaningful "existing" URL to
* fake without misrepresenting what an admin would actually see before adding one, so this test
* matches webServiceRegistration.cfm's plain empty -> registered pattern instead.
--->
<h2>Add/Edit ColdFusion Web Service - WSDL URL (create, verify sync, remove)</h2>
<p>File: webServiceWsdlUrl.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestWebService";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Web_Services-webServiceWsdlUrl">
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
