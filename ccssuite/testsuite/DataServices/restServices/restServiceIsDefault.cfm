<!---
* @file  restServiceIsDefault.cfm
* @description Add/Edit REST Service — Set as default application (create, verify, then remove),
* reusing Root Path's dedicated test folder, varying only isDefault. Before setting true, the
* setter refuses if any OTHER path is already the default for this host, rather than silently
* stealing it. Never touches the live "ccs" mapping — see restServices/i.cfm for the documented
* history of real corruption incidents in this area; this follows the same single-node,
* no-active-push, mail-style tolerant verification already used by restServiceRootPath.cfm.
--->
<h2>Add/Edit REST Service - Set as default application (create, verify, remove)</h2>
<p>File: restServiceIsDefault.cfm</p>
<br>
<cftry>
	<cfscript>
		final SETTING_NAME = "CCSTestRestServiceIsDefault";
		testDvr = new cfsuite.ccssuite.testDriver();
		stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		syncTestResult = {};
		syncTestResult = stUtil.runMultiNodeBooleanSyncTest(testDvr, SETTING_NAME, CGI.SCRIPT_NAME);
	</cfscript>

	<cf_qatest id="test-Data_Services-REST_Services-restServiceIsDefault">
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
