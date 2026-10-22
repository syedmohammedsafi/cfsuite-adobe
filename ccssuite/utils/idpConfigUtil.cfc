/**
* Read/write ColdFusion Administrator Security > IDP Configuration settings.
*/
component output="false" {

	variables.TEST_IDP_URL_ALIAS = "ccsTestIdpUrl";
	variables.TEST_IDP_DEF_ALIAS = "ccsTestIdpDef";
	variables.TEST_IDP_XML_ALIAS = "ccsTestIdpXml";
	variables.TEST_IDP_OWN_ALIAS = "ccsTestIdpOwn";
	variables.TEST_IDP_URL = "https://integrator-2400116.okta.com/app/exk113xruo02aEUjO698/sso/saml/metadata";
	variables.TEST_IDP_URL_ALT = "https://integrator-2400116.okta.com/app/exkyajioytrvd2Jn8697/sso/saml/metadata";
	variables.TEST_ENTITY_ID = "http://www.okta.com/exk113xruo02aEUjO698";
	variables.TEST_SSO_URL = "https://integrator-2400116.okta.com/app/integrator-2400116_oktasaml20_1/exk113xruo02aEUjO698/sso/saml";
	variables.TEST_IDP_FIELD_ALIAS = "ccsTestIdpFields";
	variables.TEST_IDP_FIELD_RENAME_ALIAS = "ccsTestIdpFieldsRenamed";
	variables.TEST_IDP_FIELD_DESCRIPTION = "CCS test IDP from SAML URL";
	variables.TEST_IDP_FIELD_DESCRIPTION_UPDATED = "CCS test IDP updated description";
	variables.TEST_IDP_FIELD_REFRESH = "1,0,0,0";
	variables.TEST_IDP_FIELD_REFRESH_UPDATED = "2,0,0,0";
	variables.SETTING_URL = "IdpFromSamlUrl";
	variables.SETTING_DEF = "IdpFromSamlDefinition";
	variables.SETTING_XML_METADATA = "IdpXmlMetadata";
	variables.SETTING_METADATA_FILE_LOCATION = "IdpMetadataFileLocation";
	variables.SETTING_XML = "IdpFromXmlFile";
	variables.SETTING_OWN = "IdpOwnDefinition";
	variables.SETTING_REMOVE_ALL = "IdpTestRemoveAll";
	variables.SETTING_NAME = "IdpName";
	variables.SETTING_DESCRIPTION = "IdpDescription";
	variables.SETTING_REFRESH = "IdpRefreshInterval";
	variables.SETTING_SAML_URL = "IdpSamlUrl";
	variables.SETTING_FIELD_SETUP = "IdpFieldTestSetup";
	variables.TEST_IDP_OWN_FIELD_ALIAS = "ccsTestIdpOwnFields";
	variables.SETTING_OWN_FIELD_SETUP = "IdpOwnFieldTestSetup";
	variables.SETTING_OWN_ENTITY_ID = "IdpOwnEntityId";
	variables.SETTING_OWN_SSO_URL = "IdpOwnSsoUrl";
	variables.SETTING_OWN_SSO_BINDING = "IdpOwnSsoBinding";
	variables.SETTING_OWN_SLO_URL = "IdpOwnSloUrl";
	variables.SETTING_OWN_SLO_BINDING = "IdpOwnSloBinding";
	variables.SETTING_OWN_LOGOUT_URL = "IdpOwnLogoutResponseUrl";
	variables.SETTING_OWN_SIGN_REQUESTS = "IdpOwnSignRequests";
	variables.SETTING_OWN_SIGN_CERT = "IdpOwnSignCertificate";
	variables.TEST_OWN_ENTITY_UPDATED = "http://ccs.test/entity-alt";
	variables.TEST_OWN_SSO_URL_UPDATED = "https://example.com/sso-alt";
	variables.TEST_OWN_SLO_URL_UPDATED = "https://example.com/slo-alt";
	variables.TEST_OWN_LOGOUT_URL_UPDATED = "https://example.com/logout-alt";
	variables.TEST_OWN_SSO_BINDING_UPDATED = "post";
	variables.TEST_OWN_SLO_BINDING_UPDATED = "redirect";
	variables.CCS_TEST_IDP_ALIAS = "TestIDPAlias";

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

	private struct function getIdentityProvidersMap(required struct configMap){
		if(NOT structKeyExists(arguments.configMap, "IdentityProvidersMap") OR NOT isStruct(arguments.configMap.IdentityProvidersMap))
			arguments.configMap.IdentityProvidersMap = {};
		return arguments.configMap.IdentityProvidersMap;
	}

	private string function findIdpMapKey(required struct idpMap, required string alias){
		for(var existingKey in arguments.idpMap){
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
		var loggedIn = admin.login(application.constants.CF_CONFIG.CF_ADMIN_PASSWORD);
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

	public string function getTestMetadataXmlPath(){
		var path = expandPath("/cfsuite/ccssuite/testsuite/security/idpConfiguration/testIdpMetadata.xml");
		if(fileExists(path))
			return path;
		return replace(server.coldfusion.rootdir, "/", "\", "all") &
			"\wwwroot\cfsuite\ccssuite\testsuite\security\idpConfiguration\testIdpMetadata.xml";
	}

	public string function getTestMetadataXml(){
		var path = getTestMetadataXmlPath();
		if(NOT fileExists(path))
			throw(message="Missing IDP test metadata XML at #path#", type="CCSTest.ConfigError");
		return fileRead(path);
	}

	public string function getAlternateMetadataXmlPath(){
		var path = expandPath("/cfsuite/ccssuite/testsuite/security/idpConfiguration/testIdpMetadataAlt.xml");
		if(fileExists(path))
			return path;
		return replace(server.coldfusion.rootdir, "/", "\", "all") &
			"\wwwroot\cfsuite\ccssuite\testsuite\security\idpConfiguration\testIdpMetadataAlt.xml";
	}

	public string function getAlternateMetadataXml(){
		var path = getAlternateMetadataXmlPath();
		if(NOT fileExists(path))
			throw(message="Missing alternate IDP test metadata XML at #path#", type="CCSTest.ConfigError");
		return fileRead(path);
	}

	public string function getTestMetadataXmlAltPath(){
		return getAlternateMetadataXmlPath();
	}

	public string function getTestMetadataXmlAlt(){
		return getAlternateMetadataXml();
	}

	private string function getAlternateSigningCertificateFromXml(){
		var path = getAlternateMetadataXmlPath();
		if(NOT fileExists(path))
			return getSigningCertificateFromXml(getTestMetadataXml());
		return getSigningCertificateFromXml(fileRead(path));
	}

	private string function getSigningCertificateFromXml(required string xmlContent){
		var startPos = find("<ds:X509Certificate>", arguments.xmlContent);
		if(NOT startPos)
			throw(message="Could not locate signing certificate in test IDP metadata XML", type="CCSTest.ConfigError");
		startPos += len("<ds:X509Certificate>");
		var endPos = find("</ds:X509Certificate>", arguments.xmlContent, startPos);
		if(NOT endPos)
			throw(message="Could not locate signing certificate end tag in test IDP metadata XML", type="CCSTest.ConfigError");
		return reReplace(mid(arguments.xmlContent, startPos, endPos - startPos), "[\r\n\s]", "", "all");
	}

	public array function getConfiguredAliases(){
		return structKeyArray(getIdentityProvidersMap(getNeoSamlMap()));
	}

	public array function getAllTestIdpAliases(){
		return [
			variables.TEST_IDP_URL_ALIAS,
			variables.TEST_IDP_DEF_ALIAS,
			variables.TEST_IDP_XML_ALIAS,
			variables.TEST_IDP_OWN_ALIAS,
			variables.TEST_IDP_FIELD_ALIAS,
			variables.TEST_IDP_FIELD_RENAME_ALIAS,
			variables.TEST_IDP_OWN_FIELD_ALIAS
		];
	}

	public array function getAllIdpUrlFieldSettings(){
		return [
			variables.SETTING_NAME,
			variables.SETTING_DESCRIPTION,
			variables.SETTING_REFRESH,
			variables.SETTING_SAML_URL,
			variables.SETTING_XML_METADATA,
			variables.SETTING_METADATA_FILE_LOCATION
		];
	}

	public array function getAllIdpOwnFieldSettings(){
		return [
			variables.SETTING_OWN_ENTITY_ID,
			variables.SETTING_OWN_SSO_URL,
			variables.SETTING_OWN_SSO_BINDING,
			variables.SETTING_OWN_SLO_URL,
			variables.SETTING_OWN_SLO_BINDING,
			variables.SETTING_OWN_LOGOUT_URL,
			variables.SETTING_OWN_SIGN_REQUESTS,
			variables.SETTING_OWN_SIGN_CERT
		];
	}

	public array function getAllIdpFieldSettings(){
		var all = getAllIdpUrlFieldSettings();
		for(var item in getAllIdpOwnFieldSettings())
			arrayAppend(all, item);
		return all;
	}

	public boolean function isIdpUrlFieldSetting(required string settingName){
		return listFindNoCase(arrayToList(getAllIdpUrlFieldSettings()), trim(arguments.settingName)) GT 0;
	}

	public boolean function isIdpOwnFieldSetting(required string settingName){
		return listFindNoCase(arrayToList(getAllIdpOwnFieldSettings()), trim(arguments.settingName)) GT 0;
	}

	public boolean function isIdpFieldSetting(required string settingName){
		return isIdpUrlFieldSetting(arguments.settingName) OR isIdpOwnFieldSetting(arguments.settingName);
	}

	public string function getTestAliasForSetting(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_URL):
				return variables.TEST_IDP_URL_ALIAS;
			case lCase(variables.SETTING_DEF):
				return variables.TEST_IDP_DEF_ALIAS;
			case lCase(variables.SETTING_XML):
				return variables.TEST_IDP_XML_ALIAS;
			case lCase(variables.SETTING_OWN):
				return variables.TEST_IDP_OWN_ALIAS;
			case lCase(variables.CCS_TEST_IDP_ALIAS):
				return variables.TEST_IDP_URL_ALIAS;
			default:
				throw(message="Unsupported IDP setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public boolean function isIdpSetting(required string settingName){
		return listFindNoCase(
			variables.SETTING_URL & "," & variables.SETTING_DEF & "," & variables.SETTING_XML & "," & variables.SETTING_XML_METADATA & "," & variables.SETTING_METADATA_FILE_LOCATION & "," &
			variables.SETTING_OWN & "," & variables.SETTING_REMOVE_ALL & "," & variables.SETTING_FIELD_SETUP & "," &
			variables.SETTING_OWN_FIELD_SETUP & "," & arrayToList(getAllIdpFieldSettings()) & "," & variables.CCS_TEST_IDP_ALIAS,
			trim(arguments.settingName)
		) GT 0;
	}

	public boolean function isTestIdpPresent(required string alias){
		if(isSecurityServiceAvailable()){
			try {
				var meta = getIdpMetadataInternal(trim(arguments.alias));
				return isStruct(meta) AND structCount(meta) GT 0;
			}
			catch(any e){
				// fallback to neo
				return isTestIdpPresentInNeo(trim(arguments.alias));
			}
		}
		return isTestIdpPresentInNeo(trim(arguments.alias));
	}

	private boolean function isTestIdpPresentInNeo(required string alias){
		var idpMap = getIdentityProvidersMap(getNeoSamlMap());
		for(var key in idpMap){
			if(compareNoCase(key, arguments.alias) EQ 0)
				return true;
		}
		return false;
	}

	private any function getIdpMetadataInternal(required string alias){
		var admin = loginAdmin();
		try {
			return getSecurityAdminApi().getIdpMetadata(arguments.alias);
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function formatBooleanSettingValue(required any value){
		if(isBoolean(arguments.value))
			return arguments.value ? "true" : "false";
		return listFindNoCase("true,yes,1,add,addall", lCase(trim("" & arguments.value))) GT 0 ? "true" : "false";
	}

	public string function getIdpConfigurationSetting(required string settingName){
		if(isIdpOwnFieldSetting(arguments.settingName))
			return getIdpOwnFieldSetting(arguments.settingName);
		if(isIdpUrlFieldSetting(arguments.settingName))
			return getIdpFieldSetting(arguments.settingName);
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_OWN_FIELD_SETUP))
			return isIdpOwnFieldTestBaseReady() ? "ready" : "absent";
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_FIELD_SETUP))
			return isIdpFieldTestBaseReady() ? "ready" : "absent";
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_REMOVE_ALL))
			return formatBooleanSettingValue(anyTestIdpPresent());
		return formatBooleanSettingValue(isTestIdpPresent(getTestAliasForSetting(arguments.settingName)));
	}

	public string function getIDPSetting(required string settingName){
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.CCS_TEST_IDP_ALIAS)){
			if(NOT isTestIdpPresent(variables.TEST_IDP_URL_ALIAS))
				return "";
			var meta = getIdpMetadataInternal(variables.TEST_IDP_URL_ALIAS);
			return toBase64(serializeJSON(normalizeIdpMetadata(meta)));
		}
		return getIdpConfigurationSetting(arguments.settingName);
	}

	public string function setIdpConfigurationSetting(required string settingName, required any settingValue){
		if(isIdpOwnFieldSetting(arguments.settingName))
			return setIdpOwnFieldSetting(arguments.settingName, arguments.settingValue);
		if(isIdpUrlFieldSetting(arguments.settingName))
			return setIdpFieldSetting(arguments.settingName, arguments.settingValue);
		var settingKey = lCase(trim(arguments.settingName));
		var action = lCase(trim("" & arguments.settingValue));
		if(settingKey EQ lCase(variables.SETTING_OWN_FIELD_SETUP)){
			if(listFindNoCase("ensure,ready", action))
				ensureIdpOwnFieldTestDefaults();
			else if(listFindNoCase("reset,remove", action))
				removeOwnFieldTestIdp();
			return getIdpConfigurationSetting(arguments.settingName);
		}
		if(settingKey EQ lCase(variables.SETTING_FIELD_SETUP)){
			if(listFindNoCase("ensure,ready", action))
				ensureIdpFieldTestDefaults();
			else if(listFindNoCase("reset,remove", action))
				removeFieldTestIdps();
			return getIdpConfigurationSetting(arguments.settingName);
		}
		if(settingKey EQ lCase(variables.SETTING_REMOVE_ALL)){
			if(listFindNoCase("addall,add", action))
				ensureAllTestIdpsPresent();
			else if(listFindNoCase("true,removeall,remove", action))
				removeAllTestIdps();
			return getIdpConfigurationSetting(arguments.settingName);
		}
		var alias = getTestAliasForSetting(arguments.settingName);
		if(formatBooleanSettingValue(arguments.settingValue) EQ "true")
			addTestIdpForSetting(arguments.settingName);
		else
			removeTestIdp(alias);
		return getIdpConfigurationSetting(arguments.settingName);
	}

	public string function setIDPSetting(required string settingName, required any settingValue){
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.CCS_TEST_IDP_ALIAS)){
			if(formatBooleanSettingValue(arguments.settingValue) EQ "true")
				addTestIdpForSetting(variables.SETTING_URL);
			else
				removeTestIdp(variables.TEST_IDP_URL_ALIAS);
			return getIDPSetting(arguments.settingName);
		}
		return setIdpConfigurationSetting(arguments.settingName, arguments.settingValue);
	}

	public boolean function idpValuesMatch(required any requestedValue, required any actualValue, required string settingName){
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_REMOVE_ALL)){
			if(listFindNoCase("addall,add", lCase(trim("" & arguments.requestedValue))))
				return formatBooleanSettingValue(arguments.actualValue) EQ "true";
			if(formatBooleanSettingValue(arguments.requestedValue) EQ "true")
				return formatBooleanSettingValue(arguments.actualValue) EQ "false";
			if(formatBooleanSettingValue(arguments.requestedValue) EQ "false")
				return formatBooleanSettingValue(arguments.actualValue) EQ "true";
		}
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_OWN_FIELD_SETUP)){
			if(listFindNoCase("ensure,ready", lCase(trim("" & arguments.requestedValue))))
				return lCase(trim("" & arguments.actualValue)) EQ "ready";
			if(listFindNoCase("reset,remove", lCase(trim("" & arguments.requestedValue))))
				return lCase(trim("" & arguments.actualValue)) EQ "absent";
		}
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_FIELD_SETUP)){
			if(listFindNoCase("ensure,ready", lCase(trim("" & arguments.requestedValue))))
				return lCase(trim("" & arguments.actualValue)) EQ "ready";
			if(listFindNoCase("reset,remove", lCase(trim("" & arguments.requestedValue))))
				return lCase(trim("" & arguments.actualValue)) EQ "absent";
		}
		if(isIdpFieldSetting(arguments.settingName))
			return idpFieldValuesMatch(arguments.requestedValue, arguments.actualValue, arguments.settingName);
		return scalarValuesMatch(arguments.requestedValue, arguments.actualValue, arguments.settingName);
	}

	public string function getNewSetValueForSetting(required string settingName, any currentValue = ""){
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_REMOVE_ALL))
			return "true";
		if(isIdpOwnFieldSetting(arguments.settingName))
			return getIdpOwnFieldNewSetValue(arguments.settingName, arguments.currentValue);
		if(isIdpUrlFieldSetting(arguments.settingName))
			return getIdpFieldNewSetValue(arguments.settingName, arguments.currentValue);
		return formatBooleanSettingValue(arguments.currentValue) EQ "true" ? "false" : "true";
	}

	public boolean function scalarValuesMatch(required any expectedValue, required any actualValue, string settingName = ""){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		if(isIdpOwnFieldSetting(arguments.settingName) OR isIdpUrlFieldSetting(arguments.settingName))
			return idpFieldValuesMatch(arguments.expectedValue, arguments.actualValue, arguments.settingName);
		return formatBooleanSettingValue(arguments.expectedValue) EQ formatBooleanSettingValue(arguments.actualValue);
	}

	public string function formatDisplayValue(required string settingName, required any value){
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_REMOVE_ALL)){
			return formatBooleanSettingValue(arguments.value) EQ "true" ? "All test IDPs removed" : "Test IDPs still present";
		}
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_OWN_FIELD_SETUP)){
			return lCase(trim("" & arguments.value)) EQ "ready" ? "Own field test IDP ready" : "Own field test IDP absent";
		}
		if(lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_FIELD_SETUP)){
			return lCase(trim("" & arguments.value)) EQ "ready" ? "Field test IDP ready" : "Field test IDP absent";
		}
		if(isIdpOwnFieldSetting(arguments.settingName))
			return formatIdpOwnFieldDisplayValue(arguments.settingName, arguments.value);
		if(isIdpUrlFieldSetting(arguments.settingName))
			return formatIdpFieldDisplayValue(arguments.settingName, arguments.value);
		return formatBooleanSettingValue(arguments.value) EQ "true" ? "Enabled" : "Disabled";
	}

	public boolean function anyTestIdpPresent(){
		for(var alias in getAllTestIdpAliases()){
			if(isTestIdpPresent(alias))
				return true;
		}
		return false;
	}

	public void function ensureAllTestIdpsAbsent(){
		removeAllTestIdps();
	}

	public void function ensureAllTestIdpsPresent(){
		for(var settingName in [variables.SETTING_URL, variables.SETTING_DEF, variables.SETTING_XML, variables.SETTING_OWN])
			addTestIdpForSetting(settingName);
	}

	public void function removeAllTestIdps(){
		for(var pass = 1; pass LTE 2; pass++){
			for(var alias in getAllTestIdpAliases())
				removeTestIdp(alias);
			if(NOT anyTestIdpPresent())
				return;
		}
	}

	public void function addTestIdpForSetting(required string settingName){
		var alias = getTestAliasForSetting(arguments.settingName);
		if(isTestIdpPresent(alias))
			return;
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_URL):
				addIdpFromUrl(alias);
				break;
			case lCase(variables.SETTING_DEF):
				addIdpFromRawXml(alias, getTestMetadataXml(), "CCS test IDP from SAML definition");
				break;
			case lCase(variables.SETTING_XML):
				addIdpFromXmlFile(alias);
				break;
			case lCase(variables.SETTING_OWN):
				addIdpFromOwnDefinition(alias);
				break;
			default:
				throw(message="Unsupported IDP add setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	private void function addIdpFromUrl(required string alias){
		addIdpViaAdminApi(
			alias = arguments.alias,
			description = "CCS test IDP from SAML URL",
			url = variables.TEST_IDP_URL
		);
	}

	private void function addIdpFromXmlFile(required string alias){
		var xmlPath = getTestMetadataXmlPath();
		var xmlContent = getTestMetadataXml();
		try {
			addIdpViaAdminApi(
				alias = arguments.alias,
				description = "CCS test IDP from XML file",
				file = xmlPath
			);
		}
		catch(any e){
			if(NOT findNoCase("parse", e.message))
				rethrow;
			addIdpFromRawXml(arguments.alias, xmlContent, "CCS test IDP from XML file");
		}
	}

	private void function addIdpFromRawXml(required string alias, required string xmlContent, required string description){
		addIdpViaAdminApi(
			alias = arguments.alias,
			description = arguments.description,
			rawxml = arguments.xmlContent
		);
	}

	private void function addIdpFromOwnDefinition(required string alias){
		var cert = getSigningCertificateFromXml(getTestMetadataXml());
		addIdpViaAdminApi(
			alias = arguments.alias,
			description = "CCS test IDP from own SAML definition",
			entityid = variables.TEST_ENTITY_ID,
			ssourl = variables.TEST_SSO_URL,
			ssobinding = "redirect",
			signrequests = javaCast("boolean", false),
			signcertificate = cert
		);
	}

	private void function addIdpViaAdminApi(
		required string alias,
		string description = "",
		string url = "",
		string file = "",
		string rawxml = "",
		string entityid = "",
		string ssourl = "",
		string ssobinding = "",
		string slourl = "",
		string slobinding = "",
		string logoutresponseurl = "",
		boolean signrequests = false,
		string signcertificate = ""
	){
		if(isSecurityServiceAvailable()){
			var admin = loginAdmin();
			try {
				var args = {
					alias = arguments.alias,
					description = arguments.description
				};
				if(len(trim(arguments.url))) args.url = arguments.url;
				if(len(trim(arguments.file))) args.file = arguments.file;
				if(len(trim(arguments.rawxml))) args.rawxml = arguments.rawxml;
				if(len(trim(arguments.entityid))) args.entityid = arguments.entityid;
				if(len(trim(arguments.ssourl))) args.ssourl = arguments.ssourl;
				if(len(trim(arguments.ssobinding))) args.ssobinding = arguments.ssobinding;
				if(len(trim(arguments.slourl))) args.slourl = arguments.slourl;
				if(len(trim(arguments.slobinding))) args.slobinding = arguments.slobinding;
				if(len(trim(arguments.logoutresponseurl))) args.logoutresponseurl = arguments.logoutresponseurl;
				if(len(trim(arguments.signcertificate))) args.signcertificate = arguments.signcertificate;
				args.signrequests = javaCast("boolean", arguments.signrequests);
				getSecurityAdminApi().addIdpMetadata(argumentCollection=args);
				return;
			}
			finally {
				logoutAdmin(admin);
			}
		}
		addIdpToNeo(arguments.alias, arguments);
	}

	private void function addIdpToNeo(required string alias, required struct options){
		var cfg = getNeoSamlMap();
		var idpMap = getIdentityProvidersMap(cfg);
		var key = findIdpMapKey(idpMap, arguments.alias);
		var entry = {
			description = trim("" & arguments.options.description),
			entityId = "",
			sloUrl = "",
			signCertificate = "",
			ssoBinding = "",
			sloBinding = "",
			logoutResponseUrl = "",
			signRequests = javaCast("boolean", false),
			ssoUrl = "",
			metadataRaw = "",
			metadataFilePath = "",
			refreshInterval = 0.416,
			metadataUrl = ""
		};
		if(structKeyExists(arguments.options, "url") AND len(trim(arguments.options.url)))
			entry.metadataUrl = trim(arguments.options.url);
		if(structKeyExists(arguments.options, "rawxml") AND len(trim(arguments.options.rawxml)))
			entry.metadataRaw = trim(arguments.options.rawxml);
		if(structKeyExists(arguments.options, "file") AND len(trim(arguments.options.file)))
			entry.metadataFilePath = trim(arguments.options.file);
		if(structKeyExists(arguments.options, "entityid") AND len(trim(arguments.options.entityid)))
			entry.entityId = trim(arguments.options.entityid);
		if(structKeyExists(arguments.options, "ssourl") AND len(trim(arguments.options.ssourl)))
			entry.ssoUrl = trim(arguments.options.ssourl);
		if(structKeyExists(arguments.options, "ssobinding") AND len(trim(arguments.options.ssobinding)))
			entry.ssoBinding = trim(arguments.options.ssobinding);
		if(structKeyExists(arguments.options, "slourl"))
			entry.sloUrl = trim("" & arguments.options.slourl);
		if(structKeyExists(arguments.options, "slobinding"))
			entry.sloBinding = trim("" & arguments.options.slobinding);
		if(structKeyExists(arguments.options, "logoutresponseurl"))
			entry.logoutResponseUrl = trim("" & arguments.options.logoutresponseurl);
		if(structKeyExists(arguments.options, "signcertificate") AND len(trim(arguments.options.signcertificate)))
			entry.signCertificate = trim(arguments.options.signcertificate);
		if(structKeyExists(arguments.options, "signrequests"))
			entry.signRequests = javaCast("boolean", arguments.options.signrequests);
		if(structKeyExists(arguments.options, "refreshinterval"))
			entry.refreshInterval = val(arguments.options.refreshinterval);
		idpMap[key] = entry;
		saveNeoSamlMap(cfg);
	}

	public void function removeTestIdp(required string alias){
		if(NOT isTestIdpPresent(arguments.alias))
			return;
		if(isSecurityServiceAvailable()){
			var admin = loginAdmin();
			try {
				getSecurityAdminApi().deleteIdpMetadata(arguments.alias);
				return;
			}
			catch(any e){
				// If deleteIdpMetadata fails (e.g. ClassCastException), proceed to remove from neo
				removeIdpFromNeo(arguments.alias);
				return;

			}
			finally {
				logoutAdmin(admin);
			}
		}
		removeIdpFromNeo(arguments.alias);
	}

	private void function removeIdpFromNeo(required string alias){
		var cfg = getNeoSamlMap();
		var idpMap = getIdentityProvidersMap(cfg);
		var changed = false;
		for(var key in duplicate(idpMap)){
			if(compareNoCase(key, arguments.alias) EQ 0){
				structDelete(idpMap, key);
				changed = true;
			}
		}
		if(changed)
			saveNeoSamlMap(cfg);
	}

	private struct function normalizeIdpMetadata(required any metadata){
		var normalized = {};
		if(NOT isStruct(arguments.metadata))
			return normalized;
		for(var key in arguments.metadata)
			normalized[lCase(key)] = arguments.metadata[key];
		return normalized;
	}

	public void function removeFieldTestIdps(){
		for(var alias in [variables.TEST_IDP_FIELD_ALIAS, variables.TEST_IDP_FIELD_RENAME_ALIAS])
			removeTestIdp(alias);
	}

	public void function ensureIdpFieldTestDefaults(){
		removeFieldTestIdps();
		addUrlIdpWithFields(
			variables.TEST_IDP_FIELD_ALIAS,
			variables.TEST_IDP_FIELD_DESCRIPTION,
			variables.TEST_IDP_FIELD_REFRESH,
			variables.TEST_IDP_URL
		);
	}

	public boolean function isIdpFieldTestBaseReady(){
		if(NOT isTestIdpPresent(variables.TEST_IDP_FIELD_ALIAS))
			return false;
		if(isTestIdpPresent(variables.TEST_IDP_FIELD_RENAME_ALIAS))
			return false;
		return idpFieldValuesMatch(
			variables.TEST_IDP_FIELD_DESCRIPTION,
			getIdpFieldSetting(variables.SETTING_DESCRIPTION),
			variables.SETTING_DESCRIPTION
		);
	}

	public string function getCurrentFieldTestAlias(){
		if(isTestIdpPresent(variables.TEST_IDP_FIELD_RENAME_ALIAS))
			return variables.TEST_IDP_FIELD_RENAME_ALIAS;
		return variables.TEST_IDP_FIELD_ALIAS;
	}

	private struct function convertIdpEntryToStruct(required any rawEntry){
		var out = {};
		if(isStruct(arguments.rawEntry)){
			for(var k in arguments.rawEntry){
				out[k] = arguments.rawEntry[k];
			}
			return out;
		}
		if(isObject(arguments.rawEntry)){
			try { out["description"] = arguments.rawEntry.getDescription(); } catch(any e){ try { out["description"] = arguments.rawEntry.description; } catch(any e2){} }
			try { out["entityId"] = arguments.rawEntry.getEntityId(); } catch(any e){ try { out["entityId"] = arguments.rawEntry.entityId; } catch(any e2){} }
			try { out["ssoUrl"] = arguments.rawEntry.getSsoUrl(); } catch(any e){ try { out["ssoUrl"] = arguments.rawEntry.ssoUrl; } catch(any e2){} }
			try { out["ssoBinding"] = arguments.rawEntry.getSsoBinding(); } catch(any e){ try { out["ssoBinding"] = arguments.rawEntry.ssoBinding; } catch(any e2){} }
			try { out["sloUrl"] = arguments.rawEntry.getSloUrl(); } catch(any e){ try { out["sloUrl"] = arguments.rawEntry.sloUrl; } catch(any e2){} }
			try { out["sloBinding"] = arguments.rawEntry.getSloBinding(); } catch(any e){ try { out["sloBinding"] = arguments.rawEntry.sloBinding; } catch(any e2){} }
			try { out["logoutResponseUrl"] = arguments.rawEntry.getLogoutResponseUrl(); } catch(any e){ try { out["logoutResponseUrl"] = arguments.rawEntry.logoutResponseUrl; } catch(any e2){} }
			try { out["signRequests"] = arguments.rawEntry.isSignRequests(); } catch(any e){ try { out["signRequests"] = arguments.rawEntry.signRequests; } catch(any e2){} }
			try { out["signCertificate"] = arguments.rawEntry.getSignCertificate(); } catch(any e){ try { out["signCertificate"] = arguments.rawEntry.signCertificate; } catch(any e2){} }
			try { out["metadataRaw"] = arguments.rawEntry.getMetadataRaw(); } catch(any e){ try { out["metadataRaw"] = arguments.rawEntry.metadataRaw; } catch(any e2){} }
			try { out["metadataUrl"] = arguments.rawEntry.getMetadataUrl(); } catch(any e){ try { out["metadataUrl"] = arguments.rawEntry.metadataUrl; } catch(any e2){} }
			try { out["metadataFilePath"] = arguments.rawEntry.getMetadataFilePath(); } catch(any e){ try { out["metadataFilePath"] = arguments.rawEntry.metadataFilePath; } catch(any e2){} }
			try { out["refreshInterval"] = arguments.rawEntry.getRefreshInterval(); } catch(any e){ try { out["refreshInterval"] = arguments.rawEntry.refreshInterval; } catch(any e2){} }
		}
		return out;
	}

	private any function getStructValueCaseInsensitive(required any data, required string keyName){
		if(NOT isStruct(arguments.data) AND isObject(arguments.data))
			arguments.data = convertIdpEntryToStruct(arguments.data);
		if(isStruct(arguments.data)){
			for(var existingKey in arguments.data){
				if(compareNoCase(existingKey, arguments.keyName) EQ 0)
					return arguments.data[existingKey];
			}
		}
		return "";
	}

	private struct function readIdpNeoEntry(required string alias){
		var idpMap = getIdentityProvidersMap(getNeoSamlMap());
		for(var key in idpMap){
			if(compareNoCase(key, arguments.alias) EQ 0)
				return convertIdpEntryToStruct(idpMap[key]);
		}
		if(isSecurityServiceAvailable()){
			try {
				var meta = getIdpMetadataInternal(arguments.alias);
				if(isStruct(meta) AND structCount(meta) GT 0)
					return normalizeIdpMetadata(meta);
			}
			catch(any e){}
		}
		return {};
	}

	private string function normalizeXmlString(required any value){
		return reReplace(trim("" & arguments.value), "[\r\n\s]+", "", "all");
	}

	private string function normalizePathValue(required any value){
		return lCase(replace(replace(trim("" & arguments.value), "/", "\\", "all"), "\\\\", "\\", "all"));
	}

	private numeric function refreshIntervalToNumber(required any value){
		var text = trim("" & arguments.value);
		if(find(",", text))
			return val(listFirst(text, ","));
		return val(text);
	}

	private string function refreshIntervalToDisplay(required any value){
		var days = refreshIntervalToNumber(arguments.value);
		return days & ",0,0,0";
	}

	private string function normalizeSamlUrl(required any value){
		return lCase(trim(replace("" & arguments.value, "\", "/", "all")));
	}

	public string function getIdpFieldSetting(required string settingName){
		if(NOT isTestIdpPresent(variables.TEST_IDP_FIELD_ALIAS) AND NOT isTestIdpPresent(variables.TEST_IDP_FIELD_RENAME_ALIAS)){
			switch(lCase(trim(arguments.settingName))){
				case lCase(variables.SETTING_NAME):
					return variables.TEST_IDP_FIELD_ALIAS;
				case lCase(variables.SETTING_DESCRIPTION):
					return variables.TEST_IDP_FIELD_DESCRIPTION;
				case lCase(variables.SETTING_REFRESH):
					return variables.TEST_IDP_FIELD_REFRESH;
				case lCase(variables.SETTING_SAML_URL):
					return variables.TEST_IDP_URL;
				case lCase(variables.SETTING_XML_METADATA):
					return getTestMetadataXml();
				case lCase(variables.SETTING_METADATA_FILE_LOCATION):
					return getTestMetadataXmlPath();
				default:
					throw(message="Unsupported IDP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
		}
		var alias = getCurrentFieldTestAlias();
		var entry = readIdpNeoEntry(alias);
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_NAME):
				return alias;
			case lCase(variables.SETTING_DESCRIPTION):
				return trim("" & getStructValueCaseInsensitive(entry, "description"));
			case lCase(variables.SETTING_REFRESH):
				return len(trim("" & getStructValueCaseInsensitive(entry, "refreshInterval")))
					? refreshIntervalToDisplay(getStructValueCaseInsensitive(entry, "refreshInterval"))
					: variables.TEST_IDP_FIELD_REFRESH;
			case lCase(variables.SETTING_SAML_URL):
				return len(trim("" & getStructValueCaseInsensitive(entry, "metadataUrl")))
					? trim("" & getStructValueCaseInsensitive(entry, "metadataUrl"))
					: variables.TEST_IDP_URL;
			case lCase(variables.SETTING_XML_METADATA):
				var raw = trim("" & getStructValueCaseInsensitive(entry, "metadataRaw"));
				return len(raw) ? raw : getTestMetadataXml();
			case lCase(variables.SETTING_METADATA_FILE_LOCATION):
				var fLoc = trim("" & getStructValueCaseInsensitive(entry, "metadataFilePath"));
				return len(fLoc) ? fLoc : getTestMetadataXmlPath();
			default:
				throw(message="Unsupported IDP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public string function setIdpFieldSetting(required string settingName, required any settingValue){
		if(NOT isIdpFieldTestBaseReady() AND NOT isTestIdpPresent(getCurrentFieldTestAlias()))
			ensureIdpFieldTestDefaults();
		var alias = getCurrentFieldTestAlias();
		var entry = readIdpNeoEntry(alias);
		var currentUrl = len(trim("" & getStructValueCaseInsensitive(entry, "metadataUrl")))
			? trim("" & getStructValueCaseInsensitive(entry, "metadataUrl"))
			: variables.TEST_IDP_URL;
		var currentDescription = len(trim("" & getStructValueCaseInsensitive(entry, "description")))
			? trim("" & getStructValueCaseInsensitive(entry, "description"))
			: variables.TEST_IDP_FIELD_DESCRIPTION;
		var currentRefresh = len(trim("" & getStructValueCaseInsensitive(entry, "refreshInterval")))
			? refreshIntervalToDisplay(getStructValueCaseInsensitive(entry, "refreshInterval"))
			: variables.TEST_IDP_FIELD_REFRESH;
		var currentXml = trim("" & getStructValueCaseInsensitive(entry, "metadataRaw"));
		var currentFile = trim("" & getStructValueCaseInsensitive(entry, "metadataFilePath"));
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_NAME):
				modifyUrlIdpEntry(
					alias,
					trim("" & arguments.settingValue),
					currentDescription,
					currentRefresh,
					currentUrl,
					currentXml,
					currentFile
				);
				break;
			case lCase(variables.SETTING_DESCRIPTION):
				modifyUrlIdpEntry(alias, alias, trim("" & arguments.settingValue), currentRefresh, currentUrl, currentXml, currentFile);
				break;
			case lCase(variables.SETTING_REFRESH):
				modifyUrlIdpEntry(alias, alias, currentDescription, trim("" & arguments.settingValue), currentUrl, currentXml, currentFile);
				break;
			case lCase(variables.SETTING_SAML_URL):
				modifyUrlIdpEntry(alias, alias, currentDescription, currentRefresh, trim("" & arguments.settingValue), "", "");
				break;
			case lCase(variables.SETTING_XML_METADATA):
				modifyUrlIdpEntry(alias, alias, currentDescription, currentRefresh, "", trim("" & arguments.settingValue), "");
				break;
			case lCase(variables.SETTING_METADATA_FILE_LOCATION):
				modifyUrlIdpEntry(alias, alias, currentDescription, currentRefresh, "", "", trim("" & arguments.settingValue));
				break;
			default:
				throw(message="Unsupported IDP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		return getIdpFieldSetting(arguments.settingName);
	}

	public string function getIdpFieldNewSetValue(required string settingName, any currentValue = ""){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_NAME):
				return compareNoCase(trim("" & arguments.currentValue), variables.TEST_IDP_FIELD_RENAME_ALIAS) EQ 0
					? variables.TEST_IDP_FIELD_ALIAS
					: variables.TEST_IDP_FIELD_RENAME_ALIAS;
			case lCase(variables.SETTING_DESCRIPTION):
				return idpFieldValuesMatch(
					variables.TEST_IDP_FIELD_DESCRIPTION_UPDATED,
					arguments.currentValue,
					variables.SETTING_DESCRIPTION
				) ? variables.TEST_IDP_FIELD_DESCRIPTION : variables.TEST_IDP_FIELD_DESCRIPTION_UPDATED;
			case lCase(variables.SETTING_REFRESH):
				return idpFieldValuesMatch(
					variables.TEST_IDP_FIELD_REFRESH_UPDATED,
					arguments.currentValue,
					variables.SETTING_REFRESH
				) ? variables.TEST_IDP_FIELD_REFRESH : variables.TEST_IDP_FIELD_REFRESH_UPDATED;
			case lCase(variables.SETTING_SAML_URL):
				return idpFieldValuesMatch(
					variables.TEST_IDP_URL_ALT,
					arguments.currentValue,
					variables.SETTING_SAML_URL
				) ? variables.TEST_IDP_URL : variables.TEST_IDP_URL_ALT;
			case lCase(variables.SETTING_XML_METADATA):
				return idpFieldValuesMatch(
					getTestMetadataXmlAlt(),
					arguments.currentValue,
					variables.SETTING_XML_METADATA
				) ? getTestMetadataXml() : getTestMetadataXmlAlt();
			case lCase(variables.SETTING_METADATA_FILE_LOCATION):
				return idpFieldValuesMatch(
					getTestMetadataXmlAltPath(),
					arguments.currentValue,
					variables.SETTING_METADATA_FILE_LOCATION
				) ? getTestMetadataXmlPath() : getTestMetadataXmlAltPath();
			default:
				throw(message="Unsupported IDP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public boolean function idpFieldValuesMatch(required any expectedValue, required any actualValue, required string settingName){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_NAME):
				return compareNoCase(trim("" & arguments.expectedValue), trim("" & arguments.actualValue)) EQ 0;
			case lCase(variables.SETTING_DESCRIPTION):
				return lCase(trim("" & arguments.expectedValue)) EQ lCase(trim("" & arguments.actualValue));
			case lCase(variables.SETTING_REFRESH):
				return refreshIntervalToNumber(arguments.expectedValue) EQ refreshIntervalToNumber(arguments.actualValue);
			case lCase(variables.SETTING_SAML_URL):
				return normalizeSamlUrl(arguments.expectedValue) EQ normalizeSamlUrl(arguments.actualValue);
			case lCase(variables.SETTING_XML_METADATA):
				return normalizeXmlString(arguments.expectedValue) EQ normalizeXmlString(arguments.actualValue);
			case lCase(variables.SETTING_METADATA_FILE_LOCATION):
				return normalizePathValue(arguments.expectedValue) EQ normalizePathValue(arguments.actualValue);
			case lCase(variables.SETTING_OWN_ENTITY_ID):
				return lCase(trim("" & arguments.expectedValue)) EQ lCase(trim("" & arguments.actualValue));
			case lCase(variables.SETTING_OWN_SSO_URL):
			case lCase(variables.SETTING_OWN_SLO_URL):
			case lCase(variables.SETTING_OWN_LOGOUT_URL):
				return normalizeSamlUrl(arguments.expectedValue) EQ normalizeSamlUrl(arguments.actualValue);
			case lCase(variables.SETTING_OWN_SSO_BINDING):
			case lCase(variables.SETTING_OWN_SLO_BINDING):
				return normalizeBindingValue(arguments.expectedValue) EQ normalizeBindingValue(arguments.actualValue);
			case lCase(variables.SETTING_OWN_SIGN_REQUESTS):
				return formatBooleanSettingValue(arguments.expectedValue) EQ formatBooleanSettingValue(arguments.actualValue);
			case lCase(variables.SETTING_OWN_SIGN_CERT):
				return normalizeCertificateValue(arguments.expectedValue) EQ normalizeCertificateValue(arguments.actualValue);
			default:
				return lCase(trim("" & arguments.expectedValue)) EQ lCase(trim("" & arguments.actualValue));
		}
	}

	public string function formatIdpFieldDisplayValue(required string settingName, required any value){
		var text = trim("" & arguments.value);
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_NAME):
				return len(text) ? text : "(empty)";
			case lCase(variables.SETTING_DESCRIPTION):
				return len(text) ? text : "(empty)";
			case lCase(variables.SETTING_REFRESH):
				return len(text) ? text : variables.TEST_IDP_FIELD_REFRESH;
			case lCase(variables.SETTING_SAML_URL):
				return len(text) ? text : "(empty)";
			case lCase(variables.SETTING_XML_METADATA):
				if(len(text) GT 40)
					return left(text, 37) & "...";
				return len(text) ? text : "(empty)";
			case lCase(variables.SETTING_METADATA_FILE_LOCATION):
				return len(text) ? text : "(empty)";
			default:
				return text;
		}
	}

	private void function addUrlIdpWithFields(
		required string alias,
		required string description,
		required string refreshInterval,
		required string metadataUrl
	){
		if(isSecurityServiceAvailable()){
			var admin = loginAdmin();
			try {
				getSecurityAdminApi().addIdpMetadata(
					alias = arguments.alias,
					description = arguments.description,
					url = arguments.metadataUrl,
					refreshinterval = refreshIntervalToNumber(arguments.refreshInterval)
				);
				return;
			}
			finally {
				logoutAdmin(admin);
			}
		}
		addIdpToNeo(arguments.alias, {
			description = arguments.description,
			url = arguments.metadataUrl,
			refreshinterval = refreshIntervalToNumber(arguments.refreshInterval)
		});
	}

	private void function modifyUrlIdpEntry(
		required string oldAlias,
		required string newAlias,
		required string description,
		required string refreshInterval,
		required string metadataUrl,
		string rawXml = "",
		string metadataFile = ""
	){
		if(isSecurityServiceAvailable()){
			var admin = loginAdmin();
			try {
				var params = {
					oldalias = arguments.oldAlias,
					newalias = arguments.newAlias,
					description = arguments.description,
					refreshinterval = refreshIntervalToNumber(arguments.refreshInterval)
				};
				if(len(trim(arguments.rawXml))){
					params.rawxml = trim(arguments.rawXml);
				}
				else if(len(trim(arguments.metadataFile))){
					params.file = trim(arguments.metadataFile);
				}
				else if(len(trim(arguments.metadataUrl))){
					params.url = trim(arguments.metadataUrl);
				}
				getSecurityAdminApi().modifyIdpMetadata(argumentCollection=params);
				return;
			}
			catch(any e){
			}
			finally {
				logoutAdmin(admin);
			}
		}
		removeIdpFromNeo(arguments.oldAlias);
		var opts = {
			description = arguments.description,
			refreshinterval = refreshIntervalToNumber(arguments.refreshInterval)
		};
		if(len(trim(arguments.rawXml)))
			opts.rawxml = trim(arguments.rawXml);
		else if(len(trim(arguments.metadataFile)))
			opts.file = trim(arguments.metadataFile);
		else
			opts.url = arguments.metadataUrl;
		addIdpToNeo(arguments.newAlias, opts);
	}

	public void function removeOwnFieldTestIdp(){
		removeTestIdp(variables.TEST_IDP_OWN_FIELD_ALIAS);
	}

	public struct function getDefaultOwnFieldSnapshot(){
		return {
			entityId = variables.TEST_ENTITY_ID,
			ssoUrl = variables.TEST_SSO_URL,
			ssoBinding = "redirect",
			sloUrl = "",
			sloBinding = "",
			logoutResponseUrl = "",
			signRequests = false,
			signCertificate = getSigningCertificateFromXml(getTestMetadataXml())
		};
	}

	public void function ensureIdpOwnFieldTestDefaults(){
		removeOwnFieldTestIdp();
		addOwnIdpWithFields(variables.TEST_IDP_OWN_FIELD_ALIAS, getDefaultOwnFieldSnapshot());
	}

	public boolean function isIdpOwnFieldTestBaseReady(){
		if(NOT isTestIdpPresent(variables.TEST_IDP_OWN_FIELD_ALIAS))
			return false;
		return idpFieldValuesMatch(
			variables.TEST_ENTITY_ID,
			getIdpOwnFieldSetting(variables.SETTING_OWN_ENTITY_ID),
			variables.SETTING_OWN_ENTITY_ID
		);
	}

	private string function normalizeBindingValue(required any value){
		var text = lCase(trim("" & arguments.value));
		if(findNoCase("post", text))
			return "post";
		if(findNoCase("redirect", text))
			return "redirect";
		return text;
	}

	private string function normalizeCertificateValue(required any value){
		return reReplace(trim("" & arguments.value), "[\r\n\s]", "", "all");
	}

	private struct function readOwnFieldSnapshotFromNeo(required string alias){
		var entry = readIdpNeoEntry(arguments.alias);
		return {
			entityId = trim("" & getStructValueCaseInsensitive(entry, "entityId")),
			ssoUrl = trim("" & getStructValueCaseInsensitive(entry, "ssoUrl")),
			ssoBinding = trim("" & getStructValueCaseInsensitive(entry, "ssoBinding")),
			sloUrl = trim("" & getStructValueCaseInsensitive(entry, "sloUrl")),
			sloBinding = trim("" & getStructValueCaseInsensitive(entry, "sloBinding")),
			logoutResponseUrl = trim("" & getStructValueCaseInsensitive(entry, "logoutResponseUrl")),
			signRequests = toBoolean(getStructValueCaseInsensitive(entry, "signRequests")),
			signCertificate = normalizeCertificateValue(getStructValueCaseInsensitive(entry, "signCertificate"))
		};
	}

	private struct function readOwnFieldSnapshotFromAdminApi(required string alias){
		try {
			var meta = normalizeIdpMetadata(getIdpMetadataInternal(arguments.alias));
			if(NOT isStruct(meta) OR NOT structCount(meta))
				return {};
			return {
				entityId = trim("" & getStructValueCaseInsensitive(meta, "entityid")),
				ssoUrl = trim("" & getStructValueCaseInsensitive(meta, "ssourl")),
				ssoBinding = trim("" & getStructValueCaseInsensitive(meta, "ssobinding")),
				sloUrl = trim("" & getStructValueCaseInsensitive(meta, "slourl")),
				sloBinding = trim("" & getStructValueCaseInsensitive(meta, "slobinding")),
				logoutResponseUrl = trim("" & getStructValueCaseInsensitive(meta, "logoutresponseurl")),
				signRequests = toBoolean(getStructValueCaseInsensitive(meta, "signrequests")),
				signCertificate = normalizeCertificateValue(getStructValueCaseInsensitive(meta, "signcertificate"))
			};
		}
		catch(any e){
			return {};
		}
	}

	private void function mergeEmptyOwnFieldSnapshotFromAdminApi(required struct snapshot, required struct apiSnapshot){
		if(NOT structCount(arguments.apiSnapshot))
			return;
		for(var key in arguments.apiSnapshot){
			if(key EQ "signRequests"){
				if(NOT arguments.snapshot.signRequests AND arguments.apiSnapshot.signRequests)
					arguments.snapshot.signRequests = arguments.apiSnapshot.signRequests;
				continue;
			}
			if(key EQ "signCertificate"){
				if(NOT len(trim("" & arguments.snapshot.signCertificate)) AND len(trim("" & arguments.apiSnapshot.signCertificate)))
					arguments.snapshot.signCertificate = arguments.apiSnapshot.signCertificate;
				continue;
			}
			if(NOT len(trim("" & arguments.snapshot[key])) AND len(trim("" & arguments.apiSnapshot[key])))
				arguments.snapshot[key] = arguments.apiSnapshot[key];
		}
	}

	private struct function readOwnFieldSnapshot(required string alias){
		var snapshot = readOwnFieldSnapshotFromNeo(arguments.alias);
		if(isSecurityServiceAvailable())
			mergeEmptyOwnFieldSnapshotFromAdminApi(snapshot, readOwnFieldSnapshotFromAdminApi(arguments.alias));
		return snapshot;
	}

	private void function syncOwnIdpFieldsToNeo(required string alias, required struct fields){
		if(isTestIdpPresentInNeo(arguments.alias))
			removeIdpFromNeo(arguments.alias);
		addIdpToNeo(arguments.alias, {
			description = "CCS test IDP own SAML definition fields",
			entityid = arguments.fields.entityId,
			ssourl = arguments.fields.ssoUrl,
			ssobinding = arguments.fields.ssoBinding,
			slourl = arguments.fields.sloUrl,
			slobinding = arguments.fields.sloBinding,
			logoutresponseurl = arguments.fields.logoutResponseUrl,
			signrequests = arguments.fields.signRequests,
			signcertificate = arguments.fields.signCertificate
		});
	}

	private boolean function toBoolean(required any value){
		if(isBoolean(arguments.value))
			return arguments.value;
		return listFindNoCase("true,yes,1", lCase(trim("" & arguments.value))) GT 0;
	}

	private void function addOwnIdpWithFields(required string alias, required struct fields){
		addIdpViaAdminApi(
			alias = arguments.alias,
			description = "CCS test IDP own SAML definition fields",
			entityid = arguments.fields.entityId,
			ssourl = arguments.fields.ssoUrl,
			ssobinding = arguments.fields.ssoBinding,
			slourl = arguments.fields.sloUrl,
			slobinding = arguments.fields.sloBinding,
			logoutresponseurl = arguments.fields.logoutResponseUrl,
			signrequests = javaCast("boolean", arguments.fields.signRequests),
			signcertificate = arguments.fields.signCertificate
		);
		if(isSecurityServiceAvailable())
			syncOwnIdpFieldsToNeo(arguments.alias, arguments.fields);
	}

	private void function modifyOwnIdpEntry(required string alias, required struct fields){
		if(isSecurityServiceAvailable()){
			var admin = loginAdmin();
			try {
				getSecurityAdminApi().modifyIdpMetadata(
					oldalias = arguments.alias,
					newalias = arguments.alias,
					description = "CCS test IDP own SAML definition fields",
					entityid = arguments.fields.entityId,
					ssourl = arguments.fields.ssoUrl,
					ssobinding = arguments.fields.ssoBinding,
					slourl = arguments.fields.sloUrl,
					slobinding = arguments.fields.sloBinding,
					logoutresponseurl = arguments.fields.logoutResponseUrl,
					signrequests = javaCast("boolean", arguments.fields.signRequests),
					signcertificate = arguments.fields.signCertificate
				);
				syncOwnIdpFieldsToNeo(arguments.alias, arguments.fields);
				return;
			}
			finally {
				logoutAdmin(admin);
			}
		}
		removeIdpFromNeo(arguments.alias);
		addIdpToNeo(arguments.alias, {
			description = "CCS test IDP own SAML definition fields",
			entityid = arguments.fields.entityId,
			ssourl = arguments.fields.ssoUrl,
			ssobinding = arguments.fields.ssoBinding,
			slourl = arguments.fields.sloUrl,
			slobinding = arguments.fields.sloBinding,
			logoutresponseurl = arguments.fields.logoutResponseUrl,
			signrequests = arguments.fields.signRequests,
			signcertificate = arguments.fields.signCertificate
		});
	}

	public string function getIdpOwnFieldSetting(required string settingName){
		if(NOT isTestIdpPresent(variables.TEST_IDP_OWN_FIELD_ALIAS)){
			var defaults = getDefaultOwnFieldSnapshot();
			switch(lCase(trim(arguments.settingName))){
				case lCase(variables.SETTING_OWN_ENTITY_ID): return defaults.entityId;
				case lCase(variables.SETTING_OWN_SSO_URL): return defaults.ssoUrl;
				case lCase(variables.SETTING_OWN_SSO_BINDING): return defaults.ssoBinding;
				case lCase(variables.SETTING_OWN_SLO_URL): return defaults.sloUrl;
				case lCase(variables.SETTING_OWN_SLO_BINDING): return defaults.sloBinding;
				case lCase(variables.SETTING_OWN_LOGOUT_URL): return defaults.logoutResponseUrl;
				case lCase(variables.SETTING_OWN_SIGN_REQUESTS): return formatBooleanSettingValue(defaults.signRequests);
				case lCase(variables.SETTING_OWN_SIGN_CERT): return defaults.signCertificate;
				default: throw(message="Unsupported own IDP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
		}
		var snapshot = readOwnFieldSnapshot(variables.TEST_IDP_OWN_FIELD_ALIAS);
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_OWN_ENTITY_ID): return snapshot.entityId;
			case lCase(variables.SETTING_OWN_SSO_URL): return snapshot.ssoUrl;
			case lCase(variables.SETTING_OWN_SSO_BINDING): return snapshot.ssoBinding;
			case lCase(variables.SETTING_OWN_SLO_URL): return snapshot.sloUrl;
			case lCase(variables.SETTING_OWN_SLO_BINDING): return snapshot.sloBinding;
			case lCase(variables.SETTING_OWN_LOGOUT_URL): return snapshot.logoutResponseUrl;
			case lCase(variables.SETTING_OWN_SIGN_REQUESTS): return formatBooleanSettingValue(snapshot.signRequests);
			case lCase(variables.SETTING_OWN_SIGN_CERT): return snapshot.signCertificate;
			default: throw(message="Unsupported own IDP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public string function setIdpOwnFieldSetting(required string settingName, required any settingValue){
		if(NOT isIdpOwnFieldTestBaseReady() AND NOT isTestIdpPresent(variables.TEST_IDP_OWN_FIELD_ALIAS))
			ensureIdpOwnFieldTestDefaults();
		var snapshot = isTestIdpPresent(variables.TEST_IDP_OWN_FIELD_ALIAS)
			? readOwnFieldSnapshot(variables.TEST_IDP_OWN_FIELD_ALIAS)
			: getDefaultOwnFieldSnapshot();
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_OWN_ENTITY_ID): snapshot.entityId = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_OWN_SSO_URL): snapshot.ssoUrl = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_OWN_SSO_BINDING): snapshot.ssoBinding = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_OWN_SLO_URL): snapshot.sloUrl = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_OWN_SLO_BINDING): snapshot.sloBinding = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_OWN_LOGOUT_URL): snapshot.logoutResponseUrl = trim("" & arguments.settingValue); break;
			case lCase(variables.SETTING_OWN_SIGN_REQUESTS): snapshot.signRequests = toBoolean(arguments.settingValue); break;
			case lCase(variables.SETTING_OWN_SIGN_CERT): snapshot.signCertificate = normalizeCertificateValue(arguments.settingValue); break;
			default: throw(message="Unsupported own IDP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		modifyOwnIdpEntry(variables.TEST_IDP_OWN_FIELD_ALIAS, snapshot);
		var result = getIdpOwnFieldSetting(arguments.settingName);
		if(NOT idpFieldValuesMatch(arguments.settingValue, result, arguments.settingName)){
			syncOwnIdpFieldsToNeo(variables.TEST_IDP_OWN_FIELD_ALIAS, snapshot);
			result = getIdpOwnFieldSetting(arguments.settingName);
		}
		return result;
	}

	public string function getIdpOwnFieldNewSetValue(required string settingName, any currentValue = ""){
		var defaults = getDefaultOwnFieldSnapshot();
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_OWN_ENTITY_ID):
				return idpFieldValuesMatch(variables.TEST_OWN_ENTITY_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.entityId : variables.TEST_OWN_ENTITY_UPDATED;
			case lCase(variables.SETTING_OWN_SSO_URL):
				return idpFieldValuesMatch(variables.TEST_OWN_SSO_URL_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.ssoUrl : variables.TEST_OWN_SSO_URL_UPDATED;
			case lCase(variables.SETTING_OWN_SSO_BINDING):
				return idpFieldValuesMatch(variables.TEST_OWN_SSO_BINDING_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.ssoBinding : variables.TEST_OWN_SSO_BINDING_UPDATED;
			case lCase(variables.SETTING_OWN_SLO_URL):
				return idpFieldValuesMatch(variables.TEST_OWN_SLO_URL_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.sloUrl : variables.TEST_OWN_SLO_URL_UPDATED;
			case lCase(variables.SETTING_OWN_SLO_BINDING):
				return idpFieldValuesMatch(variables.TEST_OWN_SLO_BINDING_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.sloBinding : variables.TEST_OWN_SLO_BINDING_UPDATED;
			case lCase(variables.SETTING_OWN_LOGOUT_URL):
				return idpFieldValuesMatch(variables.TEST_OWN_LOGOUT_URL_UPDATED, arguments.currentValue, arguments.settingName)
					? defaults.logoutResponseUrl : variables.TEST_OWN_LOGOUT_URL_UPDATED;
			case lCase(variables.SETTING_OWN_SIGN_REQUESTS):
				return formatBooleanSettingValue(arguments.currentValue) EQ "true" ? "false" : "true";
			case lCase(variables.SETTING_OWN_SIGN_CERT):
				var altCert = getAlternateSigningCertificateFromXml();
				return idpFieldValuesMatch(altCert, arguments.currentValue, arguments.settingName)
					? defaults.signCertificate : altCert;
			default:
				throw(message="Unsupported own IDP field setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public string function formatIdpOwnFieldDisplayValue(required string settingName, required any value){
		var text = trim("" & arguments.value);
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.SETTING_OWN_SIGN_REQUESTS):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "Enabled" : "Disabled";
			case lCase(variables.SETTING_OWN_SIGN_CERT):
				return len(text) GT 40 ? left(text, 40) & "..." : (len(text) ? text : "(empty)");
			case lCase(variables.SETTING_OWN_SLO_URL):
			case lCase(variables.SETTING_OWN_SLO_BINDING):
			case lCase(variables.SETTING_OWN_LOGOUT_URL):
				return len(text) ? text : "(empty)";
			default:
				return len(text) ? text : "(empty)";
		}
	}

}
