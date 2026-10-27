/**
* Data & Services > Web Services admin page: "Web Service Version" dropdown and
* "Add/Edit ColdFusion Web Service" (Web Service Name / WSDL URL) registration.
*
* WEB SERVICE VERSION: via the raw coldfusion.server.ServiceFactory.getXmlRpcService(), not
* CFIDE.adminapi.extensions — confirmed both call paths hit the exact same underlying bug (see
* below), so the raw service is used directly rather than adding an unnecessary adminapi hop.
*
* KNOWN PRODUCT BUG: setWSEngineVersion() applies the new value locally, then throws a genuine
* java.lang.ClassCastException ("class coldfusion.util.Key cannot be cast to class
* java.lang.String") inside coldfusion.server.ServiceBase.doSerialize() ->
* CentralConfigClientUtil.pushToCCS() on every single call, in this CF2025 build — confirmed via
* direct testing through both CFIDE.adminapi.extensions.setWSVersion() and the raw XmlRpcService,
* and a real admin clicking "Update Web Service Version" in the browser hits the same failure.
* Because the exception happens during the CCS-push phase (after the local value is already
* applied), we swallow exactly this exception so the local set can still be tested — but the push
* to peer nodes never completes, so this setting cannot be verified as multi-node-synced here;
* the test that uses this util is scoped to nodesScope="currentPort" for that reason.
*
* WEB SERVICE REGISTRATION (Web Service Name + WSDL URL): CFIDE.adminapi.extensions.setWebService()
* / deleteWebservice() reliably create/update/delete entries in neo-xmlrpc.xml's "mappings" map —
* confirmed via direct testing, including update-in-place and delete-fully-removes. (Earlier in
* this environment registration silently no-op'd while the now-decommissioned testInstanceOne
* node was part of the CCS topology and repeatedly failing to report its own config — once that
* node was removed, writes started persisting reliably again.) However
* getWebServices()/getMappings() do NOT reflect live writes even from a fresh request afterward —
* a separate bug from the read side never refreshing its cache — so verification here reads
* neo-xmlrpc.xml directly instead, the same approach solrServerConfigUtil.cfc uses for Solr Server
* fields that also have no working live getter.
*/
component output="false" {

	public function init(){
		return this;
	}

	private any function getXmlRpcService(){
		return createObject("java", "coldfusion.server.ServiceFactory").getXmlRpcService();
	}

	private boolean function isKnownPushToCCSCastBug(required any e){
		return (
			arguments.e.type EQ "java.lang.ClassCastException"
			OR findNoCase("ClassCastException", arguments.e.type)
			OR findNoCase("ClassCastException", arguments.e.message)
		)
		AND findNoCase("coldfusion.util.Key", arguments.e.message)
		AND findNoCase("java.lang.String", arguments.e.message);
	}

	public string function getWSVersionSetting(){
		return trim("" & getXmlRpcService().getWSEngineVersion());
	}

	public string function setWSVersionSetting(required any settingValue){
		var value = trim("" & arguments.settingValue);
		try {
			getXmlRpcService().setWSEngineVersion(value);
		}
		catch(any e){
			if(NOT isKnownPushToCCSCastBug(e))
				rethrow;
			// expected: local value is already applied by this point, only the CCS push failed
		}
		return getWSVersionSetting();
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

	private string function getNeoXmlRpcPath(){
		var constants = getConstants();
		return server.coldfusion.rootdir & constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & constants.SYS_CONFIG.FILE_SEPARATOR & "neo-xmlrpc.xml";
	}

	private string function getConfigLockName(required string configPath){
		return "ccs-neo-xmlrpc-" & hash(arguments.configPath);
	}

	private array function loadConfigArray(){
		var configPath = getNeoXmlRpcPath();
		var lockName = getConfigLockName(configPath);
		var lastError = {};

		lock name="#lockName#" type="readonly" timeout="30" {
			for(var attempt = 1; attempt LTE 3; attempt++){
				try {
					var content = trim(fileRead(configPath));
					if(NOT len(content))
						return [];
					var cfg = "";
					cfwddx(action="WDDX2CFML", input=content, output="cfg");
					if(NOT isArray(cfg))
						throw(message="invalid neo-xmlrpc.xml structure", type="CCSTest.ConfigError");
					return cfg;
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

	private string function findStructKey(required struct data, required string key){
		for(var existingKey in arguments.data){
			if(compareNoCase(existingKey, arguments.key) EQ 0)
				return existingKey;
		}
		return arguments.key;
	}

	/**
	* index 1 of neo-xmlrpc.xml's array is the "mappings" struct: {webServiceName: wsdlUrl}.
	*/
	public string function getWebServiceMappingSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 1 OR NOT isStruct(cfg[1]))
			return "";
		var key = findStructKey(cfg[1], arguments.webServiceName);
		if(NOT structKeyExists(cfg[1], key))
			return "";
		return trim("" & cfg[1][key]);
	}

	private struct function getRuntime(){
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		var admin = adminUtil.createAdministrator();
		adminUtil.login(getConstants().CF_CONFIG);
		return {
			admin = admin,
			adminUtil = adminUtil,
			api = createObject("component", "CFIDE.adminapi.extensions")
		};
	}

	public string function setWebServiceMappingSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					// swallow "already absent" only - a genuine failure (e.g. CCS unavailable)
					// must surface, or callers wrongly believe cleanup succeeded
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=value,
					username="",
					password="",
					wsproxyserver="",
					wsproxyport="",
					wsproxyusername="",
					wsproxypassword="",
					wstimeout="",
					authtype="none",
					ntlmdomain="",
					workstation=""
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServiceMappingSetting(arguments.webServiceName);
	}

	/**
	* "Web Service Name" field test: the tracked value here is the NAME itself (present/absent),
	* not the WSDL URL — a fixed default WSDL is used internally to satisfy setWebService()'s
	* requirement for a URL, but that URL isn't the setting under test here (see
	* webServiceWsdlUrl.cfm for the URL field's own test, which reuses
	* getWebServiceMappingSetting/setWebServiceMappingSetting directly).
	*/
	variables.DEFAULT_TEST_WSDL_URL = "http://localhost:8500/cfsuite/ccssuite/testsuite/DataServices/webServices/ccsTestService.wsdl";

	public string function getWebServiceNameSetting(required string webServiceName){
		return len(getWebServiceMappingSetting(arguments.webServiceName)) ? arguments.webServiceName : "";
	}

	public string function setWebServiceNameSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		setWebServiceMappingSetting(arguments.webServiceName, len(value) ? variables.DEFAULT_TEST_WSDL_URL : "");
		return getWebServiceNameSetting(arguments.webServiceName);
	}

	/**
	* "Authentication Type" field test: the tracked value is the authtype string ("basic"/"ntlm"/
	* "none") for a fixed test service — index 10 of neo-xmlrpc.xml's array is the "authtypes"
	* struct: {webServiceName: authtype} (confirmed via direct testing). A fixed default WSDL is
	* used internally to satisfy setWebService()'s requirement for a URL, same as the Name test.
	*/
	public string function getWebServiceAuthTypeSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 10 OR NOT isStruct(cfg[10]))
			return "";
		var key = findStructKey(cfg[10], arguments.webServiceName);
		if(NOT structKeyExists(cfg[10], key))
			return "";
		return trim("" & cfg[10][key]);
	}

	public string function setWebServiceAuthTypeSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=variables.DEFAULT_TEST_WSDL_URL,
					username="",
					password="",
					wsproxyserver="",
					wsproxyport="",
					wsproxyusername="",
					wsproxypassword="",
					wstimeout="",
					authtype=value,
					ntlmdomain="",
					workstation=""
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServiceAuthTypeSetting(arguments.webServiceName);
	}

	/**
	* "Timeout" field test: the tracked value is the timeout-in-seconds string for a fixed test
	* service — index 8 of neo-xmlrpc.xml's array is the "timeouts" struct: {webServiceName:
	* timeout} (confirmed via direct testing; stored as a number, e.g. 30.0). A fixed default
	* WSDL is used internally to satisfy setWebService()'s requirement for a URL, same as the
	* Name/Authentication Type tests.
	*/
	public string function getWebServiceTimeoutSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 8 OR NOT isStruct(cfg[8]))
			return "";
		var key = findStructKey(cfg[8], arguments.webServiceName);
		if(NOT structKeyExists(cfg[8], key))
			return "";
		return trim("" & int(val(cfg[8][key])));
	}

	public string function setWebServiceTimeoutSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=variables.DEFAULT_TEST_WSDL_URL,
					username="",
					password="",
					wsproxyserver="",
					wsproxyport="",
					wsproxyusername="",
					wsproxypassword="",
					wstimeout=value,
					authtype="none",
					ntlmdomain="",
					workstation=""
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServiceTimeoutSetting(arguments.webServiceName);
	}

	/**
	* "Proxy Server" field test: the tracked value is the proxy hostname string for a fixed test
	* service — index 4 of neo-xmlrpc.xml's array is the "proxyservers" struct: {webServiceName:
	* proxyServer} (confirmed via direct testing). A real, resolvable hostname must be used —
	* setWebService() actually attempts to fetch the WSDL through the given proxy, and an
	* unresolvable host (e.g. a fake "proxy1.example.com") throws UnknownHostException and aborts
	* the whole registration; "localhost"/"127.0.0.1" resolve fine and don't block the fetch. A
	* fixed default WSDL is used internally to satisfy setWebService()'s requirement for a URL,
	* same as the Name/Authentication Type/Timeout tests. Proxy Server's real default is blank (no
	* proxy configured), so unlike Authentication Type/Timeout this follows the WSDL URL field's
	* plain empty-\>create-\>update pattern rather than needing a non-empty default first.
	*/
	public string function getWebServiceProxyServerSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 4 OR NOT isStruct(cfg[4]))
			return "";
		var key = findStructKey(cfg[4], arguments.webServiceName);
		if(NOT structKeyExists(cfg[4], key))
			return "";
		return trim("" & cfg[4][key]);
	}

	public string function setWebServiceProxyServerSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=variables.DEFAULT_TEST_WSDL_URL,
					username="",
					password="",
					wsproxyserver=value,
					wsproxyport="",
					wsproxyusername="",
					wsproxypassword="",
					wstimeout="",
					authtype="none",
					ntlmdomain="",
					workstation=""
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServiceProxyServerSetting(arguments.webServiceName);
	}

	/**
	* "Proxy Port" field test: the tracked value is the proxy port string for a fixed test
	* service — index 5 of neo-xmlrpc.xml's array is the "proxyports" struct: {webServiceName:
	* proxyPort} (confirmed via direct testing). Unlike Proxy Server, a port can be set with no
	* proxy server given at all — it's just stored, and doesn't get exercised as an actual proxy
	* connection unless a server is also set — so any real port number works here without risking
	* a WSDL-fetch failure. A fixed default WSDL is used internally to satisfy setWebService()'s
	* requirement for a URL. Proxy Port's real default is blank (no proxy configured), so like
	* Proxy Server this follows the WSDL URL field's plain empty-\>create-\>update pattern.
	*/
	public string function getWebServiceProxyPortSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 5 OR NOT isStruct(cfg[5]))
			return "";
		var key = findStructKey(cfg[5], arguments.webServiceName);
		if(NOT structKeyExists(cfg[5], key))
			return "";
		return trim("" & cfg[5][key]);
	}

	public string function setWebServiceProxyPortSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=variables.DEFAULT_TEST_WSDL_URL,
					username="",
					password="",
					wsproxyserver="",
					wsproxyport=value,
					wsproxyusername="",
					wsproxypassword="",
					wstimeout="",
					authtype="none",
					ntlmdomain="",
					workstation=""
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServiceProxyPortSetting(arguments.webServiceName);
	}

	/**
	* "Proxy Username" field test: the tracked value is the proxy username string for a fixed
	* test service — index 6 of neo-xmlrpc.xml's array is the "proxyusernames" struct
	* {webServiceName: proxyUsername} (confirmed via direct testing). Like Proxy Port, a username
	* set with no proxy server given isn't exercised as an actual proxy connection during
	* setWebService()'s WSDL fetch, so any value is safe here. A fixed default WSDL is used
	* internally to satisfy setWebService()'s requirement for a URL. Proxy Username's real
	* default is blank (no proxy configured), so this follows the same plain
	* empty-\>create-\>update pattern as Proxy Server/Proxy Port.
	*/
	public string function getWebServiceProxyUsernameSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 6 OR NOT isStruct(cfg[6]))
			return "";
		var key = findStructKey(cfg[6], arguments.webServiceName);
		if(NOT structKeyExists(cfg[6], key))
			return "";
		return trim("" & cfg[6][key]);
	}

	public string function setWebServiceProxyUsernameSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=variables.DEFAULT_TEST_WSDL_URL,
					username="",
					password="",
					wsproxyserver="",
					wsproxyport="",
					wsproxyusername=value,
					wsproxypassword="",
					wstimeout="",
					authtype="none",
					ntlmdomain="",
					workstation=""
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServiceProxyUsernameSetting(arguments.webServiceName);
	}

	/**
	* "Proxy Password" field test: the tracked value is the proxy password string for a fixed
	* test service — index 7 of neo-xmlrpc.xml's array is the "proxypasswords" struct
	* {webServiceName: proxyPassword} (confirmed via direct testing). Unlike the mail server and
	* Solr Server password fields tested elsewhere in this suite, this one is stored in PLAIN TEXT
	* in neo-xmlrpc.xml — confirmed via direct testing (no auto-encryption applied) — so this can
	* use a plain exact-match comparison instead of the leniency pattern those other password
	* fields need. Like Proxy Username, a password set with no proxy server given isn't exercised
	* as an actual proxy connection during setWebService()'s WSDL fetch, so any value is safe here.
	* Proxy Password's real default is blank, so this follows the same plain
	* empty-\>create-\>update pattern as Proxy Server/Port/Username.
	*/
	public string function getWebServiceProxyPasswordSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 7 OR NOT isStruct(cfg[7]))
			return "";
		var key = findStructKey(cfg[7], arguments.webServiceName);
		if(NOT structKeyExists(cfg[7], key))
			return "";
		return trim("" & cfg[7][key]);
	}

	public string function setWebServiceProxyPasswordSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=variables.DEFAULT_TEST_WSDL_URL,
					username="",
					password="",
					wsproxyserver="",
					wsproxyport="",
					wsproxyusername="",
					wsproxypassword=value,
					wstimeout="",
					authtype="none",
					ntlmdomain="",
					workstation=""
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServiceProxyPasswordSetting(arguments.webServiceName);
	}
