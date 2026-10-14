/**
* Shared helpers for AIservices testsuite CFM pages.
*/
component output="true" {

	variables.LLM_TEST_ALIAS = "CCSTestLLM";
	variables.EMBEDDING_TEST_ALIAS = "CCSTestEmbedding";
	variables.VECTORSTORE_TEST_ALIAS = "CCSTestVectorStore";
	variables.FIELD_NAME_TIMEOUT = "timeout";

	public function init(){
		return this;
	}

	public string function getLLMTestAlias(){
		return variables.LLM_TEST_ALIAS;
	}

	public string function getEmbeddingTestAlias(){
		return variables.EMBEDDING_TEST_ALIAS;
	}

	public string function getVectorStoreTestAlias(){
		return variables.VECTORSTORE_TEST_ALIAS;
	}

	public struct function sortStructKeys(required struct data){
		return new cfsuite.ccssuite.utils.llmConfigUtil().init().sortStructKeys(arguments.data);
	}

	public struct function initTestFrame(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		return new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().initTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
	}

	public struct function initAiSyncTestFrame(
		required any testDriver,
		required string alias,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		if(isAiTestAlias(arguments.alias)){
			stUtil.initializeCcsNodeConfig("all");
			deleteAiTestAliasOnAllNodes(
				arguments.testDriver,
				arguments.alias,
				arguments.scriptPath,
				arguments.skipUnreachableNodes
			);
		}
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var initedTestFrame = initTestFrame(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		return {
			initedTestFrame = initedTestFrame,
			originalValue = isAiTestAlias(arguments.alias)
				? ""
				: getPresetValueFromFrame(initedTestFrame, arguments.alias)
		};
	}

	public struct function prepareAiFieldSyncTest(
		required any testDriver,
		required string alias,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var apiArea = getApiAreaFromScriptPath(arguments.scriptPath);
		var prepared = initAiSyncTestFrame(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		if(NOT isEmptyAiSettingValue(prepared.originalValue, apiArea))
			return prepared;

		var defaultValue = encodeDefaultConfigForArea(apiArea);
		arguments.testDriver.setAndGetSyncedValues(
			duplicate(prepared.initedTestFrame),
			defaultValue,
			arguments.alias
		);
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var seededFrame = initTestFrame(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);

		return {
			initedTestFrame = seededFrame,
			originalValue = getPresetValueFromFrame(seededFrame, arguments.alias)
		};
	}

	private string function encodeDefaultConfigForArea(required string apiArea){
		if(lCase(arguments.apiArea) EQ "embeddingmodels")
			return encodeEmbeddingConfig(getDefaultEmbeddingConfig());
		if(listFindNoCase("vectorstores,RAG", arguments.apiArea))
			return encodeVectorStoreConfig(getDefaultVectorStoreConfig());
		return encodeLLMConfig(getDefaultLLMConfig());
	}

	public any function getPresetValueFromFrame(required struct testFrame, string settingName = ""){
		return new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().getPresetValueFromFrame(
			arguments.testFrame,
			arguments.settingName
		);
	}

	public struct function runSyncTest(
		required any testDriver,
		required struct initedTestFrame,
		required string settingName,
		required any newSetValue
	){
		return new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().runSyncTest(
			arguments.testDriver,
			arguments.initedTestFrame,
			arguments.settingName,
			arguments.newSetValue
		);
	}

	public void function restoreTest(required any testDriver, required struct initedTestFrame, required any originalValue, required string settingName){
		new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().restoreTest(
			arguments.testDriver,
			arguments.initedTestFrame,
			arguments.originalValue,
			arguments.settingName
		);
	}

	public string function getQatestResultMessage(required boolean passed){
		return new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().getQatestResultMessage(arguments.passed);
	}

	public struct function getDefaultLLMConfig(){
		return {
			"provider": "openai",
			"modelName": "gpt-4-test",
			"baseUrl": "https://api.openai.com",
			"organizationId": "test-org-id",
			"projectId": "test-project-id",
			"temperature": 0.7,
			"maxTokens": 1024,
			"topP": 0.9,
			"presencePenalty": 0,
			"seed": 42,
			"responseFormat": "default",
			"stopSequences": "END",
			"frequencyPenalty": 0,
			"logitBias": "{}",
			"maxRetries": 3,
			"timeout": 45,
			"userId": "test-user-id",
			"logRequests": false,
			"logResponses": false,
			"parallelToolCalls": false,
			"strictJsonSchema": false,
			"metadata": '{"env":"dev"}',
			"httpClient": {
				"PROXY": {
					"host": "127.0.0.1",
					"port": 8888,
					"user": "testproxyuser",
					"pass": "testproxypassword"
				}
			}
		};
	}

	private struct function decodeLLMConfig(required any settingValue){
		var llmUtil = new cfsuite.ccssuite.utils.llmConfigUtil().init();
		var raw = trim("" & arguments.settingValue);
		if(NOT len(raw))
			return {};
		return llmUtil.decodeConfigValue(raw);
	}

	private string function encodeLLMConfig(required struct config){
		return new cfsuite.ccssuite.utils.llmConfigUtil().init().encodeConfigValue(arguments.config);
	}

	public any function getTestValueForLLMField(required string fieldName, struct baseConfig = {}){
		var key = lCase(trim(arguments.fieldName));
		if(compareNoCase(key, variables.FIELD_NAME_TIMEOUT) EQ 0) return 60;
		switch(key){
			case "provider":
				return (structKeyExists(arguments.baseConfig, "provider") AND lCase(trim("" & arguments.baseConfig.provider)) EQ "openai") ? "anthropic" : "openai";
			case "modelname":
				return toggleStringMarker(structKeyExists(arguments.baseConfig, "modelName") ? arguments.baseConfig.modelName : "gpt-4-test", "_ccs");
			case "apikey":
				return "test-api-key-ccs";
			case "baseurl":
				return "https://api.openai.com/v1";
			case "organizationid":
				return toggleStringMarker(structKeyExists(arguments.baseConfig, "organizationId") ? arguments.baseConfig.organizationId : "test-org-id", "_ccs");
			case "projectid":
				return toggleStringMarker(structKeyExists(arguments.baseConfig, "projectId") ? arguments.baseConfig.projectId : "test-project-id", "_ccs");
			case "temperature":
				return 0.85;
			case "maxtokens":
				return 2048;
			case "topp":
				return 0.95;
			case "presencepenalty":
				return 0.5;
			case "seed":
				return 99;
			case "responseformat":
				return (structKeyExists(arguments.baseConfig, "responseFormat") AND lCase(trim("" & arguments.baseConfig.responseFormat)) EQ "json") ? "default" : "json";
			case "stopsequences":
				return "END,STOP";
			case "frequencypenalty":
				return 0.5;
			case "logitbias":
				return '{"50256":-100}';
			case "proxyhost":
				return "10.0.0.1";
			case "proxyport":
				return 9090;
			case "proxyusername":
				return "proxyuser_ccs";
			case "proxypassword":
				return "proxypass_ccs";
			case "maxretries":
				return 5;
			case "userid":
				return toggleStringMarker(structKeyExists(arguments.baseConfig, "userId") ? arguments.baseConfig.userId : "test-user-id", "_ccs");
			case "logrequests":
				return flipBoolean(structKeyExists(arguments.baseConfig, "logRequests") ? arguments.baseConfig.logRequests : false);
			case "logresponses":
				return flipBoolean(structKeyExists(arguments.baseConfig, "logResponses") ? arguments.baseConfig.logResponses : false);
			case "paralleltoolcalls":
				return flipBoolean(structKeyExists(arguments.baseConfig, "parallelToolCalls") ? arguments.baseConfig.parallelToolCalls : false);
			case "strictjsonschema":
				return flipBoolean(structKeyExists(arguments.baseConfig, "strictJsonSchema") ? arguments.baseConfig.strictJsonSchema : false);
			case "metadata":
				return '{"env":"test"}';
			default:
				throw(message="Unsupported LLM field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
	}

	public struct function applyLLMFieldValue(required struct config, required string fieldName, required any fieldValue){
		var updated = duplicate(arguments.config);
		var key = lCase(trim(arguments.fieldName));
		if(compareNoCase(key, variables.FIELD_NAME_TIMEOUT) EQ 0){
			updated.timeout = arguments.fieldValue;
			return updated;
		}
		switch(key){
			case "provider":
				updated.provider = arguments.fieldValue;
				break;
			case "modelname":
				updated.modelName = arguments.fieldValue;
				break;
			case "apikey":
				updated.apiKey = arguments.fieldValue;
				break;
			case "baseurl":
				updated.baseUrl = arguments.fieldValue;
				break;
			case "organizationid":
				updated.organizationId = arguments.fieldValue;
				break;
			case "projectid":
				updated.projectId = arguments.fieldValue;
				break;
			case "temperature":
				updated.temperature = arguments.fieldValue;
				break;
			case "maxtokens":
				updated.maxTokens = arguments.fieldValue;
				break;
			case "topp":
				updated.topP = arguments.fieldValue;
				break;
			case "presencepenalty":
				updated.presencePenalty = arguments.fieldValue;
				break;
			case "seed":
				updated.seed = arguments.fieldValue;
				break;
			case "responseformat":
				updated.responseFormat = arguments.fieldValue;
				break;
			case "stopsequences":
				updated.stopSequences = arguments.fieldValue;
				break;
			case "frequencypenalty":
				updated.frequencyPenalty = arguments.fieldValue;
				break;
			case "logitbias":
				updated.logitBias = arguments.fieldValue;
				break;
			case "proxyhost":
				ensureProxyStruct(updated).host = arguments.fieldValue;
				break;
			case "proxyport":
				ensureProxyStruct(updated).port = arguments.fieldValue;
				break;
			case "proxyusername":
				ensureProxyStruct(updated).user = arguments.fieldValue;
				break;
			case "proxypassword":
				ensureProxyStruct(updated).pass = arguments.fieldValue;
				break;
			case "maxretries":
				updated.maxRetries = arguments.fieldValue;
				break;
			case "userid":
				updated.userId = arguments.fieldValue;
				break;
			case "logrequests":
				updated.logRequests = arguments.fieldValue;
				break;
			case "logresponses":
				updated.logResponses = arguments.fieldValue;
				break;
			case "paralleltoolcalls":
				updated.parallelToolCalls = arguments.fieldValue;
				break;
			case "strictjsonschema":
				updated.strictJsonSchema = arguments.fieldValue;
				break;
			case "metadata":
				updated.metadata = arguments.fieldValue;
				break;
			default:
				throw(message="Unsupported LLM field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
		return updated;
	}

	public struct function buildLLMConfigForField(required string fieldName, any currentValue = ""){
		var baseConfig = getDefaultLLMConfig();
		var existing = decodeLLMConfig(arguments.currentValue);
		if(NOT structIsEmpty(existing))
			structAppend(baseConfig, existing, true);
		var testValue = getTestValueForLLMField(arguments.fieldName, baseConfig);
		return applyLLMFieldValue(baseConfig, arguments.fieldName, testValue);
	}

	public struct function runLLMFieldSyncTest(
		required any testDriver,
		required string alias,
		required string fieldName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var prepared = prepareAiFieldSyncTest(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var initedTestFrame = prepared.initedTestFrame;
		var originalValue = prepared.originalValue;
		var newConfig = buildLLMConfigForField(arguments.fieldName, originalValue);
		var newSetValue = encodeLLMConfig(newConfig);
		var expectedFieldValue = extractConfigFieldValue(newConfig, arguments.fieldName);

		return runMultiNodeLLMSyncTest(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			false,
			arguments.fieldName,
			""
		);
	}

	public struct function runFullLLMSyncTest(
		required any testDriver,
		required string alias,
		required string scriptPath,
		struct configOverrides = {},
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var prepared = initAiSyncTestFrame(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var initedTestFrame = prepared.initedTestFrame;
		var config = getDefaultLLMConfig();
		structAppend(config, arguments.configOverrides, true);
		config.apiKey = "test-api-key-12345";
		var newSetValue = encodeLLMConfig(config);

		return runMultiNodeLLMSyncTest(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			false,
			"",
			prepared.originalValue
		);
	}

	public struct function runMultiNodeLLMSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		required any newSetValue,
		required struct initedTestFrame,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all",
		boolean showEmptyNodes = false,
		string fieldName = "",
		any capturedOriginalValue = ""
	){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		var existingValues = stUtil.collectPresetValuesFromFrame(
			initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes)
		);

		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var syncTestFrame = initTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var apiArea = structKeyExists(syncTestFrame, application.testConstants.TEST_FRAME.API_AREA)
			? syncTestFrame[application.testConstants.TEST_FRAME.API_AREA]
			: "LLMs";
		var originalValue = isAiTestAlias(arguments.settingName)
			? arguments.capturedOriginalValue
			: (len(trim("" & arguments.capturedOriginalValue))
				? arguments.capturedOriginalValue
				: getPresetValueFromFrame(syncTestFrame, arguments.settingName));
		if(isAiTestAlias(arguments.settingName) AND isEmptyAiSettingValue(originalValue, apiArea))
			originalValue = "";

		writeAiSyncUpdateMessage(
			arguments.settingName,
			arguments.fieldName,
			arguments.newSetValue,
			syncTestFrame,
			apiArea,
			arguments.nodesScope
		);

		var syncResult = runLLMSyncTest(
			arguments.testDriver,
			syncTestFrame,
			arguments.settingName,
			arguments.newSetValue,
			arguments.fieldName
		);
		var showAllNodes = arguments.nodesScope EQ "all" OR arguments.showEmptyNodes;

		stUtil.writeSyncVerificationTable(
			buildCurrentNodeAiVerificationRows(
				syncTestFrame,
				syncResult,
				existingValues,
				arguments.newSetValue,
				apiArea,
				arguments.fieldName,
				arguments.settingName
			),
			arguments.settingName,
			"Existing Value",
			"New Value"
		);

		if(syncResult.passed){
			// Re-check under the test's OWN requested scope, not a hardcoded "all" — see the
			// matching comment in serverSettingsTestUtil.runMultiNodeSettingSyncTest. ColdFusion
			// Collections (the one caller here that requests nodesScope="currentPort") is backed by
			// an external Solr server that, in this environment, all CF instances happen to share —
			// so re-querying peers under "all" scope made them look synced when nothing was ever
			// pushed to them; they were just seeing the same shared resource.
			stUtil.initializeCcsNodeConfig(arguments.nodesScope);
			var afterFrame = initTestFrame(
				arguments.testDriver,
				arguments.settingName,
				arguments.scriptPath,
				arguments.skipUnreachableNodes
			);
			// Restore full cluster metadata for display now that afterFrame is already built under
			// the requested (possibly narrower) scope — see the matching comment in
			// serverSettingsTestUtil.runMultiNodeSettingSyncTest. initializeCcsNodeConfig() also
			// overwrites the ccsTestNodesScope flag itself, so restore the test's actual requested
			// scope afterward — buildAllNodeAiVerificationRows reads that flag.
			stUtil.initializeCcsNodeConfig("all", true);
			application.ccsTestNodesScope = arguments.nodesScope;
			writeOutput("<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
			stUtil.applyExistingPresetValuesToFrame(afterFrame, existingValues);
			stUtil.writeSyncVerificationTable(
				buildAllNodeAiVerificationRows(
					afterFrame,
					existingValues,
					arguments.newSetValue,
					apiArea,
					arguments.fieldName,
					showAllNodes
				),
				arguments.settingName
			);
		}

		application.ccsTestNodesScope = "currentPort";

		return {
			passed = syncResult.passed,
			initedTestFrame = syncTestFrame,
			originalValue = originalValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath
		};
	}

	public struct function runLLMSyncTest(
		required any testDriver,
		required struct initedTestFrame,
		required string settingName,
		required any newSetValue,
		string fieldName = ""
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var postSyncFrame = arguments.testDriver.setAndGetSyncedValues(
			duplicate(arguments.initedTestFrame),
			arguments.newSetValue,
			arguments.settingName
		);
		var apiArea = structKeyExists(arguments.initedTestFrame, application.testConstants.TEST_FRAME.API_AREA)
			? arguments.initedTestFrame[application.testConstants.TEST_FRAME.API_AREA]
			: "LLMs";
		var rows = buildAiVerificationRows(postSyncFrame, arguments.newSetValue, apiArea, arguments.fieldName, true);
		var passed = arrayLen(rows) GT 0;
		for(var row in rows){
			if(NOT row.passed){
				passed = false;
				break;
			}
		}
		var expectedPostSetFrame = arguments.testDriver.getExpectedTestFrame(
			duplicate(arguments.initedTestFrame),
			arguments.newSetValue
		);
		return {
			postSyncFrame = postSyncFrame,
			expectedPostSetFrame = expectedPostSetFrame,
			passed = passed
		};
	}

	public void function restoreLLMSyncTest(required any testDriver, required struct syncTestResult, required string alias){
		restoreAiConfigSyncTest(arguments.testDriver, arguments.syncTestResult, arguments.alias);
	}

	public struct function getDefaultEmbeddingConfig(){
		return {
			"provider": "openai",
			"modelName": "text-embedding-3-small",
			"baseUrl": "https://api.openai.com",
			"dimension": 1536,
			"batchSize": 100,
			"organizationId": "test-org-id",
			"projectId": "test-project-id",
			"user": "test-user-id",
			"maxRetries": 3,
			"timeout": 60000,
			"logRequests": false,
			"logResponses": false
		};
	}

	private struct function decodeEmbeddingConfig(required any settingValue){
		return new cfsuite.ccssuite.utils.embeddingConfigUtil().init().decodeConfigValue(arguments.settingValue);
	}

	private string function encodeEmbeddingConfig(required struct config){
		return new cfsuite.ccssuite.utils.embeddingConfigUtil().init().encodeConfigValue(arguments.config);
	}

	public any function getTestValueForEmbeddingField(required string fieldName, struct baseConfig = {}){
		var key = lCase(trim(arguments.fieldName));
		if(compareNoCase(key, variables.FIELD_NAME_TIMEOUT) EQ 0) return 90000;
		switch(key){
			case "provider":
				return (structKeyExists(arguments.baseConfig, "provider") AND lCase(trim("" & arguments.baseConfig.provider)) EQ "openai") ? "azureopenai" : "openai";
			case "apikey":
				return "test-embedding-api-key-ccs";
			case "modelname":
				return toggleStringMarker(structKeyExists(arguments.baseConfig, "modelName") ? arguments.baseConfig.modelName : "text-embedding-3-small", "_ccs");
			case "baseurl":
				return "https://api.openai.com/v1";
			case "dimension":
				return 3072;
			case "organizationid":
				return toggleStringMarker(structKeyExists(arguments.baseConfig, "organizationId") ? arguments.baseConfig.organizationId : "test-org-id", "_ccs");
			case "projectid":
				return toggleStringMarker(structKeyExists(arguments.baseConfig, "projectId") ? arguments.baseConfig.projectId : "test-project-id", "_ccs");
			case "user":
				return toggleStringMarker(structKeyExists(arguments.baseConfig, "user") ? arguments.baseConfig.user : "test-user-id", "_ccs");
			case "batchsize":
				return 200;
			case "maxretries":
				return 5;
			case "logrequests":
				return flipBoolean(structKeyExists(arguments.baseConfig, "logRequests") ? arguments.baseConfig.logRequests : false);
			case "logresponses":
				return flipBoolean(structKeyExists(arguments.baseConfig, "logResponses") ? arguments.baseConfig.logResponses : false);
			default:
				throw(message="Unsupported embedding field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
	}

	public struct function applyEmbeddingFieldValue(required struct config, required string fieldName, required any fieldValue){
		var updated = duplicate(arguments.config);
		var key = lCase(trim(arguments.fieldName));
		if(compareNoCase(key, variables.FIELD_NAME_TIMEOUT) EQ 0){
			updated.timeout = arguments.fieldValue;
			return updated;
		}
		switch(key){
			case "provider": updated.provider = arguments.fieldValue; break;
			case "apikey": updated.apiKey = arguments.fieldValue; break;
			case "modelname": updated.modelName = arguments.fieldValue; break;
			case "baseurl": updated.baseUrl = arguments.fieldValue; break;
			case "dimension": updated.dimension = arguments.fieldValue; break;
			case "organizationid": updated.organizationId = arguments.fieldValue; break;
			case "projectid": updated.projectId = arguments.fieldValue; break;
			case "user": updated.user = arguments.fieldValue; break;
			case "batchsize": updated.batchSize = arguments.fieldValue; break;
			case "maxretries": updated.maxRetries = arguments.fieldValue; break;
			case "logrequests": updated.logRequests = arguments.fieldValue; break;
			case "logresponses": updated.logResponses = arguments.fieldValue; break;
			default:
				throw(message="Unsupported embedding field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
		return updated;
	}

	public struct function buildEmbeddingConfigForField(required string fieldName, any currentValue = ""){
		var baseConfig = getDefaultEmbeddingConfig();
		var existing = decodeEmbeddingConfig(arguments.currentValue);
		if(NOT structIsEmpty(existing))
			structAppend(baseConfig, existing, true);
		var testValue = getTestValueForEmbeddingField(arguments.fieldName, baseConfig);
		return applyEmbeddingFieldValue(baseConfig, arguments.fieldName, testValue);
	}

	public struct function runEmbeddingFieldSyncTest(
		required any testDriver,
		required string alias,
		required string fieldName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var prepared = prepareAiFieldSyncTest(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var initedTestFrame = prepared.initedTestFrame;
		var originalValue = prepared.originalValue;
		var newConfig = buildEmbeddingConfigForField(arguments.fieldName, originalValue);
		var newSetValue = encodeEmbeddingConfig(newConfig);
		var expectedFieldValue = extractConfigFieldValue(newConfig, arguments.fieldName);

		return runMultiNodeLLMSyncTest(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			false,
			arguments.fieldName,
			""
		);
	}

	public struct function runFullEmbeddingSyncTest(
		required any testDriver,
		required string alias,
		required string scriptPath,
		struct configOverrides = {},
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var prepared = initAiSyncTestFrame(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var initedTestFrame = prepared.initedTestFrame;
		var config = getDefaultEmbeddingConfig();
		structAppend(config, arguments.configOverrides, true);
		config.apiKey = "test-embedding-api-key-12345";
		config.modelName = "text-embedding-3-small-ccs-full";
		config.dimension = 3072;
		var newSetValue = encodeEmbeddingConfig(config);

		return runMultiNodeLLMSyncTest(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			false,
			"",
			prepared.originalValue
		);
	}

	public void function restoreEmbeddingSyncTest(required any testDriver, required struct syncTestResult, required string alias){
		restoreAiConfigSyncTest(arguments.testDriver, arguments.syncTestResult, arguments.alias);
	}

	public struct function getDefaultVectorStoreConfig(){
		return {
			"provider": "milvus",
			"url": "http://localhost:19530",
			"dimension": 1536,
			"collectionName": "default",
			"databaseName": "default",
			"metricType": "COSINE",
			"indexType": "HNSW",
			"apiKey": "",
			"username": "",
			"password": "",
			"topK": 100,
			"minScore": 0,
			"embeddingModel": "",
			"connectionSettings": {
				"callTimeout": 60000,
				"connectionTimeout": 20000,
				"keepAlive": true,
				"keepAliveTime": 30000,
				"keepAliveTimeout": 5000,
				"idleTimeout": 600000,
				"deadline": 0
			},
			"retrySettings": {
				"maxRetries": 3,
				"retryOnRateLimit": true,
				"initialBackoff": 200,
				"maxBackoff": 1000,
				"backOffMultiplier": 2
			}
		};
	}

	private struct function decodeVectorStoreConfig(required any settingValue){
		return new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().decodeConfigValue(arguments.settingValue);
	}

	private string function encodeVectorStoreConfig(required struct config){
		return new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().encodeConfigValue(arguments.config);
	}

	private struct function ensureConnectionSettingsStruct(required struct config){
		if(NOT structKeyExists(arguments.config, "connectionSettings") OR NOT isStruct(arguments.config.connectionSettings))
			arguments.config.connectionSettings = duplicate(getDefaultVectorStoreConfig().connectionSettings);
		return arguments.config.connectionSettings;
	}

	private struct function ensureRetrySettingsStruct(required struct config){
		if(NOT structKeyExists(arguments.config, "retrySettings") OR NOT isStruct(arguments.config.retrySettings))
			arguments.config.retrySettings = duplicate(getDefaultVectorStoreConfig().retrySettings);
		return arguments.config.retrySettings;
	}

	public any function getTestValueForVectorStoreField(required string fieldName, struct baseConfig = {}){
		var key = lCase(trim(arguments.fieldName));
		switch(key){
			case "provider":
				return (structKeyExists(arguments.baseConfig, "provider") AND lCase(trim("" & arguments.baseConfig.provider)) EQ "milvus") ? "qdrant" : "milvus";
			case "url":
				return "http://127.0.0.1:19530";
			case "dimension":
				return 3072;
			case "collectionname":
				return toggleStringMarker(structKeyExists(arguments.baseConfig, "collectionName") ? arguments.baseConfig.collectionName : "default", "_ccs");
			case "databasename":
				return toggleStringMarker(structKeyExists(arguments.baseConfig, "databaseName") ? arguments.baseConfig.databaseName : "default", "_ccs");
			case "metrictype":
				return (structKeyExists(arguments.baseConfig, "metricType") AND uCase(trim("" & arguments.baseConfig.metricType)) EQ "COSINE") ? "L2" : "COSINE";
			case "indextype":
				return (structKeyExists(arguments.baseConfig, "indexType") AND uCase(trim("" & arguments.baseConfig.indexType)) EQ "HNSW") ? "IVF_FLAT" : "HNSW";
			case "apikey":
				return "test-vectorstore-api-key-ccs";
			case "username":
				return "test-vs-user_ccs";
			case "password":
				return "test-vs-pass_ccs";
			case "topk":
				return 10;
			case "minscore":
				return 0.75;
			case "embeddingmodel":
				return "CCSTestEmbedding";
			case "calltimeout":
				return 90000;
			case "connectiontimeout":
				return 30000;
			case "keepalive":
				return flipBoolean(getVectorStoreConnectionField(arguments.baseConfig, "keepAlive", true));
			case "keepalivetime":
				return 45000;
			case "keepalivetimeout":
				return 8000;
			case "idletimeout":
				return 900000;
			case "deadline":
				return 1000;
			case "maxretries":
				return 5;
			case "retryonratelimit":
				return flipBoolean(getVectorStoreRetryField(arguments.baseConfig, "retryOnRateLimit", true));
			case "initialbackoff":
				return 400;
			case "maxbackoff":
				return 2000;
			case "backoffmultiplier":
				return 3;
			default:
				throw(message="Unsupported vector store field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
	}

	private any function getVectorStoreConnectionField(required struct baseConfig, required string fieldName, any defaultValue = ""){
		if(structKeyExists(arguments.baseConfig, "connectionSettings")
			AND isStruct(arguments.baseConfig.connectionSettings)
			AND structKeyExists(arguments.baseConfig.connectionSettings, arguments.fieldName))
			return arguments.baseConfig.connectionSettings[arguments.fieldName];
		return arguments.defaultValue;
	}

	private any function getVectorStoreRetryField(required struct baseConfig, required string fieldName, any defaultValue = ""){
		if(structKeyExists(arguments.baseConfig, "retrySettings")
			AND isStruct(arguments.baseConfig.retrySettings)
			AND structKeyExists(arguments.baseConfig.retrySettings, arguments.fieldName))
			return arguments.baseConfig.retrySettings[arguments.fieldName];
		return arguments.defaultValue;
	}

	public struct function applyVectorStoreFieldValue(required struct config, required string fieldName, required any fieldValue){
		var updated = duplicate(arguments.config);
		var key = lCase(trim(arguments.fieldName));
		switch(key){
			case "provider": updated.provider = arguments.fieldValue; break;
			case "url": updated.url = arguments.fieldValue; break;
			case "dimension": updated.dimension = arguments.fieldValue; break;
			case "collectionname": updated.collectionName = arguments.fieldValue; break;
			case "databasename": updated.databaseName = arguments.fieldValue; break;
			case "metrictype": updated.metricType = arguments.fieldValue; break;
			case "indextype": updated.indexType = arguments.fieldValue; break;
			case "apikey": updated.apiKey = arguments.fieldValue; break;
			case "username": updated.username = arguments.fieldValue; break;
			case "password": updated.password = arguments.fieldValue; break;
			case "topk": updated.topK = arguments.fieldValue; break;
			case "minscore": updated.minScore = arguments.fieldValue; break;
			case "embeddingmodel": updated.embeddingModel = arguments.fieldValue; break;
			case "calltimeout": ensureConnectionSettingsStruct(updated).callTimeout = arguments.fieldValue; break;
			case "connectiontimeout": ensureConnectionSettingsStruct(updated).connectionTimeout = arguments.fieldValue; break;
			case "keepalive": ensureConnectionSettingsStruct(updated).keepAlive = arguments.fieldValue; break;
			case "keepalivetime": ensureConnectionSettingsStruct(updated).keepAliveTime = arguments.fieldValue; break;
			case "keepalivetimeout": ensureConnectionSettingsStruct(updated).keepAliveTimeout = arguments.fieldValue; break;
			case "idletimeout": ensureConnectionSettingsStruct(updated).idleTimeout = arguments.fieldValue; break;
			case "deadline": ensureConnectionSettingsStruct(updated).deadline = arguments.fieldValue; break;
			case "maxretries": ensureRetrySettingsStruct(updated).maxRetries = arguments.fieldValue; break;
			case "retryonratelimit": ensureRetrySettingsStruct(updated).retryOnRateLimit = arguments.fieldValue; break;
			case "initialbackoff": ensureRetrySettingsStruct(updated).initialBackoff = arguments.fieldValue; break;
			case "maxbackoff": ensureRetrySettingsStruct(updated).maxBackoff = arguments.fieldValue; break;
			case "backoffmultiplier": ensureRetrySettingsStruct(updated).backOffMultiplier = arguments.fieldValue; break;
			default:
				throw(message="Unsupported vector store field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
		return updated;
	}

	/**
	* coldfusion.server.VectorStoreService validates each provider against its own field
	* schema (e.g. Milvus accepts databaseName/indexType/metricType; Qdrant and InMemory
	* reject them as "Unknown Field"). The provider field test toggles the actual provider,
	* so it must use only fields every provider we toggle between accepts — the full default
	* config (which is Milvus-shaped) would get rejected the moment it's saved under qdrant.
	*/
	private string function getMinimalCrossProviderVectorStoreFieldList(){
		return "provider,url,dimension,collectionName,topK,minScore";
	}

	private struct function restrictToMinimalCrossProviderFields(required struct config){
		var allowed = getMinimalCrossProviderVectorStoreFieldList();
		var result = {};
		for(var key in arguments.config){
			if(listFindNoCase(allowed, key))
				result[key] = arguments.config[key];
		}
		return result;
	}

	public struct function buildVectorStoreConfigForField(required string fieldName, any currentValue = ""){
		var baseConfig = getDefaultVectorStoreConfig();
		var existing = decodeVectorStoreConfig(arguments.currentValue);
		if(NOT structIsEmpty(existing))
			structAppend(baseConfig, existing, true);
		if(lCase(trim(arguments.fieldName)) EQ "provider")
			baseConfig = restrictToMinimalCrossProviderFields(baseConfig);
		var testValue = getTestValueForVectorStoreField(arguments.fieldName, baseConfig);
		return applyVectorStoreFieldValue(baseConfig, arguments.fieldName, testValue);
	}

	public struct function runVectorStoreFieldSyncTest(
		required any testDriver,
		required string alias,
		required string fieldName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var prepared = prepareAiFieldSyncTest(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var initedTestFrame = prepared.initedTestFrame;
		var originalValue = prepared.originalValue;
		var newConfig = buildVectorStoreConfigForField(arguments.fieldName, originalValue);
		var newSetValue = encodeVectorStoreConfig(newConfig);
		var expectedFieldValue = extractConfigFieldValue(newConfig, arguments.fieldName);

		return runMultiNodeLLMSyncTest(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			false,
			arguments.fieldName,
			""
		);
	}

	public struct function runFullVectorStoreSyncTest(
		required any testDriver,
		required string alias,
		required string scriptPath,
		struct configOverrides = {},
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var prepared = initAiSyncTestFrame(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			arguments.skipUnreachableNodes,
			arguments.nodesScope
		);
		var initedTestFrame = prepared.initedTestFrame;
		var config = getDefaultVectorStoreConfig();
		structAppend(config, arguments.configOverrides, true);
		config.apiKey = "test-vectorstore-api-key-12345";
		config.url = "http://127.0.0.1:19530";
		config.collectionName = "ccs-test-collection";
		var newSetValue = encodeVectorStoreConfig(config);

		return runMultiNodeLLMSyncTest(
			arguments.testDriver,
			arguments.alias,
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			false,
			"",
			prepared.originalValue
		);
	}

	public void function restoreVectorStoreSyncTest(required any testDriver, required struct syncTestResult, required string alias){
		restoreAiConfigSyncTest(arguments.testDriver, arguments.syncTestResult, arguments.alias);
	}

	/**
	* mcpServers has no per-item alias — the whole flat server-name-keyed map is one setting,
	* so this mirrors runFullVectorStoreSyncTest without the alias seed/delete machinery.
	*/
	public struct function getDefaultMcpServerConfig(){
		return {
			"ccs-test-filesystem-server": {
				"command": "npx",
				"args": ["-y", "@modelcontextprotocol/server-filesystem", "C:/ColdFusion2025/cfusion/wwwroot"],
				"commandWhitelist": ["npx"],
				"env": {
					"SOME_ENV_VARIABLE": "test-val"
				}
			},
			"ccs-test-http-server": {
				"url": "http://127.0.0.1:3000/sse",
				"headers": {
					"Authorization": "Bearer my-secret-token"
				}
			}
		};
	}

	private string function encodeMcpServerConfig(required struct config){
		return new cfsuite.ccssuite.utils.mcpConfigUtil().init().encodeConfigValue(arguments.config);
	}

	public struct function runFullMcpServerSyncTest(
		required any testDriver,
		required string scriptPath,
		struct configOverrides = {},
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		stUtil.initializeCcsNodeConfig(arguments.nodesScope);
		var settingName = "mcpServers";
		var initedTestFrame = initTestFrame(arguments.testDriver, settingName, arguments.scriptPath, arguments.skipUnreachableNodes);
		var originalValue = getPresetValueFromFrame(initedTestFrame, settingName);

		var config = getDefaultMcpServerConfig();
		structAppend(config, arguments.configOverrides, true);
		var newSetValue = encodeMcpServerConfig(config);

		return runMultiNodeLLMSyncTest(
			arguments.testDriver,
			settingName,
			arguments.scriptPath,
			newSetValue,
			initedTestFrame,
			arguments.skipUnreachableNodes,
			arguments.nodesScope,
			false,
			"",
			originalValue
		);
	}

	public void function restoreMcpServerSyncTest(required any testDriver, required struct syncTestResult){
		restoreAiConfigSyncTest(arguments.testDriver, arguments.syncTestResult, "mcpServers");
	}

	private void function restoreAiConfigSyncTest(required any testDriver, required struct syncTestResult, required string alias){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		if(NOT structKeyExists(arguments.syncTestResult, "originalValue")){
			application.ccsTestNodesScope = "currentPort";
			return;
		}

		var scriptPath = structKeyExists(arguments.syncTestResult, "scriptPath")
			? arguments.syncTestResult.scriptPath
			: "/cfsuite/ccssuite/testsuite/AIservices/embeddingModels/embeddingConfig.cfm";
		var apiArea = getApiAreaFromScriptPath(scriptPath);
		var originalValue = arguments.syncTestResult.originalValue;

		stUtil.initializeCcsNodeConfig("all");
		if(isAiTestAlias(arguments.alias) AND isEmptyAiSettingValue(originalValue, apiArea)){
			deleteAiTestAliasOnAllNodes(arguments.testDriver, arguments.alias, scriptPath, true);
		}
		else {
			var restoreFrame = initTestFrame(arguments.testDriver, arguments.alias, scriptPath, true);
			restoreTest(arguments.testDriver, restoreFrame, originalValue, arguments.alias);
		}
		application.ccsTestNodesScope = "currentPort";
	}

	private boolean function isCurrentServerNodeKey(required string nodeKey){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var separator = structKeyExists(application.testConstants, "TEST_FRAME")
			AND structKeyExists(application.testConstants.TEST_FRAME, "COMPOSITE_KEY_FIELD_SEPARATOR")
			? application.testConstants.TEST_FRAME.COMPOSITE_KEY_FIELD_SEPARATOR
			: "::";
		var parts = listToArray(arguments.nodeKey, separator, false, true);
		if(arrayLen(parts) LT 2)
			return false;
		return val(parts[2]) EQ val(cgi.server_port);
	}

	private array function sortAiVerificationRowsCurrentFirst(required array rows){
		var sorted = [];
		for(var row in arguments.rows){
			if(isCurrentServerNodeKey(row.nodeKey))
				arrayAppend(sorted, row);
		}
		var otherRows = [];
		for(var row in arguments.rows){
			if(NOT isCurrentServerNodeKey(row.nodeKey))
				arrayAppend(otherRows, row);
		}
		arraySort(otherRows, function(a, b){
			return compare(a.nodeLabel, b.nodeLabel);
		});
		for(var row in otherRows)
			arrayAppend(sorted, row);
		return sorted;
	}

	private array function getAiNodeLabelsFromFrame(required struct testFrame){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var labels = [];
		var setTypes = [
			application.testConstants.TEST_FRAME.PRIME_SET,
			application.testConstants.TEST_FRAME.NONPRIME_SET
		];

		for(var setType in setTypes){
			if(NOT structKeyExists(arguments.testFrame, setType))
				continue;
			for(var nodeKey in arguments.testFrame[setType].keyList()){
				var label = stUtil.getURLFragFromNodeKey(nodeKey);
				if(len(label) AND arrayFindNoCase(labels, label) EQ 0)
					arrayAppend(labels, label);
			}
		}
		return labels;
	}

	private array function getAiNodeLabelsFromCcsConfig(){
		if(NOT structKeyExists(application, "ccsConfigMap"))
			return [];
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var labels = [];
		for(var nodeKey in application.ccsConfigMap.keyList()){
			var label = stUtil.getURLFragFromNodeKey(nodeKey);
			if(len(label) AND arrayFindNoCase(labels, label) EQ 0)
				arrayAppend(labels, label);
		}
		return labels;
	}

	private struct function getAiNodeMetadataForKey(required string nodeKey){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		var cluster = "N/A";
		var env = "N/A";
		if(structKeyExists(application, "ccsConfigMap") AND application.ccsConfigMap.keyExists(arguments.nodeKey)){
			cluster = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.CLUSTER];
			env = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		}
		return {
			cluster = len(trim("" & cluster)) ? cluster : "N/A",
			environment = len(trim("" & env)) ? env : "N/A"
		};
	}

	private string function formatAiNewValueDisplay(required any newSetValue, required string apiArea, string fieldName = ""){
		if(len(arguments.fieldName)){
			var config = decodeConfigPayload(arguments.newSetValue, arguments.apiArea);
			return formatFieldDisplayValue(extractConfigFieldValue(config, arguments.fieldName));
		}
		return formatConfigSummaryFromPayload(arguments.newSetValue, arguments.apiArea);
	}

	private string function formatAiExistingValueDisplay(required any existingValue, required string apiArea, string fieldName = ""){
		if(len(arguments.fieldName))
			return formatExistingFieldDisplay(arguments.existingValue, arguments.fieldName, arguments.apiArea);
		return formatConfigSummaryFromPayload(arguments.existingValue, arguments.apiArea);
	}

	private void function writeAiSyncUpdateMessage(
		required string settingName,
		required string fieldName,
		required any newSetValue,
		required struct syncTestFrame,
		required string apiArea,
		string nodesScope = "all"
	){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var primeNode = stUtil.getPresetNodeKeyFromFrame(arguments.syncTestFrame, arguments.settingName);
		var primeLabel = stUtil.getURLFragFromNodeKey(primeNode);
		var targetLabel = len(arguments.fieldName) ? arguments.fieldName : arguments.settingName;
		var valueLabel = formatAiNewValueDisplay(arguments.newSetValue, arguments.apiArea, arguments.fieldName);
		var allNodes = getAiNodeLabelsFromFrame(arguments.syncTestFrame);
		if(arguments.nodesScope EQ "all" AND arrayLen(allNodes) LTE 1){
			var configNodes = getAiNodeLabelsFromCcsConfig();
			if(arrayLen(configNodes) GT arrayLen(allNodes))
				allNodes = configNodes;
		}

		if(arguments.nodesScope NEQ "all" OR arrayLen(allNodes) LTE 1){
			writeOutput("updating #targetLabel# to: #valueLabel# on node: #primeLabel#<br>");
			return;
		}

		writeOutput(
			"updating #targetLabel# to: #valueLabel# on prime node: #primeLabel#; "
		);
	}

	private array function buildCurrentNodeAiVerificationRows(
		required struct syncTestFrame,
		required struct syncResult,
		required struct existingValues,
		required any newSetValue,
		required string apiArea,
		string fieldName = "",
		string settingName = ""
	){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var currentNodeKey = stUtil.getPresetNodeKeyFromFrame(arguments.syncTestFrame, arguments.settingName);
		var metadata = getAiNodeMetadataForKey(currentNodeKey);
		var existing = structKeyExists(arguments.existingValues, currentNodeKey)
			? arguments.existingValues[currentNodeKey]
			: getPresetValueFromFrame(arguments.syncTestFrame, arguments.settingName);
		var passed = false;
		var syncRows = buildAiVerificationRows(
			arguments.syncResult.postSyncFrame,
			arguments.newSetValue,
			arguments.apiArea,
			arguments.fieldName,
			true
		);

		for(var row in syncRows){
			if(row.nodeKey EQ currentNodeKey){
				passed = row.passed;
				break;
			}
		}

		return [{
			nodeKey = currentNodeKey,
			nodeLabel = stUtil.getURLFragFromNodeKey(currentNodeKey),
			existingValue = formatAiExistingValueDisplay(existing, arguments.apiArea, arguments.fieldName),
			updatedValue = formatAiNewValueDisplay(arguments.newSetValue, arguments.apiArea, arguments.fieldName),
			passed = passed,
			cluster = metadata.cluster,
			environment = metadata.environment,
			setType = application.testConstants.TEST_FRAME.PRIME_SET
		}];
	}

	private array function buildAllNodeAiVerificationRows(
		required struct afterFrame,
		required struct existingValues,
		required any newSetValue,
		required string apiArea,
		string fieldName = "",
		boolean showEmptyNodes = true
	){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var rows = buildAiVerificationRows(
			arguments.afterFrame,
			arguments.newSetValue,
			arguments.apiArea,
			arguments.fieldName,
			arguments.showEmptyNodes
		);
		var rowKeys = {};
		for(var row in rows)
			rowKeys[row.nodeKey] = true;

		var allNodeKeys = arguments.existingValues.keyList();
		if(structKeyExists(application, "ccsConfigMap") AND NOT structIsEmpty(application.ccsConfigMap)){
			var testMgr = new cfsuite.ccssuite.testManager().init();
			allNodeKeys = listAppend(allNodeKeys, testMgr.getNodeKeysInPrimeEnvironment());
			var nonPrimeKeys = testMgr.getNodeKeysNotInPrimeEnvironment();
			if(len(nonPrimeKeys))
				allNodeKeys = listAppend(allNodeKeys, nonPrimeKeys);
		}

		for(var nodeKey in listToArray(allNodeKeys)){
			if(structKeyExists(rowKeys, nodeKey))
				continue;
			rowKeys[nodeKey] = true;

			var metadata = getAiNodeMetadataForKey(nodeKey);
			// Distinguish "we captured this node's value before the test ran, and it happens to be
			// blank" (hasCapturedValue — a real, known state) from "we never captured anything for
			// this node at all" (truly unavailable). The old check (len(trim(existing))) conflated
			// the two, showing "(unavailable)" even when the real pre-test value was legitimately
			// empty (e.g. no collection existed there).
			var hasCapturedValue = structKeyExists(arguments.existingValues, nodeKey);
			var existing = hasCapturedValue ? arguments.existingValues[nodeKey] : "";
			var displayExisting = hasCapturedValue
				? formatAiExistingValueDisplay(existing, arguments.apiArea, arguments.fieldName)
				: "(unavailable)";
			// Same reasoning as buildAllNodeSyncVerificationRows: a currentPort-scoped test (e.g.
			// ColdFusion Collections) never intended to evaluate any other node, so an empty/
			// unfetched value here is expected, not a failure.
			var outOfScope = application.ccsTestNodesScope EQ "currentPort";
			arrayAppend(rows, {
				nodeKey = nodeKey,
				nodeLabel = stUtil.getURLFragFromNodeKey(nodeKey),
				existingValue = displayExisting,
				updatedValue = displayExisting,
				verificationStatus = (hasCapturedValue OR outOfScope) ? "Passed" : "Failed",
				passed = (hasCapturedValue OR outOfScope),
				syncState = outOfScope ? "Out of scope (single-node test)" : (hasCapturedValue ? "Not re-checked (skipped/unreachable)" : "Unavailable"),
				cluster = metadata.cluster,
				environment = metadata.environment,
				setType = application.testConstants.TEST_FRAME.PRIME_SET
			});
		}

		return sortAiVerificationRowsCurrentFirst(rows);
	}

	public array function buildAiVerificationRows(
		required struct postSyncFrame,
		required any newSetValue,
		required string apiArea,
		string fieldName = "",
		boolean showEmptyNodes = false
	){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();

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

				var preDisplay = len(arguments.fieldName)
					? formatExistingFieldDisplay(prePayload, arguments.fieldName, arguments.apiArea)
					: formatConfigSummaryFromPayload(prePayload, arguments.apiArea);
				var postDisplay = len(arguments.fieldName)
					? formatUpdatedFieldDisplay(postPayload, arguments.fieldName, arguments.apiArea)
					: formatConfigSummaryFromPayload(postPayload, arguments.apiArea);

				if(NOT arguments.showEmptyNodes AND preDisplay EQ "(not configured)" AND postDisplay EQ "(not configured)")
					continue;

				var passed = aiNodeVerificationPassed(
					arguments.fieldName,
					prePayload,
					postPayload,
					arguments.newSetValue,
					nodeKey,
					arguments.apiArea
				);

				var cluster = "N/A";
				var env = "N/A";
				if(structKeyExists(application, "ccsConfigMap") AND application.ccsConfigMap.keyExists(nodeKey)) {
					cluster = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.CLUSTER];
					env = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
				}

				// A node in a different cluster/environment than the current one is out of scope
				// for this change, regardless of whether the underlying resource is genuinely
				// isolated per node (mail/CCS-replicated settings) or, in this environment,
				// physically shared across all instances (ColdFusion Collections' Solr backend) —
				// either way, a cross-cluster node should never be reported as having received an
				// update it isn't supposed to get. Same-cluster peers are left alone here and show
				// whatever was actually fetched, since same-cluster sync IS expected to be visible.
				var currentKey = CGI.SERVER_NAME & "::" & CGI.SERVER_PORT;
				var isCrossCluster = false;
				if(NOT isCurrentServerNodeKey(nodeKey)
						AND structKeyExists(application, "ccsConfigMap")
						AND application.ccsConfigMap.keyExists(currentKey)){
					var currentCluster = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.CLUSTER];
					var currentEnv = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.ENVIRONMENT];
					if(currentCluster NEQ cluster OR currentEnv NEQ env)
						isCrossCluster = true;
				}
				if(isCrossCluster){
					postDisplay = preDisplay;
					passed = true;
				}

				arrayAppend(rows, {
					nodeKey = nodeKey,
					nodeLabel = stUtil.getURLFragFromNodeKey(nodeKey),
					existingValue = preDisplay,
					updatedValue = postDisplay,
					verificationStatus = passed ? "Passed" : "Failed",
					passed = passed,
					syncState = isCrossCluster ? "Different cluster/env" : (passed ? "Synced" : "Unexpected value"),
					cluster = len(trim("" & cluster)) ? cluster : "N/A",
					environment = len(trim("" & env)) ? env : "N/A",
					setType = setType
				});
			}
		}

		return sortAiVerificationRowsCurrentFirst(rows);
	}

	private boolean function aiNodeVerificationPassed(
		required string fieldName,
		required any presetPayload,
		required any postPayload,
		required any expectedPayload,
		required string nodeKey,
		required string apiArea
	){
		if(len(arguments.fieldName))
			return aiFieldNodePassed(
				arguments.fieldName,
				arguments.presetPayload,
				arguments.postPayload,
				arguments.expectedPayload,
				arguments.nodeKey,
				arguments.apiArea
			);

		if(NOT isNodeInCurrentCluster(arguments.nodeKey))
			return new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().setMatches(
				"",
				arguments.presetPayload,
				arguments.postPayload,
				arguments.presetPayload,
				arguments.apiArea
			);

		return new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().setMatches(
			"",
			arguments.presetPayload,
			arguments.postPayload,
			arguments.expectedPayload,
			arguments.apiArea
		);
	}

	private boolean function aiFieldNodePassed(
		required string fieldName,
		required any presetPayload,
		required any postPayload,
		required any expectedPayload,
		required string nodeKey,
		required string apiArea
	){
		var expectedField = extractConfigFieldValue(
			decodeConfigPayload(arguments.expectedPayload, arguments.apiArea),
			arguments.fieldName
		);
		var postField = extractStoredFieldValue(arguments.postPayload, arguments.fieldName, arguments.apiArea);
		var presetField = extractStoredFieldValue(arguments.presetPayload, arguments.fieldName, arguments.apiArea);

		var sameCluster = isNodeInCurrentCluster(nodeKey);
		if(sameCluster)
			return fieldValuesEquivalent(expectedField, postField);
		return fieldValuesEquivalent(presetField, postField);
	}

	private boolean function isNodeInCurrentCluster(required string nodeKey){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		if(NOT structKeyExists(application, "ccsConfigMap"))
			return true;

		var currentKey = CGI.SERVER_NAME & "::" & CGI.SERVER_PORT;
		if(NOT application.ccsConfigMap.keyExists(currentKey) OR NOT application.ccsConfigMap.keyExists(arguments.nodeKey))
			return true;

		var currentCluster = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.CLUSTER];
		var currentEnv = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		var nodeCluster = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.CLUSTER];
		var nodeEnv = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		return currentCluster EQ nodeCluster AND currentEnv EQ nodeEnv;
	}

	/**
	* payload can be a diagnostic string like "set FAILED. Admin API or CCS rejected update
	* (read back: ...)" rather than an actual encoded config, whenever the underlying set
	* was rejected (e.g. Admin API validation). Decoding is purely for display here, so treat
	* anything that doesn't decode as "no config" instead of letting the parse error escape.
	*/
	private struct function decodeConfigPayload(required any payload, required string apiArea){
		try {
			if(lCase(arguments.apiArea) EQ "embeddingmodels")
				return new cfsuite.ccssuite.utils.embeddingConfigUtil().init().decodeConfigValue(arguments.payload);
			if(listFindNoCase("vectorstores,RAG", arguments.apiArea))
				return new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().decodeConfigValue(arguments.payload);
			if(lCase(arguments.apiArea) EQ "mcpservers")
				return new cfsuite.ccssuite.utils.mcpConfigUtil().init().decodeConfigValue(arguments.payload);
			if(lCase(arguments.apiArea) EQ "nosqldatasources")
				return new cfsuite.ccssuite.utils.nosqlDatasourceConfigUtil().init().decodeConfigValue(arguments.payload);
			if(lCase(arguments.apiArea) EQ "coldfusioncollections")
				return new cfsuite.ccssuite.utils.coldfusionCollectionsConfigUtil().init().decodeConfigValue(arguments.payload);
			return new cfsuite.ccssuite.utils.llmConfigUtil().init().decodeConfigValue(arguments.payload);
		}
		catch(any e){
			return {};
		}
	}

	private struct function getDefaultConfigForArea(required string apiArea){
		if(lCase(arguments.apiArea) EQ "embeddingmodels")
			return getDefaultEmbeddingConfig();
		if(listFindNoCase("vectorstores,RAG", arguments.apiArea))
			return getDefaultVectorStoreConfig();
		return getDefaultLLMConfig();
	}

	private any function getBaselineFieldValue(required any payload, required string fieldName, required string apiArea){
		var config = decodeConfigPayload(arguments.payload, arguments.apiArea);
		if(NOT structIsEmpty(config))
			return extractConfigFieldValue(config, arguments.fieldName);

		return extractConfigFieldValue(getDefaultConfigForArea(arguments.apiArea), arguments.fieldName);
	}

	public any function extractConfigFieldValue(required struct config, required string fieldName){
		var key = normalizeAiFieldName(arguments.fieldName);
		if(key EQ "provider") return structKeyExists(arguments.config, "provider") ? arguments.config.provider : "";
		if(key EQ "apikey") return structKeyExists(arguments.config, "apiKey") ? arguments.config.apiKey : "";
		if(key EQ "modelname") return structKeyExists(arguments.config, "modelName") ? arguments.config.modelName : "";
		if(key EQ "baseurl") return structKeyExists(arguments.config, "baseUrl") ? arguments.config.baseUrl : "";
		if(key EQ "organizationid") return structKeyExists(arguments.config, "organizationId") ? arguments.config.organizationId : "";
		if(key EQ "projectid") return structKeyExists(arguments.config, "projectId") ? arguments.config.projectId : "";
		if(key EQ "userid") return structKeyExists(arguments.config, "userId") ? arguments.config.userId : "";
		if(key EQ "user") return structKeyExists(arguments.config, "user") ? arguments.config.user : "";
		if(key EQ "temperature") return structKeyExists(arguments.config, "temperature") ? arguments.config.temperature : "";
		if(key EQ "maxtokens") return structKeyExists(arguments.config, "maxTokens") ? arguments.config.maxTokens : "";
		if(key EQ "topp") return structKeyExists(arguments.config, "topP") ? arguments.config.topP : "";
		if(key EQ "presencepenalty") return structKeyExists(arguments.config, "presencePenalty") ? arguments.config.presencePenalty : "";
		if(key EQ "seed") return structKeyExists(arguments.config, "seed") ? arguments.config.seed : "";
		if(key EQ "responseformat") return structKeyExists(arguments.config, "responseFormat") ? arguments.config.responseFormat : "";
		if(key EQ "stopsequences") return structKeyExists(arguments.config, "stopSequences") ? arguments.config.stopSequences : "";
		if(key EQ "frequencypenalty") return structKeyExists(arguments.config, "frequencyPenalty") ? arguments.config.frequencyPenalty : "";
		if(key EQ "logitbias") return structKeyExists(arguments.config, "logitBias") ? arguments.config.logitBias : "";
		if(key EQ "maxretries"){
			if(structKeyExists(arguments.config, "maxRetries"))
				return arguments.config.maxRetries;
			return getVectorStoreRetryField(arguments.config, "maxRetries", "");
		}
		if(key EQ "requesttimeout") return structKeyExists(arguments.config, "timeout") ? arguments.config.timeout : "";
		if(key EQ "logrequests") return structKeyExists(arguments.config, "logRequests") ? arguments.config.logRequests : "";
		if(key EQ "logresponses") return structKeyExists(arguments.config, "logResponses") ? arguments.config.logResponses : "";
		if(key EQ "paralleltoolcalls") return structKeyExists(arguments.config, "parallelToolCalls") ? arguments.config.parallelToolCalls : "";
		if(key EQ "strictjsonschema") return structKeyExists(arguments.config, "strictJsonSchema") ? arguments.config.strictJsonSchema : "";
		if(key EQ "metadata") return structKeyExists(arguments.config, "metadata") ? arguments.config.metadata : "";
		if(key EQ "dimension") return structKeyExists(arguments.config, "dimension") ? arguments.config.dimension : "";
		if(key EQ "batchsize") return structKeyExists(arguments.config, "batchSize") ? arguments.config.batchSize : "";
		if(key EQ "proxyhost"){
			return structKeyExists(arguments.config, "httpClient")
				AND isStruct(arguments.config.httpClient)
				AND structKeyExists(arguments.config.httpClient, "PROXY")
				AND isStruct(arguments.config.httpClient.PROXY)
				AND structKeyExists(arguments.config.httpClient.PROXY, "host")
				? arguments.config.httpClient.PROXY.host : "";
		}
		if(key EQ "proxyport"){
			return structKeyExists(arguments.config, "httpClient")
				AND isStruct(arguments.config.httpClient)
				AND structKeyExists(arguments.config.httpClient, "PROXY")
				AND isStruct(arguments.config.httpClient.PROXY)
				AND structKeyExists(arguments.config.httpClient.PROXY, "port")
				? arguments.config.httpClient.PROXY.port : "";
		}
		if(key EQ "proxyusername"){
			return structKeyExists(arguments.config, "httpClient")
				AND isStruct(arguments.config.httpClient)
				AND structKeyExists(arguments.config.httpClient, "PROXY")
				AND isStruct(arguments.config.httpClient.PROXY)
				AND structKeyExists(arguments.config.httpClient.PROXY, "user")
				? arguments.config.httpClient.PROXY.user : "";
		}
		if(key EQ "proxypassword"){
			return structKeyExists(arguments.config, "httpClient")
				AND isStruct(arguments.config.httpClient)
				AND structKeyExists(arguments.config.httpClient, "PROXY")
				AND isStruct(arguments.config.httpClient.PROXY)
				AND structKeyExists(arguments.config.httpClient.PROXY, "pass")
				? arguments.config.httpClient.PROXY.pass : "";
		}
		if(key EQ "url") return structKeyExists(arguments.config, "url") ? arguments.config.url : "";
		if(key EQ "collectionname") return structKeyExists(arguments.config, "collectionName") ? arguments.config.collectionName : "";
		if(key EQ "databasename") return structKeyExists(arguments.config, "databaseName") ? arguments.config.databaseName : "";
		if(key EQ "metrictype") return structKeyExists(arguments.config, "metricType") ? arguments.config.metricType : "";
		if(key EQ "indextype") return structKeyExists(arguments.config, "indexType") ? arguments.config.indexType : "";
		if(key EQ "username") return structKeyExists(arguments.config, "username") ? arguments.config.username : "";
		if(key EQ "password") return structKeyExists(arguments.config, "password") ? arguments.config.password : "";
		if(key EQ "topk") return structKeyExists(arguments.config, "topK") ? arguments.config.topK : "";
		if(key EQ "minscore") return structKeyExists(arguments.config, "minScore") ? arguments.config.minScore : "";
		if(key EQ "embeddingmodel") return structKeyExists(arguments.config, "embeddingModel") ? arguments.config.embeddingModel : "";
		if(key EQ "calltimeout") return getVectorStoreConnectionField(arguments.config, "callTimeout", "");
		if(key EQ "connectiontimeout") return getVectorStoreConnectionField(arguments.config, "connectionTimeout", "");
		if(key EQ "keepalive") return getVectorStoreConnectionField(arguments.config, "keepAlive", "");
		if(key EQ "keepalivetime") return getVectorStoreConnectionField(arguments.config, "keepAliveTime", "");
		if(key EQ "keepalivetimeout") return getVectorStoreConnectionField(arguments.config, "keepAliveTimeout", "");
		if(key EQ "idletimeout") return getVectorStoreConnectionField(arguments.config, "idleTimeout", "");
		if(key EQ "deadline") return getVectorStoreConnectionField(arguments.config, "deadline", "");
		if(key EQ "retryonratelimit") return getVectorStoreRetryField(arguments.config, "retryOnRateLimit", "");
		if(key EQ "initialbackoff") return getVectorStoreRetryField(arguments.config, "initialBackoff", "");
		if(key EQ "maxbackoff") return getVectorStoreRetryField(arguments.config, "maxBackoff", "");
		if(key EQ "backoffmultiplier") return getVectorStoreRetryField(arguments.config, "backOffMultiplier", "");
		return "";
	}

	private string function normalizeAiFieldName(required string fieldName){
		if(compareNoCase(trim(arguments.fieldName), variables.FIELD_NAME_TIMEOUT) EQ 0)
			return "requesttimeout";
		return lCase(trim(arguments.fieldName));
	}

	public string function formatFieldDisplayValue(required any value){
		if(isNull(arguments.value))
			return "(not configured)";
		if(isNumeric(arguments.value) AND NOT listFindNoCase("true,false,yes,no", lCase(trim("" & arguments.value))))
			return "" & val(arguments.value);
		if(isBoolean(arguments.value) AND NOT isNumeric(arguments.value))
			return arguments.value ? "true" : "false";
		if(NOT len(trim("" & arguments.value)))
			return "(not configured)";
		return trim("" & arguments.value);
	}

	private any function extractStoredFieldValue(required any payload, required string fieldName, required string apiArea){
		var config = decodeConfigPayload(arguments.payload, arguments.apiArea);
		if(structIsEmpty(config))
			return "";
		return extractConfigFieldValue(config, arguments.fieldName);
	}

	private string function formatExistingFieldDisplay(required any payload, required string fieldName, required string apiArea){
		var config = decodeConfigPayload(arguments.payload, arguments.apiArea);
		if(structIsEmpty(config))
			return formatOptionalFieldDisplay(getBaselineFieldValue(arguments.payload, arguments.fieldName, arguments.apiArea), arguments.fieldName);
		return formatOptionalFieldDisplay(extractConfigFieldValue(config, arguments.fieldName), arguments.fieldName);
	}

	private string function formatUpdatedFieldDisplay(required any payload, required string fieldName, required string apiArea){
		var config = decodeConfigPayload(arguments.payload, arguments.apiArea);
		if(structIsEmpty(config))
			return formatOptionalFieldDisplay(getBaselineFieldValue(arguments.payload, arguments.fieldName, arguments.apiArea), arguments.fieldName);
		return formatOptionalFieldDisplay(extractConfigFieldValue(config, arguments.fieldName), arguments.fieldName);
	}

	private string function formatOptionalFieldDisplay(required any value, required string fieldName){
		if(isOptionalEmptyField(arguments.fieldName) AND NOT len(trim("" & arguments.value)))
			return "(empty)";
		return formatFieldDisplayValue(arguments.value);
	}

	private boolean function isOptionalEmptyField(required string fieldName){
		var key = normalizeAiFieldName(arguments.fieldName);
		return listFindNoCase("apikey,username,password,embeddingmodel", key) GT 0;
	}

	private string function formatFieldDisplayFromPayload(required any payload, required string fieldName, required string apiArea){
		return formatUpdatedFieldDisplay(arguments.payload, arguments.fieldName, arguments.apiArea);
	}

	private string function formatConfigSummaryFromPayload(required any payload, required string apiArea){
		var config = decodeConfigPayload(arguments.payload, arguments.apiArea);
		if(structIsEmpty(config))
			return "(empty)";

		var parts = [];
		if(lCase(arguments.apiArea) EQ "embeddingmodels"){
			if(structKeyExists(config, "provider")) arrayAppend(parts, "provider=" & formatFieldDisplayValue(config.provider));
			if(structKeyExists(config, "modelName")) arrayAppend(parts, "modelName=" & formatFieldDisplayValue(config.modelName));
			if(structKeyExists(config, "timeout")) arrayAppend(parts, "timeout=" & formatFieldDisplayValue(config.timeout));
			if(structKeyExists(config, "dimension")) arrayAppend(parts, "dimension=" & formatFieldDisplayValue(config.dimension));
			if(structKeyExists(config, "apiKey") AND len(trim("" & config.apiKey))) arrayAppend(parts, "apiKey=(configured)");
		}
		else if(listFindNoCase("vectorstores,RAG", arguments.apiArea)){
			if(structKeyExists(config, "provider")) arrayAppend(parts, "provider=" & formatFieldDisplayValue(config.provider));
			if(structKeyExists(config, "url")) arrayAppend(parts, "url=" & formatFieldDisplayValue(config.url));
			if(structKeyExists(config, "dimension")) arrayAppend(parts, "dimension=" & formatFieldDisplayValue(config.dimension));
			if(structKeyExists(config, "collectionName")) arrayAppend(parts, "collectionName=" & formatFieldDisplayValue(config.collectionName));
			if(structKeyExists(config, "metricType")) arrayAppend(parts, "metricType=" & formatFieldDisplayValue(config.metricType));
			if(structKeyExists(config, "indexType")) arrayAppend(parts, "indexType=" & formatFieldDisplayValue(config.indexType));
			if(structKeyExists(config, "apiKey") AND len(trim("" & config.apiKey))) arrayAppend(parts, "apiKey=(configured)");
			if(structKeyExists(config, "connectionSettings") AND isStruct(config.connectionSettings) AND structKeyExists(config.connectionSettings, "callTimeout"))
				arrayAppend(parts, "callTimeout=" & formatFieldDisplayValue(config.connectionSettings.callTimeout));
		}
		else if(lCase(arguments.apiArea) EQ "mcpservers"){
			var serverNames = structKeyArray(config);
			arraySort(serverNames, "textnocase");
			arrayAppend(parts, arrayLen(serverNames) & " server(s): " & arrayToList(serverNames, ", "));
		}
		else if(lCase(arguments.apiArea) EQ "nosqldatasources"){
			if(structKeyExists(config, "type")) arrayAppend(parts, "type=" & formatFieldDisplayValue(config.type));
			if(structKeyExists(config, "host")) arrayAppend(parts, "host=" & formatFieldDisplayValue(config.host));
			if(structKeyExists(config, "port")) arrayAppend(parts, "port=" & formatFieldDisplayValue(config.port));
			if(structKeyExists(config, "readConcern")) arrayAppend(parts, "readConcern=" & formatFieldDisplayValue(config.readConcern));
			if(structKeyExists(config, "readPreference")) arrayAppend(parts, "readPreference=" & formatFieldDisplayValue(config.readPreference));
			if(structKeyExists(config, "password") AND len(trim("" & config.password))) arrayAppend(parts, "password=(configured)");
		}
		else if(lCase(arguments.apiArea) EQ "coldfusioncollections"){
			arrayAppend(parts, "collection created");
			if(structKeyExists(config, "language")) arrayAppend(parts, "language=" & formatFieldDisplayValue(config.language));
			if(structKeyExists(config, "termHighlighting")) arrayAppend(parts, "termHighlighting=" & formatFieldDisplayValue(config.termHighlighting));
		}
		else {
			if(structKeyExists(config, "provider")) arrayAppend(parts, "provider=" & formatFieldDisplayValue(config.provider));
			if(structKeyExists(config, "modelName")) arrayAppend(parts, "modelName=" & formatFieldDisplayValue(config.modelName));
			if(structKeyExists(config, "temperature")) arrayAppend(parts, "temperature=" & formatFieldDisplayValue(config.temperature));
		}
		return arrayLen(parts) ? arrayToList(parts, "; ") : "(configured)";
	}

	private boolean function fieldValuesEquivalent(required any left, required any right){
		if(isNumeric(arguments.left) AND isNumeric(arguments.right))
			return val(arguments.left) EQ val(arguments.right);
		if(
			(isBoolean(arguments.left) AND NOT isNumeric(arguments.left))
			OR (isBoolean(arguments.right) AND NOT isNumeric(arguments.right))
		)
			return (arguments.left ? true : false) EQ (arguments.right ? true : false);
		return trim("" & arguments.left) EQ trim("" & arguments.right);
	}

	private struct function ensureProxyStruct(required struct config){
		if(NOT structKeyExists(arguments.config, "httpClient") OR NOT isStruct(arguments.config.httpClient))
			arguments.config.httpClient = {};
		if(NOT structKeyExists(arguments.config.httpClient, "PROXY") OR NOT isStruct(arguments.config.httpClient.PROXY))
			arguments.config.httpClient.PROXY = {};
		return arguments.config.httpClient.PROXY;
	}

	private string function toggleStringMarker(required string value, required string marker){
		var text = trim(arguments.value);
		if(findNoCase(arguments.marker, text))
			return replace(text, arguments.marker, "", "all");
		return text & arguments.marker;
	}

	private boolean function flipBoolean(required any value){
		if(isBoolean(arguments.value) AND NOT isNumeric(arguments.value))
			return NOT arguments.value;
		return NOT listFindNoCase("true,yes,1", lCase(trim("" & arguments.value)));
	}

	private boolean function isAiTestAlias(required string alias){
		return compareNoCase(trim(arguments.alias), variables.LLM_TEST_ALIAS) EQ 0
			OR compareNoCase(trim(arguments.alias), variables.EMBEDDING_TEST_ALIAS) EQ 0
			OR compareNoCase(trim(arguments.alias), variables.VECTORSTORE_TEST_ALIAS) EQ 0;
	}

	private string function getApiAreaFromScriptPath(required string scriptPath){
		var path = replace(arguments.scriptPath, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		if(NOT pos)
			return "settings";
		var remainder = mid(path, pos + len(marker), len(path));
		var parts = listToArray(remainder, "/");
		return arrayLen(parts) GTE 2 ? parts[2] : "settings";
	}

	private boolean function isEmptyAiSettingValue(required any value, required string apiArea){
		var raw = trim("" & arguments.value);
		if(NOT len(raw) OR raw EQ "|")
			return true;
		if(lCase(arguments.apiArea) EQ "embeddingmodels")
			return structIsEmpty(new cfsuite.ccssuite.utils.embeddingConfigUtil().init().decodeConfigValue(raw));
		if(listFindNoCase("vectorstores,RAG", arguments.apiArea))
			return structIsEmpty(new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().decodeConfigValue(raw));
		if(lCase(arguments.apiArea) EQ "llms")
			return structIsEmpty(new cfsuite.ccssuite.utils.llmConfigUtil().init().decodeConfigValue(raw));
		return false;
	}

	private void function deleteAiTestAliasOnAllNodes(
		required any testDriver,
		required string alias,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		var deleteFrame = initTestFrame(arguments.testDriver, arguments.alias, arguments.scriptPath, arguments.skipUnreachableNodes);
		restoreTest(arguments.testDriver, deleteFrame, "", arguments.alias);
	}
}
