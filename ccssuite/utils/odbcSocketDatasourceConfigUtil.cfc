component output="false" {
        public function init(){
                return this;
        }

        public array function getFields(){
                return [
                        {name="odbcSocketDsn", field="dsn", label="CF Data Source Name", type="text"},
                        {name="odbcSocketDatasource", field="datasource", label="ODBC DSN", type="select-one"},
                        {name="odbcSocketTrustedConnection", field="UseTrustedConnection", label="Trusted Connection", type="checkbox"},
                        {name="odbcSocketUsername", field="username", label="User name", type="text"},
                        {name="odbcSocketPassword", field="password", label="Password", type="password"},
                        {name="odbcSocketDescription", field="description", label="Description", type="textarea"}
                ];
        }

        public struct function getField(required string settingName){
                for(var field in getFields()){
                        if(compareNoCase(field.name, arguments.settingName) EQ 0)
                                return field;
                }
                throw(message="Unsupported ODBC Socket datasource setting", type="CCSTest.ConfigError");
        }

        public array function getColumns(){
                return ["dsn", "driver", "datasource", "UseTrustedConnection", "username", "password", "description", "host", "port"];
        }

        private struct function getApi(){
                if(NOT structKeyExists(application, "constants"))
                        application.constants = new cfsuite.ccssuite.constants().init();
                var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
                var admin = adminUtil.createAdministrator();
                adminUtil.login(application.constants.CF_CONFIG);
                return {admin=admin, adminUtil=adminUtil, api=createObject("component", "CFIDE.adminapi.datasource")};
        }

        private array function getAvailableOdbcDsnNames(){
                var context = getApi();
                try {
                        var sources = context.api.getODBCDatasources();
                        if(NOT isQuery(sources) OR NOT listFindNoCase(sources.columnList, "ENTRY"))
                                throw(message="ColdFusion ODBC datasource list is unavailable", type="CCSTest.ConfigError");
                        var names = [];
                        for(var row=1; row LTE sources.recordCount; row++){
                                var name = trim("" & sources.ENTRY[row]);
                                if(len(name) AND arrayFindNoCase(names, name) EQ 0)
                                        arrayAppend(names, name);
                        }
                        arraySort(names, "textnocase");
                        return names;
                }
                finally {
                        context.adminUtil.logout(context.admin);
                }
        }

        public void function requireFixtureResources(required string settingName){
                getField(arguments.settingName);
                var names = getAvailableOdbcDsnNames();
                var requiredCount = compareNoCase(getField(arguments.settingName).field, "datasource") EQ 0 ? 2 : 1;
                if(arrayLen(names) LT requiredCount)
                        throw(message="ODBC Socket test prerequisite missing: "
                                & (requiredCount EQ 2
                                        ? "the ODBC DSN selection test needs at least two existing ColdFusion ODBC DSNs on every node."
                                        : "at least one existing ColdFusion ODBC DSN is required on every node.")
                                & " No datasource or ODBC DSN was changed.", type="CCSTest.FixtureUnavailable");
        }

        private struct function getFixture(required string settingName, boolean seed = false){
                var field = getField(arguments.settingName).field;
                var names = getAvailableOdbcDsnNames();
                var needsAlternate = compareNoCase(field, "datasource") EQ 0;
                if(NOT arrayLen(names))
                        throw(message="ODBC Socket test prerequisite missing: insufficient existing ODBC DSNs; no datasource was changed.",
                                type="CCSTest.FixtureUnavailable");

                var fixture = {dsn="CCSSUITE_ODBCSOCKET_" & uCase(field), driver="ODBCSocket",
                        datasource=names[1], UseTrustedConnection="false", username="ccssuite_fixture_user",
                        password="fixture-password-original", description="CCSSUITE reserved ODBC Socket fixture",
                        host="localhost", port="20014"};
                if(NOT arguments.seed){
                        switch(field){
                                case "dsn": fixture.dsn &= "_RENAMED"; break;
                                case "datasource":
                                        if(arrayLen(names) GTE 2)
                                                fixture.datasource = names[2];
                                        break;
                                case "UseTrustedConnection": fixture.UseTrustedConnection = "true"; break;
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

        private string function normalizeTrustedConnection(required any value){
                var normalized = lCase(trim("" & arguments.value));
                if(listFindNoCase("true,yes,1", normalized))
                        return "true";
                if(listFindNoCase("false,no,0", normalized))
                        return "false";
                throw(message="ODBC Socket trusted-connection metadata is invalid", type="CCSTest.ConfigError");
        }

        private boolean function recordMatches(required struct expected, required struct actual, boolean includePassword = true){
                for(var column in getColumns()){
                        if(column EQ "password" AND NOT arguments.includePassword)
                                continue;
                        if(NOT structKeyExists(arguments.expected, column) OR NOT structKeyExists(arguments.actual, column)
                                OR NOT isSimpleValue(arguments.expected[column]) OR NOT isSimpleValue(arguments.actual[column]))
                                return false;
                        var expectedValue = "" & arguments.expected[column];
                        var actualValue = "" & arguments.actual[column];
                        if(column EQ "UseTrustedConnection"){
                                try {
                                        if(normalizeTrustedConnection(expectedValue) NEQ normalizeTrustedConnection(actualValue))
                                                return false;
                                }
                                catch(CCSTest.ConfigError invalidTrustedValue){
                                        return false;
                                }
                                continue;
                        }
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
                return isStruct(expectedRows[1]) AND isStruct(actualRows[1]) AND recordMatches(expectedRows[1], actualRows[1]);
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
                        if(field EQ "UseTrustedConnection"){
                                try {
                                        fieldValue = normalizeTrustedConnection(row[field]) EQ "true" ? "Enabled" : "Disabled";
                                }
                                catch(CCSTest.ConfigError invalidTrustedValue){
                                        return "(unavailable)";
                                }
                        }
                        arrayAppend(values, field EQ "password" ? (len(fieldValue) ? "[redacted]" : "(empty)") : fieldValue);
                }
                return (arrayLen(rows) GT 1 ? "Multiple registrations: " : "") & arrayToList(values, ", ");
        }

        private array function getFixtureNames(required string settingName){
                var field = getField(arguments.settingName).field;
                var seedName = "CCSSUITE_ODBCSOCKET_" & uCase(field);
                return field EQ "dsn" ? [seedName, seedName & "_RENAMED"] : [seedName];
        }

        private any function getDatasourceValue(required struct datasource, required string column){
                if(structKeyExists(arguments.datasource, arguments.column) AND isSimpleValue(arguments.datasource[arguments.column]))
                        return arguments.datasource[arguments.column];
                if(structKeyExists(arguments.datasource, "urlmap") AND isStruct(arguments.datasource.urlmap)
                        AND structKeyExists(arguments.datasource.urlmap, arguments.column)
                        AND isSimpleValue(arguments.datasource.urlmap[arguments.column]))
                        return arguments.datasource.urlmap[arguments.column];
                throw(message="Reserved ODBC Socket metadata is unavailable: " & arguments.column, type="CCSTest.ConfigError");
        }

        public struct function normalizeDatasource(required string datasourceName, required struct datasource){
                var snapshot = {dsn=arguments.datasourceName};
                for(var column in ["driver", "datasource", "username", "password", "description", "host", "port", "UseTrustedConnection"])
                        snapshot[column] = getDatasourceValue(arguments.datasource, column);
                snapshot.UseTrustedConnection = normalizeTrustedConnection(snapshot.UseTrustedConnection);
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
                                                throw(message="Reserved ODBC Socket metadata is invalid", type="CCSTest.ConfigError");
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
                        throw(message="ODBC Socket fixture state must be JSON", type="CCSTest.ConfigError");
                var rows = deserializeJSON(arguments.settingValue);
                if(NOT isArray(rows) OR arrayLen(rows) GT 1)
                        throw(message="Unsupported ODBC Socket fixture state", type="CCSTest.ConfigError");
                var fixture = {};
                if(arrayLen(rows)){
                        if(NOT isStruct(rows[1]) OR structCount(rows[1]) NEQ arrayLen(getColumns()))
                                throw(message="Only complete reserved ODBC Socket fixtures are allowed", type="CCSTest.ConfigError");
                        if(recordMatches(seed, rows[1]) AND rows[1].password EQ seed.password)
                                fixture = seed;
                        else if(recordMatches(target, rows[1]) AND rows[1].password EQ target.password)
                                fixture = target;
                        else
                                throw(message="Only fixed reserved ODBC Socket field values are allowed", type="CCSTest.ConfigError");
                }
                var context = getApi();
                try {
                        var datasources = context.api.getDatasources();
                        var presentNames = [];
                        for(var datasourceName in getFixtureNames(arguments.settingName)){
                                if(structKeyExists(datasources, datasourceName)){
                                        if(NOT isStruct(datasources[datasourceName]))
                                                throw(message="Reserved ODBC Socket name belongs to another configuration", type="CCSTest.FixtureCollision");
                                        var snapshot = normalizeDatasource(datasourceName, datasources[datasourceName]);
                                        if(NOT recordMatches(seed, snapshot, false) AND NOT recordMatches(target, snapshot, false))
                                                throw(message="Reserved ODBC Socket name belongs to another configuration; refusing to modify it", type="CCSTest.FixtureCollision");
                                        arrayAppend(presentNames, datasourceName);
                                }
                        }
                        if(NOT arrayLen(rows)){
                                for(var datasourceName in presentNames)
                                        context.api.deleteDatasource(dsnname=datasourceName);
                        }
                        else {
                                if(arrayLen(presentNames) GT 1)
                                        throw(message="Both reserved ODBC Socket datasource names exist; refusing to overwrite them", type="CCSTest.FixtureCollision");
                                var options = {name=fixture.dsn, datasource=fixture.datasource,
                                        useTrustedConnection=fixture.UseTrustedConnection, username=fixture.username,
                                        password=hash(fixture.dsn & ":" & fixture.password, "SHA-256"),
                                        encryptpassword=true, host=fixture.host, port=fixture.port,
                                        description=fixture.description, pooling=false, login_timeout=1, validateConnection=false};
                                if(arrayLen(presentNames)){
                                        if(compareNoCase(presentNames[1], fixture.dsn) NEQ 0)
                                                options.originaldsn = presentNames[1];
                                        else
                                                context.api.deleteDatasource(dsnname=presentNames[1]);
                                }
                                context.api.setODBCSocket(argumentCollection=options);
                        }
                }
                finally {
                        context.adminUtil.logout(context.admin);
                }
                return getSetting(arguments.settingName);
        }
}
