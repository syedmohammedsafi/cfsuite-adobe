component output="false" {
	public function init(){ return this; }

	public struct function getFieldMap(){
		return {
			dsnName="name", driverName="type", mongo_host="host", mongo_port="port",
			mongo_replicaSetName="replicaSet", mongo_enableSSL="ssl", mongo_DnsSeedlist="dnsSeedList",
			mongo_authMechanism="authMechanism", mongo_authUsername="username", mongo_authPassword="password",
			mongo_authSource="authSource", mongo_gssapiServiceName="gssapiServiceName", mongo_readConcern="readConcern",
			mongo_readPref="readPreference", mongo_maxStaleness="maxStalenessSeconds", mongo_w="w",
			mongo_writeTimeout="wtimeout", mongo_j="j", mongo_connTimeout="connectTimeout",
			mongo_maxConnPoolSize="maxPoolSize", mongo_minConnPoolSize="minPoolSize",
			mongo_maxConnLifeTime="maxConnectionLifeTime", mongo_maxConnIdleTime="maxConnectionIdleTime",
			mongo_maxConnPoolWaitTime="maxWaitQueueTimeout", mongo_maxConnPoolWaitSize="maxWaitQueueSize",
			mongo_heartbeatFreq="heartbeatFrequency", mongo_minHeartbeatFreq="minHeartbeatFrequency"
		};
	}

	public void function requireSetting(required string settingName){
		if(NOT structKeyExists(getFieldMap(), arguments.settingName))
			throw(type="CCSTest.UnsupportedNoSQL", message="Unsupported NoSQL field identifier: " & arguments.settingName);
	}

	public struct function getRuntime(){
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		var admin = adminUtil.createAdministrator();
		try {
			adminUtil.login(application.constants.CF_CONFIG);
			return {
				adminUtil = adminUtil,
				admin = admin,
				api = createObject("component", "CFIDE.adminapi.nosql_datasource"),
				service = createObject("java", "coldfusion.server.ServiceFactory").getNoSQLService()
			};
		}
		catch(any failure){
			adminUtil.logout(admin);
			throw(type="CCSTest.NoSQLApi", message="NoSQL API unavailable: " & failure.message);
		}
	}

	public void function requireSupported(required string settingName){
		requireSetting(arguments.settingName);
		if(arguments.settingName EQ "mongo_maxStaleness")
			return;
		var runtime = getRuntime();
		try {
			var supported = false;
			for(var method in getMetadata(runtime.api).functions){
				if(compareNoCase(method.name, "setMongoDataSource") EQ 0){
					for(var parameter in method.parameters){
						if(compareNoCase(parameter.name, getFieldMap()[arguments.settingName]) EQ 0)
							supported = true;
					}
				}
			}
			if(NOT supported)
				throw(type="CCSTest.UnsupportedNoSQL", message="Installed setMongoDataSource does not expose " & getFieldMap()[arguments.settingName] & "; no configuration changed.");
		}
		finally { runtime.adminUtil.logout(runtime.admin); }
	}

	public struct function decodeState(required any value){
		try {
			var state = deserializeJSON("" & arguments.value);
			if(NOT isStruct(state) OR NOT structKeyExists(state, "entries") OR NOT isStruct(state.entries))
				throw(type="CCSTest.NoSQLPayload");
			return state;
		}
		catch(any failure){
			throw(type="CCSTest.NoSQLPayload", message="Invalid NoSQL fixture payload: " & failure.message);
		}
	}

		public string function getTestDsnName(){
		return "CCSTestMongoDSN";
	}

	public struct function getDefaultMongoConfig(){
		return {
			host = "127.0.0.1",
			port = 27017,
			heartbeatFrequency = 10000,
			minHeartbeatFrequency = 2000,
			connectTimeout = 2000,
			maxConnectionIdleTime = 2000,
			maxConnectionLifeTime = 2000,
			maxPoolSize = 20,
			minPoolSize = 0,
			maxWaitQueueSize = 10,
			maxWaitQueueTimeout = 2000,
			readConcern = "majority",
			readPreference = "primary",
			w = "1",
			wtimeout = 2000,
			j = false,
			ssl = false,
			dnsSeedList = false,
			maxStalenessSeconds = 0,
			authMechanism = "",
			authSource = "",
			gssapiServiceName = "",
			username = "",
			password = "",
			replicaSet = ""
		};
	}

/**
	 * Read the active MongoDB datasource from the Admin API dynamically.
	 * Returns a state struct: { entries: { dsnName: {field:val,...} } }
	 */
	private any function getCaseInsensitive(required struct str, required string keyName, any defaultVal=""){
		if(structKeyExists(arguments.str, arguments.keyName)) return arguments.str[arguments.keyName];
		var uKey = uCase(arguments.keyName);
		if(structKeyExists(arguments.str, uKey)) return arguments.str[uKey];
		var lKey = lCase(arguments.keyName);
		if(structKeyExists(arguments.str, lKey)) return arguments.str[lKey];
		for(var k in arguments.str){
			if(compareNoCase(k, arguments.keyName) EQ 0) return arguments.str[k];
		}
		return arguments.defaultVal;
	}

	private boolean function hasCaseInsensitive(required struct str, required string keyName){
		if(structKeyExists(arguments.str, arguments.keyName)) return true;
		var uKey = uCase(arguments.keyName);
		if(structKeyExists(arguments.str, uKey)) return true;
		var lKey = lCase(arguments.keyName);
		if(structKeyExists(arguments.str, lKey)) return true;
		for(var k in arguments.str){
			if(compareNoCase(k, arguments.keyName) EQ 0) return true;
		}
		return false;
	}

	public struct function readState(required struct runtime){
		var all = arguments.runtime.api.getDatasources();
		var entries = structNew("ordered");
		var fieldMap = getFieldMap();
		var testDsn = getTestDsnName();

		var chosenDsn = "";
		if(hasCaseInsensitive(all, testDsn) AND isStruct(getCaseInsensitive(all, testDsn))){
			chosenDsn = testDsn;
		}
		else if(hasCaseInsensitive(all, testDsn & "_Updated") AND isStruct(getCaseInsensitive(all, testDsn & "_Updated"))){
			chosenDsn = testDsn & "_Updated";
		}

		if(len(chosenDsn)){
			var config = structNew("ordered");
			var dsnEntry = getCaseInsensitive(all, chosenDsn);
			var rawDs = {};
			try { rawDs = arguments.runtime.service.getDatasource(chosenDsn); } catch(any e){}
			for(var field in fieldMap){
				var property = fieldMap[field];
				if(compareNoCase("name", property) EQ 0)
					continue;
				if(compareNoCase("type", property) EQ 0){
					config[property] = "mongodb";
					continue;
				}
				if(hasCaseInsensitive(dsnEntry, property)){
					config[property] = getCaseInsensitive(dsnEntry, property);
				}
				else if(isStruct(rawDs) AND hasCaseInsensitive(rawDs, property)){
					config[property] = getCaseInsensitive(rawDs, property);
				}
				else {
					config[property] = "";
				}
			}
			entries[chosenDsn] = config;
		}

		return {entries=entries};
	}

	public string function getSetting(required string settingName){
		requireSetting(arguments.settingName);
		var runtime = getRuntime();
		try { return serializeJSON(readState(runtime)); }
		catch(any failure){ throw(type="CCSTest.NoSQLApi", message="NoSQL fixture read failed: " & failure.message); }
		finally { runtime.adminUtil.logout(runtime.admin); }
	}

	public string function setSetting(required string settingName, required any value){
		requireSetting(arguments.settingName);
		var valStr = trim("" & arguments.value);
		var runtime = getRuntime();
		try {
			if(NOT len(valStr) OR valStr EQ "{}" OR valStr EQ '{"entries":{}}' OR valStr EQ '{"ENTRIES":{}}'){
				try { runtime.api.deleteMongoDatasource(getTestDsnName()); try { runtime.service.store(); } catch(any se){} } catch(any e){}
				try { runtime.api.deleteMongoDatasource(getTestDsnName() & "_Updated"); } catch(any e){}
				return serializeJSON({entries={}});
			}

			var state = decodeState(arguments.value);
			var all = runtime.api.getDatasources();
			var dsnNames = structKeyArray(state.entries);
			if(NOT arrayLen(dsnNames)){
				try { runtime.api.deleteMongoDatasource(getTestDsnName()); try { runtime.service.store(); } catch(any se){} } catch(any e){}
				try { runtime.api.deleteMongoDatasource(getTestDsnName() & "_Updated"); } catch(any e){}
				return serializeJSON({entries={}});
			}
			var targetName = dsnNames[1];
			var targetUpdates = state.entries[targetName];

			var baseConfig = getDefaultMongoConfig();


			// Apply target updates
			for(var prop in targetUpdates){
				baseConfig[prop] = targetUpdates[prop];
			}

			var config = {};
			for(var field in getFieldMap()){
				var property = getFieldMap()[field];
				if(listFindNoCase("name,type,maxStalenessSeconds", property))
					continue;
				if(structKeyExists(baseConfig, property)){
					var propVal = baseConfig[property];
					if(property EQ "authMechanism" AND NOT len(trim("" & propVal)))
						continue;
					if(listFindNoCase("authSource,gssapiServiceName,username,password", property) AND NOT len(trim("" & propVal)))
						continue;
					if(property EQ "replicaSet" AND NOT len(trim("" & propVal)))
						continue;
					config[property] = propVal;
				}
			}
			config.name = targetName;
			config.type = "mongodb";
			if(structKeyExists(config, "authMechanism") AND len(trim("" & config.authMechanism))){
				if(NOT structKeyExists(config, "username") OR NOT len(trim("" & config.username))){
					config.username = "ccs_mongo_user";
					baseConfig.username = "ccs_mongo_user";
				}
				if(compareNoCase(config.authMechanism, "GSSAPI") EQ 0){
					structDelete(config, "password");
					baseConfig.password = "";
				}
				else {
					if(NOT structKeyExists(config, "password") OR NOT len(trim("" & config.password))){
						config.password = "ccs_mongo_pass";
						baseConfig.password = "ccs_mongo_pass";
					}
				}
			}

			if(structKeyExists(config, "username") AND len(trim("" & config.username))){
				if(NOT structKeyExists(config, "authMechanism") OR NOT len(trim("" & config.authMechanism))){
					config.authMechanism = "SCRAM-SHA-256";
					baseConfig.authMechanism = "SCRAM-SHA-256";
				}
				if(compareNoCase(config.authMechanism, "GSSAPI") NEQ 0){
					if(NOT structKeyExists(config, "password") OR NOT len(trim("" & config.password))){
						config.password = "ccs_mongo_pass";
						baseConfig.password = "ccs_mongo_pass";
					}
				}
			}

			for(var k in ["authMechanism", "AUTHMECHANISM", "username", "USERNAME", "password", "PASSWORD", "authSource", "AUTHSOURCE", "gssapiServiceName", "GSSAPISERVICENAME", "replicaSet", "REPLICASET"]){
				if(structKeyExists(baseConfig, k) AND NOT len(trim("" & baseConfig[k])))
					structDelete(baseConfig, k);
				if(structKeyExists(config, k) AND NOT len(trim("" & config[k])))
					structDelete(config, k);
			}

			runtime.api.setMongoDataSource(argumentCollection=config);
			try { runtime.service.store(); } catch(any e){}
			if(structKeyExists(baseConfig, "maxStalenessSeconds") AND len(trim("" & baseConfig.maxStalenessSeconds))){
				try { runtime.service.setDataSource(targetName, "mongodb", baseConfig); } catch(any e){}
			}

			if(targetName NEQ getTestDsnName()){
				try { runtime.api.deleteMongoDatasource(getTestDsnName()); try { runtime.service.store(); } catch(any se){} } catch(any e){}
			}

			return serializeJSON(readState(runtime));
		}
		catch(any failure){ throw(type="CCSTest.NoSQLApi", message="NoSQL field update failed: " & failure.message & " " & failure.detail); }
		finally { runtime.adminUtil.logout(runtime.admin); }
	}

	public struct function getListSummary(){
		var runtime = getRuntime();
		try {
			var all = runtime.api.getDatasources();
			var mongoCount = 0;
			for(var name in all){
				if(isStruct(all[name]) AND structKeyExists(all[name], "type") AND compareNoCase(all[name].type, "mongodb") EQ 0)
					mongoCount++;
			}
			return {configurationWrites=false, datasourceCount=structCount(all), mongodbCount=mongoCount};
		}
		catch(any failure){ throw(type="CCSTest.NoSQLApi", message="NoSQL list read failed: " & failure.message); }
		finally { runtime.adminUtil.logout(runtime.admin); }
	}
}
