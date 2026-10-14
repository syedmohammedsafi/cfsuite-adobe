/**
* Shared helpers for Extensions testsuite CFM pages.
*/
component output="true" {

	public function init(){
		return this;
	}

	private struct function initExtensionsTestFrame(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		return arguments.testDriver.initTestFrameWithPreSetValues(
			arguments.settingName,
			arguments.testDriver.getGenericTestFrame(),
			arguments.scriptPath,
			"_getterExtensions.cfm",
			"_setterExtensions.cfm",
			arguments.skipUnreachableNodes
		);
	}

	private boolean function skipBaselineSeedForField(required string configType, required string fieldName){
		var field = lCase(trim(arguments.fieldName));
		if(arguments.configType EQ "java" AND field EQ "tagname")
			return true;
		if(arguments.configType EQ "cpp" AND listFindNoCase("tagname,serverlibrary,procedure", field))
			return true;
		return false;
	}

	private void function deleteTestCppCfxOnAllNodes(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		new cfsuite.ccssuite.utils.extensionsConfigUtil().init().ensureTestCppCfxAbsent();
		propagateExtensionsSettingToPeers(arguments.testDriver, arguments.scriptPath, "CppCfx", "delete", arguments.skipUnreachableNodes);
		application.ccsTestNodesScope = "currentPort";
	}

	private void function deleteTestJavaCfxOnAllNodes(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		new cfsuite.ccssuite.utils.extensionsConfigUtil().init().ensureTestJavaCfxAbsent();
		propagateExtensionsSettingToPeers(arguments.testDriver, arguments.scriptPath, "JavaCfx", "delete", arguments.skipUnreachableNodes);
		application.ccsTestNodesScope = "currentPort";
	}

	private void function propagateExtensionsSettingToPeers(
		required any testDriver,
		required string scriptPath,
		required string settingName,
		required string setValue,
		boolean skipUnreachableNodes = true
	){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		var frame = initExtensionsTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes);
		var currentKey = getCurrentServerNodeKey();
		var apiArea = frame[application.testConstants.TEST_FRAME.API_AREA];
		var setterUrl = frame[application.testConstants.TEST_FRAME.SETTER_URL];
		var protocol = structKeyExists(application, "protocol") ? application.protocol : "http";
		var setTypes = [
			application.testConstants.TEST_FRAME.PRIME_SET,
			application.testConstants.TEST_FRAME.NONPRIME_SET
		];

		for(var setType in setTypes){
			if(NOT structKeyExists(frame, setType))
				continue;
			for(var nodeKey in frame[setType].keyList()){
				if(nodeKey EQ currentKey)
					continue;
				var nodeFrag = stUtil.getURLFragFromNodeKey(nodeKey);
				var url = protocol & "://" & nodeFrag & setterUrl
					& "?setting=" & urlEncodedFormat(arguments.settingName)
					& "&setValueTo=" & urlEncodedFormat(arguments.setValue)
					& "&area=" & urlEncodedFormat(apiArea);
				try {
					cfhttp(url=url, method="GET", result="response", timeout=20);
				}
				catch(any e){}
			}
		}
	}

	private string function getCurrentServerNodeKey(){
		return CGI.SERVER_NAME & "::" & CGI.SERVER_PORT;
	}

	private array function filterVerificationRowsForCurrentNode(required array rows){
		var currentKey = getCurrentServerNodeKey();
		var filtered = [];
		for(var row in arguments.rows){
			if(row.nodeKey EQ currentKey)
				arrayAppend(filtered, row);
		}
		if(NOT arrayLen(filtered) AND arrayLen(arguments.rows))
			arrayAppend(filtered, arguments.rows[1]);
		return filtered;
	}

	private struct function seedExtensionsBaseline(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		required string configType,
		required string fieldName,
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort"
	){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var initedTestFrame = initExtensionsTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);

		if(skipBaselineSeedForField(arguments.configType, arguments.fieldName))
			return { initedTestFrame = initedTestFrame, originalValue = "delete" };

		var seedConfig = (arguments.configType EQ "java")
			? extUtil.getDefaultJavaCfxConfig()
			: extUtil.getDefaultCppCfxConfig();
		arguments.testDriver.setAndGetSyncedValues(
			duplicate(initedTestFrame),
			extUtil.encodeJson(seedConfig),
			arguments.settingName
		);
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		initedTestFrame = initExtensionsTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);

		return { initedTestFrame = initedTestFrame, originalValue = "delete" };
	}

	public struct function prepareJavaCfxFieldTest(
		required any testDriver,
		required string scriptPath,
		string fieldName = "",
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		deleteTestJavaCfxOnAllNodes(arguments.testDriver, arguments.scriptPath, arguments.skipUnreachableNodes);
		return seedExtensionsBaseline(
			arguments.testDriver,
			"JavaCfx",
			arguments.scriptPath,
			"java",
			arguments.fieldName,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
	}

	public struct function prepareCppCfxFieldTest(
		required any testDriver,
		required string scriptPath,
		string fieldName = "",
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		deleteTestCppCfxOnAllNodes(arguments.testDriver, arguments.scriptPath, arguments.skipUnreachableNodes);
		return seedExtensionsBaseline(
			arguments.testDriver,
			"CppCfx",
			arguments.scriptPath,
			"cpp",
			arguments.fieldName,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
	}

	public struct function runJavaCfxFieldSyncTest(
		required any testDriver,
		required string fieldName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var prepared = prepareJavaCfxFieldTest(
			arguments.testDriver,
			arguments.scriptPath,
			arguments.fieldName,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var originalValue = prepared.originalValue;
		var currentValue = stUtil.getPresetValueFromFrame(prepared.initedTestFrame, "JavaCfx");
		var newConfig = extUtil.buildJavaCfxConfigForField(arguments.fieldName, currentValue);
		var newSetValue = extUtil.encodeJson(newConfig);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(prepared.initedTestFrame, "JavaCfx");
		var expectedFieldValue = extUtil.extractJavaFieldValue(newConfig, arguments.fieldName);
		writeOutput("updating Java CFX #arguments.fieldName# to: #formatFieldDisplayValue(expectedFieldValue, arguments.fieldName)# on node: #currentNode#<br>");

		return runExtensionsFieldSyncTest(
			arguments.testDriver,
			"JavaCfx",
			arguments.scriptPath,
			newSetValue,
			prepared.initedTestFrame,
			arguments.skipUnreachableNodes,
			"all",
			arguments.fieldName,
			"java",
			originalValue
		);
	}

	public struct function runCppCfxFieldSyncTest(
		required any testDriver,
		required string fieldName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var prepared = prepareCppCfxFieldTest(
			arguments.testDriver,
			arguments.scriptPath,
			arguments.fieldName,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var originalValue = prepared.originalValue;
		var currentValue = stUtil.getPresetValueFromFrame(prepared.initedTestFrame, "CppCfx");
		var newConfig = extUtil.buildCppCfxConfigForField(arguments.fieldName, currentValue);
		var newSetValue = extUtil.encodeJson(newConfig);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(prepared.initedTestFrame, "CppCfx");
		var expectedFieldValue = extUtil.extractCppFieldValue(newConfig, arguments.fieldName);
		writeOutput("updating C++ CFX #arguments.fieldName# to: #formatFieldDisplayValue(expectedFieldValue, arguments.fieldName)# on node: #currentNode#<br>");

		return runExtensionsFieldSyncTest(
			arguments.testDriver,
			"CppCfx",
			arguments.scriptPath,
			newSetValue,
			prepared.initedTestFrame,
			arguments.skipUnreachableNodes,
			"all",
			arguments.fieldName,
			"cpp",
			originalValue
		);
	}

	public struct function runCustomTagPathSyncTest(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "currentPort"
	){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		extUtil.ensureTestCustomTagPathAbsent();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var initedTestFrame = initExtensionsTestFrame(arguments.testDriver, "CustomTagPaths", arguments.scriptPath, arguments.skipUnreachableNodes);
		var currentPathsJson = stUtil.getPresetValueFromFrame(initedTestFrame, "CustomTagPaths");
		if(NOT len(trim("" & currentPathsJson)))
			currentPathsJson = extUtil.getExtensionsSetting("CustomTagPaths");
		var originalValue = extUtil.getRemoveTestCustomTagPathToken();
		var newSetValue = extUtil.getAddTestCustomTagPathToken();
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, "CustomTagPaths");
		writeOutput("adding custom tag path #extUtil.getTestCustomTagPath()# on node: #currentNode#<br>");

		return runExtensionsFieldSyncTest(
			arguments.testDriver,
			"CustomTagPaths",
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			"all",
			"",
			"customTagPaths",
			originalValue
		);
	}

	public struct function runFullJavaCfxSyncTest(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		deleteTestJavaCfxOnAllNodes(arguments.testDriver, arguments.scriptPath, arguments.skipUnreachableNodes);
		stUtil.initializeCcsNodeConfig("all");
		var initedTestFrame = initExtensionsTestFrame(arguments.testDriver, "JavaCfx", arguments.scriptPath, arguments.skipUnreachableNodes);
		var config = extUtil.getDefaultJavaCfxConfig();
		config.description = "CCS full Java CFX config test";
		config.className = "CCSTestJavaCfxAlt";
		var newSetValue = extUtil.encodeJson(config);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, "JavaCfx");
		writeOutput("registering full Java CFX config on node: #currentNode#<br>");

		return runExtensionsFieldSyncTest(
			arguments.testDriver,
			"JavaCfx",
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			"all",
			"",
			"java",
			"delete"
		);
	}

	public struct function runFullCppCfxSyncTest(
		required any testDriver,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		deleteTestCppCfxOnAllNodes(arguments.testDriver, arguments.scriptPath, arguments.skipUnreachableNodes);
		stUtil.initializeCcsNodeConfig("all");
		var initedTestFrame = initExtensionsTestFrame(arguments.testDriver, "CppCfx", arguments.scriptPath, arguments.skipUnreachableNodes);
		var config = extUtil.getDefaultCppCfxConfig();
		config.description = "CCS full C++ CFX config test";
		config.keepLibraryLoaded = false;
		var newSetValue = extUtil.encodeJson(config);
		var currentNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, "CppCfx");
		writeOutput("registering full C++ CFX config on node: #currentNode#<br>");

		return runExtensionsFieldSyncTest(
			arguments.testDriver,
			"CppCfx",
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			"all",
			"",
			"cpp",
			"delete"
		);
	}

	private struct function runExtensionsFieldSyncTest(
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
			initExtensionsTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes)
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
			: "cfxTags";
		var verificationRows = buildExtensionsVerificationRows(
			syncResult.postSyncFrame,
			arguments.newSetValue,
			arguments.configType,
			arguments.fieldName,
			apiArea,
			false,
			arguments.testDriver,
			arguments.scriptPath
		);
		var passed = extensionsVerificationPassed(verificationRows);

		if(arrayLen(verificationRows)){
			stUtil.writeSyncVerificationTable(
				passed
					? filterVerificationRowsForCurrentNode(verificationRows)
					: verificationRows,
				arguments.settingName
			);
		}

		if(passed){
			stUtil.initializeCcsNodeConfig("all");
			var afterFrame = initExtensionsTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes);
			writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
			stUtil.applyExistingPresetValuesToFrame(afterFrame, existingValues);
			var afterRows = buildExtensionsVerificationRows(
				afterFrame,
				arguments.newSetValue,
				arguments.configType,
				arguments.fieldName,
				apiArea,
				true,
				arguments.testDriver,
				arguments.scriptPath
			);
			passed = extensionsVerificationPassed(afterRows);
			stUtil.writeSyncVerificationTable(afterRows, arguments.settingName);
		}

		application.ccsTestNodesScope = "currentPort";
		return {
			passed = passed,
			initedTestFrame = arguments.initedTestFrame,
			originalValue = arguments.restoreValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName
		};
	}

	public void function restoreExtensionsSyncTest(required any testDriver, required struct syncTestResult){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		if(NOT structKeyExists(arguments.syncTestResult, "originalValue"))
			return;
		var settingName = structKeyExists(arguments.syncTestResult, "settingName")
			? arguments.syncTestResult.settingName
			: "JavaCfx";
		var scriptPath = structKeyExists(arguments.syncTestResult, "scriptPath")
			? arguments.syncTestResult.scriptPath
			: "/cfsuite/ccssuite/testsuite/extensions/cfxTags/java/javaCfxConfig.cfm";
		stUtil.initializeCcsNodeConfig("all");
		var restoreFrame = initExtensionsTestFrame(arguments.testDriver, settingName, scriptPath, true);
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

	public array function buildExtensionsVerificationRows(
		required struct postSyncFrame,
		required any newSetValue,
		required string configType,
		string fieldName = "",
		string apiArea = "",
		boolean showEmptyNodes = false,
		any testDriver = "",
		string scriptPath = ""
	){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
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
				if(NOT arguments.showEmptyNodes AND NOT len(trim("" & prePayload)) AND NOT len(trim("" & postPayload)))
					continue;

				var preDisplay = formatPayloadDisplay(prePayload, arguments.configType, arguments.fieldName, nodeKey, arguments.testDriver, arguments.scriptPath);
				var postDisplay = formatPayloadDisplay(postPayload, arguments.configType, arguments.fieldName, nodeKey, arguments.testDriver, arguments.scriptPath);
				var passed = extensionsNodeVerificationPassed(
					arguments.configType,
					arguments.fieldName,
					prePayload,
					postPayload,
					arguments.newSetValue,
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
					existingValue = preDisplay,
					updatedValue = postDisplay,
					verificationStatus = passed ? "Passed" : "Failed",
					passed = passed,
					cluster = len(trim("" & cluster)) ? cluster : "N/A",
					environment = len(trim("" & env)) ? env : "N/A",
					setType = setType
				});
			}
		}
		return rows;
	}

	private boolean function extensionsVerificationPassed(required array rows){
		if(NOT arrayLen(arguments.rows))
			return false;
		for(var row in arguments.rows){
			if(NOT row.passed)
				return false;
		}
		return true;
	}

	private boolean function extensionsNodeVerificationPassed(
		required string configType,
		required string fieldName,
		required any presetPayload,
		required any postPayload,
		required any expectedPayload,
		required string nodeKey
	){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		var presetText = payloadToString(arguments.presetPayload);
		var postText = payloadToString(arguments.postPayload);
		var expectedText = payloadToString(arguments.expectedPayload);
		if(findNoCase("set FAILED", postText))
			return false;
		if(NOT isSameClusterNode(arguments.nodeKey))
			return configsEquivalent(arguments.configType, presetText, postText);
		if(len(arguments.fieldName))
			return fieldValuesEquivalent(
				arguments.configType,
				arguments.fieldName,
				extractFieldFromPayload(arguments.configType, postText, arguments.fieldName),
				extractFieldFromPayload(arguments.configType, expectedText, arguments.fieldName)
			);
		if(arguments.configType EQ "customTagPaths"){
			if(trim(expectedText) EQ extUtil.getRemoveTestCustomTagPathToken())
				return NOT extUtil.customTagPathPresent(postText, "");
			return extUtil.customTagPathPresent(postText, "");
		}
		return configsEquivalent(arguments.configType, expectedText, postText);
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

	private boolean function configsEquivalent(required string configType, required any leftPayload, required any rightPayload){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		if(arguments.configType EQ "cpp" OR arguments.configType EQ "java")
			return extUtil.configsMatch(arguments.leftPayload, arguments.rightPayload);
		var left = extUtil.decodeJson(leftPayload);
		var right = extUtil.decodeJson(rightPayload);
		if(arguments.configType EQ "customTagPaths"){
			if(NOT isArray(left)) left = [];
			if(NOT isArray(right)) right = [];
			if(arrayLen(left) NEQ arrayLen(right)) return false;
			for(var item in left){
				if(arrayFindNoCase(right, item) EQ 0) return false;
			}
			return true;
		}
		if(NOT isStruct(left)) left = {};
		if(NOT isStruct(right)) right = {};
		return serializeJSON(sortStructKeys(left)) EQ serializeJSON(sortStructKeys(right));
	}

	private struct function sortStructKeys(required struct data){
		var sorted = {};
		for(var key in structSort(arguments.data, "text", "asc")){
			sorted[key] = isStruct(arguments.data[key]) ? sortStructKeys(arguments.data[key]) : arguments.data[key];
		}
		return sorted;
	}

	private any function extractFieldFromPayload(required string configType, required any payload, required string fieldName){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		var config = extUtil.decodeJson(arguments.payload);
		if(NOT isStruct(config)) config = {};
		if(arguments.configType EQ "java")
			return extUtil.extractJavaFieldValue(config, arguments.fieldName);
		if(arguments.configType EQ "cpp")
			return extUtil.extractCppFieldValue(config, arguments.fieldName);
		return "";
	}

	private boolean function fieldValuesEquivalent(required string configType, required string fieldName, required any left, required any right){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		return extUtil.cfxFieldValuesMatch(arguments.configType, arguments.fieldName, arguments.left, arguments.right);
	}

	private string function formatPayloadDisplay(
		required any payload,
		required string configType,
		string fieldName = "",
		string nodeKey = "",
		any testDriver = "",
		string scriptPath = ""
	){
		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		if(len(arguments.fieldName)){
			var config = extUtil.decodeJson(arguments.payload);
			if(NOT isStruct(config)) config = {};
			if(arguments.configType EQ "cpp" AND lCase(arguments.fieldName) EQ "serverlibrary"
					AND len(trim("" & extUtil.extractCppFieldValue(config, "tagName")))
					AND len(arguments.nodeKey) AND len(arguments.scriptPath) AND isObject(arguments.testDriver)){
				return formatFieldDisplayValue(
					getLocalCppServerLibraryForNode(arguments.nodeKey, arguments.testDriver, arguments.scriptPath),
					arguments.fieldName
				);
			}
			if(arguments.configType EQ "java")
				return formatFieldDisplayValue(extUtil.extractJavaFieldValue(config, arguments.fieldName), arguments.fieldName);
			if(arguments.configType EQ "cpp")
				return formatFieldDisplayValue(extUtil.extractCppFieldValue(config, arguments.fieldName), arguments.fieldName);
		}
		if(arguments.configType EQ "customTagPaths"){
			var payloadText = trim("" & arguments.payload);
			if(payloadText EQ extUtil.getAddTestCustomTagPathToken())
				return "(add test path)";
			if(payloadText EQ extUtil.getRemoveTestCustomTagPathToken())
				return "(remove test path)";
			var paths = extUtil.decodeJson(arguments.payload);
			return isArray(paths) ? arrayToList(paths, "; ") : "(empty)";
		}
		var config = extUtil.decodeJson(arguments.payload);
		if(NOT isStruct(config) OR structIsEmpty(config))
			return "(not registered)";
		var parts = [];
		var tagName = extUtil.extractCppFieldValue(config, "tagName");
		if(len(trim("" & tagName))) arrayAppend(parts, "tagName=" & tagName);
		var className = extUtil.extractJavaFieldValue(config, "className");
		if(len(trim("" & className))) arrayAppend(parts, "className=" & className);
		var serverLibrary = extUtil.extractCppFieldValue(config, "serverLibrary");
		if(len(trim("" & extUtil.extractCppFieldValue(config, "tagName"))) AND len(arguments.nodeKey)
				AND len(arguments.scriptPath) AND isObject(arguments.testDriver))
			serverLibrary = getLocalCppServerLibraryForNode(arguments.nodeKey, arguments.testDriver, arguments.scriptPath);
		else if(len(trim("" & serverLibrary)))
			serverLibrary = serverLibrary;
		if(len(trim("" & serverLibrary))) arrayAppend(parts, "serverLibrary=" & serverLibrary);
		var procedure = extUtil.extractCppFieldValue(config, "procedure");
		if(len(trim("" & procedure))) arrayAppend(parts, "procedure=" & procedure);
		var keepLoaded = extUtil.extractCppFieldValue(config, "keepLibraryLoaded");
		if(len(trim("" & keepLoaded)) OR isBoolean(keepLoaded))
			arrayAppend(parts, "keepLibraryLoaded=" & (keepLoaded ? "true" : "false"));
		var description = extUtil.extractCppFieldValue(config, "description");
		if(len(trim("" & description))) arrayAppend(parts, "description=" & description);
		return arrayLen(parts) ? arrayToList(parts, "; ") : "(registered)";
	}

	public string function formatFieldDisplayValue(required any value, string fieldName = ""){
		if(isNull(arguments.value))
			return "(empty)";
		if(isBoolean(arguments.value))
			return arguments.value ? "true" : "false";
		if(isNumeric(arguments.value))
			return "" & val(arguments.value);
		if(NOT len(trim("" & arguments.value))){
			if(len(arguments.fieldName) AND listFindNoCase("description", lCase(arguments.fieldName)))
				return "(empty)";
			return "(empty)";
		}
		return trim("" & arguments.value);
	}

	private string function getLocalCppServerLibraryForNode(
		required string nodeKey,
		required any testDriver,
		required string scriptPath
	){
		if(NOT structKeyExists(request, "ccsLocalCppLibraryCache"))
			request.ccsLocalCppLibraryCache = {};
		if(structKeyExists(request.ccsLocalCppLibraryCache, arguments.nodeKey))
			return request.ccsLocalCppLibraryCache[arguments.nodeKey];

		var extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		if(isCurrentServerNodeKey(arguments.nodeKey)){
			request.ccsLocalCppLibraryCache[arguments.nodeKey] = extUtil.getTestCppCfxLibraryPath();
			return request.ccsLocalCppLibraryCache[arguments.nodeKey];
		}

		var frame = initExtensionsTestFrame(arguments.testDriver, "CppCfx", arguments.scriptPath, true);
		var getterUrl = frame[application.testConstants.TEST_FRAME.GETTER_URL];
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var protocol = structKeyExists(application, "protocol") ? application.protocol : "http";
		var nodeFrag = stUtil.getURLFragFromNodeKey(arguments.nodeKey);
		var localUrl = protocol & "://" & nodeFrag & getterUrl & "?setting=CppCfx&localPath=1";
		var path = extUtil.getTestCppCfxLibraryPath();
		try {
			cfhttp(url=localUrl, method="GET", result="response", timeout=15);
			if(val(listFirst(response.statusCode, " ")) EQ 200 AND len(trim(response.fileContent)))
				path = trim(response.fileContent);
		}
		catch(any e){}

		request.ccsLocalCppLibraryCache[arguments.nodeKey] = path;
		return path;
	}

	private boolean function isCurrentServerNodeKey(required string nodeKey){
		return arguments.nodeKey EQ getCurrentServerNodeKey();
	}

}
