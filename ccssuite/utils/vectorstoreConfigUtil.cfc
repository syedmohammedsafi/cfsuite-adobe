/**
* Read/write Vector Store configurations through the live coldfusion.server.VectorStoreService
* (the same service CFIDE/administrator/ai/rag/ingestion.cfm and the Vector Stores admin page use),
* rather than editing neo-vectorstore.xml directly. Writing straight to the file only updates disk —
* the service caches its config in memory and won't see a raw file edit until CF restarts, and a
* mismatched on-disk shape (e.g. an extra wrapper key) can silently break every page that reads
* through the service even though the raw XML "looks fine".
*/
component output="false" {

	variables.CAMEL_TO_WDDX = {
		"provider" = "PROVIDER",
		"url" = "URL",
		"dimension" = "DIMENSION",
		"metricType" = "METRICTYPE",
		"indexType" = "INDEXTYPE",
		"collectionName" = "COLLECTIONNAME",
		"databaseName" = "DATABASENAME",
		"apiKey" = "APIKEY",
		"username" = "USERNAME",
		"password" = "PASSWORD",
		"topK" = "TOPK",
		"minScore" = "MINSCORE",
		"embeddingModel" = "EMBEDDINGMODEL",
		"batchSize" = "BATCHSIZE",
		"connectionSettings" = "CONNECTIONSETTINGS",
		"retrySettings" = "RETRYSETTINGS",
		"callTimeout" = "CALLTIMEOUT",
		"connectionTimeout" = "CONNECTIONTIMEOUT",
		"keepAlive" = "KEEPALIVE",
		"keepAliveTime" = "KEEPALIVETIME",
		"keepAliveTimeout" = "KEEPALIVETIMEOUT",
		"idleTimeout" = "IDLETIMEOUT",
		"deadline" = "DEADLINE",
		"maxRetries" = "MAXRETRIES",
		"retryOnRateLimit" = "RETRYONRATELIMIT",
		"initialBackoff" = "INITIALBACKOFF",
		"maxBackoff" = "MAXBACKOFF",
		"backOffMultiplier" = "BACKOFFMULTIPLIER",
		"index" = "INDEX",
		"namespace" = "NAMESPACE",
		"serverless" = "SERVERLESS",
		"cloud" = "CLOUD",
		"region" = "REGION",
		"deletionProtection" = "DELETIONPROTECTION",
		"pod" = "POD",
		"environment" = "ENVIRONMENT",
		"podType" = "PODTYPE",
		"tenantName" = "TENANTNAME"
	};

	public function init(){
		return this;
	}

	private any function getVectorStoreService(){
		return createObject("java", "coldfusion.server.ServiceFactory").getVectorStoreService(true);
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
			throw(message="Invalid vector store config payload", detail=e.message, type="CCSTest.ConfigError");
		}
	}

	public string function encodeConfigValue(required struct config){
		return toBase64(serializeJSON(sortStructKeys(arguments.config)));
	}

	public string function getVectorStoreSetting(required string alias){
		try {
			var entry = getVectorStoreService().getConfigData(arguments.alias);
			var camel = wddxStructToCamel(entry);
			structDelete(camel, "alias");
			return encodeConfigValue(camel);
		}
		catch(any e){
			return "";
		}
	}

	public string function setVectorStoreSetting(required string alias, required any settingValue){
		var raw = trim("" & arguments.settingValue);
		if(NOT len(raw)){
			deleteVectorStoreSetting(arguments.alias);
			return "";
		}

		var config = decodeConfigValue(arguments.settingValue);
		if(structIsEmpty(config)){
			deleteVectorStoreSetting(arguments.alias);
			return "";
		}

		var wddxConfig = camelStructToWddx(config);
		var vsService = getVectorStoreService();
		var exists = false;
		try {
			var curr = vsService.getConfigData(arguments.alias);
			if(isDefined("curr")) exists = true;
		}
		catch(any e){
			exists = false;
		}

		if(exists){
			try {
				vsService.modifyConfigData(arguments.alias, wddxConfig);
			}
			catch(any e){
				try {
					vsService.deleteConfigData(arguments.alias);
					vsService.addConfigData(arguments.alias, wddxConfig);
				}
				catch(any e2){
					rethrow;
				}
			}
		}
		else {
			vsService.addConfigData(arguments.alias, wddxConfig);
		}
		return getVectorStoreSetting(arguments.alias);
	}

	public void function deleteVectorStoreSetting(required string alias){
		try {
			getVectorStoreService().deleteConfigData(arguments.alias);
		}
		catch(any e){
			// already absent - nothing to delete
		}
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
			else if(listFindNoCase("apiKey,password", key)){
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