/**
	* "Username" field test (wsusername): the tracked value is the web service authentication username
	* string for a fixed test service — index 2 of neo-xmlrpc.xml's array is the "usernames" struct
	* {webServiceName: username} (confirmed via direct testing). Stored in plain text. A fixed default
	* WSDL is used internally to satisfy setWebService()'s requirement for a URL. Username's real
	* default is blank (no authentication configured), following the standard empty->create->update pattern.
	*/
	public string function getWebServiceUsernameSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 2 OR NOT isStruct(cfg[2]))
			return "";
		var key = findStructKey(cfg[2], arguments.webServiceName);
		if(NOT structKeyExists(cfg[2], key))
			return "";
		return trim("" & cfg[2][key]);
	}

	public string function setWebServiceUsernameSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=variables.DEFAULT_TEST_WSDL_URL,
					username=value,
					password="",
					wsproxyserver="",
					wsproxyport="",
					wsproxyusername="",
					wsproxypassword="",
					wstimeout="",
					authtype="none",
					ntlmdomain="",
					workstation=""
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServiceUsernameSetting(arguments.webServiceName);
	}

	/**
	* "Password" field test (wspassword): the tracked value is the web service authentication password
	* string for a fixed test service — index 3 of neo-xmlrpc.xml's array is the "passwords" struct
	* {webServiceName: password} (confirmed via direct testing). Stored auto-encrypted by CF runtime
	* in neo-xmlrpc.xml; decrypted via PasswordUtils for exact plaintext comparison. A fixed default
	* WSDL is used internally to satisfy setWebService()'s requirement for a URL. Password's real default
	* is blank, following the standard empty->create->update pattern.
	*/
	public string function getWebServicePasswordSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 3 OR NOT isStruct(cfg[3]))
			return "";
		var key = findStructKey(cfg[3], arguments.webServiceName);
		if(NOT structKeyExists(cfg[3], key))
			return "";
		var encPass = trim("" & cfg[3][key]);
		if(NOT len(encPass))
			return "";
		try {
			var pu = createObject("java", "coldfusion.util.PasswordUtils");
			return pu.decryptPassword(encPass, pu.getInstance().getSeedValue());
		}
		catch(any e){
			return encPass;
		}
	}

	public string function setWebServicePasswordSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=variables.DEFAULT_TEST_WSDL_URL,
					username="",
					password=value,
					wsproxyserver="",
					wsproxyport="",
					wsproxyusername="",
					wsproxypassword="",
					wstimeout="",
					authtype="none",
					ntlmdomain="",
					workstation=""
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServicePasswordSetting(arguments.webServiceName);
	}

	/**
	* "Domain" field test (wsdomain): NTLM authentication domain for SOAP web services.
	* Index 11 of neo-xmlrpc.xml's array is the "ntlmdomains" struct {webServiceName: ntlmdomain}
	* (confirmed via direct testing). Stored in plain text. A fixed default WSDL is used internally.
	* Domain's real default is blank, following the standard empty->create->update pattern.
	*/
	public string function getWebServiceDomainSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 11 OR NOT isStruct(cfg[11]))
			return "";
		var key = findStructKey(cfg[11], arguments.webServiceName);
		if(NOT structKeyExists(cfg[11], key))
			return "";
		return trim("" & cfg[11][key]);
	}

	public string function setWebServiceDomainSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=variables.DEFAULT_TEST_WSDL_URL,
					username="",
					password="",
					wsproxyserver="",
					wsproxyport="",
					wsproxyusername="",
					wsproxypassword="",
					wstimeout="",
					authtype="none",
					ntlmdomain=value,
					workstation=""
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServiceDomainSetting(arguments.webServiceName);
	}

	/**
	* "Workstation" field test (wsworkstation): NTLM workstation name for SOAP web services.
	* Index 12 of neo-xmlrpc.xml's array is the "workstations" struct {webServiceName: workstation}
	* (confirmed via direct testing). Stored in plain text. A fixed default WSDL is used internally.
	* Workstation's real default is blank, following the standard empty->create->update pattern.
	*/
	public string function getWebServiceWorkstationSetting(required string webServiceName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 12 OR NOT isStruct(cfg[12]))
			return "";
		var key = findStructKey(cfg[12], arguments.webServiceName);
		if(NOT structKeyExists(cfg[12], key))
			return "";
		return trim("" & cfg[12][key]);
	}

	public string function setWebServiceWorkstationSetting(required string webServiceName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteWebservice(arguments.webServiceName);
				}
				catch(any e){
					if(NOT findNoCase("not found", e.message) AND NOT findNoCase("does not exist", e.message))
						rethrow;
				}
			}
			else {
				runtime.api.setWebService(
					name=arguments.webServiceName,
					path=variables.DEFAULT_TEST_WSDL_URL,
					username="",
					password="",
					wsproxyserver="",
					wsproxyport="",
					wsproxyusername="",
					wsproxypassword="",
					wstimeout="",
					authtype="none",
					ntlmdomain="",
					workstation=value
				);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getWebServiceWorkstationSetting(arguments.webServiceName);
	}
}
