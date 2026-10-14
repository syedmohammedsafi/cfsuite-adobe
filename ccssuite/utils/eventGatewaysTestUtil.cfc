/**
* Shared helpers for Event Gateways testsuite CFM pages.
*/
component output="false" {

	public function init(){
		variables.componentVersion = 8;
		return this;
	}

	private struct function initEventGatewaysTestFrame(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		return arguments.testDriver.initTestFrameWithPreSetValues(
			arguments.settingName,
			arguments.testDriver.getGenericTestFrame(),
			arguments.scriptPath,
			"_getterEventGateways.cfm",
			"_setterEventGateways.cfm",
			arguments.skipUnreachableNodes
		);
	}

	private boolean function skipBaselineSeedForField(required string configType, required string fieldName){
		var field = lCase(trim(arguments.fieldName));
		if(arguments.configType EQ "gatewayType" AND field EQ "type")
			return true;
		if(arguments.configType EQ "gatewayInstance" AND listFindNoCase("gatewayid,type,cfcpaths", field))
			return true;
		return false;
	}

	private struct function seedEventGatewaysBaseline(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		required string configType,
		required string fieldName,
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort"
	){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var initedTestFrame = initEventGatewaysTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);

		if(skipBaselineSeedForField(arguments.configType, arguments.fieldName))
			return { initedTestFrame = initedTestFrame, originalValue = "delete" };

		var seedValue = "";
		if(arguments.configType EQ "gatewayType")
			seedValue = egUtil.encodeJson(egUtil.getDefaultGatewayTypeConfig());
		else if(arguments.configType EQ "gatewayInstance")
			seedValue = egUtil.encodeJson(egUtil.getDefaultGatewayInstanceConfig());

		arguments.testDriver.setAndGetSyncedValues(
			duplicate(initedTestFrame),
			seedValue,
			arguments.settingName
		);
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		initedTestFrame = initEventGatewaysTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);

		return { initedTestFrame = initedTestFrame, originalValue = "delete" };
	}

	public struct function prepareGatewayTypeFieldTest(
		required any testDriver,
		required string scriptPath,
		string fieldName = "",
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort"
	){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		egUtil.ensureTestGatewayTypeAbsent();
		return seedEventGatewaysBaseline(
			arguments.testDriver,
			"GatewayType",
			arguments.scriptPath,
			"gatewayType",
			arguments.fieldName,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
	}

	public struct function prepareGatewayInstanceFieldTest(
		required any testDriver,
		required string scriptPath,
		string fieldName = "",
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort"
	){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		egUtil.ensureTestGatewayInstanceAbsent();
		return seedEventGatewaysBaseline(
			arguments.testDriver,
			"GatewayInstance",
			arguments.scriptPath,
			"gatewayInstance",
			arguments.fieldName,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
	}

	public struct function runSettingsSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort"
	){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var initedTestFrame = initEventGatewaysTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = egUtil.getNewSetValueForSetting(arguments.settingName, currentValue);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		writeOutput(
			"updating " & arguments.settingName & " to: " &
			egUtil.formatSettingsDisplayValue(arguments.settingName, newSetValue) &
			" on node: " & currentNode & "<br>"
		);

		stUtil.initializeCcsNodeConfig("all");
		var existingValues = stUtil.collectPresetValuesFromFrame(
			initEventGatewaysTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes)
		);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			initedTestFrame,
			arguments.settingName,
			newSetValue
		);

		if(syncResult.passed){
			stUtil.writeSyncVerificationTable(
				buildEventGatewaysVerificationRows(
					syncResult.postSyncFrame,
					newSetValue,
					"settings",
					"",
					arguments.settingName
				),
				arguments.settingName
			);
			stUtil.initializeCcsNodeConfig("all");
			var afterFrame = initEventGatewaysTestFrame(
				arguments.testDriver,
				arguments.settingName,
				arguments.scriptPath,
				arguments.skipUnreachableNodes
			);
			writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
			stUtil.applyExistingPresetValuesToFrame(afterFrame, existingValues);
			stUtil.writeSyncVerificationTable(
				buildEventGatewaysVerificationRows(
					afterFrame,
					newSetValue,
					"settings",
					"",
					arguments.settingName,
					true
				),
				arguments.settingName
			);
		}

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = syncResult.passed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName
		};
	}

	public struct function runGatewayTypeFieldSyncTest(
		required any testDriver,
		required string fieldName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort"
	){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var prepared = prepareGatewayTypeFieldTest(
			arguments.testDriver,
			arguments.scriptPath,
			arguments.fieldName,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var currentValue = stUtil.getPresetValueFromFrame(prepared.initedTestFrame, "GatewayType");
		var newConfig = egUtil.buildGatewayTypeConfigForField(arguments.fieldName, currentValue);
		var newSetValue = egUtil.encodeJson(newConfig);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(prepared.initedTestFrame, "GatewayType");
		var expectedFieldValue = egUtil.extractGatewayTypeFieldValue(newConfig, arguments.fieldName);
		writeOutput("updating gateway type #arguments.fieldName# to: #formatFieldDisplayValue(expectedFieldValue, arguments.fieldName)# on node: #currentNode#<br>");

		return runEventGatewaysSyncTest(
			arguments.testDriver,
			"GatewayType",
			arguments.scriptPath,
			newSetValue,
			prepared.initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			arguments.fieldName,
			"gatewayType",
			prepared.originalValue
		);
	}

	public struct function runGatewayInstanceFieldSyncTest(
		required any testDriver,
		required string fieldName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort"
	){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var prepared = prepareGatewayInstanceFieldTest(
			arguments.testDriver,
			arguments.scriptPath,
			arguments.fieldName,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var currentValue = stUtil.getPresetValueFromFrame(prepared.initedTestFrame, "GatewayInstance");
		var newConfig = egUtil.buildGatewayInstanceConfigForField(arguments.fieldName, currentValue);
		var newSetValue = egUtil.encodeJson(newConfig);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(prepared.initedTestFrame, "GatewayInstance");
		var expectedFieldValue = egUtil.extractGatewayInstanceFieldValue(newConfig, arguments.fieldName);
		writeOutput("updating gateway instance #arguments.fieldName# to: #formatFieldDisplayValue(expectedFieldValue, arguments.fieldName)# on node: #currentNode#<br>");

		return runEventGatewaysSyncTest(
			arguments.testDriver,
			"GatewayInstance",
			arguments.scriptPath,
			newSetValue,
			prepared.initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			arguments.fieldName,
			"gatewayInstance",
			prepared.originalValue
		);
	}

	public struct function runFullGatewayTypeSyncTest(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort"
	){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var prepared = prepareGatewayTypeFieldTest(
			arguments.testDriver,
			arguments.scriptPath,
			"",
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var config = egUtil.getDefaultGatewayTypeConfig();
		config.description = "CCS full gateway type config test";
		config.class = "examples.watcher.DirectoryWatcherGateway";
		var newSetValue = egUtil.encodeJson(config);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(prepared.initedTestFrame, "GatewayType");
		writeOutput("updating full gateway type config on node: #currentNode#<br>");

		return runEventGatewaysSyncTest(
			arguments.testDriver,
			"GatewayType",
			arguments.scriptPath,
			newSetValue,
			prepared.initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			"",
			"gatewayType",
			prepared.originalValue
		);
	}

	public struct function runFullGatewayInstanceSyncTest(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort"
	){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var prepared = prepareGatewayInstanceFieldTest(
			arguments.testDriver,
			arguments.scriptPath,
			"",
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var config = egUtil.getDefaultGatewayInstanceConfig();
		config.mode = "auto";
		config.cfcPaths = [egUtil.getAltGatewayCfcPath()];
		var newSetValue = egUtil.encodeJson(config);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(prepared.initedTestFrame, "GatewayInstance");
		writeOutput("updating full gateway instance config on node: #currentNode#<br>");

		return runEventGatewaysSyncTest(
			arguments.testDriver,
			"GatewayInstance",
			arguments.scriptPath,
			newSetValue,
			prepared.initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			"",
			"gatewayInstance",
			prepared.originalValue
		);
	}

	private struct function runEventGatewaysSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		required any newSetValue,
		required struct initedTestFrame,
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort",
		string fieldName = "",
		required string configType,
		required any restoreValue
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		var existingValues = stUtil.collectPresetValuesFromFrame(
			initEventGatewaysTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes)
		);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncResult = stUtil.runSyncTest(
			arguments.testDriver,
			arguments.initedTestFrame,
			arguments.settingName,
			arguments.newSetValue
		);
		var apiArea = structKeyExists(arguments.initedTestFrame, application.testConstants.TEST_FRAME.API_AREA)
			? arguments.initedTestFrame[application.testConstants.TEST_FRAME.API_AREA]
			: "settings";
		var verificationRows = buildEventGatewaysVerificationRows(
			syncResult.postSyncFrame,
			arguments.newSetValue,
			arguments.configType,
			arguments.fieldName,
			arguments.settingName
		);

		if(syncResult.passed){
			stUtil.writeSyncVerificationTable(verificationRows, arguments.settingName);
			stUtil.initializeCcsNodeConfig("all");
			var afterFrame = initEventGatewaysTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes);
			writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
			stUtil.applyExistingPresetValuesToFrame(afterFrame, existingValues);
			stUtil.writeSyncVerificationTable(
				buildEventGatewaysVerificationRows(afterFrame, arguments.newSetValue, arguments.configType, arguments.fieldName, arguments.settingName, true),
				arguments.settingName
			);
		}

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = syncResult.passed,
			initedTestFrame = arguments.initedTestFrame,
			originalValue = arguments.restoreValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName
		};
	}

	public void function restoreEventGatewaysSyncTest(required any testDriver, required struct syncTestResult){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		if(NOT structKeyExists(arguments.syncTestResult, "originalValue"))
			return;
		var settingName = structKeyExists(arguments.syncTestResult, "settingName")
			? arguments.syncTestResult.settingName
			: "EnableGatewayService";
		var scriptPath = structKeyExists(arguments.syncTestResult, "scriptPath")
			? arguments.syncTestResult.scriptPath
			: "/cfsuite/ccssuite/testsuite/eventGateways/settings/enableGatewayService.cfm";
		stUtil.initializeCcsNodeConfig("all");
		var restoreFrame = initEventGatewaysTestFrame(arguments.testDriver, settingName, scriptPath, true);
		stUtil.restoreTest(arguments.testDriver, restoreFrame, arguments.syncTestResult.originalValue, settingName);
		application.ccsTestNodesScope = "currentPort";
	}

	public string function getQatestResultMessage(required boolean passed){
		return new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().getQatestResultMessage(arguments.passed);
	}

	private string function payloadToString(required any payload){
		if(isNull(arguments.payload))
			return "";
		if(isQuery(arguments.payload))
			return serializeJSON(queryToArray(arguments.payload));
		if(isSimpleValue(arguments.payload))
			return trim("" & arguments.payload);
		if(isStruct(arguments.payload) OR isArray(arguments.payload))
			return serializeJSON(arguments.payload);
		return "";
	}

	private array function queryToArray(required query data){
		var rows = [];
		for(var rowIdx = 1; rowIdx LTE arguments.data.recordCount; rowIdx++){
			var row = {};
			for(var col in arguments.data.columnList()){
				row[col] = arguments.data[col][rowIdx];
			}
			arrayAppend(rows, row);
		}
		return rows;
	}

	public array function buildEventGatewaysVerificationRows(
		required struct postSyncFrame,
		required any newSetValue,
		required string configType,
		string fieldName = "",
		string settingName = "",
		boolean showEmptyNodes = false
	){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var rows = [];
		var setTypes = [
			application.testConstants.TEST_FRAME.PRIME_SET,
			application.testConstants.TEST_FRAME.NONPRIME_SET
		];

		for(var setType in setTypes){
			if(NOT structKeyExists(arguments.postSyncFrame, setType))
				continue;
			for(var nodeKey in arguments.postSyncFrame[setType].keyList()){
				var actual = arguments.postSyncFrame[setType][nodeKey];
				var prePayload = structKeyExists(actual, application.testConstants.TEST_FRAME.PRESET_VALUE)
					? actual[application.testConstants.TEST_FRAME.PRESET_VALUE] : "";
				var postPayload = structKeyExists(actual, application.testConstants.TEST_FRAME.POSTSET_VALUE)
					? actual[application.testConstants.TEST_FRAME.POSTSET_VALUE] : "";
				var prePayloadText = payloadToString(prePayload);
				var postPayloadText = payloadToString(postPayload);
				if(NOT arguments.showEmptyNodes AND NOT len(prePayloadText) AND NOT len(postPayloadText))
					continue;

				var preDisplay = formatPayloadDisplay(prePayloadText, arguments.configType, arguments.fieldName, arguments.settingName);
				var postDisplay = formatPayloadDisplay(postPayloadText, arguments.configType, arguments.fieldName, arguments.settingName);
				var passed = eventGatewaysNodeVerificationPassed(
					arguments.configType,
					arguments.fieldName,
					arguments.settingName,
					prePayloadText,
					postPayloadText,
					payloadToString(arguments.newSetValue),
					nodeKey
				);

				var cluster = "N/A";
				var env = "N/A";
				if(structKeyExists(application, "ccsConfigMap") AND application.ccsConfigMap.keyExists(nodeKey)) {
					cluster = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.CLUSTER];
					env = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
				}

				arrayAppend(rows, {
					nodeKey = nodeKey,
					nodeLabel = stUtil.getURLFragFromNodeKey(nodeKey),
					existingValue = "" & preDisplay,
					updatedValue = "" & postDisplay,
					verificationStatus = passed ? "Passed" : "Failed",
					passed = passed,
					cluster = len(trim("" & cluster)) ? ("" & cluster) : "N/A",
					environment = len(trim("" & env)) ? ("" & env) : "N/A",
					setType = setType
				});
			}
		}
		return rows;
	}

	private boolean function eventGatewaysNodeVerificationPassed(
		required string configType,
		required string fieldName,
		required string settingName,
		required any presetPayload,
		required any postPayload,
		required any expectedPayload,
		required string nodeKey
	){
		var presetText = payloadToString(arguments.presetPayload);
		var postText = payloadToString(arguments.postPayload);
		var expectedText = payloadToString(arguments.expectedPayload);
		if(findNoCase("set FAILED", postText))
			return false;
		if(NOT isSameClusterNode(arguments.nodeKey))
			return payloadsEquivalent(arguments.configType, arguments.settingName, presetText, postText);
		if(arguments.configType EQ "settings")
			return new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init().scalarValuesMatch(
				expectedText,
				postText,
				arguments.settingName
			);
		if(len(trim("" & arguments.fieldName)))
			return fieldValuesEquivalent(
				arguments.configType,
				arguments.fieldName,
				extractFieldFromPayload(arguments.configType, postText, arguments.fieldName),
				extractFieldFromPayload(arguments.configType, expectedText, arguments.fieldName)
			);
		return payloadsEquivalent(arguments.configType, arguments.settingName, expectedText, postText);
	}

	private boolean function isSameClusterNode(required string nodeKey){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		if(NOT structKeyExists(application, "ccsConfigMap"))
			return true;
		var currentKey = CGI.SERVER_NAME & "::" & CGI.SERVER_PORT;
		if(NOT application.ccsConfigMap.keyExists(currentKey) OR NOT application.ccsConfigMap.keyExists(arguments.nodeKey))
			return true;
		var currentCluster = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.CLUSTER];
		var currentEnv = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		var nodeCluster = application.ccsConfigMap[arguments.nodeKey][application.constants.CCS_CONFIG.CLUSTER];
		var nodeEnv = application.ccsConfigMap[arguments.nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		return currentCluster EQ nodeCluster AND currentEnv EQ nodeEnv;
	}

	private boolean function payloadsEquivalent(required string configType, required string settingName, required any leftPayload, required any rightPayload){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		if(arguments.configType EQ "settings")
			return egUtil.scalarValuesMatch(arguments.leftPayload, arguments.rightPayload, arguments.settingName);
		return egUtil.configsMatch(arguments.leftPayload, arguments.rightPayload);
	}

	private any function extractFieldFromPayload(required string configType, required any payload, required string fieldName){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		var config = egUtil.decodeJson(arguments.payload);
		if(NOT isStruct(config)) config = {};
		if(arguments.configType EQ "gatewayType")
			return egUtil.extractGatewayTypeFieldValue(config, arguments.fieldName);
		if(arguments.configType EQ "gatewayInstance")
			return egUtil.extractGatewayInstanceFieldValue(config, arguments.fieldName);
		return "";
	}

	private boolean function fieldValuesEquivalent(required string configType, required string fieldName, required any left, required any right){
		if(isBoolean(arguments.left) OR isBoolean(arguments.right))
			return (arguments.left ? true : false) EQ (arguments.right ? true : false);
		if(isNumeric(arguments.left) AND isNumeric(arguments.right))
			return val(arguments.left) EQ val(arguments.right);
		if(arguments.configType EQ "gatewayInstance" AND lCase(arguments.fieldName) EQ "cfcpaths"){
			var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
			var leftPaths = isArray(arguments.left) ? arguments.left : listToArray(replace(trim("" & arguments.left), ";", ",", "all"), ",", false, true);
			var rightPaths = isArray(arguments.right) ? arguments.right : listToArray(replace(trim("" & arguments.right), ";", ",", "all"), ",", false, true);
			return egUtil.configsMatch(egUtil.encodeJson({cfcPaths=leftPaths}), egUtil.encodeJson({cfcPaths=rightPaths}));
		}
		if(arguments.configType EQ "gatewayInstance" AND lCase(arguments.fieldName) EQ "configurationpath"){
			var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
			return egUtil.configsMatch(
				egUtil.encodeJson({configurationPath=arguments.left}),
				egUtil.encodeJson({configurationPath=arguments.right})
			);
		}
		return trim("" & arguments.left) EQ trim("" & arguments.right);
	}

	private string function formatPayloadDisplay(required any payload, required string configType, string fieldName = "", string settingName = ""){
		var egUtil = new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init();
		if(arguments.configType EQ "settings")
			return egUtil.formatSettingsDisplayValue(arguments.settingName, arguments.payload);
		if(len(arguments.fieldName)){
			var config = egUtil.decodeJson(arguments.payload);
			if(NOT isStruct(config)) config = {};
			if(arguments.configType EQ "gatewayType")
				return formatFieldDisplayValue(egUtil.extractGatewayTypeFieldValue(config, arguments.fieldName), arguments.fieldName);
			if(arguments.configType EQ "gatewayInstance")
				return formatFieldDisplayValue(egUtil.extractGatewayInstanceFieldValue(config, arguments.fieldName), arguments.fieldName);
		}
		var config = egUtil.decodeJson(arguments.payload);
		if(NOT isStruct(config) OR structIsEmpty(config))
			return "(empty)";
		var parts = [];
		if(structKeyExists(config, "type")) arrayAppend(parts, "type=" & config.type);
		if(structKeyExists(config, "gatewayId")) arrayAppend(parts, "gatewayId=" & config.gatewayId);
		if(structKeyExists(config, "description")) arrayAppend(parts, "description=" & config.description);
		if(structKeyExists(config, "class")) arrayAppend(parts, "class=" & config.class);
		if(structKeyExists(config, "startTimeout")) arrayAppend(parts, "startTimeout=" & config.startTimeout);
		if(structKeyExists(config, "killOnTimeout")) arrayAppend(parts, "killOnTimeout=" & (config.killOnTimeout ? "true" : "false"));
		if(structKeyExists(config, "cfcPaths") AND isArray(config.cfcPaths)) arrayAppend(parts, "cfcPaths=" & arrayToList(config.cfcPaths, "; "));
		if(structKeyExists(config, "configurationPath")) arrayAppend(parts, "configurationPath=" & config.configurationPath);
		if(structKeyExists(config, "mode")) arrayAppend(parts, "mode=" & config.mode);
		return arrayLen(parts) ? arrayToList(parts, "; ") : "(registered)";
	}

	public string function formatFieldDisplayValue(required any value, string fieldName = ""){
		if(isArray(arguments.value))
			return arrayToList(arguments.value, "; ");
		if(isNull(arguments.value))
			return "(empty)";
		if(isBoolean(arguments.value))
			return arguments.value ? "true" : "false";
		if(isNumeric(arguments.value))
			return "" & val(arguments.value);
		if(NOT len(trim("" & arguments.value))){
			if(len(arguments.fieldName) AND listFindNoCase("description,configurationpath", lCase(arguments.fieldName)))
				return "(empty)";
			return "(empty)";
		}
		return trim("" & arguments.value);
	}

}
