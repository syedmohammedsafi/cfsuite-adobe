/**
* Packaging & Deployment (ColdFusion Archives & JEE Archives) configuration utility.
*/
component output="false" {

	variables.TEST_CAR_NAME = "ccsTestCarArchive";
	variables.TEST_JEE_NAME = "ccsTestJeeArchive";

	public function init(){
		variables.componentVersion = 1;
		return this;
	}

	public string function getTestCarName(){
		return variables.TEST_CAR_NAME;
	}

	public string function getTestJeeName(){
		return variables.TEST_JEE_NAME;
	}

	public string function getDefaultDeployFile(){
		return replace(server.coldfusion.rootdir, "/", "\", "all") & "\archives\ccsTestDeploy.car";
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

	// ==========================================
	// ColdFusion Archives (CAR) Helpers
	// ==========================================

	private any function getArchiveDeployService(){
		return createObject("java", "coldfusion.server.ServiceFactory").getArchiveDeployService();
	}

	public boolean function hasCarArchive(string archiveName = variables.TEST_CAR_NAME){
		try {
			var ads = getArchiveDeployService();
			var map = ads.getArchives();
			return isStruct(map) AND map.keyExists(arguments.archiveName);
		}
		catch(any e){
			return false;
		}
	}

	public void function ensureCarArchivePresent(string archiveName = variables.TEST_CAR_NAME){
		if(hasCarArchive(arguments.archiveName))
			return;
		try {
			var ads = getArchiveDeployService();
			ads.createArchive(arguments.archiveName);
		}
		catch(any e){}
	}

	public void function ensureCarArchiveAbsent(string archiveName = variables.TEST_CAR_NAME){
		if(NOT hasCarArchive(arguments.archiveName))
			return;
		try {
			var ads = getArchiveDeployService();
			var map = ads.getArchives();
			if(isStruct(map) AND map.keyExists(arguments.archiveName))
				map.remove(arguments.archiveName);
		}
		catch(any e){}
	}

	private string function getNeoArchivedeployPath(){
		return server.coldfusion.rootdir & "/lib/neo-archivedeploy.xml";
	}

	private struct function loadNeoArchivedeploy(){
		var filePath = getNeoArchivedeployPath();
		lock name="ccs-neo-archivedeploy" type="readonly" timeout="30" {
			if(NOT fileExists(filePath))
				return { archives = {}, log_archive = false, log_deploy = false };
			var content = trim(fileRead(filePath));
			if(NOT len(content))
				return { archives = {}, log_archive = false, log_deploy = false };
			var raw = "";
			cfwddx(action="WDDX2CFML", input=content, output="raw");
			if(isStruct(raw))
				return raw;
			return { archives = {}, log_archive = false, log_deploy = false };
		}
	}

	private void function saveNeoArchivedeploy(required struct configMap){
		var filePath = getNeoArchivedeployPath();
		lock name="ccs-neo-archivedeploy" type="exclusive" timeout="30" {
			var wddx = "";
			cfwddx(action="CFML2WDDX", input=arguments.configMap, output="wddx");
			fileWrite(filePath, wddx);
		}
	}

	public boolean function getCarLoggingSetting(required string settingName){
		var cfg = loadNeoArchivedeploy();
		var key = lCase(trim(arguments.settingName));
		if(key EQ "log_archive" OR key EQ "logarchive")
			return structKeyExists(cfg, "log_archive") ? toBoolean(cfg.log_archive) : false;
		if(key EQ "log_deploy" OR key EQ "logdeploy")
			return structKeyExists(cfg, "log_deploy") ? toBoolean(cfg.log_deploy) : false;
		return false;
	}

	public void function setCarLoggingSetting(required string settingName, required boolean value){
		var cfg = loadNeoArchivedeploy();
		var key = lCase(trim(arguments.settingName));
		if(key EQ "log_archive" OR key EQ "logarchive")
			cfg.log_archive = arguments.value;
		else if(key EQ "log_deploy" OR key EQ "logdeploy")
			cfg.log_deploy = arguments.value;
		saveNeoArchivedeploy(cfg);
	}

	// ==========================================
	// JEE Archives (WAR/EAR) Helpers
	// ==========================================

	private string function getJeePackagesDir(){
		return server.coldfusion.rootdir & "/packages";
	}

	private string function getJeeArchiveDir(string archiveName = variables.TEST_JEE_NAME){
		return getJeePackagesDir() & "/" & arguments.archiveName;
	}

	private string function getJeeArchiveConfigPath(string archiveName = variables.TEST_JEE_NAME){
		return getJeeArchiveDir(arguments.archiveName) & "/config/config.xml";
	}

	public boolean function hasJeeArchive(string archiveName = variables.TEST_JEE_NAME){
		return fileExists(getJeeArchiveConfigPath(arguments.archiveName));
	}

	private struct function buildDefaultJeeConfig(){
		return {
			appdir = replace(server.coldfusion.rootdir, "/", "\", "all") & "\wwwroot",
			distdir = replace(server.coldfusion.rootdir, "/", "\", "all") & "\packages\dist",
			archivetype = "WAR",
			profiletype = "WAR",
			contextroot = "",
			disabledebug = true,
			srcless = true,
			includeadmin = true,
			datasources = []
		};
	}

	public struct function readJeeArchiveConfig(string archiveName = variables.TEST_JEE_NAME){
		var cfgPath = getJeeArchiveConfigPath(arguments.archiveName);
		lock name="ccs-jee-package-#arguments.archiveName#" type="readonly" timeout="30" {
			if(NOT fileExists(cfgPath))
				return buildDefaultJeeConfig();
			try {
				var content = trim(fileRead(cfgPath));
				if(NOT len(content))
					return buildDefaultJeeConfig();
				var cfg = "";
				cfwddx(action="WDDX2CFML", input=content, output="cfg");
				if(isStruct(cfg))
					return cfg;
			}
			catch(any e){}
			return buildDefaultJeeConfig();
		}
	}

	public void function writeJeeArchiveConfig(string archiveName = variables.TEST_JEE_NAME, required struct configStruct){
		var arcDir = getJeeArchiveDir(arguments.archiveName);
		var cfgDir = arcDir & "/config";
		lock name="ccs-jee-package-#arguments.archiveName#" type="exclusive" timeout="30" {
			if(NOT directoryExists(cfgDir))
				directoryCreate(cfgDir);
			var cfgPath = cfgDir & "/config.xml";
			var wddx = "";
			cfwddx(action="CFML2WDDX", input=arguments.configStruct, output="wddx");
			fileWrite(cfgPath, wddx);
		}
	}

	public void function ensureJeeArchivePresent(string archiveName = variables.TEST_JEE_NAME){
		if(hasJeeArchive(arguments.archiveName))
			return;
		writeJeeArchiveConfig(arguments.archiveName, buildDefaultJeeConfig());
	}

	public void function ensureJeeArchiveAbsent(string archiveName = variables.TEST_JEE_NAME){
		var arcDir = getJeeArchiveDir(arguments.archiveName);
		lock name="ccs-jee-package-#arguments.archiveName#" type="exclusive" timeout="30" {
			if(directoryExists(arcDir)){
				try { directoryDelete(arcDir, true); } catch(any e){}
			}
		}
	}

	// ==========================================
	// Generic Getter / Setter Dispatch
	// ==========================================

	public string function getPackagingSetting(required string settingName, string apiArea = "archives"){
		var area = lCase(trim(arguments.apiArea));
		var key = lCase(trim(arguments.settingName));

		// Area: archives (ColdFusion Archives)
		if(area EQ "archives" OR area EQ "coldfusionarchives"){
			switch(key){
				case "archivename":
					return formatBooleanSettingValue(hasCarArchive(variables.TEST_CAR_NAME));
				case "archivefilename":
					return structKeyExists(application, "ccsTestDeployArchiveFile") ? application.ccsTestDeployArchiveFile : "";
				case "logarchive":
				case "log_archive":
					return formatBooleanSettingValue(getCarLoggingSetting("log_archive"));
				case "logdeploy":
				case "log_deploy":
					return formatBooleanSettingValue(getCarLoggingSetting("log_deploy"));
				default:
					throw(message="Unsupported ColdFusion Archives setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
		}

		// Area: jeeArchives / j2eepackaging
		if(area EQ "jeearchives" OR area EQ "j2eepackaging"){
			switch(key){
				case "archivename":
					return formatBooleanSettingValue(hasJeeArchive(variables.TEST_JEE_NAME));
				case "applicationdir":
				case "application_dir":
					if(NOT hasJeeArchive(variables.TEST_JEE_NAME))
						return "";
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					return structKeyExists(cfg, "appdir") ? trim("" & cfg.appdir) : "";
				case "distdir":
					if(NOT hasJeeArchive(variables.TEST_JEE_NAME))
						return "";
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					return structKeyExists(cfg, "distdir") ? trim("" & cfg.distdir) : "";
				case "archivetype":
				case "archive_type":
					if(NOT hasJeeArchive(variables.TEST_JEE_NAME))
						return "WAR";
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					if(structKeyExists(cfg, "archivetype"))
						return uCase(trim("" & cfg.archivetype));
					return structKeyExists(cfg, "profiletype") ? uCase(trim("" & cfg.profiletype)) : "WAR";
				case "contextroot":
				case "context_root":
					if(NOT hasJeeArchive(variables.TEST_JEE_NAME))
						return "";
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					return structKeyExists(cfg, "contextroot") ? trim("" & cfg.contextroot) : "";
				case "disabledebug":
				case "disable_debug":
					if(NOT hasJeeArchive(variables.TEST_JEE_NAME))
						return "true";
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					return formatBooleanSettingValue(structKeyExists(cfg, "disabledebug") ? cfg.disabledebug : true);
				case "srclessdeploy":
				case "srcless":
					if(NOT hasJeeArchive(variables.TEST_JEE_NAME))
						return "true";
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					return formatBooleanSettingValue(structKeyExists(cfg, "srcless") ? cfg.srcless : true);
				case "includeadmin":
					if(NOT hasJeeArchive(variables.TEST_JEE_NAME))
						return "true";
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					return formatBooleanSettingValue(structKeyExists(cfg, "includeadmin") ? cfg.includeadmin : true);
				default:
					throw(message="Unsupported JEE Archives setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
		}

		throw(message="Unsupported packaging area: #arguments.apiArea#", type="CCSTest.ConfigError");
	}

	public string function setPackagingSetting(required string settingName, required any settingValue, string apiArea = "archives"){
		var area = lCase(trim(arguments.apiArea));
		var key = lCase(trim(arguments.settingName));

		// Area: archives (ColdFusion Archives)
		if(area EQ "archives" OR area EQ "coldfusionarchives"){
			switch(key){
				case "archivename":
					if(toBoolean(arguments.settingValue))
						ensureCarArchivePresent(variables.TEST_CAR_NAME);
					else
						ensureCarArchiveAbsent(variables.TEST_CAR_NAME);
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				case "archivefilename":
					var fn = trim("" & arguments.settingValue);
					if(len(fn) AND fn NEQ "(empty)")
						application.ccsTestDeployArchiveFile = fn;
					else
						structDelete(application, "ccsTestDeployArchiveFile");
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				case "logarchive":
				case "log_archive":
					setCarLoggingSetting("log_archive", toBoolean(arguments.settingValue));
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				case "logdeploy":
				case "log_deploy":
					setCarLoggingSetting("log_deploy", toBoolean(arguments.settingValue));
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				default:
					throw(message="Unsupported ColdFusion Archives setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
		}

		// Area: jeeArchives / j2eepackaging
		if(area EQ "jeearchives" OR area EQ "j2eepackaging"){
			switch(key){
				case "archivename":
					if(toBoolean(arguments.settingValue))
						ensureJeeArchivePresent(variables.TEST_JEE_NAME);
					else
						ensureJeeArchiveAbsent(variables.TEST_JEE_NAME);
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				case "applicationdir":
				case "application_dir":
					ensureJeeArchivePresent(variables.TEST_JEE_NAME);
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					cfg.appdir = trim("" & arguments.settingValue);
					writeJeeArchiveConfig(variables.TEST_JEE_NAME, cfg);
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				case "distdir":
					ensureJeeArchivePresent(variables.TEST_JEE_NAME);
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					cfg.distdir = trim("" & arguments.settingValue);
					writeJeeArchiveConfig(variables.TEST_JEE_NAME, cfg);
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				case "archivetype":
				case "archive_type":
					ensureJeeArchivePresent(variables.TEST_JEE_NAME);
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					var typeVal = uCase(trim("" & arguments.settingValue));
					cfg.archivetype = typeVal;
					cfg.profiletype = typeVal;
					writeJeeArchiveConfig(variables.TEST_JEE_NAME, cfg);
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				case "contextroot":
				case "context_root":
					ensureJeeArchivePresent(variables.TEST_JEE_NAME);
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					cfg.contextroot = trim("" & arguments.settingValue);
					writeJeeArchiveConfig(variables.TEST_JEE_NAME, cfg);
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				case "disabledebug":
				case "disable_debug":
					ensureJeeArchivePresent(variables.TEST_JEE_NAME);
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					cfg.disabledebug = toBoolean(arguments.settingValue);
					writeJeeArchiveConfig(variables.TEST_JEE_NAME, cfg);
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				case "srclessdeploy":
				case "srcless":
					ensureJeeArchivePresent(variables.TEST_JEE_NAME);
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					cfg.srcless = toBoolean(arguments.settingValue);
					writeJeeArchiveConfig(variables.TEST_JEE_NAME, cfg);
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				case "includeadmin":
					ensureJeeArchivePresent(variables.TEST_JEE_NAME);
					var cfg = readJeeArchiveConfig(variables.TEST_JEE_NAME);
					cfg.includeadmin = toBoolean(arguments.settingValue);
					writeJeeArchiveConfig(variables.TEST_JEE_NAME, cfg);
					return getPackagingSetting(arguments.settingName, arguments.apiArea);
				default:
					throw(message="Unsupported JEE Archives setting: #arguments.settingName#", type="CCSTest.ConfigError");
			}
		}

		throw(message="Unsupported packaging area: #arguments.apiArea#", type="CCSTest.ConfigError");
	}

	public string function getNewSetValueForSetting(required string settingName, any currentValue = "", string apiArea = "archives"){
		var key = lCase(trim(arguments.settingName));
		switch(key){
			case "archivefilename":
				return len(trim("" & arguments.currentValue)) ? "" : getDefaultDeployFile();
			case "applicationdir":
			case "application_dir":
				var cur = trim("" & arguments.currentValue);
				var testPath = replace(server.coldfusion.rootdir, "/", "\", "all") & "\wwwroot\cfsuite";
				return compareNoCase(cur, testPath) EQ 0
					? (replace(server.coldfusion.rootdir, "/", "\", "all") & "\wwwroot")
					: testPath;
			case "distdir":
				var cur = trim("" & arguments.currentValue);
				var testPath = replace(server.coldfusion.rootdir, "/", "\", "all") & "\packages\dist";
				return compareNoCase(cur, testPath) EQ 0
					? (replace(server.coldfusion.rootdir, "/", "\", "all") & "\packages\deploy")
					: testPath;
			case "archivetype":
			case "archive_type":
				return uCase(trim("" & arguments.currentValue)) EQ "EAR" ? "WAR" : "EAR";
			case "contextroot":
			case "context_root":
				return len(trim("" & arguments.currentValue)) ? "" : "/ccsApp";
			default:
				return formatBooleanSettingValue(arguments.currentValue) EQ "true" ? "false" : "true";
		}
	}

	public boolean function scalarValuesMatch(required any expectedValue, required any actualValue, string settingName = "", string apiArea = "archives"){
		if(findNoCase("set FAILED", trim("" & arguments.actualValue)))
			return false;
		var key = lCase(trim(arguments.settingName));
		switch(key){
			case "archivefilename":
			case "applicationdir":
			case "application_dir":
			case "distdir":
			case "contextroot":
			case "context_root":
				return compareNoCase(trim("" & arguments.expectedValue), trim("" & arguments.actualValue)) EQ 0;
			case "archivetype":
			case "archive_type":
				return compareNoCase(trim("" & arguments.expectedValue), trim("" & arguments.actualValue)) EQ 0;
			default:
				return formatBooleanSettingValue(arguments.expectedValue) EQ formatBooleanSettingValue(arguments.actualValue);
		}
	}

	public string function formatDisplayValue(required string settingName, required any value, string apiArea = "archives"){
		var text = trim("" & arguments.value);
		var key = lCase(trim(arguments.settingName));
		switch(key){
			case "archivename":
				return formatBooleanSettingValue(arguments.value) EQ "true" ? "Configured" : "(empty)";
			case "archivefilename":
			case "contextroot":
			case "context_root":
				return len(text) ? text : "(empty)";
			case "archivetype":
			case "archive_type":
				return uCase(text);
			case "applicationdir":
			case "application_dir":
			case "distdir":
				return len(text) ? text : "(empty)";
			default:
				return formatBooleanSettingValue(arguments.value);
		}
	}
}
