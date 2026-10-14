<!---
* @file  webServiceProxyPort.cfm
* @description Add/Edit ColdFusion Web Service — Proxy Port (create, verify sync across nodes,
* then remove), using a fixed test service name "CCSTestWebServiceProxyPort".
*
* Same mechanism as webServiceProxyServer.cfm etc.: index 5 of neo-xmlrpc.xml's array is the
* "proxyports" struct {webServiceName: proxyPort} (confirmed via direct testing). Unlike Proxy
* Server, a port set with no proxy server given isn't exercised as an actual proxy connection
* during setWebService()'s WSDL fetch, so any real port number is safe here — no risk of an
* UnknownHostException-style abort. A fixed default WSDL is used internally to satisfy
* setWebService()'s requirement for a URL — the URL isn't what this test verifies.
* getWebServices()/getMappings() never reflect live writes, so verification reads
* neo-xmlrpc.xml directly instead (webServicesConfigUtil.cfc).
*
* This data is not part of what real CCS organically replicates (confirmed via direct polling for
* the Name/URL fields, same underlying mechanism here), so
* serverSettingsApiUtil.requiresPeerInstancePropagation() flags the "webservices" area to use this
* suite's active-push mechanism (the same one used for AI Services/extensions/security) instead of
* passively waiting on CCS.
*
* Single-pass create, not the silent-setup-then-update pattern used by Authentication Type/
* Timeout: those fields have a real non-empty default (NONE / 0) worth updating away from, but
* Proxy Port's real default is genuinely blank — there's nothing to fake an "existing" value from
* without misrepresenting what an admin would actually see, so this test matches
* webServiceRegistration.cfm's plain empty -> registered pattern instead.
--->
<h2>Add/Edit ColdFusion Web Service - Proxy Port (create, verify sync, remove)</h2>
<p>File: webServiceProxyPort.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestWebServiceProxyPort";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Web_Services-webServiceProxyPort">
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
