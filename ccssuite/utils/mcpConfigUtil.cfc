/**
* Read/write MCP Server configurations in neo-ai.xml (mcpServers).
*/
component output="false" {

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
		return "ccs-neo-ai-mcp-" & hash(arguments.configPath);
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
			if(NOT findNoCase("name='mcpServers'", wddx))
				throw(message="refusing to write corrupted neo-ai.xml", type="CCSTest.ConfigError");
			fileWrite(neoAiPath, wddx);
		}
	}

	private struct function decodeMcpServersValue(required any storedValue){
		var raw = trim("" & arguments.storedValue);
		if(NOT len(raw) OR raw EQ "{}")
			return {};

		try {
			var parsed = deserializeJSON(raw);
			return isStruct(parsed) ? parsed : {};
		}
		catch(any e){
			throw(message="Invalid MCP servers payload", detail=e.message, type="CCSTest.ConfigError");
		}
	}

	private struct function getMcpServersStruct(){
		var cfg = loadAiConfigMap();
		var mcpKey = findStructKey(cfg, "mcpServers");
		if(NOT structKeyExists(cfg, mcpKey))
			return {};
		return decodeMcpServersValue(cfg[mcpKey]);
	}

	private void function saveMcpServersStruct(required struct mcpServers){
		var cfg = loadAiConfigMap();
		var mcpKey = findStructKey(cfg, "mcpServers");
		cfg[mcpKey] = structIsEmpty(arguments.mcpServers) ? "{}" : serializeJSON(arguments.mcpServers);
		saveAiConfigMap(cfg);
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
			throw(message="Invalid MCP config payload", detail=e.message, type="CCSTest.ConfigError");
		}
	}

	public string function encodeConfigValue(required struct config){
		return toBase64(serializeJSON(sortStructKeys(arguments.config)));
	}

	public string function getMCPSetting(required string settingName){
		if(compareNoCase(arguments.settingName, "mcpServers") NEQ 0)
			throw(message="Unsupported MCP setting: " & arguments.settingName, type="CCSTest.ConfigError");
		return encodeConfigValue(getMcpServersStruct());
	}

	public string function setMCPSetting(required string settingName, required any settingValue){
		if(compareNoCase(arguments.settingName, "mcpServers") NEQ 0)
			throw(message="Unsupported MCP setting: " & arguments.settingName, type="CCSTest.ConfigError");

		var raw = trim("" & arguments.settingValue);
		if(NOT len(raw)){
			saveMcpServersStruct({});
			return "";
		}

		var config = decodeConfigValue(arguments.settingValue);
		if(structIsEmpty(config))
			saveMcpServersStruct({});
		else
			saveMcpServersStruct(config);

		return getMCPSetting(arguments.settingName);
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
			if(isArray(arguments.expected[key])){
				if(NOT isArray(arguments.actual[key]) OR arrayLen(arguments.expected[key]) NEQ arrayLen(arguments.actual[key]))
					return false;
				for(var i = 1; i LTE arrayLen(arguments.expected[key]); i++){
					if(isStruct(arguments.expected[key][i]) AND isStruct(arguments.actual[key][i])){
						if(NOT structValuesMatch(arguments.expected[key][i], arguments.actual[key][i]))
							return false;
					}
					else if(NOT valuesEquivalent(arguments.expected[key][i], arguments.actual[key][i])){
						return false;
					}
				}
			}
			else if(isStruct(arguments.expected[key])){
				if(NOT isStruct(arguments.actual[key]) OR NOT structValuesMatch(arguments.expected[key], arguments.actual[key]))
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
