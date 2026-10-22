/**
* Read/write ColdFusion Administrator Security > SP Configuration settings.
*/
component output="false" {

	variables.TEST_SP_ADD_ALIAS = "ccsTestSpAdd";
	variables.TEST_SP_GEN_ALIAS = "ccsTestSpGen";
	variables.TEST_SP_FIELD_ALIAS = "ccsTestSpFields";
	variables.TEST_SP_FIELD_RENAME_ALIAS = "ccsTestSpFieldsRenamed";
	variables.TEST_SP_DESCRIPTION = "CCS test SP";
	variables.TEST_SP_DESCRIPTION_UPDATED = "CCS test SP updated description";
	variables.TEST_ENTITY_ID = "http://ccs.test/sp";
	variables.TEST_ENTITY_ID_UPDATED = "http://ccs.test/sp-alt";
	variables.TEST_ACS_URL = "https://example.com/acs";
	variables.TEST_ACS_URL_UPDATED = "https://example.com/acs-alt";
	variables.TEST_ACS_BINDING_UPDATED = "post";
	variables.TEST_SLO_URL_UPDATED = "https://example.com/slo";
	variables.TEST_SLO_BINDING_UPDATED = "redirect";
	variables.TEST_KEYSTORE_PATH = "C:/ColdFusion2023/samlkeystore.jks";
	variables.TEST_KEYSTORE_PATH_UPDATED = "C:/ColdFusion2025/cfusion/lib/saml/test-keystore.jks";
	variables.TEST_KEYSTORE_ALIAS = "selfsigned";
	variables.TEST_KEYSTORE_ALIAS_UPDATED = "signing";
	variables.TEST_KEYSTORE_PASSWORD = "auipdm/TDFho75SajRlKBub6Ya6nnU8nz4EAkgor61GeNuCPV2dkbT0rlFBL0sAngl91zr/IImG0mg8alvmzkQ==";
	variables.TEST_REQUEST_STORE_UPDATED = "cache";
	variables.SETTING_ADD = "SpAdd";
	variables.SETTING_GENERATE = "SpGenerate";
	variables.SETTING_REMOVE_ALL = "SpTestRemoveAll";
	variables.SETTING_FIELD_SETUP = "SpFieldTestSetup";
	variables.SETTING_NAME = "SpName";
	variables.SETTING_DESCRIPTION = "SpDescription";
	variables.SETTING_IDP_INITIATED = "SpIdpInitiatedSso";
	variables.SETTING_ENTITY_ID = "SpEntityId";
	variables.SETTING_ACS_URL = "SpAcsUrl";
	variables.SETTING_ACS_BINDING = "SpAcsBinding";
	variables.SETTING_SLO_URL = "SpSloUrl";
	variables.SETTING_SLO_BINDING = "SpSloBinding";
	variables.SETTING_SIGN_REQUESTS = "SpSignRequests";
	variables.SETTING_WANT_ASSERTIONS = "SpWantAssertionsSigned";
	variables.SETTING_LOGOUT_RESPONSE = "SpLogoutResponseSigned";
	variables.SETTING_KEYSTORE_PATH = "SpSignKeystorePath";
	variables.SETTING_KEYSTORE_PASSWORD = "SpSignKeystorePassword";
	variables.SETTING_KEYSTORE_ALIAS = "SpSignKeystoreAlias";
	variables.SETTING_REQUEST_STORE = "SpRequestStore";

	public function init(){
		variables.componentVersion = 1;
		return this;
	}

	private void function ensureConstants(){
		if(isDefined("application") AND NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
	}

	private string function getNeoSamlPath(){
		return server.coldfusion.rootdir & "\lib\neo-saml.xml";
	}

	private string function getNeoSamlLockName(required string configPath){
		return "ccs-neo-saml-" & hash(arguments.configPath);
	}

	private any function loadNeoSamlRaw(){
		var configPath = getNeoSamlPath();
		var lockName = getNeoSamlLockName(configPath);
		var lastError = {};
		lock name="#lockName#" type="readonly" timeout="30" {
			for(var attempt = 1; attempt LTE 3; attempt++){
				try {
					var content = trim(fileRead(configPath));
					if(NOT len(content))
						throw(message="neo-saml.xml is empty", type="CCSTest.ConfigError");
					var cfg = "";
					cfwddx(action="WDDX2CFML", input=content, output="cfg");
					if(isStruct(cfg))
						return cfg;
					throw(message="invalid neo-saml.xml structure", type="CCSTest.ConfigError");
				}
				catch(any e){
					lastError = e;
					if(attempt LT 3) sleep(50);
				}
			}
		}
		throw(message=lastError.message, detail=lastError.detail, type="CCSTest.ConfigError");
	}

	private struct function getNeoSamlMap(){
		return loadNeoSamlRaw();
	}

	private void function saveNeoSamlMap(required struct configMap){
		var configPath = getNeoSamlPath();
		var lockName = getNeoSamlLockName(configPath);
		lock name="#lockName#" type="exclusive" timeout="30" {
			var wddx = "";
			cfwddx(action="CFML2WDDX", input=arguments.configMap, output="wddx");
			fileWrite(configPath, wddx);
		}
	}

	private struct function getServiceProvidersMap(required struct configMap){
		if(NOT structKeyExists(arguments.configMap, "ServiceProvidersMap") OR NOT isStruct(arguments.configMap.ServiceProvidersMap))
			arguments.configMap.ServiceProvidersMap = {};
		return arguments.configMap.ServiceProvidersMap;
	}

	private string function findSpMapKey(required struct spMap, required string alias){
		for(var existingKey in arguments.spMap){
			if(compareNoCase(existingKey, arguments.alias) EQ 0)
				return existingKey;
		}
		return arguments.alias;
	}

	private boolean function isSecurityServiceAvailable(){
		if(structKeyExists(request, "ccsSecurityServiceAvailable"))
			return request.ccsSecurityServiceAvailable;
		try {
			createObject("java", "coldfusion.server.ServiceFactory").getSecurityService();
			request.ccsSecurityServiceAvailable = true;
		}
		catch(any e){
			request.ccsSecurityServiceAvailable = false;
		}
		return request.ccsSecurityServiceAvailable;
	}

	private any function loginAdmin(){
		ensureConstants();
		var admin = createObject("component", "CFIDE.adminapi.administrator");
		var pwd = structKeyExists(application, "constants")
			? application.constants.CF_CONFIG.CF_ADMIN_PASSWORD
			: (structKeyExists(request, "constants") ? request.constants.CF_CONFIG.CF_ADMIN_PASSWORD : "");
		if(NOT admin.login(pwd))
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

	private any function getSpMetadataInternal(required string alias){
		var admin = loginAdmin();
		try {
			return getSecurityAdminApi().getSpMetadata(arguments.alias);
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public array function getConfiguredAliases(){
		return structKeyArray(getServiceProvidersMap(getNeoSamlMap()));
	}

	public array function getAllTestSpAliases(){
		return [
			variables.TEST_SP_ADD_ALIAS,
			variables.TEST_SP_GEN_ALIAS,
			variables.TEST_SP_FIELD_ALIAS,
			variables.TEST_SP_FIELD_RENAME_ALIAS
		];
	}

	public array function getAllSpFieldSettings(){
		return [
			variables.SETTING_NAME,
			variables.SETTING_DESCRIPTION,
			variables.SETTING_IDP_INITIATED,
			variables.SETTING_ENTITY_ID,
			variables.SETTING_ACS_URL,
			variables.SETTING_ACS_BINDING,
			variables.SETTING_SLO_URL,
			variables.SETTING_SLO_BINDING,
			variables.SETTING_SIGN_REQUESTS,
			variables.SETTING_WANT_ASSERTIONS,
			variables.SETTING_LOGOUT_RESPONSE,
			variables.SETTING_KEYSTORE_PATH,
			variables.SETTING_KEYSTORE_PASSWORD,
			variables.SETTING_KEYSTORE_ALIAS,
			variables.SETTING_REQUEST_STORE
		];
	}

	public boolean function isSpFieldSetting(required string settingName){
		return listFindNoCase(arrayToList(getAllSpFieldSettings()), trim(arguments.settingName)) GT 0;
	}

	public boolean function isSpSetting(required string settingName){
		return listFindNoCase(
			variables.SETTING_ADD & "," & variables.SETTING_GENERATE & "," & variables.SETTING_REMOVE_ALL & "," &
			variables.SETTING_FIELD_SETUP & "," & arrayToList(getAllSpFieldSettings()),
			trim(arguments.settingName)
		) GT 0;
	}

	public string function formatBooleanSettingValue(required any value){
		if(isBoolean(arguments.value))
			return arguments.value ? "true" : "false";
		return listFindNoCase("true,yes,1,add,addall", lCase(trim("" & arguments.value))) GT 0 ? "true" : "false";
	}

	public boolean function isTestSpPresent(required string alias){
		if(isSecurityServiceAvailable()){
			try {
				var meta = getSpMetadataInternal(trim(arguments.alias));
				return isStruct(meta) AND structCount(meta) GT 0;
			}
			catch(any e){
				return false;
			}
		}
		return isTestSpPresentInNeo(trim(arguments.alias));
	}

	private boolean function isTestSpPresentInNeo(required string alias){
		var spMap = getServiceProvidersMap(getNeoSamlMap());
		for(var key in spMap){
			if(compareNoCase(key, arguments.alias) EQ 0)
				return true;
		}
		return false;
	}

	public boolean function anyTestSpPresent(){
		for(var alias in getAllTestSpAliases()){
			if(isTestSpPresent(alias))
				return true;
		}
		return false;
	}

	public void function ensureAllTestSpsAbsent(){
		removeAllTestSps();
	}

	public void function removeAllTestSps(){
		for(var pass = 1; pass LTE 2; pass++){
			for(var alias in getAllTestSpAliases())
				removeTestSp(alias);
			if(NOT anyTestSpPresent())
				return;
		}
	}

	public void function ensureAllTestSpsPresent(){
		removeAllTestSps();
		addTestSpForSetting(variables.SETTING_ADD);
		addTestSpForSetting(variables.SETTING_GENERATE);
	}

	private string function getTestAliasForSetting(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_ADD): return variables.TEST_SP_ADD_ALIAS;
			case lCase(variables.SETTING_GENERATE): return variables.TEST_SP_GEN_ALIAS;
			default: throw(message="Unsupported SP setting alias mapping: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public void function addTestSpForSetting(required string settingName){
		var alias = getTestAliasForSetting(arguments.settingName);
		if(isTestSpPresent(alias))
			return;
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_ADD):
				addManualTestSp(alias);
				break;
			case lCase(variables.SETTING_GENERATE):
				addGeneratedTestSp(alias);
				break;
			default:
				throw(message="Unsupported SP add setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public void function cleanupTestSpForSetting(required string settingName){
		removeTestSp(getTestAliasForSetting(arguments.settingName));
	}

	public void function removeTestSp(required string alias){
		if(NOT isTestSpPresent(arguments.alias))
			return;
		if(isSecurityServiceAvailable()){
			var admin = loginAdmin();
			try {
				getSecurityAdminApi().deleteSpMetadata(arguments.alias);
				return;
			}
			catch(any e){
				if(findNoCase("not found", e.message) OR findNoCase("does not exist", e.message))
					return;
			}
			finally {
				logoutAdmin(admin);
			}
		}
		removeSpFromNeo(arguments.alias);
	}

	private void function removeSpFromNeo(required string alias){
		var cfg = getNeoSamlMap();
		var spMap = getServiceProvidersMap(cfg);
		var key = findSpMapKey(spMap, arguments.alias);
		if(structKeyExists(spMap, key)){
			structDelete(spMap, key);
			saveNeoSamlMap(cfg);
		}
	}

	private any function getStructValueCaseInsensitive(required struct data, required string keyName){
		for(var existingKey in arguments.data){
			if(compareNoCase(existingKey, arguments.keyName) EQ 0)
				return arguments.data[existingKey];
		}
		return "";
	}

	private struct function readSpNeoEntry(required string alias){
		var spMap = getServiceProvidersMap(getNeoSamlMap());
		for(var key in spMap){
			if(compareNoCase(key, arguments.alias) EQ 0)
				return normalizeNeoSpEntry(spMap[key]);
		}
		return {};
	}

	private struct function readSpSnapshotFromNeo(required string alias){
		var entry = readSpNeoEntry(arguments.alias);
		return mapSpSnapshotFromEntry(entry);
	}

	private struct function readSpSnapshotFromAdminApi(required string alias){
		try {
			var meta = getSpMetadataInternal(arguments.alias);
			if(NOT isStruct(meta) OR NOT structCount(meta))
				return {};
			return {
				description = trim("" & getStructValueCaseInsensitive(meta, "description")),
				entityId = trim("" & getStructValueCaseInsensitive(meta, "entityid")),
				acsUrl = trim("" & getStructValueCaseInsensitive(meta, "acsurl")),
				acsBinding = trim("" & getStructValueCaseInsensitive(meta, "acsbinding")),
				sloUrl = trim("" & getStructValueCaseInsensitive(meta, "slourl")),
				sloBinding = trim("" & getStructValueCaseInsensitive(meta, "slobinding")),
				idpInitiatedSso = toBoolean(getStructValueCaseInsensitive(meta, "idpinitiatedsso")),
				signRequests = toBoolean(getStructValueCaseInsensitive(meta, "signrequests")),
				wantAssertionsSigned = toBoolean(getStructValueCaseInsensitive(meta, "wantassertionssigned")),
				logoutResponseSigned = toBoolean(getStructValueCaseInsensitive(meta, "logoutresponsesigned")),
				signKeystorePath = trim("" & getStructValueCaseInsensitive(meta, "signkeystorepath")),
				signKeystorePassword = trim("" & getStructValueCaseInsensitive(meta, "signkeystorepassword")),
				signKeystoreAlias = trim("" & getStructValueCaseInsensitive(meta, "signkeystorealias")),
				requestStore = trim("" & getStructValueCaseInsensitive(meta, "requeststore")),
				generated = toBoolean(getStructValueCaseInsensitive(meta, "generated"))
			};
		}
		catch(any e){
			return {};
		}
	}

	private struct function mapSpSnapshotFromEntry(required struct entry){
		return {
			description = trim("" & getStructValueCaseInsensitive(arguments.entry, "description")),
			entityId = trim("" & getStructValueCaseInsensitive(arguments.entry, "entityId")),
			acsUrl = trim("" & getStructValueCaseInsensitive(arguments.entry, "acsUrl")),
			acsBinding = trim("" & getStructValueCaseInsensitive(arguments.entry, "acsBinding")),
			sloUrl = trim("" & getStructValueCaseInsensitive(arguments.entry, "sloUrl")),
			sloBinding = trim("" & getStructValueCaseInsensitive(arguments.entry, "sloBinding")),
			idpInitiatedSso = toBoolean(getStructValueCaseInsensitive(arguments.entry, "allowIdpInitiatedSso")),
			signRequests = toBoolean(getStructValueCaseInsensitive(arguments.entry, "signRequests")),
			wantAssertionsSigned = toBoolean(getStructValueCaseInsensitive(arguments.entry, "wantAssertionsSigned")),
			logoutResponseSigned = toBoolean(getStructValueCaseInsensitive(arguments.entry, "logoutResponseSigned")),
			signKeystorePath = trim("" & getStructValueCaseInsensitive(arguments.entry, "signKeystorePath")),
			signKeystorePassword = trim("" & getStructValueCaseInsensitive(arguments.entry, "signKeystorePassword")),
			signKeystoreAlias = trim("" & getStructValueCaseInsensitive(arguments.entry, "signKeystoreAlias")),
			requestStore = trim("" & getStructValueCaseInsensitive(arguments.entry, "stateStore")),
			generated = toBoolean(getStructValueCaseInsensitive(arguments.entry, "generated"))
		};
	}

	private void function mergeEmptySpSnapshotFromAdminApi(required struct snapshot, required struct apiSnapshot){
		if(NOT structCount(arguments.apiSnapshot))
			return;
		for(var key in arguments.apiSnapshot){
			if(key EQ "generated")
				continue;
			if(listFindNoCase("idpInitiatedSso,signRequests,wantAssertionsSigned,logoutResponseSigned", key)){
				if(arguments.apiSnapshot[key] AND NOT arguments.snapshot[key])
					arguments.snapshot[key] = arguments.apiSnapshot[key];
				continue;
			}
			if(NOT len(trim("" & arguments.snapshot[key])) AND len(trim("" & arguments.apiSnapshot[key])))
				arguments.snapshot[key] = arguments.apiSnapshot[key];
		}
	}

	private struct function readSpSnapshot(required string alias){
		var snapshot = readSpSnapshotFromNeo(arguments.alias);
		if(isSecurityServiceAvailable())
			mergeEmptySpSnapshotFromAdminApi(snapshot, readSpSnapshotFromAdminApi(arguments.alias));
		return snapshot;
	}

	private boolean function toBoolean(required any value){
		if(isBoolean(arguments.value))
			return arguments.value;
		return listFindNoCase("true,yes,1", lCase(trim("" & arguments.value))) GT 0;
	}

	private string function normalizeBindingValue(required any value){
		var text = lCase(trim("" & arguments.value));
		if(findNoCase("post", text))
			return "post";
		if(findNoCase("redirect", text))
			return "redirect";
		return text;
	}

	private string function normalizeUrlValue(required any value){
		return lCase(trim(replace("" & arguments.value, "\", "/", "all")));
	}

	private string function normalizeRequestStoreValue(required any value){
		return lCase(trim("" & arguments.value));
	}

	public struct function getDefaultFieldSnapshot(){
		return {
			description = variables.TEST_SP_DESCRIPTION,
			entityId = variables.TEST_ENTITY_ID,
			acsUrl = variables.TEST_ACS_URL,
			acsBinding = "redirect",
			sloUrl = "",
			sloBinding = "",
			idpInitiatedSso = false,
			signRequests = false,
			wantAssertionsSigned = false,
			logoutResponseSigned = false,
			signKeystorePath = "",
			signKeystorePassword = "",
			signKeystoreAlias = "",
			requestStore = "",
			generated = false
		};
	}

	private struct function normalizeNeoSpEntry(required any rawEntry){
		if(isStruct(arguments.rawEntry))
			return duplicate(arguments.rawEntry);
		try {
			var copied = duplicate(arguments.rawEntry);
			if(isStruct(copied))
				return copied;
		}
		catch(any e){}
		return {};
	}

	private struct function findGeneratedSpTemplate(required struct spMap){
		for(var key in arguments.spMap){
			if(left(key, 12) EQ "CFGenerated_")
				return normalizeNeoSpEntry(arguments.spMap[key]);
			var entry = normalizeNeoSpEntry(arguments.spMap[key]);
			if(structCount(entry) AND toBoolean(getStructValueCaseInsensitive(entry, "generated")))
				return entry;
		}
		throw(message="No generated SP template found in neo-saml.xml", type="CCSTest.ConfigError");
	}

	private void function addSpToNeo(required string alias, required struct options){
		var cfg = getNeoSamlMap();
		var spMap = getServiceProvidersMap(cfg);
		var key = findSpMapKey(spMap, arguments.alias);
		var entry = {
			description = trim("" & arguments.options.description),
			entityId = trim("" & arguments.options.entityId),
			acsUrl = trim("" & arguments.options.acsUrl),
			acsBinding = trim("" & arguments.options.acsBinding),
			sloUrl = trim("" & arguments.options.sloUrl),
			sloBinding = trim("" & arguments.options.sloBinding),
			allowIdpInitiatedSso = javaCast("boolean", arguments.options.idpInitiatedSso),
			signRequests = javaCast("boolean", arguments.options.signRequests),
			wantAssertionsSigned = javaCast("boolean", arguments.options.wantAssertionsSigned),
			logoutResponseSigned = javaCast("boolean", arguments.options.logoutResponseSigned),
			signKeystorePath = trim("" & arguments.options.signKeystorePath),
			signKeystorePassword = trim("" & arguments.options.signKeystorePassword),
			signKeystoreAlias = trim("" & arguments.options.signKeystoreAlias),
			stateStore = trim("" & arguments.options.requestStore),
			generated = javaCast("boolean", arguments.options.generated),
			signMetadata = javaCast("boolean", false),
			strict = javaCast("boolean", true)
		};
		if(arguments.options.generated){
			var template = findGeneratedSpTemplate(spMap);
			if(NOT len(entry.signKeystorePath))
				entry.signKeystorePath = trim("" & getStructValueCaseInsensitive(template, "signKeystorePath"));
			if(NOT len(entry.signKeystorePassword))
				entry.signKeystorePassword = trim("" & getStructValueCaseInsensitive(template, "signKeystorePassword"));
			if(NOT len(entry.signKeystoreAlias))
				entry.signKeystoreAlias = trim("" & getStructValueCaseInsensitive(template, "signKeystoreAlias"));
		}
		spMap[key] = entry;
		saveNeoSamlMap(cfg);
	}

	private void function syncSpFieldsToNeo(required string alias, required struct fields){
		if(isTestSpPresentInNeo(arguments.alias))
			removeSpFromNeo(arguments.alias);
		addSpToNeo(arguments.alias, arguments.fields);
	}

	private struct function buildAdminSpArgs(required string alias, required struct fields, string oldAlias = "", string newAlias = ""){
		var args = {
			description = arguments.fields.description,
			entityid = arguments.fields.entityId,
			acsurl = arguments.fields.acsUrl,
			acsbinding = arguments.fields.acsBinding,
			slourl = arguments.fields.sloUrl,
			slobinding = arguments.fields.sloBinding,
			idpinitiatedsso = javaCast("boolean", arguments.fields.idpInitiatedSso),
			signrequests = javaCast("boolean", arguments.fields.signRequests),
			wantassertionssigned = javaCast("boolean", arguments.fields.wantAssertionsSigned),
			logoutresponsesigned = javaCast("boolean", arguments.fields.logoutResponseSigned),
			signkeystorepath = arguments.fields.signKeystorePath,
			signkeystorepassword = arguments.fields.signKeystorePassword,
			signkeystorealias = arguments.fields.signKeystoreAlias,
			requeststore = arguments.fields.requestStore
		};
		if(len(trim(arguments.oldAlias))){
			args.oldalias = arguments.oldAlias;
			args.newalias = len(trim(arguments.newAlias)) ? arguments.newAlias : arguments.oldAlias;
		} else {
			args.alias = arguments.alias;
		}
		return args;
	}

	private void function addSpViaAdminApi(required string alias, required struct fields){
		if(isSecurityServiceAvailable()){
			var admin = loginAdmin();
			try {
				getSecurityAdminApi().addSpMetadata(argumentCollection=buildAdminSpArgs(arguments.alias, arguments.fields));
				return;
			}
			finally {
				logoutAdmin(admin);
			}
		}
		addSpToNeo(arguments.alias, arguments.fields);
	}

	private void function modifySpViaAdminApi(required string alias, required struct fields, string newAlias = ""){
		var targetAlias = len(trim(arguments.newAlias)) ? arguments.newAlias : arguments.alias;
		if(isSecurityServiceAvailable()){
			var admin = loginAdmin();
			try {
				getSecurityAdminApi().modifySpMetadata(argumentCollection=buildAdminSpArgs(arguments.alias, arguments.fields, arguments.alias, targetAlias));
				syncSpFieldsToNeo(targetAlias, arguments.fields);
				if(compareNoCase(arguments.alias, targetAlias) NEQ 0 AND isTestSpPresentInNeo(arguments.alias))
					removeSpFromNeo(arguments.alias);
				return;
			}
			finally {
				logoutAdmin(admin);
			}
		}
		removeSpFromNeo(arguments.alias);
		addSpToNeo(targetAlias, arguments.fields);
	}

	private void function addManualTestSp(required string alias){
		var fields = getDefaultFieldSnapshot();
		fields.description = "CCS test SP add manual";
		addSpViaAdminApi(arguments.alias, fields);
		if(isSecurityServiceAvailable())
			syncSpFieldsToNeo(arguments.alias, fields);
	}

	private void function addGeneratedTestSp(required string alias){
		var cfg = getNeoSamlMap();
		var spMap = getServiceProvidersMap(cfg);
		var template = findGeneratedSpTemplate(spMap);
		var fields = getDefaultFieldSnapshot();
		fields.description = "CCS test SP generated";
		fields.entityId = "http://coldfusion.adobe.com/" & arguments.alias;
		fields.acsUrl = "https://example.com/generated-acs";
		fields.acsBinding = "redirect";
		fields.generated = true;
		fields.signKeystorePath = trim("" & getStructValueCaseInsensitive(template, "signKeystorePath"));
		fields.signKeystorePassword = trim("" & getStructValueCaseInsensitive(template, "signKeystorePassword"));
		fields.signKeystoreAlias = trim("" & getStructValueCaseInsensitive(template, "signKeystoreAlias"));
		fields.signRequests = true;
		fields.wantAssertionsSigned = true;
		fields.logoutResponseSigned = true;
		addSpViaAdminApi(arguments.alias, fields);
		if(isSecurityServiceAvailable())
			syncSpFieldsToNeo(arguments.alias, fields);
	}

	private void function modifySpEntry(required string alias, required struct fields, string newAlias = ""){
		modifySpViaAdminApi(arguments.alias, arguments.fields, arguments.newAlias);
	}

	public void function removeFieldTestSps(){
		for(var alias in [variables.TEST_SP_FIELD_ALIAS, variables.TEST_SP_FIELD_RENAME_ALIAS])
			removeTestSp(alias);
	}

	public void function ensureSpFieldTestDefaults(){
		removeFieldTestSps();
		var fields = getDefaultFieldSnapshot();
		fields.description = variables.TEST_SP_DESCRIPTION;
		addSpViaAdminApi(variables.TEST_SP_FIELD_ALIAS, fields);
		if(isSecurityServiceAvailable())
			syncSpFieldsToNeo(variables.TEST_SP_FIELD_ALIAS, fields);
	}

	public boolean function isSpFieldTestBaseReady(){
		if(NOT isTestSpPresent(variables.TEST_SP_FIELD_ALIAS))
			return false;
		if(isTestSpPresent(variables.TEST_SP_FIELD_RENAME_ALIAS))
			return false;
		return spFieldValuesMatch(
			variables.TEST_SP_DESCRIPTION,
			getSpFieldSetting(variables.SETTING_DESCRIPTION),
			variables.SETTING_DESCRIPTION
		);
	}

	private string function getCurrentFieldTestAlias(){
		if(isTestSpPresent(variables.TEST_SP_FIELD_RENAME_ALIAS))
			return variables.TEST_SP_FIELD_RENAME_ALIAS;
		return variables.TEST_SP_FIELD_ALIAS;
	}

	public string function getSpConfigurationSetting(required string settingName){
		if(isSpFieldSetting(arguments.settingName))
			return getSpFieldSetting(arguments.settingName);
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_FIELD_SETUP))
			return isSpFieldTestBaseReady() ? "ready" : "absent";
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_REMOVE_ALL))
			return formatBooleanSettingValue(anyTestSpPresent());
		return formatBooleanSettingValue(isTestSpPresent(getTestAliasForSetting(arguments.settingName)));
	}

	public string function setSpConfigurationSetting(required string settingName, required any settingValue){
		if(isSpFieldSetting(arguments.settingName))
			return setSpFieldSetting(arguments.settingName, arguments.settingValue);
		var settingKey = lCase(trim(arguments.settingName));
		var action = lCase(trim("" & arguments.settingValue));
		if(settingKey EQ lCase(variables.SETTING_FIELD_SETUP)){
			if(listFindNoCase("ensure,ready", action))
				ensureSpFieldTestDefaults();
			else if(listFindNoCase("reset,remove", action))
				removeFieldTestSps();
			return getSpConfigurationSetting(arguments.settingName);
		}
		if(settingKey EQ lCase(variables.SETTING_REMOVE_ALL)){
			if(listFindNoCase("addall,add", action))
				ensureAllTestSpsPresent();
			else if(listFindNoCase("true,removeall,remove", action))
				removeAllTestSps();
			return getSpConfigurationSetting(arguments.settingName);
		}
		var alias = getTestAliasForSetting(arguments.settingName);
		if(formatBooleanSettingValue(arguments.settingValue) EQ "true")
			addTestSpForSetting(arguments.settingName);
		else
			removeTestSp(alias);
		return getSpConfigurationSetting(arguments.settingName);
	}

	public string function getSpFieldSetting(required string settingName){
		if(NOT isTestSpPresent(variables.TEST_SP_FIELD_ALIAS) AND NOT isTestSpPresent(variables.TEST_SP_FIELD_RENAME_ALIAS)){
			var defaults = getDefaultFieldSnapshot();
			return getSpFieldValueFromSnapshot(defaults, arguments.settingName, variables.TEST_SP_FIELD_ALIAS);
		}
		var snapshot = readSpSnapshot(getCurrentFieldTestAlias());
		return getSpFieldValueFromSnapshot(snapshot, arguments.settingName, getCurrentFieldTestAlias());
	}

	private string function getSpFieldValueFromSnapshot(required struct snapshot, required string settingName, required string alias){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_NAME): return arguments.alias;
			case lCase(variables.SETTING_DESCRIPTION): return arguments.snapshot.description;
			case lCase(variables.SETTING_IDP_INITIATED): return formatBooleanSettingValue(arguments.snapshot.idpInitiatedSso);
			case lCase(variables.SETTING_ENTITY_ID): return arguments.snapshot.entityId;
			case lCase(variables.SETTING_ACS_URL): return arguments.snapshot.acsUrl;
			case lCase(variables.SETTING_ACS_BINDING): return arguments.snapshot.acsBinding;
			case lCase(variables.SETTING_SLO_URL): return arguments.snapshot.sloUrl;
			case lCase(variables.SETTING_SLO_BINDING): return arguments.snapshot.sloBinding;
			case lCase(variables.SETTING_SIGN_REQUESTS): return formatBooleanSettingValue(arguments.snapshot.signRequests);
			case lCase(variables.SETTING_WANT_ASSERTIONS): return formatBooleanSettingValue(arguments.snapshot.wantAssertionsSigned);
			case lCase(variables.SETTING_LOGOUT_RESPONSE): return formatBooleanSettingValue(arguments.snapshot.logoutResponseSigned);
			case lCase(variables.SETTING_KEYSTORE_PATH): return arguments.snapshot.signKeystorePath;
			case lCase(variables.SETTING_KEYSTORE_PASSWORD): return arguments.snapshot.signKeystorePassword;
			case lCase(variables.SETTING_KEYSTORE_ALIAS): return arguments.snapshot.signKeystoreAlias;
			case lCase(variables.SETTING_REQUEST_STORE): return arguments.snapshot.requestStore;
			default: throw(message="Unsupported SP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public string function setSpFieldSetting(required string settingName, required any settingValue){
		if(NOT isSpFieldTestBaseReady() AND NOT isTestSpPresent(getCurrentFieldTestAlias()))
			ensureSpFieldTestDefaults();
		var alias = getCurrentFieldTestAlias();
		var snapshot = isTestSpPresent(alias) ? readSpSnapshot(alias) : getDefaultFieldSnapshot();
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_NAME):
				modifySpEntry(alias, snapshot, trim("" & arguments.settingValue));
				return getSpFieldSetting(arguments.settingName);
			case lCase(variables.SETTING_DESCRIPTION): snapshot.description = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_IDP_INITIATED): snapshot.idpInitiatedSso = toBoolean(arguments.settingValue); break;
			case lCase(variables.SETTING_ENTITY_ID): snapshot.entityId = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_ACS_URL): snapshot.acsUrl = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_ACS_BINDING): snapshot.acsBinding = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_SLO_URL): snapshot.sloUrl = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_SLO_BINDING): snapshot.sloBinding = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_SIGN_REQUESTS): snapshot.signRequests = toBoolean(arguments.settingValue); break;
			case lCase(variables.SETTING_WANT_ASSERTIONS): snapshot.wantAssertionsSigned = toBoolean(arguments.settingValue); break;
			case lCase(variables.SETTING_LOGOUT_RESPONSE): snapshot.logoutResponseSigned = toBoolean(arguments.settingValue); break;
			case lCase(variables.SETTING_KEYSTORE_PATH): snapshot.signKeystorePath = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_KEYSTORE_PASSWORD): snapshot.signKeystorePassword = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_KEYSTORE_ALIAS): snapshot.signKeystoreAlias = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_REQUEST_STORE): snapshot.requestStore = trim("" & arguments.settingValue); break;
			default: throw(message="Unsupported SP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		if(lCase(trim(arguments.settingName)) NEQ lCase(variables.SETTING_NAME))
			modifySpEntry(alias, snapshot);
		var result = getSpFieldSetting(arguments.settingName);
		if(NOT spFieldValuesMatch(arguments.settingValue, result, arguments.settingName)){
			syncSpFieldsToNeo(getCurrentFieldTestAlias(), snapshot);
			if(isSecurityServiceAvailable())
				modifySpEntry(getCurrentFieldTestAlias(), snapshot);
			result = getSpFieldSetting(arguments.settingName);
		}
		return result;
	}

	public boolean function spFieldValuesMatch(required any expectedValue, required any actualValue, required string settingName){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_NAME):
			case lCase(variables.SETTING_DESCRIPTION):
			case lCase(variables.SETTING_ENTITY_ID):
				return lCase(trim("" & arguments.expectedValue)) EQ lCase(trim("" & arguments.actualValue));
			case lCase(variables.SETTING_ACS_URL):
			case lCase(variables.SETTING_SLO_URL):
				return normalizeUrlValue(arguments.expectedValue) EQ normalizeUrlValue(arguments.actualValue);
			case lCase(variables.SETTING_ACS_BINDING):
			case lCase(variables.SETTING_SLO_BINDING):
				return normalizeBindingValue(arguments.expectedValue) EQ normalizeBindingValue(arguments.actualValue);
			case lCase(variables.SETTING_REQUEST_STORE):
				return normalizeRequestStoreValue(arguments.expectedValue) EQ normalizeRequestStoreValue(arguments.actualValue);
			case lCase(variables.SETTING_IDP_INITIATED):
			case lCase(variables.SETTING_SIGN_REQUESTS):
			case lCase(variables.SETTING_WANT_ASSERTIONS):
			case lCase(variables.SETTING_LOGOUT_RESPONSE):
				return formatBooleanSettingValue(arguments.expectedValue) EQ formatBooleanSettingValue(arguments.actualValue);
			case lCase(variables.SETTING_KEYSTORE_PATH):
			case lCase(variables.SETTING_KEYSTORE_ALIAS):
			case lCase(variables.SETTING_KEYSTORE_PASSWORD):
				return trim("" & arguments.expectedValue) EQ trim("" & arguments.actualValue);
			default:
				return lCase(trim("" & arguments.expectedValue)) EQ lCase(trim("" & arguments.actualValue));
		}
	}

	public boolean function spValuesMatch(required any requestedValue, required any actualValue, required string settingName){
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_REMOVE_ALL)){
			if(listFindNoCase("addall,add", lCase(trim("" & arguments.requestedValue))))
				return formatBooleanSettingValue(arguments.actualValue) EQ "true";
			if(formatBooleanSettingValue(arguments.requestedValue) EQ "true")
				return formatBooleanSettingValue(arguments.actualValue) EQ "false";
			if(formatBooleanSettingValue(arguments.requestedValue) EQ "false")
				return formatBooleanSettingValue(arguments.actualValue) EQ "true";
		}
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_FIELD_SETUP)){
			if(listFindNoCase("ensure,ready", lCase(trim("" & arguments.requestedValue))))
				return lCase(trim("" & arguments.actualValue)) EQ "ready";
			if(listFindNoCase("reset,remove", lCase(trim("" & arguments.requestedValue))))
				return lCase(trim("" & arguments.actualValue)) EQ "absent";
		}
		if(isSpFieldSetting(arguments.settingName))
			return spFieldValuesMatch(arguments.requestedValue, arguments.actualValue, arguments.settingName);
		if(formatBooleanSettingValue(arguments.requestedValue) EQ "true")
			return formatBooleanSettingValue(arguments.actualValue) EQ "true";
		return formatBooleanSettingValue(arguments.actualValue) EQ "false";
	}

	public string function getNewSetValueForSetting(required string settingName, any currentValue = ""){
		if(isSpFieldSetting(arguments.settingName))
			return getSpFieldNewSetValue(arguments.settingName, arguments.currentValue);
		return formatBooleanSettingValue(arguments.currentValue) EQ "true" ? "false" : "true";
	}

	public string function getSpFieldNewSetValue(required string settingName, any currentValue = ""){
		var defaults = getDefaultFieldSnapshot();
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_NAME):
				return spFieldValuesMatch(variables.TEST_SP_FIELD_RENAME_ALIAS, arguments.currentValue, arguments.settingName)
					? variables.TEST_SP_FIELD_ALIAS : variables.TEST_SP_FIELD_RENAME_ALIAS;
			case lCase(variables.SETTING_DESCRIPTION):
				return spFieldValuesMatch(variables.TEST_SP_DESCRIPTION_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.description : variables.TEST_SP_DESCRIPTION_UPDATED;
			case lCase(variables.SETTING_IDP_INITIATED):
			case lCase(variables.SETTING_SIGN_REQUESTS):
			case lCase(variables.SETTING_WANT_ASSERTIONS):
			case lCase(variables.SETTING_LOGOUT_RESPONSE):
				return formatBooleanSettingValue(arguments.currentValue) EQ "true" ? "false" : "true";
			case lCase(variables.SETTING_ENTITY_ID):
				return spFieldValuesMatch(variables.TEST_ENTITY_ID_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.entityId : variables.TEST_ENTITY_ID_UPDATED;
			case lCase(variables.SETTING_ACS_URL):
				return spFieldValuesMatch(variables.TEST_ACS_URL_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.acsUrl : variables.TEST_ACS_URL_UPDATED;
			case lCase(variables.SETTING_ACS_BINDING):
				return spFieldValuesMatch(variables.TEST_ACS_BINDING_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.acsBinding : variables.TEST_ACS_BINDING_UPDATED;
			case lCase(variables.SETTING_SLO_URL):
				return spFieldValuesMatch(variables.TEST_SLO_URL_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.sloUrl : variables.TEST_SLO_URL_UPDATED;
			case lCase(variables.SETTING_SLO_BINDING):
				return spFieldValuesMatch(variables.TEST_SLO_BINDING_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.sloBinding : variables.TEST_SLO_BINDING_UPDATED;
			case lCase(variables.SETTING_KEYSTORE_PATH):
				return spFieldValuesMatch(variables.TEST_KEYSTORE_PATH_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.signKeystorePath : variables.TEST_KEYSTORE_PATH_UPDATED;
			case lCase(variables.SETTING_KEYSTORE_PASSWORD):
				return spFieldValuesMatch(variables.TEST_KEYSTORE_PASSWORD, arguments.currentValue, arguments.settingName)
					? defaults.signKeystorePassword : variables.TEST_KEYSTORE_PASSWORD;
			case lCase(variables.SETTING_KEYSTORE_ALIAS):
				return spFieldValuesMatch(variables.TEST_KEYSTORE_ALIAS_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.signKeystoreAlias : variables.TEST_KEYSTORE_ALIAS_UPDATED;
			case lCase(variables.SETTING_REQUEST_STORE):
				return spFieldValuesMatch(variables.TEST_REQUEST_STORE_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.requestStore : variables.TEST_REQUEST_STORE_UPDATED;
			default:
				throw(message="Unsupported SP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public string function formatDisplayValue(required string settingName, required any value){
		if(isSpFieldSetting(arguments.settingName))
			return formatSpFieldDisplayValue(arguments.settingName, arguments.value);
		return formatBooleanSettingValue(arguments.value) EQ "true" ? "Enabled" : "Disabled";
	}

	public string function formatSpFieldDisplayValue(required string settingName, required any value){
		var text = trim("" & arguments.value);
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_IDP_INITIATED):
			case lCase(variables.SETTING_SIGN_REQUESTS):
			case lCase(variables.SETTING_WANT_ASSERTIONS):
			case lCase(variables.SETTING_LOGOUT_RESPONSE):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "Enabled" : "Disabled";
			case lCase(variables.SETTING_KEYSTORE_PASSWORD):
				if(NOT len(text) OR text EQ "password")
					return "(empty)";
				return len(text) GT 20 ? left(text, 20) & "..." : text;
			case lCase(variables.SETTING_SLO_URL):
			case lCase(variables.SETTING_SLO_BINDING):
			case lCase(variables.SETTING_KEYSTORE_PATH):
			case lCase(variables.SETTING_KEYSTORE_ALIAS):
			case lCase(variables.SETTING_REQUEST_STORE):
				return len(text) ? text : "(empty)";
			default:
				return len(text) ? text : "(empty)";
		}
	}

}
