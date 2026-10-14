/**
* Read/write ColdFusion Administrator Security > User Manager settings.
*/
component output="false" {

	variables.TEST_USER = "ccsTestUserMgr";
	variables.TEST_PASS = "CcsTestPass123!";
	variables.TEST_ROLE = "AI Services > LLMs";
	variables.TEST_DATASOURCE = "cfbookclub";
	variables.TEST_DESCRIPTION = "CCS User Manager sync test";
	variables.TEST_FILE_DIR = "_ccsUserTest";
	variables.USER_EXISTS_SETTING = "UserExists";
	variables.USER_DESCRIPTION_SETTING = "UserDescription";
	variables.ALLOW_RDS_ACCESS_SETTING = "AllowRdsAccess";
	variables.ALLOW_ADMIN_ACCESS_SETTING = "AllowAdminAccess";
	variables.ENABLED_DATA_SOURCE_SETTING = "EnabledDataSource";
	variables.USER_ROLE_SETTING = "UserRole";
	variables.SECURED_FILE_PATH_SETTING = "SecuredFilePath";
	// "Group" checkbox on the Add/Edit User form. Confirmed live this round-trips through
	// setUser(isGroup=...)/getUser().ISGROUP as a plain flag with no LDAP/SAML config required -- unlike
	// isLdap/isSaml, which threw an unrecoverable error when set without a real external identity source
	// (see i.cfm's exclusion table), isGroup is genuinely independent and testable on its own.
	variables.IS_GROUP_SETTING = "IsGroup";

	public function init(){
		variables.componentVersion = 1;
		return this;
	}

	private any function getSecUtil(){
		return new cfsuite.ccssuite.utils.securityConfigUtil().init();
	}

	public string function getTestUsername(){
		return variables.TEST_USER;
	}

	public string function getTestPassword(){
		return variables.TEST_PASS;
	}

	public string function getTestSecuredFilePath(){
		return replace(server.coldfusion.rootdir, "/", "\", "all")
			& "\wwwroot\cfsuite\ccssuite\testsuite\security\userManager\"
			& variables.TEST_FILE_DIR & "\-";
	}

	private boolean function toBoolean(required any value){
		if(isBoolean(arguments.value))
			return arguments.value;
		var text = lCase(trim("" & arguments.value));
		return listFindNoCase("true,yes,1", text) GT 0;
	}

	public string function formatBooleanSettingValue(required any value){
		return toBoolean(arguments.value) ? "true" : "false";
	}

	public void function ensureUserManagerPrerequisites(){
		var secUtil = getSecUtil();
		if(secUtil.getAdministratorSetting("AdminUserIdRequired") NEQ "true")
			secUtil.setAdministratorSetting("AdminUserIdRequired", true);
		ensureTestDatasourceRegistered();
	}

	// EnabledDataSource grants variables.TEST_DATASOURCE on the test user via setUser(enabledds=[...]) --
	// confirmed live that CF silently drops any name in that array that isn't a registered datasource
	// (no error, just never lands), instead of throwing. This dev environment ships with ZERO datasources
	// configured (neo-datasource.xml starts empty), so register a throwaway embedded Derby datasource
	// once per node -- no external DB server needed, and nothing here ever actually connects to it, it
	// only needs to exist by name for the grant to stick.
	private void function ensureTestDatasourceRegistered(){
		if(structKeyExists(request, "ccsTestDatasourceReady") AND request.ccsTestDatasourceReady)
			return;
		var admin = loginAdmin();
		try {
			var ds = createObject("component", "CFIDE.adminapi.datasource");
			if(NOT structKeyExists(ds.getDatasources(), variables.TEST_DATASOURCE)){
				var dbPath = replace(server.coldfusion.rootdir, "/", "\", "all") & "\db\" & variables.TEST_DATASOURCE;
				ds.setDerbyEmbedded(name=variables.TEST_DATASOURCE, database=dbPath);
			}
		}
		finally {
			logoutAdmin(admin);
		}
		request.ccsTestDatasourceReady = true;
	}

	public boolean function testUserExists(){
		var admin = loginAdmin();
		try {
			getSecurityAdminApi().getUser(variables.TEST_USER);
			return true;
		}
		catch(any e){
			return false;
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public void function ensureTestUserAbsent(){
		if(NOT testUserExists())
			return;
		deleteTestUserInternal();
	}

	public void function ensureTestUserPresent(){
		ensureUserManagerPrerequisites();
		if(testUserExists())
			return;
		applyUserSnapshot(buildBaselineSnapshot());
	}

	private struct function buildBaselineSnapshot(){
		return {
			username = variables.TEST_USER,
			password = variables.TEST_PASS,
			description = "",
			roles = [],
			disabledroles = [],
			enabledds = [],
			allowrdsaccess = false,
			allowadminaccess = false,
			allowadminapiaccess = false,
			securedFilePath = false,
			isgroup = false
		};
	}

	private struct function readUserSnapshot(){
		if(NOT testUserExists())
			return buildBaselineSnapshot();
		var admin = loginAdmin();
		try {
			var user = getSecurityAdminApi().getUser(variables.TEST_USER);
			var snapshot = {
				username = variables.TEST_USER,
				password = variables.TEST_PASS,
				description = structKeyExists(user, "DESCRIPTION") ? trim("" & user.DESCRIPTION) : "",
				roles = filterCustomRoles(structKeyExists(user, "ROLES") AND isArray(user.ROLES) ? duplicate(user.ROLES) : []),
				disabledroles = [],
				enabledds = structKeyExists(user, "ENABLEDDS") AND isArray(user.ENABLEDDS) ? duplicate(user.ENABLEDDS) : [],
				allowrdsaccess = rolePresent(user, "coldfusion.rds"),
				allowadminaccess = rolePresent(user, "coldfusion.administrator"),
				allowadminapiaccess = rolePresent(user, "coldfusion.adminapi"),
				securedFilePath = isSecuredFilePathPresentInNeo(),
				isgroup = structKeyExists(user, "ISGROUP") ? user.ISGROUP : false
			};
			return snapshot;
		}
		finally {
			logoutAdmin(admin);
		}
	}

	private boolean function rolePresent(required struct user, required string roleName){
		if(NOT structKeyExists(arguments.user, "ROLES") OR NOT isArray(arguments.user.ROLES))
			return false;
		return arrayFindNoCase(arguments.user.ROLES, arguments.roleName) GT 0;
	}

	private void function applyUserSnapshot(required struct snapshot, boolean manageSecuredFilePathInNeo = false){
		ensureUserManagerPrerequisites();
		var admin = loginAdmin();
		try {
			var sec = getSecurityAdminApi();
			var args = {
				username = variables.TEST_USER,
				password = variables.TEST_PASS,
				description = structKeyExists(arguments.snapshot, "description") ? arguments.snapshot.description : "",
				roles = structKeyExists(arguments.snapshot, "roles") AND isArray(arguments.snapshot.roles) ? arguments.snapshot.roles : [],
				disabledroles = structKeyExists(arguments.snapshot, "disabledroles") AND isArray(arguments.snapshot.disabledroles) ? arguments.snapshot.disabledroles : [],
				enabledds = structKeyExists(arguments.snapshot, "enabledds") AND isArray(arguments.snapshot.enabledds) ? arguments.snapshot.enabledds : [],
				allowrdsaccess = structKeyExists(arguments.snapshot, "allowrdsaccess") ? arguments.snapshot.allowrdsaccess : false,
				allowadminaccess = structKeyExists(arguments.snapshot, "allowadminaccess") ? arguments.snapshot.allowadminaccess : false,
				allowadminapiaccess = structKeyExists(arguments.snapshot, "allowadminapiaccess") ? arguments.snapshot.allowadminapiaccess : false,
				isGroup = structKeyExists(arguments.snapshot, "isgroup") ? arguments.snapshot.isgroup : false
			};
			sec.setUser(argumentCollection=args);
			if(arguments.manageSecuredFilePathInNeo){
				setSecuredFilePathInNeo(structKeyExists(arguments.snapshot, "securedFilePath") ? arguments.snapshot.securedFilePath : false);
			}
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public void function addTestUser(){
		applyUserSnapshot(buildBaselineSnapshot());
	}

	public void function deleteTestUser(){
		deleteTestUserInternal();
	}

	private void function deleteTestUserInternal(){
		var admin = loginAdmin();
		try {
			try {
				getSecurityAdminApi().deleteUser(variables.TEST_USER);
			}
			catch(any e){}
			removeTestUserFromNeo();
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public string function getUserManagerSetting(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.USER_EXISTS_SETTING):
				return formatBooleanSettingValue(testUserExists());
			case lCase(variables.USER_DESCRIPTION_SETTING):
				if(NOT testUserExists())
					return "";
				return readUserSnapshot().description;
			case lCase(variables.ALLOW_RDS_ACCESS_SETTING):
				if(NOT testUserExists())
					return "false";
				return formatBooleanSettingValue(readUserSnapshot().allowrdsaccess);
			case lCase(variables.ALLOW_ADMIN_ACCESS_SETTING):
				if(NOT testUserExists())
					return "false";
				return formatBooleanSettingValue(readUserSnapshot().allowadminaccess);
			case lCase(variables.ENABLED_DATA_SOURCE_SETTING):
				if(NOT testUserExists())
					return "false";
				return formatBooleanSettingValue(arrayFindNoCase(readUserSnapshot().enabledds, variables.TEST_DATASOURCE) GT 0);
			case lCase(variables.USER_ROLE_SETTING):
				if(NOT testUserExists())
					return "false";
				return formatBooleanSettingValue(arrayFindNoCase(readUserSnapshot().roles, variables.TEST_ROLE) GT 0);
			case lCase(variables.SECURED_FILE_PATH_SETTING):
				// Deliberately skips the testUserExists() admin-API round trip the other settings use:
				// isSecuredFilePathPresentInNeo() already returns false when the user record is missing
				// (readAuthorizedUserFromNeo() -> structIsEmpty check), and adding one here is actively
				// harmful -- confirmed live that ANY later CFIDE.adminapi.administrator login/logout cycle
				// (even a read-only one) reloads and re-flushes its own in-memory neo-security.xml snapshot
				// back to disk, silently clobbering the direct sandbox-array write setSecuredFilePathInNeo()
				// just made moments earlier in the same request.
				return formatBooleanSettingValue(isSecuredFilePathPresentInNeo());
			case lCase(variables.IS_GROUP_SETTING):
				if(NOT testUserExists())
					return "false";
				return formatBooleanSettingValue(readUserSnapshot().isgroup);
			default:
				throw(message="Unsupported user manager setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	public string function setUserManagerSetting(required string settingName, required any settingValue){
		var settingKey = lCase(trim(arguments.settingName));
		if(settingKey EQ lCase(variables.USER_EXISTS_SETTING)){
			if(toBoolean(arguments.settingValue))
				addTestUser();
			else
				deleteTestUser();
			return getUserManagerSetting(arguments.settingName);
		}

		ensureUserManagerPrerequisites();
		if(NOT testUserExists())
			addTestUser();

		var snapshot = readUserSnapshot();
		switch(settingKey){
			case lCase(variables.USER_DESCRIPTION_SETTING):
				snapshot.description = trim("" & arguments.settingValue);
				break;
			case lCase(variables.ALLOW_RDS_ACCESS_SETTING):
				snapshot.allowrdsaccess = toBoolean(arguments.settingValue);
				break;
			case lCase(variables.ALLOW_ADMIN_ACCESS_SETTING):
				snapshot.allowadminaccess = toBoolean(arguments.settingValue);
				if(NOT snapshot.allowadminaccess)
					snapshot.allowadminapiaccess = false;
				break;
			case lCase(variables.ENABLED_DATA_SOURCE_SETTING):
				snapshot.enabledds = toBoolean(arguments.settingValue) ? [variables.TEST_DATASOURCE] : [];
				break;
			case lCase(variables.USER_ROLE_SETTING):
				snapshot.roles = toBoolean(arguments.settingValue) ? [variables.TEST_ROLE] : [];
				break;
			case lCase(variables.SECURED_FILE_PATH_SETTING):
				snapshot.securedFilePath = toBoolean(arguments.settingValue);
				break;
			case lCase(variables.IS_GROUP_SETTING):
				snapshot.isgroup = toBoolean(arguments.settingValue);
				break;
			default:
				throw(message="Unsupported user manager setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		applyUserSnapshot(snapshot, settingKey EQ lCase(variables.SECURED_FILE_PATH_SETTING));
		return getUserManagerSetting(arguments.settingName);
	}

	public string function getNewSetValueForSetting(required string settingName, any currentValue = ""){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.USER_DESCRIPTION_SETTING):
				return len(trim("" & arguments.currentValue)) ? "" : variables.TEST_DESCRIPTION;
			default:
				return formatBooleanSettingValue(arguments.currentValue) EQ "true" ? "false" : "true";
		}
	}

	public boolean function scalarValuesMatch(required any expectedValue, required any actualValue, string settingName = ""){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.USER_DESCRIPTION_SETTING):
				return lCase(trim("" & arguments.expectedValue)) EQ lCase(trim("" & arguments.actualValue));
			default:
				return formatBooleanSettingValue(arguments.expectedValue) EQ formatBooleanSettingValue(arguments.actualValue);
		}
	}

	public string function formatDisplayValue(required string settingName, required any value){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.USER_EXISTS_SETTING):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "Enabled" : "Disabled";
			case lCase(variables.USER_DESCRIPTION_SETTING):
				var text = trim("" & arguments.value);
				return len(text) ? text : "(empty)";
			case lCase(variables.ALLOW_RDS_ACCESS_SETTING):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "Allowed" : "Not allowed";
			case lCase(variables.ALLOW_ADMIN_ACCESS_SETTING):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "Allowed" : "Not allowed";
			case lCase(variables.ENABLED_DATA_SOURCE_SETTING):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "Allowed (#variables.TEST_DATASOURCE#)" : "Not allowed";
			case lCase(variables.USER_ROLE_SETTING):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "Allowed (#variables.TEST_ROLE#)" : "Not allowed";
			case lCase(variables.SECURED_FILE_PATH_SETTING):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? getTestSecuredFilePath() : "(none)";
			case lCase(variables.IS_GROUP_SETTING):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "Group" : "Individual user";
			default:
				return formatBooleanSettingValue(arguments.value);
		}
	}

	private array function getNeoUserSandboxes(required struct user){
		for(var keyName in ["sandboxes", "SANDBOXES"]){
			try {
				if(structKeyExists(arguments.user, keyName) AND isArray(arguments.user[keyName]))
					return duplicate(arguments.user[keyName]);
			}
			catch(any e){}
		}
		return [];
	}

	private void function writeNeoUserSandboxes(required struct user, required array sandboxes){
		try {
			arguments.user.sandboxes = arguments.sandboxes;
		}
		catch(any e){
			try {
				arguments.user.SANDBOXES = arguments.sandboxes;
			}
			catch(any e2){
				structInsert(arguments.user, "sandboxes", arguments.sandboxes, true);
			}
		}
	}

	private boolean function isSecuredFilePathPresentInNeo(){
		var user = readAuthorizedUserFromNeo();
		if(structIsEmpty(user))
			return false;
		return hasTestSecuredPathInSandboxes(getNeoUserSandboxes(user));
	}

	private boolean function hasTestSecuredPathInSandboxes(required array sandboxes){
		for(var entry in arguments.sandboxes){
			if(isStruct(entry) AND structKeyExists(entry, "TARGET")
					AND findNoCase(variables.TEST_FILE_DIR, normalizePath("" & entry.TARGET)))
				return true;
		}
		return false;
	}

	private void function setSecuredFilePathInNeo(required boolean present){
		var cfg = loadSecurityConfigMap();
		ensureAuthorizedUsersStruct(cfg);
		if(NOT structKeyExists(cfg.AuthorizedUsers, variables.TEST_USER)){
			if(NOT arguments.present)
				return;
			cfg.AuthorizedUsers[variables.TEST_USER] = {
				username = variables.TEST_USER,
				roles = [],
				description = "",
				sandboxes = [],
				isLdap = false,
				isGroup = false,
				isSaml = false
			};
		}
		// duplicate() on this entry doesn't produce a plain CFML struct -- confirmed live that
		// AuthorizedUsers entries deserialize from WDDX as type='java.util.HashMap', and dot-assignment
		// on a duplicate() of one silently no-ops (no exception, so writeNeoUserSandboxes()'s try/catch
		// fallback chain never even triggers) instead of actually mutating it. Copying key-by-key via
		// for-in into a fresh struct literal is the only way that's confirmed to stick.
		var user = {};
		for(var fieldKey in cfg.AuthorizedUsers[variables.TEST_USER])
			user[fieldKey] = cfg.AuthorizedUsers[variables.TEST_USER][fieldKey];
		var sandboxes = removeTestSecuredPathsFromArray(getNeoUserSandboxes(user));
		if(arguments.present){
			arrayAppend(sandboxes, {
				TARGET = getTestSecuredFilePath(),
				ACTION = "read,write,execute,delete",
				CLASS = "java.io.FilePermission"
			});
		}
		writeNeoUserSandboxes(user, sandboxes);
		cfg.AuthorizedUsers[variables.TEST_USER] = user;
		saveSecurityConfigMap(cfg);
	}

	private array function removeTestSecuredPathsFromArray(required array sandboxes){
		var cleaned = [];
		for(var entry in arguments.sandboxes){
			if(isStruct(entry) AND structKeyExists(entry, "TARGET")
					AND findNoCase(variables.TEST_FILE_DIR, normalizePath("" & entry.TARGET)))
				continue;
			arrayAppend(cleaned, entry);
		}
		return cleaned;
	}

	private void function removeTestUserFromNeo(){
		var cfg = loadSecurityConfigMap();
		if(NOT structKeyExists(cfg, "AuthorizedUsers") OR NOT isStruct(cfg.AuthorizedUsers))
			return;
		if(structKeyExists(cfg.AuthorizedUsers, variables.TEST_USER))
			structDelete(cfg.AuthorizedUsers, variables.TEST_USER);
		saveSecurityConfigMap(cfg);
	}

	private struct function readAuthorizedUserFromNeo(){
		var cfg = loadSecurityConfigMap();
		if(NOT structKeyExists(cfg, "AuthorizedUsers") OR NOT isStruct(cfg.AuthorizedUsers))
			return {};
		if(NOT structKeyExists(cfg.AuthorizedUsers, variables.TEST_USER))
			return {};
		return cfg.AuthorizedUsers[variables.TEST_USER];
	}

	private void function ensureAuthorizedUsersStruct(required struct configMap){
		if(NOT structKeyExists(arguments.configMap, "AuthorizedUsers") OR NOT isStruct(arguments.configMap.AuthorizedUsers))
			arguments.configMap.AuthorizedUsers = {};
	}

	private string function normalizePath(required string pathValue){
		return replace(replace(trim(arguments.pathValue), "/", "\", "all"), "\\\\", "\", "all");
	}

	private array function filterCustomRoles(required array roles){
		var filtered = [];
		for(var roleName in arguments.roles){
			if(listFindNoCase("coldfusion.rds,coldfusion.administrator,coldfusion.adminapi", roleName))
				continue;
			arrayAppend(filtered, roleName);
		}
		return filtered;
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

	private struct function loadSecurityConfigMap(){
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
		var raw = loadSecurityConfigRaw();
		if(isStruct(raw))
			saveSecurityConfigRaw(arguments.configMap);
		else if(isArray(raw) AND arrayLen(raw) GTE 1){
			raw[1] = arguments.configMap;
			saveSecurityConfigRaw(raw);
		}
		else
			throw(message="invalid neo-security.xml structure", type="CCSTest.ConfigError");
	}

	private any function loginAdmin(){
		ensureConstants();
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

}
