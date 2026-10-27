<!---
* @file  webServiceDomain.cfm
* @description Add/Edit ColdFusion Web Service — Domain (create, verify sync across
* nodes, then remove), using a fixed test service name "CCSTestWebServiceDomain".
*
* Same mechanism as webServiceProxyUsername.cfm etc.: index 11 of neo-xmlrpc.xml's array is the
* "ntlmdomains" struct {webServiceName: ntlmdomain} (confirmed via direct testing). Stored in plain text.
* A fixed default WSDL is used internally to satisfy setWebService()'s requirement for a URL — the
* URL isn't what this test verifies.
* getWebServices()/getMappings() never reflect live writes, so verification reads
* neo-xmlrpc.xml directly instead (webServicesConfigUtil.cfc).
*
* This data is not part of what real CCS organically replicates (confirmed via direct polling for
* the Name/URL fields, same underlying mechanism here), so
* serverSettingsApiUtil.requiresPeerInstancePropagation() flags the "webservices" area to use this
* suite's active-push mechanism (the same one used for AI Services/extensions/security) instead of
* passively waiting on CCS.
*
* Single-pass create, matching webServiceRegistration.cfm's plain empty -> registered pattern.
--->
<h2>Add/Edit ColdFusion Web Service - Domain (create, verify sync, remove)</h2>
<p>File: webServiceDomain.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestWebServiceDomain";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Web_Services-webServiceDomain">
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
