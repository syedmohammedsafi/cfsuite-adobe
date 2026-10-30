/**
* Read/write ColdFusion Administrator Security > User Manager settings.
*/
component output="false" {

	variables.TEST_USER = "ccsTestUserMgr";
	variables.TEST_SAML_USER = "ccsTestSamlUser@test.com";
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
	variables.USER_PASSWORD_SETTING = "UserPassword";
	variables.USER_PASSWORD_CONFIRM_SETTING = "UserPasswordConfirm";
	variables.USER_EXTERNAL_SETTING = "UserExternal";
	variables.USER_TYPE_LDAP_SETTING = "UserTypeLdap";
	variables.USER_TYPE_SAML_SETTING = "UserTypeSaml";
	variables.USER_ADMIN_CONSOLE_AND_API_SETTING = "UserAdminConsoleAndApi";
	variables.USER_API_ACCESS_ONLY_SETTING = "UserApiAccessOnly";
	variables.USER_PROHIBITED_ROLE_SETTING = "UserProhibitedRole";
	variables.USER_PROHIBITED_DATASOURCE_SETTING = "UserProhibitedDataSource";
	variables.USER_FILE_READ_SETTING = "UserFileRead";
	variables.USER_FILE_WRITE_SETTING = "UserFileWrite";
	variables.USER_FILE_EXECUTE_SETTING = "UserFileExecute";
	variables.USER_FILE_DELETE_SETTING = "UserFileDelete";

	public function init(){
		variables.componentVersion = 1;
		return this;
	}

	private any function getSecUtil(){
		return new cfsuite.ccssuite.utils.securityConfigUtil().init();
	}

	public boolean function isUserManagerSetting(required string settingName){
		var key = lCase(trim(arguments.settingName));
		var supported = [
			variables.USER_EXISTS_SETTING,
			variables.USER_DESCRIPTION_SETTING,
			variables.ALLOW_RDS_ACCESS_SETTING,
			variables.ALLOW_ADMIN_ACCESS_SETTING,
			variables.ENABLED_DATA_SOURCE_SETTING,
			variables.USER_ROLE_SETTING,
			variables.SECURED_FILE_PATH_SETTING,
			variables.IS_GROUP_SETTING,
			variables.USER_PASSWORD_SETTING,
			variables.USER_PASSWORD_CONFIRM_SETTING,
			variables.USER_EXTERNAL_SETTING,
			variables.USER_TYPE_LDAP_SETTING,
			variables.USER_TYPE_SAML_SETTING,
			variables.USER_ADMIN_CONSOLE_AND_API_SETTING,
			variables.USER_API_ACCESS_ONLY_SETTING,
			variables.USER_PROHIBITED_ROLE_SETTING,
			variables.USER_PROHIBITED_DATASOURCE_SETTING,
			variables.USER_FILE_READ_SETTING,
			variables.USER_FILE_WRITE_SETTING,
			variables.USER_FILE_EXECUTE_SETTING,
			variables.USER_FILE_DELETE_SETTING
		];
		for(var s in supported){
			if(lCase(s) EQ key)
				return true;
		}
		return false;
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
	}

	// EnabledDataSource grants variables.TEST_DATASOURCE on the test user via setUser(enabledds=[...]) --
	// confirmed live that CF silently drops any name in that array that isn't a registered datasource
	// (no error, just never lands), instead of throwing. This dev environment ships with ZERO datasources
	// configured (neo-datasource.xml starts empty), so register a throwaway embedded Derby datasource
	// once per node -- no external DB server needed, and nothing here ever actually connects to it, it
	// only needs to exist by name for the grant to stick.
	private void function ensureTestDatasourceRegistered(){
		if(structKeyExists(application, "ccsTestDatasourceReady") AND application.ccsTestDatasourceReady)
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
		application.ccsTestDatasourceReady = true;
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

	public boolean function testSamlUserExists(){
		var admin = loginAdmin();
		try {
			var u = getSecurityAdminApi().getUser(variables.TEST_SAML_USER);
			return structKeyExists(u, "ISSAML") AND u.ISSAML;
		}
		catch(any e){
			return false;
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public void function ensureTestSamlUserPresent(){
		ensureUserManagerPrerequisites();
		if(testSamlUserExists())
			return;
		var admin = loginAdmin();
		try {
			var sec = getSecurityAdminApi();
			sec.setUser(username=variables.TEST_SAML_USER, password=variables.TEST_PASS, isSaml=true);
		}
		finally {
			logoutAdmin(admin);
		}
	}

	public void function ensureTestSamlUserAbsent(){
		var admin = loginAdmin();
		try {
			try {
				getSecurityAdminApi().deleteUser(variables.TEST_SAML_USER);
			}
			catch(any e){}
			removeUserFromNeo(variables.TEST_SAML_USER);
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
			isgroup = false,
			isLdap = false,
			isSaml = false
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
				isgroup = structKeyExists(user, "ISGROUP") ? user.ISGROUP : false,
				isLdap = structKeyExists(user, "ISLDAP") ? user.ISLDAP : false,
				isSaml = structKeyExists(user, "ISSAML") ? user.ISSAML : false
			};
			return snapshot;
		}
		catch(any e){
			return buildBaselineSnapshot();
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
				password = structKeyExists(arguments.snapshot, "password") AND len(trim(arguments.snapshot.password)) ? arguments.snapshot.password : variables.TEST_PASS,
				description = structKeyExists(arguments.snapshot, "description") ? arguments.snapshot.description : "",
				roles = structKeyExists(arguments.snapshot, "roles") AND isArray(arguments.snapshot.roles) ? arguments.snapshot.roles : [],
				disabledroles = structKeyExists(arguments.snapshot, "disabledroles") AND isArray(arguments.snapshot.disabledroles) ? arguments.snapshot.disabledroles : [],
				enabledds = structKeyExists(arguments.snapshot, "enabledds") AND isArray(arguments.snapshot.enabledds) ? arguments.snapshot.enabledds : [],
				allowrdsaccess = structKeyExists(arguments.snapshot, "allowrdsaccess") ? arguments.snapshot.allowrdsaccess : false,
				allowadminaccess = structKeyExists(arguments.snapshot, "allowadminaccess") ? arguments.snapshot.allowadminaccess : false,
				allowadminapiaccess = structKeyExists(arguments.snapshot, "allowadminapiaccess") ? arguments.snapshot.allowadminapiaccess : false,
				isGroup = structKeyExists(arguments.snapshot, "isgroup") ? arguments.snapshot.isgroup : false,
				isLdap = structKeyExists(arguments.snapshot, "isLdap") ? arguments.snapshot.isLdap : false,
				isSaml = structKeyExists(arguments.snapshot, "isSaml") ? arguments.snapshot.isSaml : false
			};
			var userAlreadyExists = false;
			try {
				sec.getUser(variables.TEST_USER);
				userAlreadyExists = true;
			} catch(any e){}
			if(userAlreadyExists AND (isLdapUserInNeo() OR isSamlUserInNeo()) AND NOT args.isLdap AND NOT args.isSaml){
				try { sec.deleteUser(variables.TEST_USER); } catch(any e){}
			}
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
			try {
				getSecurityAdminApi().deleteUser(variables.TEST_SAML_USER);
			}
			catch(any e){}
			removeTestUserFromNeo();
			removeUserFromNeo(variables.TEST_SAML_USER);
			structDelete(application, "ccsTestUserPassword");
			structDelete(application, "ccsTestUserPasswordConfirm");
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
					return "";
				var dss = readUserSnapshot().enabledds;
				return isArray(dss) AND arrayLen(dss) ? arrayToList(dss) : "";
			case lCase(variables.USER_ROLE_SETTING):
				if(NOT testUserExists())
					return "";
				var rls = readUserSnapshot().roles;
				return isArray(rls) AND arrayLen(rls) ? arrayToList(rls) : "";
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
			case lCase(variables.USER_PASSWORD_SETTING):
				return structKeyExists(application, "ccsTestUserPassword") ? application.ccsTestUserPassword : "";
			case lCase(variables.USER_PASSWORD_CONFIRM_SETTING):
				return structKeyExists(application, "ccsTestUserPasswordConfirm") ? application.ccsTestUserPasswordConfirm : "";
			case lCase(variables.USER_EXTERNAL_SETTING):
				return formatBooleanSettingValue(isExternalUserInNeo());
			case lCase(variables.USER_TYPE_LDAP_SETTING):
				return formatBooleanSettingValue(isLdapUserInNeo());
			case lCase(variables.USER_TYPE_SAML_SETTING):
				return formatBooleanSettingValue(testSamlUserExists());
			case lCase(variables.USER_ADMIN_CONSOLE_AND_API_SETTING):
				return formatBooleanSettingValue(isAdminConsoleAndApiInNeo());
			case lCase(variables.USER_API_ACCESS_ONLY_SETTING):
				return formatBooleanSettingValue(isApiAccessOnlyInNeo());
			case lCase(variables.USER_PROHIBITED_ROLE_SETTING):
				var user = readAuthorizedUserFromNeo();
				if(structIsEmpty(user)) return "";
				var dRoles = getNeoUserField(user, "disabledroles", []);
				return isArray(dRoles) AND arrayLen(dRoles) ? arrayToList(dRoles) : "";
			case lCase(variables.USER_PROHIBITED_DATASOURCE_SETTING):
				var user = readAuthorizedUserFromNeo();
				if(structIsEmpty(user)) return "";
				var dDS = getNeoUserField(user, "disabledds", []);
				return isArray(dDS) AND arrayLen(dDS) ? arrayToList(dDS) : "";
			case lCase(variables.USER_FILE_READ_SETTING):
				return formatBooleanSettingValue(isUserFileActionPresentInNeo("read"));
			case lCase(variables.USER_FILE_WRITE_SETTING):
				return formatBooleanSettingValue(isUserFileActionPresentInNeo("write"));
			case lCase(variables.USER_FILE_EXECUTE_SETTING):
				return formatBooleanSettingValue(isUserFileActionPresentInNeo("execute"));
			case lCase(variables.USER_FILE_DELETE_SETTING):
				return formatBooleanSettingValue(isUserFileActionPresentInNeo("delete"));
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
				snapshot.enabledds = parseSettingValueToArray(arguments.settingValue, variables.TEST_DATASOURCE);
				break;
			case lCase(variables.USER_ROLE_SETTING):
				snapshot.roles = parseSettingValueToArray(arguments.settingValue, variables.TEST_ROLE);
				break;
			case lCase(variables.SECURED_FILE_PATH_SETTING):
				snapshot.securedFilePath = toBoolean(arguments.settingValue);
				break;
			case lCase(variables.IS_GROUP_SETTING):
				snapshot.isgroup = toBoolean(arguments.settingValue);
				break;
			case lCase(variables.USER_PASSWORD_SETTING):
				var passVal = trim("" & arguments.settingValue);
				if(len(passVal) AND passVal NEQ "(empty)"){
					application.ccsTestUserPassword = passVal;
					snapshot.password = passVal;
				}
				else {
					structDelete(application, "ccsTestUserPassword");
				}
				break;
			case lCase(variables.USER_PASSWORD_CONFIRM_SETTING):
				var confirmVal = trim("" & arguments.settingValue);
				if(len(confirmVal) AND confirmVal NEQ "(empty)"){
					application.ccsTestUserPasswordConfirm = confirmVal;
				}
				else {
					structDelete(application, "ccsTestUserPasswordConfirm");
				}
				return getUserManagerSetting(arguments.settingName);
			case lCase(variables.USER_EXTERNAL_SETTING):
				var ext = toBoolean(arguments.settingValue);
				snapshot.isLdap = ext;
				if(ext) snapshot.isSaml = false;
				break;
			case lCase(variables.USER_TYPE_LDAP_SETTING):
				var isL = toBoolean(arguments.settingValue);
				snapshot.isLdap = isL;
				if(isL) snapshot.isSaml = false;
				break;
			case lCase(variables.USER_TYPE_SAML_SETTING):
				if(toBoolean(arguments.settingValue))
					ensureTestSamlUserPresent();
				else
					ensureTestSamlUserAbsent();
				return getUserManagerSetting(arguments.settingName);
			case lCase(variables.USER_ADMIN_CONSOLE_AND_API_SETTING):
				var consoleAndApi = toBoolean(arguments.settingValue);
				snapshot.allowadminaccess = consoleAndApi;
				snapshot.allowadminapiaccess = NOT consoleAndApi;
				break;
			case lCase(variables.USER_API_ACCESS_ONLY_SETTING):
				var apiOnly = toBoolean(arguments.settingValue);
				snapshot.allowadminaccess = NOT apiOnly;
				snapshot.allowadminapiaccess = apiOnly;
				break;
			case lCase(variables.USER_PROHIBITED_ROLE_SETTING):
				setProhibitedRoleInNeo(arguments.settingValue);
				return getUserManagerSetting(arguments.settingName);
			case lCase(variables.USER_PROHIBITED_DATASOURCE_SETTING):
				setProhibitedDataSourceInNeo(arguments.settingValue);
				return getUserManagerSetting(arguments.settingName);
			case lCase(variables.USER_FILE_READ_SETTING):
				setUserFileActionInNeo("read", toBoolean(arguments.settingValue));
				return getUserManagerSetting(arguments.settingName);
			case lCase(variables.USER_FILE_WRITE_SETTING):
				setUserFileActionInNeo("write", toBoolean(arguments.settingValue));
				return getUserManagerSetting(arguments.settingName);
			case lCase(variables.USER_FILE_EXECUTE_SETTING):
				setUserFileActionInNeo("execute", toBoolean(arguments.settingValue));
				return getUserManagerSetting(arguments.settingName);
			case lCase(variables.USER_FILE_DELETE_SETTING):
				setUserFileActionInNeo("delete", toBoolean(arguments.settingValue));
				return getUserManagerSetting(arguments.settingName);
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
			case lCase(variables.USER_PASSWORD_SETTING):
			case lCase(variables.USER_PASSWORD_CONFIRM_SETTING):
				return variables.TEST_PASS;
			case lCase(variables.USER_ROLE_SETTING):
				return toggleItemInList(arguments.currentValue, variables.TEST_ROLE);
			case lCase(variables.USER_PROHIBITED_ROLE_SETTING):
				return toggleItemInList(arguments.currentValue, variables.TEST_ROLE);
			case lCase(variables.ENABLED_DATA_SOURCE_SETTING):
				return toggleItemInList(arguments.currentValue, variables.TEST_DATASOURCE);
			case lCase(variables.USER_PROHIBITED_DATASOURCE_SETTING):
				return toggleItemInList(arguments.currentValue, variables.TEST_DATASOURCE);
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
			case lCase(variables.USER_PASSWORD_SETTING):
			case lCase(variables.USER_PASSWORD_CONFIRM_SETTING):
				return trim("" & arguments.expectedValue) EQ trim("" & arguments.actualValue);
			case lCase(variables.USER_ROLE_SETTING):
				return multiSelectValuesMatch(arguments.expectedValue, arguments.actualValue, variables.TEST_ROLE);
			case lCase(variables.USER_PROHIBITED_ROLE_SETTING):
				return multiSelectValuesMatch(arguments.expectedValue, arguments.actualValue, variables.TEST_ROLE);
			case lCase(variables.ENABLED_DATA_SOURCE_SETTING):
				return multiSelectValuesMatch(arguments.expectedValue, arguments.actualValue, variables.TEST_DATASOURCE);
			case lCase(variables.USER_PROHIBITED_DATASOURCE_SETTING):
				return multiSelectValuesMatch(arguments.expectedValue, arguments.actualValue, variables.TEST_DATASOURCE);
			default:
				return formatBooleanSettingValue(arguments.expectedValue) EQ formatBooleanSettingValue(arguments.actualValue);
		}
	}

	public string function formatDisplayValue(required string settingName, required any value){
		switch(lCase(trim(arguments.settingName))){
			case lCase(variables.USER_EXISTS_SETTING):
				return formatBooleanSettingValue(arguments.value);
			case lCase(variables.USER_DESCRIPTION_SETTING):
				var text = trim("" & arguments.value);
				return len(text) ? text : "(empty)";
			case lCase(variables.ALLOW_RDS_ACCESS_SETTING):
				return formatBooleanSettingValue(arguments.value);
			case lCase(variables.ALLOW_ADMIN_ACCESS_SETTING):
				return formatBooleanSettingValue(arguments.value);
			case lCase(variables.ENABLED_DATA_SOURCE_SETTING):
			case lCase(variables.USER_ROLE_SETTING):
			case lCase(variables.USER_PROHIBITED_ROLE_SETTING):
			case lCase(variables.USER_PROHIBITED_DATASOURCE_SETTING):
				var list = parseItemsList(arguments.value);
				return arrayLen(list) ? arrayToList(list, ", ") : "(none)";
			case lCase(variables.SECURED_FILE_PATH_SETTING):
				return formatBooleanSettingValue(arguments.value) EQ "true" ? getTestSecuredFilePath() : "(none)";
			case lCase(variables.IS_GROUP_SETTING):
				return formatBooleanSettingValue(arguments.value);
			case lCase(variables.USER_PASSWORD_SETTING):
			case lCase(variables.USER_PASSWORD_CONFIRM_SETTING):
				var text = trim("" & arguments.value);
				if(NOT len(text) OR text EQ "password")
					return "(empty)";
				return text;
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
				isSaml = javaCast("boolean", false)
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
		removeUserFromNeo(variables.TEST_USER);
	}

	private void function removeUserFromNeo(required string username){
		var cfg = loadSecurityConfigMap();
		if(NOT structKeyExists(cfg, "AuthorizedUsers") OR NOT isStruct(cfg.AuthorizedUsers))
			return;
		if(structKeyExists(cfg.AuthorizedUsers, arguments.username))
			structDelete(cfg.AuthorizedUsers, arguments.username);
		saveSecurityConfigMap(cfg);
	}

	private struct function readAuthorizedUserFromNeo(){
		var cfg = loadSecurityConfigMap();
		if(NOT structKeyExists(cfg, "AuthorizedUsers") OR NOT isStruct(cfg.AuthorizedUsers))
			return {};
		if(NOT structKeyExists(cfg.AuthorizedUsers, variables.TEST_USER))
			return {};
		var rawUser = cfg.AuthorizedUsers[variables.TEST_USER];
		var cleanUser = {};
		if(isStruct(rawUser)){
			for(var k in rawUser){
				cleanUser[k] = rawUser[k];
			}
		}
		return cleanUser;
	}

	private any function getNeoUserField(required struct user, required string fieldName, any defaultValue = ""){
		if(structIsEmpty(arguments.user))
			return arguments.defaultValue;
		if(structKeyExists(arguments.user, arguments.fieldName))
			return arguments.user[arguments.fieldName];
		for(var k in arguments.user){
			if(compareNoCase(k, arguments.fieldName) EQ 0)
				return arguments.user[k];
		}
		return arguments.defaultValue;
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
		return getSecUtil().loginAdminPublic();
	}

	private void function logoutAdmin(required any admin){
		// No-op to preserve authenticated Admin API session across nested calls within the request
	}

	private any function getSecurityAdminApi(){
		return createObject("component", "CFIDE.adminapi.security");
	}


	private void function ensureTestSecuredPathReady(){
		if(NOT isSecuredFilePathPresentInNeo())
			setSecuredFilePathInNeo(true);
	}

	private boolean function isUserFileActionPresentInNeo(required string actionName){
		var user = readAuthorizedUserFromNeo();
		if(structIsEmpty(user))
			return false;
		var sandboxes = getNeoUserSandboxes(user);
		for(var entry in sandboxes){
			if(isStruct(entry) AND structKeyExists(entry, "TARGET")
					AND findNoCase(variables.TEST_FILE_DIR, normalizePath("" & entry.TARGET))){
				var actions = structKeyExists(entry, "ACTION") ? entry.ACTION : "";
				return listFindNoCase(actions, arguments.actionName) GT 0;
			}
		}
		return false;
	}

	private void function setUserFileActionInNeo(required string actionName, required boolean present){
		ensureTestSecuredPathReady();
		var cfg = loadSecurityConfigMap();
		ensureAuthorizedUsersStruct(cfg);
		if(NOT structKeyExists(cfg.AuthorizedUsers, variables.TEST_USER))
			return;
		var user = {};
		for(var fieldKey in cfg.AuthorizedUsers[variables.TEST_USER])
			user[fieldKey] = cfg.AuthorizedUsers[variables.TEST_USER][fieldKey];
		var sandboxes = getNeoUserSandboxes(user);
		for(var i = 1; i LTE arrayLen(sandboxes); i++){
			var entry = sandboxes[i];
			if(isStruct(entry) AND structKeyExists(entry, "TARGET")
					AND findNoCase(variables.TEST_FILE_DIR, normalizePath("" & entry.TARGET))){
				var actions = structKeyExists(entry, "ACTION") ? entry.ACTION : "";
				var actList = listToArray(actions);
				var idx = arrayFindNoCase(actList, arguments.actionName);
				if(arguments.present AND idx EQ 0){
					arrayAppend(actList, arguments.actionName);
				} else if(NOT arguments.present AND idx GT 0){
					arrayDeleteAt(actList, idx);
				}
				entry.ACTION = arrayToList(actList);
				sandboxes[i] = entry;
				break;
			}
		}
		writeNeoUserSandboxes(user, sandboxes);
		cfg.AuthorizedUsers[variables.TEST_USER] = user;
		saveSecurityConfigMap(cfg);
	}

	private boolean function isProhibitedRolePresentInNeo(){
		var user = readAuthorizedUserFromNeo();
		if(structIsEmpty(user)) return false;
		var dRoles = getNeoUserField(user, "disabledroles", []);
		if(NOT isArray(dRoles)) return false;
		return arrayFindNoCase(dRoles, variables.TEST_ROLE) GT 0;
	}

	private void function setProhibitedRoleInNeo(required any settingValue){
		var cfg = loadSecurityConfigMap();
		ensureAuthorizedUsersStruct(cfg);
		if(NOT structKeyExists(cfg.AuthorizedUsers, variables.TEST_USER))
			return;
		var user = {};
		for(var fieldKey in cfg.AuthorizedUsers[variables.TEST_USER])
			user[fieldKey] = cfg.AuthorizedUsers[variables.TEST_USER][fieldKey];
		user["disabledroles"] = parseSettingValueToArray(arguments.settingValue, variables.TEST_ROLE);
		cfg.AuthorizedUsers[variables.TEST_USER] = user;
		saveSecurityConfigMap(cfg);
	}

	private void function setProhibitedDataSourceInNeo(required any settingValue){
		var cfg = loadSecurityConfigMap();
		ensureAuthorizedUsersStruct(cfg);
		if(NOT structKeyExists(cfg.AuthorizedUsers, variables.TEST_USER))
			return;
		var user = {};
		for(var fieldKey in cfg.AuthorizedUsers[variables.TEST_USER])
			user[fieldKey] = cfg.AuthorizedUsers[variables.TEST_USER][fieldKey];
		user["disabledds"] = parseSettingValueToArray(arguments.settingValue, variables.TEST_DATASOURCE);
		cfg.AuthorizedUsers[variables.TEST_USER] = user;
		saveSecurityConfigMap(cfg);
	}

	private boolean function isLdapUserInNeo(){
		var user = readAuthorizedUserFromNeo();
		if(structIsEmpty(user)) return false;
		return toBoolean(getNeoUserField(user, "isLdap", false));
	}

	private void function setLdapUserInNeo(required boolean present){
		var cfg = loadSecurityConfigMap();
		ensureAuthorizedUsersStruct(cfg);
		if(NOT structKeyExists(cfg.AuthorizedUsers, variables.TEST_USER)) return;
		var user = {};
		for(var fieldKey in cfg.AuthorizedUsers[variables.TEST_USER])
			user[fieldKey] = cfg.AuthorizedUsers[variables.TEST_USER][fieldKey];
		user["isLdap"] = arguments.present;
		cfg.AuthorizedUsers[variables.TEST_USER] = user;
		saveSecurityConfigMap(cfg);
	}

	private boolean function isSamlUserInNeo(){
		var user = readAuthorizedUserFromNeo();
		if(structIsEmpty(user)) return false;
		return toBoolean(getNeoUserField(user, "isSaml", false));
	}

	private void function setSamlUserInNeo(required boolean present){
		var cfg = loadSecurityConfigMap();
		ensureAuthorizedUsersStruct(cfg);
		if(NOT structKeyExists(cfg.AuthorizedUsers, variables.TEST_USER)) return;
		var user = {};
		for(var fieldKey in cfg.AuthorizedUsers[variables.TEST_USER])
			user[fieldKey] = cfg.AuthorizedUsers[variables.TEST_USER][fieldKey];
		user["isSaml"] = javaCast("boolean", arguments.present);
		cfg.AuthorizedUsers[variables.TEST_USER] = user;
		saveSecurityConfigMap(cfg);
	}

	private boolean function isExternalUserInNeo(){
		return isLdapUserInNeo() OR isSamlUserInNeo();
	}

	private void function setExternalUserInNeo(required boolean present){
		setLdapUserInNeo(arguments.present);
	}

	private boolean function isApiAccessOnlyInNeo(){
		var user = readAuthorizedUserFromNeo();
		if(structIsEmpty(user)) return false;
		var roles = getNeoUserField(user, "roles", []);
		var hasApi = isArray(roles) ? (arrayFindNoCase(roles, "coldfusion.adminapi") GT 0) : (listFindNoCase(roles, "coldfusion.adminapi") GT 0);
		var hasAdmin = isArray(roles) ? (arrayFindNoCase(roles, "coldfusion.administrator") GT 0) : (listFindNoCase(roles, "coldfusion.administrator") GT 0);
		return hasApi AND NOT hasAdmin;
	}

	private void function setApiAccessOnlyInNeo(required boolean present){
		var cfg = loadSecurityConfigMap();
		ensureAuthorizedUsersStruct(cfg);
		if(NOT structKeyExists(cfg.AuthorizedUsers, variables.TEST_USER)) return;
		var user = {};
		for(var fieldKey in cfg.AuthorizedUsers[variables.TEST_USER])
			user[fieldKey] = cfg.AuthorizedUsers[variables.TEST_USER][fieldKey];
		user["allowadminaccess"] = true;
		user["allowadminapiaccess"] = arguments.present;
		cfg.AuthorizedUsers[variables.TEST_USER] = user;
		saveSecurityConfigMap(cfg);
	}

	private boolean function isAdminConsoleAndApiInNeo(){
		var user = readAuthorizedUserFromNeo();
		if(structIsEmpty(user)) return false;
		var roles = getNeoUserField(user, "roles", []);
		var hasAdmin = isArray(roles) ? (arrayFindNoCase(roles, "coldfusion.administrator") GT 0) : (listFindNoCase(roles, "coldfusion.administrator") GT 0);
		return hasAdmin;
	}

	private void function setAdminConsoleAndApiInNeo(required boolean present){
		setApiAccessOnlyInNeo(NOT arguments.present);
	}


	private array function parseItemsList(required any value){
		if(isArray(arguments.value))
			return arguments.value;
		var raw = trim("" & arguments.value);
		if(NOT len(raw) OR raw EQ "(none)" OR raw EQ "(empty)")
			return [];
		var result = [];
		for(var item in listToArray(raw)){
			var t = trim(item);
			if(len(t) AND arrayFindNoCase(result, t) EQ 0)
				arrayAppend(result, t);
		}
		return result;
	}

	private array function parseSettingValueToArray(required any value, required string testItem){
		var text = trim("" & arguments.value);
		if(listFindNoCase("true,yes,1", text) GT 0)
			return [arguments.testItem];
		if(listFindNoCase("false,no,0", text) GT 0 OR NOT len(text) OR text EQ "(none)" OR text EQ "(empty)")
			return [];
		return parseItemsList(text);
	}

	private string function toggleItemInList(required any currentValue, required string targetItem){
		var list = parseItemsList(arguments.currentValue);
		if(arrayFindNoCase(list, arguments.targetItem) GT 0){
			var filtered = [];
			for(var item in list){
				if(compareNoCase(trim(item), arguments.targetItem) NEQ 0)
					arrayAppend(filtered, trim(item));
			}
			return arrayToList(filtered);
		}
		else {
			arrayAppend(list, arguments.targetItem);
			return arrayToList(list);
		}
	}

	private boolean function multiSelectValuesMatch(required any expectedValue, required any actualValue, required string targetItem){
		var expText = trim("" & arguments.expectedValue);
		var shouldHaveTarget = false;
		if(listFindNoCase("true,yes,1", expText) GT 0)
			shouldHaveTarget = true;
		else if(listFindNoCase("false,no,0,(empty),(none)", expText) GT 0 OR NOT len(expText))
			shouldHaveTarget = false;
		else
			shouldHaveTarget = (arrayFindNoCase(parseItemsList(expText), arguments.targetItem) GT 0);

		var actualList = parseItemsList(arguments.actualValue);
		var hasTarget = (arrayFindNoCase(actualList, arguments.targetItem) GT 0);
		return shouldHaveTarget EQ hasTarget;
	}
}