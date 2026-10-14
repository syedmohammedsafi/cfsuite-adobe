/**
* Read/write ColdFusion Administrator Debugging & Logging settings
* (neo-debug.xml, neo-logging.xml, neo-metric.xml, neo-runtime logging props).
*/
component output="false" {

	variables.SCOPE_VAR_MAP = {
		"application" = "applicationvar",
		"cookie" = "cookievar",
		"server" = "servervar",
		"cgi" = "cgivar",
		"form" = "formvar",
		"session" = "sessionvar",
		"client" = "clientvar",
		"url" = "urlvar",
		"request" = "requestvar"
	};

	variables.METRIC_SETTINGS = "cfstat,cfconnectorport,cfmetrics,cfmetrics.pullfreq,cfstathost";
	variables.NUMERIC_DEBUG_OUTPUT_SETTINGS = "template_highlight_minimum";
	variables.DEFAULT_TEMPLATE_HIGHLIGHT_MINIMUM = 250;
	variables.LINE_DEBUGGER_SETTINGS = "line_debugger_enabled,line_debugger_port,max_debug_sessions";

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

	private string function normalizeKey(required string settingName){
		return lCase(trim(arguments.settingName));
	}

	private string function libPath(required string fileName){
		var constants = getConstants();
		return server.coldfusion.rootdir & constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & constants.SYS_CONFIG.FILE_SEPARATOR & arguments.fileName;
	}

	public string function getNeoDebugPath(){
		return libPath("neo-debug.xml");
	}

	public string function getNeoLoggingPath(){
		return libPath("neo-logging.xml");
	}

	public string function getNeoMetricPath(){
		return libPath("neo-metric.xml");
	}

	public string function getNeoRuntimePath(){
		return libPath("neo-runtime.xml");
	}

	private string function normalizeLogDirectoryPath(required string pathValue){
		var path = replace(trim(arguments.pathValue), "\", "/", "all");
		if(len(path) AND right(path, 1) NEQ "/")
			path &= "/";
		return path;
	}

	private string function findStructKey(required struct data, required string key){
		for(var existingKey in arguments.data){
			if(compareNoCase(existingKey, arguments.key) EQ 0)
				return existingKey;
		}
		return arguments.key;
	}

	private string function getDebugConfigLockName(required string neoDebugPath){
		return "ccs-neo-debug-" & hash(arguments.neoDebugPath);
	}

	private array function loadDebugConfig(){
		var neoDebugPath = getNeoDebugPath();
		var lockName = getDebugConfigLockName(neoDebugPath);
		var lastError = {};

		lock name="#lockName#" type="readonly" timeout="30" {
			for(var attempt = 1; attempt LTE 3; attempt++){
				try {
					var neoDebugCfg = [];
					var content = trim(fileRead(neoDebugPath));
					if(NOT len(content))
						throw(message="neo-debug.xml is empty", type="CCSTest.ConfigError");
					cfwddx(action="WDDX2CFML", input=content, output="neoDebugCfg");
					if(NOT isArray(neoDebugCfg) OR arrayLen(neoDebugCfg) LT 2)
						throw(message="invalid neo-debug.xml structure", type="CCSTest.ConfigError");
					return neoDebugCfg;
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

	private void function saveDebugConfig(required array debugCfg){
		var neoDebugPath = getNeoDebugPath();
		var lockName = getDebugConfigLockName(neoDebugPath);

		lock name="#lockName#" type="exclusive" timeout="30" {
			var neoDebugWddx = "";
			cfwddx(action="CFML2WDDX", input=arguments.debugCfg, output="neoDebugWddx");
			if(NOT findNoCase("name='general'", neoDebugWddx))
				throw(message="refusing to write corrupted neo-debug.xml", type="CCSTest.ConfigError");
			fileWrite(neoDebugPath, neoDebugWddx);
		}
	}

	private struct function getDebugLineDebuggerStruct(){
		var cfg = loadDebugConfig();
		if(arrayLen(cfg) LT 3)
			throw(message="line debugger settings not found in neo-debug.xml", type="CCSTest.ConfigError");
		return cfg[3];
	}

	private void function saveDebugLineDebuggerStruct(required struct lineDebuggerStruct){
		var cfg = loadDebugConfig();
		if(arrayLen(cfg) LT 3)
			throw(message="line debugger settings not found in neo-debug.xml", type="CCSTest.ConfigError");
		cfg[3] = arguments.lineDebuggerStruct;
		saveDebugConfig(cfg);
	}

	private string function getLineDebuggerFileKey(required string settingName){
		switch(normalizeKey(arguments.settingName)){
			case "line_debugger_enabled":
				return "LINE_DEBUGGER_ENABLED";
			case "line_debugger_port":
				return "LINE_DEBUGGER_PORT";
			case "max_debug_sessions":
				return "MAX_DEBUG_SESSIONS";
			default:
				return uCase(trim(arguments.settingName));
		}
	}

	private boolean function isLineDebuggerSetting(required string settingName){
		return listFindNoCase(variables.LINE_DEBUGGER_SETTINGS, normalizeKey(arguments.settingName)) GT 0;
	}

	private any function readLineDebuggerNumeric(required any value){
		if(isNumeric(arguments.value) AND NOT listFindNoCase("true,false,yes,no", lCase(trim("" & arguments.value))))
			return val(arguments.value);
		if(isBoolean(arguments.value))
			return 0;
		return val(arguments.value);
	}

	private any function getDebugLineDebuggerValue(required string settingName){
		var fileKey = getLineDebuggerFileKey(arguments.settingName);
		var lineDebuggerStruct = getDebugLineDebuggerStruct();
		var structKey = findStructKey(lineDebuggerStruct, fileKey);
		if(NOT structKeyExists(lineDebuggerStruct, structKey))
			throw(message="#arguments.settingName# not found in neo-debug line debugger struct", type="CCSTest.ConfigError");

		var value = lineDebuggerStruct[structKey];
		if(fileKey EQ "LINE_DEBUGGER_ENABLED")
			return formatBooleanText(value);
		return readLineDebuggerNumeric(value);
	}

	private any function setDebugLineDebuggerValue(required string settingName, required any settingValue){
		var fileKey = getLineDebuggerFileKey(arguments.settingName);
		var lineDebuggerStruct = duplicate(getDebugLineDebuggerStruct());
		var structKey = findStructKey(lineDebuggerStruct, fileKey);
		if(NOT structKeyExists(lineDebuggerStruct, structKey))
			throw(message="#arguments.settingName# not found in neo-debug line debugger struct", type="CCSTest.ConfigError");

		if(fileKey EQ "LINE_DEBUGGER_ENABLED")
			lineDebuggerStruct[structKey] = parseBooleanText(arguments.settingValue);
		else
			lineDebuggerStruct[structKey] = val(arguments.settingValue);

		saveDebugLineDebuggerStruct(lineDebuggerStruct);
		return getDebugLineDebuggerValue(arguments.settingName);
	}

	private struct function getDebugOutputStruct(){
		var cfg = loadDebugConfig();
		return cfg[1];
	}

	private struct function getDebugAccessStruct(){
		var cfg = loadDebugConfig();
		return cfg[2];
	}

	private void function saveDebugStructs(required struct outputStruct, required struct accessStruct){
		var cfg = loadDebugConfig();
		cfg[1] = arguments.outputStruct;
		cfg[2] = arguments.accessStruct;
		if(arrayLen(cfg) GTE 3)
			saveDebugConfig(cfg);
	}

	private string function formatBooleanText(required any value){
		if(isBoolean(arguments.value))
			return arguments.value ? "true" : "false";
		return listFindNoCase("true,yes,1", lCase(trim("" & arguments.value))) ? "true" : "false";
	}

	private boolean function parseBooleanText(required string text){
		return listFindNoCase("true,yes,1", lCase(trim(arguments.text))) GT 0;
	}

	private string function normalizeDebugTemplateName(required string value){
		var text = replace(trim(arguments.value), "\", "/", "all");
		if(find("/", text))
			return listLast(text, "/");
		return text;
	}

	private string function toDebugTemplatePath(required string value){
		var fileName = normalizeDebugTemplateName(arguments.value);
		if(find("/", trim(arguments.value)))
			return replace(trim(arguments.value), "\", "/", "all");
		return "/WEB-INF/debug/" & fileName;
	}

	private string function getRuntimePropertyName(required string settingName){
		switch(normalizeKey(arguments.settingName)){
			case "logslowrequests":
				return "logSlowRequests";
			case "logrequesttimelimit":
				return "slowRequestTimeLimit";
			default:
				return arguments.settingName;
		}
	}

	private string function getRuntimeFileVarName(required string settingName){
		return getRuntimePropertyName(arguments.settingName);
	}

	private string function getRuntimeLoggingSettingType(required string settingName){
		return (normalizeKey(arguments.settingName) EQ "logslowrequests") ? "boolean" : "number";
	}

	private any function getRuntimeLoggingSettingFromFile(required string settingName){
		var key = getRuntimeFileVarName(arguments.settingName);
		var content = fileRead(getNeoRuntimePath());
		var markerPos = findVarMarker(content, key);
		if(getRuntimeLoggingSettingType(arguments.settingName) EQ "boolean"){
			var boolBounds = findBooleanValueBounds(content, markerPos);
			return formatBooleanText(mid(content, boolBounds[1], boolBounds[2] - boolBounds[1]));
		}
		var numBounds = findNumberValueBounds(content, markerPos);
		return val(trim(mid(content, numBounds[1], numBounds[2] - numBounds[1])));
	}

	private any function setRuntimeLoggingSettingInFile(required string settingName, required any settingValue){
		var path = getNeoRuntimePath();
		var lockName = getDebugConfigLockName(path);
		lock name="#lockName#" type="exclusive" timeout="30" {
			var content = fileRead(path);
			var key = getRuntimeFileVarName(arguments.settingName);
			var markerPos = findVarMarker(content, key);
			var updated = "";
			if(getRuntimeLoggingSettingType(arguments.settingName) EQ "boolean"){
				var boolBounds = findBooleanValueBounds(content, markerPos);
				var boolValue = parseBooleanText(arguments.settingValue) ? "true" : "false";
				updated = left(content, boolBounds[1] - 1) & boolValue &
					mid(content, boolBounds[2], len(content) - boolBounds[2] + 1);
			}
			else {
				var numBounds = findNumberValueBounds(content, markerPos);
				updated = left(content, numBounds[1] - 1) & val(arguments.settingValue) &
					mid(content, numBounds[2], len(content) - numBounds[2] + 1);
			}
			if(NOT findNoCase("name='logSlowRequests'", updated))
				throw(message="refusing to write corrupted neo-runtime.xml", type="CCSTest.ConfigError");
			fileWrite(path, updated);
		}
		return getRuntimeLoggingSettingFromFile(arguments.settingName);
	}

	private string function getLoggingFileVarName(required string settingName){
		switch(normalizeKey(arguments.settingName)){
			case "maxarchives":
				return "maxFileBackup";
			case "maxfilesize":
				return "maxFileSize";
			case "logdirectory":
				return "logDirectory";
			case "enableoslogging":
			case "enablescheduledtasklogging":
				return "enableOSLogging";
			default:
				return arguments.settingName;
		}
	}

	private string function getLoggingSettingType(required string settingName){
		switch(normalizeKey(arguments.settingName)){
			case "logdirectory":
				return "string";
			case "enableoslogging":
			case "enablescheduledtasklogging":
				return "boolean";
			default:
				return "number";
		}
	}

	private numeric function findVarMarker(required string content, required string varName){
		var markerPos = findNoCase("name='" & arguments.varName & "'", arguments.content);
		if(NOT markerPos)
			throw(message="#arguments.varName# not found in config xml", type="CCSTest.ConfigError");
		return markerPos;
	}

	private array function findNumberValueBounds(required string content, required numeric fromPos){
		var openTag = findNoCase("<number>", arguments.content, arguments.fromPos);
		var closeTag = findNoCase("</number>", arguments.content, openTag);
		if(NOT openTag OR NOT closeTag)
			throw(message="number tag not found in config xml", type="CCSTest.ConfigError");
		return [openTag + len("<number>"), closeTag];
	}

	private array function findStringValueBounds(required string content, required numeric fromPos){
		var openTag = findNoCase("<string>", arguments.content, arguments.fromPos);
		var closeTag = findNoCase("</string>", arguments.content, openTag);
		if(NOT openTag OR NOT closeTag)
			throw(message="string tag not found in config xml", type="CCSTest.ConfigError");
		return [openTag + len("<string>"), closeTag];
	}

	private array function findBooleanValueBounds(required string content, required numeric fromPos){
		var openTag = findNoCase("<boolean value='", arguments.content, arguments.fromPos);
		var valStart = openTag + len("<boolean value='");
		var quotePos = find("'", arguments.content, valStart);
		if(NOT openTag OR NOT quotePos)
			throw(message="boolean tag not found in config xml", type="CCSTest.ConfigError");
		return [valStart, quotePos];
	}

	private any function getLoggingSettingFromFile(required string settingName){
		var key = getLoggingFileVarName(arguments.settingName);
		var content = fileRead(getNeoLoggingPath());
		var markerPos = findVarMarker(content, key);
		switch(getLoggingSettingType(arguments.settingName)){
			case "boolean":
				var boolBounds = findBooleanValueBounds(content, markerPos);
				return formatBooleanText(mid(content, boolBounds[1], boolBounds[2] - boolBounds[1]));
			case "string":
				var strBounds = findStringValueBounds(content, markerPos);
				return normalizeLogDirectoryPath(mid(content, strBounds[1], strBounds[2] - strBounds[1]));
			default:
				var numBounds = findNumberValueBounds(content, markerPos);
				var numValue = val(trim(mid(content, numBounds[1], numBounds[2] - numBounds[1])));
				if(normalizeKey(arguments.settingName) EQ "maxfilesize")
					return int(numValue / 1000);
				return numValue;
		}
	}

	private any function setLoggingSettingInFile(required string settingName, required any settingValue){
		var path = getNeoLoggingPath();
		var lockName = getDebugConfigLockName(path);
		lock name="#lockName#" type="exclusive" timeout="30" {
			var content = fileRead(path);
			var key = getLoggingFileVarName(arguments.settingName);
			var markerPos = findVarMarker(content, key);
			var updated = "";
			switch(getLoggingSettingType(arguments.settingName)){
				case "boolean":
					var boolBounds = findBooleanValueBounds(content, markerPos);
					var boolValue = parseBooleanText(arguments.settingValue) ? "true" : "false";
					updated = left(content, boolBounds[1] - 1) & boolValue &
						mid(content, boolBounds[2], len(content) - boolBounds[2] + 1);
					break;
				case "string":
					var strBounds = findStringValueBounds(content, markerPos);
					updated = left(content, strBounds[1] - 1) & normalizeLogDirectoryPath(arguments.settingValue) &
						mid(content, strBounds[2], len(content) - strBounds[2] + 1);
					break;
				default:
					var numBounds = findNumberValueBounds(content, markerPos);
					var writeValue = val(arguments.settingValue);
					if(normalizeKey(arguments.settingName) EQ "maxfilesize")
						writeValue = writeValue * 1000;
					updated = left(content, numBounds[1] - 1) & writeValue &
						mid(content, numBounds[2], len(content) - numBounds[2] + 1);
			}
			if(NOT findNoCase("name='logDirectory'", updated))
				throw(message="refusing to write corrupted neo-logging.xml", type="CCSTest.ConfigError");
			fileWrite(path, updated);
		}
		return getLoggingSettingFromFile(arguments.settingName);
	}

	private string function getMetricSettingType(required string settingName){
		return (normalizeKey(arguments.settingName) EQ "cfmetrics.pullfreq") ? "number" : "string";
	}

	private any function getMetricSettingFromFile(required string settingName){
		var key = arguments.settingName;
		var content = fileRead(getNeoMetricPath());
		var markerPos = findVarMarker(content, key);
		if(getMetricSettingType(arguments.settingName) EQ "number"){
			var numBounds = findNumberValueBounds(content, markerPos);
			return val(trim(mid(content, numBounds[1], numBounds[2] - numBounds[1])));
		}
		var strBounds = findStringValueBounds(content, markerPos);
		return trim(mid(content, strBounds[1], strBounds[2] - strBounds[1]));
	}

	private any function setMetricSettingInFile(required string settingName, required any settingValue){
		var path = getNeoMetricPath();
		var content = fileRead(path);
		var key = arguments.settingName;
		var markerPos = findVarMarker(content, key);
		var updated = "";
		if(getMetricSettingType(arguments.settingName) EQ "number"){
			var numBounds = findNumberValueBounds(content, markerPos);
			updated = left(content, numBounds[1] - 1) & val(arguments.settingValue) &
				mid(content, numBounds[2], len(content) - numBounds[2] + 1);
		}
		else {
			var strBounds = findStringValueBounds(content, markerPos);
			updated = left(content, strBounds[1] - 1) & arguments.settingValue &
				mid(content, strBounds[2], len(content) - strBounds[2] + 1);
		}
		if(NOT findNoCase("name='cfmetrics'", updated))
			throw(message="refusing to write corrupted neo-metric.xml", type="CCSTest.ConfigError");
		fileWrite(path, updated);
		return getMetricSettingFromFile(arguments.settingName);
	}

	private boolean function isNumericDebugOutputSetting(required string settingName){
		return listFindNoCase(variables.NUMERIC_DEBUG_OUTPUT_SETTINGS, normalizeKey(arguments.settingName)) GT 0;
	}

	private numeric function readTemplateHighlightMinimum(required any value){
		if(isNumeric(arguments.value) AND NOT listFindNoCase("true,false,yes,no", lCase(trim("" & arguments.value))))
			return val(arguments.value);
		if(isBoolean(arguments.value))
			return variables.DEFAULT_TEMPLATE_HIGHLIGHT_MINIMUM;
		if(listFindNoCase("true,false,yes,no", lCase(trim("" & arguments.value)))){
			if(parseBooleanText(arguments.value))
				return variables.DEFAULT_TEMPLATE_HIGHLIGHT_MINIMUM;
			return 0;
		}
		return val(arguments.value);
	}

	private any function getDebugOutputValue(required string settingName){
		var key = normalizeKey(arguments.settingName);
		var outputStruct = getDebugOutputStruct();

		if(key EQ "variables_scopes"){
			var scopes = [];
			for(var scopeName in variables.SCOPE_VAR_MAP){
				var varKey = variables.SCOPE_VAR_MAP[scopeName];
				var structKey = findStructKey(outputStruct, varKey);
				if(structKeyExists(outputStruct, structKey) AND parseBooleanText(outputStruct[structKey]))
					arrayAppend(scopes, scopeName);
			}
			arraySort(scopes, "textnocase");
			return arrayToList(scopes, ",");
		}

		var fileKey = key;
		if(key EQ "timer")
			fileKey = "TIMER";
		if(key EQ "flashformcompileerrors")
			fileKey = "FLASHFORMCOMPILEERRORS";

		var structKey = findStructKey(outputStruct, fileKey);
		if(NOT structKeyExists(outputStruct, structKey))
			throw(message="#arguments.settingName# not found in neo-debug.xml", type="CCSTest.ConfigError");

		if(key EQ "template_highlight_minimum")
			return readTemplateHighlightMinimum(outputStruct[structKey]);

		var value = outputStruct[structKey];
		if(isNumeric(value) AND NOT listFindNoCase("true,false,yes,no", lCase(trim("" & value))))
			return val(value);
		if(isBoolean(value))
			return formatBooleanText(value);
		if(key EQ "debug_template")
			return normalizeDebugTemplateName(value);
		return trim("" & value);
	}

	private any function setDebugOutputValue(required string settingName, required any settingValue){
		var key = normalizeKey(arguments.settingName);
		var outputStruct = duplicate(getDebugOutputStruct());
		var accessStruct = duplicate(getDebugAccessStruct());

		if(key EQ "variables_scopes"){
			var selectedScopes = {};
			for(var scopeName in listToArray(arguments.settingValue, ",", false, true)){
				selectedScopes[lCase(trim(scopeName))] = true;
			}
			for(var scopeName in variables.SCOPE_VAR_MAP){
				var varKey = findStructKey(outputStruct, variables.SCOPE_VAR_MAP[scopeName]);
				outputStruct[varKey] = structKeyExists(selectedScopes, scopeName);
			}
			saveDebugStructs(outputStruct, accessStruct);
			return getDebugOutputValue(arguments.settingName);
		}

		var fileKey = key;
		if(key EQ "timer")
			fileKey = "TIMER";
		if(key EQ "flashformcompileerrors")
			fileKey = "FLASHFORMCOMPILEERRORS";

		var structKey = findStructKey(outputStruct, fileKey);
		if(NOT structKeyExists(outputStruct, structKey))
			throw(message="#arguments.settingName# not found in neo-debug.xml", type="CCSTest.ConfigError");

		if(key EQ "template_highlight_minimum"){
			outputStruct[structKey] = val(arguments.settingValue);
			saveDebugStructs(outputStruct, accessStruct);
			return getDebugOutputValue(arguments.settingName);
		}

		if(isBoolean(outputStruct[structKey]) OR listFindNoCase("true,false,yes,no", lCase(trim("" & arguments.settingValue))))
			outputStruct[structKey] = parseBooleanText(arguments.settingValue);
		else if(isNumeric(outputStruct[structKey]) OR isNumeric(arguments.settingValue))
			outputStruct[structKey] = val(arguments.settingValue);
		else if(key EQ "debug_template")
			outputStruct[structKey] = toDebugTemplatePath(arguments.settingValue);
		else
			outputStruct[structKey] = trim("" & arguments.settingValue);

		saveDebugStructs(outputStruct, accessStruct);
		return getDebugOutputValue(arguments.settingName);
	}

	private any function getDebugAccessValue(required string settingName){
		var key = normalizeKey(arguments.settingName);
		var accessStruct = getDebugAccessStruct();
		if(key EQ "developerprofile"){
			return formatBooleanText(accessStruct.developer_enabled);
		}
		if(key EQ "debuggingipaddress"){
			return formatCommaListValue(trim("" & accessStruct.iplist));
		}
		throw(message="#arguments.settingName# not found in neo-debug access struct", type="CCSTest.ConfigError");
	}

	private any function setDebugAccessValue(required string settingName, required any settingValue){
		var key = normalizeKey(arguments.settingName);
		var outputStruct = duplicate(getDebugOutputStruct());
		var accessStruct = duplicate(getDebugAccessStruct());

		if(key EQ "developerprofile"){
			accessStruct.developer_enabled = parseBooleanText(arguments.settingValue);
		}
		else if(key EQ "debuggingipaddress"){
			accessStruct.iplist = formatCommaListValue(trim("" & arguments.settingValue));
		}
		else {
			throw(message="#arguments.settingName# not found in neo-debug access struct", type="CCSTest.ConfigError");
		}

		saveDebugStructs(outputStruct, accessStruct);
		return getDebugAccessValue(arguments.settingName);
	}

	public string function getDebuggingIpAddress(){
		return getDebugAccessValue("debuggingIpAddress");
	}

	private struct function getRuntime(){
		var constants = getConstants();
		var admin = "";
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		admin = adminUtil.createAdministrator();
		adminUtil.login(constants.CF_CONFIG);
		return {
			admin = admin,
			adminUtil = adminUtil,
			api = createObject("component", "CFIDE.adminapi.runtime")
		};
	}

	private boolean function isRuntimeLoggingSetting(required string settingName){
		return listFindNoCase("logslowrequests,logrequesttimelimit", normalizeKey(arguments.settingName)) GT 0;
	}

	private boolean function isLoggingSetting(required string settingName){
		return listFindNoCase(
			"maxarchives,maxfilesize,logdirectory,enableoslogging,enablescheduledtasklogging",
			normalizeKey(arguments.settingName)
		) GT 0;
	}

	private boolean function isMetricSetting(required string settingName){
		return listFindNoCase(variables.METRIC_SETTINGS, normalizeKey(arguments.settingName)) GT 0;
	}

	private boolean function isAccessSetting(required string settingName){
		return listFindNoCase("developerprofile,debuggingipaddress", normalizeKey(arguments.settingName)) GT 0;
	}

	public any function getDebuggingSetting(required string settingName){
		ensureConstants();
		setting requesttimeout=120;
		if(isRuntimeLoggingSetting(arguments.settingName))
			return getRuntimeLoggingSettingFromFile(arguments.settingName);
		if(isLoggingSetting(arguments.settingName))
			return getLoggingSettingFromFile(arguments.settingName);
		if(isMetricSetting(arguments.settingName))
			return getMetricSettingFromFile(arguments.settingName);
		if(isAccessSetting(arguments.settingName))
			return getDebugAccessValue(arguments.settingName);
		if(isLineDebuggerSetting(arguments.settingName))
			return getDebugLineDebuggerValue(arguments.settingName);
		return getDebugOutputValue(arguments.settingName);
	}

	public any function setDebuggingSetting(required string settingName, required any settingValue){
		ensureConstants();
		setting requesttimeout=120;
		if(isRuntimeLoggingSetting(arguments.settingName))
			return setRuntimeLoggingSettingInFile(arguments.settingName, arguments.settingValue);
		if(isLoggingSetting(arguments.settingName))
			return setLoggingSettingInFile(arguments.settingName, arguments.settingValue);
		if(isMetricSetting(arguments.settingName))
			return setMetricSettingInFile(arguments.settingName, arguments.settingValue);
		if(isAccessSetting(arguments.settingName))
			return setDebugAccessValue(arguments.settingName, arguments.settingValue);
		if(isLineDebuggerSetting(arguments.settingName))
			return setDebugLineDebuggerValue(arguments.settingName, arguments.settingValue);
		return setDebugOutputValue(arguments.settingName, arguments.settingValue);
	}

	private string function normalizeCommaList(required string listValue){
		var items = [];
		for(var item in listToArray(arguments.listValue, ",", false, true)){
			item = lCase(trim(item));
			if(len(item) AND arrayFindNoCase(items, item) EQ 0)
				arrayAppend(items, item);
		}
		arraySort(items, "textnocase");
		return arrayToList(items, ",");
	}

	public string function formatCommaListValue(required string listValue){
		return normalizeCommaList(arguments.listValue);
	}

	public boolean function setMatches(
		required string settingName,
		required any presetValue,
		required any actualValue,
		required any requestedValue
	){
		var key = normalizeKey(arguments.settingName);
		if(key EQ "variables_scopes" OR key EQ "debuggingipaddress")
			return normalizeCommaList(arguments.actualValue) EQ normalizeCommaList(arguments.requestedValue);
		if(key EQ "debug_template")
			return compareNoCase(normalizeDebugTemplateName(arguments.actualValue), normalizeDebugTemplateName(arguments.requestedValue)) EQ 0;
		if(key EQ "template_highlight_minimum" OR key EQ "line_debugger_port" OR key EQ "max_debug_sessions" OR key EQ "logrequesttimelimit")
			return val(arguments.actualValue) EQ val(arguments.requestedValue);
		if(key EQ "logdirectory")
			return normalizeLogDirectoryPath(arguments.actualValue) EQ normalizeLogDirectoryPath(arguments.requestedValue);
		if(key EQ "line_debugger_enabled")
			return formatBooleanText(arguments.actualValue) EQ formatBooleanText(arguments.requestedValue);
		if(isBoolean(arguments.actualValue) OR listFindNoCase("true,false,yes,no", lCase(trim("" & arguments.actualValue))))
			return formatBooleanText(arguments.actualValue) EQ formatBooleanText(arguments.requestedValue);
		if(isNumeric(arguments.actualValue) OR isNumeric(arguments.requestedValue))
			return val(arguments.actualValue) EQ val(arguments.requestedValue);
		return trim("" & arguments.actualValue) EQ trim("" & arguments.requestedValue);
	}

}
