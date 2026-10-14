<!---
* @file  webServiceTimeout.cfm
* @description Add/Edit ColdFusion Web Service — Timeout (update an existing registration's
* timeout, verify sync across nodes, then remove), using a fixed test service name
* "CCSTestWebServiceTimeout", cycling 0 -> 30 -> 0.
*
* Same mechanism as webServiceRegistration.cfm/webServiceWsdlUrl.cfm/webServiceAuthType.cfm:
* index 8 of neo-xmlrpc.xml's array is the "timeouts" struct {webServiceName: timeout} (confirmed
* via direct testing; stored as a number, e.g. 30.0). CFIDE.adminapi.extensions.setWebService()/
* deleteWebservice() reliably create/update/delete entries there when targeting a real, reachable
* static .wsdl file (a fixed default is used internally to satisfy the URL requirement — the URL
* isn't what this test verifies). getWebServices()/getMappings() never reflect live writes, so
* verification reads neo-xmlrpc.xml directly instead (webServicesConfigUtil.cfc).
*
* This data is not part of what real CCS organically replicates (confirmed via direct polling for
* the Name/URL fields, same underlying mechanism here), so
* serverSettingsApiUtil.requiresPeerInstancePropagation() flags the "webservices" area to use this
* suite's active-push mechanism (the same one used for AI Services/extensions/security) instead of
* passively waiting on CCS.
*
* The setup pass (registering the service with "0", the real field's own default when left blank)
* is silent — its output is captured and discarded — so the visible/measured test shows the real
* 0 -> 30 transition an admin would actually see, matching webServiceAuthType.cfm's pattern.
--->
<h2>Add/Edit ColdFusion Web Service - Timeout (update, verify sync, remove)</h2>
<p>File: webServiceTimeout.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestWebServiceTimeout";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		setupResult = {};
	</cfscript>

	<cfsavecontent variable="setupOutput">
		<cfscript>
			setupResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
		</cfscript>
	</cfsavecontent>

	<cfscript>
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Web_Services-webServiceTimeout">
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
			// restore using setupResult (which captured the true original/empty preset), so the
			// final rollback deletes the registration on every node rather than leaving it at
			// the intermediate "created" value.
			stUtil.restoreMultiNodeSyncTest(testDvr, setupResult, SETTING_NAME);
		</cfscript>
	</cffinally>
</cftry>
