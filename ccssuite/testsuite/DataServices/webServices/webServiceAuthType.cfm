<!---
* @file  webServiceAuthType.cfm
* @description Add/Edit ColdFusion Web Service — Authentication Type (update an existing
* registration's auth type, verify sync across nodes, then remove), using a fixed test service
* name "CCSTestWebServiceAuthType", cycling none -> basic -> ntlm -> none.
*
* Same mechanism as webServiceRegistration.cfm/webServiceWsdlUrl.cfm: index 10 of
* neo-xmlrpc.xml's array is the "authtypes" struct {webServiceName: authtype} (confirmed via
* direct testing). CFIDE.adminapi.extensions.setWebService()/deleteWebservice() reliably create/
* update/delete entries there when targeting a real, reachable static .wsdl file (a fixed default
* is used internally to satisfy the URL requirement — the URL isn't what this test verifies).
* getWebServices()/getMappings() never reflect live writes, so verification reads
* neo-xmlrpc.xml directly instead (webServicesConfigUtil.cfc).
*
* This data is not part of what real CCS organically replicates (confirmed via direct polling for
* the Name/URL fields, same underlying mechanism here), so
* serverSettingsApiUtil.requiresPeerInstancePropagation() flags the "webservices" area to use this
* suite's active-push mechanism (the same one used for AI Services/extensions/security) instead of
* passively waiting on CCS.
*
* The setup pass (registering the service with "none", the real admin UI's own default
* selection) is silent — its output is captured and discarded — so the visible/measured test
* shows the real none -> basic transition an admin would actually see, matching
* webServiceWsdlUrl.cfm's silent-setup pattern.
--->
<h2>Add/Edit ColdFusion Web Service - Authentication Type (update, verify sync, remove)</h2>
<p>File: webServiceAuthType.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestWebServiceAuthType";
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

	<cf_qatest id="test-Data_Services-Web_Services-webServiceAuthType">
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
