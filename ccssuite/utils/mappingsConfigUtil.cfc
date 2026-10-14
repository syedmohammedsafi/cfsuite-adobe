component output="false" {
	public function init(){
		return this;
	}

	public array function getFixtureNames(required string settingName){
		switch(lCase(arguments.settingName)){
			case "logicalpath": return ["/ccssuite_mapping_logical_a", "/ccssuite_mapping_logical_b"];
			case "directorypath": return ["/ccssuite_mapping_directory"];
			case "deletemapping": return ["/ccssuite_mapping_delete"];
			default: throw(message="Unsupported mappings test setting", type="CCSTest.ConfigError");
		}
	}

	private struct function getApi(){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		var admin = adminUtil.createAdministrator();
		adminUtil.login(application.constants.CF_CONFIG);
		return {admin=admin, adminUtil=adminUtil, api=createObject("component", "CFIDE.adminapi.extensions")};
	}

	public struct function getMappings(){
		var runtime = getApi();
		try {
			var mappings = runtime.api.getMappings();
			if(NOT isStruct(mappings))
				throw(message="Mappings API did not return a mappings struct", type="CCSTest.ConfigError");
			return mappings;
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function getSetting(required string settingName){
		var mappings = getMappings();
		var state = structNew("ordered");
		for(var name in getFixtureNames(arguments.settingName)){
			if(structKeyExists(mappings, name))
				state[name] = mappings[name];
		}
		return serializeJSON(state);
	}

	private struct function parseState(required string settingName, required any settingValue){
		var state = deserializeJSON("" & arguments.settingValue);
		if(NOT isStruct(state))
			throw(message="Mapping test state must be a JSON object", type="CCSTest.ConfigError");
		var names = getFixtureNames(arguments.settingName);
		for(var name in state){
			if(NOT arrayFindNoCase(names, name) OR NOT isSimpleValue(state[name]) OR NOT len(trim("" & state[name])))
				throw(message="Only this test's reserved mappings and nonempty directory paths may be changed", type="CCSTest.ConfigError");
		}
		return state;
	}

	private string function normalizePath(required any path){
		var text = replace(trim("" & arguments.path), chr(92), "/", "all");
		if(len(text) GT 1)
			text = reReplace(text, "/+$", "");
		return findNoCase("Windows", server.os.name) ? lCase(text) : text;
	}

	public boolean function configsMatch(required string settingName, required any expectedValue, required any actualValue){
		try {
			var expected = parseState(arguments.settingName, arguments.expectedValue);
			var actual = parseState(arguments.settingName, arguments.actualValue);
			if(structCount(expected) NEQ structCount(actual))
				return false;
			for(var name in expected){
				if(NOT structKeyExists(actual, name) OR compare(normalizePath(expected[name]), normalizePath(actual[name])) NEQ 0)
					return false;
			}
			return true;
		}
		catch(any failure){
			return false;
		}
	}

	public string function setSetting(required string settingName, required any settingValue){
		var state = parseState(arguments.settingName, arguments.settingValue);
		var runtime = getApi();
		try {
			var current = runtime.api.getMappings();
			for(var name in getFixtureNames(arguments.settingName)){
				if(structKeyExists(state, name)){
					if(NOT structKeyExists(current, name) OR compare(normalizePath(current[name]), normalizePath(state[name])) NEQ 0)
						runtime.api.setMapping(mapName=name, mapPath=state[name]);
				}
				else if(structKeyExists(current, name))
					runtime.api.deleteMapping(mapName=name);
			}
			var updated = runtime.api.getMappings();
			var result = structNew("ordered");
			for(var name in getFixtureNames(arguments.settingName)){
				if(structKeyExists(updated, name))
					result[name] = updated[name];
			}
			return serializeJSON(result);
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function getTestState(required string settingName, required any currentValue, boolean prepare = false){
		var current = parseState(arguments.settingName, arguments.currentValue);
		var names = getFixtureNames(arguments.settingName);
		var state = structNew("ordered");
		var directory = expandPath("/cfsuite/ccssuite/testAssets");
		if(arguments.settingName EQ "logicalPath")
			state[structKeyExists(current, names[1]) ? names[2] : names[1]] = directory;
		else if(arguments.prepare)
			state[names[1]] = directory;
		else if(arguments.settingName EQ "directoryPath")
			state[names[1]] = expandPath("/cfsuite/ccssuite/utils");
		return serializeJSON(state);
	}
}