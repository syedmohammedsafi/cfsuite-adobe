<!---
* @file  webServiceRegistration.cfm
* @description Add/Edit ColdFusion Web Service - Web Service Name — create, verify sync across
* nodes, then remove, using a fixed test service name "CCSTestWebServiceName". The tracked value
* here is the NAME itself (registered/not registered), not the WSDL URL — setWebService() still
* needs a URL to register with, so a fixed default .wsdl file is used internally for that, but the
* URL isn't what this test is verifying. See webServiceWsdlUrl.cfm for the WSDL URL field's own
* test, where the tracked value is the URL.
*
* CFIDE.adminapi.extensions.setWebService()/deleteWebservice() reliably create/update/delete
* entries in neo-xmlrpc.xml's "mappings" map (confirmed via direct testing — registering against
* a live CFC hangs via CF's Axis2 deployment step, but a static .wsdl file target works cleanly).
* getWebServices()/getMappings() do NOT reflect live writes even from a fresh request, so
* verification here reads neo-xmlrpc.xml directly instead (webServicesConfigUtil.cfc), the same
* approach solrServerConfigUtil.cfc uses for Solr Server fields with no working live getter.
*
* Multi-node via active push, not organic CCS replication: confirmed via 18s of direct polling
* that a new/changed "mappings" entry is never replicated by real CCS to a same-cluster peer node
* — unlike the Solr Server scalar fields. serverSettingsApiUtil.requiresPeerInstancePropagation()
* flags the "webservices" area so testDriver.cfc actively re-applies the same setWebService() call
* on each peer node directly (the same mechanism this suite already uses for AI Services/
* extensions/security), instead of passively waiting on CCS.
--->
<h2>Add/Edit ColdFusion Web Service - Web Service Name (create, verify sync, remove)</h2>
<p>File: webServiceRegistration.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestWebServiceName";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-Web_Services-webServiceRegistration">
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
