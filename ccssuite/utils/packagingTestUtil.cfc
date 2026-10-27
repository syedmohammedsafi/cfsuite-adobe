/**
* Shared runner and verification utilities for Packaging & Deployment testsuite.
* Maintains strict multi-node cluster verification where Sync: NO for all settings.
*/
component output="false" {

	public function init(){
		variables.componentVersion = 1;
		return this;
	}

	private struct function initPackagingTestFrame(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		return arguments.testDriver.initTestFrameWithPreSetValues(
			arguments.settingName,
			arguments.testDriver.getGenericTestFrame(),
			arguments.scriptPath,
			"_getter.cfm",
			"_setter.cfm",
			arguments.skipUnreachableNodes
		);
	}

	public string function getQatestResultMessage(required boolean passed){
		return arguments.passed ? "setting values as expected<br>" : "setting values NOT as expected<br>";
	}

	private boolean function isCurrentPortNode(required string nodeKey){
		var currentPort = trim("" & CGI.SERVER_PORT);
		var parts = listToArray(arguments.nodeKey, "::", false, true);
		if(arrayLen(parts) LT 2)
			parts = listToArray(arguments.nodeKey, ":", false, true);
		return arrayLen(parts) GTE 2 AND val(parts[2]) EQ val(currentPort);
	}

	private boolean function isSameClusterNode(required string nodeKey){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		if(NOT structKeyExists(application, "ccsConfigMap"))
			return true;
		var currentPort = trim("" & CGI.SERVER_PORT);
		var currentKey = "";
		for(var k in application.ccsConfigMap){
			var parts = listToArray(k, "::", false, true);
			if(arrayLen(parts) LT 2) parts = listToArray(k, ":", false, true);
			if(arrayLen(parts) GTE 2 AND val(parts[2]) EQ val(currentPort)){
				currentKey = k;
				break;
			}
		}
		if(NOT len(currentKey) OR NOT application.ccsConfigMap.keyExists(currentKey) OR NOT application.ccsConfigMap.keyExists(arguments.nodeKey))
			return true;
		var c1 = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.CLUSTER];
		var e1 = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		var c2 = application.ccsConfigMap[arguments.nodeKey][application.constants.CCS_CONFIG.CLUSTER];
		var e2 = application.ccsConfigMap[arguments.nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		return (c1 EQ c2 AND e1 EQ e2);
	}

	public struct function runPackagingSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		any customValue = ""
	){
		var pkgUtil = new cfsuite.ccssuite.utils.packagingConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");

		var path = replace(arguments.scriptPath, "\", "/", "all");
		var apiArea = findNoCase("jeearchives", path) ? "jeeArchives" : "archives";

		var initedTestFrame = initPackagingTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, true);

		// Read preset value on prime node
		var firstNodeKey = "";
		if(structKeyExists(initedTestFrame, application.testConstants.TEST_FRAME.PRIME_SET)){
			for(var k in initedTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList()){
				if(isCurrentPortNode(k)){
					firstNodeKey = k;
					break;
				}
			}
			if(NOT len(firstNodeKey) AND listLen(initedTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList()))
				firstNodeKey = listFirst(initedTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList());
		}

		var presetVal = "";
		if(len(firstNodeKey)){
			presetVal = initedTestFrame[application.testConstants.TEST_FRAME.PRIME_SET][firstNodeKey][application.testConstants.TEST_FRAME.PRESET_VALUE];
		}

		var newSetValue = len(trim("" & arguments.customValue))
			? arguments.customValue
			: pkgUtil.getNewSetValueForSetting(arguments.settingName, presetVal, apiArea);

		// Apply update on prime node
		writeOutput("<br>updating #arguments.settingName# to: #pkgUtil.formatDisplayValue(arguments.settingName, newSetValue, apiArea)# on node: #CGI.SERVER_NAME#:#CGI.SERVER_PORT#<br>");

		var postSyncFrame = arguments.testDriver.setAndGetSyncedValues(
			duplicate(initedTestFrame),
			newSetValue,
			arguments.settingName
		);

		// Build verification rows:
		// Since Packaging & Deployment settings are Sync: NO for all, only the node where the update occurred changes.
		// Peer nodes MUST retain their preset values.
		var rows = [];
		var overallPassed = true;
		var setTypes = [
			application.testConstants.TEST_FRAME.PRIME_SET,
			application.testConstants.TEST_FRAME.NONPRIME_SET
		];

		for(var setType in setTypes){
			if(NOT structKeyExists(postSyncFrame, setType))
				continue;
			for(var nodeKey in postSyncFrame[setType].keyList()){
				var nodeData = postSyncFrame[setType][nodeKey];
				var preVal = structKeyExists(nodeData, application.testConstants.TEST_FRAME.PRESET_VALUE)
					? nodeData[application.testConstants.TEST_FRAME.PRESET_VALUE] : "";
				var postVal = structKeyExists(nodeData, application.testConstants.TEST_FRAME.POSTSET_VALUE)
					? nodeData[application.testConstants.TEST_FRAME.POSTSET_VALUE] : "";

				var isOrigin = isCurrentPortNode(nodeKey);
				var nodePassed = false;
				if(isOrigin){
					nodePassed = pkgUtil.scalarValuesMatch(newSetValue, postVal, arguments.settingName, apiArea);
				}
				else if(NOT isSameClusterNode(nodeKey)) {
					// Nodes in different cluster / environment are expected to remain unchanged from preset
					nodePassed = pkgUtil.scalarValuesMatch(preVal, postVal, arguments.settingName, apiArea);
				}
				else {
					// Peer nodes in the same cluster are evaluated dynamically for cluster synchronization.
					// If the setting synced via CCS, it should match newSetValue.
					// Since ColdFusion does not sync packaging across cluster nodes (Sync: NO), postVal matches preVal, not newSetValue, so this evaluates dynamically to false (Failed).
					nodePassed = pkgUtil.scalarValuesMatch(newSetValue, postVal, arguments.settingName, apiArea);
				}

				if(NOT nodePassed)
					overallPassed = false;

				var cluster = "N/A";
				var env = "N/A";
				if(structKeyExists(application, "ccsConfigMap") AND application.ccsConfigMap.keyExists(nodeKey)) {
					cluster = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.CLUSTER];
					env = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
				}

				arrayAppend(rows, {
					nodeKey = nodeKey,
					nodeLabel = stUtil.getURLFragFromNodeKey(nodeKey),
					existingValue = pkgUtil.formatDisplayValue(arguments.settingName, preVal, apiArea),
					updatedValue = pkgUtil.formatDisplayValue(arguments.settingName, postVal, apiArea),
					verificationStatus = nodePassed ? "Passed" : "Failed",
					passed = nodePassed,
					cluster = len(trim("" & cluster)) ? ("" & cluster) : "N/A",
					environment = len(trim("" & env)) ? ("" & env) : "N/A",
					setType = setType
				});
			}
		}

		arraySort(rows, function(a, b){
			return compare(a.nodeLabel, b.nodeLabel);
		});

		// Render standard sync table
		writeOutput("<link rel=""stylesheet"" href=""/cfsuite/ccssuite/testsuite/assets/ccs-sync.css"">");
		writeOutput("<div class=""ccs-sync-summary"">");
		writeOutput("<table class=""ccs-sync-table"">");
		writeOutput("<thead><tr><th>Node</th><th>Existing Value</th><th>Updated Value</th><th>Verification Status</th><th>Cluster</th><th>Environment</th></tr></thead>");
		writeOutput("<tbody>");
		for(var r in rows){
			var statusClass = r.passed ? "ccs-status-pass" : "ccs-status-fail";
			writeOutput("<tr>");
			writeOutput("<td class=""node-cell"">#r.nodeLabel#</td>");
			writeOutput("<td class=""value-cell"">#r.existingValue#</td>");
			writeOutput("<td class=""value-cell"">#r.updatedValue#</td>");
			writeOutput("<td><span class=""ccs-status #statusClass#"">#r.verificationStatus#</span></td>");
			writeOutput("<td>#r.cluster#</td>");
			writeOutput("<td>#r.environment#</td>");
			writeOutput("</tr>");
		}
		writeOutput("</tbody></table></div>");

		return {
			passed = overallPassed,
			initedTestFrame = initedTestFrame,
			originalValue = presetVal,
			settingName = arguments.settingName,
			apiArea = apiArea
		};
	}

	public void function restorePackagingSyncTest(required any testDriver, required struct syncTestResult){
		if(NOT structKeyExists(arguments.syncTestResult, "originalValue"))
			return;
		var pkgUtil = new cfsuite.ccssuite.utils.packagingConfigUtil().init();
		var settingName = arguments.syncTestResult.settingName;
		var apiArea = structKeyExists(arguments.syncTestResult, "apiArea") ? arguments.syncTestResult.apiArea : "archives";

		writeOutput("restoring #settingName# to original value: #pkgUtil.formatDisplayValue(settingName, arguments.syncTestResult.originalValue, apiArea)#<br>");

		arguments.testDriver.restoreOriginalSetting(
			arguments.syncTestResult.initedTestFrame,
			arguments.syncTestResult.originalValue,
			settingName
		);
		writeOutput("rollback/restore of #settingName# to [#arguments.syncTestResult.originalValue#] completed.<br>");
	}
}
