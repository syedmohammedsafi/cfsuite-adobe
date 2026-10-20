component output="false" {
	public function init(){
		return this;
	}

	public array function getFields(){
		return [
			{name="oracleDsn", field="dsn", label="CF Data Source Name", type="text"},
			{name="oracleSid", field="sid", label="SID Name", type="text"},
			{name="oracleServiceName", field="servicename", label="Service Name", type="text"},
			{name="oracleHost", field="host", label="Server", type="text"},
			{name="oraclePort", field="port", label="Port", type="text"},
			{name="oracleUsername", field="username", label="User name", type="text"},
			{name="oraclePassword", field="password", label="Password", type="password"},
			{name="oracleDescription", field="description", label="Description", type="textarea"}
		];
	}

	public struct function getField(required string settingName){
		for(var field in getFields()){
			if(compareNoCase(field.name, arguments.settingName) EQ 0)
				return field;
		}
		throw(message="Unsupported Oracle datasource setting", type="CCSTest.ConfigError");
	}

	public array function getColumns(){
		return ["dsn", "driver", "sid", "servicename", "host", "port", "username", "password", "description"];
	}

	private struct function getApi(){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		var admin = adminUtil.createAdministrator();
		adminUtil.login(application.constants.CF_CONFIG);
		return {admin=admin, adminUtil=adminUtil, api=createObject("component", "CFIDE.adminapi.datasource")};
	}

	private struct function getFixture(required string settingName, boolean seed=false){
		var field = getField(arguments.settingName).field;
		var fixture = {
			dsn="CCSSUITE_ORACLE_" & uCase(field),
			driver="Oracle",
			sid="CCSSUITE_FIXTURE_SID",
			servicename="",
			host="127.0.0.1",
			port="1",
			username="ccssuite_fixture_user",
			password="fixture-password-original",
			description="CCSSUITE reserved Oracle fixture"
		};
		if(NOT arguments.seed){
			switch(field){
				case "dsn": fixture.dsn &= "_RENAMED"; break;
				case "sid": fixture.sid = "CCSSUITE_FIXTURE_SID_UPDATED"; break;
				case "servicename":
					fixture.sid = "";
					fixture.servicename = "CCSSUITE_FIXTURE_SERVICE";
					break;
				case "host": fixture.host = "127.0.0.2"; break;
				case "port": fixture.port = "2"; break;
				case "username": fixture.username = "ccssuite_fixture_user_updated"; break;
				case "password": fixture.password = "fixture-password-updated"; break;
				case "description": fixture.description &= " updated"; break;
			}
		}
		return fixture;
	}

	public string function getTestState(required string settingName){
		return serializeJSON([getFixture(arguments.settingName)]);
	}

	public string function getSeedState(required string settingName){
		return serializeJSON([getFixture(arguments.settingName, true)]);
	}

	private boolean function recordMatches(required struct expected, required struct actual, boolean includePassword=true){
		for(var column in getColumns()){
			if(column EQ "password" AND NOT arguments.includePassword)
				continue;
			if(NOT structKeyExists(arguments.expected, column) OR NOT structKeyExists(arguments.actual, column)
				OR NOT isSimpleValue(arguments.expected[column]) OR NOT isSimpleValue(arguments.actual[column]))
				return false;
			var expectedValue = "" & arguments.expected[column];
			var actualValue = "" & arguments.actual[column];
			if(column EQ "password" AND listFind("fixture-password-original,fixture-password-updated", expectedValue)
				AND reFindNoCase("^sha256:[a-f0-9]{64}$", actualValue))
				continue;
			if(listFindNoCase("dsn,driver,host", column)){
				if(compareNoCase(expectedValue, actualValue) NEQ 0)
					return false;
			}
			else if(compare(expectedValue, actualValue) NEQ 0)
				return false;
		}
		return true;
	}

	public boolean function configsMatch(required string settingName, required any expected, required any actual){
		getField(arguments.settingName);
		if(NOT isJSON(arguments.expected) OR NOT isJSON(arguments.actual))
			return false;
		var expectedRows = deserializeJSON(arguments.expected);
		var actualRows = deserializeJSON(arguments.actual);
		if(NOT isArray(expectedRows) OR NOT isArray(actualRows) OR arrayLen(expectedRows) GT 1
			OR arrayLen(expectedRows) NEQ arrayLen(actualRows))
			return false;
		if(NOT arrayLen(expectedRows))
			return true;
		return isStruct(expectedRows[1]) AND isStruct(actualRows[1])
			AND recordMatches(expectedRows[1], actualRows[1]);
	}

	public boolean function setMatches(required string settingName, required any preset, required any actual, required any requested){
		if(NOT configsMatch(arguments.settingName, arguments.requested, arguments.actual))
			return false;
		var requestedRows = deserializeJSON(arguments.requested);
		if(getField(arguments.settingName).field NEQ "password" OR NOT arrayLen(requestedRows)
			OR requestedRows[1].password NEQ "fixture-password-updated")
			return true;
		if(NOT isJSON(arguments.preset))
			return false;
		var presetRows = deserializeJSON(arguments.preset);
		var actualRows = deserializeJSON(arguments.actual);
		return isArray(presetRows) AND arrayLen(presetRows) EQ 1 AND isStruct(presetRows[1])
			AND structKeyExists(presetRows[1], "password") AND isSimpleValue(presetRows[1].password)
			AND reFindNoCase("^sha256:[a-f0-9]{64}$", presetRows[1].password) GT 0
			AND reFindNoCase("^sha256:[a-f0-9]{64}$", actualRows[1].password) GT 0
			AND compare(presetRows[1].password, actualRows[1].password) NEQ 0;
	}

	public string function formatDisplayValue(required string settingName, required any value){
		var field = getField(arguments.settingName).field;
		var text = trim("" & arguments.value);
		if(findNoCase("set FAILED", text))
			return "Setting update failed";
		if(NOT isJSON(text))
			return "(unavailable)";
		var rows = deserializeJSON(text);
		if(NOT isArray(rows))
			return "(unavailable)";
		if(NOT arrayLen(rows))
			return "Not registered";
		var values = [];
		for(var row in rows){
			if(NOT isStruct(row) OR NOT structKeyExists(row, field) OR NOT isSimpleValue(row[field]))
				return "(unavailable)";
			var fieldValue = "" & row[field];
			arrayAppend(values, field EQ "password" ? (len(fieldValue) ? "[redacted]" : "(empty)") : fieldValue);
		}
		return (arrayLen(rows) GT 1 ? "Multiple registrations: " : "") & arrayToList(values, ", ");
	}

	private array function getFixtureNames(required string settingName){
		var seed = getFixture(arguments.settingName, true);
		var target = getFixture(arguments.settingName);
		return seed.dsn EQ target.dsn ? [seed.dsn] : [seed.dsn, target.dsn];
	}

	private any function getConnectionValue(required struct datasource, required string column){
		if(structKeyExists(arguments.datasource, column) AND isSimpleValue(arguments.datasource[column]))
			return arguments.datasource[column];
		if(structKeyExists(arguments.datasource, "urlmap") AND isStruct(arguments.datasource.urlmap)
			AND structKeyExists(arguments.datasource.urlmap, column) AND isSimpleValue(arguments.datasource.urlmap[column]))
			return arguments.datasource.urlmap[column];
		throw(message="Reserved Oracle connection field is unavailable: " & arguments.column, type="CCSTest.ConfigError");
	}

	public struct function normalizeDatasource(required string datasourceName, required struct datasource){
		var snapshot = {dsn=arguments.datasourceName};
		for(var column in ["driver", "username", "password", "description"]){
			if(NOT structKeyExists(arguments.datasource, column) OR NOT isSimpleValue(arguments.datasource[column]))
				throw(message="Reserved Oracle metadata is unavailable: " & column, type="CCSTest.ConfigError");
			snapshot[column] = arguments.datasource[column];
		}
		for(var column in ["sid", "servicename", "host", "port"])
			snapshot[column] = getConnectionValue(arguments.datasource, column);
		snapshot.password = len(snapshot.password) ? "sha256:" & hash(snapshot.password, "SHA-256") : "";
		snapshot.port = "" & snapshot.port;
		return snapshot;
	}

	public string function getSetting(required string settingName){
		var names = getFixtureNames(arguments.settingName);
		var context = getApi();
		try {
			var datasources = context.api.getDatasources();
			var rows = [];
			for(var datasourceName in names){
				if(structKeyExists(datasources, datasourceName)){
					if(NOT isStruct(datasources[datasourceName]))
						throw(message="Reserved Oracle metadata is invalid", type="CCSTest.ConfigError");
					arrayAppend(rows, normalizeDatasource(datasourceName, datasources[datasourceName]));
				}
			}
			return serializeJSON(rows);
		}
		finally {
			context.adminUtil.logout(context.admin);
		}
	}

	public string function setSetting(required string settingName, required any settingValue){
		var seed = getFixture(arguments.settingName, true);
		var target = getFixture(arguments.settingName);
		if(NOT isJSON(arguments.settingValue))
			throw(message="Oracle fixture state must be JSON", type="CCSTest.ConfigError");
		var rows = deserializeJSON(arguments.settingValue);
		if(NOT isArray(rows) OR arrayLen(rows) GT 1)
			throw(message="Unsupported Oracle fixture state", type="CCSTest.ConfigError");
		var fixture = {};
		if(arrayLen(rows)){
			if(NOT isStruct(rows[1]) OR structCount(rows[1]) NEQ arrayLen(getColumns()))
				throw(message="Only complete reserved Oracle fixtures are allowed", type="CCSTest.ConfigError");
			if(recordMatches(seed, rows[1]) AND rows[1].password EQ seed.password)
				fixture = seed;
			else if(recordMatches(target, rows[1]) AND rows[1].password EQ target.password)
				fixture = target;
			else
				throw(message="Only fixed reserved Oracle field values are allowed", type="CCSTest.ConfigError");
		}
		var context = getApi();
		try {
			var datasources = context.api.getDatasources();
			var presentNames = [];
			for(var datasourceName in getFixtureNames(arguments.settingName)){
				if(structKeyExists(datasources, datasourceName)){
					if(NOT isStruct(datasources[datasourceName]))
						throw(message="Reserved Oracle name belongs to another configuration", type="CCSTest.FixtureCollision");
					var snapshot = normalizeDatasource(datasourceName, datasources[datasourceName]);
					if(NOT recordMatches(seed, snapshot, false) AND NOT recordMatches(target, snapshot, false))
						throw(message="Reserved Oracle name belongs to another configuration; refusing to modify it", type="CCSTest.FixtureCollision");
					arrayAppend(presentNames, datasourceName);
				}
			}
			if(NOT arrayLen(rows)){
				for(var datasourceName in presentNames)
					context.api.deleteDatasource(dsnname=datasourceName);
			}
			else {
				if(arrayLen(presentNames) GT 1)
					throw(message="Both reserved Oracle names exist; refusing to overwrite them", type="CCSTest.FixtureCollision");
				var options = {vendor="oracle", type="ddtek", name=fixture.dsn, host=fixture.host,
					sid=fixture.sid, servicename=fixture.servicename, port=fixture.port,
					username=fixture.username, password=hash(fixture.dsn & ":" & fixture.password, "SHA-256"),
					encryptpassword=true, description=fixture.description, pooling=false,
					login_timeout=1, validateConnection=false};
				if(arrayLen(presentNames)){
					if(compareNoCase(presentNames[1], fixture.dsn) NEQ 0)
						options.originaldsn = presentNames[1];
					else
						context.api.deleteDatasource(dsnname=presentNames[1]);
				}
				context.api.setOracle(argumentCollection=options);
			}
		}
		finally {
			context.adminUtil.logout(context.admin);
		}
		return getSetting(arguments.settingName);
	}
}
