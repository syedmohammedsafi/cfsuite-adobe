/**
* Data & Services > REST Services admin page: "Add/Edit REST Service" registration.
*
* CFIDE.adminapi.extensions.registerRESTService(path, name, host, isdef) / deleteRESTService(path)
* reliably create/delete entries in neo-jaxrs.xml. getRESTServices() does reflect live writes
* immediately (confirmed via direct testing — unlike Web Services' getWebServices()), but calling
* it repeatedly logs in/out of the admin API each time, which is too slow for this suite's
* multi-node verification retry loop (up to 30 rapid polls) — confirmed via direct testing that
* this caused the loop to give up before ever seeing the true state. So reads here go straight to
* neo-jaxrs.xml instead, the same approach used for Solr Server/Web Services fields.
*
* Root Path is the true unique key here (deleteRESTService() takes only a path, not the mapping
* name) — matching neo-jaxrs.xml's own structure: {rootPath: [mapping, host, isDefault]}.
* Registration actually initializes the target as a REST application (deploys it), so the target
* folder must exist AND contain at least one valid `component rest="true"` CFC — an empty folder
* or nonexistent path throws ("REST service can not be registered." / "Application ... could not
* be initialized."), analogous to Web Services needing a real, reachable WSDL. A minimal test CFC
* (ping.cfc) is committed alongside this test for that reason.
*
* CRITICAL: this suite's own REST mapping ("ccs", rooted at .../ccssuite/restCFCs) is live
* infrastructure registered at application startup (see appBootstrap.cfc) and used internally —
* every function here must only ever target the dedicated test path below, never that mapping.
*/
component output="false" {

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

	/**
	* Fixed dedicated test path — never the live "ccs" REST mapping. Its CFC (ping.cfc) sits
	* alongside this util so registration always has a real, valid REST app to initialize.
	*/
	public string function getTestRootPath(){
		return server.coldfusion.rootdir & "\wwwroot\cfsuite\ccssuite\testsuite\DataServices\restServices";
	}

	private string function getNeoJaxrsPath(){
		var constants = getConstants();
		return server.coldfusion.rootdir & constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & constants.SYS_CONFIG.FILE_SEPARATOR & "neo-jaxrs.xml";
	}

	private string function getConfigLockName(required string configPath){
		return "ccs-neo-jaxrs-" & hash(arguments.configPath);
	}

	private array function loadConfigArray(){
		var configPath = getNeoJaxrsPath();
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
						throw(message="invalid neo-jaxrs.xml structure", type="CCSTest.ConfigError");
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
	* index 2 of neo-jaxrs.xml's array is the mappings struct: {rootPath: [mapping, host, isDefault]}.
	*/
	public string function getRestServiceRootPathSetting(required string mappingName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 2 OR NOT isStruct(cfg[2]))
			return "";
		var testPath = getTestRootPath();
		var key = findStructKey(cfg[2], testPath);
		if(NOT structKeyExists(cfg[2], key))
			return "";
		return testPath;
	}

	public string function setRestServiceRootPathSetting(required string mappingName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		var testPath = getTestRootPath();
		try {
			if(NOT len(value)){
				try {
					runtime.api.deleteRESTService(testPath);
				}
				catch(any e){
					// already absent - nothing to delete
				}
			}
			else {
				runtime.api.registerRESTService(path=testPath, name=arguments.mappingName, host="localhost:#CGI.SERVER_PORT#", isdef=false);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getRestServiceRootPathSetting(arguments.mappingName);
	}

	/**
	* "Host [:Port]" field test: same dedicated test path/mapping as Root Path above (Root Path is
	* the true unique key in neo-jaxrs.xml — registerRESTService() re-registering the same path just
	* updates its [mapping, host, isDefault] entry in place), varying only the host string. Never
	* touches the live "ccs" mapping.
	*/
	public string function getRestServiceHostSetting(required string mappingName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 2 OR NOT isStruct(cfg[2]))
			return "";
		var testPath = getTestRootPath();
		var key = findStructKey(cfg[2], testPath);
		if(NOT structKeyExists(cfg[2], key) OR NOT isArray(cfg[2][key]) OR arrayLen(cfg[2][key]) LT 2)
			return "";
		return trim("" & cfg[2][key][2]);
	}

	public string function setRestServiceHostSetting(required string mappingName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		var testPath = getTestRootPath();
		try {
			if(NOT len(value)){
				try { runtime.api.deleteRESTService(testPath); }
				catch(any e){}
			}
			else {
				runtime.api.registerRESTService(path=testPath, name="CCSTestRestService", host=value, isdef=false);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getRestServiceHostSetting(arguments.mappingName);
	}

	/**
	* "Service Mapping" field test: same dedicated test path as Root Path above, varying only the
	* mapping/name string. Never touches the live "ccs" mapping.
	*/
	public string function getRestServiceMappingSetting(required string mappingName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 2 OR NOT isStruct(cfg[2]))
			return "";
		var testPath = getTestRootPath();
		var key = findStructKey(cfg[2], testPath);
		if(NOT structKeyExists(cfg[2], key) OR NOT isArray(cfg[2][key]) OR arrayLen(cfg[2][key]) LT 1)
			return "";
		return trim("" & cfg[2][key][1]);
	}

	public string function setRestServiceMappingSetting(required string mappingName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		var testPath = getTestRootPath();
		try {
			if(NOT len(value)){
				try { runtime.api.deleteRESTService(testPath); }
				catch(any e){}
			}
			else {
				runtime.api.registerRESTService(path=testPath, name=value, host="localhost:#CGI.SERVER_PORT#", isdef=false);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getRestServiceMappingSetting(arguments.mappingName);
	}

	/**
	* "Set as default application" field test: same dedicated test path as Root Path above. Only one
	* default application is allowed per host — before setting true, this checks neo-jaxrs.xml for
	* any OTHER path already marked default for this same host and fails loudly instead of silently
	* stealing that live default, the same caution this file's header already calls out for the
	* "ccs" mapping.
	*/
	public string function getRestServiceIsDefaultSetting(required string mappingName){
		var cfg = loadConfigArray();
		if(arrayLen(cfg) LT 2 OR NOT isStruct(cfg[2]))
			return "";
		var testPath = getTestRootPath();
		var key = findStructKey(cfg[2], testPath);
		if(NOT structKeyExists(cfg[2], key) OR NOT isArray(cfg[2][key]) OR arrayLen(cfg[2][key]) LT 3)
			return "";
		return (cfg[2][key][3] EQ true) ? "true" : "false";
	}

	public string function setRestServiceIsDefaultSetting(required string mappingName, required any settingValue){
		var value = trim("" & arguments.settingValue);
		var runtime = getRuntime();
		var testPath = getTestRootPath();
		var testHost = "localhost:#CGI.SERVER_PORT#";
		try {
			if(NOT len(value)){
				try { runtime.api.deleteRESTService(testPath); }
				catch(any e){}
			}
			else if(value EQ "true"){
				var cfg = loadConfigArray();
				if(arrayLen(cfg) GTE 2 AND isStruct(cfg[2])){
					for(var existingPath in cfg[2]){
						if(compareNoCase(existingPath, testPath) EQ 0)
							continue;
						var entry = cfg[2][existingPath];
						if(isArray(entry) AND arrayLen(entry) GTE 3 AND trim("" & entry[2]) EQ testHost AND entry[3] EQ true)
							throw(message="Another REST service (#existingPath#) is already the default for host #testHost# — refusing to steal it.", type="CCSTest.ConfigError");
					}
				}
				runtime.api.registerRESTService(path=testPath, name="CCSTestRestService", host=testHost, isdef=true);
			}
			else {
				runtime.api.registerRESTService(path=testPath, name="CCSTestRestService", host=testHost, isdef=false);
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getRestServiceIsDefaultSetting(arguments.mappingName);
	}
}
