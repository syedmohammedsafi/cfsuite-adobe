component output="false" {
        public function init(){
                return this;
        }

        public array function getFields(){
                return [
                        {name="derbyEmbeddedDsn", field="dsn", label="CF Data Source Name", type="text", file="dsn.cfm"},
                        {name="derbyEmbeddedDatabase", field="database", label="Database Folder", type="text", file="database.cfm"},
                        {name="derbyEmbeddedCreateDatabase", field="isnewdb", label="Create Database", type="checkbox", file="createDatabase.cfm"},
                        {name="derbyEmbeddedDescription", field="description", label="Description", type="textarea", file="description.cfm"}
                ];
        }

        public struct function getField(required string settingName){
                for(var field in getFields()){
                        if(compareNoCase(field.name, arguments.settingName) EQ 0)
                                return field;
                }
                throw(message="Unsupported Apache Derby Embedded setting", type="CCSTest.ConfigError");
        }

        public array function getColumns(){
                return ["dsn", "driver", "database", "isnewdb", "description"];
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
                var fixture = {dsn="CCSSUITE_DERBYEMBEDDED_" & uCase(field), driver="Apache Derby Embedded",
                        database=expandPath("/cfsuite/ccssuite/testAssets/databases/derbyEmbedded/" & field & "/original"),
                        isnewdb=false, description="CCSSUITE reserved Derby Embedded fixture"};
                if(NOT arguments.seed){
                        switch(field){
                                case "dsn": fixture.dsn &= "_RENAMED"; break;
                                case "database": fixture.database = expandPath("/cfsuite/ccssuite/testAssets/databases/derbyEmbedded/database/updated"); break;
                                case "isnewdb": fixture.isnewdb = true; break;
                                case "description": fixture.description &= " updated"; break;
                        }
                }
                return fixture;
        }

        public string function normalizeDatabasePath(required string path){
                var canonicalPath = createObject("java", "java.io.File").init(arguments.path).getCanonicalPath();
                var normalized = replace(canonicalPath, "\", "/", "all");
                var marker = "/testAssets/databases/derbyEmbedded/";
                var markerPosition = findNoCase(marker, normalized);
                if(markerPosition)
                        normalized = mid(normalized, markerPosition, len(normalized));
                return lCase(normalized);
        }

        public string function getTestState(required string settingName){
                return serializeJSON([getFixture(arguments.settingName)]);
        }

        public string function getSeedState(required string settingName){
                return serializeJSON([getFixture(arguments.settingName, true)]);
        }

        private boolean function recordMatches(required struct expected, required struct actual){
                for(var column in getColumns()){
                        if(NOT structKeyExists(arguments.expected, column) OR NOT structKeyExists(arguments.actual, column)
                                OR NOT isSimpleValue(arguments.expected[column]) OR NOT isSimpleValue(arguments.actual[column]))
                                return false;
                        if(column EQ "database"){
                                if(normalizeDatabasePath(arguments.expected[column]) NEQ normalizeDatabasePath(arguments.actual[column]))
                                        return false;
                        }
                        else if(column EQ "isnewdb"){
                                if(NOT isBoolean(arguments.expected[column]) OR NOT isBoolean(arguments.actual[column])
                                        OR (arguments.expected[column] ? true : false) NEQ (arguments.actual[column] ? true : false))
                                        return false;
                        }
                        else if(column EQ "description"){
                                if(compare(arguments.expected[column], arguments.actual[column]) NEQ 0)
                                        return false;
                        }
                        else if(compareNoCase(arguments.expected[column], arguments.actual[column]) NEQ 0)
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
                        if(field EQ "isnewdb"){
                                if(NOT isBoolean(row[field]))
                                        return "(unavailable)";
                                arrayAppend(values, row[field] ? "Enabled" : "Disabled");
                        }
                        else
                                arrayAppend(values, "" & row[field]);
                }
                return (arrayLen(rows) GT 1 ? "Multiple registrations: " : "") & arrayToList(values, ", ");
        }

        private array function getFixtureNames(required string settingName){
                var seed = getFixture(arguments.settingName, true);
                var target = getFixture(arguments.settingName);
                return seed.dsn EQ target.dsn ? [seed.dsn] : [seed.dsn, target.dsn];
        }

        private struct function getSnapshot(required string datasourceName, required struct datasource){
                if(NOT structKeyExists(arguments.datasource, "driver") OR NOT isSimpleValue(arguments.datasource.driver)
                        OR NOT structKeyExists(arguments.datasource, "description") OR NOT isSimpleValue(arguments.datasource.description)
                        OR NOT structKeyExists(arguments.datasource, "urlmap") OR NOT isStruct(arguments.datasource.urlmap)
                        OR NOT structKeyExists(arguments.datasource.urlmap, "database") OR NOT isSimpleValue(arguments.datasource.urlmap.database)
                        OR NOT structKeyExists(arguments.datasource.urlmap, "isnewdb") OR NOT isBoolean(arguments.datasource.urlmap.isnewdb))
                        throw(message="Reserved Derby Embedded metadata is unavailable", type="CCSTest.ConfigError");
                return {dsn=arguments.datasourceName, driver=arguments.datasource.driver, database=arguments.datasource.urlmap.database,
                        isnewdb=arguments.datasource.urlmap.isnewdb ? true : false, description=arguments.datasource.description};
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
                                                throw(message="Reserved Embedded metadata is invalid", type="CCSTest.ConfigError");
                                        arrayAppend(rows, getSnapshot(datasourceName, datasources[datasourceName]));
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
                        throw(message="Embedded fixture state must be JSON", type="CCSTest.ConfigError");
                var rows = deserializeJSON(arguments.settingValue);
                if(NOT isArray(rows) OR arrayLen(rows) GT 1)
                        throw(message="Unsupported Embedded fixture state", type="CCSTest.ConfigError");
                var fixture = {};
                if(arrayLen(rows)){
                        if(NOT isStruct(rows[1]) OR structCount(rows[1]) NEQ arrayLen(getColumns()))
                                throw(message="Only complete reserved Embedded fixtures are allowed", type="CCSTest.ConfigError");
                        if(recordMatches(seed, rows[1]))
                                fixture = seed;
                        else if(recordMatches(target, rows[1]))
                                fixture = target;
                        else
                                throw(message="Only fixed reserved Embedded field values are allowed", type="CCSTest.ConfigError");
                }
                var context = getApi();
                try {
                        var datasources = context.api.getDatasources();
                        var presentNames = [];
                        for(var datasourceName in getFixtureNames(arguments.settingName)){
                                if(structKeyExists(datasources, datasourceName)){
                                        if(NOT isStruct(datasources[datasourceName]))
                                                throw(message="Reserved Embedded name belongs to another configuration", type="CCSTest.FixtureCollision");
                                        var snapshot = getSnapshot(datasourceName, datasources[datasourceName]);
                                        if(NOT recordMatches(seed, snapshot) AND NOT recordMatches(target, snapshot))
                                                throw(message="Reserved Embedded name belongs to another configuration; refusing to modify it", type="CCSTest.FixtureCollision");
                                        arrayAppend(presentNames, datasourceName);
                                }
                        }
                        if(NOT arrayLen(rows)){
                                for(var datasourceName in presentNames)
                                        context.api.deleteDatasource(dsnname=datasourceName);
                        }
                        else {
                                if(arrayLen(presentNames) GT 1)
                                        throw(message="Both reserved Embedded names exist; refusing to overwrite them", type="CCSTest.FixtureCollision");
                                if((NOT arrayLen(presentNames) AND (directoryExists(seed.database) OR directoryExists(target.database)))
                                        OR (fixture.isnewdb AND directoryExists(fixture.database)))
                                        throw(message="Reserved Embedded database folder already exists; no database files were changed", type="CCSTest.FixtureCollision");
                                var options = {name=fixture.dsn, database=fixture.database, isnewdb=fixture.isnewdb,
                                        description=fixture.description, pooling=false, login_timeout=1, validateConnection=false};
                                if(arrayLen(presentNames)){
                                        if(compareNoCase(presentNames[1], fixture.dsn) NEQ 0)
                                                options.originaldsn = presentNames[1];
                                        else
                                                context.api.deleteDatasource(dsnname=presentNames[1]);
                                }
                                context.api.setDerbyEmbedded(argumentCollection=options);
                        }
                }
                finally {
                        context.adminUtil.logout(context.admin);
                }
                return getSetting(arguments.settingName);
        }
}