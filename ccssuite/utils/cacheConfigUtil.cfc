/**
* Read/write for the CF Administrator "Caching" settings page (Template Cache Size, Trusted Cache,
* Save Class Files, Component Cache, Cache Template In Request, Cache Web Server Paths), via the
* CFIDE.adminapi.runtime getCacheProperty/setCacheProperty generic accessor.
*/
component output="false" {

	public function init(){
		return this;
	}

	private void function ensureConstants(){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
	}

	private struct function getRuntime(){
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		ensureConstants();
		var admin = adminUtil.createAdministrator();
		adminUtil.login(application.constants.CF_CONFIG);
		return {
			admin = admin,
			adminUtil = adminUtil,
			api = createObject("component", "CFIDE.adminapi.runtime")
		};
	}

	private string function resolveCachePropertyName(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case "cachewebserverpaths":
				return "cacheRealPath";
			default:
				return arguments.settingName;
		}
	}

	private any function formatCacheValue(required any value){
		if(isBoolean(arguments.value) AND NOT isNumeric(arguments.value))
			return arguments.value ? "true" : "false";
		return arguments.value;
	}

	private boolean function isRedisSetting(required string settingName){
		return listFindNoCase("redisCacheStorageHost,redisCacheStoragePort,redisCacheStoragePassword,redisSessionStorageCluster,redisCacheStorageIsSSL,redisTimeToIdleSeconds,redisTimeToLiveSeconds,redisMaxElementsInMemory,redisEternal", trim(arguments.settingName)) GT 0;
	}

	private string function decodeRedisPassword(required string value){
		var prefix = "ccssuite-redis-encrypted:";
		if(left(arguments.value, len(prefix)) NEQ prefix)
			return arguments.value;
		var passwordUtil = createObject("java", "coldfusion.util.PasswordUtils");
		try {
			return passwordUtil.decryptPassword(listFirst(mid(arguments.value, len(prefix) + 1, len(arguments.value)), ":"), passwordUtil.getInstance().getSeedValue());
		}
		catch(any failure){
			throw(message="Unable to decode Redis password restoration token", type="CCSTest.ConfigError");
		}
	}

	public boolean function cacheValuesMatch(required string settingName, required any expectedValue, required any actualValue){
		if(compareNoCase(arguments.settingName, "redisCacheStoragePassword") EQ 0){
			var expectedFingerprint = left("" & arguments.expectedValue, len("ccssuite-redis-encrypted:")) EQ "ccssuite-redis-encrypted:" ? listLast(arguments.expectedValue, ":") : hash("" & arguments.expectedValue, "SHA-256");
			var actualFingerprint = left("" & arguments.actualValue, len("ccssuite-redis-encrypted:")) EQ "ccssuite-redis-encrypted:" ? listLast(arguments.actualValue, ":") : hash("" & arguments.actualValue, "SHA-256");
			return compare(expectedFingerprint, actualFingerprint) EQ 0;
		}
		return arguments.expectedValue EQ arguments.actualValue;
	}

	private any function getRedisSetting(required string settingName){
		var key = lCase(trim(arguments.settingName));
		if(key EQ "rediscachestorageport"){
			// Read the live value; CCS/store() can rewrite neo-runtime.xml during a test.
			return createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService().getRedisCacheStoragePort();
		}
		if(listFindNoCase("redisTimeToIdleSeconds,redisTimeToLiveSeconds,redisMaxElementsInMemory,redisEternal", key)){
			var runtimeService = createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService();
			var value = "";
			switch(key){
				case "redistimetoidleseconds": value = runtimeService.getredisServerMaxIdle(); break;
				case "redistimetoliveseconds": value = runtimeService.getredisServerMaxLife(); break;
				case "redismaxelementsinmemory": value = runtimeService.getredisServerMaxObjects(); break;
				case "rediseternal":
					value = runtimeService.getRedisServerEternal();
					if(NOT len(trim(value)))
						value = "false";
					break;
			}
			if((key EQ "rediseternal" AND NOT isBoolean(value)) OR (key NEQ "rediseternal" AND NOT isNumeric(value)))
				throw(message="Invalid saved Redis cache policy: #arguments.settingName#", type="CCSTest.ConfigError");
			return formatCacheValue(value);
		}
		var config = xmlParse(fileRead(server.coldfusion.rootdir & "/lib/neo-runtime.xml"));
		var entries = xmlSearch(config, "//struct[var[@name='templateCacheSize']]/var[translate(@name,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='#key#']/*");
		if(arrayLen(entries) EQ 0 AND key EQ "redissessionstoragecluster")
			return "false";
		if(arrayLen(entries) NEQ 1)
			throw(message="Redis setting #arguments.settingName# unavailable in neo-runtime.xml", type="CCSTest.ConfigError");
		var savedValue = structKeyExists(entries[1].xmlAttributes, "value") ? entries[1].xmlAttributes.value : entries[1].xmlText;
		if(key EQ "rediscachestoragepassword"){
			if(NOT len(savedValue))
				return "";
			var token = "ccssuite-redis-encrypted:" & savedValue;
			return token & ":" & hash(decodeRedisPassword(token), "SHA-256");
		}
		return formatCacheValue(savedValue);
	}

	private any function setRedisSetting(required string settingName, required any settingValue){
		var runtimeService = createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService();
		switch(lCase(trim(arguments.settingName))){
			case "rediscachestoragehost": runtimeService.setRedisCacheStorageHost(javaCast("string", arguments.settingValue)); break;
			case "rediscachestorageport": runtimeService.setRedisCacheStoragePort(javaCast("int", arguments.settingValue)); break;
			case "rediscachestoragepassword": runtimeService.setRedisCacheStoragePassword(javaCast("string", decodeRedisPassword("" & arguments.settingValue))); break;
			case "redissessionstoragecluster": runtimeService.setRedisSessionStorageCluster(javaCast("boolean", arguments.settingValue)); break;
			case "rediscachestorageisssl": runtimeService.setRedisCacheStorageIsSSL(javaCast("boolean", arguments.settingValue)); break;
			case "redistimetoidleseconds": runtimeService.setredisServerMaxIdle(javaCast("long", arguments.settingValue)); break;
			case "redistimetoliveseconds": runtimeService.setredisServerMaxLife(javaCast("long", arguments.settingValue)); break;
			case "redismaxelementsinmemory": runtimeService.setredisServerMaxObjects(javaCast("long", arguments.settingValue)); break;
			case "rediseternal": runtimeService.setRedisServerEternal(javaCast("string", arguments.settingValue)); break;
		}
		runtimeService.store();
		return getRedisSetting(arguments.settingName);
	}

	private any function getMemcachedRuntimeSetting(required string settingName){
		var key = lCase(trim(arguments.settingName));
		var runtimeService = createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService();
		var value = "";
		switch(key){
			case "memcachedtimetoidleseconds": value = runtimeService.getMemcachedServerMaxIdle(); break;
			case "memcachedtimetoliveseconds": value = runtimeService.getMemcachedServerMaxLife(); break;
			case "memcachedmaxelementsinmemory": value = runtimeService.getMemcachedServerMaxObjects(); break;
			case "memcachedeternal":
				value = runtimeService.getMemcachedServerEternal();
				if(NOT len(trim(value)))
					value = "false";
				break;
		}
		if((key EQ "memcachedeternal" AND NOT isBoolean(value)) OR (key NEQ "memcachedeternal" AND NOT isNumeric(value)))
			throw(message="Invalid saved Memcached setting #arguments.settingName#", type="CCSTest.ConfigError");
		return formatCacheValue(value);
	}

	private boolean function isJcsSetting(required string settingName){
		return listFindNoCase("jcsdsnname,jcsservermaxidle,jcsservermaxlife,jcsservermaxobjects,jcsservereternal", trim(arguments.settingName)) GT 0;
	}

	private any function getJcsSetting(required string settingName){
		var runtimeService = createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService();
		switch(lCase(trim(arguments.settingName))){
			case "jcsdsnname": return runtimeService.getJCSClusterDsnName();
			case "jcsservermaxidle": return runtimeService.getJCSServerMaxIdle();
			case "jcsservermaxlife": return runtimeService.getJCSServerMaxLife();
			case "jcsservermaxobjects": return runtimeService.getJCSServerMaxObjects();
			case "jcsservereternal":
				var value = runtimeService.getJCSServerEternal();
				return len(trim(value)) ? formatCacheValue(value) : "false";
		}
	}

	private any function setJcsSetting(required string settingName, required any settingValue){
		var runtimeService = createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService();
		switch(lCase(trim(arguments.settingName))){
			case "jcsservermaxidle": runtimeService.setJCSServerMaxIdle(javaCast("long", arguments.settingValue)); break;
			case "jcsservermaxlife": runtimeService.setJCSServerMaxLife(javaCast("long", arguments.settingValue)); break;
			case "jcsservermaxobjects": runtimeService.setJCSServerMaxObjects(javaCast("long", arguments.settingValue)); break;
			case "jcsservereternal": runtimeService.setJCSServerEternal(javaCast("string", arguments.settingValue)); break;
		}
		runtimeService.store();
		return getJcsSetting(arguments.settingName);
	}

	private any function getSavedCacheSetting(required string settingName){
		var key = lCase(trim(arguments.settingName));
		var policyNames = {
			jcsservermaxidle="jcs.default.elementattributes.IdleTime",
			jcsservermaxlife="jcs.default.elementattributes.MaxLife",
			jcsservermaxobjects="jcs.default.cacheattributes.MaxObjects",
			jcsservereternal="jcs.default.elementattributes.IsEternal",
			redistimetoidleseconds="timeToIdleSeconds",
			redistimetoliveseconds="timeToLiveSeconds",
			redismaxelementsinmemory="maxElementsInMemory",
			rediseternal="eternal",
			memcachedtimetoidleseconds="timeToIdleSeconds",
			memcachedtimetoliveseconds="timeToLiveSeconds",
			memcachedmaxelementsinmemory="maxElementsInMemory",
			memcachedeternal="eternal"
		};
		var libPath = server.coldfusion.rootdir & "/lib/";
		if(structKeyExists(policyNames, key)){
			var policyFile = left(key, 3) EQ "jcs" ? "cache.ccf" : (left(key, 5) EQ "redis" ? "rediscache.properties" : "memcachedcache.properties");
			var properties = createObject("java", "java.util.Properties").init();
			var reader = createObject("java", "java.io.StringReader").init(fileRead(libPath & policyFile));
			try {
				properties.load(reader);
			}
			finally {
				reader.close();
			}
			var defaultValue = findNoCase("eternal", key) ? "false" : (findNoCase("objects", key) OR findNoCase("elements", key) ? "10000" : "86400");
			var policyValue = properties.getProperty(policyNames[key], defaultValue);
			if(findNoCase("eternal", key) ? NOT isBoolean(policyValue) : NOT isNumeric(policyValue))
				throw(message="Invalid saved cache policy: #arguments.settingName#", type="CCSTest.ConfigError");
			return formatCacheValue(policyValue);
		}
		var savedNames = {
			jcsdsnname="jcsclusterdsnname",
			enableinternalquerycache="enableinternalquerycache",
			maxcachecount="maxcachecount",
			rediscachestoragehost="rediscachestoragehost",
			rediscachestorageport="rediscachestorageport",
			redissessionstoragecluster="redissessionstoragecluster",
			rediscachestorageisssl="rediscachestorageisssl"
		};
		if(NOT structKeyExists(savedNames, key))
			throw(message="No saved-value cache reader for #arguments.settingName#", type="CCSTest.ConfigError");
		var configFile = key EQ "maxcachecount" ? "neo-datasource.xml" : "neo-runtime.xml";
		var config = xmlParse(fileRead(libPath & configFile));
		var entries = xmlSearch(config, "//var[translate(@name,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='#savedNames[key]#']/*");
		if(NOT arrayLen(entries)){
			if(key EQ "jcsdsnname")
				return "";
			if(listFindNoCase("redissessionstoragecluster,enableinternalquerycache", key))
				return "false";
			throw(message="Saved cache setting #arguments.settingName# unavailable in #configFile#", type="CCSTest.ConfigError");
		}
		var savedValue = structKeyExists(entries[1].xmlAttributes, "value") ? entries[1].xmlAttributes.value : entries[1].xmlText;
		for(var entry in entries){
			var entryValue = structKeyExists(entry.xmlAttributes, "value") ? entry.xmlAttributes.value : entry.xmlText;
			if(compare("" & savedValue, "" & entryValue) NEQ 0)
				throw(message="Conflicting saved cache values for #arguments.settingName#", type="CCSTest.ConfigError");
		}
		return formatCacheValue(savedValue);
	}

	public any function getCacheSetting(required string settingName){
		var runtime = getRuntime();
		try {
			if(compareNoCase(arguments.settingName, "enableInternalQueryCache") EQ 0)
				return formatCacheValue(createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService().isInternalCacheForQueryEnabled());
			if(compareNoCase(arguments.settingName, "maxcachecount") EQ 0)
				return createObject("java", "coldfusion.server.ServiceFactory").getDataSourceService().getMaxQueryCount();
			if(isJcsSetting(arguments.settingName))
				return getJcsSetting(arguments.settingName);
			if(isRedisSetting(arguments.settingName))
				return getRedisSetting(arguments.settingName);
			if(lCase(trim(arguments.settingName)) EQ "memcachedserver")
				return runtime.api.getMemcachedServer();
			if(listFindNoCase("memcachedTimeToIdleSeconds,memcachedTimeToLiveSeconds,memcachedMaxElementsInMemory,memcachedEternal", trim(arguments.settingName)))
				return getMemcachedRuntimeSetting(arguments.settingName);
			return formatCacheValue(runtime.api.getCacheProperty(resolveCachePropertyName(arguments.settingName)));
		}
		catch(any failure){
			if(findNoCase("Permission denied for creating Java object", failure.message)
				AND findNoCase("ColdFusion package has been disabled", failure.detail))
				return getSavedCacheSetting(arguments.settingName);
			rethrow;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public any function setCacheSetting(required string settingName, required any settingValue){
		var runtime = getRuntime();
		try {
			if(compareNoCase(arguments.settingName, "jcsdsnname") EQ 0){
				runtime.api.setJCSClusterDsnName(dsn=arguments.settingValue, createTables=false);
				return getSavedCacheSetting(arguments.settingName);
			}
			if(compareNoCase(arguments.settingName, "enableInternalQueryCache") EQ 0){
				var queryRuntimeService = createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService();
				queryRuntimeService.setInternalCacheForQueryEnabled(javaCast("boolean", arguments.settingValue));
				queryRuntimeService.store();
				return formatCacheValue(queryRuntimeService.isInternalCacheForQueryEnabled());
			}
			if(compareNoCase(arguments.settingName, "maxcachecount") EQ 0){
				var datasourceService = createObject("java", "coldfusion.server.ServiceFactory").getDataSourceService();
				datasourceService.setMaxQueryCount(javaCast("int", arguments.settingValue));
				datasourceService.store();
				return datasourceService.getMaxQueryCount();
			}
			if(isJcsSetting(arguments.settingName))
				return setJcsSetting(arguments.settingName, arguments.settingValue);
			if(isRedisSetting(arguments.settingName))
				return setRedisSetting(arguments.settingName, arguments.settingValue);
			if(lCase(trim(arguments.settingName)) EQ "memcachedserver"){
				runtime.api.setMemcachedServer(arguments.settingValue);
				return runtime.api.getMemcachedServer();
			}
			if(listFindNoCase("memcachedTimeToIdleSeconds,memcachedTimeToLiveSeconds,memcachedMaxElementsInMemory,memcachedEternal", trim(arguments.settingName))){
				var runtimeService = createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService();
				switch(lCase(trim(arguments.settingName))){
					case "memcachedtimetoidleseconds":
						runtimeService.setMemcachedServerMaxIdle(javaCast("long", arguments.settingValue));
						break;
					case "memcachedtimetoliveseconds":
						runtimeService.setMemcachedServerMaxLife(javaCast("long", arguments.settingValue));
						break;
					case "memcachedmaxelementsinmemory":
						runtimeService.setMemcachedServerMaxObjects(javaCast("long", arguments.settingValue));
						break;
					case "memcachedeternal":
						runtimeService.setMemcachedServerEternal(javaCast("string", arguments.settingValue));
						break;
				}
				runtimeService.store();
				return getMemcachedRuntimeSetting(arguments.settingName);
			}
			runtime.api.setCacheProperty(resolveCachePropertyName(arguments.settingName), arguments.settingValue);
			return formatCacheValue(runtime.api.getCacheProperty(resolveCachePropertyName(arguments.settingName)));
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

}
