/**
* Unified read/write for ColdFusion Administrator server settings tests.
* Dispatches by setting name + serverSettings subfolder (area) to the correct util/API.
*/
component output="false" {

	variables.SCOPE_SETTINGS = "sessionscopetimeout,applicationscopetimeout,sessionscopemaxtimeout,applicationscopemaxtimeout";
	variables.MEMORY_SCOPE_SETTINGS = "enablej2eesessions,enablesessionscope,enableapplicationscope,sessionscopetimeout,applicationscopetimeout,sessionscopemaxtimeout,applicationscopemaxtimeout";

	public function init(){
		return this;
	}

	private struct function getConstants(){
		if(isDefined("application") AND structKeyExists(application, "constants") AND isStruct(application.constants))
			return application.constants;
		if(NOT structKeyExists(request, "constants") OR NOT isStruct(request.constants))
			request.constants = new cfsuite.ccssuite.constants().init();
		return request.constants;
	}

	private void function ensureConstants(){
		getConstants();
	}

	private string function normalizeKey(required string settingName){
		return lCase(trim(arguments.settingName));
	}

	private string function normalizeArea(required string apiArea){
		return lCase(trim(arguments.apiArea));
	}

	private boolean function isDebuggingArea(required string apiArea){
		return listFindNoCase(
			"debugoutputsettings,loggingsettings,debuggingipaddress,developerprofile,debuggersettings,systemprobes",
			normalizeArea(arguments.apiArea)
		) GT 0;
	}

	private boolean function isScopeSetting(required string settingKey){
		return listFindNoCase(variables.SCOPE_SETTINGS, arguments.settingKey) GT 0;
	}

	private boolean function isMemoryScopeSetting(required string settingKey){
		return listFindNoCase(variables.MEMORY_SCOPE_SETTINGS, arguments.settingKey) GT 0;
	}

	private string function normalizeScopeTimeout(required string timeoutValue){
		var parts = listToArray(trim(arguments.timeoutValue), ",");
		while(arrayLen(parts) LT 4)
			arrayAppend(parts, "0");
		return arrayToList(parts, ",");
	}

	private string function formatSettingValue(any value = ""){
		if(NOT structKeyExists(arguments, "value") OR isNull(arguments.value))
			return "";
		if(isBoolean(arguments.value) AND NOT isNumeric(arguments.value))
			return arguments.value ? "true" : "false";
		var text = lCase(trim("" & arguments.value));
		if(listFindNoCase("true,yes", text))
			return "true";
		if(listFindNoCase("false,no", text))
			return "false";
		return trim("" & arguments.value);
	}

	private string function resolveRuntimePropertyName(required string settingName){
		switch(normalizeKey(arguments.settingName)){
			case "usejavaasregexengine":
				return "useJavaRegexEngine";
			case "disableservicefactory":
				return "disableServiceFactory";
			case "sessioncookiesamesite":
				return "sessionCookieSamesite";
			case "maxunzipratio":
				return "MaxUnzipRatio";
			case "reportthreads":
				return "ReportThread";
			default:
				return arguments.settingName;
		}
	}

	private string function resolveCacheEngineName(required numeric engineIndex){
		switch(arguments.engineIndex){
			case 0: return "ehcache";
			case 1: return "jcs";
			case 2: return "redis";
			case 3: return "memcached";
			default: throw(message="Unknown server cache engine index: #arguments.engineIndex#", type="CCSTest.ConfigError");
		}
	}

	private string function normalizeSessionCookieSamesite(required any value){
		return lCase(trim("" & arguments.value));
	}

	private any function readRuntimeProperty(required any runtimeApi, required string settingName){
		var propertyName = resolveRuntimePropertyName(arguments.settingName);
		var value = "";
		try {
			value = arguments.runtimeApi.getRuntimeProperty(propertyName);
		}
		catch(any e){
			return "";
		}
		if(isNull(value))
			return "";
		return value;
	}

	private any function coerceRuntimePropertyValue(required string settingName, required any settingValue){
		if(normalizeKey(arguments.settingName) EQ "sessioncookiesamesite")
			return normalizeSessionCookieSamesite(arguments.settingValue);

		if(normalizeKey(arguments.settingName) EQ "appcfclookuporder")
			return val(arguments.settingValue);

		if(isBoolean(arguments.settingValue) AND NOT isNumeric(arguments.settingValue))
			return arguments.settingValue;

		var normalized = formatSettingValue(arguments.settingValue);
		if(normalized EQ "true" OR normalized EQ "false")
			return normalized EQ "true";

		return arguments.settingValue;
	}

	private boolean function isCommaListSetting(required string settingKey){
		return listFindNoCase("blockedextforfileupload,compileextforinclude", arguments.settingKey) GT 0;
	}

	private string function normalizeCommaList(required string listValue){
		var items = [];
		for(var item in listToArray(arguments.listValue, ",", false, true)){
			item = uCase(trim(item));
			if(len(item) AND arrayFindNoCase(items, item) EQ 0)
				arrayAppend(items, item);
		}
		arraySort(items, "textnocase");
		return arrayToList(items, ",");
	}

	private boolean function commaListsMatch(required any left, required any right){
		return normalizeCommaList(arguments.left) EQ normalizeCommaList(arguments.right);
	}

	private string function normalizeWebDirectoryPath(required string pathValue){
		var path = replace(trim(arguments.pathValue), "\", "/", "all");
		if(len(path) AND right(path, 1) NEQ "/")
			path &= "/";
		return path;
	}

	private string function normalizeAbsolutePath(required string pathValue){
		var path = trim(arguments.pathValue);
		path = replace(path, "/", "\", "all");
		while(find("\\", path))
			path = replace(path, "\\", "\", "all");
		return path;
	}

	private boolean function pathSettingsMatch(required string settingKey, required any actualValue, required any requestedValue){
		if(arguments.settingKey EQ "cfformscriptsrc")
			return normalizeWebDirectoryPath(arguments.actualValue) EQ normalizeWebDirectoryPath(arguments.requestedValue);
		if(arguments.settingKey EQ "ormsearchindexdirectory")
			return compareNoCase(normalizeAbsolutePath(arguments.actualValue), normalizeAbsolutePath(arguments.requestedValue)) EQ 0;
		if(arguments.settingKey EQ "cachepath")
			return compareNoCase(normalizeAbsolutePath(arguments.actualValue), normalizeAbsolutePath(arguments.requestedValue)) EQ 0;
		return false;
	}

	private string function formatRuntimeSettingValue(required string settingName, required any value){
		switch(normalizeKey(arguments.settingName)){
			case "cfformscriptsrc":
				return normalizeWebDirectoryPath(arguments.value);
			case "ormsearchindexdirectory":
				return normalizeAbsolutePath(arguments.value);
			case "sessioncookiesamesite":
				return normalizeSessionCookieSamesite(arguments.value);
			default:
				return formatSettingValue(arguments.value);
		}
	}

	private boolean function isClientStoreSetting(required string settingKey){
		return listFindNoCase(
			"clientstoredatasource,clientstoredescription,clientstorepurge,clientstorepurgedays,clientstoredisableglobals",
			arguments.settingKey
		) GT 0;
	}

	private boolean function isClientStoreBooleanTrue(required any value){
		var text = lCase(trim("" & arguments.value));
		return listFindNoCase("true,yes,1", text) GT 0;
	}

	private string function formatClientStoreBoolean(required boolean value){
		return arguments.value ? "YES" : "NO";
	}

	private struct function getTestClientStore(required any runtimeApi){
		var ds = getClientVariablesTestDatasourceName();
		var stores = arguments.runtimeApi.getClientStores();
		if(NOT isStruct(stores) OR NOT structKeyExists(stores, ds))
			return {};
		var store = stores[ds];
		return {
			description = structKeyExists(store, "DESCRIPTION") ? trim("" & store.DESCRIPTION) : "",
			disable_globals = structKeyExists(store, "DISABLE_GLOBALS") ? isClientStoreBooleanTrue(store.DISABLE_GLOBALS) : false,
			purge = structKeyExists(store, "PURGE") ? isClientStoreBooleanTrue(store.PURGE) : true,
			timeout = structKeyExists(store, "TIMEOUT") ? val(store.TIMEOUT) : 90,
			name = ds,
			type = "JDBC",
			dsn = ds
		};
	}

	private void function writeTestClientStore(required any runtimeApi, required struct store){
		arguments.runtimeApi.setClientStore(
			arguments.store.description,
			arguments.store.disable_globals,
			arguments.store.name,
			arguments.store.purge,
			arguments.store.timeout,
			arguments.store.type,
			arguments.store.dsn
		);
	}

	private any function getClientStoreSettingValue(required any runtimeApi, required string settingName){
		var key = normalizeKey(arguments.settingName);
		var store = getTestClientStore(arguments.runtimeApi);
		switch(key){
			case "clientstoredatasource":
				return structIsEmpty(store) ? "" : getClientVariablesTestDatasourceName();
			case "clientstoredescription":
				return structKeyExists(store, "description") ? store.description : "";
			case "clientstorepurge":
				return structIsEmpty(store) ? "" : formatClientStoreBoolean(store.purge);
			case "clientstorepurgedays":
				return structIsEmpty(store) ? "" : trim("" & store.timeout);
			case "clientstoredisableglobals":
				return structIsEmpty(store) ? "" : formatClientStoreBoolean(store.disable_globals);
			default:
				throw(message="Unsupported client store setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	private any function setClientStoreSettingValue(required any runtimeApi, required string settingName, required any settingValue){
		var key = normalizeKey(arguments.settingName);
		var store = getTestClientStore(arguments.runtimeApi);
		if(structIsEmpty(store)){
			store = {
				description = "",
				disable_globals = false,
				purge = true,
				timeout = 90,
				name = getClientVariablesTestDatasourceName(),
				type = "JDBC",
				dsn = getClientVariablesTestDatasourceName()
			};
		}
		switch(key){
			case "clientstoredatasource":
				var ds = trim("" & arguments.settingValue);
				if(len(ds))
					writeTestClientStore(arguments.runtimeApi, store);
				else
					arguments.runtimeApi.deleteClientStore(getClientVariablesTestDatasourceName());
				break;
			case "clientstoredescription":
				store.description = trim("" & arguments.settingValue);
				writeTestClientStore(arguments.runtimeApi, store);
				break;
			case "clientstorepurge":
				store.purge = isClientStoreBooleanTrue(arguments.settingValue);
				writeTestClientStore(arguments.runtimeApi, store);
				break;
			case "clientstorepurgedays":
				store.timeout = val(arguments.settingValue);
				writeTestClientStore(arguments.runtimeApi, store);
				break;
			case "clientstoredisableglobals":
				store.disable_globals = isClientStoreBooleanTrue(arguments.settingValue);
				writeTestClientStore(arguments.runtimeApi, store);
				break;
			default:
				throw(message="Unsupported client store setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		return getClientStoreSettingValue(arguments.runtimeApi, arguments.settingName);
	}

	public string function resolveHandlerType(required string settingName, string apiArea = ""){
		var key = normalizeKey(arguments.settingName);
		var area = normalizeArea(arguments.apiArea);

		if(isDebuggingArea(area))
			return "debugging";

		switch(area){
			case "mail":
				return "mail";
			case "scheduledtasks":
				return "scheduledTasks";
			case "fontmanagement":
				return "fontManagement";
			case "websocket":
				return "websocket";
			case "sslcertificate":
				return "sslCertificate";
			case "caching":
				if(key EQ "servercachetype")
					return "cacheEngine";
				return "cache";
			case "charting":
				return "charting";
			case "document":
				return "document";
			case "clientvariables":
				if(isClientStoreSetting(key))
					return "clientVariables";
				return "scope";
			case "monitoring":
				return "monitoring";
			case "memoryvariables":
				if(new cfsuite.ccssuite.utils.memoryVariablesConfigUtil().init().isStorageSetting(arguments.settingName))
					return "memoryStorage";
				return isMemoryScopeSetting(key) ? "scope" : "runtime";
			case "mappings":
				return "mappings";
		}

		if(key EQ "watch.interval" OR key EQ "watch.watchenabled")
			return "watch";
		if(listFindNoCase("corepoolsizecloudservices,maxpoolsizecloudservices,keepalivetimecloudservices", key))
			return "cloudServicesPool";
		if(key EQ "enablecspnonceforscript")
			return "cspNonce";
		if(key EQ "uuidcftoken")
			return "uuidCFToken";
		if(key EQ "maxthreadcountforparallelcalls")
			return "maxThreadCount";
		if(key EQ "restdiscovery")
			return "restDiscovery";
		if(isScopeSetting(key) AND area EQ "memoryvariables")
			return "scope";

		return "runtime";
	}

	public boolean function requiresPeerInstancePropagation(required string settingName, string apiArea = ""){
		var area = normalizeArea(arguments.apiArea);
		if(area EQ "systemprobes")
			return false;
		if(area EQ "document" OR isDebuggingArea(area) OR area EQ "settings")
			return true;
		// Web Services registration (neo-xmlrpc.xml "mappings") is not part of what real CCS
		// replicates for this service — confirmed via direct polling — so peer nodes need the
		// same active push used for AI Services/extensions/security, rather than passively
		// waiting on CCS.
		if(area EQ "webservices")
			return true;
		// REST Services registration (neo-jaxrs.xml): DO NOT enable active push here.
		// Confirmed via direct testing on two separate occasions: (1) repeated register/deploy
		// cycles across nodes hung CF's entire JAX-RS/REST layer, requiring a server restart to
		// clear; (2) even a single careful run afterward left NewInstanceForTesting's live "ccs"
		// REST mapping silently corrupted (its root path got overwritten to point at cfusion's
		// restCFCs folder instead of its own) with no visible error. Root Path is also a
		// per-instance filesystem path anyway, so there's nothing meaningful to push identically.
		if(area EQ "restservices")
			return false;
		// SSL Certificate config lives in each instance's own runtime/conf/server.xml (a Tomcat
		// connector file), not in any neo-*.xml file CCS replicates, so there's nothing for CCS to
		// sync passively — confirmed via direct testing, same as mail's keystore fields below. This
		// needs the same active push, scoped to the prime node's own cluster/environment
		// (testDriver.propagateDocumentSettingToPrimePeers -> getNodeKeysInPrimeEnvironment()), so a
		// node in a different cluster/environment (e.g. a production peer) is correctly left alone.
		if(area EQ "sslcertificate")
			return true;
		// Mail's keystore/signing/credential fields never arrive via passive CCS, confirmed by direct
		// measurement: every other mail setting (server, port, username, spooldir, sign, usessl, ...)
		// converges to a peer in under a second, while keystore, keyalias, keystorepassword, keypassword,
		// and password sat unchanged on a peer for 2+ minutes across repeated isolated runs, even
		// starting from an already-non-empty value. These need the same active push used for
		// AI Services/extensions/security rather than passively waiting on CCS.
		if(area EQ "mail" AND listFindNoCase("keystore,keystorepassword,keyalias,keypassword,password", normalizeKey(arguments.settingName)))
			return true;
		// Cloud Credentials registration (neo-cloudcredential.xml): confirmed via direct testing
		// that a newly-added credential never appears in the prime node's own CCS version history
		// at all (unlike neo-mail.xml, which gets a fresh version on every change) — real CCS does
		// not track this file in this environment, the same situation already confirmed for Web
		// Services' neo-xmlrpc.xml, so the same active-push mechanism is safe here.
		if(area EQ "cloudcredentials")
			return true;
		// PDF Service registration (simulated): active push required since CCS does not reliably sync this config
		if(area EQ "pdfservices")
			return true;
		// GraphQL Client Configuration (neo-graphql-config.xml): confirmed via direct testing that a
		// newly-added client configuration DOES create a real CCS version on the prime node (unlike
		// Cloud Credentials, where no version is ever created), but never appears in a peer node's
		// own neo-graphql-config.xml even after ~80 seconds of direct polling, with nothing logged
		// on the peer either — CCS registers the change but never delivers it. Active push is safe
		// here since there's no organic delivery to race against.
		if(area EQ "graphql")
			return true;
		// Cloud Configuration's Proxy Password and Proxy Endpoint
		// (httpClientConfig.proxyConfiguration.password / .endpoint): confirmed via direct testing
		// that these specific fields never organically sync to a peer even after 3+ minutes of
		// polling, unlike every other Cloud Configuration field (Config Alias, Service Name,
		// timeouts, booleans, Ntlm Domain/Workstation, Proxy Username all sync within ~1s). Same
		// pattern as mail's password/keystore fields — credential/endpoint-shaped values appear to
		// be excluded from real CCS's file-replication scope.
		if(area EQ "cloudconfiguration" AND listFindNoCase("ccstestcloudconfigproxypassword,ccstestcloudconfigproxyendpoint", normalizeKey(arguments.settingName)))
			return true;
		// Package Manager's credential/host fields (neo_updates.xml, via UpdateService): confirmed
		// via direct testing that SETTING a value organically syncs to a peer fine, but RESTORING
		// back to empty afterward does not — the peer is left with stale test residue indefinitely
		// (30s+ direct polling, no change). Same asymmetric-clear pattern as mail/cloud config's
		// credential fields. Package Manager's apiArea is its test-folder name ("updateSettings"),
		// derived automatically from the script path — not the "PackageManager" menu name itself.
		if(area EQ "updatesettings" AND listFindNoCase("notificationemails,notificationfromemail,proxyhost,proxyusername,proxypassword", normalizeKey(arguments.settingName)))
			return true;
		return listFindNoCase(
			"cspNonce,watch,maxThreadCount",
			resolveHandlerType(arguments.settingName, arguments.apiArea)
		) GT 0;
	}

	public any function getSetting(required string settingName, string apiArea = ""){
		ensureConstants();
		setting requesttimeout=120;
		var handler = resolveHandlerType(arguments.settingName, arguments.apiArea);
		var runtime = "";

		switch(handler){
			case "watch":
				if(normalizeKey(arguments.settingName) EQ "watch.watchenabled")
					return new cfsuite.ccssuite.utils.watchConfigUtil().init().getWatchEnabled() ? "true" : "false";
				return new cfsuite.ccssuite.utils.watchConfigUtil().init().getWatchInterval();
			case "cloudServicesPool":
				return new cfsuite.ccssuite.utils.cloudServicesThreadPoolConfigUtil().init().getCloudServicesPoolSetting(arguments.settingName);
			case "cacheEngine":
				runtime = getRuntime();
				try {
					return trim("" & runtime.api.getRuntimeProperty("serverCacheType"));
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			case "cspNonce":
				return new cfsuite.ccssuite.utils.cspNonceUtil().init().getCspNonceEnabled() ? "true" : "false";
			case "uuidCFToken":
				runtime = getRuntime();
				try {
					return formatSettingValue(runtime.api.getScopeProperty("UUIDCFToken"));
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			case "maxThreadCount":
				return trim("" & new cfsuite.ccssuite.utils.maxThreadCountConfigUtil().init().getMaxThreadCountForParallelCalls());
			case "cache":
				return trim(new cfsuite.ccssuite.utils.cacheConfigUtil().init().getCacheSetting(arguments.settingName));
			case "mail":
				return trim("" & getMailSetting(arguments.settingName));
			case "scheduledTasks":
				return new cfsuite.ccssuite.utils.scheduledTasksConfigUtil().init().getSetting(arguments.settingName);
			case "fontManagement":
				return new cfsuite.ccssuite.utils.fontManagementConfigUtil().init().getSetting(arguments.settingName);
			case "websocket":
				return trim("" & getWebSocketSetting(arguments.settingName));
			case "sslCertificate":
				return trim("" & getSslCertificateSetting(arguments.settingName));
			case "charting":
				return trim("" & getChartingSetting(arguments.settingName));
			case "document":
				return trim("" & getDocumentSetting(arguments.settingName));
			case "monitoring":
				return trim("" & new cfsuite.ccssuite.utils.monitoringConfigUtil().init().getMonitoringSetting(arguments.settingName));
			case "clientVariables":
				runtime = getRuntime();
				try {
					return trim("" & getClientStoreSettingValue(runtime.api, arguments.settingName));
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			case "debugging":
				if(normalizeArea(arguments.apiArea) EQ "systemprobes")
					return new cfsuite.ccssuite.utils.systemProbesConfigUtil().init().getSetting(arguments.settingName);
				return trim("" & new cfsuite.ccssuite.utils.debuggingConfigUtil().init().getDebuggingSetting(arguments.settingName));
			case "scope":
				runtime = getRuntime();
				try {
					return formatSettingValue(runtime.api.getScopeProperty(arguments.settingName));
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			case "restDiscovery":
				runtime = getRuntime();
				try {
					return formatSettingValue(runtime.api.isRESTDiscoveryEnabled());
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			case "memoryStorage":
			case "mappings":
				if(handler EQ "mappings")
					return new cfsuite.ccssuite.utils.mappingsConfigUtil().init().getSetting(arguments.settingName);
				runtime = getRuntime();
				try {
					return new cfsuite.ccssuite.utils.memoryVariablesConfigUtil().init().getSetting(arguments.settingName);
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			default:
				runtime = getRuntime();
				try {
					return formatRuntimeSettingValue(
						arguments.settingName,
						readRuntimeProperty(runtime.api, arguments.settingName)
					);
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
		}
	}

	public any function setSetting(required string settingName, required any settingValue, string apiArea = ""){
		ensureConstants();
		setting requesttimeout=120;
		var handler = resolveHandlerType(arguments.settingName, arguments.apiArea);
		var runtime = "";

		switch(handler){
			case "watch":
				if(normalizeKey(arguments.settingName) EQ "watch.watchenabled")
					return new cfsuite.ccssuite.utils.watchConfigUtil().init().setWatchEnabled(arguments.settingValue) ? "true" : "false";
				return new cfsuite.ccssuite.utils.watchConfigUtil().init().setWatchInterval(val(arguments.settingValue));
			case "cloudServicesPool":
				return new cfsuite.ccssuite.utils.cloudServicesThreadPoolConfigUtil().init().setCloudServicesPoolSetting(arguments.settingName, val(arguments.settingValue));
			case "cacheEngine":
				runtime = getRuntime();
				try {
					runtime.api.setServerCachingEngine(resolveCacheEngineName(val(arguments.settingValue)));
					return trim("" & runtime.api.getRuntimeProperty("serverCacheType"));
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			case "cspNonce":
				new cfsuite.ccssuite.utils.cspNonceUtil().init().setCspNonceEnabled(arguments.settingValue);
				return getSetting(arguments.settingName, arguments.apiArea);
			case "uuidCFToken":
				runtime = getRuntime();
				try {
					runtime.api.setScopeProperty("UUIDCFToken", arguments.settingValue);
					return getSetting(arguments.settingName, arguments.apiArea);
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			case "maxThreadCount":
				new cfsuite.ccssuite.utils.maxThreadCountConfigUtil().init().setMaxThreadCountForParallelCalls(val(arguments.settingValue));
				return getSetting(arguments.settingName, arguments.apiArea);
			case "cache":
				new cfsuite.ccssuite.utils.cacheConfigUtil().init().setCacheSetting(arguments.settingName, arguments.settingValue);
				return getSetting(arguments.settingName, arguments.apiArea);
			case "mail":
				return setMailSetting(arguments.settingName, arguments.settingValue);
			case "scheduledTasks":
				return new cfsuite.ccssuite.utils.scheduledTasksConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
			case "fontManagement":
				return new cfsuite.ccssuite.utils.fontManagementConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
			case "websocket":
				return setWebSocketSetting(arguments.settingName, arguments.settingValue);
			case "sslCertificate":
				return setSslCertificateSetting(arguments.settingName, arguments.settingValue);
			case "charting":
				return setChartingSetting(arguments.settingName, arguments.settingValue);
			case "document":
				return setDocumentSetting(arguments.settingName, arguments.settingValue);
			case "monitoring":
				new cfsuite.ccssuite.utils.monitoringConfigUtil().init().setMonitoringSetting(arguments.settingName, arguments.settingValue);
				return getSetting(arguments.settingName, arguments.apiArea);
			case "clientVariables":
				runtime = getRuntime();
				try {
					return setClientStoreSettingValue(runtime.api, arguments.settingName, arguments.settingValue);
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			case "debugging":
				if(normalizeArea(arguments.apiArea) EQ "systemprobes")
					return new cfsuite.ccssuite.utils.systemProbesConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
				new cfsuite.ccssuite.utils.debuggingConfigUtil().init().setDebuggingSetting(arguments.settingName, arguments.settingValue);
				return getSetting(arguments.settingName, arguments.apiArea);
			case "scope":
				runtime = getRuntime();
				try {
					runtime.api.setScopeProperty(arguments.settingName, arguments.settingValue);
					return getSetting(arguments.settingName, arguments.apiArea);
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			case "restDiscovery":
				runtime = getRuntime();
				try {
					runtime.api.setRESTDiscoveryEnabled(arguments.settingValue);
					return getSetting(arguments.settingName, arguments.apiArea);
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
			case "mappings":
				return new cfsuite.ccssuite.utils.mappingsConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
			default:
				runtime = getRuntime();
				try {
					if(handler EQ "memoryStorage")
						return new cfsuite.ccssuite.utils.memoryVariablesConfigUtil().init().setSetting(runtime.api, arguments.settingName, arguments.settingValue);
					runtime.api.setRuntimeProperty(
						resolveRuntimePropertyName(arguments.settingName),
						coerceRuntimePropertyValue(arguments.settingName, arguments.settingValue)
					);
					return getSetting(arguments.settingName, arguments.apiArea);
				}
				finally {
					runtime.adminUtil.logout(runtime.admin);
				}
		}
	}

	public boolean function setMatches(
		required string settingName,
		required any presetValue,
		required any actualValue,
		required any requestedValue,
		string apiArea = ""
	){
		if(lCase(normalizeArea(arguments.apiArea)) EQ "caching" AND compareNoCase(arguments.settingName, "redisCacheStoragePassword") EQ 0)
			return new cfsuite.ccssuite.utils.cacheConfigUtil().init().cacheValuesMatch(arguments.settingName, arguments.requestedValue, arguments.actualValue);
		if(lCase(normalizeArea(arguments.apiArea)) EQ "llms"){
			return new cfsuite.ccssuite.utils.llmConfigUtil().init().setMatches(
				arguments.presetValue,
				arguments.actualValue,
				arguments.requestedValue
			);
		}
		if(lCase(normalizeArea(arguments.apiArea)) EQ "embeddingmodels"){
			return new cfsuite.ccssuite.utils.embeddingConfigUtil().init().setMatches(
				arguments.presetValue,
				arguments.actualValue,
				arguments.requestedValue
			);
		}
		if(listFindNoCase("vectorstores,RAG", normalizeArea(arguments.apiArea))){
			return new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().setMatches(
				arguments.presetValue,
				arguments.actualValue,
				arguments.requestedValue
			);
		}
		if(lCase(normalizeArea(arguments.apiArea)) EQ "solrserver" AND lCase(arguments.settingName) EQ "password"){
			// Solr Server's password field is auto-encrypted by CF's runtime once a plaintext
			// value is detected on disk (same behavior as neo-mail.xml's password field), so an
			// exact string match against what we requested isn't meaningful — same leniency as
			// isMailSensitiveSetting below: pass if it changed to something non-empty.
			if(len(trim("" & arguments.requestedValue)) EQ 0)
				return trim("" & arguments.actualValue) EQ trim("" & arguments.requestedValue);
			return len(trim("" & arguments.actualValue)) AND trim("" & arguments.actualValue) NEQ trim("" & arguments.presetValue);
		}
		if(lCase(normalizeArea(arguments.apiArea)) EQ "restservices"){
			// Root Path is a per-instance filesystem path — the requested value pushed to a peer
			// is the PRIME node's own path, but each peer registers against its own, different,
			// local path (confirmed via direct testing), so an exact string match against the
			// requested value isn't meaningful. Pass if it changed to/from non-empty consistently
			// with what was requested (empty request -> expect empty actual, i.e. removed;
			// non-empty request -> expect some real path registered, whatever it is on this node).
			if(len(trim("" & arguments.requestedValue)) EQ 0)
				return len(trim("" & arguments.actualValue)) EQ 0;
			return len(trim("" & arguments.actualValue)) GT 0;
		}
		if(lCase(normalizeArea(arguments.apiArea)) EQ "mcpservers"){
			return new cfsuite.ccssuite.utils.mcpConfigUtil().init().setMatches(
				arguments.presetValue,
				arguments.actualValue,
				arguments.requestedValue
			);
		}
		if(lCase(normalizeArea(arguments.apiArea)) EQ "datasources"){
			return new cfsuite.ccssuite.utils.datasourceConfigUtil().init().setMatches(
				arguments.settingName, arguments.presetValue, arguments.actualValue, arguments.requestedValue
			);
		}
		if(lCase(normalizeArea(arguments.apiArea)) EQ "nosqldatasources"){
			return new cfsuite.ccssuite.utils.nosqlDatasourceConfigUtil().init().setMatches(
				arguments.presetValue,
				arguments.actualValue,
				arguments.requestedValue
			);
		}
		if(lCase(normalizeArea(arguments.apiArea)) EQ "coldfusioncollections"){
			return new cfsuite.ccssuite.utils.coldfusionCollectionsConfigUtil().init().setMatches(
				arguments.presetValue,
				arguments.actualValue,
				arguments.requestedValue
			);
		}
		if(listFindNoCase("JavaCfx,CppCfx,CustomTagPaths", arguments.settingName)){
			if(arguments.settingName EQ "CustomTagPaths")
				return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().setMatches(
					arguments.presetValue,
					arguments.actualValue,
					arguments.requestedValue
				);
			return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().configsMatch(
				arguments.requestedValue,
				arguments.actualValue
			);
		}
		if(listFindNoCase("EnableGatewayService,ThreadPoolSize,MaxQueueSize", arguments.settingName)){
			return new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init().scalarValuesMatch(
				arguments.requestedValue,
				arguments.actualValue,
				arguments.settingName
			);
		}
		if(listFindNoCase("GatewayType,GatewayInstance", arguments.settingName)){
			return new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init().configsMatch(
				arguments.requestedValue,
				arguments.actualValue
			);
		}
		if(lCase(normalizeArea(arguments.apiArea)) EQ "administrator"
				OR lCase(normalizeArea(arguments.apiArea)) EQ "rds"
				OR lCase(normalizeArea(arguments.apiArea)) EQ "sandboxsecurity"
				OR listFindNoCase("AllowConcurrentAdminLogin,AdminUserIdRequired,ExternalAuth,RootAdminUserId,RdsEnabled,RdsSecurityEnabled,UseSingleRdsPassword,SandboxSecurityEnabled,SandboxPath", arguments.settingName)){
			var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
			if(arguments.settingName EQ "SandboxPath")
				return secUtil.sandboxPathValuesMatch(arguments.requestedValue, arguments.actualValue);
			return secUtil.scalarValuesMatch(
				arguments.requestedValue,
				arguments.actualValue,
				arguments.settingName
			);
		}
		var handler = resolveHandlerType(arguments.settingName, arguments.apiArea);
		if(handler EQ "mail"){
			if(isMailSensitiveSetting(arguments.settingName)){
				if(len(trim("" & arguments.requestedValue)) EQ 0)
					return trim("" & arguments.actualValue) EQ trim("" & arguments.requestedValue);
				return len(trim("" & arguments.actualValue)) AND trim("" & arguments.actualValue) NEQ trim("" & arguments.presetValue);
			}
			return mailSettingsMatch(arguments.settingName, arguments.actualValue, arguments.requestedValue);
		}
		if(handler EQ "websocket"){
			if(isWebSocketSensitiveSetting(arguments.settingName)){
				if(len(trim("" & arguments.requestedValue)) EQ 0)
					return trim("" & arguments.actualValue) EQ trim("" & arguments.requestedValue);
				return len(trim("" & arguments.actualValue)) AND trim("" & arguments.actualValue) NEQ trim("" & arguments.presetValue);
			}
			return websocketSettingsMatch(arguments.settingName, arguments.actualValue, arguments.requestedValue);
		}
		if(handler EQ "charting")
			return chartSettingsMatch(arguments.settingName, arguments.actualValue, arguments.requestedValue);
		if(handler EQ "document")
			return documentSettingsMatch(arguments.settingName, arguments.actualValue, arguments.requestedValue);
		if(handler EQ "clientVariables"){
			var key = normalizeKey(arguments.settingName);
			if(key EQ "clientstoredatasource"){
				var requested = trim("" & arguments.requestedValue);
				var actual = trim("" & arguments.actualValue);
				if(len(requested))
					return actual EQ requested;
				return NOT len(actual);
			}
			if(listFindNoCase("clientstorepurge,clientstoredisableglobals", key))
				return formatSettingValue(arguments.actualValue) EQ formatSettingValue(arguments.requestedValue);
			if(key EQ "clientstorepurgedays")
				return val(arguments.actualValue) EQ val(arguments.requestedValue);
			return trim("" & arguments.actualValue) EQ trim("" & arguments.requestedValue);
		}
		if(handler EQ "scope" AND normalizeArea(arguments.apiArea) EQ "clientvariables" AND normalizeKey(arguments.settingName) EQ "clientstorage")
			return lCase(trim("" & arguments.actualValue)) EQ lCase(trim("" & arguments.requestedValue));
		if(handler EQ "scope" AND normalizeArea(arguments.apiArea) EQ "memoryvariables"){
			var memKey = normalizeKey(arguments.settingName);
			if(listFindNoCase("sessionscopetimeout,applicationscopetimeout,sessionscopemaxtimeout,applicationscopemaxtimeout", memKey))
				return normalizeScopeTimeout("" & arguments.actualValue) EQ normalizeScopeTimeout("" & arguments.requestedValue);
		}
		if(handler EQ "runtime" AND normalizeArea(arguments.apiArea) EQ "memoryvariables"){
			var memKey = normalizeKey(arguments.settingName);
			if(memKey EQ "sessionstorage")
				return lCase(trim("" & arguments.actualValue)) EQ lCase(trim("" & arguments.requestedValue));
			if(memKey EQ "sessioncookietimeout")
				return val(arguments.actualValue) EQ val(arguments.requestedValue);
			if(memKey EQ "sessioncookiesamesite")
				return normalizeSessionCookieSamesite(arguments.actualValue) EQ normalizeSessionCookieSamesite(arguments.requestedValue);
		}
		if(handler EQ "memoryStorage")
			return new cfsuite.ccssuite.utils.memoryVariablesConfigUtil().init().valuesMatch(arguments.settingName, arguments.requestedValue, arguments.actualValue);
		if(handler EQ "mappings")
			return new cfsuite.ccssuite.utils.mappingsConfigUtil().init().configsMatch(arguments.settingName, arguments.requestedValue, arguments.actualValue);
		if(handler EQ "scheduledTasks")
			return new cfsuite.ccssuite.utils.scheduledTasksConfigUtil().init().configsMatch(arguments.settingName, arguments.requestedValue, arguments.actualValue);
		if(handler EQ "fontManagement")
			return new cfsuite.ccssuite.utils.fontManagementConfigUtil().init().configsMatch(arguments.settingName, arguments.requestedValue, arguments.actualValue);
		if(handler EQ "debugging")
			return new cfsuite.ccssuite.utils.debuggingConfigUtil().init().setMatches(
				arguments.settingName, arguments.presetValue, arguments.actualValue, arguments.requestedValue);

		if(isCommaListSetting(normalizeKey(arguments.settingName)))
			return commaListsMatch(arguments.actualValue, arguments.requestedValue);

		var settingKey = normalizeKey(arguments.settingName);
		if(listFindNoCase("cfformscriptsrc,ormsearchindexdirectory", settingKey))
			return pathSettingsMatch(settingKey, arguments.actualValue, arguments.requestedValue);

		return formatSettingValue(arguments.actualValue) EQ formatSettingValue(arguments.requestedValue);
	}

	public string function getClientVariablesTestDatasourceName(){
		return "cfartgallery";
	}

	public void function ensureClientVariablesTestStorePresent(){
		var runtime = getRuntime();
		try {
			var ds = getClientVariablesTestDatasourceName();
			var stores = runtime.api.getClientStores();
			if(NOT isStruct(stores) OR NOT structKeyExists(stores, ds))
				runtime.api.setClientStore("", false, ds, true, 90, "JDBC", ds);
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public void function ensureClientVariablesTestDatasourceStoreAbsent(){
		var runtime = getRuntime();
		try {
			var testDs = getClientVariablesTestDatasourceName();
			var stores = runtime.api.getClientStores();
			if(isStruct(stores) AND structKeyExists(stores, testDs))
				runtime.api.deleteClientStore(testDs);
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	private struct function getMailApi(){
		ensureConstants();
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		var admin = adminUtil.createAdministrator();
		adminUtil.login(getConstants().CF_CONFIG);
		return {
			admin = admin,
			adminUtil = adminUtil,
			api = createObject("component", "CFIDE.adminapi.mail")
		};
	}

	private void function logoutMailApi(required struct mailRuntime){
		arguments.mailRuntime.adminUtil.logout(arguments.mailRuntime.admin);
	}

	private string function getMailConfigPath(){
		return server.coldfusion.rootdir & "/lib/neo-mail.xml";
	}

	private struct function readMailConfigStruct(){
		var data = {};
		cfwddx(action="WDDX2CFML", input=fileRead(getMailConfigPath()), output="data");
		return data;
	}

	private void function writeMailConfigStruct(required struct mailConfig){
		var wddxOut = "";
		cfwddx(action="CFML2WDDX", input=arguments.mailConfig, output="wddxOut");
		fileWrite(getMailConfigPath(), wddxOut);
	}

	private boolean function isMailSensitiveSetting(required string settingKey){
		return listFindNoCase("password,keystorepassword,keypassword", normalizeKey(arguments.settingKey)) GT 0;
	}

	private boolean function isMailBooleanSetting(required string settingKey){
		return listFindNoCase("sign,usessl,usetls,spoolenable,allowdownload,mailsentloggingenable,maintainconnections,spooltomemory", normalizeKey(arguments.settingKey)) GT 0;
	}

	private boolean function parseMailBoolean(required any value){
		var text = lCase(trim("" & arguments.value));
		return listFindNoCase("true,yes,1", text) GT 0;
	}

	private any function formatMailSettingForOutput(required string settingKey, required any value){
		var key = normalizeKey(arguments.settingKey);
		if(isMailBooleanSetting(key))
			return parseMailBoolean(arguments.value) ? "true" : "false";
		if(listFindNoCase("port,timeout,schedule,maxdeliverythreads,maxmessagesinmemory", key))
			return val(arguments.value);
		return trim("" & arguments.value);
	}

	private any function coerceMailSettingForStore(required string settingKey, required any settingValue){
		var key = normalizeKey(arguments.settingKey);
		if(isMailBooleanSetting(key))
			// Must be a real CFML boolean, not the string "YES"/"NO": setMailProperty() persists
			// whatever type it's given, and a string value gets WDDX-serialized as <string>YES</string>
			// instead of <boolean>. CentralConfigRefreshServlet's Mail module reload then does a hard
			// cast to java.lang.Boolean when a peer node applies the CCS-pushed config, so a
			// string-typed value throws ClassCastException and blocks that peer's sync indefinitely
			// (confirmed via coldfusion-error.log: MailSpooler.load ClassCastException on every
			// CentralConfigRefreshServlet.reloadModule("Mail") attempt).
			return parseMailBoolean(arguments.settingValue);
		if(listFindNoCase("port,timeout,schedule,maxdeliverythreads,maxmessagesinmemory", key))
			return val(arguments.settingValue);
		if(key EQ "severity")
			return lCase(trim("" & arguments.settingValue));
		return arguments.settingValue;
	}

	private boolean function mailSettingsMatch(required string settingName, required any actualValue, required any requestedValue){
		var key = normalizeKey(arguments.settingName);
		if(isMailBooleanSetting(key))
			return parseMailBoolean(arguments.actualValue) EQ parseMailBoolean(arguments.requestedValue);
		if(listFindNoCase("port,timeout,schedule,maxdeliverythreads,maxmessagesinmemory", key))
			return val(arguments.actualValue) EQ val(arguments.requestedValue);
		if(key EQ "severity")
			return lCase(trim("" & arguments.actualValue)) EQ lCase(trim("" & arguments.requestedValue));
		return trim("" & arguments.actualValue) EQ trim("" & arguments.requestedValue);
	}

	private boolean function mailStoredValueMatches(required string settingKey, required any actualValue, required any requestedValue){
		var key = normalizeKey(arguments.settingKey);
		var actual = arguments.actualValue;
		var requested = coerceMailSettingForStore(key, arguments.requestedValue);
		if(isMailBooleanSetting(key))
			return parseMailBoolean(actual) EQ parseMailBoolean(requested);
		if(listFindNoCase("port,timeout,schedule,maxdeliverythreads,maxmessagesinmemory", key))
			return val(actual) EQ val(requested);
		if(key EQ "severity")
			return lCase(trim("" & actual)) EQ lCase(trim("" & requested));
		return trim("" & actual) EQ trim("" & requested);
	}

	public any function getMailSetting(required string settingName){
		ensureConstants();
		var key = normalizeKey(arguments.settingName);
		if(key EQ "backupmailservers")
			return listRest(getMailSetting("server"));
		if(listFindNoCase("defaultmailcharset,maintainconnections,maxdeliverythreads,spooltomemory,maxmessagesinmemory", key)){
			var mailRuntime = getMailApi();
			try {
				return formatMailSettingForOutput(key, mailRuntime.api.getMailProperty(key));
			}
			finally {
				logoutMailApi(mailRuntime);
			}
		}
		var mailConfig = readMailConfigStruct();
		if(structKeyExists(mailConfig, key))
			return formatMailSettingForOutput(key, mailConfig[key]);
		return "";
	}

	public any function setMailSetting(required string settingName, required any settingValue){
		ensureConstants();
		var key = normalizeKey(arguments.settingName);
		var storeValue = coerceMailSettingForStore(key, arguments.settingValue);

		if(key EQ "backupmailservers"){
			var primaryServer = listFirst(getMailSetting("server"));
			if(NOT len(trim(primaryServer)))
				throw(message="Configure a primary mail server before testing backup mail servers", type="CCSTest.MailFixtureMissing");
			var backupServers = trim("" & storeValue);
			setMailSetting("server", len(backupServers) ? listAppend(primaryServer, backupServers) : primaryServer);
			return getMailSetting(arguments.settingName);
		}

		if(listFindNoCase("defaultmailcharset,maintainconnections,maxdeliverythreads,spooltomemory,maxmessagesinmemory", key)){
			var mailRuntime = getMailApi();
			try {
				mailRuntime.api.setMailProperty(key, storeValue);
				return getMailSetting(arguments.settingName);
			}
			finally {
				logoutMailApi(mailRuntime);
			}
		}

		var mailRuntime = getMailApi();
		try {
			mailRuntime.api.setMailProperty(key, storeValue);
		}
		finally {
			logoutMailApi(mailRuntime);
		}

		var afterConfig = readMailConfigStruct();
		if(structKeyExists(afterConfig, key) AND mailStoredValueMatches(key, afterConfig[key], storeValue))
			return formatMailSettingForOutput(key, afterConfig[key]);

		var mailConfig = readMailConfigStruct();
		mailConfig[key] = storeValue;
		writeMailConfigStruct(mailConfig);
		return getMailSetting(arguments.settingName);
	}

	public struct function verifyMailServerConnection(){
		ensureConstants();
		var serverName = trim(listFirst("" & getMailSetting("server")));
		var port = val(getMailSetting("port"));
		var timeoutSeconds = val(getMailSetting("timeout"));
		var useSsl = parseMailBoolean(getMailSetting("usessl"));
		if(timeoutSeconds LTE 0)
			timeoutSeconds = 60;
		if(NOT len(serverName))
			return { success = false, server = serverName, port = port, message = "mail server is not configured" };

		var timeoutMs = timeoutSeconds * 1000;
		try {
			// TCP reachability check (works on Java 17+; avoids SSLSocketFactory module access issues).
			var socket = createObject("java", "java.net.Socket").init();
			var address = createObject("java", "java.net.InetSocketAddress").init(serverName, port);
			socket.connect(address, timeoutMs);
			socket.close();
			return {
				success = true,
				server = serverName,
				port = port,
				useSsl = useSsl,
				message = "Connected to #serverName#:#port#"
			};
		}
		catch(any e){
			return {
				success = false,
				server = serverName,
				port = port,
				useSsl = useSsl,
				message = e.message
			};
		}
	}

	private string function getWebSocketConfigPath(){
		return server.coldfusion.rootdir & "/lib/neo-websocket.xml";
	}

	private struct function readWebSocketConfigStruct(){
		var data = {};
		cfwddx(action="WDDX2CFML", input=fileRead(getWebSocketConfigPath()), output="data");
		return data;
	}

	private void function writeWebSocketConfigStruct(required struct wsConfig){
		var normalized = {};
		for(var key in arguments.wsConfig){
			var nk = normalizeKey(key);
			if(isWebSocketBooleanSetting(nk))
				normalized[key] = parseWebSocketBoolean(arguments.wsConfig[key]);
			else if(isWebSocketNumericSetting(nk))
				normalized[key] = val(arguments.wsConfig[key]);
			else
				normalized[key] = arguments.wsConfig[key];
		}
		var wddxOut = "";
		cfwddx(action="CFML2WDDX", input=normalized, output="wddxOut");
		wddxOut = replace(wddxOut, "<struct>", "<struct type='coldfusion.server.ConfigMap'>");
		fileWrite(getWebSocketConfigPath(), wddxOut);
	}

	private string function resolveWebSocketConfigKey(required string settingName, required struct wsConfig){
		var target = normalizeKey(arguments.settingName);
		for(var configKey in arguments.wsConfig.keyList()){
			if(normalizeKey(configKey) EQ target)
				return configKey;
		}
		return arguments.settingName;
	}

	private boolean function isWebSocketSensitiveSetting(required string settingKey){
		return normalizeKey(arguments.settingKey) EQ "keystorepassword";
	}

	private boolean function isWebSocketBooleanSetting(required string settingKey){
		return listFindNoCase(
			"startwebsocketservice,enablewebsocketoverproxyport,startlisteneronnormalport,sslenabled,flashfallback,clustered",
			normalizeKey(arguments.settingKey)
		) GT 0;
	}

	private boolean function isWebSocketNumericSetting(required string settingKey){
		return listFindNoCase("maxframesize,sockettimeout", normalizeKey(arguments.settingKey)) GT 0;
	}

	private boolean function parseWebSocketBoolean(required any value){
		return listFindNoCase("true,yes,1", lCase(trim("" & arguments.value))) GT 0;
	}

	private any function formatWebSocketSettingForOutput(required string settingKey, required any value){
		var key = normalizeKey(arguments.settingKey);
		if(isWebSocketBooleanSetting(key))
			return parseWebSocketBoolean(arguments.value) ? "true" : "false";
		if(isWebSocketNumericSetting(key))
			return val(arguments.value);
		return trim("" & arguments.value);
	}

	private any function coerceWebSocketSettingForStore(required string settingKey, required any settingValue){
		var key = normalizeKey(arguments.settingKey);
		if(isWebSocketBooleanSetting(key))
			return parseWebSocketBoolean(arguments.settingValue);
		if(isWebSocketNumericSetting(key))
			return val(arguments.settingValue);
		if(key EQ "logging")
			return lCase(trim("" & arguments.settingValue));
		return trim("" & arguments.settingValue);
	}

	private boolean function websocketSettingsMatch(required string settingName, required any actualValue, required any requestedValue){
		var key = normalizeKey(arguments.settingName);
		if(isWebSocketBooleanSetting(key))
			return parseWebSocketBoolean(arguments.actualValue) EQ parseWebSocketBoolean(arguments.requestedValue);
		if(isWebSocketNumericSetting(key))
			return val(arguments.actualValue) EQ val(arguments.requestedValue);
		if(key EQ "logging")
			return lCase(trim("" & arguments.actualValue)) EQ lCase(trim("" & arguments.requestedValue));
		return trim("" & arguments.actualValue) EQ trim("" & arguments.requestedValue);
	}

	public any function getWebSocketSetting(required string settingName){
		ensureConstants();
		var wsConfig = readWebSocketConfigStruct();
		var configKey = resolveWebSocketConfigKey(arguments.settingName, wsConfig);
		if(structKeyExists(wsConfig, configKey))
			return formatWebSocketSettingForOutput(configKey, wsConfig[configKey]);
		return "";
	}

	public any function setWebSocketSetting(required string settingName, required any settingValue){
		ensureConstants();
		var wsConfig = readWebSocketConfigStruct();
		var configKey = resolveWebSocketConfigKey(arguments.settingName, wsConfig);
		if(NOT structKeyExists(wsConfig, configKey))
			configKey = arguments.settingName;
		wsConfig[configKey] = coerceWebSocketSettingForStore(configKey, arguments.settingValue);
		writeWebSocketConfigStruct(wsConfig);
		return getWebSocketSetting(arguments.settingName);
	}

	private string function getServerXmlPath(){
		return server.coldfusion.rootdir & "/runtime/conf/server.xml";
	}

	private string function readServerXmlContent(){
		return fileRead(getServerXmlPath());
	}

	// fileWrite() on this CF build always appends a trailing newline, even when one is already
	// present — writing the same content back unchanged still grows the file by one line every
	// time. Stripping trailing CR/LF before every write keeps repeated writes idempotent instead of
	// accumulating blank lines at end-of-file across test runs.
	private void function writeServerXmlContent(required string content){
		fileWrite(getServerXmlPath(), reReplace(arguments.content, "[\r\n]+$", "", "one"));
	}

	// The <Certificate .../> element this suite reads/writes lives inside the SSL Connector block
	// that ships commented out in server.xml (Existing-certificate values only — Https/Http enable
	// and the Create/self-signed fields are deliberately out of scope, see sslCertificate/i.cfm).
	// Editing attribute text inside an XML comment is inert to the running Tomcat instance: its
	// parser skips comments entirely, so this never uncomments the SSL connector, never touches the
	// live port-8500 HTTP connector, and never requires a server restart to stay safe.
	private struct function locateSslCertificateTag(required string content){
		var match = reFind("<Certificate[^>]*/>", arguments.content, 1, true);
		if(match.pos[1] EQ 0)
			throw(message="SSL Certificate <Certificate> element not found in server.xml", type="CCSTest.ConfigError");
		return {
			tag = mid(arguments.content, match.pos[1], match.len[1]),
			startPos = match.pos[1],
			len = match.len[1]
		};
	}

	private string function resolveSslCertificateAttribute(required string settingName){
		switch(normalizeKey(arguments.settingName)){
			case "certificatelocation":
				return "certificateKeystoreFile";
			case "certificatepassword":
				return "certificateKeystorePassword";
			case "certificatealgorithm":
				return "type";
			default:
				throw(message="Unsupported SSL certificate setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
	}

	private string function getSslCertificateTagAttribute(required string tag, required string attributeName){
		var pattern = arguments.attributeName & '\s*=\s*"([^"]*)"';
		var match = reFind(pattern, arguments.tag, 1, true);
		if(match.pos[1] EQ 0 OR arrayLen(match.pos) LT 2)
			return "";
		return mid(arguments.tag, match.pos[2], match.len[2]);
	}

	private string function setSslCertificateTagAttribute(required string tag, required string attributeName, required string attributeValue){
		var pattern = arguments.attributeName & '\s*=\s*"[^"]*"';
		var match = reFind(pattern, arguments.tag, 1, true);
		if(match.pos[1] EQ 0)
			throw(message="Attribute #arguments.attributeName# not found on SSL Certificate element", type="CCSTest.ConfigError");
		var before = mid(arguments.tag, 1, match.pos[1] - 1);
		var after = mid(arguments.tag, match.pos[1] + match.len[1], len(arguments.tag));
		return before & arguments.attributeName & '="' & arguments.attributeValue & '"' & after;
	}

	// "UseSslCertificate" (the Existing/Create radio) has no real persisted state of its own — CF
	// admin's radio choice is a pure UI selector, never written to server.xml as a separate flag.
	// This is a synthetic stand-in only: whether the <Certificate .../> element exists at all
	// inside the still-commented <SSLHostConfig> block (present = an existing cert configured,
	// absent = none). Still 100% inert — never uncomments the connector.
	private string function getDefaultSslCertificateTag(){
		return '<Certificate certificateKeystoreFile="adminlocalhost" certificateKeystorePassword="password" type="RSA" />';
	}

	private boolean function sslCertificateTagExists(required string content){
		var match = reFind("<Certificate[^>]*/>", arguments.content, 1, true);
		return match.pos[1] GT 0;
	}

	private numeric function locateSslHostConfigOpenTagEnd(required string content){
		var match = reFind("<SSLHostConfig>", arguments.content, 1, true);
		if(match.pos[1] EQ 0)
			throw(message="SSL Certificate <SSLHostConfig> element not found in server.xml", type="CCSTest.ConfigError");
		return match.pos[1] + match.len[1];
	}

	public any function getUseSslCertificatePresence(){
		return sslCertificateTagExists(readServerXmlContent()) ? "true" : "false";
	}

	public any function setUseSslCertificatePresence(required any settingValue){
		var wantPresent = isBoolean(arguments.settingValue) AND NOT isNumeric(arguments.settingValue)
			? arguments.settingValue
			: (listFindNoCase("true,yes,1", trim("" & arguments.settingValue)) GT 0);
		var content = readServerXmlContent();
		var exists = sslCertificateTagExists(content);

		if(wantPresent AND NOT exists){
			var newlineStyle = find(chr(13) & chr(10), content) ? (chr(13) & chr(10)) : chr(10);
			var insertAt = locateSslHostConfigOpenTagEnd(content);
			content = mid(content, 1, insertAt - 1) & newlineStyle & getDefaultSslCertificateTag() & mid(content, insertAt, len(content));
			writeServerXmlContent(content);
		}
		else if(NOT wantPresent AND exists){
			var located = locateSslCertificateTag(content);
			var tagEndPos = located.startPos + located.len;
			var removeEnd = tagEndPos;
			if(mid(content, tagEndPos, 2) EQ (chr(13) & chr(10)))
				removeEnd = tagEndPos + 2;
			else if(mid(content, tagEndPos, 1) EQ chr(10))
				removeEnd = tagEndPos + 1;
			content = mid(content, 1, located.startPos - 1) & mid(content, removeEnd, len(content));
			writeServerXmlContent(content);
		}

		return getUseSslCertificatePresence();
	}

	// "SslHttpsEnabled"/"SslHttpEnabled" (the Https/Http "Enable" checkboxes) are excluded from real
	// round-trip testing on purpose: the real fields control whether the live <Connector> blocks are
	// commented or active. Enabling Https for real means uncommenting a connector whose keystore
	// ("adminlocalhost") almost certainly isn't a real file — Tomcat commonly refuses to start at all
	// with an invalid cert config, not just fail that one connector. Disabling Http for real means
	// commenting out the port-8500 connector THIS admin session runs on — a self-lockout risk on the
	// next restart. Neither takes effect without a restart, but the file would sit in that broken
	// state for the test's duration, and any restart during that window (scheduled task, crash,
	// someone else touching the service) turns it into a real outage. So instead, these are synthetic
	// markers added to/removed from already-inert companion elements that are NEVER the live
	// connectors: a custom attribute on the commented SSL <Connector>'s own opening tag (for Https),
	// and on the separate, always-commented "shared thread pool" HTTP <Connector> template a few
	// lines above it (for Http) — the one Tomcat never uses regardless of anything in this file.
	private string function getHttpsEnabledMarkerAttribute(){
		return "data-ccstest-https-enabled";
	}

	private string function getHttpEnabledMarkerAttribute(){
		return "data-ccstest-http-enabled";
	}

	private struct function locateCommentedSslConnectorOpenTag(required string content){
		var match = reFind('<Connector[^>]*protocol="org\.apache\.coyote\.http11\.Http11NioProtocol"[^>]*>', arguments.content, 1, true);
		if(match.pos[1] EQ 0)
			throw(message="Commented SSL <Connector> tag not found in server.xml", type="CCSTest.ConfigError");
		return {
			tag = mid(arguments.content, match.pos[1], match.len[1]),
			startPos = match.pos[1],
			len = match.len[1]
		};
	}

	private struct function locateCommentedSharedPoolHttpConnectorTag(required string content){
		var match = reFind('<Connector[^>]*executor="tomcatThreadPool"[^>]*/>', arguments.content, 1, true);
		if(match.pos[1] EQ 0)
			throw(message="Commented shared thread pool HTTP <Connector> tag not found in server.xml", type="CCSTest.ConfigError");
		return {
			tag = mid(arguments.content, match.pos[1], match.len[1]),
			startPos = match.pos[1],
			len = match.len[1]
		};
	}

	private boolean function tagHasMarkerAttribute(required string tag, required string markerName){
		var match = reFind(arguments.markerName & '\s*=\s*"true"', arguments.tag, 1, true);
		return match.pos[1] GT 0;
	}

	private string function addMarkerAttributeToTag(required string tag, required string markerName){
		if(tagHasMarkerAttribute(arguments.tag, arguments.markerName))
			return arguments.tag;
		var insertPos = find(" ", arguments.tag);
		if(NOT insertPos)
			throw(message="Cannot locate insertion point in tag", type="CCSTest.ConfigError");
		return mid(arguments.tag, 1, insertPos) & arguments.markerName & '="true" ' & mid(arguments.tag, insertPos + 1, len(arguments.tag));
	}

	private string function removeMarkerAttributeFromTag(required string tag, required string markerName){
		var match = reFind(arguments.markerName & '\s*=\s*"true"\s*', arguments.tag, 1, true);
		if(match.pos[1] EQ 0)
			return arguments.tag;
		return mid(arguments.tag, 1, match.pos[1] - 1) & mid(arguments.tag, match.pos[1] + match.len[1], len(arguments.tag));
	}

	private any function getMarkerPresence(required struct located, required string markerName){
		return tagHasMarkerAttribute(arguments.located.tag, arguments.markerName) ? "true" : "false";
	}

	private void function setMarkerPresence(required string content, required struct located, required string markerName, required any settingValue){
		var wantPresent = isBoolean(arguments.settingValue) AND NOT isNumeric(arguments.settingValue)
			? arguments.settingValue
			: (listFindNoCase("true,yes,1", trim("" & arguments.settingValue)) GT 0);
		var newTag = wantPresent
			? addMarkerAttributeToTag(arguments.located.tag, arguments.markerName)
			: removeMarkerAttributeFromTag(arguments.located.tag, arguments.markerName);
		var newContent = mid(arguments.content, 1, arguments.located.startPos - 1) & newTag & mid(arguments.content, arguments.located.startPos + arguments.located.len, len(arguments.content));
		writeServerXmlContent(newContent);
	}

	public any function getHttpsEnabledPresence(){
		return getMarkerPresence(locateCommentedSslConnectorOpenTag(readServerXmlContent()), getHttpsEnabledMarkerAttribute());
	}

	public any function setHttpsEnabledPresence(required any settingValue){
		var content = readServerXmlContent();
		setMarkerPresence(content, locateCommentedSslConnectorOpenTag(content), getHttpsEnabledMarkerAttribute(), arguments.settingValue);
		return getHttpsEnabledPresence();
	}

	public any function getHttpEnabledPresence(){
		return getMarkerPresence(locateCommentedSharedPoolHttpConnectorTag(readServerXmlContent()), getHttpEnabledMarkerAttribute());
	}

	public any function setHttpEnabledPresence(required any settingValue){
		var content = readServerXmlContent();
		setMarkerPresence(content, locateCommentedSharedPoolHttpConnectorTag(content), getHttpEnabledMarkerAttribute(), arguments.settingValue);
		return getHttpEnabledPresence();
	}

	// "DistinguishedName" (the Create radio's Distinguished Name field, e.g. "CN=host,OU=...") has
	// no real persisted state to test at all — unlike Https/Http, there isn't even an existing real
	// element to represent it (it only ever exists transiently in the Create form, consumed by
	// generateKeyAndCertificate() to build a brand-new self-signed cert — the same generation risk
	// already excluded from real testing). This is a synthetic string-value round-trip only: a
	// custom attribute (data-ccstest-distinguished-name) added to/updated on the same already-inert
	// commented <Certificate .../> tag the Existing fields use. Still 100% inert.
	private string function getDistinguishedNameMarkerAttribute(){
		return "data-ccstest-distinguished-name";
	}

	private string function getTagAttributeOrEmpty(required string tag, required string attributeName){
		var pattern = arguments.attributeName & '\s*=\s*"([^"]*)"';
		var match = reFind(pattern, arguments.tag, 1, true);
		if(match.pos[1] EQ 0 OR arrayLen(match.pos) LT 2)
			return "";
		return mid(arguments.tag, match.pos[2], match.len[2]);
	}

	private string function addOrSetTagAttribute(required string tag, required string attributeName, required string attributeValue){
		var pattern = arguments.attributeName & '\s*=\s*"[^"]*"';
		var match = reFind(pattern, arguments.tag, 1, true);
		if(match.pos[1] GT 0){
			var before = mid(arguments.tag, 1, match.pos[1] - 1);
			var after = mid(arguments.tag, match.pos[1] + match.len[1], len(arguments.tag));
			return before & arguments.attributeName & '="' & arguments.attributeValue & '"' & after;
		}
		var insertPos = find(" ", arguments.tag);
		if(NOT insertPos)
			throw(message="Cannot locate insertion point in tag", type="CCSTest.ConfigError");
		return mid(arguments.tag, 1, insertPos) & arguments.attributeName & '="' & arguments.attributeValue & '" ' & mid(arguments.tag, insertPos + 1, len(arguments.tag));
	}

	public any function getDistinguishedNameValue(){
		var located = locateSslCertificateTag(readServerXmlContent());
		return getTagAttributeOrEmpty(located.tag, getDistinguishedNameMarkerAttribute());
	}

	public any function setDistinguishedNameValue(required any settingValue){
		var content = readServerXmlContent();
		var located = locateSslCertificateTag(content);
		var newTag = addOrSetTagAttribute(located.tag, getDistinguishedNameMarkerAttribute(), trim("" & arguments.settingValue));
		var newContent = mid(content, 1, located.startPos - 1) & newTag & mid(content, located.startPos + located.len, len(content));
		writeServerXmlContent(newContent);
		return getDistinguishedNameValue();
	}

	// "CertificateName" (the Create radio's Certificate Name field — the name/path for the
	// newly-generated keystore) is the same situation as DistinguishedName: no real persisted
	// state, only ever consumed transiently by generateKeyAndCertificate(). Same synthetic
	// string-value round-trip via its own custom attribute on the same commented
	// <Certificate .../> tag.
	private string function getCertificateNameMarkerAttribute(){
		return "data-ccstest-certificate-name";
	}

	public any function getCertificateNameValue(){
		var located = locateSslCertificateTag(readServerXmlContent());
		return getTagAttributeOrEmpty(located.tag, getCertificateNameMarkerAttribute());
	}

	public any function setCertificateNameValue(required any settingValue){
		var content = readServerXmlContent();
		var located = locateSslCertificateTag(content);
		var newTag = addOrSetTagAttribute(located.tag, getCertificateNameMarkerAttribute(), trim("" & arguments.settingValue));
		var newContent = mid(content, 1, located.startPos - 1) & newTag & mid(content, located.startPos + located.len, len(content));
		writeServerXmlContent(newContent);
		return getCertificateNameValue();
	}

	public any function getSslCertificateSetting(required string settingName){
		ensureConstants();
		var key = normalizeKey(arguments.settingName);
		if(key EQ "usesslcertificate")
			return getUseSslCertificatePresence();
		if(key EQ "sslhttpsenabled")
			return getHttpsEnabledPresence();
		if(key EQ "sslhttpenabled")
			return getHttpEnabledPresence();
		if(key EQ "distinguishedname")
			return getDistinguishedNameValue();
		if(key EQ "certificatename")
			return getCertificateNameValue();
		var attributeName = resolveSslCertificateAttribute(arguments.settingName);
		var located = locateSslCertificateTag(readServerXmlContent());
		return getSslCertificateTagAttribute(located.tag, attributeName);
	}

	public any function setSslCertificateSetting(required string settingName, required any settingValue){
		ensureConstants();
		var key = normalizeKey(arguments.settingName);
		if(key EQ "usesslcertificate")
			return setUseSslCertificatePresence(arguments.settingValue);
		if(key EQ "distinguishedname")
			return setDistinguishedNameValue(arguments.settingValue);
		if(key EQ "certificatename")
			return setCertificateNameValue(arguments.settingValue);
		if(key EQ "sslhttpsenabled")
			return setHttpsEnabledPresence(arguments.settingValue);
		if(key EQ "sslhttpenabled")
			return setHttpEnabledPresence(arguments.settingValue);
		var attributeName = resolveSslCertificateAttribute(arguments.settingName);
		var content = readServerXmlContent();
		var located = locateSslCertificateTag(content);
		var newTag = setSslCertificateTagAttribute(located.tag, attributeName, trim("" & arguments.settingValue));
		var newContent = mid(content, 1, located.startPos - 1) & newTag & mid(content, located.startPos + located.len, len(content));
		writeServerXmlContent(newContent);
		return getSslCertificateSetting(arguments.settingName);
	}

	public array function getChartingSettingKeyList(){
		return ["CacheType", "CacheSize", "TimeToLive"];
	}

	private struct function getChartRuntime(){
		ensureConstants();
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		var admin = adminUtil.createAdministrator();
		adminUtil.login(getConstants().CF_CONFIG);
		return {
			admin = admin,
			adminUtil = adminUtil,
			api = createObject("component", "CFIDE.adminapi.runtime")
		};
	}

	private void function logoutChartRuntime(required struct chartRuntime){
		arguments.chartRuntime.adminUtil.logout(arguments.chartRuntime.admin);
	}

	private string function resolveChartPropertyName(required string settingName){
		switch(normalizeKey(arguments.settingName)){
			case "cachetype":
				return "CacheType";
			case "cachesize":
				return "CacheSize";
			case "timetolive":
				return "TimeToLive";
			case "cachepath":
				return "CachePath";
			default:
				return arguments.settingName;
		}
	}

	private string function normalizeChartCacheType(required any value){
		var text = lCase(trim("" & arguments.value));
		if(findNoCase("disk", text))
			return "disk";
		if(findNoCase("memory", text))
			return "memory";
		if(val(text) EQ 1)
			return "disk";
		return "memory";
	}

	private any function formatChartSettingForOutput(required string propertyName, required any value){
		var key = normalizeKey(arguments.propertyName);
		if(key EQ "cachetype")
			return normalizeChartCacheType(arguments.value);
		if(listFindNoCase("cachesize,timetolive", key))
			return val(arguments.value);
		return trim("" & arguments.value);
	}

	private any function coerceChartSettingForStore(required string propertyName, required any settingValue){
		var key = normalizeKey(arguments.propertyName);
		if(key EQ "cachetype")
			return normalizeChartCacheType(arguments.settingValue);
		if(listFindNoCase("cachesize,timetolive", key))
			return val(arguments.settingValue);
		return trim("" & arguments.settingValue);
	}

	private boolean function chartSettingsMatch(required string settingName, required any actualValue, required any requestedValue){
		var key = normalizeKey(resolveChartPropertyName(arguments.settingName));
		if(key EQ "cachetype")
			return normalizeChartCacheType(arguments.actualValue) EQ normalizeChartCacheType(arguments.requestedValue);
		if(listFindNoCase("cachesize,timetolive", key))
			return val(arguments.actualValue) EQ val(arguments.requestedValue);
		if(key EQ "cachepath")
			return pathSettingsMatch(key, arguments.actualValue, arguments.requestedValue);
		return trim("" & arguments.actualValue) EQ trim("" & arguments.requestedValue);
	}

	public any function getChartingSetting(required string settingName){
		ensureConstants();
		var propertyName = resolveChartPropertyName(arguments.settingName);
		if(normalizeKey(propertyName) EQ "cachepath")
			return new cfsuite.ccssuite.utils.chartCachePathConfigUtil().init().getCachePath();
		var chartRuntime = getChartRuntime();
		try {
			return formatChartSettingForOutput(propertyName, chartRuntime.api.getChartProperty(propertyName));
		}
		finally {
			logoutChartRuntime(chartRuntime);
		}
	}

	public any function setChartingSetting(required string settingName, required any settingValue){
		ensureConstants();
		var propertyName = resolveChartPropertyName(arguments.settingName);
		var storeValue = coerceChartSettingForStore(propertyName, arguments.settingValue);
		if(normalizeKey(propertyName) EQ "cachepath")
			return new cfsuite.ccssuite.utils.chartCachePathConfigUtil().init().setCachePath(storeValue);
		var chartRuntime = getChartRuntime();
		try {
			chartRuntime.api.setChartProperty(propertyName, storeValue);
		}
		finally {
			logoutChartRuntime(chartRuntime);
		}
		return getChartingSetting(arguments.settingName);
	}

	public array function getDocumentSettingKeyList(){
		return ["openOfficeDirectory", "remoteOpenOffice"];
	}

	public struct function getDocumentRemoteOpenOfficeSettings(){
		var runtime = readDocumentRemoteOpenOfficeRuntime();
		return {
			hostname = formatDocumentSettingForOutput("hostname", runtime.hostname),
			port = formatDocumentSettingForOutput("port", runtime.port)
		};
	}

	public string function formatDocumentRemoteOpenOfficeValue(required struct settings){
		var host = trim(arguments.settings.hostname);
		var port = trim("" & arguments.settings.port);
		if(NOT len(host) AND NOT len(port))
			return "";
		return host & "|" & port;
	}

	private struct function parseDocumentRemoteOpenOfficeValue(required string value){
		var text = trim("" & arguments.value);
		if(NOT len(text) OR text EQ "|")
			return { hostname = "", port = "" };
		var parts = listToArray(text, "|", false, true);
		return {
			hostname = arrayLen(parts) GTE 1 ? trim(parts[1]) : "",
			port = arrayLen(parts) GTE 2 ? trim(parts[2]) : ""
		};
	}

	private void function clearDocumentRemoteStruct(required array docConfig){
		arguments.docConfig[3] = {};
	}

	private boolean function isDocumentRemoteOpenOfficeEmpty(required string hostname, required string port){
		return NOT len(trim(arguments.hostname)) AND NOT len(trim("" & arguments.port));
	}

	public struct function setDocumentRemoteOpenOfficeSettings(required string hostname, required string port){
		var host = trim(arguments.hostname);
		var portValue = trim("" & arguments.port);
		var docConfig = readDocumentConfigArray();
		if(isDocumentRemoteOpenOfficeEmpty(host, portValue)){
			clearDocumentRemoteStruct(docConfig);
			syncDocumentRemoteOpenOfficeRuntime("", "");
		}
		else {
			setDocumentRemoteValue(docConfig, "hostname", host);
			setDocumentRemoteValue(docConfig, "port", portValue);
			syncDocumentRemoteOpenOfficeRuntime(host, portValue);
		}
		writeDocumentConfigArray(docConfig);
		return getDocumentRemoteOpenOfficeSettings();
	}

	public void function clearDocumentRemoteOpenOfficeSettings(){
		setDocumentRemoteOpenOfficeSettings("", "");
	}

	private any function getDocumentService(){
		return createObject("java", "coldfusion.server.ServiceFactory").getDocumentService();
	}

	private struct function readDocumentRemoteOpenOfficeRuntime(){
		var docConfig = readDocumentConfigArray();
		return {
			hostname = trim("" & getDocumentRemoteValue(docConfig, "hostname")),
			port = trim("" & getDocumentRemoteValue(docConfig, "port"))
		};
	}

	private void function syncDocumentRemoteOpenOfficeRuntime(required string hostname, required string port){
		try {
			getDocumentService().setOpenOfficeRemoteConfig(trim(arguments.hostname), trim("" & arguments.port));
		}
		catch(any e){
			// Live sync needs coldfusion.server.ServiceFactory, which the CF sandbox blocks for
			// non-admin CFML. neo-document.xml (written by writeDocumentConfigArray) is the source
			// of truth our own getter reads back from, so a live-sync failure here isn't fatal.
		}
	}

	private boolean function isDocumentRemoteOpenOfficeRuntimeEmpty(){
		var runtime = readDocumentRemoteOpenOfficeRuntime();
		return isDocumentRemoteOpenOfficeEmpty(runtime.hostname, runtime.port);
	}

	public boolean function verifyDocumentRemoteOpenOfficeCleared(){
		if(NOT isDocumentRemoteOpenOfficeRuntimeEmpty())
			return false;
		var docConfig = readDocumentConfigArray();
		return NOT structCount(docConfig[3]);
	}

	private string function getDocumentConfigPath(){
		return server.coldfusion.rootdir & "/lib/neo-document.xml";
	}

	private array function readDocumentConfigArray(){
		var data = [];
		cfwddx(action="WDDX2CFML", input=fileRead(getDocumentConfigPath()), output="data");
		return ensureDocumentConfigArray(data);
	}

	private array function ensureDocumentConfigArray(required array docConfig){
		while(arrayLen(arguments.docConfig) LT 4)
			arrayAppend(arguments.docConfig, {});
		if(NOT isStruct(arguments.docConfig[1]))
			arguments.docConfig[1] = {};
		if(NOT isStruct(arguments.docConfig[2]))
			arguments.docConfig[2] = {};
		if(NOT isStruct(arguments.docConfig[3]))
			arguments.docConfig[3] = {};
		if(NOT isStruct(arguments.docConfig[4]) OR NOT structCount(arguments.docConfig[4])){
			arguments.docConfig[4] = {
				localhost = {
					hostname = "127.0.0.1",
					port = 8995,
					ishttps = false,
					isenabled = true,
					engine = "pdfReactor",
					islocal = true,
					weight = 2,
					name = "localhost"
				}
			};
		}
		return arguments.docConfig;
	}

	private void function writeDocumentConfigArray(required array docConfig){
		var safeConfig = ensureDocumentConfigArray(arguments.docConfig);
		var wddxOut = "";
		cfwddx(action="CFML2WDDX", input=safeConfig, output="wddxOut");
		fileWrite(getDocumentConfigPath(), wddxOut);
	}

	private numeric function getDocumentLocalOpenOfficeIndex(){
		if(findNoCase("windows", server.os.name))
			return 1;
		return 2;
	}

	private string function resolveDocumentSettingKey(required string settingName){
		switch(normalizeKey(arguments.settingName)){
			case "openofficedirectory":
				return "openOfficeDirectory";
			case "remoteopenoffice":
				return "remoteOpenOffice";
			default:
				return normalizeKey(arguments.settingName);
		}
	}

	private string function resolveDocumentRemoteKey(required struct remoteStruct, required string settingKey){
		for(var configKey in arguments.remoteStruct.keyList()){
			if(lCase(configKey) EQ lCase(arguments.settingKey))
				return configKey;
		}
		return arguments.settingKey;
	}

	private any function getDocumentRemoteValue(required array docConfig, required string settingKey){
		var remote = arguments.docConfig[3];
		var key = resolveDocumentRemoteKey(remote, arguments.settingKey);
		if(structKeyExists(remote, key))
			return remote[key];
		return "";
	}

	private void function setDocumentRemoteValue(required array docConfig, required string settingKey, required any value){
		var remote = arguments.docConfig[3];
		var key = resolveDocumentRemoteKey(remote, arguments.settingKey);
		remote[key] = arguments.value;
	}

	private string function getDocumentLocalOpenOfficeDirectory(required array docConfig){
		var localIndex = getDocumentLocalOpenOfficeIndex();
		var keys = structKeyList(arguments.docConfig[localIndex]);
		if(NOT len(keys))
			return "";
		return listGetAt(keys, 1);
	}

	private void function setDocumentLocalOpenOfficeDirectory(required array docConfig, required string directoryPath){
		var localIndex = getDocumentLocalOpenOfficeIndex();
		arguments.docConfig[localIndex] = {};
		var path = normalizeAbsolutePath(arguments.directoryPath);
		if(len(path))
			arguments.docConfig[localIndex][path] = {};
	}

	private any function formatDocumentSettingForOutput(required string settingKey, required any value){
		var key = resolveDocumentSettingKey(arguments.settingKey);
		if(key EQ "openofficedirectory")
			return normalizeAbsolutePath(arguments.value);
		if(key EQ "port")
			return trim("" & arguments.value);
		return trim("" & arguments.value);
	}

	private any function coerceDocumentSettingForStore(required string settingKey, required any settingValue){
		var key = resolveDocumentSettingKey(arguments.settingKey);
		if(key EQ "openofficedirectory")
			return normalizeAbsolutePath(arguments.settingValue);
		if(key EQ "port")
			return trim("" & arguments.settingValue);
		return trim("" & arguments.settingValue);
	}

	private boolean function documentSettingsMatch(required string settingName, required any actualValue, required any requestedValue){
		var key = resolveDocumentSettingKey(arguments.settingName);
		if(key EQ "openofficedirectory")
			return compareNoCase(normalizeAbsolutePath(arguments.actualValue), normalizeAbsolutePath(arguments.requestedValue)) EQ 0;
		if(key EQ "remoteopenoffice")
			return normalizeDocumentRemoteOpenOfficeValue(arguments.actualValue) EQ normalizeDocumentRemoteOpenOfficeValue(arguments.requestedValue);
		if(key EQ "port")
			return trim("" & arguments.actualValue) EQ trim("" & arguments.requestedValue);
		return trim("" & arguments.actualValue) EQ trim("" & arguments.requestedValue);
	}

	private string function normalizeDocumentRemoteOpenOfficeValue(required any value){
		var text = trim("" & arguments.value);
		if(NOT len(text) OR text EQ "|")
			return "|";
		var parsed = parseDocumentRemoteOpenOfficeValue(text);
		return lCase(trim(parsed.hostname)) & "|" & trim("" & parsed.port);
	}

	public any function getDocumentSetting(required string settingName){
		ensureConstants();
		var key = resolveDocumentSettingKey(arguments.settingName);
		var docConfig = readDocumentConfigArray();
		if(key EQ "openofficedirectory")
			return formatDocumentSettingForOutput(key, getDocumentLocalOpenOfficeDirectory(docConfig));
		if(key EQ "remoteopenoffice")
			return formatDocumentRemoteOpenOfficeValue(getDocumentRemoteOpenOfficeSettings());
		if(key EQ "hostname")
			return formatDocumentSettingForOutput(key, getDocumentRemoteValue(docConfig, "hostname"));
		if(key EQ "port")
			return formatDocumentSettingForOutput(key, getDocumentRemoteValue(docConfig, "port"));
		throw(message="Unsupported document setting: #arguments.settingName#", type="CCSTest.ConfigError");
	}

	public any function setDocumentSetting(required string settingName, required any settingValue){
		ensureConstants();
		var key = resolveDocumentSettingKey(arguments.settingName);
		var docConfig = readDocumentConfigArray();
		if(key EQ "openofficedirectory"){
			setDocumentLocalOpenOfficeDirectory(docConfig, coerceDocumentSettingForStore(key, arguments.settingValue));
		}
		else if(key EQ "remoteopenoffice"){
			var remote = parseDocumentRemoteOpenOfficeValue("" & arguments.settingValue);
			setDocumentRemoteOpenOfficeSettings(remote.hostname, remote.port);
			return getDocumentSetting(arguments.settingName);
		}
		else if(key EQ "hostname")
			setDocumentRemoteValue(docConfig, "hostname", coerceDocumentSettingForStore(key, arguments.settingValue));
		else if(key EQ "port")
			setDocumentRemoteValue(docConfig, "port", coerceDocumentSettingForStore(key, arguments.settingValue));
		else {
			throw(message="Unsupported document setting: #arguments.settingName#", type="CCSTest.ConfigError");
		}
		writeDocumentConfigArray(docConfig);
		return getDocumentSetting(arguments.settingName);
	}

	private struct function getRuntime(){
		var admin = "";
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		admin = adminUtil.createAdministrator();
		adminUtil.login(getConstants().CF_CONFIG);
		return {
			admin = admin,
			adminUtil = adminUtil,
			api = createObject("component", "CFIDE.adminapi.runtime")
		};
	}

}
