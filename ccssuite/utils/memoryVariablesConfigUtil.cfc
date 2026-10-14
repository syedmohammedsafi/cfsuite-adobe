component output="false" {
	public function init(){
		return this;
	}

	public boolean function isStorageSetting(required string settingName){
		return listFindNoCase("sessionStorage,reuseRedisCachingForSessionStorage,sessionStorageHost,sessionStoragePort,sessionStoragePassword,sessionStorageTimeout,redisSessionStorageCluster,sessionStorageSSLEnabled,CFLoginUseSessionStorageRedis", arguments.settingName) GT 0;
	}

	private string function decodePassword(required string value){
		var prefix = "ccssuite-session-encrypted:";
		if(left(arguments.value, len(prefix)) NEQ prefix)
			return arguments.value;
		try {
			var passwordUtil = createObject("java", "coldfusion.util.PasswordUtils");
			return passwordUtil.decryptPassword(listFirst(mid(arguments.value, len(prefix) + 1, len(arguments.value)), ":"), passwordUtil.getInstance().getSeedValue());
		}
		catch(any failure){
			throw(message="Unable to decode the session-storage password restoration token", type="CCSTest.ConfigError");
		}
	}

	private string function passwordFingerprint(required any value){
		var text = "" & arguments.value;
		return left(text, len("ccssuite-session-encrypted:")) EQ "ccssuite-session-encrypted:"
			? listLast(text, ":") : hash(text, "SHA-256");
	}

	public boolean function valuesMatch(required string settingName, required any expectedValue, required any actualValue){
		if(compareNoCase(arguments.settingName, "sessionStoragePassword") EQ 0)
			return compare(passwordFingerprint(arguments.expectedValue), passwordFingerprint(arguments.actualValue)) EQ 0;
		if(listFindNoCase("sessionStoragePort,sessionStorageTimeout", arguments.settingName))
			return isNumeric(arguments.expectedValue) AND isNumeric(arguments.actualValue) AND val(arguments.expectedValue) EQ val(arguments.actualValue);
		if(listFindNoCase("reuseRedisCachingForSessionStorage,redisSessionStorageCluster,sessionStorageSSLEnabled,CFLoginUseSessionStorageRedis", arguments.settingName))
			return isBoolean(arguments.expectedValue) AND isBoolean(arguments.actualValue) AND javaCast("boolean", arguments.expectedValue) EQ javaCast("boolean", arguments.actualValue);
		return compareNoCase(trim("" & arguments.expectedValue), trim("" & arguments.actualValue)) EQ 0;
	}

	private any function readSavedSetting(required string settingName){
		var key = lCase(arguments.settingName);
		var templateSetting = listFindNoCase("reuseRedisCachingForSessionStorage,redisSessionStorageCluster,sessionStorageSSLEnabled,CFLoginUseSessionStorageRedis", key) GT 0;
		var savedKey = key EQ "sessionstoragesslenabled" ? "sslsessionstorage" : key;
		var config = xmlParse(fileRead(server.coldfusion.rootdir & "/lib/neo-runtime.xml"));
		var section = templateSetting ? "templateCacheSize" : "sessionStorageHost";
		var entries = xmlSearch(config, "//struct[var[@name='#section#']]/var[translate(@name,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='#savedKey#']/*");
		if(NOT arrayLen(entries)){
			if(listFindNoCase("reuseRedisCachingForSessionStorage,sessionStorageSSLEnabled,CFLoginUseSessionStorageRedis", key))
				return "false";
			if(listFindNoCase("sessionStorageHost,sessionStoragePassword", key))
				return "";
			throw(message="Saved session-storage setting #arguments.settingName# is unavailable", type="CCSTest.ConfigError");
		}
		if(arrayLen(entries) NEQ 1)
			throw(message="Ambiguous saved session-storage setting #arguments.settingName#", type="CCSTest.ConfigError");
		return structKeyExists(entries[1].xmlAttributes, "value") ? entries[1].xmlAttributes.value : entries[1].xmlText;
	}

	public any function getSetting(required string settingName){
		if(NOT isStorageSetting(arguments.settingName))
			throw(message="Unsupported session-storage setting", type="CCSTest.ConfigError");
		var value = "";
		try {
			var service = createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService();
			switch(lCase(arguments.settingName)){
				case "sessionstorage": value = service.getSessionStorage(); break;
				case "reuserediscachingforsessionstorage": value = service.getReuseRedisCachingForSessionStorage(); break;
				case "sessionstoragehost": value = service.getSessionStorageHost(); break;
				case "sessionstorageport": value = service.getSessionStoragePort(); break;
				case "sessionstoragepassword": value = service.getSessionStoragePassword(); break;
				case "sessionstoragetimeout": value = service.getSessionStorageTimeout(); break;
				case "redissessionstoragecluster": value = service.getRedisSessionStorageCluster(); break;
				case "sessionstoragesslenabled": value = service.getSessionStorageSSLEnabled(); break;
				case "cfloginusesessionstorageredis": value = service.getCFLoginUseSessionStorageRedis(); break;
			}
		}
		catch(any failure){
			if(NOT (findNoCase("Permission denied for creating Java object", failure.message)
				AND findNoCase("ColdFusion package has been disabled", failure.detail)))
				rethrow;
			value = readSavedSetting(arguments.settingName);
		}
		if(isNull(value)){
			if(compareNoCase(arguments.settingName, "sessionStoragePassword") NEQ 0)
				throw(message="No runtime value for #arguments.settingName#", type="CCSTest.ConfigError");
			value = "";
		}
		if(compareNoCase(arguments.settingName, "sessionStoragePassword") EQ 0 AND len(value)){
			var token = "ccssuite-session-encrypted:" & value;
			return token & ":" & hash(decodePassword(token), "SHA-256");
		}
		if(isBoolean(value) AND NOT isNumeric(value))
			return javaCast("boolean", value) ? "true" : "false";
		return value;
	}

	public any function setSetting(required any runtimeApi, required string settingName, required any settingValue){
		if(valuesMatch(arguments.settingName, arguments.settingValue, getSetting(arguments.settingName)))
			return getSetting(arguments.settingName);
		var value = arguments.settingValue;
		if(compareNoCase(arguments.settingName, "sessionStoragePassword") EQ 0)
			value = decodePassword("" & value);
		if(listFindNoCase("sessionStoragePort,sessionStorageTimeout", arguments.settingName))
			value = javaCast("int", value);
		if(listFindNoCase("reuseRedisCachingForSessionStorage,redisSessionStorageCluster,sessionStorageSSLEnabled,CFLoginUseSessionStorageRedis", arguments.settingName))
			value = javaCast("boolean", value);
		if(listFindNoCase("sessionStorageSSLEnabled,CFLoginUseSessionStorageRedis", arguments.settingName)){
			var service = createObject("java", "coldfusion.server.ServiceFactory").getRuntimeService();
			if(compareNoCase(arguments.settingName, "sessionStorageSSLEnabled") EQ 0)
				service.setSessionStorageSSLEnabled(value);
			else
				service.setCFLoginUseSessionStorageRedis(value);
			service.store();
		}
		else {
			try {
				arguments.runtimeApi.setRuntimeProperty(arguments.settingName, value);
			}
			catch(any failure){
				if(compareNoCase(arguments.settingName, "sessionStoragePassword") EQ 0)
					throw(message="Unable to set the session-storage password", type="CCSTest.ConfigError");
				rethrow;
			}
		}
		return getSetting(arguments.settingName);
	}
}