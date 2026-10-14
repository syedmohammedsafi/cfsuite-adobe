/**
* Read/write ColdFusion Administrator Event Gateways settings
* (via CFIDE.adminapi.eventgateway + neo-event.xml).
*/
component output="false" {

	variables.ENABLE_GATEWAY_SERVICE_SETTING = "EnableGatewayService";
	variables.THREAD_POOL_SIZE_SETTING = "ThreadPoolSize";
	variables.MAX_QUEUE_SIZE_SETTING = "MaxQueueSize";
	variables.GATEWAY_TYPE_SETTING = "GatewayType";
	variables.GATEWAY_INSTANCE_SETTING = "GatewayInstance";
	variables.TEST_GATEWAY_TYPE = "CCSTestGateway";
	variables.TEST_GATEWAY_INSTANCE_ID = "CCS Test Gateway";
	variables.DEFAULT_GATEWAY_TYPE_CLASS = "coldfusion.eventgateway.cfml.CfmlGateway";
	variables.ALT_GATEWAY_TYPE_CLASS = "examples.watcher.DirectoryWatcherGateway";
	variables.DEFAULT_INSTANCE_TYPE = "CFML";

	public function init(){
		variables.componentVersion = 4;
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

	private any function loginAdmin(){
		var constants = getConstants();
		var admin = createObject("component", "CFIDE.adminapi.administrator");
		var userId = structKeyExists(constants.CF_CONFIG, "CF_ADMIN_USERID")
			? trim("" & constants.CF_CONFIG.CF_ADMIN_USERID) : "";
		var loggedIn = len(userId)
			? admin.login(adminPassword=constants.CF_CONFIG.CF_ADMIN_PASSWORD, adminUserId=userId)
			: admin.login(constants.CF_CONFIG.CF_ADMIN_PASSWORD);
		if(NOT loggedIn)
			throw(message="Admin API login failed", type="CCSTest.AdminLoginFailed");
		return admin;
	}

	private void function logoutAdmin(required any admin){
		if(isObject(arguments.admin)){
			try { arguments.admin.logout(); } catch(any x){}
		}
	}

	private any function getEventGatewayApi(){
		return createObject("component", "CFIDE.adminapi.eventgateway");
	}

	public string function getNeoEventPath(){
		var constants = getConstants();
		return server.coldfusion.rootdir & constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & constants.SYS_CONFIG.FILE_SEPARATOR & "neo-event.xml";
	}

	public string function encodeJson(required any value){
		if(isStruct(arguments.value))
			return serializeJSON(normalizeStructKeys(arguments.value));
		return serializeJSON(arguments.value);
	}

	public any function decodeJson(required string raw){
		var text = trim(arguments.raw);
		if(NOT len(text) OR text EQ "|")
			return "";
		try {
			return deserializeJSON(text);
		}
		catch(any e){
			return text;
		}
	}

	private string function normalizePathValue(required any pathValue){
		var path = replace(replace(trim("" & arguments.pathValue), "\", "/", "all"), "//", "/", "all");
		path = replace(path, "{cf.rootdir}", replace(server.coldfusion.rootdir, "\", "/", "all"), "all");
		return lCase(path);
	}

	private array function normalizePathList(required array paths){
		var normalized = [];
		for(var pathValue in arguments.paths){
			var item = normalizePathValue(pathValue);
			if(len(item) AND arrayFindNoCase(normalized, item) EQ 0)
				arrayAppend(normalized, item);
		}
		return normalized;
	}

	private any function getMappedField(required struct data, required string key){
		for(var existingKey in arguments.data){
			if(compareNoCase(existingKey, arguments.key) EQ 0)
				return arguments.data[existingKey];
		}
		return "";
	}

	private struct function mapGatewayTypeStruct(required any typeInfo){
		if(isQuery(arguments.typeInfo)){
			if(arguments.typeInfo.recordCount EQ 0)
				return {};
			var row = {};
			for(var col in arguments.typeInfo.columnList()){
				row[col] = arguments.typeInfo[col][1];
			}
			return mapGatewayTypeStruct(row);
		}
		if(isArray(arguments.typeInfo)){
			if(NOT arrayLen(arguments.typeInfo))
				return {};
			return mapGatewayTypeStruct(arguments.typeInfo[1]);
		}
		if(NOT isStruct(arguments.typeInfo) OR structIsEmpty(arguments.typeInfo))
			return {};
		var config = {};
		var typeValue = getMappedField(arguments.typeInfo, "TYPE");
		if(len(trim("" & typeValue)))
			config.type = uCase(trim("" & typeValue));
		if(structKeyExists(arguments.typeInfo, "DESCRIPTION") OR len(trim("" & getMappedField(arguments.typeInfo, "DESCRIPTION"))))
			config.description = trim("" & getMappedField(arguments.typeInfo, "DESCRIPTION"));
		var classValue = getMappedField(arguments.typeInfo, "CLASS");
		if(len(trim("" & classValue)))
			config.class = trim("" & classValue);
		var timeoutValue = getMappedField(arguments.typeInfo, "STARTTIMEOUT");
		if(len(trim("" & timeoutValue)))
			config.startTimeout = val(timeoutValue);
		var killValue = getMappedField(arguments.typeInfo, "KILLONTIMEOUT");
		if(len(trim("" & killValue)) OR isBoolean(killValue))
			config.killOnTimeout = (killValue ? true : false);
		return config;
	}

	private struct function mapGatewayInstanceStruct(required any instanceInfo){
		if(isQuery(arguments.instanceInfo)){
			if(arguments.instanceInfo.recordCount EQ 0)
				return {};
			var row = {};
			for(var col in arguments.instanceInfo.columnList()){
				row[col] = arguments.instanceInfo[col][1];
			}
			return mapGatewayInstanceStruct(row);
		}
		if(isArray(arguments.instanceInfo)){
			if(NOT arrayLen(arguments.instanceInfo))
				return {};
			return mapGatewayInstanceStruct(arguments.instanceInfo[1]);
		}
		if(NOT isStruct(arguments.instanceInfo) OR structIsEmpty(arguments.instanceInfo))
			return {};
		var config = {};
		if(structKeyExists(arguments.instanceInfo, "GATEWAYID"))
			config.gatewayId = trim("" & arguments.instanceInfo.GATEWAYID);
		if(structKeyExists(arguments.instanceInfo, "TYPE"))
			config.type = uCase(trim("" & arguments.instanceInfo.TYPE));
		if(structKeyExists(arguments.instanceInfo, "CFCPATHS")){
			var paths = [];
			if(isArray(arguments.instanceInfo.CFCPATHS)){
				for(var pathValue in arguments.instanceInfo.CFCPATHS){
					pathValue = trim("" & pathValue);
					if(len(pathValue)) arrayAppend(paths, replace(pathValue, "\", "/", "all"));
				}
			}
			else if(len(trim("" & arguments.instanceInfo.CFCPATHS))){
				arrayAppend(paths, replace(trim("" & arguments.instanceInfo.CFCPATHS), "\", "/", "all"));
			}
			config.cfcPaths = paths;
		}
		if(structKeyExists(arguments.instanceInfo, "CONFIGURATIONPATH"))
			config.configurationPath = trim("" & arguments.instanceInfo.CONFIGURATIONPATH);
		if(structKeyExists(arguments.instanceInfo, "MODE"))
			config.mode = lCase(trim("" & arguments.instanceInfo.MODE));
		return config;
	}

	private struct function readGatewayType(required string typeName){
		var admin = loginAdmin();
		try {
			var typeInfo = getEventGatewayApi().getGatewayTypes(arguments.typeName);
			return mapGatewayTypeStruct(typeInfo);
		}
		catch(any e){
			return {};
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private struct function readGatewayInstance(required string gatewayId){
		var admin = loginAdmin();
		try {
			var instanceInfo = getEventGatewayApi().getGatewayInstances(arguments.gatewayId);
			return mapGatewayInstanceStruct(instanceInfo);
		}
		catch(any e){
			return {};
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function getEnableGatewayServiceValue(){
		var admin = loginAdmin();
		try {
			return (getEventGatewayApi().getGatewayServiceStatus() ? "true" : "false");
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function getThreadPoolSizeValue(){
		var admin = loginAdmin();
		try {
			return "" & val(getEventGatewayApi().getGatewayProperty("ThreadPoolSize"));
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function getMaxQueueSizeValue(){
		var admin = loginAdmin();
		try {
			return "" & val(getEventGatewayApi().getGatewayProperty("MaxQueueSize"));
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function getGatewayTypeSettingValue(){
		return encodeJson(readGatewayType(variables.TEST_GATEWAY_TYPE));
	}

	public string function getGatewayInstanceSettingValue(){
		return encodeJson(readGatewayInstance(variables.TEST_GATEWAY_INSTANCE_ID));
	}

	public string function getEventGatewaysSetting(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.ENABLE_GATEWAY_SERVICE_SETTING):
				return getEnableGatewayServiceValue();
			case lCase(variables.THREAD_POOL_SIZE_SETTING):
				return getThreadPoolSizeValue();
			case lCase(variables.MAX_QUEUE_SIZE_SETTING):
				return getMaxQueueSizeValue();
			case lCase(variables.GATEWAY_TYPE_SETTING):
				return getGatewayTypeSettingValue();
			case lCase(variables.GATEWAY_INSTANCE_SETTING):
				return getGatewayInstanceSettingValue();
			default:
				throw(message="Unsupported event gateway setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public struct function getDefaultGatewayTypeConfig(){
		return {
			"type": uCase(variables.TEST_GATEWAY_TYPE),
			"description": "CCS test gateway type",
			"class": variables.DEFAULT_GATEWAY_TYPE_CLASS,
			"startTimeout": 30,
			"killOnTimeout": true
		};
	}

	public struct function getDefaultGatewayInstanceConfig(){
		return {
			"gatewayId": variables.TEST_GATEWAY_INSTANCE_ID,
			"type": variables.DEFAULT_INSTANCE_TYPE,
			"cfcPaths": [getTestGatewayCfcPath()],
			"configurationPath": "",
			"mode": "manual"
		};
	}

	public string function getTestGatewayCfcPath(){
		return replace(server.coldfusion.rootdir & "/gateway/cfc/examples/echo.cfc", "\", "/", "all");
	}

	public string function getAltGatewayCfcPath(){
		return replace(server.coldfusion.rootdir & "/gateway/cfc/examples/log.cfc", "\", "/", "all");
	}

	public string function getTestGatewayConfigurationPath(){
		return replace(server.coldfusion.rootdir & "/gateway/config/sms-test.cfg", "\", "/", "all");
	}

	private struct function normalizeGatewayTypeConfig(required struct config){
		var normalized = getDefaultGatewayTypeConfig();
		if(structKeyExists(arguments.config, "type") AND len(trim("" & arguments.config.type)))
			normalized.type = uCase(trim("" & arguments.config.type));
		if(structKeyExists(arguments.config, "description"))
			normalized.description = trim("" & arguments.config.description);
		if(structKeyExists(arguments.config, "class") AND len(trim("" & arguments.config.class)))
			normalized.class = trim("" & arguments.config.class);
		if(structKeyExists(arguments.config, "startTimeout"))
			normalized.startTimeout = val(arguments.config.startTimeout);
		if(structKeyExists(arguments.config, "killOnTimeout"))
			normalized.killOnTimeout = (arguments.config.killOnTimeout ? true : false);
		return normalized;
	}

	private struct function normalizeGatewayInstanceConfig(required struct config){
		var normalized = getDefaultGatewayInstanceConfig();
		if(structKeyExists(arguments.config, "gatewayId") AND len(trim("" & arguments.config.gatewayId)))
			normalized.gatewayId = trim("" & arguments.config.gatewayId);
		if(structKeyExists(arguments.config, "type") AND len(trim("" & arguments.config.type)))
			normalized.type = uCase(trim("" & arguments.config.type));
		if(structKeyExists(arguments.config, "cfcPaths") AND isArray(arguments.config.cfcPaths))
			normalized.cfcPaths = arguments.config.cfcPaths;
		if(structKeyExists(arguments.config, "configurationPath"))
			normalized.configurationPath = trim("" & arguments.config.configurationPath);
		if(structKeyExists(arguments.config, "mode") AND len(trim("" & arguments.config.mode)))
			normalized.mode = lCase(trim("" & arguments.config.mode));
		return normalized;
	}

	private void function registerGatewayType(required struct config){
		var cfg = normalizeGatewayTypeConfig(arguments.config);
		var admin = loginAdmin();
		try {
			getEventGatewayApi().setGatewayType(
				cfg.type,
				cfg.description,
				cfg.class,
				cfg.startTimeout,
				cfg.killOnTimeout
			);
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private void function deleteGatewayTypeByName(required string typeName){
		var admin = loginAdmin();
		try {
			try { getEventGatewayApi().deleteGatewayType(uCase(trim(arguments.typeName))); } catch(any e){}
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private void function registerGatewayInstance(required struct config){
		var cfg = normalizeGatewayInstanceConfig(arguments.config);
		var cfcPaths = [];
		for(var pathValue in cfg.cfcPaths){
			pathValue = trim("" & pathValue);
			if(len(pathValue)) arrayAppend(cfcPaths, pathValue);
		}
		if(NOT arrayLen(cfcPaths))
			arrayAppend(cfcPaths, getTestGatewayCfcPath());
		var admin = loginAdmin();
		try {
			getEventGatewayApi().setGatewayInstance(
				cfg.gatewayId,
				cfg.type,
				cfcPaths,
				cfg.configurationPath,
				cfg.mode
			);
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private void function deleteGatewayInstanceById(required string gatewayId){
		var admin = loginAdmin();
		try {
			try {
				if(getEventGatewayApi().getGatewayInstanceStatus(arguments.gatewayId))
					getEventGatewayApi().stopGatewayInstance(arguments.gatewayId);
			} catch(any e){}
			try { getEventGatewayApi().deleteGatewayInstance(arguments.gatewayId); } catch(any e){}
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function setEventGatewaysSetting(required string settingName, required any settingValue){
		var key = lCase(trim(arguments.settingName));
		var raw = trim("" & arguments.settingValue);
		try {
			if(key EQ lCase(variables.ENABLE_GATEWAY_SERVICE_SETTING)){
				var admin = loginAdmin();
				try {
					getEventGatewayApi().setGatewayServiceStatus(raw EQ "true" OR raw EQ "1" OR raw EQ "yes");
				}
				finally {
					logoutAdmin(admin);
				}
				return getEnableGatewayServiceValue();
			}
			if(key EQ lCase(variables.THREAD_POOL_SIZE_SETTING)){
				var adminPool = loginAdmin();
				try {
					getEventGatewayApi().setGatewayProperty("ThreadPoolSize", val(raw));
				}
				finally {
					logoutAdmin(adminPool);
				}
				return getThreadPoolSizeValue();
			}
			if(key EQ lCase(variables.MAX_QUEUE_SIZE_SETTING)){
				var adminQueue = loginAdmin();
				try {
					getEventGatewayApi().setGatewayProperty("MaxQueueSize", val(raw));
				}
				finally {
					logoutAdmin(adminQueue);
				}
				return getMaxQueueSizeValue();
			}
			if(key EQ lCase(variables.GATEWAY_TYPE_SETTING)){
				if(raw EQ "register"){
					registerGatewayType(getDefaultGatewayTypeConfig());
				}
				else if(raw EQ "delete"){
					deleteGatewayTypeByName(variables.TEST_GATEWAY_TYPE);
				}
				else {
					registerGatewayType(normalizeGatewayTypeConfig(decodeJson(raw)));
				}
				return getGatewayTypeSettingValue();
			}
			if(key EQ lCase(variables.GATEWAY_INSTANCE_SETTING)){
				if(raw EQ "register"){
					registerGatewayInstance(getDefaultGatewayInstanceConfig());
				}
				else if(raw EQ "delete"){
					deleteGatewayInstanceById(variables.TEST_GATEWAY_INSTANCE_ID);
				}
				else {
					registerGatewayInstance(normalizeGatewayInstanceConfig(decodeJson(raw)));
				}
				return getGatewayInstanceSettingValue();
			}
			throw(message="Unsupported event gateway setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		catch(any e){
			return "set FAILED. #e.message# #e.detail#";
		}
	}

	public void function ensureTestGatewayTypeAbsent(){
		deleteGatewayTypeByName(variables.TEST_GATEWAY_TYPE);
	}

	public void function ensureTestGatewayInstanceAbsent(){
		deleteGatewayInstanceById(variables.TEST_GATEWAY_INSTANCE_ID);
	}

	public boolean function configsMatch(required any expectedValue, required any actualValue){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		var expected = normalizeConfigPayload(arguments.expectedValue);
		var actual = normalizeConfigPayload(arguments.actualValue);
		return serializeJSON(expected) EQ serializeJSON(actual);
	}

	private struct function normalizeConfigPayload(required any payload){
		var decoded = "";
		if(isStruct(arguments.payload) OR isArray(arguments.payload))
			decoded = arguments.payload;
		else if(isQuery(arguments.payload))
			decoded = decodeJson(encodeJson(queryToArray(arguments.payload)));
		else
			decoded = decodeJson(trim("" & arguments.payload));
		if(NOT isStruct(decoded))
			return {};
		return normalizeStructKeys(decoded);
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

	public boolean function scalarValuesMatch(required any expectedValue, required any actualValue, string settingName = ""){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		var expectedText = trim("" & arguments.expectedValue);
		var actualText = trim("" & arguments.actualValue);
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.ENABLE_GATEWAY_SERVICE_SETTING)){
			return normalizeBooleanString(expectedText) EQ normalizeBooleanString(actualText);
		}
		if(isNumeric(expectedText) AND isNumeric(actualText))
			return val(expectedText) EQ val(actualText);
		return expectedText EQ actualText;
	}

	private struct function normalizeStructKeys(required struct data){
		var normalized = {};
		var keys = structKeyArray(arguments.data);
		arraySort(keys, "text", "asc");
		for(var key in keys){
			var normalizedKey = lCase(key);
			if(isArray(arguments.data[key])){
				if(normalizedKey EQ "cfcpaths")
					normalized[normalizedKey] = normalizePathList(arguments.data[key]);
				else
					normalized[normalizedKey] = arguments.data[key];
			}
			else if(isStruct(arguments.data[key]))
				normalized[normalizedKey] = normalizeStructKeys(arguments.data[key]);
			else if(isNumeric(arguments.data[key]))
				normalized[normalizedKey] = val(arguments.data[key]);
			else if(isBoolean(arguments.data[key]))
				normalized[normalizedKey] = (arguments.data[key] ? true : false);
			else if(normalizedKey EQ "configurationpath")
				normalized[normalizedKey] = normalizePathValue(arguments.data[key]);
			else
				normalized[normalizedKey] = arguments.data[key];
		}
		return normalized;
	}

	public any function extractGatewayTypeFieldValue(required struct config, required string fieldName){
		switch(lCase(trim(arguments.fieldName))){
			case "type": return structKeyExists(arguments.config, "type") ? arguments.config.type : "";
			case "description": return structKeyExists(arguments.config, "description") ? arguments.config.description : "";
			case "class": return structKeyExists(arguments.config, "class") ? arguments.config.class : "";
			case "starttimeout": return structKeyExists(arguments.config, "startTimeout") ? arguments.config.startTimeout : "";
			case "killontimeout": return structKeyExists(arguments.config, "killOnTimeout") ? arguments.config.killOnTimeout : "";
			default: return "";
		}
	}

	public any function extractGatewayInstanceFieldValue(required struct config, required string fieldName){
		switch(lCase(trim(arguments.fieldName))){
			case "gatewayid": return structKeyExists(arguments.config, "gatewayId") ? arguments.config.gatewayId : "";
			case "type": return structKeyExists(arguments.config, "type") ? arguments.config.type : "";
			case "cfcpaths":
				return structKeyExists(arguments.config, "cfcPaths") AND isArray(arguments.config.cfcPaths)
					? arrayToList(arguments.config.cfcPaths, "; ") : "";
			case "configurationpath": return structKeyExists(arguments.config, "configurationPath") ? arguments.config.configurationPath : "";
			case "mode": return structKeyExists(arguments.config, "mode") ? arguments.config.mode : "";
			default: return "";
		}
	}

	public struct function applyGatewayTypeFieldValue(required struct config, required string fieldName, required any fieldValue){
		var updated = duplicate(arguments.config);
		switch(lCase(trim(arguments.fieldName))){
			case "type": updated.type = uCase(trim("" & arguments.fieldValue)); break;
			case "description": updated.description = trim("" & arguments.fieldValue); break;
			case "class": updated.class = trim("" & arguments.fieldValue); break;
			case "starttimeout": updated.startTimeout = val(arguments.fieldValue); break;
			case "killontimeout": updated.killOnTimeout = (arguments.fieldValue ? true : false); break;
			default:
				throw(message="Unsupported gateway type field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
		return updated;
	}

	public struct function applyGatewayInstanceFieldValue(required struct config, required string fieldName, required any fieldValue){
		var updated = duplicate(arguments.config);
		switch(lCase(trim(arguments.fieldName))){
			case "gatewayid": updated.gatewayId = trim("" & arguments.fieldValue); break;
			case "type": updated.type = uCase(trim("" & arguments.fieldValue)); break;
			case "cfcpaths":
				if(isArray(arguments.fieldValue))
					updated.cfcPaths = arguments.fieldValue;
				else
					updated.cfcPaths = listToArray(replace(trim("" & arguments.fieldValue), ";", ",", "all"), ",", false, true);
				break;
			case "configurationpath": updated.configurationPath = trim("" & arguments.fieldValue); break;
			case "mode": updated.mode = lCase(trim("" & arguments.fieldValue)); break;
			default:
				throw(message="Unsupported gateway instance field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
		return updated;
	}

	public any function getTestValueForGatewayTypeField(required string fieldName, struct baseConfig = {}){
		var cfg = structIsEmpty(arguments.baseConfig) ? getDefaultGatewayTypeConfig() : arguments.baseConfig;
		switch(lCase(trim(arguments.fieldName))){
			case "type":
				return variables.TEST_GATEWAY_TYPE;
			case "description":
				return findNoCase("_ccs", cfg.description) ? "CCS test gateway type" : "CCS test gateway type_ccs";
			case "class":
				return (structKeyExists(cfg, "class") AND compareNoCase(cfg.class, variables.DEFAULT_GATEWAY_TYPE_CLASS) EQ 0)
					? variables.ALT_GATEWAY_TYPE_CLASS : variables.DEFAULT_GATEWAY_TYPE_CLASS;
			case "starttimeout":
				return (structKeyExists(cfg, "startTimeout") AND val(cfg.startTimeout) EQ 30) ? 45 : 30;
			case "killontimeout":
				return NOT (structKeyExists(cfg, "killOnTimeout") AND cfg.killOnTimeout);
			default:
				throw(message="Unsupported gateway type field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
	}

	public any function getTestValueForGatewayInstanceField(required string fieldName, struct baseConfig = {}){
		var cfg = structIsEmpty(arguments.baseConfig) ? getDefaultGatewayInstanceConfig() : arguments.baseConfig;
		switch(lCase(trim(arguments.fieldName))){
			case "gatewayid":
				return variables.TEST_GATEWAY_INSTANCE_ID;
			case "type":
				return variables.DEFAULT_INSTANCE_TYPE;
			case "cfcpaths":
				var testPath = getTestGatewayCfcPath();
				var altPath = getAltGatewayCfcPath();
				if(structKeyExists(cfg, "cfcPaths") AND isArray(cfg.cfcPaths) AND arrayLen(cfg.cfcPaths)){
					if(normalizePathValue(cfg.cfcPaths[1]) EQ normalizePathValue(testPath))
						return [altPath];
				}
				return [testPath];
			case "configurationpath":
				var testPath = getTestGatewayConfigurationPath();
				if(structKeyExists(cfg, "configurationPath") AND len(trim("" & cfg.configurationPath)))
					return "";
				return testPath;
			case "mode":
				return (structKeyExists(cfg, "mode") AND lCase(cfg.mode) EQ "manual") ? "auto" : "manual";
			default:
				throw(message="Unsupported gateway instance field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
	}

	public string function getNewSetValueForSetting(required string settingName, any currentValue = ""){
		var value = trim("" & arguments.currentValue);
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.ENABLE_GATEWAY_SERVICE_SETTING):
				var enabled = (value EQ "true" OR value EQ "1" OR value EQ "yes");
				return enabled ? "false" : "true";
			case lCase(variables.THREAD_POOL_SIZE_SETTING):
				var poolSize = val(value);
				if(poolSize GT 0)
					return "" & (poolSize - 1);
				return "1";
			case lCase(variables.MAX_QUEUE_SIZE_SETTING):
				var queueSize = val(value);
				if(queueSize GT 1)
					return "" & (queueSize - 1);
				return "10";
			default:
				throw(message="Unsupported event gateway setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public string function formatSettingsDisplayValue(required string settingName, required any value){
		var text = trim("" & arguments.value);
		if(NOT len(text))
			return "(empty)";
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.ENABLE_GATEWAY_SERVICE_SETTING))
			return normalizeBooleanString(text) ? "true" : "false";
		if(isNumeric(text))
			return "" & val(text);
		return text;
	}

	private boolean function normalizeBooleanString(required string value){
		var text = lCase(trim(arguments.value));
		return (text EQ "true" OR text EQ "1" OR text EQ "yes");
	}

	public any function getTestValueForSettingsField(required string settingName, any currentValue = ""){
		return getNewSetValueForSetting(arguments.settingName, arguments.currentValue);
	}

	public struct function buildGatewayTypeConfigForField(required string fieldName, any currentValue = ""){
		var baseConfig = getDefaultGatewayTypeConfig();
		var existing = decodeJson(arguments.currentValue);
		if(isStruct(existing) AND NOT structIsEmpty(existing))
			structAppend(baseConfig, existing, true);
		var testValue = getTestValueForGatewayTypeField(arguments.fieldName, baseConfig);
		return applyGatewayTypeFieldValue(baseConfig, arguments.fieldName, testValue);
	}

	public struct function buildGatewayInstanceConfigForField(required string fieldName, any currentValue = ""){
		var baseConfig = getDefaultGatewayInstanceConfig();
		var existing = decodeJson(arguments.currentValue);
		if(isStruct(existing) AND NOT structIsEmpty(existing))
			structAppend(baseConfig, existing, true);
		var testValue = getTestValueForGatewayInstanceField(arguments.fieldName, baseConfig);
		return applyGatewayInstanceFieldValue(baseConfig, arguments.fieldName, testValue);
	}

}
