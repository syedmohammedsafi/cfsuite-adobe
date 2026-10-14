/**
* Read/write ColdFusion Administrator Extensions settings
* (CFX tags and custom tag paths via CFIDE.adminapi.extensions + neo-runtime.xml).
*/
component output="false" {

	variables.JAVA_CFX_SETTING = "JavaCfx";
	variables.CPP_CFX_SETTING = "CppCfx";
	variables.CUSTOM_TAG_PATHS_SETTING = "CustomTagPaths";
	variables.CCS_ADD_TEST_CUSTOM_TAG_PATH = "CCS_ADD_TEST_CUSTOM_TAG_PATH";
	variables.CCS_REMOVE_TEST_CUSTOM_TAG_PATH = "CCS_REMOVE_TEST_CUSTOM_TAG_PATH";
	variables.TEST_JAVA_CFX_TAG = "cfx_ccs_test";
	variables.TEST_CPP_CFX_TAG = "cfx_ccs_cpp_test";
	variables.TEST_JAVA_CFX_CLASS = "CCSTestJavaCfx";
	variables.DEFAULT_CPP_PROCEDURE = "ProcessTagRequest";

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

	private any function createExtensionsApi(){
		return createObject("component", "CFIDE.adminapi.extensions");
	}

	private any function getExtensionsApi(){
		return createExtensionsApi();
	}

	public string function getNeoRuntimePath(){
		var constants = getConstants();
		return server.coldfusion.rootdir & constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & constants.SYS_CONFIG.FILE_SEPARATOR & "neo-runtime.xml";
	}

	private array function loadRuntimeConfig(){
		var configPath = getNeoRuntimePath();
		var lockName = "ccs-neo-runtime-" & hash(configPath);
		var lastError = {};
		lock name="#lockName#" type="readonly" timeout="30" {
			for(var attempt = 1; attempt LTE 3; attempt++){
				try {
					var content = trim(fileRead(configPath));
					if(NOT len(content))
						throw(message="neo-runtime.xml is empty", type="CCSTest.ConfigError");
					var cfg = [];
					cfwddx(action="WDDX2CFML", input=content, output="cfg");
					if(NOT isArray(cfg) OR arrayLen(cfg) LT 5)
						throw(message="invalid neo-runtime.xml structure", type="CCSTest.ConfigError");
					return cfg;
				}
				catch(any e){
					lastError = e;
					if(attempt LT 3) sleep(50);
				}
			}
		}
		throw(message=lastError.message, detail=lastError.detail, type="CCSTest.ConfigError");
	}

	private struct function getCfxTagsStruct(){
		var cfg = loadRuntimeConfig();
		var cfxSlot = cfg[3];
		return isStruct(cfxSlot) ? cfxSlot : {};
	}

	private struct function getCustomTagPathsStruct(){
		var cfg = loadRuntimeConfig();
		var pathSlot = cfg[4];
		return isStruct(pathSlot) ? pathSlot : {};
	}

	private string function findStructKey(required struct data, required string key){
		for(var existingKey in arguments.data){
			if(compareNoCase(existingKey, arguments.key) EQ 0)
				return existingKey;
		}
		return arguments.key;
	}

	private any function getStructFieldIgnoreCase(required struct data, required string fieldName){
		var key = findStructKey(arguments.data, arguments.fieldName);
		if(structKeyExists(arguments.data, key))
			return arguments.data[key];
		return "";
	}

	private struct function normalizeJavaCfxConfig(required struct config){
		var normalized = getDefaultJavaCfxConfig();
		var tagName = trim("" & getStructFieldIgnoreCase(arguments.config, "tagName"));
		if(len(tagName))
			normalized.tagName = normalizeCfxTagName(tagName);
		var className = trim("" & getStructFieldIgnoreCase(arguments.config, "className"));
		if(len(className))
			normalized.className = className;
		if(len(trim("" & getStructFieldIgnoreCase(arguments.config, "description"))))
			normalized.description = trim("" & getStructFieldIgnoreCase(arguments.config, "description"));
		return normalized;
	}

	private struct function normalizeCppCfxConfig(required struct config){
		var normalized = getDefaultCppCfxConfig();
		var tagName = trim("" & getStructFieldIgnoreCase(arguments.config, "tagName"));
		if(len(tagName))
			normalized.tagName = normalizeCfxTagName(tagName);
		var serverLibrary = trim("" & getStructFieldIgnoreCase(arguments.config, "serverLibrary"));
		if(len(serverLibrary)){
			serverLibrary = replace(serverLibrary, "\", "/", "all");
			if(len(tagName) AND compareNoCase(normalizeCfxTagName(tagName), variables.TEST_CPP_CFX_TAG) EQ 0)
				normalized.serverLibrary = getTestCppCfxLibraryPath();
			else if(NOT fileExists(replace(serverLibrary, "/", "\", "all")))
				normalized.serverLibrary = getTestCppCfxLibraryPath();
			else
				normalized.serverLibrary = serverLibrary;
		}
		var procedure = trim("" & getStructFieldIgnoreCase(arguments.config, "procedure"));
		if(len(procedure))
			normalized.procedure = procedure;
		var keepLoaded = getStructFieldIgnoreCase(arguments.config, "keepLibraryLoaded");
		if(len(trim("" & keepLoaded)) OR isBoolean(keepLoaded))
			normalized.keepLibraryLoaded = (keepLoaded ? true : false);
		if(len(trim("" & getStructFieldIgnoreCase(arguments.config, "description"))))
			normalized.description = trim("" & getStructFieldIgnoreCase(arguments.config, "description"));
		return normalized;
	}

	public string function normalizeCfxTagName(required string tagName){
		var name = lCase(trim(arguments.tagName));
		if(NOT len(name))
			return variables.TEST_JAVA_CFX_TAG;
		if(left(name, 4) NEQ "cfx_")
			name = "cfx_" & name;
		return name;
	}

	public struct function getDefaultJavaCfxConfig(){
		return {
			"tagName": variables.TEST_JAVA_CFX_TAG,
			"className": variables.TEST_JAVA_CFX_CLASS,
			"description": "CCS test Java CFX tag"
		};
	}

	public struct function getDefaultCppCfxConfig(){
		return {
			"tagName": variables.TEST_CPP_CFX_TAG,
			"serverLibrary": getTestCppCfxLibraryPath(),
			"procedure": variables.DEFAULT_CPP_PROCEDURE,
			"keepLibraryLoaded": true,
			"description": "CCS test C++ CFX tag"
		};
	}

	public string function getTestCppCfxLibraryPath(){
		var constants = getConstants();
		return replace(server.coldfusion.rootdir & constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & constants.SYS_CONFIG.FILE_SEPARATOR & "CFXNeo.dll", "\", "/", "all");
	}

	public string function getAddTestCustomTagPathToken(){
		return variables.CCS_ADD_TEST_CUSTOM_TAG_PATH;
	}

	public string function getRemoveTestCustomTagPathToken(){
		return variables.CCS_REMOVE_TEST_CUSTOM_TAG_PATH;
	}

	public string function getTestCustomTagPath(){
		ensureConstants();
		return replace(server.coldfusion.rootdir & "/wwwroot/cfsuite/ccssuite/testAssets/extensions/customtags", "\", "/", "all");
	}

	public string function encodeJson(required any value){
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

	private struct function readRegisteredJavaCfx(required string tagName){
		var key = normalizeCfxTagName(arguments.tagName);
		var admin = loginAdmin();
		try {
			return getExtensionsApi().getCFX(key);
		}
		catch(any e){
			return {};
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private struct function readRegisteredCppCfx(required string tagName){
		return readRegisteredJavaCfx(arguments.tagName);
	}

	private struct function mapCfxStructToJavaConfig(required struct cfxInfo){
		if(structIsEmpty(arguments.cfxInfo))
			return {};
		var config = {};
		if(structKeyExists(arguments.cfxInfo, "NAME"))
			config.tagName = lCase(trim("" & arguments.cfxInfo.NAME));
		if(structKeyExists(arguments.cfxInfo, "CLASSNAME"))
			config.className = trim("" & arguments.cfxInfo.CLASSNAME);
		if(structKeyExists(arguments.cfxInfo, "DESCRIPTION"))
			config.description = trim("" & arguments.cfxInfo.DESCRIPTION);
		return config;
	}

	private struct function mapCfxStructToCppConfig(required struct cfxInfo){
		if(structIsEmpty(arguments.cfxInfo))
			return {};
		var config = mapCfxStructToJavaConfig(arguments.cfxInfo);
		if(structKeyExists(arguments.cfxInfo, "LIBRARY"))
			config.serverLibrary = trim("" & arguments.cfxInfo.LIBRARY);
		if(structKeyExists(arguments.cfxInfo, "PROCEDURE"))
			config.procedure = trim("" & arguments.cfxInfo.PROCEDURE);
		if(structKeyExists(arguments.cfxInfo, "CACHE"))
			config.keepLibraryLoaded = (arguments.cfxInfo.CACHE ? true : false);
		return config;
	}

	public string function getJavaCfxSettingValue(){
		var config = mapCfxStructToJavaConfig(readRegisteredJavaCfx(variables.TEST_JAVA_CFX_TAG));
		return encodeJson(config);
	}

	public string function getCppCfxSettingValue(){
		var config = mapCfxStructToCppConfig(readRegisteredCppCfx(variables.TEST_CPP_CFX_TAG));
		return encodeJson(config);
	}

	public string function getCustomTagPathsSettingValue(){
		var paths = [];
		var admin = loginAdmin();
		try {
			var rawPaths = getExtensionsApi().getCustomTagPaths();
			if(isArray(rawPaths)){
				for(var pathValue in rawPaths){
					pathValue = trim("" & pathValue);
					if(len(pathValue) AND arrayFindNoCase(normalizePathList(paths), normalizePathValue(pathValue)) EQ 0)
						arrayAppend(paths, replace(pathValue, "\", "/", "all"));
				}
			}
			else if(isStruct(rawPaths)){
				for(var key in rawPaths){
					var pathValue = trim("" & rawPaths[key]);
					if(len(pathValue) AND arrayFindNoCase(normalizePathList(paths), normalizePathValue(pathValue)) EQ 0)
						arrayAppend(paths, replace(pathValue, "\", "/", "all"));
				}
			}
		}
		catch(any e){}
		finally {
			logoutAdmin(admin);
		}
		return encodeJson(paths);
	}

	public string function getExtensionsSetting(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.JAVA_CFX_SETTING):
				return getJavaCfxSettingValue();
			case lCase(variables.CPP_CFX_SETTING):
				return getCppCfxSettingValue();
			case lCase(variables.CUSTOM_TAG_PATHS_SETTING):
				return getCustomTagPathsSettingValue();
			default:
				throw(message="Unsupported extensions setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	private void function registerJavaCfx(required struct config){
		var cfg = normalizeJavaCfxConfig(arguments.config);
		var admin = loginAdmin();
		try {
			getExtensionsApi().setJavaCFX(cfg.tagName, cfg.className, cfg.description);
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private void function registerCppCfx(required struct config){
		var cfg = normalizeCppCfxConfig(arguments.config);
		if(NOT fileExists(replace(cfg.serverLibrary, "/", "\", "all")))
			throw(message="C++ CFX library not found: #cfg.serverLibrary#", type="CCSTest.ConfigError");
		var admin = loginAdmin();
		try {
			getExtensionsApi().setCPPCFX(cfg.tagName, cfg.serverLibrary, cfg.description, cfg.keepLibraryLoaded, cfg.procedure);
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private void function deleteCfxTag(required string tagName){
		var key = normalizeCfxTagName(arguments.tagName);
		var admin = loginAdmin();
		try {
			try { getExtensionsApi().deleteCFX(key); } catch(any e){}
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function setExtensionsSetting(required string settingName, required any settingValue){
		var key = lCase(trim(arguments.settingName));
		var raw = trim("" & arguments.settingValue);
		try {
			if(key EQ lCase(variables.JAVA_CFX_SETTING)){
				if(raw EQ "register"){
					registerJavaCfx(getDefaultJavaCfxConfig());
				}
				else if(raw EQ "delete"){
					deleteCfxTag(variables.TEST_JAVA_CFX_TAG);
				}
				else {
					registerJavaCfx(normalizeJavaCfxConfig(decodeJson(raw)));
				}
				return getJavaCfxSettingValue();
			}
			if(key EQ lCase(variables.CPP_CFX_SETTING)){
				if(raw EQ "register"){
					registerCppCfx(getDefaultCppCfxConfig());
				}
				else if(raw EQ "delete"){
					deleteCfxTag(variables.TEST_CPP_CFX_TAG);
				}
				else {
					var parsedCppConfig = decodeJson(raw);
					if(NOT isStruct(parsedCppConfig))
						throw(message="CppCfx setValueTo must be JSON object, register, or delete", type="CCSTest.ConfigError");
					registerCppCfx(normalizeCppCfxConfig(parsedCppConfig));
				}
				return getCppCfxSettingValue();
			}
			if(key EQ lCase(variables.CUSTOM_TAG_PATHS_SETTING)){
				if(raw EQ variables.CCS_ADD_TEST_CUSTOM_TAG_PATH){
					addCustomTagPath(getTestCustomTagPath());
					return getCustomTagPathsSettingValue();
				}
				if(raw EQ variables.CCS_REMOVE_TEST_CUSTOM_TAG_PATH){
					removeCustomTagPath(getTestCustomTagPath());
					return getCustomTagPathsSettingValue();
				}
				var paths = isArray(decodeJson(raw)) ? decodeJson(raw) : [];
				for(var newPath in paths){
					addCustomTagPath(newPath);
				}
				return getCustomTagPathsSettingValue();
			}
			throw(message="Unsupported extensions setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		catch(any e){
			return "set FAILED. #e.message# #e.detail#";
		}
	}

	public void function addCustomTagPath(required string path){
		var pathValue = replace(trim(arguments.path), "\", "/", "all");
		if(NOT len(pathValue)) return;
		if(NOT directoryExists(pathValue))
			directoryCreate(pathValue);
		var admin = loginAdmin();
		try {
			getExtensionsApi().setCustomTagPath(pathValue);
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public void function removeCustomTagPath(required string path){
		var pathValue = replace(trim(arguments.path), "\", "/", "all");
		if(NOT len(pathValue)) return;
		var admin = loginAdmin();
		try {
			try { getExtensionsApi().deleteCustomTagPath(pathValue); } catch(any e){}
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function removeTestCustomTagPathFromJson(required string currentValue){
		var paths = decodeJson(arguments.currentValue);
		if(NOT isArray(paths)) paths = [];
		var testPath = getTestCustomTagPath();
		var filtered = [];
		for(var path in paths){
			if(compareNoCase(trim("" & path), testPath) NEQ 0)
				arrayAppend(filtered, path);
		}
		return encodeJson(filtered);
	}

	public string function withTestCustomTagPath(required string currentValue){
		var paths = decodeJson(arguments.currentValue);
		if(NOT isArray(paths)) paths = [];
		var testPath = getTestCustomTagPath();
		if(arrayFindNoCase(paths, testPath) EQ 0)
			arrayAppend(paths, testPath);
		return encodeJson(paths);
	}

	public void function ensureTestJavaCfxAbsent(){
		deleteCfxTag(variables.TEST_JAVA_CFX_TAG);
	}

	public void function ensureTestCppCfxAbsent(){
		deleteCfxTag(variables.TEST_CPP_CFX_TAG);
	}

	public void function ensureTestCustomTagPathAbsent(){
		removeCustomTagPath(getTestCustomTagPath());
	}

	public boolean function javaCfxRegistered(required any postValue){
		var config = decodeJson(arguments.postValue);
		if(NOT isStruct(config) OR structIsEmpty(config))
			config = mapCfxStructToJavaConfig(readRegisteredJavaCfx(variables.TEST_JAVA_CFX_TAG));
		return structKeyExists(config, "tagName")
			AND compareNoCase(config.tagName, variables.TEST_JAVA_CFX_TAG) EQ 0
			AND structKeyExists(config, "className")
			AND len(trim("" & config.className));
	}

	public boolean function cppCfxRegistered(required any postValue){
		var config = decodeJson(arguments.postValue);
		if(NOT isStruct(config) OR structIsEmpty(config))
			config = mapCfxStructToCppConfig(readRegisteredCppCfx(variables.TEST_CPP_CFX_TAG));
		return structKeyExists(config, "tagName")
			AND compareNoCase(config.tagName, variables.TEST_CPP_CFX_TAG) EQ 0
			AND structKeyExists(config, "serverLibrary")
			AND len(trim("" & config.serverLibrary));
	}

	public boolean function customTagPathPresent(required any postValue, string expectedPath = ""){
		var paths = decodeJson(arguments.postValue);
		if(NOT isArray(paths)) paths = [];
		var marker = "/cfsuite/ccssuite/testassets/extensions/customtags";
		for(var path in paths){
			var normalized = lCase(replace(replace(trim("" & path), "\", "/", "all"), "//", "/", "all"));
			if(findNoCase(marker, normalized))
				return true;
		}
		if(len(trim(arguments.expectedPath))){
			var expected = lCase(replace(replace(trim(arguments.expectedPath), "\", "/", "all"), "//", "/", "all"));
			for(var path in paths){
				if(lCase(replace(replace(trim("" & path), "\", "/", "all"), "//", "/", "all")) EQ expected)
					return true;
			}
		}
		return false;
	}

	public boolean function setMatches(required any presetValue, required any actualValue, required any requestedValue){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		var requested = trim("" & arguments.requestedValue);
		if(requested EQ variables.CCS_REMOVE_TEST_CUSTOM_TAG_PATH)
			return NOT customTagPathPresent(arguments.actualValue, "");
		if(requested EQ variables.CCS_ADD_TEST_CUSTOM_TAG_PATH)
			return customTagPathPresent(arguments.actualValue, "");
		return configsMatch(arguments.requestedValue, arguments.actualValue);
	}

	public boolean function configsMatch(required any expectedValue, required any actualValue){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		var expected = decodeJson(arguments.expectedValue);
		var actual = decodeJson(arguments.actualValue);
		if(isArray(expected) OR isArray(actual)){
			return pathListsMatch(expected, actual);
		}
		if(NOT isStruct(expected)) expected = {};
		if(NOT isStruct(actual)) actual = {};
		if(isCppCfxTestConfig(expected) OR isCppCfxTestConfig(actual))
			return cppCfxConfigsMatch(expected, actual);
		return serializeJSON(normalizeStructKeys(expected)) EQ serializeJSON(normalizeStructKeys(actual));
	}

	private boolean function isCppCfxTestConfig(required struct config){
		var tagName = trim("" & getStructFieldIgnoreCase(arguments.config, "tagName"));
		return len(tagName) AND compareNoCase(tagName, variables.TEST_CPP_CFX_TAG) EQ 0;
	}

	private boolean function cppCfxConfigsMatch(required struct expected, required struct actual){
		var exp = normalizeCppCfxConfig(arguments.expected);
		var act = normalizeCppCfxConfig(arguments.actual);
		if(structIsEmpty(exp) AND structIsEmpty(act))
			return true;
		if(structIsEmpty(exp) OR structIsEmpty(act))
			return false;
		exp.serverLibrary = getCfxLibraryFileName(exp.serverLibrary);
		act.serverLibrary = getCfxLibraryFileName(act.serverLibrary);
		return serializeJSON(normalizeStructKeys(exp)) EQ serializeJSON(normalizeStructKeys(act));
	}

	private string function getCfxLibraryFileName(required string libraryPath){
		var path = replace(trim(arguments.libraryPath), "\", "/", "all");
		return lCase(listLast(path, "/"));
	}

	private boolean function pathListsMatch(required any expectedList, required any actualList){
		var expected = normalizePathList(isArray(arguments.expectedList) ? arguments.expectedList : []);
		var actual = normalizePathList(isArray(arguments.actualList) ? arguments.actualList : []);
		if(arrayLen(expected) NEQ arrayLen(actual)) return false;
		for(var item in expected){
			if(arrayFindNoCase(actual, item) EQ 0) return false;
		}
		return true;
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

	private string function normalizePathValue(required any pathValue){
		return lCase(replace(replace(trim("" & arguments.pathValue), "\", "/", "all"), "//", "/", "all"));
	}

	private struct function normalizeStructKeys(required struct data){
		var normalized = {};
		for(var key in structSort(arguments.data, "text", "asc")){
			normalized[key] = isStruct(arguments.data[key]) ? normalizeStructKeys(arguments.data[key]) : arguments.data[key];
		}
		return normalized;
	}

	public boolean function cfxFieldValuesMatch(required string configType, required string fieldName, required any left, required any right){
		if(lCase(arguments.configType) EQ "cpp" AND lCase(trim(arguments.fieldName)) EQ "serverlibrary")
			return compareNoCase(getCfxLibraryFileName(arguments.left), getCfxLibraryFileName(arguments.right)) EQ 0;
		if(isBoolean(arguments.left) OR isBoolean(arguments.right))
			return (arguments.left ? true : false) EQ (arguments.right ? true : false);
		if(isNumeric(arguments.left) AND isNumeric(arguments.right))
			return val(arguments.left) EQ val(arguments.right);
		return trim("" & arguments.left) EQ trim("" & arguments.right);
	}

	public any function extractJavaFieldValue(required struct config, required string fieldName){
		switch(lCase(trim(arguments.fieldName))){
			case "tagname": return getStructFieldIgnoreCase(arguments.config, "tagName");
			case "classname": return getStructFieldIgnoreCase(arguments.config, "className");
			case "description": return getStructFieldIgnoreCase(arguments.config, "description");
			default: return "";
		}
	}

	public any function extractCppFieldValue(required struct config, required string fieldName){
		switch(lCase(trim(arguments.fieldName))){
			case "tagname": return getStructFieldIgnoreCase(arguments.config, "tagName");
			case "serverlibrary": return getStructFieldIgnoreCase(arguments.config, "serverLibrary");
			case "procedure": return getStructFieldIgnoreCase(arguments.config, "procedure");
			case "keeplibraryloaded": return getStructFieldIgnoreCase(arguments.config, "keepLibraryLoaded");
			case "description": return getStructFieldIgnoreCase(arguments.config, "description");
			default: return "";
		}
	}

	public struct function applyJavaCfxFieldValue(required struct config, required string fieldName, required any fieldValue){
		var updated = duplicate(arguments.config);
		switch(lCase(trim(arguments.fieldName))){
			case "tagname": updated.tagName = normalizeCfxTagName(arguments.fieldValue); break;
			case "classname": updated.className = trim("" & arguments.fieldValue); break;
			case "description": updated.description = trim("" & arguments.fieldValue); break;
			default:
				throw(message="Unsupported Java CFX field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
		return updated;
	}

	public struct function applyCppCfxFieldValue(required struct config, required string fieldName, required any fieldValue){
		var updated = duplicate(arguments.config);
		switch(lCase(trim(arguments.fieldName))){
			case "tagname": updated.tagName = normalizeCfxTagName(arguments.fieldValue); break;
			case "serverlibrary": updated.serverLibrary = trim("" & arguments.fieldValue); break;
			case "procedure": updated.procedure = trim("" & arguments.fieldValue); break;
			case "keeplibraryloaded": updated.keepLibraryLoaded = (arguments.fieldValue ? true : false); break;
			case "description": updated.description = trim("" & arguments.fieldValue); break;
			default:
				throw(message="Unsupported C++ CFX field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
		return updated;
	}

	public any function getTestValueForJavaCfxField(required string fieldName, struct baseConfig = {}){
		var cfg = structIsEmpty(arguments.baseConfig) ? getDefaultJavaCfxConfig() : arguments.baseConfig;
		switch(lCase(trim(arguments.fieldName))){
			case "tagname":
				return variables.TEST_JAVA_CFX_TAG;
			case "classname":
				return (structKeyExists(cfg, "className") AND compareNoCase(cfg.className, variables.TEST_JAVA_CFX_CLASS) EQ 0)
					? "CCSTestJavaCfxAlt" : variables.TEST_JAVA_CFX_CLASS;
			case "description":
				return findNoCase("_ccs", cfg.description) ? "CCS test Java CFX tag" : "CCS test Java CFX tag_ccs";
			default:
				throw(message="Unsupported Java CFX field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
	}

	public any function getTestValueForCppCfxField(required string fieldName, struct baseConfig = {}){
		var cfg = structIsEmpty(arguments.baseConfig) ? getDefaultCppCfxConfig() : arguments.baseConfig;
		switch(lCase(trim(arguments.fieldName))){
			case "tagname":
				return variables.TEST_CPP_CFX_TAG;
			case "serverlibrary":
				return getTestCppCfxLibraryPath();
			case "procedure":
				return variables.DEFAULT_CPP_PROCEDURE;
			case "keeplibraryloaded":
				return NOT (structKeyExists(cfg, "keepLibraryLoaded") AND cfg.keepLibraryLoaded);
			case "description":
				return findNoCase("_ccs", cfg.description) ? "CCS test C++ CFX tag" : "CCS test C++ CFX tag_ccs";
			default:
				throw(message="Unsupported C++ CFX field: #arguments.fieldName#", type="CCSTest.ConfigError");
		}
	}

	public struct function buildJavaCfxConfigForField(required string fieldName, any currentValue = ""){
		var baseConfig = getDefaultJavaCfxConfig();
		var existing = decodeJson(arguments.currentValue);
		if(isStruct(existing) AND NOT structIsEmpty(existing))
			structAppend(baseConfig, existing, true);
		var testValue = getTestValueForJavaCfxField(arguments.fieldName, baseConfig);
		return applyJavaCfxFieldValue(baseConfig, arguments.fieldName, testValue);
	}

	public struct function buildCppCfxConfigForField(required string fieldName, any currentValue = ""){
		var baseConfig = getDefaultCppCfxConfig();
		var existing = decodeJson(arguments.currentValue);
		if(isStruct(existing) AND NOT structIsEmpty(existing))
			structAppend(baseConfig, existing, true);
		var testValue = getTestValueForCppCfxField(arguments.fieldName, baseConfig);
		return applyCppCfxFieldValue(baseConfig, arguments.fieldName, testValue);
	}

}
