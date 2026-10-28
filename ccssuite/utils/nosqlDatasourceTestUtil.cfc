component output="false" {

	public function init(){
		return this;
	}

	public any function getNextFieldValue(required string settingName, any currentValue){
		var val = isNull(arguments.currentValue) ? "" : trim("" & arguments.currentValue);
		switch(arguments.settingName){
			case "mongo_enableSSL":
			case "mongo_DnsSeedlist":
			case "mongo_j":
				var b = isBoolean(val) ? (val ? true : false) : (listFindNoCase("true,yes,1,Enabled", val) GT 0);
				return !b;

			case "mongo_port":
				var p = val(val);
				return (p EQ 27017) ? 27018 : (p EQ 27018 ? 27017 : (p > 0 ? p + 1 : 27017));

			case "mongo_writeTimeout":
			case "mongo_connTimeout":
			case "mongo_maxConnPoolWaitTime":
			case "mongo_maxConnPoolSize":
			case "mongo_minConnPoolSize":
			case "mongo_maxConnLifeTime":
			case "mongo_maxConnIdleTime":
			case "mongo_maxConnPoolWaitSize":
			case "mongo_heartbeatFreq":
			case "mongo_minHeartbeatFreq":
				var num = val(val);
				return (num > 0) ? num + 1 : 1;

			case "mongo_maxStaleness":
				var num = val(val);
				return (num > 0) ? num + 10 : 120;

			case "mongo_authMechanism":
				return (compareNoCase(val, "SCRAM-SHA-256") EQ 0) ? "SCRAM-SHA-1" : "SCRAM-SHA-256";

			case "mongo_readConcern":
				return (compareNoCase(val, "majority") EQ 0) ? "local" : "majority";

			case "mongo_readPref":
				return (compareNoCase(val, "primary") EQ 0) ? "secondary" : "primary";

			case "mongo_w":
				return (compareNoCase(val, "1") EQ 0) ? "majority" : "1";

			case "mongo_authSource":
				return (compareNoCase(val, "admin") EQ 0) ? "test" : "admin";

			case "mongo_gssapiServiceName":
				return (compareNoCase(val, "mongodb") EQ 0) ? "testing" : "mongodb";

			case "mongo_host":
				if(val EQ "127.0.0.1") return "127.0.0.2";
				if(val EQ "127.0.0.2") return "127.0.0.1";
				if(len(val) GT 5 AND right(val, 5) EQ "_test")
					return left(val, len(val) - 5);
				return len(val) ? val & "_test" : "127.0.0.1";

			case "mongo_replicaSetName":
			case "mongo_authUsername":
				if(len(val) GT 5 AND right(val, 5) EQ "_test")
					return left(val, len(val) - 5);
				return len(val) ? val & "_test" : "test";

			case "mongo_authPassword":
				return len(val) ? "" : "testpwd";

			case "dsnName":
				if(len(val) GT 5 AND right(val, 5) EQ "_test")
					return left(val, len(val) - 5);
				return len(val) ? val & "_test" : "mongo_dsn_test";

			case "driverName":
				return "mongodb";

			default:
				if(len(val) GT 5 AND right(val, 5) EQ "_test")
					return left(val, len(val) - 5);
				return len(val) ? val & "_test" : "test_val";
		}
	}

	public string function getDefaultDisplayValue(required string settingName){
		switch(arguments.settingName){
			case "mongo_port":
				return "27017";
			case "mongo_authMechanism":
				return "NONE";
			case "mongo_readConcern":
				return "Local";
			case "mongo_readPref":
				return "Primary";
			case "mongo_j":
			case "mongo_enableSSL":
			case "mongo_DnsSeedlist":
				return "Disabled";
			default:
				return "(empty)";
		}
	}

	public string function formatDisplayValue(required string settingName, required any value){
		var text = trim("" & arguments.value);
		if(findNoCase("set FAILED", text))
			return "Setting update failed";
		if(NOT isJSON(text)){
			if(listFindNoCase("mongo_enableSSL,mongo_DnsSeedlist,mongo_j", arguments.settingName)){
				if(NOT len(text) OR text EQ "false" OR text EQ "0" OR text EQ "no" OR text EQ "Disabled" OR text EQ "(empty)")
					return "Disabled";
				if(text EQ "true" OR text EQ "1" OR text EQ "yes" OR text EQ "YES" OR text EQ "Enabled")
					return "Enabled";
			}
			if(NOT len(text))
				return getDefaultDisplayValue(arguments.settingName);
			return text;
		}
		var state = {};
		try {
			state = deserializeJSON(text);
		}
		catch(any e){
			return getDefaultDisplayValue(arguments.settingName);
		}
		if(NOT isStruct(state) OR NOT structKeyExists(state, "entries") OR NOT isStruct(state.entries)){
			return getDefaultDisplayValue(arguments.settingName);
		}
		if(structIsEmpty(state.entries)){
			return getDefaultDisplayValue(arguments.settingName);
		}
		var apiUtil = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init();
		var fieldMap = apiUtil.getFieldMap();
		var targetField = structKeyExists(fieldMap, arguments.settingName) ? fieldMap[arguments.settingName] : arguments.settingName;
		var values = [];
		for(var dsn in state.entries){
			var entry = state.entries[dsn];
			if(arguments.settingName EQ "dsnName"){
				arrayAppend(values, dsn);
			}
			else if(arguments.settingName EQ "driverName"){
				arrayAppend(values, structKeyExists(entry, "type") ? entry.type : "mongodb");
			}
			else if(isStruct(entry)){
				var val = "";
				if(structKeyExists(entry, targetField)) val = entry[targetField];
				else if(structKeyExists(entry, uCase(targetField))) val = entry[uCase(targetField)];
				else if(structKeyExists(entry, lCase(targetField))) val = entry[lCase(targetField)];

				if(listFindNoCase("ssl,dnsSeedList,j", targetField)){
					arrayAppend(values, ((isBoolean(val) && val) OR val EQ "YES" OR val EQ "yes" OR val EQ "1" OR val EQ "true") ? "Enabled" : "Disabled");
				}
				else if(targetField EQ "password"){
					arrayAppend(values, (len(trim(val)) && val NEQ "empty") ? "[redacted]" : "(empty)");
				}
				else if(len(trim("" & val))){
					arrayAppend(values, "" & val);
				}
				else {
					arrayAppend(values, getDefaultDisplayValue(arguments.settingName));
				}
			}
		}
		if(NOT arrayLen(values)){
			return getDefaultDisplayValue(arguments.settingName);
		}
		return (arrayLen(values) GT 1 ? "Multiple registrations: " : "") & arrayToList(values, ", ");
	}

	public boolean function fieldValuesMatch(required string settingName, required any expectedPayload, required any actualPayload){
		var expText = trim("" & arguments.expectedPayload);
		var actText = trim("" & arguments.actualPayload);
		if(NOT isJSON(expText) OR NOT isJSON(actText))
			return expText EQ actText;

		var expState = {};
		var actState = {};
		try {
			expState = deserializeJSON(expText);
			actState = deserializeJSON(actText);
		}
		catch(any e){
			return false;
		}

		if(NOT isStruct(expState) OR NOT structKeyExists(expState, "entries") OR NOT isStruct(actState) OR NOT structKeyExists(actState, "entries"))
			return false;

		if(structIsEmpty(expState.entries) AND structIsEmpty(actState.entries))
			return true;
		if(structIsEmpty(expState.entries) OR structIsEmpty(actState.entries))
			return false;

		var apiUtil = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init();
		var fieldMap = apiUtil.getFieldMap();
		var targetField = structKeyExists(fieldMap, arguments.settingName) ? fieldMap[arguments.settingName] : arguments.settingName;

		var expDsn = structKeyArray(expState.entries)[1];
		var actDsn = structKeyArray(actState.entries)[1];

		if(arguments.settingName EQ "dsnName")
			return compareNoCase(expDsn, actDsn) EQ 0;

		var expConfig = expState.entries[expDsn];
		var actConfig = actState.entries[actDsn];

		if(arguments.settingName EQ "driverName"){
			var expType = structKeyExists(expConfig, "type") ? expConfig.type : "mongodb";
			var actType = structKeyExists(actConfig, "type") ? actConfig.type : "mongodb";
			return compareNoCase(expType, actType) EQ 0;
		}

		var eVal = "";
		if(structKeyExists(expConfig, targetField)) eVal = expConfig[targetField];
		else if(structKeyExists(expConfig, uCase(targetField))) eVal = expConfig[uCase(targetField)];
		else if(structKeyExists(expConfig, lCase(targetField))) eVal = expConfig[lCase(targetField)];

		var aVal = "";
		if(structKeyExists(actConfig, targetField)) aVal = actConfig[targetField];
		else if(structKeyExists(actConfig, uCase(targetField))) aVal = actConfig[uCase(targetField)];
		else if(structKeyExists(actConfig, lCase(targetField))) aVal = actConfig[lCase(targetField)];

		if(listFindNoCase("ssl,dnsSeedList,j", targetField)){
			var eBool = isBoolean(eVal) ? (eVal ? true : false) : (listFindNoCase("true,yes,1,Enabled", "" & eVal) GT 0);
			var aBool = isBoolean(aVal) ? (aVal ? true : false) : (listFindNoCase("true,yes,1,Enabled", "" & aVal) GT 0);
			return eBool EQ aBool;
		}
		else if(listFindNoCase("port,wtimeout,connectTimeout,maxPoolSize,minPoolSize,maxConnectionLifeTime,maxConnectionIdleTime,maxWaitQueueTimeout,maxWaitQueueSize,heartbeatFrequency,minHeartbeatFrequency,maxStalenessSeconds", targetField)){
			return val(eVal) EQ val(aVal);
		}
		else if(compareNoCase(targetField, "password") EQ 0){
			return (len(trim(eVal)) EQ 0) EQ (len(trim(aVal)) EQ 0);
		}
		else {
			return compareNoCase(trim("" & eVal), trim("" & aVal)) EQ 0;
		}
	}

	public string function getTargetPayload(required string settingName, required any currentJsonStr){
		var apiUtil = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init();
		apiUtil.requireSetting(arguments.settingName);

		var dsnName = apiUtil.getTestDsnName();
		var baseConfig = apiUtil.getDefaultMongoConfig();



		var fieldMap = apiUtil.getFieldMap();
		var targetField = structKeyExists(fieldMap, arguments.settingName) ? fieldMap[arguments.settingName] : arguments.settingName;
		var currentVal = structKeyExists(baseConfig, targetField) ? baseConfig[targetField] : "";

		var nextVal = getNextFieldValue(arguments.settingName, currentVal);

		if(arguments.settingName EQ "dsnName"){
			var targetEntries = structNew("ordered");
			targetEntries[dsnName & "_Updated"] = baseConfig;
			return serializeJSON({entries=targetEntries});
		}
		else if(arguments.settingName NEQ "driverName"){
			baseConfig[targetField] = nextVal;
			if(arguments.settingName EQ "mongo_authMechanism"){
				baseConfig.username = "ccs_mongo_user";
				baseConfig.password = "ccs_mongo_pass";
			}
			else if(arguments.settingName EQ "mongo_authUsername"){
				baseConfig.authMechanism = "SCRAM-SHA-256";
				baseConfig.password = "ccs_mongo_pass";
			}
			else if(arguments.settingName EQ "mongo_maxStaleness"){
				baseConfig.readPreference = "secondary";
			}
		}

		var entries = structNew("ordered");
		entries[dsnName] = baseConfig;
		return serializeJSON({entries=entries});
	}

	private boolean function isCurrentPortNode(required string nodeKey){
		var currentPort = trim("" & CGI.SERVER_PORT);
		var parts = listToArray(arguments.nodeKey, "::", false, true);
		if(arrayLen(parts) LT 2)
			parts = listToArray(arguments.nodeKey, ":", false, true);
		if(arrayLen(parts) LT 2)
			return false;
		return val(parts[2]) EQ val(currentPort);
	}

	private string function getCurrentNodeKey(){
		var currentPort = trim("" & CGI.SERVER_PORT);
		if(structKeyExists(application, "ccsConfigMap")){
			for(var k in application.ccsConfigMap){
				var parts = listToArray(k, "::", false, true);
				if(arrayLen(parts) LT 2) parts = listToArray(k, ":", false, true);
				if(arrayLen(parts) GTE 2 AND val(parts[2]) EQ val(currentPort))
					return k;
			}
		}
		return CGI.SERVER_NAME & "::" & CGI.SERVER_PORT;
	}

	private boolean function isSameClusterNode(required string nodeKey){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		if(NOT structKeyExists(application, "ccsConfigMap"))
			return true;
		var currentKey = getCurrentNodeKey();
		if(NOT application.ccsConfigMap.keyExists(currentKey) OR NOT application.ccsConfigMap.keyExists(arguments.nodeKey))
			return true;
		var clusterKey = structKeyExists(application.constants, "CCS_CONFIG") AND structKeyExists(application.constants.CCS_CONFIG, "CLUSTER") ? application.constants.CCS_CONFIG.CLUSTER : "cluster";
		var envKey = structKeyExists(application.constants, "CCS_CONFIG") AND structKeyExists(application.constants.CCS_CONFIG, "ENVIRONMENT") ? application.constants.CCS_CONFIG.ENVIRONMENT : "environment";
		if(NOT structKeyExists(application.ccsConfigMap[currentKey], clusterKey) OR NOT structKeyExists(application.ccsConfigMap[arguments.nodeKey], clusterKey))
			return true;
		var currentCluster = application.ccsConfigMap[currentKey][clusterKey];
		var currentEnv = structKeyExists(application.ccsConfigMap[currentKey], envKey) ? application.ccsConfigMap[currentKey][envKey] : "";
		var nodeCluster = application.ccsConfigMap[arguments.nodeKey][clusterKey];
		var nodeEnv = structKeyExists(application.ccsConfigMap[arguments.nodeKey], envKey) ? application.ccsConfigMap[arguments.nodeKey][envKey] : "";
		return currentCluster EQ nodeCluster AND currentEnv EQ nodeEnv;
	}

	private struct function getNodeMetadataForKey(required string nodeKey){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		var cluster = "N/A";
		var env = "N/A";
		if(structKeyExists(application, "ccsConfigMap") AND application.ccsConfigMap.keyExists(arguments.nodeKey)){
			cluster = application.ccsConfigMap[arguments.nodeKey][application.constants.CCS_CONFIG.CLUSTER];
			env = application.ccsConfigMap[arguments.nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		}
		return {
			cluster = len(trim("" & cluster)) ? ("" & cluster) : "N/A",
			environment = len(trim("" & env)) ? ("" & env) : "N/A"
		};
	}

	private array function buildCurrentNodeRows(
		required struct initedTestFrame,
		required struct postSyncFrame,
		required struct existingValues,
		required string settingName,
		required any newSetValue
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var primeNodeKey = stUtil.getPresetNodeKeyFromFrame(arguments.initedTestFrame, arguments.settingName);
		var existing = structKeyExists(arguments.existingValues, primeNodeKey) ? arguments.existingValues[primeNodeKey] : "";
		var postVal = "";
		var setTypes = [application.testConstants.TEST_FRAME.PRIME_SET, application.testConstants.TEST_FRAME.NONPRIME_SET];
		for(var setType in setTypes){
			if(structKeyExists(arguments.postSyncFrame, setType) AND structKeyExists(arguments.postSyncFrame[setType], primeNodeKey)){
				var pair = arguments.postSyncFrame[setType][primeNodeKey];
				if(structKeyExists(pair, application.testConstants.TEST_FRAME.POSTSET_VALUE))
					postVal = pair[application.testConstants.TEST_FRAME.POSTSET_VALUE];
			}
		}
		var applied = fieldValuesMatch(arguments.settingName, arguments.newSetValue, postVal);
		var metadata = getNodeMetadataForKey(primeNodeKey);
		return [{
			nodeKey = primeNodeKey,
			nodeLabel = stUtil.getURLFragFromNodeKey(primeNodeKey),
			existingValue = formatDisplayValue(arguments.settingName, existing),
			updatedValue = formatDisplayValue(arguments.settingName, postVal),
			passed = applied,
			verificationStatus = applied ? "Passed" : "Failed",
			syncState = applied ? "Applied" : "Not applied",
			cluster = metadata.cluster,
			environment = metadata.environment,
			setType = application.testConstants.TEST_FRAME.PRIME_SET
		}];
	}

	private array function buildAllNodeRows(
		required struct postSyncFrame,
		required struct existingValues,
		required string settingName,
		required any newSetValue
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var rows = [];
		var setTypes = [application.testConstants.TEST_FRAME.PRIME_SET, application.testConstants.TEST_FRAME.NONPRIME_SET];
		for(var setType in setTypes){
			if(NOT structKeyExists(arguments.postSyncFrame, setType))
				continue;
			for(var nodeKey in arguments.postSyncFrame[setType].keyList()){
				var nodeData = arguments.postSyncFrame[setType][nodeKey];
				var preVal = structKeyExists(arguments.existingValues, nodeKey)
					? arguments.existingValues[nodeKey]
					: (structKeyExists(nodeData, application.testConstants.TEST_FRAME.PRESET_VALUE) ? nodeData[application.testConstants.TEST_FRAME.PRESET_VALUE] : "");
				var postVal = structKeyExists(nodeData, application.testConstants.TEST_FRAME.POSTSET_VALUE)
					? nodeData[application.testConstants.TEST_FRAME.POSTSET_VALUE] : "";

				var isCurrent = isCurrentPortNode(nodeKey);
				var isSameCluster = isSameClusterNode(nodeKey);
				var nodePassed = false;
				var syncState = "";

				if(isCurrent){
					nodePassed = fieldValuesMatch(arguments.settingName, arguments.newSetValue, postVal);
					syncState = nodePassed ? "Applied" : "Not applied";
				}
				else if(NOT isSameCluster){
					nodePassed = (trim("" & preVal) EQ trim("" & postVal)) OR fieldValuesMatch(arguments.settingName, preVal, postVal);
					syncState = "Different cluster/env";
				}
				else {
					nodePassed = fieldValuesMatch(arguments.settingName, arguments.newSetValue, postVal);
					syncState = nodePassed ? "Synced" : "Not synced with CCS";
				}

				var metadata = getNodeMetadataForKey(nodeKey);
				arrayAppend(rows, {
					nodeKey = nodeKey,
					nodeLabel = stUtil.getURLFragFromNodeKey(nodeKey),
					existingValue = formatDisplayValue(arguments.settingName, preVal),
					updatedValue = formatDisplayValue(arguments.settingName, postVal),
					passed = nodePassed,
					verificationStatus = nodePassed ? "Passed" : "Failed",
					syncState = syncState,
					cluster = metadata.cluster,
					environment = metadata.environment,
					setType = setType
				});
			}
		}
		arraySort(rows, function(a, b){
			return compare(a.nodeLabel, b.nodeLabel);
		});
		return rows;
	}

	public struct function runSyncTest(required any testDriver, required string settingName, required string scriptPath){
		var apiUtil = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();

		apiUtil.requireSupported(arguments.settingName);
		stUtil.initializeCcsNodeConfig("all");

		try {
			var cleanRuntime = apiUtil.getRuntime();
			try { cleanRuntime.api.deleteMongoDatasource(apiUtil.getTestDsnName()); } catch(any e){}
			try { cleanRuntime.api.deleteMongoDatasource(apiUtil.getTestDsnName() & "_Updated"); } catch(any e){}
			cleanRuntime.adminUtil.logout(cleanRuntime.admin);
		} catch(any e){}

		var initedTestFrame = stUtil.initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, false);
		var currentValue = stUtil.getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var existingValues = stUtil.collectPresetValuesFromFrame(initedTestFrame);

		var targetPayload = getTargetPayload(arguments.settingName, currentValue);

		var primeNode = stUtil.getPresetNodeKeyFromFrame(initedTestFrame, arguments.settingName);
		var primeLabel = stUtil.getURLFragFromNodeKey(primeNode);
		writeOutput("updating #arguments.settingName# to: #formatDisplayValue(arguments.settingName, targetPayload)# on prime node: #primeLabel#<br>");

		stUtil.initializeCcsNodeConfig("all");
		var syncResult = stUtil.runSyncTest(arguments.testDriver, initedTestFrame, arguments.settingName, targetPayload);

		var currentNodeRows = buildCurrentNodeRows(initedTestFrame, syncResult.postSyncFrame, existingValues, arguments.settingName, targetPayload);
		writeOutput("<b>Main node before and after update:</b><br><br>");
		stUtil.writeSyncVerificationTable(currentNodeRows, arguments.settingName, "Before Update", "After Update", true, {});

		writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
		var afterRows = buildAllNodeRows(syncResult.postSyncFrame, existingValues, arguments.settingName, targetPayload);
		stUtil.writeSyncVerificationTable(afterRows, arguments.settingName, "Existing Value", "Updated Value", true, {});

		var overallPassed = true;
		for(var row in afterRows){
			if(isSameClusterNode(row.nodeKey) AND NOT row.passed)
				overallPassed = false;
		}

		application.ccsTestNodesScope = "currentPort";

		return {
			passed = overallPassed,
			initedTestFrame = initedTestFrame,
			originalValue = currentValue,
			existingValues = existingValues,
			syncResult = syncResult,
			scriptPath = arguments.scriptPath,
			settingName = arguments.settingName
		};
	}

	public void function restoreSyncTest(required any testDriver, required struct syncTestResult, required string settingName){
		var apiUtil = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init();
		try {
			var runtime = apiUtil.getRuntime();
			try { runtime.api.deleteMongoDatasource(apiUtil.getTestDsnName()); } catch(any e){}
			try { runtime.api.deleteMongoDatasource(apiUtil.getTestDsnName() & "_Updated"); } catch(any e){}
			runtime.adminUtil.logout(runtime.admin);
		} catch(any e){}

		// Also clean up peer node in same cluster
		try {
			var cfSettingKey = arguments.settingName;
			var emptyPayload = serializeJSON({entries={}});
			var peerUrl = "http://localhost:8501/cfsuite/ccssuite/testsuite/DataServices/_setter.cfm?area=nosql&setting=" & urlEncodedFormat(cfSettingKey) & "&setValueTo=" & urlEncodedFormat(emptyPayload);
			var httpService = new http();
			httpService.setMethod("GET");
			httpService.setUrl(peerUrl);
			httpService.setTimeout(5);
			httpService.send();
		} catch(any e){}
	}
}
