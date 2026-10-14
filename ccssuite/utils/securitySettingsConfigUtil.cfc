/**
* Read/write ColdFusion Administrator Security > Settings (passkey + client certificate).
*/
component output="false" {

	variables.SETTING_CHALLENGE_STORE = "ChallengeStore";
	variables.SETTING_CHALLENGE_TTL = "ChallengeTtl";
	variables.SETTING_PASSKEY_DATASOURCE = "PasskeyDefaultDatasource";
	variables.SETTING_CLIENT_CERT_AUTH = "ClientCertAuthEnabled";
	variables.SETTING_CLIENT_CERT_ROOT = "ClientCertRootAdminEnabled";
	variables.SETTING_CLIENT_CERT_SOURCE = "ClientCertCertificateSource";
	variables.SETTING_CLIENT_CERT_HEADER = "ClientCertSubjectHeader";
	variables.SETTING_CLIENT_CERT_MATCH = "ClientCertMatchCriteria";

	variables.TEST_CHALLENGE_STORE_ALT = "ehcache";
	variables.TEST_CHALLENGE_TTL_ALT = "120";
	variables.TEST_PASSKEY_DATASOURCE_ALT = "cfartgallery";
	variables.TEST_CLIENT_CERT_HEADER_ALT = "X-SSL-Client-Cert-Subject";
	variables.TEST_CLIENT_CERT_MATCH_ALT = "cn";

	public function init(){
		variables.componentVersion = 1;
		return this;
	}

	public array function getAllSettingsNames(){
		return [
			variables.SETTING_CHALLENGE_STORE,
			variables.SETTING_CHALLENGE_TTL,
			variables.SETTING_PASSKEY_DATASOURCE,
			variables.SETTING_CLIENT_CERT_AUTH,
			variables.SETTING_CLIENT_CERT_ROOT,
			variables.SETTING_CLIENT_CERT_SOURCE,
			variables.SETTING_CLIENT_CERT_HEADER,
			variables.SETTING_CLIENT_CERT_MATCH
		];
	}

	public boolean function isSettingsSetting(required string settingName){
		return listFindNoCase(arrayToList(getAllSettingsNames()), trim(arguments.settingName)) GT 0;
	}

	private boolean function isPasskeySetting(required string settingName){
		return listFindNoCase(
			variables.SETTING_CHALLENGE_STORE & "," & variables.SETTING_CHALLENGE_TTL & "," & variables.SETTING_PASSKEY_DATASOURCE,
			trim(arguments.settingName)
		) GT 0;
	}

	private boolean function isClientCertSetting(required string settingName){
		return listFindNoCase(
			variables.SETTING_CLIENT_CERT_AUTH & "," & variables.SETTING_CLIENT_CERT_ROOT & "," &
			variables.SETTING_CLIENT_CERT_SOURCE & "," & variables.SETTING_CLIENT_CERT_HEADER & "," & variables.SETTING_CLIENT_CERT_MATCH,
			trim(arguments.settingName)
		) GT 0;
	}

	private string function getPasskeyApiKey(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_CHALLENGE_STORE): return "challengeStore";
			case lCase(variables.SETTING_CHALLENGE_TTL): return "challengeTtl";
			case lCase(variables.SETTING_PASSKEY_DATASOURCE): return "datasource";
			default: throw(message="Unsupported passkey setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	private string function getClientCertApiKey(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_CLIENT_CERT_AUTH): return "enabled";
			case lCase(variables.SETTING_CLIENT_CERT_ROOT): return "rootAdminEnabled";
			case lCase(variables.SETTING_CLIENT_CERT_SOURCE): return "useCGI";
			case lCase(variables.SETTING_CLIENT_CERT_HEADER): return "subjectHeader";
			case lCase(variables.SETTING_CLIENT_CERT_MATCH): return "matchCriteria";
			default: throw(message="Unsupported client cert setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
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

	private any function getSecurityAdminApi(){
		return createObject("component", "CFIDE.adminapi.security");
	}

	private struct function readPasskeyConfig(){
		var admin = loginAdmin();
		try {
			return getSecurityAdminApi().getPasskeyConfig();
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private struct function readClientCertConfig(){
		var admin = loginAdmin();
		try {
			return getClientCertConfigWithNeoMerge(getSecurityAdminApi().getClientCertConfig());
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private struct function getClientCertConfigWithNeoMerge(required struct apiConfig){
		var config = duplicate(arguments.apiConfig);
		try {
			var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
			var cfg = secUtil.readSecurityConfigMapPublic();
			if(structKeyExists(cfg, "ClientCertConfig") AND isStruct(cfg.ClientCertConfig)){
				var neo = cfg.ClientCertConfig;
				if(NOT len(trim("" & config.subjectHeader)) AND structKeyExists(neo, "subjectHeader"))
					config.subjectHeader = trim("" & neo.subjectHeader);
				if(NOT len(trim("" & config.matchCriteria)) AND structKeyExists(neo, "matchCriteria"))
					config.matchCriteria = trim("" & neo.matchCriteria);
			}
		}
		catch(any e){}
		return config;
	}

	private void function syncClientCertConfigToNeo(required struct config){
		try {
			var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
			var cfg = secUtil.readSecurityConfigMapPublic();
			if(NOT structKeyExists(cfg, "ClientCertConfig") OR NOT isStruct(cfg.ClientCertConfig))
				cfg.ClientCertConfig = {};
			cfg.ClientCertConfig.enabled = javaCast("boolean", toBoolean(arguments.config.enabled));
			cfg.ClientCertConfig.rootAdminEnabled = javaCast("boolean", toBoolean(arguments.config.rootAdminEnabled));
			cfg.ClientCertConfig.useCGI = javaCast("boolean", toBoolean(arguments.config.useCGI));
			cfg.ClientCertConfig.subjectHeader = trim("" & arguments.config.subjectHeader);
			cfg.ClientCertConfig.matchCriteria = trim("" & arguments.config.matchCriteria);
			secUtil.writeSecurityConfigMapPublic(cfg);
		}
		catch(any e){}
	}

	private string function readPasskeySettingValue(required string settingName){
		var config = readPasskeyConfig();
		var key = getPasskeyApiKey(arguments.settingName);
		if(NOT structKeyExists(config, key))
			return "";
		return trim("" & config[key]);
	}

	private string function readClientCertSettingValue(required string settingName){
		var config = readClientCertConfig();
		var key = getClientCertApiKey(arguments.settingName);
		if(NOT structKeyExists(config, key))
			return "";
		if(key EQ "enabled" OR key EQ "rootAdminEnabled" OR key EQ "useCGI")
			return formatBooleanSettingValue(config[key]);
		return trim("" & config[key]);
	}

	public string function getSettingsSetting(required string settingName){
		if(isPasskeySetting(arguments.settingName))
			return readPasskeySettingValue(arguments.settingName);
		if(isClientCertSetting(arguments.settingName))
			return readClientCertSettingValue(arguments.settingName);
		throw(message="Unsupported security settings setting: #arguments.settingName#", type="CCSTest.ConfigError");
	}

	private string function writePasskeySettingValue(required string settingName, required any settingValue){
		var admin = loginAdmin();
		try {
			var security = getSecurityAdminApi();
			var config = security.getPasskeyConfig();
			var key = getPasskeyApiKey(arguments.settingName);
			config[key] = trim("" & arguments.settingValue);
			security.setPasskeyConfig(config);
			return trim("" & security.getPasskeyConfig()[key]);
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private string function writeClientCertSettingValue(required string settingName, required any settingValue){
		var admin = loginAdmin();
		try {
			var security = getSecurityAdminApi();
			var config = security.getClientCertConfig();
			var key = getClientCertApiKey(arguments.settingName);
			var valToSet = arguments.settingValue;
			if(key EQ "enabled" OR key EQ "rootAdminEnabled" OR key EQ "useCGI")
				valToSet = javaCast("boolean", toBoolean(arguments.settingValue));
			else
				valToSet = trim("" & arguments.settingValue);
			config[key] = valToSet;

			if(key EQ "enabled"){
				if(valToSet EQ true){
					if(NOT config.useCGI AND NOT len(trim("" & config.subjectHeader)))
						config.subjectHeader = "SSL_CLIENT_S_DN";
				} else if(trim("" & config.subjectHeader) EQ "SSL_CLIENT_S_DN"){
					config.subjectHeader = "";
				}
			}

			security.setClientCertConfig(config);
			syncClientCertConfigToNeo(config);
			var updated = security.getClientCertConfig();
			if(key EQ "enabled" OR key EQ "rootAdminEnabled" OR key EQ "useCGI")
				return formatBooleanSettingValue(updated[key]);
			return trim("" & updated[key]);
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function setSettingsSetting(required string settingName, required any settingValue){
		if(isPasskeySetting(arguments.settingName))
			return writePasskeySettingValue(arguments.settingName, arguments.settingValue);
		if(isClientCertSetting(arguments.settingName))
			return writeClientCertSettingValue(arguments.settingName, arguments.settingValue);
		throw(message="Unsupported security settings setting: #arguments.settingName#", type="CCSTest.ConfigError");
	}

	public string function getNewSetValueForSetting(required string settingName, any currentValue = ""){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_CHALLENGE_STORE):
				return settingsValuesMatch(variables.TEST_CHALLENGE_STORE_ALT, arguments.currentValue, arguments.settingName)
					? "memory" : variables.TEST_CHALLENGE_STORE_ALT;
			case lCase(variables.SETTING_CHALLENGE_TTL):
				return settingsValuesMatch(variables.TEST_CHALLENGE_TTL_ALT, arguments.currentValue, arguments.settingName)
					? "60" : variables.TEST_CHALLENGE_TTL_ALT;
			case lCase(variables.SETTING_PASSKEY_DATASOURCE):
				return settingsValuesMatch(variables.TEST_PASSKEY_DATASOURCE_ALT, arguments.currentValue, arguments.settingName)
					? "" : variables.TEST_PASSKEY_DATASOURCE_ALT;
			case lCase(variables.SETTING_CLIENT_CERT_AUTH):
			case lCase(variables.SETTING_CLIENT_CERT_ROOT):
			case lCase(variables.SETTING_CLIENT_CERT_SOURCE):
				return formatBooleanSettingValue(arguments.currentValue) EQ "true" ? "false" : "true";
			case lCase(variables.SETTING_CLIENT_CERT_HEADER):
				return settingsValuesMatch(variables.TEST_CLIENT_CERT_HEADER_ALT, arguments.currentValue, arguments.settingName)
					? "" : variables.TEST_CLIENT_CERT_HEADER_ALT;
			case lCase(variables.SETTING_CLIENT_CERT_MATCH):
				return settingsValuesMatch(variables.TEST_CLIENT_CERT_MATCH_ALT, arguments.currentValue, arguments.settingName)
					? "exact" : variables.TEST_CLIENT_CERT_MATCH_ALT;
			default:
				throw(message="Unsupported security settings setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public boolean function settingsValuesMatch(required any expectedValue, required any actualValue, required string settingName){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_CHALLENGE_STORE):
				return normalizeChallengeStoreValue(arguments.expectedValue) EQ normalizeChallengeStoreValue(arguments.actualValue);
			case lCase(variables.SETTING_CHALLENGE_TTL):
				return trim("" & arguments.expectedValue) EQ trim("" & arguments.actualValue);
			case lCase(variables.SETTING_PASSKEY_DATASOURCE):
				return lCase(trim("" & arguments.expectedValue)) EQ lCase(trim("" & arguments.actualValue));
			case lCase(variables.SETTING_CLIENT_CERT_AUTH):
			case lCase(variables.SETTING_CLIENT_CERT_ROOT):
			case lCase(variables.SETTING_CLIENT_CERT_SOURCE):
				return formatBooleanSettingValue(arguments.expectedValue) EQ formatBooleanSettingValue(arguments.actualValue);
			case lCase(variables.SETTING_CLIENT_CERT_HEADER):
				return trim("" & arguments.expectedValue) EQ trim("" & arguments.actualValue);
			case lCase(variables.SETTING_CLIENT_CERT_MATCH):
				return normalizeMatchCriteriaValue(arguments.expectedValue) EQ normalizeMatchCriteriaValue(arguments.actualValue);
			default:
				return lCase(trim("" & arguments.expectedValue)) EQ lCase(trim("" & arguments.actualValue));
		}
	}

	public string function formatDisplayValue(required string settingName, required any value){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_CHALLENGE_STORE):
				return formatChallengeStoreDisplay(arguments.value);
			case lCase(variables.SETTING_CHALLENGE_TTL):
				var ttl = trim("" & arguments.value);
				return len(ttl) ? ttl & " seconds" : "(empty)";
			case lCase(variables.SETTING_PASSKEY_DATASOURCE):
				var ds = trim("" & arguments.value);
				return len(ds) ? ds : "None";
			case lCase(variables.SETTING_CLIENT_CERT_AUTH):
			case lCase(variables.SETTING_CLIENT_CERT_ROOT):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "Enabled" : "Disabled";
			case lCase(variables.SETTING_CLIENT_CERT_SOURCE):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "CGI Variable" : "HTTP Header";
			case lCase(variables.SETTING_CLIENT_CERT_HEADER):
				var header = trim("" & arguments.value);
				return len(header) ? header : "(empty)";
			case lCase(variables.SETTING_CLIENT_CERT_MATCH):
				return formatMatchCriteriaDisplay(arguments.value);
			default:
				return trim("" & arguments.value);
		}
	}

	private string function formatChallengeStoreDisplay(required any value){
		switch(normalizeChallengeStoreValue(arguments.value)){
			case "memory": return "Memory (In-Process)";
			case "ehcache": return "EhCache";
			case "servercache": return "Server Cache";
			default: return trim("" & arguments.value);
		}
	}

	private string function formatMatchCriteriaDisplay(required any value){
		switch(normalizeMatchCriteriaValue(arguments.value)){
			case "exact": return "Exact DN";
			case "cn": return "Common Name (CN)";
			default: return trim("" & arguments.value);
		}
	}

	private string function normalizeChallengeStoreValue(required any value){
		var text = lCase(trim("" & arguments.value));
		if(findNoCase("server", text))
			return "servercache";
		if(findNoCase("ehcache", text))
			return "ehcache";
		if(findNoCase("memory", text))
			return "memory";
		return text;
	}

	private string function normalizeMatchCriteriaValue(required any value){
		var text = lCase(trim("" & arguments.value));
		if(text EQ "cn" OR findNoCase("common name", text))
			return "cn";
		if(text EQ "exact" OR findNoCase("exact dn", text))
			return "exact";
		return text;
	}

	private boolean function toBoolean(required any value){
		if(isBoolean(arguments.value))
			return arguments.value;
		return listFindNoCase("true,yes,1", lCase(trim("" & arguments.value))) GT 0;
	}

	private string function formatBooleanSettingValue(required any value){
		return toBoolean(arguments.value) ? "true" : "false";
	}

}
