component output="false" {
        public function init(){
                return this;
        }

        public array function getFields(){
                return [
                        {name="msAccessDsn", field="dsn", label="CF Data Source Name", type="text"},
                        {name="msAccessDatabaseFile", field="databasefile", label="Database File", type="text"},
                        {name="msAccessSystemDatabaseFile", field="systemDatabaseFile", label="System Database File", type="text"},
                        {name="msAccessUseDefaultUsername", field="UseTrustedConnection", label="Use Default User name", type="checkbox"},
                        {name="msAccessUsername", field="username", label="ColdFusion User Name", type="text"},
                        {name="msAccessPassword", field="password", label="ColdFusion Password", type="password"},
                        {name="msAccessDescription", field="description", label="Description", type="textarea"}
                ];
        }

        public struct function getField(required string settingName){
                for(var field in getFields()){
                        if(compareNoCase(field.name, arguments.settingName) EQ 0)
                                return field;
                }
                throw(message="Unsupported Microsoft Access setting", type="CCSTest.ConfigError");
        }

        public array function getColumns(){
                return ["dsn", "driver", "databasefile", "systemDatabaseFile", "UseTrustedConnection", "username", "password", "description"];
        }

        private struct function getApi(){
                if(NOT structKeyExists(application, "constants"))
                        application.constants = new cfsuite.ccssuite.constants().init();
                var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
                var admin = adminUtil.createAdministrator();
                adminUtil.login(application.constants.CF_CONFIG);
                return {admin=admin, adminUtil=adminUtil, api=createObject("component", "CFIDE.adminapi.datasource")};
        }

        private struct function getFixture(required string settingName, boolean seed = false){
                var field = getField(arguments.settingName).field;
                var directory = "/cfsuite/ccssuite/testAssets/databases/msAccess/" & field & "/";
                var fixture = {dsn="CCSSUITE_MSACCESS_" & uCase(field), driver="MSAccess",
                        databasefile=expandPath(directory & "original.mdb"), systemDatabaseFile=expandPath(directory & "original.mdw"),
                        UseTrustedConnection=(field EQ "UseTrustedConnection"), username="ccssuite_fixture_user",
                        password="fixture-password-original", description="CCSSUITE reserved Microsoft Access fixture"};
                if(NOT arguments.seed){
                        switch(field){
                                case "dsn": fixture.dsn &= "_RENAMED"; break;
                                case "databasefile": fixture.databasefile = expandPath(directory & "updated.mdb"); break;
                                case "systemDatabaseFile": fixture.systemDatabaseFile = expandPath(directory & "updated.mdw"); break;
                                case "UseTrustedConnection": fixture.UseTrustedConnection = false; break;
                                case "username": fixture.username = "ccssuite_fixture_user_updated"; break;
                                case "password": fixture.password = "fixture-password-updated"; break;
                                case "description": fixture.description &= " updated"; break;
                        }
                }
                return fixture;
        }

        public string function normalizeDatabasePath(required string path){
                var canonicalPath = createObject("java", "java.io.File").init(arguments.path).getCanonicalPath();
                var normalized = replace(canonicalPath, "\", "/", "all");
                var marker = "/testAssets/databases/msAccess/";
                var position = findNoCase(marker, normalized);
                if(position)
                        normalized = mid(normalized, position, len(normalized));
                return lCase(normalized);
        }

        public string function getTestState(required string settingName){
                return serializeJSON([getFixture(arguments.settingName)]);
        }

        public string function getSeedState(required string settingName){
                return serializeJSON([getFixture(arguments.settingName, true)]);
        }

        public struct function getSetterArguments(required string settingName, boolean seed = false){
                var fixture = getFixture(arguments.settingName, arguments.seed);
                var original = getFixture(arguments.settingName, true);
                return {name=fixture.dsn, databasefile=fixture.databasefile, systemDatabaseFile=fixture.systemDatabaseFile,
                        UseTrustedConnection=fixture.UseTrustedConnection, username=fixture.username,
                        password=hash(original.dsn & ":" & fixture.password, "SHA-256"), encryptpassword=true,
                        description=fixture.description, pooling=false, login_timeout=1, validateConnection=false};
        }

        public boolean function isOwnedDatasource(required string settingName, required struct snapshot, boolean cleanup = false){
                var seed = getFixture(arguments.settingName, true);
                if(recordMatches(seed, arguments.snapshot, false) OR recordMatches(getFixture(arguments.settingName), arguments.snapshot, false))
                        return true;
                if(NOT arguments.cleanup)
                        return false;
                seed.username = "System";
                seed.password = "";
                return recordMatches(seed, arguments.snapshot);
        }

        private boolean function recordMatches(required struct expected, required struct actual, boolean includePassword = true){
                for(var column in getColumns()){
                        if(column EQ "password" AND NOT arguments.includePassword)
                                continue;
                        if(NOT structKeyExists(arguments.expected, column) OR NOT structKeyExists(arguments.actual, column)
                                OR NOT isSimpleValue(arguments.expected[column]) OR NOT isSimpleValue(arguments.actual[column]))
                                return false;
                        if(column EQ "UseTrustedConnection"){
                                if(NOT isBoolean(arguments.expected[column]) OR NOT isBoolean(arguments.actual[column])
                                        OR (NOT arguments.expected[column]) NEQ (NOT arguments.actual[column]))
                                        return false;
                                continue;
                        }
                        var expectedValue = "" & arguments.expected[column];
                        var actualValue = "" & arguments.actual[column];
                        if(listFindNoCase("databasefile,systemDatabaseFile", column)){
                                if(normalizeDatabasePath(expectedValue) NEQ normalizeDatabasePath(actualValue))
                                        return false;
                                continue;
                        }
                        if(column EQ "password" AND listFind("fixture-password-original,fixture-password-updated", expectedValue)
                                AND reFindNoCase("^sha256:[a-f0-9]{64}$", actualValue))
                                continue;
                        if(listFind("dsn,driver", column)){
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
                                if(NOT isBoolean(row[field]))
                                        return "(unavailable)";
                                fieldValue = row[field] ? "Enabled" : "Disabled";
                        }
                        arrayAppend(values, field EQ "password" ? (len(fieldValue) ? "[redacted]" : "(empty)") : fieldValue);
                }
                return (arrayLen(rows) GT 1 ? "Multiple registrations: " : "") & arrayToList(values, ", ");
        }

        private array function getFixtureNames(required string settingName){
                var seed = getFixture(arguments.settingName, true);
                var target = getFixture(arguments.settingName);
                return seed.dsn EQ target.dsn ? [seed.dsn] : [seed.dsn, target.dsn];
        }

        public struct function normalizeDatasource(required string datasourceName, required struct datasource){
                var snapshot = {dsn=arguments.datasourceName};
                for(var column in ["driver", "username", "password", "description"]){
                        if(NOT structKeyExists(arguments.datasource, column) OR NOT isSimpleValue(arguments.datasource[column]))
                                throw(message="Reserved Microsoft Access metadata is unavailable: " & column, type="CCSTest.ConfigError");
                        snapshot[column] = arguments.datasource[column];
                }
                snapshot.password = len(snapshot.password) ? "sha256:" & hash(snapshot.password, "SHA-256") : "";
                for(var column in ["databasefile", "systemDatabaseFile", "UseTrustedConnection"]){
                        if(structKeyExists(arguments.datasource, column) AND isSimpleValue(arguments.datasource[column]))
                                snapshot[column] = arguments.datasource[column];
                        else if(structKeyExists(arguments.datasource, "urlmap") AND isStruct(arguments.datasource.urlmap)
                                AND structKeyExists(arguments.datasource.urlmap, column) AND isSimpleValue(arguments.datasource.urlmap[column]))
                                snapshot[column] = arguments.datasource.urlmap[column];
                        else
                                throw(message="Reserved Microsoft Access connection field is unavailable: " & column, type="CCSTest.ConfigError");
                }
                if(NOT len(trim(snapshot.databasefile)) OR NOT isBoolean(snapshot.UseTrustedConnection))
                        throw(message="Reserved Microsoft Access connection metadata is invalid", type="CCSTest.ConfigError");
                snapshot.UseTrustedConnection = snapshot.UseTrustedConnection ? true : false;
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
                                                throw(message="Reserved Microsoft Access metadata is invalid", type="CCSTest.ConfigError");
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
                        throw(message="Microsoft Access fixture state must be JSON", type="CCSTest.ConfigError");
                var rows = deserializeJSON(arguments.settingValue);
                if(NOT isArray(rows) OR arrayLen(rows) GT 1)
                        throw(message="Unsupported Microsoft Access fixture state", type="CCSTest.ConfigError");
                var fixture = {};
                if(arrayLen(rows)){
                        if(NOT isStruct(rows[1]) OR structCount(rows[1]) NEQ arrayLen(getColumns()))
                                throw(message="Only complete reserved Microsoft Access fixtures are allowed", type="CCSTest.ConfigError");
                        if(recordMatches(seed, rows[1]) AND rows[1].password EQ seed.password)
                                fixture = seed;
                        else if(recordMatches(target, rows[1]) AND rows[1].password EQ target.password)
                                fixture = target;
                        else
                                throw(message="Only fixed reserved Microsoft Access field values are allowed", type="CCSTest.ConfigError");
                }
                var context = getApi();
                try {
                        var datasources = context.api.getDatasources();
                        var presentNames = [];
                        for(var datasourceName in getFixtureNames(arguments.settingName)){
                                if(structKeyExists(datasources, datasourceName)){
                                        if(NOT isStruct(datasources[datasourceName]))
                                                throw(message="Reserved Microsoft Access name belongs to another configuration", type="CCSTest.FixtureCollision");
                                        var snapshot = normalizeDatasource(datasourceName, datasources[datasourceName]);
                                        if(NOT isOwnedDatasource(arguments.settingName, snapshot, NOT arrayLen(rows)))
                                                throw(message="Reserved Microsoft Access name belongs to another configuration; refusing to modify it", type="CCSTest.FixtureCollision");
                                        arrayAppend(presentNames, datasourceName);
                                }
                        }
                        if(NOT arrayLen(rows)){
                                for(var datasourceName in presentNames)
                                        context.api.deleteDatasource(dsnname=datasourceName);
                        }
                        else {
                                if(arrayLen(presentNames) GT 1)
                                        throw(message="Both reserved Microsoft Access names exist; refusing to overwrite them", type="CCSTest.FixtureCollision");
                                var options = getSetterArguments(arguments.settingName, recordMatches(seed, fixture));
                                if(arrayLen(presentNames)){
                                        if(compareNoCase(presentNames[1], fixture.dsn) NEQ 0)
                                                options.originaldsn = presentNames[1];
                                        else
                                                context.api.deleteDatasource(dsnname=presentNames[1]);
                                }
                                context.api.setMSAccess(argumentCollection=options);
                        }
                }
                finally {
                        context.adminUtil.logout(context.admin);
                }
                return getSetting(arguments.settingName);
        }
}