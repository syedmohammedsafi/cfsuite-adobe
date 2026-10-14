/**
* Read/write Embedding Model configurations in neo-ai.xml (embeddingmodels).
*/
component output="false" {

	variables.CAMEL_TO_WDDX = {
		"provider" = "PROVIDER",
		"modelName" = "MODELNAME",
		"apiKey" = "APIKEY",
		"baseUrl" = "BASEURL",
		"dimension" = "DIMENSION",
		"organizationId" = "ORGANIZATIONID",
		"projectId" = "PROJECTID",
		"user" = "USER",
		"batchSize" = "BATCHSIZE",
		"maxRetries" = "MAXRETRIES",
		"timeout" = "TIMEOUT",
		"logRequests" = "LOGREQUESTS",
		"logResponses" = "LOGRESPONSES"
	};

	public function init(){
		return this;
	}

	private void function ensureConstants(){
		if(isDefined("application") AND NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		if(NOT structKeyExists(request, "constants") OR NOT isStruct(request.constants))
			request.constants = new cfsuite.ccssuite.constants().init();
	}

	private struct function getConstants(){
		ensureConstants();
		if(isDefined("application") AND structKeyExists(application, "constants") AND isStruct(application.constants))
			return application.constants;
		return request.constants;
	}

	private string function getNeoAiPath(){
		var constants = getConstants();
		return server.coldfusion.rootdir & constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & constants.SYS_CONFIG.FILE_SEPARATOR & "neo-ai.xml";
	}

	private string function getConfigLockName(required string configPath){
		return "ccs-neo-ai-" & hash(arguments.configPath);
	}

	private string function findStructKey(required struct data, required string key){
		for(var existingKey in arguments.data){
			if(compareNoCase(existingKey, arguments.key) EQ 0)
				return existingKey;
		}
		return arguments.key;
	}

	private struct function loadAiConfigMap(){
		var neoAiPath = getNeoAiPath();
		var lockName = getConfigLockName(neoAiPath);
		var lastError = {};

		lock name="#lockName#" type="readonly" timeout="30" {
			for(var attempt = 1; attempt LTE 3; attempt++){
				try {
					var content = trim(fileRead(neoAiPath));
					if(NOT len(content))
						throw(message="neo-ai.xml is empty", type="CCSTest.ConfigError");
					var cfg = {};
					cfwddx(action="WDDX2CFML", input=content, output="cfg");
					if(NOT isStruct(cfg))
						throw(message="invalid neo-ai.xml structure", type="CCSTest.ConfigError");
					return cfg;
				}
				catch(any e){
					lastError = e;
					if(attempt LT 3)
						sleep(50);
				}
			}
		}

		throw(message=lastError.message, detail=lastError.detail, type="CCSTest.ConfigError");
	}

	private void function saveAiConfigMap(required struct configMap){
		var neoAiPath = getNeoAiPath();
		var lockName = getConfigLockName(neoAiPath);

		lock name="#lockName#" type="exclusive" timeout="30" {
			var wddx = "";
			cfwddx(action="CFML2WDDX", input=arguments.configMap, output="wddx");
			if(NOT findNoCase("name='embeddingmodels'", wddx))
				throw(message="refusing to write corrupted neo-ai.xml", type="CCSTest.ConfigError");
			fileWrite(neoAiPath, wddx);
		}
	}

	private struct function getEmbeddingModelsStruct(){
		var cfg = loadAiConfigMap();
		var embedKey = findStructKey(cfg, "embeddingmodels");
		if(NOT structKeyExists(cfg, embedKey) OR NOT isStruct(cfg[embedKey]))
			return {};
		return cfg[embedKey];
	}

	private void function saveEmbeddingModelsStruct(required struct embeddingModels){
		var cfg = loadAiConfigMap();
		var embedKey = findStructKey(cfg, "embeddingmodels");
		cfg[embedKey] = arguments.embeddingModels;
		saveAiConfigMap(cfg);
	}

	private string function wddxKeyToCamel(required string key){
		var lower = lCase(trim(arguments.key));
		for(var camelKey in variables.CAMEL_TO_WDDX){
			if(lCase(variables.CAMEL_TO_WDDX[camelKey]) EQ lower)
				return camelKey;
		}
		if(len(lower) LTE 1)
			return lower;
		return lCase(left(lower, 1)) & mid(lower, 2, len(lower) - 1);
	}

	private string function camelToWddxKey(required string key){
		if(structKeyExists(variables.CAMEL_TO_WDDX, arguments.key))
			return variables.CAMEL_TO_WDDX[arguments.key];
		return uCase(trim(arguments.key));
	}

	private any function normalizeWddxValue(required any value){
		if(isNull(arguments.value))
			return "";
		if(isNumeric(arguments.value) AND NOT listFindNoCase("true,false,yes,no", lCase(trim("" & arguments.value))))
			return val(arguments.value);
		if(isBoolean(arguments.value) AND NOT isNumeric(arguments.value))
			return arguments.value;
		return trim("" & arguments.value);
	}

	private struct function wddxStructToCamel(required struct wddxStruct){
		var result = {};
		for(var key in arguments.wddxStruct){
			var camelKey = wddxKeyToCamel(key);
			var value = arguments.wddxStruct[key];
			if(isStruct(value))
				result[camelKey] = wddxStructToCamel(value);
			else
				result[camelKey] = normalizeWddxValue(value);
		}
		return result;
	}

	private struct function camelStructToWddx(required struct camelStruct){
		var result = {};
		for(var key in arguments.camelStruct){
			var wddxKey = camelToWddxKey(key);
			var value = arguments.camelStruct[key];
			if(isStruct(value))
				result[wddxKey] = camelStructToWddx(value);
			else if(isNumeric(value) AND NOT listFindNoCase("true,false,yes,no", lCase(trim("" & value))))
				result[wddxKey] = val(value);
			else if(isBoolean(value) AND NOT isNumeric(value))
				result[wddxKey] = value;
			else if(len(trim("" & value)))
				result[wddxKey] = trim("" & value);
		}
		return result;
	}

	public struct function sortStructKeys(required struct data){
		return new cfsuite.ccssuite.utils.llmConfigUtil().init().sortStructKeys(arguments.data);
	}

	public struct function decodeConfigValue(required any settingValue){
		var raw = trim("" & arguments.settingValue);
		if(NOT len(raw))
			return {};

		try {
			if(reFind("^[A-Za-z0-9+/=\r\n]+$", raw) AND len(raw) MOD 4 EQ 0)
				raw = toString(toBinary(raw));
			var parsed = deserializeJSON(raw);
			return isStruct(parsed) ? parsed : {};
		}
		catch(any e){
			throw(message="Invalid embedding config payload", detail=e.message, type="CCSTest.ConfigError");
		}
	}

	public string function encodeConfigValue(required struct config){
		return toBase64(serializeJSON(sortStructKeys(arguments.config)));
	}

	public string function getEmbeddingSetting(required string alias){
		var embeddingModels = getEmbeddingModelsStruct();
		var aliasKey = findStructKey(embeddingModels, arguments.alias);
		if(NOT structKeyExists(embeddingModels, aliasKey))
			return "";

		return encodeConfigValue(wddxStructToCamel(embeddingModels[aliasKey]));
	}

	public string function setEmbeddingSetting(required string alias, required any settingValue){
		var raw = trim("" & arguments.settingValue);
		if(NOT len(raw)){
			deleteEmbeddingSetting(arguments.alias);
			return "";
		}

		var embeddingModels = duplicate(getEmbeddingModelsStruct());
		var aliasKey = findStructKey(embeddingModels, arguments.alias);
		var config = decodeConfigValue(arguments.settingValue);
		if(structIsEmpty(config))
			structDelete(embeddingModels, aliasKey);
		else
			embeddingModels[arguments.alias] = camelStructToWddx(config);

		saveEmbeddingModelsStruct(embeddingModels);
		return getEmbeddingSetting(arguments.alias);
	}

	public void function deleteEmbeddingSetting(required string alias){
		var embeddingModels = duplicate(getEmbeddingModelsStruct());
		var aliasKey = findStructKey(embeddingModels, arguments.alias);
		if(structKeyExists(embeddingModels, aliasKey))
			structDelete(embeddingModels, aliasKey);
		saveEmbeddingModelsStruct(embeddingModels);
	}

	private boolean function valuesEquivalent(required any left, required any right){
		if(isNumeric(arguments.left) AND isNumeric(arguments.right))
			return val(arguments.left) EQ val(arguments.right);
		if(
			(isBoolean(arguments.left) AND NOT isNumeric(arguments.left))
			OR (isBoolean(arguments.right) AND NOT isNumeric(arguments.right))
		)
			return (arguments.left ? true : false) EQ (arguments.right ? true : false);
		return trim("" & arguments.left) EQ trim("" & arguments.right);
	}

	private boolean function structValuesMatch(required struct expected, required struct actual){
		for(var key in arguments.expected){
			if(NOT structKeyExists(arguments.actual, key))
				continue;
			if(isStruct(arguments.expected[key])){
				if(NOT isStruct(arguments.actual[key]) OR NOT structValuesMatch(arguments.expected[key], arguments.actual[key]))
					return false;
			}
			else if(key EQ "apiKey"){
				if(len(trim("" & arguments.expected[key])) AND len(trim("" & arguments.actual[key])))
					continue;
				if(NOT valuesEquivalent(arguments.expected[key], arguments.actual[key]))
					return false;
			}
			else if(NOT valuesEquivalent(arguments.expected[key], arguments.actual[key])){
				return false;
			}
		}
		return true;
	}

	public boolean function configsMatch(required any expectedValue, required any actualValue){
		var expected = decodeConfigValue(arguments.expectedValue);
		var actual = decodeConfigValue(arguments.actualValue);
		if(structIsEmpty(expected) AND structIsEmpty(actual))
			return true;
		return structValuesMatch(expected, actual);
	}

	public boolean function setMatches(
		required any presetValue,
		required any actualValue,
		required any requestedValue
	){
		return configsMatch(arguments.requestedValue, arguments.actualValue);
	}
}
