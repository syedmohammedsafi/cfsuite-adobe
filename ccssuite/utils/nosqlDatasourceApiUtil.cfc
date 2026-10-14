component output="false" {
        public function init(){ return this; }

        public array function getReservedNames(){
                return ["CCSSuiteMongoA", "CCSSuiteMongoB"];
        }

        public struct function getFieldMap(){
                return {dsnName="name", driverName="type", mongo_host="host", mongo_port="port",
                        mongo_replicaSetName="replicaSet", mongo_enableSSL="ssl", mongo_DnsSeedlist="dnsSeedList",
                        mongo_authMechanism="authMechanism", mongo_authUsername="username", mongo_authPassword="password",
                        mongo_authSource="authSource", mongo_gssapiServiceName="gssapiServiceName", mongo_readConcern="readConcern",
                        mongo_readPref="readPreference", mongo_maxStaleness="maxStalenessSeconds", mongo_w="w",
                        mongo_writeTimeout="wtimeout", mongo_j="j", mongo_connTimeout="connectTimeout",
                        mongo_maxConnPoolSize="maxPoolSize", mongo_minConnPoolSize="minPoolSize",
                        mongo_maxConnLifeTime="maxConnectionLifeTime", mongo_maxConnIdleTime="maxConnectionIdleTime",
                        mongo_maxConnPoolWaitTime="maxWaitQueueTimeout", mongo_maxConnPoolWaitSize="maxWaitQueueSize",
                        mongo_heartbeatFreq="heartbeatFrequency", mongo_minHeartbeatFreq="minHeartbeatFrequency"};
        }

        public void function requireSetting(required string settingName){
                if(NOT structKeyExists(getFieldMap(), arguments.settingName))
                        throw(type="CCSTest.UnsupportedNoSQL", message="Unsupported NoSQL field identifier.");
        }

        private struct function getRuntime(){
                var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
                var admin = adminUtil.createAdministrator();
                try {
                        adminUtil.login(application.constants.CF_CONFIG);
                        return {adminUtil=adminUtil, admin=admin,
                                api=createObject("component", "CFIDE.adminapi.nosql_datasource"),
                                service=createObject("java", "coldfusion.server.ServiceFactory").getNoSQLService()};
                }
                catch(any failure){
                        adminUtil.logout(admin);
                        throw(type="CCSTest.NoSQLApi", message="NoSQL API unavailable; details withheld.");
                }
        }

        public void function requireSupported(required string settingName){
                requireSetting(arguments.settingName);
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
                        if(arguments.settingName EQ "mongo_authPassword" AND
                                compare(runtime.service.encryptPassword("ccs-synthetic-check"), runtime.service.encryptPassword("ccs-synthetic-check")) NEQ 0)
                                throw(type="CCSTest.UnsupportedNoSQL", message="Installed password encryption cannot be verified deterministically; no configuration changed.");
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
                        throw(type="CCSTest.NoSQLPayload", message="Invalid NoSQL fixture payload; details withheld.");
                }
        }

        public boolean function isOwnedFixture(required string name, required struct config){
                return arrayFindNoCase(getReservedNames(), arguments.name) GT 0
                        AND structKeyExists(arguments.config, "type") AND compareNoCase(arguments.config.type, "mongodb") EQ 0
                        AND structKeyExists(arguments.config, "host") AND listFind("127.0.0.1,127.0.0.2", arguments.config.host) GT 0
                        AND structKeyExists(arguments.config, "port") AND listFind("1,2", "" & arguments.config.port) GT 0
                        AND structKeyExists(arguments.config, "username") AND listFind("CCSSuiteFixture,CCSSuiteFixtureTarget", arguments.config.username) GT 0
                        AND structKeyExists(arguments.config, "authSource") AND listFind("CCSSuiteFixture,CCSSuiteFixtureTarget", arguments.config.authSource) GT 0;
        }

        private string function fixturePassword(){
                return hash("CCSSuiteMongo reserved regression credential", "SHA-256");
        }

        private struct function readState(required struct runtime){
                var all = arguments.runtime.api.getDatasources();
                var entries = structNew("ordered");
                for(var name in getReservedNames()){
                        if(NOT structKeyExists(all, name))
                                continue;
                        if(NOT isStruct(all[name]) OR NOT isOwnedFixture(name, all[name]))
                                throw(type="CCSTest.NoSQLCollision", message="Reserved NoSQL name is occupied by a non-fixture; no values disclosed.");
                        var config = structNew("ordered");
                        for(var field in getFieldMap()){
                                var property = getFieldMap()[field];
                                if(listFindNoCase("name,maxStalenessSeconds", property))
                                        continue;
                                if(structKeyExists(all[name], property)){
                                        if(property EQ "password"){
                                                var stored = "" & all[name][property];
                                                config[property] = NOT len(stored) ? "empty" :
                                                        (compare(stored, arguments.runtime.service.encryptPassword(fixturePassword())) EQ 0 ? "fixture-target" : "unverified");
                                        }
                                        else
                                                config[property] = all[name][property];
                                }
                        }
                        entries[name] = config;
                }
                return {entries=entries};
        }

        public string function getSetting(required string settingName){
                requireSetting(arguments.settingName);
                var runtime = getRuntime();
                try { return serializeJSON(readState(runtime)); }
                catch(any failure){ throw(type="CCSTest.NoSQLApi", message="NoSQL fixture read failed; details withheld."); }
                finally { runtime.adminUtil.logout(runtime.admin); }
        }

        public string function setSetting(required string settingName, required any value){
                requireSetting(arguments.settingName);
                var state = decodeState(arguments.value);
                var allowed = getFieldMap();
                for(var name in state.entries){
                        if(NOT isStruct(state.entries[name]) OR NOT isOwnedFixture(name, state.entries[name]))
                                throw(type="CCSTest.NoSQLPayload", message="Only reserved loopback MongoDB fixtures may be written.");
                        for(var property in state.entries[name]){
                                if(NOT arrayFindNoCase(structValueArray(allowed), property) OR listFindNoCase("name,maxStalenessSeconds", property))
                                        throw(type="CCSTest.NoSQLPayload", message="Unsupported fixture property; no configuration changed.");
                        }
                        if(NOT structKeyExists(state.entries[name], "password") OR
                                NOT listFind("empty,fixture-target", state.entries[name].password))
                                throw(type="CCSTest.NoSQLPayload", message="Only symbolic fixture password states are accepted.");
                }
                var runtime = getRuntime();
                try {
                        var all = runtime.api.getDatasources();
                        for(var name in getReservedNames()){
                                if(structKeyExists(all, name) AND (NOT isStruct(all[name]) OR NOT isOwnedFixture(name, all[name])))
                                        throw(type="CCSTest.NoSQLCollision", message="Reserved fixture collision; refusing to overwrite or remove.");
                        }
                        for(var name in state.entries){
                                var config = duplicate(state.entries[name]);
                                config.name = name;
                                config.password = config.password EQ "empty" ? "" : fixturePassword();
                                runtime.api.setMongoDataSource(argumentCollection=config);
                        }
                        for(var name in getReservedNames()){
                                if(structKeyExists(all, name) AND NOT structKeyExists(state.entries, name))
                                        runtime.api.deleteMongoDatasource(name);
                        }
                        return serializeJSON(readState(runtime));
                }
                catch(any failure){ throw(type="CCSTest.NoSQLApi", message="NoSQL fixture write or readback failed; details withheld."); }
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
                catch(any failure){ throw(type="CCSTest.NoSQLApi", message="NoSQL list read failed; details withheld."); }
                finally { runtime.adminUtil.logout(runtime.admin); }
        }
}