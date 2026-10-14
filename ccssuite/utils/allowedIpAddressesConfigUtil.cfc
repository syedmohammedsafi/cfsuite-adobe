/**
* Read/write ColdFusion Administrator Security > Allowed IP Addresses settings.
*
* The real Admin UI page has exactly two controls: a free-text "IP Address" box that adds one
* entry, and a "RestrictedAdminIPList" multi-select used to pick an entry to remove. Both act on
* the same underlying allowedAdminIPList value, so this util models it as ONE test IP with two
* force-a-specific-direction alias settings (add / remove) -- same pattern as EXTERNAL_AUTH_*
* and RDS_SINGLE_PASSWORD_ONLY/RDS_SEPARATE_USER_AUTH in securityConfigUtil.cfc.
*/
component output="false" {

	variables.ALLOWED_ADMIN_IP_LIST_KEY = "allowedAdminIPList";
	variables.DEFAULT_ADMIN_IPS = "127.0.0.1,::1";
	variables.TEST_IP = "203.0.113.50";
	variables.SETTING_ADD = "AllowedAdminIpAdd";
	variables.SETTING_REMOVE = "AllowedAdminIpRemove";

	public function init(){
		variables.componentVersion = 1;
		return this;
	}

	private any function getSecUtil(){
		return new cfsuite.ccssuite.utils.securityConfigUtil().init();
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
		if(NOT isDefined("application.constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
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

	private any function getSecurityService(){
		return createObject("java", "coldfusion.server.ServiceFactory").getSecurityService();
	}

	private struct function getSecurityConfigMap(){
		return getSecUtil().readSecurityConfigMapPublic();
	}

	private void function saveSecurityConfigMap(required struct configMap){
		getSecUtil().writeSecurityConfigMapPublic(arguments.configMap);
	}

	private string function findStructKey(required struct data, required string key){
		return getSecUtil().findSecurityConfigKeyPublic(arguments.data, arguments.key);
	}

	public string function getAddSettingName(){
		return variables.SETTING_ADD;
	}

	public string function getRemoveSettingName(){
		return variables.SETTING_REMOVE;
	}

	public boolean function isAllowedIpSetting(required string settingName){
		return listFindNoCase(variables.SETTING_ADD & "," & variables.SETTING_REMOVE, trim(arguments.settingName)) GT 0;
	}

	public string function formatBooleanSettingValue(required any value){
		if(isBoolean(arguments.value))
			return arguments.value ? "true" : "false";
		return listFindNoCase("true,yes,1", lCase(trim("" & arguments.value))) GT 0 ? "true" : "false";
	}

	public string function getAllowedIpAddressesSetting(required string settingName){
		if(NOT isAllowedIpSetting(arguments.settingName))
			throw(message="Unsupported allowed IP setting: #arguments.settingName#", type="CCSTest.ConfigError");
		return getAllowedAdminIpListRaw();
	}

	public string function setAllowedIpAddressesSetting(required string settingName, required any settingValue){
		if(NOT isAllowedIpSetting(arguments.settingName))
			throw(message="Unsupported allowed IP setting: #arguments.settingName#", type="CCSTest.ConfigError");
		if(resolveTargetPresence(arguments.settingValue))
			addIpToAllowedAdminList(variables.TEST_IP);
		else
			removeIpFromAllowedAdminList(variables.TEST_IP);
		return getAllowedIpAddressesSetting(arguments.settingName);
	}

	public boolean function allowedIpValuesMatch(required any requestedValue, required any actualValue, required string settingName){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		return resolveTargetPresence(arguments.requestedValue) EQ
			(arrayFindNoCase(parseIpList(arguments.actualValue), variables.TEST_IP) GT 0);
	}

	public string function getNewSetValueForSetting(required string settingName, any currentValue = ""){
		return lCase(trim(arguments.settingName)) EQ lCase(variables.SETTING_REMOVE) ? "false" : "true";
	}

	// Accepts either a plain boolean-ish flag (from getNewSetValueForSetting, driving the primary set
	// call) or a raw allowedAdminIPList snapshot (originalValue captured before the test ran, replayed
	// verbatim during rollback/restore) and resolves both to "should the test IP be present afterward?".
	private boolean function resolveTargetPresence(required any settingValue){
		var text = trim("" & arguments.settingValue);
		if(listFindNoCase("true,false,yes,no,1,0", text))
			return formatBooleanSettingValue(text) EQ "true";
		return arrayFindNoCase(parseIpList(text), variables.TEST_IP) GT 0;
	}

	public string function formatDisplayValue(required string settingName, required any value){
		return formatAllowedAdminIpListDisplay(arguments.value);
	}

	public string function getAllowedAdminIpListDisplay(){
		return formatAllowedAdminIpListDisplay(getAllowedAdminIpListRaw());
	}

	public string function formatAllowedAdminIpListDisplay(required any value){
		var ips = parseIpList(arguments.value);
		return arrayLen(ips) ? arrayToList(ips) : "(empty - all access allowed)";
	}

	public void function ensureTestIpAbsent(){
		removeIpFromAllowedAdminList(variables.TEST_IP);
	}

	public void function ensureTestIpPresent(){
		addIpToAllowedAdminList(variables.TEST_IP);
	}

	private void function addIpToAllowedAdminList(required string ipValue){
		var ips = parseIpList(getAllowedAdminIpListRaw());
		if(arrayFindNoCase(ips, trim(arguments.ipValue)) EQ 0)
			arrayAppend(ips, trim(arguments.ipValue));
		saveAllowedAdminIpList(ips);
	}

	private void function removeIpFromAllowedAdminList(required string ipValue){
		var ips = parseIpList(getAllowedAdminIpListRaw());
		var cleaned = [];
		for(var ip in ips){
			if(compareNoCase(trim(ip), trim(arguments.ipValue)) NEQ 0)
				arrayAppend(cleaned, ip);
		}
		saveAllowedAdminIpList(cleaned);
	}

	private string function getAllowedAdminIpListRaw(){
		if(isSecurityServiceAvailable()){
			var admin = loginAdmin();
			try {
				return trim("" & getSecurityService().getAllowedAdminIPList());
			}
			finally {
				logoutAdmin(admin);
			}
		}
		return readAllowedAdminIpListFromNeo();
	}

	private void function saveAllowedAdminIpList(required array ips){
		var normalized = normalizeIpList(arguments.ips);
		if(isSecurityServiceAvailable()){
			var admin = loginAdmin();
			try {
				getSecurityService().setAllowedAdminIPList(arrayToList(normalized));
				return;
			}
			finally {
				logoutAdmin(admin);
			}
		}
		writeAllowedAdminIpListToNeo(arrayToList(normalized));
	}

	private array function normalizeIpList(required array ips){
		var normalized = [];
		for(var ip in arguments.ips){
			var text = trim("" & ip);
			if(NOT len(text))
				continue;
			if(arrayFindNoCase(normalized, text) EQ 0)
				arrayAppend(normalized, text);
		}
		for(var defaultIp in parseIpList(variables.DEFAULT_ADMIN_IPS)){
			if(arrayFindNoCase(normalized, defaultIp) EQ 0)
				arrayAppend(normalized, defaultIp);
		}
		return normalized;
	}

	private array function parseIpList(required any value){
		var text = trim("" & arguments.value);
		if(NOT len(text))
			return [];
		var ips = [];
		for(var ip in listToArray(text)){
			ip = trim(ip);
			if(len(ip) AND arrayFindNoCase(ips, ip) EQ 0)
				arrayAppend(ips, ip);
		}
		return ips;
	}

	private string function readAllowedAdminIpListFromNeo(){
		var cfg = getSecurityConfigMap();
		var key = findStructKey(cfg, variables.ALLOWED_ADMIN_IP_LIST_KEY);
		if(NOT structKeyExists(cfg, key))
			return variables.DEFAULT_ADMIN_IPS;
		return trim("" & cfg[key]);
	}

	private void function writeAllowedAdminIpListToNeo(required string listValue){
		var cfg = getSecurityConfigMap();
		var key = findStructKey(cfg, variables.ALLOWED_ADMIN_IP_LIST_KEY);
		cfg[key] = trim("" & arguments.listValue);
		saveSecurityConfigMap(cfg);
	}

}
