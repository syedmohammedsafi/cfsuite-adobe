/**
* Read/write NoSQL (MongoDB) Data Source configurations through CFIDE.adminapi.nosql_datasource,
* which is a thin wrapper around the live coldfusion.server.NoSQLService. Config fields are
* already plain camelCase on both read and write (no WDDX-style uppercase conversion needed).
*
* Only getDataSources() (no name argument) is used for reads — the single-name variant,
* getDataSources(name), and verifyMongoDatasource() both attempt a live connection to the
* Mongo host and throw when nothing is listening there, which is expected in this test
* environment (there's no real MongoDB server backing these test entries).
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
			api = createObject("component", "CFIDE.adminapi.nosql_datasource")
		};
	}

	private string function findStructKey(required struct data, required string key){
		for(var existingKey in arguments.data){
			if(compareNoCase(existingKey, arguments.key) EQ 0)
				return existingKey;
		}
		return arguments.key;
	}

	public struct function sortStructKeys(required struct data){
		return new cfsuite.ccssuite.utils.llmConfigUtil().init().sortStructKeys(arguments.data);
	}

	public struct function decodeConfigValue(required any settingValue){
		var raw = trim("" & arguments.settingValue);
		if(NOT len(raw))
			return {};

		try {
			if(reFind("^[A-Za-z0-9+/=\r\n]+$", raw) AND len(raw) MOD 4 EQ 0)
				raw = toString(toBinary(raw));
			var parsed = deserializeJSON(raw);
			return isStruct(parsed) ? parsed : {};
		}
		catch(any e){
			throw(message="Invalid NoSQL datasource config payload", detail=e.message, type="CCSTest.ConfigError");
		}
	}

	public string function encodeConfigValue(required struct config){
		return toBase64(serializeJSON(sortStructKeys(arguments.config)));
	}

	public string function getNoSQLSetting(required string alias){
		var runtime = getRuntime();
		try {
			var all = runtime.api.getDataSources();
			var aliasKey = findStructKey(all, arguments.alias);
			if(NOT structKeyExists(all, aliasKey))
				return "";
			var config = duplicate(all[aliasKey]);
			structDelete(config, "name");
			return encodeConfigValue(config);
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setNoSQLSetting(required string alias, required any settingValue){
		var raw = trim("" & arguments.settingValue);
		if(NOT len(raw)){
			deleteNoSQLSetting(arguments.alias);
			return "";
		}

		var config = decodeConfigValue(arguments.settingValue);
		if(structIsEmpty(config)){
			deleteNoSQLSetting(arguments.alias);
			return "";
		}

		var runtime = getRuntime();
		try {
			var args = duplicate(config);
			args["name"] = arguments.alias;
			if(NOT structKeyExists(args, "type") OR NOT len(trim("" & args.type)))
				args["type"] = "mongodb";
			runtime.api.setMongoDataSource(argumentCollection=args);
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
		return getNoSQLSetting(arguments.alias);
	}

	public void function deleteNoSQLSetting(required string alias){
		var runtime = getRuntime();
		try {
			runtime.api.deleteMongoDataSource(arguments.alias);
		}
		catch(any e){
			// already absent - nothing to delete
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	private boolean function valuesEquivalent(required any left, required any right){
		if(isNumeric(arguments.left) AND isNumeric(arguments.right))
			return val(arguments.left) EQ val(arguments.right);
		if(
			(isBoolean(arguments.left) AND NOT isNumeric(arguments.left))
			OR (isBoolean(arguments.right) AND NOT isNumeric(arguments.right))
		)
			return (arguments.left ? true : false) EQ (arguments.right ? true : false);
		return trim("" & arguments.left) EQ trim("" & arguments.right);
	}

	private boolean function structValuesMatch(required struct expected, required struct actual){
		for(var key in arguments.expected){
			if(NOT structKeyExists(arguments.actual, key))
				continue;
			if(isStruct(arguments.expected[key])){
				if(NOT isStruct(arguments.actual[key]) OR NOT structValuesMatch(arguments.expected[key], arguments.actual[key]))
					return false;
			}
			else if(key EQ "password"){
				if(len(trim("" & arguments.expected[key])) AND len(trim("" & arguments.actual[key])))
					continue;
				if(NOT valuesEquivalent(arguments.expected[key], arguments.actual[key]))
					return false;
			}
			else if(NOT valuesEquivalent(arguments.expected[key], arguments.actual[key])){
				return false;
			}
		}
		return true;
	}

	public boolean function configsMatch(required any expectedValue, required any actualValue){
		var expected = decodeConfigValue(arguments.expectedValue);
		var actual = decodeConfigValue(arguments.actualValue);
		if(structIsEmpty(expected) AND structIsEmpty(actual))
			return true;
		return structValuesMatch(expected, actual);
	}

	public boolean function setMatches(
		required any presetValue,
		required any actualValue,
		required any requestedValue
	){
		return configsMatch(arguments.requestedValue, arguments.actualValue);
	}
}
