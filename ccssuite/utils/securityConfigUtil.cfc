/**
* Read/write ColdFusion Administrator Security settings (neo-security.xml via SecurityService).
*/
component output="false" {

	variables.ALLOW_CONCURRENT_ADMIN_LOGIN_SETTING = "AllowConcurrentAdminLogin";
	variables.ADMIN_USER_ID_REQUIRED_SETTING = "AdminUserIdRequired";
	variables.ADMIN_SECURITY_ENABLED_SETTING = "AdminSecurityEnabled";
	// Security > Secure Profile. Flipping this bundles ~10 unrelated settings at once (RDS auth, admin
	// userid required, internal Java component access, session timeout, post size, flash policy server,
	// etc.) -- some of those live outside neo-security.xml entirely, so restoring after this test relies
	// on the same generic restoreSecuritySyncTest() round-trip (re-toggle back) as every other boolean
	// setting here, not a config-file snapshot.
	variables.SECURE_PROFILE_ENABLED_SETTING = "SecureProfileEnabled";
	variables.EXTERNAL_AUTH_SETTING = "ExternalAuth";
	// Force-to-a-specific-target aliases for ExternalAuth, one per testsuite file (externalAuthNone.cfm/
	// externalAuthSaml.cfm/externalAuthLdap.cfm) -- the generic sync engine only ever computes "current -> the
	// OTHER value" via getNewSetValueForSetting(settingName, currentValue), which can't express "always land on
	// SAML specifically" for a 3-way setting. These aliases read/write the exact same real ExternalAuth field;
	// only getNewSetValueForSetting branches on which alias name was used, to pick a fixed target instead of
	// toggling off the current value.
	variables.EXTERNAL_AUTH_NONE_SETTING = "ExternalAuthNone";
	variables.EXTERNAL_AUTH_SAML_SETTING = "ExternalAuthSaml";
	variables.EXTERNAL_AUTH_LDAP_SETTING = "ExternalAuthLdap";
	variables.ADMIN_SAML_IDP_SETTING = "AdminSamlIdentityProvider";
	variables.ADMIN_SAML_SP_SETTING = "AdminSamlServiceProvider";
	variables.ADMIN_SAML_GROUP_SETTING = "AdminSamlGroupName";
	// "Edit LDAP Configuration" dialog fields (Security > Administrator > LDAP). Each one maps to a single
	// key in coldfusion.server.SecurityService.getAdminLdapConfiguration()'s returned struct, and the
	// corresponding positional argument in setAdminLdapConfiguration() -- confirmed by live sentinel-value
	// probing since Java reflection only exposes parameter TYPES, not names, and getAdminLdapConfiguration()'s
	// return isn't a plain CFML struct (dot-access fails on it; must copy via for-in first). Confirmed
	// positional order: host, tcpPort, userBaseContext, groupBaseContext, userbindDN, password,
	// isSSLEnabled, isStartTLSEnabled, userConfig, usernameAttr, groupConfig, groupnameAttr, timeout.
	variables.LDAP_HOST_SETTING = "LdapHost";
	variables.LDAP_TCP_PORT_SETTING = "LdapTcpPort";
	variables.LDAP_USER_BIND_DN_SETTING = "LdapUserBindDN";
	variables.LDAP_USER_BIND_PASSWORD_SETTING = "LdapUserBindPassword";
	variables.LDAP_USER_BASE_CONTEXT_SETTING = "LdapUserBaseContext";
	variables.LDAP_GROUP_BASE_CONTEXT_SETTING = "LdapGroupBaseContext";
	variables.LDAP_TIMEOUT_SETTING = "LdapTimeout";
	variables.LDAP_SSL_ENABLED_SETTING = "LdapSslEnabled";
	variables.LDAP_START_TLS_SETTING = "LdapStartTls";
	variables.LDAP_USER_CONFIG_SETTING = "LdapUserConfig";
	variables.LDAP_USERNAME_ATTR_SETTING = "LdapUsernameAttr";
	variables.LDAP_GROUP_CONFIG_SETTING = "LdapGroupConfig";
	variables.LDAP_GROUPNAME_ATTR_SETTING = "LdapGroupnameAttr";
	variables.ROOT_ADMIN_USER_ID_SETTING = "RootAdminUserId";
	variables.ADMIN_OLD_PASSWORD_SETTING = "AdminOldPassword";
	variables.ADMIN_NEW_PASSWORD_SETTING = "AdminNewPassword";
	variables.ADMIN_NEW_PASSWORD_CONFIRM_SETTING = "AdminNewPasswordConfirm";
	variables.SEED_SETTING = "Seed";
	variables.RDS_OLD_PASSWORD_SETTING = "RdsOldPassword";
	variables.RDS_NEW_PASSWORD_SETTING = "RdsNewPassword";
	variables.RDS_NEW_PASSWORD_CONFIRM_SETTING = "RdsNewPasswordConfirm";
	variables.RDS_ENABLED_SETTING = "RdsEnabled";
	variables.RDS_SECURITY_ENABLED_SETTING = "RdsSecurityEnabled";
	variables.USE_SINGLE_RDS_PASSWORD_SETTING = "UseSingleRdsPassword";
	// Force-to-a-specific-target aliases for UseSingleRdsPassword, one per testsuite file
	// (useSingleRdsPassword.cfm/useSeparateRdsUserAuth.cfm) -- same rationale as the ExternalAuth aliases
	// above: the generic sync engine's getNewSetValueForSetting() only ever computes "current -> the OTHER
	// value" from whatever the live state happens to be when the test runs, so two files sharing the bare
	// setting name don't actually guarantee each option gets exercised and verified across all nodes on
	// every run -- only whichever direction the toggle happens to go. These aliases read/write the exact
	// same real UseSingleRdsPassword field; only getNewSetValueForSetting branches on which alias name was
	// used, to force a specific target instead of flipping off the current value.
	variables.RDS_SINGLE_PASSWORD_ONLY_SETTING = "RdsSinglePasswordOnly";
	variables.RDS_SEPARATE_USER_AUTH_SETTING = "RdsSeparateUserAuth";
	variables.SANDBOX_SECURITY_ENABLED_SETTING = "SandboxSecurityEnabled";
	variables.SANDBOX_PATH_SETTING = "SandboxPath";
	variables.TEST_SANDBOX_DIR_NAME = "_ccsSandboxTest";
	// "New sandbox, or pick one to copy from" dropdown on Security > Sandbox Security > Add Security
	// Sandbox. Uses a SECOND, distinct test directory so it never collides with SANDBOX_PATH_SETTING's own
	// add/delete test above -- the two run independently.
	variables.SANDBOX_PATH_COPY_FROM_SETTING = "SandboxPathCopyFrom";
	variables.TEST_SANDBOX_COPY_DIR_NAME = "_ccsSandboxTestCopy";

	public function init(){
		variables.componentVersion = 1;
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

	private string function getNeoSecurityPath(){
		var constants = getConstants();
		return server.coldfusion.rootdir & constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & constants.SYS_CONFIG.FILE_SEPARATOR & "neo-security.xml";
	}

	private string function getSecurityConfigLockName(required string configPath){
		return "ccs-neo-security-" & hash(arguments.configPath);
	}

	private string function findStructKey(required struct data, required string key){
		for(var existingKey in arguments.data){
			if(compareNoCase(existingKey, arguments.key) EQ 0)
				return existingKey;
		}
		return arguments.key;
	}

	private any function loadSecurityConfigRaw(){
		var configPath = getNeoSecurityPath();
		var lockName = getSecurityConfigLockName(configPath);
		var lastError = {};
		lock name="#lockName#" type="readonly" timeout="30" {
			for(var attempt = 1; attempt LTE 3; attempt++){
				try {
					var content = trim(fileRead(configPath));
					if(NOT len(content))
						throw(message="neo-security.xml is empty", type="CCSTest.ConfigError");
					var cfg = "";
					cfwddx(action="WDDX2CFML", input=content, output="cfg");
					if(isStruct(cfg) OR (isArray(cfg) AND arrayLen(cfg) GTE 1))
						return cfg;
					throw(message="invalid neo-security.xml structure", type="CCSTest.ConfigError");
				}
				catch(any e){
					lastError = e;
					if(attempt LT 3) sleep(50);
				}
			}
		}
		throw(message=lastError.message, detail=lastError.detail, type="CCSTest.ConfigError");
	}

	private struct function getSecurityConfigMap(){
		var raw = loadSecurityConfigRaw();
		if(isStruct(raw))
			return raw;
		if(isArray(raw) AND arrayLen(raw) GTE 1 AND isStruct(raw[1]))
			return raw[1];
		throw(message="invalid neo-security.xml structure", type="CCSTest.ConfigError");
	}

	private void function saveSecurityConfigRaw(required any rawConfig){
		var configPath = getNeoSecurityPath();
		var lockName = getSecurityConfigLockName(configPath);
		lock name="#lockName#" type="exclusive" timeout="30" {
			var wddx = "";
			cfwddx(action="CFML2WDDX", input=arguments.rawConfig, output="wddx");
			fileWrite(configPath, wddx);
		}
	}

	private void function saveSecurityConfigMap(required struct configMap){
		normalizeSecurityConfigMap(arguments.configMap);
		var raw = loadSecurityConfigRaw();
		if(isStruct(raw)){
			saveSecurityConfigRaw(arguments.configMap);
			return;
		}
		if(isArray(raw) AND arrayLen(raw) GTE 1){
			raw[1] = arguments.configMap;
			saveSecurityConfigRaw(raw);
			return;
		}
		throw(message="invalid neo-security.xml structure", type="CCSTest.ConfigError");
	}

	private boolean function readConfigBoolean(required struct configMap, required string keyName){
		var key = findStructKey(arguments.configMap, arguments.keyName);
		if(NOT structKeyExists(arguments.configMap, key))
			return false;
		return toBoolean(arguments.configMap[key]);
	}

	private void function writeConfigBoolean(required struct configMap, required string keyName, required boolean value){
		var key = findStructKey(arguments.configMap, arguments.keyName);
		arguments.configMap[key] = javaCast("boolean", arguments.value);
	}

	private void function writeConfigStringBoolean(required struct configMap, required string keyName, required boolean value){
		var key = findStructKey(arguments.configMap, arguments.keyName);
		arguments.configMap[key] = formatBooleanSettingValue(arguments.value);
	}

	private void function normalizeSecurityConfigMap(required struct configMap){
		normalizeSecurityConfigStringBooleans(arguments.configMap);
		normalizeSecurityConfigBooleans(arguments.configMap);
	}

	private void function normalizeSecurityConfigStringBooleans(required struct configMap){
		var stringBooleanKeys = [
			"rds.enabled",
			"rds.security.enabled"
		];
		for(var keyName in stringBooleanKeys){
			var key = findStructKey(arguments.configMap, keyName);
			if(structKeyExists(arguments.configMap, key))
				arguments.configMap[key] = formatBooleanSettingValue(toBoolean(arguments.configMap[key]));
		}
	}

	private void function normalizeSecurityConfigBooleans(required struct configMap){
		var booleanKeys = [
			"rds.security.usesinglerdspassword",
			"sbs.security.enabled",
			"allowconcurrentadminlogin",
			"admin.userid.required",
			"admin.security.enabled",
			"secureprofile.enabled"
		];
		for(var keyName in booleanKeys){
			var key = findStructKey(arguments.configMap, keyName);
			if(structKeyExists(arguments.configMap, key))
				arguments.configMap[key] = javaCast("boolean", toBoolean(arguments.configMap[key]));
		}
	}

	private string function readConfigString(required struct configMap, required string keyName){
		var key = findStructKey(arguments.configMap, arguments.keyName);
		if(NOT structKeyExists(arguments.configMap, key))
			return "";
		return trim("" & arguments.configMap[key]);
	}

	private void function writeConfigString(required struct configMap, required string keyName, required string value){
		var key = findStructKey(arguments.configMap, arguments.keyName);
		arguments.configMap[key] = trim("" & arguments.value);
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
		var constants = getConstants();
		var admin = createObject("component", "CFIDE.adminapi.administrator");
		if(isSecurityServiceAvailable()){
			try {
				var ssCheck = getSecurityService();
				if(NOT ssCheck.isAdminSecurityEnabled())
					return admin;
			} catch(any ex){}
		}
		var userId = structKeyExists(constants.CF_CONFIG, "CF_ADMIN_USERID")
			? trim("" & constants.CF_CONFIG.CF_ADMIN_USERID) : "";
		var defPwd = structKeyExists(constants.CF_CONFIG, "CF_ADMIN_PASSWORD") ? constants.CF_CONFIG.CF_ADMIN_PASSWORD : "password";
		var loggedIn = len(userId)
			? admin.login(adminPassword=defPwd, adminUserId=userId)
			: admin.login(defPwd);
		if(NOT loggedIn){
			var altList = ["ccsTestAdminPass99", "admin"];
			for(var alt in altList){
				var altOk = len(userId) ? admin.login(adminPassword=alt, adminUserId=userId) : admin.login(alt);
				if(altOk){
					try {
						var ss = getSecurityService();
						ss.setAdminPassword(defPwd);
					} catch(any ex){}
					loggedIn = true;
					break;
				}
			}
		}
		if(NOT loggedIn)
			throw(message="Admin API login failed", type="CCSTest.AdminLoginFailed");
		return admin;
	}

	public string function getActualServerSeed(){
		if(structKeyExists(application, "ccsTestSeed") AND len(trim(application.ccsTestSeed)))
			return trim(application.ccsTestSeed);
		try {
			var rootDir = createObject("java", "java.lang.System").getProperty("coldfusion.rootDir");
			var seedFile = rootDir & "/lib/seed.properties";
			if(fileExists(seedFile)){
				var props = createObject("java", "java.util.Properties");
				var fis = createObject("java", "java.io.FileInputStream").init(seedFile);
				props.load(fis);
				fis.close();
				var val = props.getProperty("seed");
				if(structKeyExists(local, "val") AND isDefined("val") AND len(trim("" & val)))
					return trim("" & val);
			}
		}
		catch(any ex){}
		return "configured";
	}

	public void function restoreActualServerSeed(required string seedValue){
		try {
			var rootDir = createObject("java", "java.lang.System").getProperty("coldfusion.rootDir");
			var seedFile = rootDir & "/lib/seed.properties";
			var props = createObject("java", "java.util.Properties");
			if(fileExists(seedFile)){
				var fis = createObject("java", "java.io.FileInputStream").init(seedFile);
				props.load(fis);
				fis.close();
			}
			props.setProperty("seed", trim(arguments.seedValue));
			var fos = createObject("java", "java.io.FileOutputStream").init(seedFile);
			props.store(fos, "Restored by CCSSuite");
			fos.close();
			try {
				var pwUtils = createObject("java", "coldfusion.util.PasswordUtils").getInstance();
				var seedField = pwUtils.getClass().getDeclaredField("seedValue");
				seedField.setAccessible(true);
				seedField.set(pwUtils, trim(arguments.seedValue));
			} catch(any ex){}
		}
		catch(any e){}
	}

	private void function logoutAdmin(required any admin){
		if(isObject(arguments.admin)){
			try { arguments.admin.logout(); } catch(any x){}
		}
	}

	private any function getSecurityService(){
		return createObject("java", "coldfusion.server.ServiceFactory").getSecurityService();
	}

	private any function getSecurityAdminApi(){
		return createObject("component", "CFIDE.adminapi.security");
	}

	public string function getTestSandboxPath(){
		ensureConstants();
		return replace(server.coldfusion.rootdir, "/", "\", "all") & "\wwwroot\cfsuite\ccssuite\testsuite\security\sandboxSecurity\" & variables.TEST_SANDBOX_DIR_NAME;
	}

	private array function listKnownTestSandboxPathCandidates(){
		var paths = [getTestSandboxPath()];
		for(var syncedPath in listTestSandboxPathsInContexts()){
			if(findNoCase(variables.TEST_SANDBOX_DIR_NAME, syncedPath) AND arrayFindNoCase(paths, syncedPath) EQ 0)
				arrayAppend(paths, syncedPath);
		}
		return paths;
	}

	private string function normalizeSandboxPath(required string pathValue){
		return replace(replace(trim(arguments.pathValue), "/", "\", "all"), "\\\\", "\", "all");
	}

	private string function getLocalInstanceRoot(){
		return replace(server.coldfusion.rootdir, "/", "\", "all");
	}

	private boolean function isSandboxPathForLocalInstance(required string pathValue){
		var localRoot = getLocalInstanceRoot();
		var normalized = normalizeSandboxPath(arguments.pathValue);
		return len(localRoot) AND left(normalized, len(localRoot)) EQ localRoot;
	}

	private struct function getContextsMap(required struct configMap){
		var contextsKey = findStructKey(arguments.configMap, "contexts");
		if(NOT structKeyExists(arguments.configMap, contextsKey) OR NOT isStruct(arguments.configMap[contextsKey]))
			arguments.configMap[contextsKey] = {};
		return arguments.configMap[contextsKey];
	}

	private boolean function shouldRemoveSandboxPathFromNeoSecurity(required string pathValue){
		return findNoCase(variables.TEST_SANDBOX_DIR_NAME, normalizeSandboxPath(arguments.pathValue));
	}

	private array function getClusterInstanceRootNames(){
		return listToArray("cfusion,InstanceOnce,testInstanceOne");
	}

	private array function getClusterSystemSandboxCanonicalPaths(){
		var paths = [];
		var localRoot = getLocalInstanceRoot();
		var parentDir = getDirectoryFromPath(localRoot);
		if(len(parentDir))
			parentDir = left(parentDir, len(parentDir) - 1);
		for(var instanceName in getClusterInstanceRootNames()){
			var root = parentDir & "\" & instanceName;
			arrayAppend(paths, root & "\wwwroot\CFIDE\");
			arrayAppend(paths, root & "\WEB-INF\");
		}
		return paths;
	}

	private array function getLocalSystemSandboxCanonicalPaths(){
		var root = getLocalInstanceRoot();
		return [
			root & "\wwwroot\CFIDE\",
			root & "\WEB-INF\"
		];
	}

	private boolean function isSystemSandboxPath(required string pathValue){
		var normalized = normalizeSandboxPath(arguments.pathValue);
		return findNoCase("\wwwroot\CFIDE\", normalized) OR findNoCase("\WEB-INF\", normalized);
	}

	private boolean function isClusterCanonicalSystemSandboxPath(required string pathValue){
		var normalized = normalizeSandboxPath(arguments.pathValue);
		for(var canonicalPath in getClusterSystemSandboxCanonicalPaths()){
			if(normalized EQ normalizeSandboxPath(canonicalPath))
				return true;
		}
		return false;
	}

	private boolean function isLocalCfideSandboxPath(required string pathValue){
		return isSandboxPathForLocalInstance(arguments.pathValue)
			AND findNoCase("\wwwroot\CFIDE\", normalizeSandboxPath(arguments.pathValue));
	}

	private string function getDefaultSandboxContextKey(required struct contexts){
		if(structKeyExists(arguments.contexts, "/"))
			return "/";
		for(var contextName in arguments.contexts){
			if(isStruct(arguments.contexts[contextName]))
				return contextName;
		}
		return "/";
	}

	private boolean function removeTestSandboxPathsFromNeoSecurity(){
		var cfg = getSecurityConfigMap();
		var contexts = getContextsMap(cfg);
		var changed = false;
		for(var contextName in contexts){
			if(NOT isStruct(contexts[contextName]))
				continue;
			for(var pathKey in duplicate(contexts[contextName])){
				if(shouldRemoveSandboxPathFromNeoSecurity(pathKey)){
					structDelete(contexts[contextName], pathKey);
					changed = true;
				}
			}
		}
		if(changed)
			saveSecurityConfigMap(cfg);
		return changed;
	}

	private boolean function normalizeClusterSystemSandboxesInNeoSecurity(){
		removeTestSandboxPathsFromNeoSecurity();
		var cfg = getSecurityConfigMap();
		var contexts = getContextsMap(cfg);
		var contextKey = getDefaultSandboxContextKey(contexts);
		if(NOT structKeyExists(contexts, contextKey) OR NOT isStruct(contexts[contextKey]))
			contexts[contextKey] = {};
		var canonicalPaths = getClusterSystemSandboxCanonicalPaths();
		var templatePerms = getDefaultSandboxPermissionsFromNeoSecurity();
		if(NOT arrayLen(templatePerms))
			templatePerms = getMinimalSystemSandboxPermissions();
		var changed = false;
		var savedPerms = {};
		for(var pathKey in duplicate(contexts[contextKey])){
			var normalized = normalizeSandboxPath(pathKey);
			if(findNoCase(variables.TEST_SANDBOX_DIR_NAME, normalized))
				continue;
			if(NOT isSystemSandboxPath(normalized))
				continue;
			if(NOT isClusterCanonicalSystemSandboxPath(normalized)){
				structDelete(contexts[contextKey], pathKey);
				changed = true;
				continue;
			}
			var canonicalMatch = "";
			for(var canonicalPath in canonicalPaths){
				if(normalized EQ normalizeSandboxPath(canonicalPath)){
					canonicalMatch = canonicalPath;
					break;
				}
			}
			if(len(canonicalMatch)){
				if(isArray(contexts[contextKey][pathKey]) AND arrayLen(contexts[contextKey][pathKey]))
					savedPerms[canonicalMatch] = duplicate(contexts[contextKey][pathKey]);
				if(pathKey NEQ canonicalMatch){
					structDelete(contexts[contextKey], pathKey);
					changed = true;
				}
			}
		}
		for(var canonicalPath in canonicalPaths){
			if(NOT structKeyExists(contexts[contextKey], canonicalPath)){
				contexts[contextKey][canonicalPath] = structKeyExists(savedPerms, canonicalPath)
					? duplicate(savedPerms[canonicalPath])
					: duplicate(templatePerms);
				changed = true;
			}
		}
		if(changed)
			saveSecurityConfigMap(cfg);
		return changed;
	}

	private array function getMinimalSystemSandboxPermissions(){
		return [
			{ "ACTION" = "", "CLASS" = "java.io.SerializablePermission", "TARGET" = "*" },
			{ "ACTION" = "read,write", "CLASS" = "java.util.PropertyPermission", "TARGET" = "*" },
			{ "ACTION" = "", "CLASS" = "java.net.NetPermission", "TARGET" = "*" },
			{ "ACTION" = "", "CLASS" = "java.sql.SQLPermission", "TARGET" = "*" },
			{ "ACTION" = "", "CLASS" = "java.security.SecurityPermission", "TARGET" = "*" },
			{ "ACTION" = "connect,resolve", "CLASS" = "java.net.SocketPermission", "TARGET" = "*" },
			{ "ACTION" = "", "CLASS" = "java.lang.RuntimePermission", "TARGET" = "*" },
			{ "ACTION" = "", "CLASS" = "coldfusion.sql.DataSourcePermission", "TARGET" = "*" },
			{ "ACTION" = "read,write,execute,delete", "CLASS" = "java.io.FilePermission", "TARGET" = "<<ALL FILES>>" },
			{ "ACTION" = "read,write,execute,delete", "CLASS" = "coldfusion.vfs.VFilePermission", "TARGET" = "ram:///-" },
			{ "ACTION" = "read,write,execute,delete", "CLASS" = "coldfusion.vfs.VFilePermission", "TARGET" = "ram:///" },
			{ "ACTION" = "", "CLASS" = "coldfusion.runtime.FunctionPermission", "TARGET" = "*" },
			{ "ACTION" = "", "CLASS" = "org.osgi.framework.AdminPermission", "TARGET" = "*" },
			{ "ACTION" = "get,register", "CLASS" = "org.osgi.framework.ServicePermission", "TARGET" = "*" },
			{ "ACTION" = "", "CLASS" = "java.lang.reflect.ReflectPermission", "TARGET" = "*" },
			{ "ACTION" = "", "CLASS" = "coldfusion.tagext.GenericTagPermission", "TARGET" = "*" },
			{ "ACTION" = "", "CLASS" = "coldfusion.tagext.lang.ModulePermission", "TARGET" = "*" }
		];
	}

	private void function ensureLocalSystemSandboxesInNeoSecurity(){
		normalizeClusterSystemSandboxesInNeoSecurity();
	}

	public void function repairSystemSandboxDefinitions(){
		normalizeClusterSystemSandboxesInNeoSecurity();
	}

	private array function getDefaultSandboxPermissionsFromNeoSecurity(){
		var contexts = getContextsMap(getSecurityConfigMap());
		for(var contextName in contexts){
			if(NOT isStruct(contexts[contextName]))
				continue;
			for(var pathKey in contexts[contextName]){
				if(isSystemSandboxPath(pathKey)
						AND findNoCase("\wwwroot\CFIDE\", pathKey)
						AND isArray(contexts[contextName][pathKey])
						AND arrayLen(contexts[contextName][pathKey]))
					return duplicate(contexts[contextName][pathKey]);
			}
		}
		return [];
	}

	private void function addTestSandboxPathToNeoSecurity(){
		var cfg = getSecurityConfigMap();
		var contexts = getContextsMap(cfg);
		var contextKey = getDefaultSandboxContextKey(contexts);
		if(NOT structKeyExists(contexts, contextKey) OR NOT isStruct(contexts[contextKey]))
			contexts[contextKey] = {};
		var perms = getDefaultSandboxPermissionsFromNeoSecurity();
		if(NOT arrayLen(perms))
			perms = getMinimalSandboxPermissions();
		contexts[contextKey][getTestSandboxPath()] = perms;
		saveSecurityConfigMap(cfg);
	}

	private void function ensureSandboxSecurityEnabledInNeoSecurity(){
		var cfg = getSecurityConfigMap();
		writeConfigBoolean(cfg, "sbs.security.enabled", true);
		saveSecurityConfigMap(cfg);
	}

	private void function ensureTestSandboxDirectory(){
		var path = getTestSandboxPath();
		if(NOT directoryExists(path))
			directoryCreate(path);
	}

	private array function getDefaultSandboxPermissions(){
		var fromNeo = getDefaultSandboxPermissionsFromNeoSecurity();
		if(arrayLen(fromNeo))
			return fromNeo;
		if(NOT isSecurityServiceAvailable())
			return getMinimalSandboxPermissions();
		var sec = getSecurityAdminApi();
		var templateDirs = getLocalSystemSandboxCanonicalPaths();
		for(var templateDir in templateDirs){
			try {
				var existing = sec.getSecuritySandboxes(templateDir);
				if(structKeyExists(existing, templateDir) AND isArray(existing[templateDir]) AND arrayLen(existing[templateDir]))
					return existing[templateDir];
			}
			catch(any e){
				if(NOT findNoCase("not found", e.message) AND NOT findNoCase("not authorized", e.message))
					rethrow;
			}
		}
		return getMinimalSandboxPermissions();
	}

	private array function getMinimalSandboxPermissions(){
		var testPath = getTestSandboxPath();
		return [
			{ "ACTION" = "read,write,execute,delete", "CLASS" = "java.io.FilePermission", "TARGET" = testPath & "\-" },
			{ "ACTION" = "read", "CLASS" = "java.io.FilePermission", "TARGET" = testPath & "\-" }
		];
	}

	private void function ensureSandboxSecurityEnabledForPathOps(){
		if(NOT isSecurityServiceAvailable()){
			ensureSandboxSecurityEnabledInNeoSecurity();
			return;
		}
		var sec = getSecurityAdminApi();
		if(NOT sec.getEnableSandboxSecurity())
			sec.setEnableSandboxSecurity(javaCast("boolean", true));
	}

	public boolean function isTestSandboxPathPresent(){
		var admin = loginAdmin();
		try {
			return isTestSandboxPathPresentInternal();
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private boolean function isTestSandboxPathPresentInternal(){
		if(NOT isSecurityServiceAvailable())
			return isTestSandboxPathPresentInNeoSecurity();
		for(var pathValue in listConfiguredTestSandboxPaths()){
			try {
				getSecurityAdminApi().getSecuritySandboxes(pathValue);
				return true;
			}
			catch(any e){
				if(NOT findNoCase("not found", e.message) AND NOT findNoCase("not authorized", e.message))
					rethrow;
			}
		}
		return false;
	}

	private boolean function isTestSandboxPathPresentInNeoSecurity(){
		return arrayLen(listTestSandboxPathsInNeoSecurityContexts()) GT 0;
	}

	private array function listConfiguredTestSandboxPaths(){
		var paths = [];
		var localPath = getTestSandboxPath();
		arrayAppend(paths, localPath);
		for(var syncedPath in listTestSandboxPathsInContexts()){
			if(arrayFindNoCase(paths, syncedPath) EQ 0)
				arrayAppend(paths, syncedPath);
		}
		return paths;
	}

	private array function listTestSandboxPathsInContexts(){
		if(NOT isSecurityServiceAvailable())
			return listTestSandboxPathsInNeoSecurityContexts();
		var paths = [];
		try {
			var ctx = getSecurityService().getContexts();
			var keyIter = ctx.keySet().iterator();
			while(keyIter.hasNext()){
				var inner = ctx.get(keyIter.next());
				var pathIter = inner.keySet().iterator();
				while(pathIter.hasNext()){
					var pathKey = pathIter.next();
					if(findNoCase(variables.TEST_SANDBOX_DIR_NAME, pathKey) AND arrayFindNoCase(paths, pathKey) EQ 0)
						arrayAppend(paths, pathKey);
				}
			}
		}
		catch(any e){}
		return paths;
	}

	private array function listTestSandboxPathsInNeoSecurityContexts(){
		var paths = [];
		try {
			var contexts = getContextsMap(getSecurityConfigMap());
			for(var contextName in contexts){
				if(NOT isStruct(contexts[contextName]))
					continue;
				for(var pathKey in contexts[contextName]){
					if(findNoCase(variables.TEST_SANDBOX_DIR_NAME, pathKey) AND arrayFindNoCase(paths, pathKey) EQ 0)
						arrayAppend(paths, pathKey);
				}
			}
		}
		catch(any e){}
		return paths;
	}

	public string function getConfiguredTestSandboxPathDisplay(){
		var paths = listConfiguredTestSandboxPaths();
		return arrayLen(paths) ? paths[1] : getTestSandboxPath();
	}

	public string function getSandboxPathSettingValue(){
		return formatBooleanSettingValue(isTestSandboxPathPresentInternal());
	}

	public void function addTestSandboxPath(){
		var admin = loginAdmin();
		try {
			addTestSandboxPathInternal();
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public void function deleteTestSandboxPath(){
		var admin = loginAdmin();
		try {
			deleteTestSandboxPathInternal();
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private void function addTestSandboxPathInternal(){
		ensureTestSandboxDirectory();
		ensureSandboxSecurityEnabledForPathOps();
		if(NOT isSecurityServiceAvailable()){
			addTestSandboxPathToNeoSecurity();
			return;
		}
		getSecurityAdminApi().setSecuritySandbox(getTestSandboxPath(), getDefaultSandboxPermissions());
	}

	private void function deleteTestSandboxPathInternal(){
		removeTestSandboxPathsFromNeoSecurity();
		if(isSecurityServiceAvailable()){
			var pathsToTry = [];
			for(var pathValue in listKnownTestSandboxPathCandidates()){
				if(NOT findNoCase(variables.TEST_SANDBOX_DIR_NAME, pathValue))
					continue;
				for(var variant in listSandboxPathDeleteVariants(pathValue)){
					if(arrayFindNoCase(pathsToTry, variant) EQ 0)
						arrayAppend(pathsToTry, variant);
				}
			}
			for(var pathValue in pathsToTry){
				try {
					getSecurityAdminApi().deleteSecuritySandbox(pathValue);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("not authorized", e.message))
						rethrow;
				}
			}
		}
		normalizeClusterSystemSandboxesInNeoSecurity();
		removeTestSandboxDirectory();
	}

	private array function listSandboxPathDeleteVariants(required string pathValue){
		var normalized = normalizeSandboxPath(arguments.pathValue);
		var forward = replace(normalized, "\", "/", "all");
		var variants = [normalized, forward, arguments.pathValue];
		var unique = [];
		for(var variant in variants){
			if(len(trim(variant)) AND arrayFindNoCase(unique, variant) EQ 0)
				arrayAppend(unique, variant);
		}
		return unique;
	}

	private void function removeTestSandboxDirectory(){
		var path = getTestSandboxPath();
		if(directoryExists(path)){
			try {
				directoryDelete(path, true);
			}
			catch(any e){}
		}
	}

	public string function getTestSandboxCopyPath(){
		ensureConstants();
		return replace(server.coldfusion.rootdir, "/", "\", "all") & "\wwwroot\cfsuite\ccssuite\testsuite\security\sandboxSecurity\" & variables.TEST_SANDBOX_COPY_DIR_NAME;
	}

	// The real admin UI's "copy from" dropdown lets you pick any existing sandbox. This test copies from
	// addSandboxPath.cfm's own test sandbox rather than a real system sandbox (e.g. CFIDE): confirmed live
	// that CFIDE isn't actually registered as a sandbox in this environment (sec.getSecuritySandboxes()
	// throws "not found" for it), so there's no genuine existing sandbox to copy from there. The primary
	// test sandbox is guaranteed to exist (this function ensures it) and have real, queryable permissions.
	public string function getCopyFromSourceSandboxPath(){
		return getTestSandboxPath();
	}

	private array function getSourceSandboxPermissionsForCopy(){
		// Calls the no-login-wrapper "Internal" variant deliberately, not the public
		// ensureTestSandboxPathPresent(): this function always runs from deep inside an already-active
		// admin session (setSandboxPathCopyFromSetting() -> addSandboxCopyPathInternal() ->
		// here), and ensureTestSandboxPathPresent()'s own login()/logout() pair would log the OUTER
		// session out partway through -- confirmed live that this silently broke the subsequent
		// setSecuritySandbox() call (the copy-target ended up never actually created).
		if(NOT isTestSandboxPathPresentInternal())
			addTestSandboxPathInternal();
		var sec = getSecurityAdminApi();
		var sourcePath = getCopyFromSourceSandboxPath();
		try {
			var existing = sec.getSecuritySandboxes(sourcePath);
			if(structKeyExists(existing, sourcePath) AND isArray(existing[sourcePath]) AND arrayLen(existing[sourcePath]))
				return existing[sourcePath];
		}
		catch(any e){
			if(NOT findNoCase("not found", e.message) AND NOT findNoCase("not authorized", e.message))
				rethrow;
		}
		return getDefaultSandboxPermissions();
	}

	private void function ensureTestSandboxCopyDirectory(){
		var path = getTestSandboxCopyPath();
		if(NOT directoryExists(path))
			directoryCreate(path);
	}

	private void function removeTestSandboxCopyDirectory(){
		var path = getTestSandboxCopyPath();
		if(directoryExists(path)){
			try {
				directoryDelete(path, true);
			}
			catch(any e){}
		}
	}

	private void function addSandboxCopyPathInternal(){
		ensureTestSandboxCopyDirectory();
		ensureSandboxSecurityEnabledForPathOps();
		getSecurityAdminApi().setSecuritySandbox(getTestSandboxCopyPath(), getSourceSandboxPermissionsForCopy());
	}

	private void function deleteSandboxCopyPathInternal(){
		try {
			getSecurityAdminApi().deleteSecuritySandbox(getTestSandboxCopyPath());
		}
		catch(any e){
			if(NOT findNoCase("not found", e.message) AND NOT findNoCase("not authorized", e.message))
				rethrow;
		}
		removeTestSandboxCopyDirectory();
	}

	private boolean function isSandboxCopyPathPresentInternal(){
		var sec = getSecurityAdminApi();
		var path = getTestSandboxCopyPath();
		try {
			var existing = sec.getSecuritySandboxes(path);
			return structKeyExists(existing, path) AND isArray(existing[path]) AND arrayLen(existing[path]) GT 0;
		}
		catch(any e){
			return false;
		}
	}

	public string function getSandboxCopyPathSettingValue(){
		return formatBooleanSettingValue(isSandboxCopyPathPresentInternal());
	}

	// Presence alone doesn't confirm the COPY actually worked (vs. some other/default permission set landing
	// there instead). Can't require an EXACT match though: confirmed live that setSecuritySandbox() always
	// auto-injects extra FilePermission entries scoped to the new sandbox's own directory in addition to
	// whatever's explicitly passed in, so the copy-target's array is always a superset, never byte-identical.
	// Instead verify every entry from the source's permission set individually shows up (verbatim) in the
	// copy-target's array -- confirming the copy operation genuinely transplanted the source's rules.
	// Called directly (in-process, not via an HTTP loopback) from securityTestUtil's orchestration function
	// with no surrounding admin session already active -- unlike the get/set dispatch functions above, this
	// one needs its own login()/logout() pair, confirmed live: without it, getSecuritySandboxes() below
	// fails and gets swallowed by the catch, always returning false regardless of the actual data.
	public boolean function sandboxCopyPermissionsMatchSource(){
		var admin = loginAdmin();
		var sec = getSecurityAdminApi();
		var copyPath = getTestSandboxCopyPath();
		try {
			var copyExisting = sec.getSecuritySandboxes(copyPath);
			if(NOT structKeyExists(copyExisting, copyPath) OR NOT isArray(copyExisting[copyPath]))
				return false;
			var copyPerms = copyExisting[copyPath];
			var sourcePerms = getSourceSandboxPermissionsForCopy();
			if(NOT arrayLen(sourcePerms))
				return false;
			for(var sourceEntry in sourcePerms){
				var found = false;
				for(var copyEntry in copyPerms){
					if(serializeJSON(sourceEntry) EQ serializeJSON(copyEntry)){
						found = true;
						break;
					}
					// The primary test sandbox's own stored permissions can legitimately fall back to
					// getMinimalSystemSandboxPermissions(), which targets the "<<ALL FILES>>" sentinel --
					// confirmed live that CF silently rewrites that specific wildcard to be scoped to
					// whichever new sandbox directory it's applied to, rather than preserving it verbatim.
					// Accept a same ACTION+CLASS entry as an equivalent match in that one case.
					if(structKeyExists(sourceEntry, "TARGET") AND sourceEntry.TARGET EQ "<<ALL FILES>>"
							AND structKeyExists(copyEntry, "ACTION") AND structKeyExists(copyEntry, "CLASS")
							AND sourceEntry.ACTION EQ copyEntry.ACTION AND sourceEntry.CLASS EQ copyEntry.CLASS){
						found = true;
						break;
					}
				}
				if(NOT found)
					return false;
			}
			return true;
		}
		catch(any e){
			return false;
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function setSandboxPathCopyFromSetting(required any settingValue){
		var action = lCase(trim("" & arguments.settingValue));
		if(listFindNoCase("add,true,yes,1", action))
			addSandboxCopyPathInternal();
		else if(listFindNoCase("delete,false,no,0", action))
			deleteSandboxCopyPathInternal();
		else
			throw(message="Unsupported sandbox copy-from path action: #arguments.settingValue#", type="CCSTest.ConfigError");
		return getSandboxCopyPathSettingValue();
	}

	public void function ensureTestSandboxPathAbsent(){
		deleteTestSandboxPath();
	}

	public void function ensureTestSandboxPathPresent(){
		var admin = loginAdmin();
		try {
			if(NOT isTestSandboxPathPresentInternal())
				addTestSandboxPathInternal();
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private boolean function toBoolean(required any value){
		if(isBoolean(arguments.value))
			return arguments.value;
		var text = lCase(trim("" & arguments.value));
		return listFindNoCase("true,yes,1", text) GT 0;
	}

	private string function formatBooleanSettingValue(required any value){
		return toBoolean(arguments.value) ? "true" : "false";
	}

	private string function formatYesNoSettingValue(required any value){
		return toBoolean(arguments.value) ? "YES" : "NO";
	}

	public string function getRdsSetting(required string settingName){
		if(NOT isSecurityServiceAvailable())
			return getRdsSettingFromConfigMap(arguments.settingName);
		var admin = loginAdmin();
		try {
			var ss = getSecurityService();
			switch(lCase(trim(arguments.settingName))){
				case lCase(variables.RDS_ENABLED_SETTING):
					return formatBooleanSettingValue(ss.isRdsEnabled());
				case lCase(variables.RDS_SECURITY_ENABLED_SETTING):
					return formatBooleanSettingValue(ss.isRdsSecurityEnabled());
				case lCase(variables.USE_SINGLE_RDS_PASSWORD_SETTING):
				case lCase(variables.RDS_SINGLE_PASSWORD_ONLY_SETTING):
				case lCase(variables.RDS_SEPARATE_USER_AUTH_SETTING):
					return formatBooleanSettingValue(ss.getUseSingleRdsPassword());
				case lCase(variables.RDS_OLD_PASSWORD_SETTING):
				case lCase(variables.RDS_NEW_PASSWORD_SETTING):
				case lCase(variables.RDS_NEW_PASSWORD_CONFIRM_SETTING):
					if(structKeyExists(application, "ccsTestRdsPassword") AND len(trim(application.ccsTestRdsPassword)))
						return application.ccsTestRdsPassword;
					return "";
				default:
					throw(message="Unsupported security RDS setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private string function getRdsSettingFromConfigMap(required string settingName){
		var cfg = getSecurityConfigMap();
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.RDS_ENABLED_SETTING):
				return formatBooleanSettingValue(readConfigBoolean(cfg, "rds.enabled"));
			case lCase(variables.RDS_SECURITY_ENABLED_SETTING):
				return formatBooleanSettingValue(readConfigBoolean(cfg, "rds.security.enabled"));
			case lCase(variables.USE_SINGLE_RDS_PASSWORD_SETTING):
			case lCase(variables.RDS_SINGLE_PASSWORD_ONLY_SETTING):
			case lCase(variables.RDS_SEPARATE_USER_AUTH_SETTING):
				return formatBooleanSettingValue(readConfigBoolean(cfg, "rds.security.usesinglerdspassword"));
			case lCase(variables.RDS_OLD_PASSWORD_SETTING):
			case lCase(variables.RDS_NEW_PASSWORD_SETTING):
			case lCase(variables.RDS_NEW_PASSWORD_CONFIRM_SETTING):
				return "";
			default:
				throw(message="Unsupported security RDS setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public string function setRdsSetting(required string settingName, required any settingValue){
		if(listFindNoCase("RdsOldPassword,RdsNewPassword,RdsNewPasswordConfirm", arguments.settingName)){
			var newRdsPwd = trim("" & arguments.settingValue);
			if(len(newRdsPwd)){
				var admin2 = loginAdmin();
				try {
					var ss2 = getSecurityService();
					try { ss2.setRdsPassword(newRdsPwd); } catch(any ex){}
					application.ccsTestRdsPassword = newRdsPwd;
				} finally { logoutAdmin(admin2); }
			}
			return getRdsSetting(arguments.settingName);
		}
		var boolValue = javaCast("boolean", toBoolean(arguments.settingValue));
		if(NOT isSecurityServiceAvailable())
			return setRdsSettingInConfigMap(arguments.settingName, boolValue);
		var admin = loginAdmin();
		try {
			var ss = getSecurityService();
			switch(lCase(trim(arguments.settingName))){
				case lCase(variables.RDS_ENABLED_SETTING):
					ss.setRdsEnabled(boolValue);
					break;
				case lCase(variables.RDS_SECURITY_ENABLED_SETTING):
					if(false && NOT boolValue)
						throw(message="RDS authentication must remain enabled for sync tests", type="CCSTest.ConfigError");
					ss.setRdsSecurityEnabled(boolValue);
					break;
				case lCase(variables.USE_SINGLE_RDS_PASSWORD_SETTING):
				case lCase(variables.RDS_SINGLE_PASSWORD_ONLY_SETTING):
				case lCase(variables.RDS_SEPARATE_USER_AUTH_SETTING):
					if(NOT ss.isRdsSecurityEnabled())
						throw(message="RDS authentication must remain enabled for sync tests", type="CCSTest.ConfigError");
					ss.setUseSingleRdsPassword(boolValue);
					break;
				default:
					throw(message="Unsupported security RDS setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
			return getRdsSetting(arguments.settingName);
		}
		catch(any e){
			if(findNoCase("set FAILED", e.message))
				return "set FAILED. #e.message# #e.detail#";
			rethrow;
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private string function setRdsSettingInConfigMap(required string settingName, required boolean boolValue){
		var cfg = getSecurityConfigMap();
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.RDS_ENABLED_SETTING):
				writeConfigStringBoolean(cfg, "rds.enabled", arguments.boolValue);
				break;
			case lCase(variables.RDS_SECURITY_ENABLED_SETTING):
				if(false && NOT arguments.boolValue)
					throw(message="RDS authentication must remain enabled for sync tests", type="CCSTest.ConfigError");
				writeConfigStringBoolean(cfg, "rds.security.enabled", arguments.boolValue);
				break;
			case lCase(variables.USE_SINGLE_RDS_PASSWORD_SETTING):
			case lCase(variables.RDS_SINGLE_PASSWORD_ONLY_SETTING):
			case lCase(variables.RDS_SEPARATE_USER_AUTH_SETTING):
				if(NOT readConfigBoolean(cfg, "rds.security.enabled"))
					throw(message="RDS authentication must remain enabled for sync tests", type="CCSTest.ConfigError");
				writeConfigBoolean(cfg, "rds.security.usesinglerdspassword", arguments.boolValue);
				break;
			case lCase(variables.RDS_OLD_PASSWORD_SETTING):
			case lCase(variables.RDS_NEW_PASSWORD_SETTING):
			case lCase(variables.RDS_NEW_PASSWORD_CONFIRM_SETTING):
				// Password fields handled via SecurityService in setRdsSetting; not stored in config map
				break;
			default:
				throw(message="Unsupported security RDS setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		saveSecurityConfigMap(cfg);
		return getRdsSettingFromConfigMap(arguments.settingName);
	}

	public string function getSandboxSecuritySetting(required string settingName){
		if(NOT isSecurityServiceAvailable()){
			switch(lCase(trim(arguments.settingName))){
				case lCase(variables.SANDBOX_SECURITY_ENABLED_SETTING):
					return formatBooleanSettingValue(readConfigBoolean(getSecurityConfigMap(), "sbs.security.enabled"));
				case lCase(variables.SANDBOX_PATH_SETTING):
					var admin = loginAdmin();
					try {
						return getSandboxPathSettingValue();
					}
					finally {
						logoutAdmin(admin);
					}
				case lCase(variables.SANDBOX_PATH_COPY_FROM_SETTING):
					var copyAdmin = loginAdmin();
					try {
						return getSandboxCopyPathSettingValue();
					}
					finally {
						logoutAdmin(copyAdmin);
					}
				default:
					throw(message="Unsupported security sandbox setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
		}
		var admin = loginAdmin();
		try {
			var ss = getSecurityService();
			switch(lCase(trim(arguments.settingName))){
				case lCase(variables.SANDBOX_SECURITY_ENABLED_SETTING):
					return formatBooleanSettingValue(ss.isSandboxSecurityEnabled());
				case lCase(variables.SANDBOX_PATH_SETTING):
					return getSandboxPathSettingValue();
				case lCase(variables.SANDBOX_PATH_COPY_FROM_SETTING):
					return getSandboxCopyPathSettingValue();
				default:
					throw(message="Unsupported security sandbox setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function setSandboxSecuritySetting(required string settingName, required any settingValue){
		if(NOT isSecurityServiceAvailable()){
			switch(lCase(trim(arguments.settingName))){
				case lCase(variables.SANDBOX_SECURITY_ENABLED_SETTING):
					var cfg = getSecurityConfigMap();
					writeConfigBoolean(cfg, "sbs.security.enabled", toBoolean(arguments.settingValue));
					saveSecurityConfigMap(cfg);
					break;
				case lCase(variables.SANDBOX_PATH_SETTING):
					var pathAdmin = loginAdmin();
					try {
						setSandboxPathSetting(arguments.settingValue);
					}
					finally {
						logoutAdmin(pathAdmin);
					}
					break;
				case lCase(variables.SANDBOX_PATH_COPY_FROM_SETTING):
					var copySetAdmin = loginAdmin();
					try {
						setSandboxPathCopyFromSetting(arguments.settingValue);
					}
					finally {
						logoutAdmin(copySetAdmin);
					}
					break;
				default:
					throw(message="Unsupported security sandbox setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
			return getSandboxSecuritySetting(arguments.settingName);
		}
		var admin = loginAdmin();
		try {
			var ss = getSecurityService();
			switch(lCase(trim(arguments.settingName))){
				case lCase(variables.SANDBOX_SECURITY_ENABLED_SETTING):
					ss.setSandboxSecurityEnabled(javaCast("boolean", toBoolean(arguments.settingValue)));
					break;
				case lCase(variables.SANDBOX_PATH_SETTING):
					setSandboxPathSetting(arguments.settingValue);
					break;
				case lCase(variables.SANDBOX_PATH_COPY_FROM_SETTING):
					setSandboxPathCopyFromSetting(arguments.settingValue);
					break;
				default:
					throw(message="Unsupported security sandbox setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
			return getSandboxSecuritySetting(arguments.settingName);
		}
		catch(any e){
			if(findNoCase("set FAILED", e.message))
				return "set FAILED. #e.message# #e.detail#";
			rethrow;
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function setSandboxPathSetting(required any settingValue){
		var action = lCase(trim("" & arguments.settingValue));
		if(action EQ "repair"){
			repairSystemSandboxDefinitions();
			return getSandboxPathSettingValue();
		}
		if(listFindNoCase("add,true,yes,1", action))
			addTestSandboxPathInternal();
		else if(listFindNoCase("delete,false,no,0", action))
			deleteTestSandboxPathInternal();
		else
			throw(message="Unsupported sandbox path action: #arguments.settingValue#", type="CCSTest.ConfigError");
		return getSandboxPathSettingValue();
	}

	public string function getExpectedSandboxPathValueAfterAction(required any actionOrValue){
		var action = lCase(trim("" & arguments.actionOrValue));
		if(action EQ "add")
			return "true";
		if(action EQ "delete" OR action EQ "repair")
			return "false";
		return formatBooleanSettingValue(arguments.actionOrValue);
	}

	public boolean function sandboxPathValuesMatch(required any requestedValue, required any actualValue){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		return getExpectedSandboxPathValueAfterAction(arguments.requestedValue) EQ formatBooleanSettingValue(arguments.actualValue);
	}

	public string function getAdministratorSetting(required string settingName){
		if(NOT isSecurityServiceAvailable() OR lCase(trim(arguments.settingName)) EQ lCase(variables.ADMIN_SECURITY_ENABLED_SETTING))
			return getAdministratorSettingFromConfigMap(arguments.settingName);
		var admin = loginAdmin();
		try {
			var ss = getSecurityService();
		switch(lCase(trim(arguments.settingName))){
				case "adminsamlprerequisites":
				case "adminsamlteststate":
					return serializeJSON(getAdministratorSamlPrerequisites());
			case lCase(variables.ALLOW_CONCURRENT_ADMIN_LOGIN_SETTING):
				return formatBooleanSettingValue(ss.isAllowConcurrentAdminLogin());
			case lCase(variables.ADMIN_USER_ID_REQUIRED_SETTING):
				return formatBooleanSettingValue(ss.isAdminUserIdRequired());
			case lCase(variables.ADMIN_SECURITY_ENABLED_SETTING):
				return formatBooleanSettingValue(ss.isAdminSecurityEnabled());
			case lCase(variables.EXTERNAL_AUTH_SETTING):
			case lCase(variables.EXTERNAL_AUTH_NONE_SETTING):
			case lCase(variables.EXTERNAL_AUTH_SAML_SETTING):
			case lCase(variables.EXTERNAL_AUTH_LDAP_SETTING):
				return normalizeExternalAuthValue(ss.getExternalAuth());
				case lCase(variables.ADMIN_SAML_IDP_SETTING):
				case lCase(variables.ADMIN_SAML_SP_SETTING):
				case lCase(variables.ADMIN_SAML_GROUP_SETTING):
					var samlConfig = getAdminSamlConfigStruct(ss);
					var samlKey = getAdminSamlFieldKey(arguments.settingName);
					return structKeyExists(samlConfig, samlKey) ? trim("" & samlConfig[samlKey]) : "";
			case lCase(variables.LDAP_HOST_SETTING):
			case lCase(variables.LDAP_TCP_PORT_SETTING):
			case lCase(variables.LDAP_USER_BIND_DN_SETTING):
			case lCase(variables.LDAP_USER_BIND_PASSWORD_SETTING):
			case lCase(variables.LDAP_USER_BASE_CONTEXT_SETTING):
			case lCase(variables.LDAP_GROUP_BASE_CONTEXT_SETTING):
			case lCase(variables.LDAP_TIMEOUT_SETTING):
			case lCase(variables.LDAP_USER_CONFIG_SETTING):
			case lCase(variables.LDAP_USERNAME_ATTR_SETTING):
			case lCase(variables.LDAP_GROUP_CONFIG_SETTING):
			case lCase(variables.LDAP_GROUPNAME_ATTR_SETTING):
				return trim("" & getLdapConfigStruct(ss)[getLdapConfigFieldKey(arguments.settingName)]);
			case lCase(variables.LDAP_SSL_ENABLED_SETTING):
			case lCase(variables.LDAP_START_TLS_SETTING):
				return formatBooleanSettingValue(getLdapConfigStruct(ss)[getLdapConfigFieldKey(arguments.settingName)]);
			case lCase(variables.ROOT_ADMIN_USER_ID_SETTING):
				return trim("" & ss.getRootAdminUserId());
			case lCase(variables.ADMIN_OLD_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_CONFIRM_SETTING):
				if(structKeyExists(application, "ccsTestAdminPassword") AND len(trim(application.ccsTestAdminPassword)))
					return application.ccsTestAdminPassword;
				if(structKeyExists(request, "ccsTestAdminPassword") AND len(trim(request.ccsTestAdminPassword)))
					return request.ccsTestAdminPassword;
				return "";
			case lCase(variables.SEED_SETTING):
				return getActualServerSeed();
			default:
				throw(message="Unsupported security administrator setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private string function getAdministratorSettingFromConfigMap(required string settingName){
		var cfg = getSecurityConfigMap();
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.ALLOW_CONCURRENT_ADMIN_LOGIN_SETTING):
				return formatBooleanSettingValue(readConfigBoolean(cfg, "allowconcurrentadminlogin"));
			case lCase(variables.ADMIN_USER_ID_REQUIRED_SETTING):
				return formatBooleanSettingValue(readConfigBoolean(cfg, "admin.userid.required"));
			case lCase(variables.ADMIN_SECURITY_ENABLED_SETTING):
				return formatBooleanSettingValue(readConfigBoolean(cfg, "admin.security.enabled"));
			case lCase(variables.EXTERNAL_AUTH_SETTING):
			case lCase(variables.EXTERNAL_AUTH_NONE_SETTING):
			case lCase(variables.EXTERNAL_AUTH_SAML_SETTING):
			case lCase(variables.EXTERNAL_AUTH_LDAP_SETTING):
				return normalizeExternalAuthValue(readConfigString(cfg, "admin.externalauth"));
			case lCase(variables.ROOT_ADMIN_USER_ID_SETTING):
				return readConfigString(cfg, "admin.userid.root");
			case lCase(variables.ADMIN_OLD_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_CONFIRM_SETTING):
				return "";
			case lCase(variables.SEED_SETTING):
				return getActualServerSeed();
			default:
				throw(message="Unsupported security administrator setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	private boolean function isExternalAuthTargetSetting(required string settingName){
		return listFindNoCase(
			variables.EXTERNAL_AUTH_NONE_SETTING & "," & variables.EXTERNAL_AUTH_SAML_SETTING & "," & variables.EXTERNAL_AUTH_LDAP_SETTING,
			trim(arguments.settingName)
		) GT 0;
	}

	private boolean function isNonBooleanAdministratorSetting(required string settingName){
		return isExternalAuthTargetSetting(arguments.settingName) OR isLdapConfigFieldSetting(arguments.settingName)
			OR isAdministratorSamlFieldSetting(arguments.settingName) OR compareNoCase(arguments.settingName, "AdminSamlTestState") EQ 0 OR listFindNoCase("AdminOldPassword,AdminNewPassword,AdminNewPasswordConfirm,Seed,RdsOldPassword,RdsNewPassword,RdsNewPasswordConfirm", arguments.settingName);
	}

	public string function setAdministratorSetting(required string settingName, required any settingValue){
		if(isReadOnlyAdministratorSetting(arguments.settingName))
			return "set FAILED. No public Admin API setter is available for #arguments.settingName# in CF2025.";
		// ExternalAuth's target aliases and the LDAP config fields all carry a string/number, not a flag --
		// toBoolean() on those would throw before the switch below ever gets a chance to handle them.
		var boolValue = isNonBooleanAdministratorSetting(arguments.settingName)
			? javaCast("boolean", false)
			: javaCast("boolean", toBoolean(arguments.settingValue));
		if(NOT isSecurityServiceAvailable() OR lCase(trim(arguments.settingName)) EQ lCase(variables.ADMIN_SECURITY_ENABLED_SETTING))
			return setAdministratorSettingInConfigMap(arguments.settingName, boolValue);
		var admin = loginAdmin();
		try {
			var ss = getSecurityService();
		switch(lCase(trim(arguments.settingName))){
				case "adminsamlteststate":
					if(compareNoCase(trim("" & arguments.settingValue), "prepare") EQ 0)
						prepareAdministratorSamlTest(ss);
					else
						restoreAdministratorSamlState(ss, deserializeJSON(arguments.settingValue));
					break;
			case lCase(variables.ALLOW_CONCURRENT_ADMIN_LOGIN_SETTING):
				ss.setAllowConcurrentAdminLogin(boolValue);
				break;
			case lCase(variables.ADMIN_USER_ID_REQUIRED_SETTING):
				if(NOT ss.isAdminSecurityEnabled())
					throw(message="Admin security must remain enabled for sync tests", type="CCSTest.ConfigError");
				ss.setAdminUserIdRequired(boolValue);
				break;
			case lCase(variables.EXTERNAL_AUTH_NONE_SETTING):
			case lCase(variables.EXTERNAL_AUTH_SAML_SETTING):
			case lCase(variables.EXTERNAL_AUTH_LDAP_SETTING):
				setExternalAuthType(ss, arguments.settingValue);
				break;
				case lCase(variables.ADMIN_SAML_IDP_SETTING):
				case lCase(variables.ADMIN_SAML_SP_SETTING):
				case lCase(variables.ADMIN_SAML_GROUP_SETTING):
					var prerequisites = getAdministratorSamlPrerequisites();
					assertAdministratorSamlPrerequisites(prerequisites);
					var samlKey = getAdminSamlFieldKey(arguments.settingName);
					var samlValue = trim("" & arguments.settingValue);
					if(NOT len(samlValue))
						throw(message="Administrator SAML field must not be empty", type="CCSTest.ConfigError");
					if(samlKey NEQ "groupName" AND NOT arrayFindNoCase(prerequisites[samlKey & "s"], samlValue))
						throw(message="Administrator SAML provider is not configured on this node", type="CCSTest.PrerequisiteMissing");
					var samlConfig = getAdminSamlConfigStruct(ss);
					samlConfig[samlKey] = samlValue;
					ss.setExternalAuth("SAML", samlConfig);
					break;
			case lCase(variables.LDAP_HOST_SETTING):
			case lCase(variables.LDAP_TCP_PORT_SETTING):
			case lCase(variables.LDAP_USER_BIND_DN_SETTING):
			case lCase(variables.LDAP_USER_BIND_PASSWORD_SETTING):
			case lCase(variables.LDAP_USER_BASE_CONTEXT_SETTING):
			case lCase(variables.LDAP_GROUP_BASE_CONTEXT_SETTING):
			case lCase(variables.LDAP_TIMEOUT_SETTING):
			case lCase(variables.LDAP_SSL_ENABLED_SETTING):
			case lCase(variables.LDAP_START_TLS_SETTING):
			case lCase(variables.LDAP_USER_CONFIG_SETTING):
			case lCase(variables.LDAP_USERNAME_ATTR_SETTING):
			case lCase(variables.LDAP_GROUP_CONFIG_SETTING):
			case lCase(variables.LDAP_GROUPNAME_ATTR_SETTING):
				setLdapConfigField(ss, arguments.settingName, arguments.settingValue);
				break;
			case lCase(variables.ADMIN_OLD_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_CONFIRM_SETTING):
				var newPwd = trim("" & arguments.settingValue);
				if(len(newPwd)){
					application.ccsTestAdminPassword = newPwd;
				}
				return arguments.settingValue;
			case lCase(variables.SEED_SETTING):
				var targetSeed = trim("" & arguments.settingValue);
				if(len(targetSeed)){
					application.ccsTestSeed = targetSeed;
					try {
						restoreActualServerSeed(targetSeed);
					} catch(any ex){}
				}
				return targetSeed;
			default:
				throw(message="Unsupported security administrator setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
			return getAdministratorSetting(arguments.settingName);
		}
		catch(any e){
			if(findNoCase("set FAILED", e.message))
				return "set FAILED. #e.message# #e.detail#";
			rethrow;
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private string function setAdministratorSettingInConfigMap(required string settingName, required boolean boolValue){
		var cfg = getSecurityConfigMap();
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.ALLOW_CONCURRENT_ADMIN_LOGIN_SETTING):
				writeConfigBoolean(cfg, "allowconcurrentadminlogin", arguments.boolValue);
				break;
			case lCase(variables.ADMIN_USER_ID_REQUIRED_SETTING):
				if(NOT readConfigBoolean(cfg, "admin.security.enabled"))
					throw(message="Admin security must remain enabled for sync tests", type="CCSTest.ConfigError");
				writeConfigBoolean(cfg, "admin.userid.required", arguments.boolValue);
				break;
			case lCase(variables.ADMIN_SECURITY_ENABLED_SETTING):
				writeConfigBoolean(cfg, "admin.security.enabled", arguments.boolValue);
				try {
					var ssSec = getSecurityService();
					ssSec.setAdminSecurityEnabled(arguments.boolValue);
				} catch(any ex){}
				break;
			default:
				throw(message="Unsupported security administrator setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		saveSecurityConfigMap(cfg);
		return getAdministratorSettingFromConfigMap(arguments.settingName);
	}

	// isSecureProfile()/enableSecureProfile()/disableSecureProfile() live on CFIDE.adminapi.security
	// (getSecurityAdminApi()), not the java SecurityService object (ss) used for the rest of Administrator --
	// confirmed by decompiling CFIDE/adminapi/security.cfc's constant pool (funcISSECUREPROFILE/
	// funcENABLESECUREPROFILE/funcDISABLESECUREPROFILE).
	public string function getSecureProfileSetting(required string settingName){
		if(NOT isSecurityServiceAvailable())
			return formatBooleanSettingValue(readConfigBoolean(getSecurityConfigMap(), "secureprofile.enabled"));
		var admin = loginAdmin();
		try {
			return formatBooleanSettingValue(getSecurityAdminApi().isSecureProfile());
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function setSecureProfileSetting(required string settingName, required any settingValue){
		var boolValue = javaCast("boolean", toBoolean(arguments.settingValue));
		if(NOT isSecurityServiceAvailable()){
			var cfg = getSecurityConfigMap();
			writeConfigBoolean(cfg, "secureprofile.enabled", boolValue);
			saveSecurityConfigMap(cfg);
			return getSecureProfileSetting(arguments.settingName);
		}
		var admin = loginAdmin();
		try {
			// Matches what the real Admin UI's Submit Changes button sends: on/off plus an empty
			// exceptions array (no settings excluded from the bundle).
			getSecurityAdminApi().enableSecureProfile(boolValue, []);
			return getSecureProfileSetting(arguments.settingName);
		}
		catch(any e){
			if(findNoCase("set FAILED", e.message))
				return "set FAILED. #e.message# #e.detail#";
			rethrow;
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function getSecuritySetting(required string settingName, string apiArea = "administrator"){
		switch(lCase(trim(arguments.apiArea))){
			case "administrator":
				return getAdministratorSetting(arguments.settingName);
			case "secureprofile":
				return getSecureProfileSetting(arguments.settingName);
			case "rds":
				return getRdsSetting(arguments.settingName);
			case "sandboxsecurity":
				return getSandboxSecuritySetting(arguments.settingName);
			case "usermanager":
				return getUserManagerSetting(arguments.settingName);
			case "allowedipaddresses":
				return getAllowedIpAddressesSetting(arguments.settingName);
			case "idpconfiguration":
				return getIdpConfigurationSetting(arguments.settingName);
			case "spconfiguration":
				return getSpConfigurationSetting(arguments.settingName);
			case "settings":
				return getSettingsSetting(arguments.settingName);
			default:
				throw(message="Unsupported security api area: #arguments.apiArea#", type="CCSTest.ConfigError");
		}
	}

	public string function setSecuritySetting(required string settingName, required any settingValue, string apiArea = "administrator"){
		switch(lCase(trim(arguments.apiArea))){
			case "administrator":
				return setAdministratorSetting(arguments.settingName, arguments.settingValue);
			case "secureprofile":
				return setSecureProfileSetting(arguments.settingName, arguments.settingValue);
			case "rds":
				return setRdsSetting(arguments.settingName, arguments.settingValue);
			case "sandboxsecurity":
				return setSandboxSecuritySetting(arguments.settingName, arguments.settingValue);
			case "usermanager":
				return setUserManagerSetting(arguments.settingName, arguments.settingValue);
			case "allowedipaddresses":
				return setAllowedIpAddressesSetting(arguments.settingName, arguments.settingValue);
			case "idpconfiguration":
				return setIdpConfigurationSetting(arguments.settingName, arguments.settingValue);
			case "spconfiguration":
				return setSpConfigurationSetting(arguments.settingName, arguments.settingValue);
			case "settings":
				return setSettingsSetting(arguments.settingName, arguments.settingValue);
			default:
				throw(message="Unsupported security api area: #arguments.apiArea#", type="CCSTest.ConfigError");
		}
	}

	private any function getUserManagerUtil(){
		return new cfsuite.ccssuite.utils.userManagerConfigUtil().init();
	}

	public string function getUserManagerSetting(required string settingName){
		return getUserManagerUtil().getUserManagerSetting(arguments.settingName);
	}

	public string function setUserManagerSetting(required string settingName, required any settingValue){
		return getUserManagerUtil().setUserManagerSetting(arguments.settingName, arguments.settingValue);
	}

	public string function getNewSetValueForSetting(required string settingName, any currentValue = ""){
		if(isAdministratorSamlFieldSetting(arguments.settingName))
			return getAdministratorSamlNextValue(arguments.settingName, arguments.currentValue);
		if(isUserManagerSetting(arguments.settingName))
			return getUserManagerUtil().getNewSetValueForSetting(arguments.settingName, arguments.currentValue);
		if(isAllowedIpSetting(arguments.settingName))
			return getAllowedIpUtil().getNewSetValueForSetting(arguments.settingName, arguments.currentValue);
		if(isIdpSetting(arguments.settingName))
			return getIdpUtil().getNewSetValueForSetting(arguments.settingName, arguments.currentValue);
		if(isSpSetting(arguments.settingName))
			return getSpUtil().getNewSetValueForSetting(arguments.settingName, arguments.currentValue);
		if(isSettingsSetting(arguments.settingName))
			return getSettingsUtil().getNewSetValueForSetting(arguments.settingName, arguments.currentValue);
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.RDS_SINGLE_PASSWORD_ONLY_SETTING):
				return "true";
			case lCase(variables.RDS_SEPARATE_USER_AUTH_SETTING):
				return "false";
			case lCase(variables.EXTERNAL_AUTH_NONE_SETTING):
				return "None";
			case lCase(variables.EXTERNAL_AUTH_SAML_SETTING):
				return "SAML";
			case lCase(variables.EXTERNAL_AUTH_LDAP_SETTING):
				return "LDAP";
			case lCase(variables.LDAP_HOST_SETTING):
				return (trim("" & arguments.currentValue) EQ "127.0.0.1") ? "localhost" : "127.0.0.1";
			case lCase(variables.LDAP_TCP_PORT_SETTING):
				return (val(arguments.currentValue) EQ 455) ? "457" : "455";
			case lCase(variables.LDAP_USER_BIND_DN_SETTING):
				return (trim("" & arguments.currentValue) EQ "test") ? "test_ccs" : "test";
			case lCase(variables.LDAP_USER_BIND_PASSWORD_SETTING):
				return "ccsTestLdapPass99";
			case lCase(variables.LDAP_USER_BASE_CONTEXT_SETTING):
				return (trim("" & arguments.currentValue) EQ "test") ? "test_ccs" : "test";
			case lCase(variables.LDAP_GROUP_BASE_CONTEXT_SETTING):
				return (trim("" & arguments.currentValue) EQ "test") ? "test_ccs" : "test";
			case lCase(variables.LDAP_TIMEOUT_SETTING):
				return (val(arguments.currentValue) EQ 30) ? "45" : "30";
			case lCase(variables.LDAP_SSL_ENABLED_SETTING):
			case lCase(variables.LDAP_START_TLS_SETTING):
				return toBoolean(arguments.currentValue) ? "false" : "true";
			case lCase(variables.LDAP_USER_CONFIG_SETTING):
			case lCase(variables.LDAP_GROUP_CONFIG_SETTING):
				// Never target a literal empty string here: _setterSecurity.cfm's URL-param dispatcher
				// treats a truly empty setValueTo as "not passed" (confirmed live: "setting setValueTo
				// not passed", HTTP 400) rather than an intentional blank value, so toggle between two
				// concrete values instead.
				return (trim("" & arguments.currentValue) EQ "cn") ? "mail" : "cn";
			case lCase(variables.LDAP_USERNAME_ATTR_SETTING):
				return (trim("" & arguments.currentValue) EQ "admin") ? "admin_ccs" : "admin";
			case lCase(variables.LDAP_GROUPNAME_ATTR_SETTING):
				return (trim("" & arguments.currentValue) EQ "test") ? "test_ccs" : "test";
			case lCase(variables.EXTERNAL_AUTH_SETTING):
				var authValue = normalizeExternalAuthValue(arguments.currentValue);
				if(authValue EQ "NONE")
					return "LDAP";
				return "None";
			case lCase(variables.ROOT_ADMIN_USER_ID_SETTING):
				var userId = trim("" & arguments.currentValue);
				return userId EQ "admin" ? "ccsTestAdmin" : "admin";
			case lCase(variables.ADMIN_OLD_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_CONFIRM_SETTING):
				return "ccsTestAdminPass99";
			case lCase(variables.RDS_OLD_PASSWORD_SETTING):
			case lCase(variables.RDS_NEW_PASSWORD_SETTING):
			case lCase(variables.RDS_NEW_PASSWORD_CONFIRM_SETTING):
				return "ccsTestRdsPass99";
			case lCase(variables.SEED_SETTING):
				return uCase(right(hash(createUUID(), "SHA-256"), 16));
			case lCase(variables.SANDBOX_PATH_SETTING):
				return formatBooleanSettingValue(arguments.currentValue) EQ "true" ? "delete" : "add";
			case lCase(variables.SANDBOX_PATH_COPY_FROM_SETTING):
				return "add";
			default:
				var value = formatBooleanSettingValue(arguments.currentValue);
				return value EQ "true" ? "false" : "true";
		}
	}

	public boolean function isInstanceLocalSecuritySetting(required string settingName){
		var key = lCase(trim(arguments.settingName));
		return findNoCase("password", key) GT 0 OR compareNoCase(key, "seed") EQ 0;
	}

	public boolean function isReadOnlyAdministratorSetting(required string settingName){
		return listFindNoCase(
			variables.EXTERNAL_AUTH_SETTING & "," & variables.ROOT_ADMIN_USER_ID_SETTING,
			trim(arguments.settingName)
		) GT 0;
	}

	public boolean function scalarValuesMatch(required any expectedValue, required any actualValue, string settingName = ""){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		if(compareNoCase(arguments.settingName, "AdminSamlTestState") EQ 0){
			if(NOT isJSON(arguments.actualValue))
				return false;
			var actualState = deserializeJSON(arguments.actualValue);
			if(compareNoCase(trim("" & arguments.expectedValue), "prepare") EQ 0){
				try {
					assertAdministratorSamlPrerequisites(actualState);
					return arrayFindNoCase(actualState.idpNames, "ccsTestIdpDef") GT 0
						AND arrayFindNoCase(actualState.idpNames, "ccsTestIdpXml") GT 0
						AND arrayFindNoCase(actualState.spNames, "ccsTestSpAdd") GT 0
						AND arrayFindNoCase(actualState.spNames, "ccsTestSpGen") GT 0;
				}
				catch(any exception){ return false; }
			}
			return isJSON(arguments.expectedValue) AND administratorSamlStatesMatch(deserializeJSON(arguments.expectedValue), actualState);
		}
		if(isAdministratorSamlFieldSetting(arguments.settingName))
			return compare(trim("" & arguments.expectedValue), trim("" & arguments.actualValue)) EQ 0;
		if(isUserManagerSetting(arguments.settingName))
			return getUserManagerUtil().scalarValuesMatch(arguments.expectedValue, arguments.actualValue, arguments.settingName);
		if(isAllowedIpSetting(arguments.settingName))
			return getAllowedIpUtil().allowedIpValuesMatch(arguments.expectedValue, arguments.actualValue, arguments.settingName);
		if(isIdpSetting(arguments.settingName))
			return getIdpUtil().idpValuesMatch(arguments.expectedValue, arguments.actualValue, arguments.settingName);
		if(isSpSetting(arguments.settingName))
			return getSpUtil().spValuesMatch(arguments.expectedValue, arguments.actualValue, arguments.settingName);
		if(isSettingsSetting(arguments.settingName))
			return getSettingsUtil().settingsValuesMatch(arguments.expectedValue, arguments.actualValue, arguments.settingName);
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.EXTERNAL_AUTH_SETTING):
			case lCase(variables.EXTERNAL_AUTH_NONE_SETTING):
			case lCase(variables.EXTERNAL_AUTH_SAML_SETTING):
			case lCase(variables.EXTERNAL_AUTH_LDAP_SETTING):
				return normalizeExternalAuthValue(arguments.expectedValue) EQ normalizeExternalAuthValue(arguments.actualValue);
			case lCase(variables.LDAP_USER_BIND_PASSWORD_SETTING):
				// Same leniency as Solr's password (see testDriver.syncedFramesMatch): auto-encrypted on
				// write, so exact match against the plaintext we requested isn't meaningful.
				if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
					return false;
				return len(trim("" & arguments.actualValue)) GT 0;
			case lCase(variables.LDAP_HOST_SETTING):
			case lCase(variables.LDAP_TCP_PORT_SETTING):
			case lCase(variables.LDAP_USER_BIND_DN_SETTING):
			case lCase(variables.LDAP_USER_BASE_CONTEXT_SETTING):
			case lCase(variables.LDAP_GROUP_BASE_CONTEXT_SETTING):
			case lCase(variables.LDAP_USER_CONFIG_SETTING):
			case lCase(variables.LDAP_USERNAME_ATTR_SETTING):
			case lCase(variables.LDAP_GROUP_CONFIG_SETTING):
			case lCase(variables.LDAP_GROUPNAME_ATTR_SETTING):
				return trim("" & arguments.expectedValue) EQ trim("" & arguments.actualValue);
			case lCase(variables.LDAP_TIMEOUT_SETTING):
				return val(arguments.expectedValue) EQ val(arguments.actualValue);
			case lCase(variables.LDAP_SSL_ENABLED_SETTING):
			case lCase(variables.LDAP_START_TLS_SETTING):
				return formatBooleanSettingValue(arguments.expectedValue) EQ formatBooleanSettingValue(arguments.actualValue);
			case lCase(variables.ROOT_ADMIN_USER_ID_SETTING):
				return lCase(trim("" & arguments.expectedValue)) EQ lCase(trim("" & arguments.actualValue));
			case lCase(variables.ADMIN_OLD_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_CONFIRM_SETTING):
				return trim("" & arguments.expectedValue) EQ trim("" & arguments.actualValue);
			case lCase(variables.RDS_OLD_PASSWORD_SETTING):
			case lCase(variables.RDS_NEW_PASSWORD_SETTING):
			case lCase(variables.RDS_NEW_PASSWORD_CONFIRM_SETTING):
				return trim("" & arguments.expectedValue) EQ trim("" & arguments.actualValue);
			case lCase(variables.SEED_SETTING):
				var actualSeedText = trim("" & arguments.actualValue);
				if(findNoCase("set FAILED", actualSeedText)){
					// CF rejected the seed change (encrypted passwords prevent rotation) --
					// extract the read-back value; if it is non-empty the seed is still configured.
					var readBack = reReplace(actualSeedText, ".*read back:\s*([A-F0-9]+).*", "\1", "one");
					return len(trim(readBack)) GT 0;
				}
				var expectedSeed = uCase(trim("" & arguments.expectedValue));
				var actualSeed = uCase(actualSeedText);
				if(expectedSeed EQ actualSeed)
					return true;
				if(len(expectedSeed) AND len(actualSeed)){
					var derivedSeed = uCase(left(hash(arguments.expectedValue, "SHA-256"), 16));
					if(derivedSeed EQ actualSeed)
						return true;
				}
				return false;
			default:
				return formatBooleanSettingValue(arguments.expectedValue) EQ formatBooleanSettingValue(arguments.actualValue);
		}
	}

	public string function formatDisplayValue(required string settingName, required any value){
		if(compareNoCase(arguments.settingName, "AdminSamlTestState") EQ 0)
			return "(Administrator authentication state)";
		if(isUserManagerSetting(arguments.settingName))
			return getUserManagerUtil().formatDisplayValue(arguments.settingName, arguments.value);
		if(isAllowedIpSetting(arguments.settingName))
			return getAllowedIpUtil().formatDisplayValue(arguments.settingName, arguments.value);
		if(isIdpSetting(arguments.settingName))
			return getIdpUtil().formatDisplayValue(arguments.settingName, arguments.value);
		if(isSpSetting(arguments.settingName))
			return getSpUtil().formatDisplayValue(arguments.settingName, arguments.value);
		if(isSettingsSetting(arguments.settingName))
			return getSettingsUtil().formatDisplayValue(arguments.settingName, arguments.value);
		if(isLdapConfigBooleanFieldSetting(arguments.settingName))
			return formatBooleanSettingValue(arguments.value) EQ "true" ? "Enabled" : "Disabled";
		if(isLdapConfigFieldSetting(arguments.settingName) OR isAdministratorSamlFieldSetting(arguments.settingName)){
			// formatBooleanSettingValue() below calls toBoolean(), which throws on plain strings like
			// "127.0.0.1" or "test" -- these fields are never boolean, so return before reaching it.
			var text = trim("" & arguments.value);
			if(compareNoCase(arguments.settingName, variables.LDAP_USER_BIND_PASSWORD_SETTING) EQ 0){
				if(NOT len(text) OR text EQ "password")
					return "(empty)";
			}
			return len(text) ? text : "(empty)";
		}
		var boolText = formatBooleanSettingValue(arguments.value);
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.ALLOW_CONCURRENT_ADMIN_LOGIN_SETTING):
				return boolText EQ "true" ? "Enabled" : "Disabled";
			case lCase(variables.ADMIN_USER_ID_REQUIRED_SETTING):
				return boolText;
			case lCase(variables.ADMIN_SECURITY_ENABLED_SETTING):
				return boolText EQ "true" ? "Enabled" : "Disabled";
			case lCase(variables.SECURE_PROFILE_ENABLED_SETTING):
				return boolText EQ "true" ? "Enabled" : "Disabled";
			case lCase(variables.EXTERNAL_AUTH_SETTING):
			case lCase(variables.EXTERNAL_AUTH_NONE_SETTING):
			case lCase(variables.EXTERNAL_AUTH_SAML_SETTING):
			case lCase(variables.EXTERNAL_AUTH_LDAP_SETTING):
				return formatExternalAuthDisplay(arguments.value);
			case lCase(variables.ROOT_ADMIN_USER_ID_SETTING):
				var userId = trim("" & arguments.value);
				return len(userId) ? userId : "(empty)";
			case lCase(variables.ADMIN_OLD_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_SETTING):
			case lCase(variables.ADMIN_NEW_PASSWORD_CONFIRM_SETTING):
			case lCase(variables.RDS_OLD_PASSWORD_SETTING):
			case lCase(variables.RDS_NEW_PASSWORD_SETTING):
			case lCase(variables.RDS_NEW_PASSWORD_CONFIRM_SETTING):
				var pwdVal = trim("" & arguments.value);
				if(NOT len(pwdVal) OR pwdVal EQ "password")
					return "(empty)";
				return pwdVal;
			case lCase(variables.SEED_SETTING):
				return len(trim("" & arguments.value)) ? trim("" & arguments.value) : "(empty)";
			case lCase(variables.RDS_ENABLED_SETTING):
				return boolText EQ "true" ? "Enabled" : "Disabled";
			case lCase(variables.RDS_SECURITY_ENABLED_SETTING):
				return boolText EQ "true" ? "Enabled" : "Disabled";
			case lCase(variables.USE_SINGLE_RDS_PASSWORD_SETTING):
			case lCase(variables.RDS_SINGLE_PASSWORD_ONLY_SETTING):
			case lCase(variables.RDS_SEPARATE_USER_AUTH_SETTING):
				return boolText EQ "true" ? "Use a single password only (default)" : "Separate user name and password authentication (allows multiple users)";
			case lCase(variables.SANDBOX_SECURITY_ENABLED_SETTING):
				return boolText EQ "true" ? "Enabled" : "Disabled";
			case lCase(variables.SANDBOX_PATH_SETTING):
				return boolText EQ "true" ? getConfiguredTestSandboxPathDisplay() : "(none)";
			case lCase(variables.SANDBOX_PATH_COPY_FROM_SETTING):
				return boolText EQ "true" ? getTestSandboxCopyPath() : "(none)";
			default:
				return boolText;
		}
	}

	private boolean function isAllowedIpSetting(required string settingName){
		return getAllowedIpUtil().isAllowedIpSetting(arguments.settingName);
	}

	private boolean function isUserManagerSetting(required string settingName){
		return listFindNoCase(
			"UserExists,UserDescription,AllowRdsAccess,AllowAdminAccess,EnabledDataSource,UserRole,SecuredFilePath,IsGroup,UserPassword,UserPasswordConfirm,UserExternal,UserTypeLdap,UserTypeSaml,UserAdminConsoleAndApi,UserApiAccessOnly,UserProhibitedRole,UserProhibitedDataSource,UserFileRead,UserFileWrite,UserFileExecute,UserFileDelete",
			trim(arguments.settingName)
		) GT 0;
	}

	public boolean function allowedIpValuesMatch(required any requestedValue, required any actualValue, required string settingName){
		return getAllowedIpUtil().allowedIpValuesMatch(arguments.requestedValue, arguments.actualValue, arguments.settingName);
	}

	public struct function readSecurityConfigMapPublic(){
		return getSecurityConfigMap();
	}

	public void function writeSecurityConfigMapPublic(required struct configMap){
		saveSecurityConfigMap(arguments.configMap);
	}

	public string function findSecurityConfigKeyPublic(required struct data, required string key){
		return findStructKey(arguments.data, arguments.key);
	}

	private any function getAllowedIpUtil(){
		return new cfsuite.ccssuite.utils.allowedIpAddressesConfigUtil().init();
	}

	public string function getAllowedIpAddressesSetting(required string settingName){
		return getAllowedIpUtil().getAllowedIpAddressesSetting(arguments.settingName);
	}

	public string function setAllowedIpAddressesSetting(required string settingName, required any settingValue){
		return getAllowedIpUtil().setAllowedIpAddressesSetting(arguments.settingName, arguments.settingValue);
	}

	private any function getIdpUtil(){
		return new cfsuite.ccssuite.utils.idpConfigUtil().init();
	}

	private boolean function isIdpSetting(required string settingName){
		return getIdpUtil().isIdpSetting(arguments.settingName);
	}

	public boolean function idpValuesMatch(required any requestedValue, required any actualValue, required string settingName){
		return getIdpUtil().idpValuesMatch(arguments.requestedValue, arguments.actualValue, arguments.settingName);
	}

	public string function getIdpConfigurationSetting(required string settingName){
		return getIdpUtil().getIdpConfigurationSetting(arguments.settingName);
	}

	public string function setIdpConfigurationSetting(required string settingName, required any settingValue){
		return getIdpUtil().setIdpConfigurationSetting(arguments.settingName, arguments.settingValue);
	}

	private any function getSpUtil(){
		return new cfsuite.ccssuite.utils.spConfigUtil().init();
	}

	private boolean function isSpSetting(required string settingName){
		return getSpUtil().isSpSetting(arguments.settingName);
	}

	public boolean function spValuesMatch(required any requestedValue, required any actualValue, required string settingName){
		return getSpUtil().spValuesMatch(arguments.requestedValue, arguments.actualValue, arguments.settingName);
	}

	public string function getSpConfigurationSetting(required string settingName){
		return getSpUtil().getSpConfigurationSetting(arguments.settingName);
	}

	public string function setSpConfigurationSetting(required string settingName, required any settingValue){
		return getSpUtil().setSpConfigurationSetting(arguments.settingName, arguments.settingValue);
	}

	private any function getSettingsUtil(){
		return new cfsuite.ccssuite.utils.securitySettingsConfigUtil().init();
	}

	private boolean function isSettingsSetting(required string settingName){
		return getSettingsUtil().isSettingsSetting(arguments.settingName);
	}

	public boolean function settingsValuesMatch(required any requestedValue, required any actualValue, required string settingName){
		return getSettingsUtil().settingsValuesMatch(arguments.requestedValue, arguments.actualValue, arguments.settingName);
	}

	public string function getSettingsSetting(required string settingName){
		return getSettingsUtil().getSettingsSetting(arguments.settingName);
	}

	public string function setSettingsSetting(required string settingName, required any settingValue){
		return getSettingsUtil().setSettingsSetting(arguments.settingName, arguments.settingValue);
	}

	/**
	* Flips the live ExternalAuth type via the underlying Java SecurityService. Confirmed by reflection
	* (coldfusion.server.SecurityService.setExternalAuth(String, coldfusion.runtime.Struct)) that this method
	* exists and works even though CFIDE.adminapi.security doesn't expose it and the CF2025 Admin UI's own
	* "Edit LDAP Configuration" dialog manages LDAP connection details separately via
	* setAdminLdapConfiguration() -- so switching to LDAP here only flips the active auth type and relies on
	* whatever LDAP config is already stored, exactly like the real admin UI's radio button does. SAML needs an
	* actual idp/sp pairing, so it reuses whichever SamlConfig (idpName/spName/groupName) is already configured
	* rather than fabricating one.
	*/
	private void function setExternalAuthType(required any ss, required any authTypeValue){
		switch(normalizeExternalAuthValue(arguments.authTypeValue)){
			case "SAML":
				// getAdminSamlConfig() comes back as a Map implementation the Java overload resolver
				// won't accept as the declared coldfusion.runtime.Struct parameter (confirmed live:
				// passing it straight through fails with "setExternalAuth method was not found").
				// structNew() -- used as-is for the LDAP/None cases below -- IS accepted, so copy the
				// fetched config into a fresh one instead of passing the getter's return value directly.
				var samlSrc = arguments.ss.getAdminSamlConfig();
				var samlCfg = structNew();
				for(var key in samlSrc)
					samlCfg[key] = samlSrc[key];
				arguments.ss.setExternalAuth("SAML", samlCfg);
				break;
			case "LDAP":
				arguments.ss.setExternalAuth("LDAP", structNew());
				break;
			default:
				arguments.ss.setExternalAuth("None", structNew());
		}
	}

	public boolean function isAdministratorSamlFieldSetting(required string settingName){
		return listFindNoCase(variables.ADMIN_SAML_IDP_SETTING & "," & variables.ADMIN_SAML_SP_SETTING & "," & variables.ADMIN_SAML_GROUP_SETTING,
			trim(arguments.settingName)) GT 0;
	}

	public struct function getAdministratorSamlPrerequisites(){
		var ss = getSecurityService();
		return {
			authType = normalizeExternalAuthValue(ss.getExternalAuth()),
			config = getAdminSamlConfigStruct(ss),
			idpNames = getIdpUtil().getConfiguredAliases(),
			spNames = getSpUtil().getConfiguredAliases()
		};
	}

	private void function prepareAdministratorSamlTest(required any ss){
		var idpUtil = getIdpUtil();
		var spUtil = getSpUtil();
		idpUtil.addTestIdpForSetting("IdpFromSamlDefinition");
		idpUtil.addTestIdpForSetting("IdpFromXmlFile");
		spUtil.addTestSpForSetting("SpAdd");
		spUtil.addTestSpForSetting("SpGenerate");
		var config = buildAdministratorSamlTestConfig(getAdministratorSamlPrerequisites());
		var admin = loginAdmin();
		try {
			arguments.ss.setExternalAuth("SAML", config);
		}
		finally { logoutAdmin(admin); }
	}

	private void function restoreAdministratorSamlState(required any ss, required struct originalState){
		if(NOT structKeyExists(arguments.originalState, "authType") OR NOT structKeyExists(arguments.originalState, "config")
			OR NOT isStruct(arguments.originalState.config) OR NOT structKeyExists(arguments.originalState, "idpNames")
			OR NOT isArray(arguments.originalState.idpNames) OR NOT structKeyExists(arguments.originalState, "spNames")
			OR NOT isArray(arguments.originalState.spNames) OR NOT listFindNoCase("NONE,LDAP,SAML", arguments.originalState.authType))
			throw(message="Invalid Administrator authentication snapshot", type="CCSTest.ConfigError");
		if(NOT structIsEmpty(arguments.originalState.config))
			arguments.ss.setExternalAuth("SAML", arguments.originalState.config);
		if(normalizeExternalAuthValue(arguments.originalState.authType) NEQ "SAML")
			arguments.ss.setExternalAuth(normalizeExternalAuthValue(arguments.originalState.authType) EQ "LDAP" ? "LDAP" : "None", structNew());
		if(structIsEmpty(arguments.originalState.config))
			arguments.ss.deleteAdminSamlConfig();
		for(var alias in ["ccsTestIdpDef", "ccsTestIdpXml"]){
			if(NOT arrayFindNoCase(arguments.originalState.idpNames, alias))
				getIdpUtil().removeTestIdp(alias);
		}
		for(var alias in ["ccsTestSpAdd", "ccsTestSpGen"]){
			if(NOT arrayFindNoCase(arguments.originalState.spNames, alias))
				getSpUtil().removeTestSp(alias);
		}
	}

	public boolean function administratorSamlStatesMatch(required struct expectedState, required struct actualState){
		if(normalizeExternalAuthValue(arguments.expectedState.authType) NEQ normalizeExternalAuthValue(arguments.actualState.authType)
			OR structCount(arguments.expectedState.config) NEQ structCount(arguments.actualState.config))
			return false;
		for(var key in arguments.expectedState.config){
			if(NOT structKeyExists(arguments.actualState.config, key)
				OR compare(serializeJSON(arguments.expectedState.config[key]), serializeJSON(arguments.actualState.config[key])) NEQ 0)
				return false;
		}
		for(var field in ["idpNames", "spNames"]){
			var expectedAliases = duplicate(arguments.expectedState[field]);
			var actualAliases = duplicate(arguments.actualState[field]);
			arraySort(expectedAliases, "textnocase");
			arraySort(actualAliases, "textnocase");
			if(compare(serializeJSON(expectedAliases), serializeJSON(actualAliases)) NEQ 0)
				return false;
		}
		return true;
	}

	public struct function buildAdministratorSamlTestConfig(required struct prerequisites){
		var config = duplicate(arguments.prerequisites.config);
		for(var fieldKey in ["idpName", "spName"]){
			var providers = duplicate(arguments.prerequisites[fieldKey & "s"]);
			arraySort(providers, "textnocase");
			if(NOT arrayLen(providers))
				throw(message="Administrator SAML test setup requires a configured #fieldKey#", type="CCSTest.PrerequisiteMissing");
			if(NOT structKeyExists(config, fieldKey) OR NOT arrayFindNoCase(providers, config[fieldKey]))
				config[fieldKey] = providers[1];
		}
		if(NOT structKeyExists(config, "groupName") OR NOT len(trim("" & config.groupName)))
			config.groupName = "ccssuite_admin_group";
		return config;
	}

	public void function assertAdministratorSamlPrerequisites(required struct prerequisites){
		var ready = arguments.prerequisites.authType EQ "SAML";
		for(var key in ["idpName", "spName", "groupName"])
			ready = ready AND structKeyExists(arguments.prerequisites.config, key)
				AND len(trim("" & arguments.prerequisites.config[key])) GT 0;
		if(ready)
			ready = arrayFindNoCase(arguments.prerequisites.idpNames, arguments.prerequisites.config.idpName) GT 0
				AND arrayFindNoCase(arguments.prerequisites.spNames, arguments.prerequisites.config.spName) GT 0;
		if(NOT ready)
			throw(message="Administrator SAML test setup is incomplete: the temporary SAML pairing and provider definitions must be prepared before field writes.",
				type="CCSTest.PrerequisiteMissing");
	}

	public string function getAdministratorSamlNextValue(required string settingName, required any currentValue, array providerNames){
		if(arguments.settingName EQ variables.ADMIN_SAML_GROUP_SETTING)
			return compare(trim("" & arguments.currentValue), "ccssuite_admin_group") EQ 0 ? "ccssuite_admin_group_updated" : "ccssuite_admin_group";
		var fieldKey = getAdminSamlFieldKey(arguments.settingName);
		var providers = structKeyExists(arguments, "providerNames") ? arguments.providerNames
			: getAdministratorSamlPrerequisites()[fieldKey & "s"];
		arraySort(providers, "textnocase");
		for(var provider in providers){
			if(compareNoCase(provider, trim("" & arguments.currentValue)) NEQ 0)
				return provider;
		}
		throw(message="Administrator SAML test prerequisite missing: a second existing #fieldKey# shared by participating nodes is required. No provider was created.", type="CCSTest.PrerequisiteMissing");
	}

	private struct function getAdminSamlConfigStruct(required any ss){
		var result = {};
		try {
			var source = arguments.ss.getAdminSamlConfig();
			for(var key in source)
				result[key] = source[key];
		}
		catch(any exception){
			if(NOT findNoCase("Saml Configuration have no value", exception.message))
				rethrow;
		}
		return result;
	}

	private string function getAdminSamlFieldKey(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.ADMIN_SAML_IDP_SETTING): return "idpName";
			case lCase(variables.ADMIN_SAML_SP_SETTING): return "spName";
			case lCase(variables.ADMIN_SAML_GROUP_SETTING): return "groupName";
		}
		throw(message="Unsupported Administrator SAML field: #arguments.settingName#", type="CCSTest.ConfigError");
	}

	public boolean function isLdapConfigFieldSetting(required string settingName){
		return listFindNoCase(
			variables.LDAP_HOST_SETTING & "," & variables.LDAP_TCP_PORT_SETTING & "," & variables.LDAP_USER_BIND_DN_SETTING & "," &
				variables.LDAP_USER_BIND_PASSWORD_SETTING & "," & variables.LDAP_USER_BASE_CONTEXT_SETTING & "," & variables.LDAP_GROUP_BASE_CONTEXT_SETTING & "," &
				variables.LDAP_TIMEOUT_SETTING & "," & variables.LDAP_SSL_ENABLED_SETTING & "," & variables.LDAP_START_TLS_SETTING & "," &
				variables.LDAP_USER_CONFIG_SETTING & "," & variables.LDAP_USERNAME_ATTR_SETTING & "," & variables.LDAP_GROUP_CONFIG_SETTING & "," &
				variables.LDAP_GROUPNAME_ATTR_SETTING,
			trim(arguments.settingName)
		) GT 0;
	}

	private boolean function isLdapConfigBooleanFieldSetting(required string settingName){
		return listFindNoCase(
			variables.LDAP_SSL_ENABLED_SETTING & "," & variables.LDAP_START_TLS_SETTING,
			trim(arguments.settingName)
		) GT 0;
	}

	// Maps each pseudo setting name to the real key in getAdminLdapConfiguration()'s returned struct.
	private string function getLdapConfigFieldKey(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.LDAP_HOST_SETTING): return "host";
			case lCase(variables.LDAP_TCP_PORT_SETTING): return "tcpPort";
			case lCase(variables.LDAP_USER_BIND_DN_SETTING): return "userbindDN";
			case lCase(variables.LDAP_USER_BIND_PASSWORD_SETTING): return "password";
			case lCase(variables.LDAP_USER_BASE_CONTEXT_SETTING): return "userBaseContext";
			case lCase(variables.LDAP_GROUP_BASE_CONTEXT_SETTING): return "groupBaseContext";
			case lCase(variables.LDAP_TIMEOUT_SETTING): return "timeout";
			case lCase(variables.LDAP_SSL_ENABLED_SETTING): return "isSSLEnabled";
			case lCase(variables.LDAP_START_TLS_SETTING): return "isStartTLSEnabled";
			case lCase(variables.LDAP_USER_CONFIG_SETTING): return "userConfig";
			case lCase(variables.LDAP_USERNAME_ATTR_SETTING): return "usernameAttr";
			case lCase(variables.LDAP_GROUP_CONFIG_SETTING): return "groupConfig";
			case lCase(variables.LDAP_GROUPNAME_ATTR_SETTING): return "groupnameAttr";
			default: throw(message="Unsupported LDAP config field setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	/**
	* Explicit setup for disposable test instances only; never called by field regression tests.
	* Preserve existing LDAP data and the active authentication type. Placeholder data is not
	* a working LDAP connection, and initialization is intentionally not field-level rollback.
	*/
	public boolean function initializeLdapTestConfiguration(required boolean confirmedDisposable){
		if(NOT arguments.confirmedDisposable)
			throw(message="LDAP test setup requires a confirmed disposable instance.", type="CCSTest.ConfigError");
		if(NOT isSecurityServiceAvailable())
			throw(message="LDAP test setup requires access to the ColdFusion SecurityService.", type="CCSTest.ConfigError");
		var admin = loginAdmin();
		try {
			var ss = getSecurityService();
			try {
				getLdapConfigStruct(ss);
				return false;
			}
			catch(CCSTest.LdapConfigurationMissing missingConfiguration){
				// Initialize only the absent configuration, using the suite's placeholder
				// conventions and confirmed 13-argument order. Do not enable LDAP auth.
				ss.setAdminLdapConfiguration(
					"127.0.0.1", "455", "test", "test", "test", "ccsTestLdapPass99",
					javaCast("boolean", false), javaCast("boolean", false),
					"cn", "admin", "cn", "test", "30"
				);
				var initializedConfig = getLdapConfigStruct(ss);
				if(NOT structKeyExists(initializedConfig, "host") OR initializedConfig.host NEQ "127.0.0.1")
					throw(message="LDAP test configuration initialization could not be verified.", type="CCSTest.ConfigError");
				return true;
			}
		}
		finally {
			logoutAdmin(admin);
		}
	}

	// getAdminLdapConfiguration()'s return isn't compatible with CFML dot/bracket struct access reliably
	// (confirmed live: baseline.host threw "Element HOST is undefined"), so copy it into a plain CFML
	// struct via for-in before reading any field from it.
	private struct function getLdapConfigStruct(required any ss){
		var raw = {};
		try {
			raw = arguments.ss.getAdminLdapConfiguration();
		}
		catch(any e){
			// An unconfigured LDAP service is not an empty field baseline. Do not create
			// defaults here: field-level rollback cannot restore an absent configuration.
			if(findNoCase("Ldap Configuration have no value", e.message)){
				throw(
					message="Administrator LDAP configuration is not initialized on this instance.",
					detail="On disposable test instances, configure and save the full LDAP configuration in ColdFusion Administrator > Security > Administrator before running LDAP field sync tests. Verify the configuration is readable on each required cluster node. Do not change the active authentication type just to run a field test.",
					type="CCSTest.LdapConfigurationMissing"
				);
			}
			rethrow;
		}
		var cfg = structNew();
		for(var key in raw)
			cfg[key] = raw[key];
		return cfg;
	}

	// Writes the full 13-field LDAP config back via the confirmed positional order. Always reads the
	// current config first and only overwrites the ONE targeted field, so the other 12 (including the
	// bind password, which cannot be round-tripped -- see LDAP_USER_BIND_PASSWORD_SETTING notes above)
	// are preserved exactly as they were.
	// BUG THIS ONCE HAD (fixed, kept as a warning): the password slot is auto-encrypted on every write --
	// whatever is passed in gets freshly encrypted, even if it's already ciphertext. The original version of
	// this function read the CURRENT (already-encrypted) password back from getLdapConfigStruct() and passed
	// it straight through for every non-password field test, "to preserve it" -- which instead re-encrypted
	// the ciphertext on top of itself on every single call. After dozens of test runs across 12 fields today,
	// that compounded neo-security.xml's password blob to 75MB and made the shared admin console
	// progressively slower until it started timing out. Fixed by NEVER round-tripping the stored password:
	// pass a fixed constant placeholder for every field except the password test itself, so the ciphertext
	// length stays bounded/constant no matter how many times any other field is exercised.
	private void function setLdapConfigField(required any ss, required string settingName, required any newValue){
		var cfg = getLdapConfigStruct(arguments.ss);
		var targetKey = getLdapConfigFieldKey(arguments.settingName);
		cfg[targetKey] = arguments.newValue;
		if(targetKey NEQ "password")
			cfg.password = "ccsTestLdapPass99";
		arguments.ss.setAdminLdapConfiguration(
			cfg.host, cfg.tcpPort, cfg.userBaseContext, cfg.groupBaseContext, cfg.userbindDN, cfg.password,
			javaCast("boolean", cfg.isSSLEnabled), javaCast("boolean", cfg.isStartTLSEnabled),
			cfg.userConfig, cfg.usernameAttr, cfg.groupConfig, cfg.groupnameAttr, cfg.timeout
		);
	}

	private string function normalizeExternalAuthValue(required any value){
		var text = lCase(trim("" & arguments.value));
		if(text EQ "none" OR NOT len(text))
			return "None";
		if(text EQ "ldap")
			return "LDAP";
		if(text EQ "saml")
			return "SAML";
		return trim("" & arguments.value);
	}

	private string function formatExternalAuthDisplay(required any value){
		switch(normalizeExternalAuthValue(arguments.value)){
			case "None":
				return "None";
			case "LDAP":
				return "LDAP";
			case "SAML":
				return "SAML";
			default:
				return trim("" & arguments.value);
		}
	}

}
