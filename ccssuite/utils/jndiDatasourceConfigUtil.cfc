component output="false" {
        public function init(){
                return this;
        }

        public array function getFields(){
                return [
                        {name="jndiDsn", field="dsn", label="CF Data Source Name", type="text"},
                        {name="jndiName", field="jndiname", label="JNDI Name", type="text"},
                        {name="jndiUsername", field="username", label="User name", type="text"},
                        {name="jndiPassword", field="password", label="Password", type="password"},
                        {name="jndiDescription", field="description", label="Description", type="textarea"}
                ];
        }

        public struct function getField(required string settingName){
                for(var field in getFields()){
                        if(compareNoCase(field.name, arguments.settingName) EQ 0)
                                return field;
                }
                throw(message="Unsupported J2EE Datasource (JNDI) setting", type="CCSTest.ConfigError");
        }

        public array function getColumns(){
                return ["dsn", "driver", "jndiname", "username", "password", "description"];
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
                var fixture = {dsn="CCSSUITE_JNDI_" & uCase(field), driver="jndi",
                        jndiname="java:comp/env/jdbc/CCSSUITE_JNDI_" & uCase(field), username="ccssuite_fixture_user",
                        password="fixture-password-original", description="CCSSUITE reserved JNDI fixture"};
                if(NOT arguments.seed){
                        switch(field){
                                case "dsn": fixture.dsn &= "_RENAMED"; break;
                                case "jndiname": fixture.jndiname &= "_UPDATED"; break;
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

        public array function getRequiredResourceNames(required string settingName){
                var seed = getFixture(arguments.settingName, true);
                var target = getFixture(arguments.settingName);
                return seed.jndiname EQ target.jndiname ? [seed.jndiname] : [seed.jndiname, target.jndiname];
        }

        public array function getFixtureResourceStatus(required string settingName){
                var statuses = [];
                var namingContext = createObject("java", "javax.naming.InitialContext").init();
                try {
                        for(var resourceName in getRequiredResourceNames(arguments.settingName)){
                                var status = {name=resourceName, available=false, dataSource=false};
                                try {
                                        var resource = namingContext.lookup(resourceName);
                                        status.available = true;
                                        status.dataSource = isInstanceOf(resource, "javax.sql.DataSource");
                                }
                                catch(any unavailableResource){
                                        status.available = false;
                                }
                                arrayAppend(statuses, status);
                        }
                        return statuses;
                }
                finally {
                        namingContext.close();
                }
        }

        public void function assertFixtureResourceStatus(required string settingName, required array statuses){
                var missing = [];
                for(var resourceName in getRequiredResourceNames(arguments.settingName)){
                        var available = false;
                        for(var status in arguments.statuses){
                                if(isStruct(status) AND structKeyExists(status, "name") AND isSimpleValue(status.name)
                                        AND compare(status.name, resourceName) EQ 0
                                        AND structKeyExists(status, "available") AND isBoolean(status.available) AND status.available
                                        AND structKeyExists(status, "dataSource") AND isBoolean(status.dataSource) AND status.dataSource){
                                        available = true;
                                        break;
                                }
                        }
                        if(NOT available)
                                arrayAppend(missing, resourceName);
                }
                if(arrayLen(missing))
                        throw(message="JNDI test prerequisite missing: " & arrayToList(missing, ", "),
                                detail="The runtime naming context must contain these container-managed javax.sql.DataSource resources before setJNDI can register them. For the local Windows nodes, run setup_jndi_fixtures.ps1 -Apply -ConfirmDisposableInstances in elevated Windows PowerShell, then run it with -Verify after startup. No Administrator setting or JNDI binding was changed by this test. This test has not reached the CCS assertion.",
                                type="CCSTest.JndiResourceUnavailable");
        }

        public void function requireFixtureResources(required string settingName){
                assertFixtureResourceStatus(arguments.settingName, getFixtureResourceStatus(arguments.settingName));
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
                for(var column in ["driver", "username", "password", "description"]){
                        if(NOT structKeyExists(arguments.datasource, column) OR NOT isSimpleValue(arguments.datasource[column]))
                                throw(message="Reserved JNDI metadata is unavailable", type="CCSTest.ConfigError");
                }
                var jndiName = "";
                if(structKeyExists(arguments.datasource, "jndiname") AND isSimpleValue(arguments.datasource.jndiname))
                        jndiName = arguments.datasource.jndiname;
                else if(structKeyExists(arguments.datasource, "urlmap") AND isStruct(arguments.datasource.urlmap)
                        AND structKeyExists(arguments.datasource.urlmap, "jndiname") AND isSimpleValue(arguments.datasource.urlmap.jndiname))
                        jndiName = arguments.datasource.urlmap.jndiname;
                else if(structKeyExists(arguments.datasource, "url") AND isSimpleValue(arguments.datasource.url)
                        AND left(arguments.datasource.url, len("java:comp/env/jdbc/CCSSUITE_JNDI_")) EQ "java:comp/env/jdbc/CCSSUITE_JNDI_")
                        jndiName = arguments.datasource.url;
                if(NOT len(jndiName))
                        throw(message="Reserved JNDI Name metadata is unavailable", type="CCSTest.ConfigError");
                return {dsn=arguments.datasourceName, driver=arguments.datasource.driver, jndiname=jndiName,
                        username=arguments.datasource.username,
                        password=len(arguments.datasource.password) ? "sha256:" & hash(arguments.datasource.password, "SHA-256") : "",
                        description=arguments.datasource.description};
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
                                                throw(message="Reserved JNDI metadata is invalid", type="CCSTest.ConfigError");
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
                        throw(message="JNDI fixture state must be JSON", type="CCSTest.ConfigError");
                var rows = deserializeJSON(arguments.settingValue);
                if(NOT isArray(rows) OR arrayLen(rows) GT 1)
                        throw(message="Unsupported JNDI fixture state", type="CCSTest.ConfigError");
                var fixture = {};
                if(arrayLen(rows)){
                        if(NOT isStruct(rows[1]) OR structCount(rows[1]) NEQ arrayLen(getColumns()))
                                throw(message="Only complete reserved JNDI fixtures are allowed", type="CCSTest.ConfigError");
                        if(recordMatches(seed, rows[1]) AND rows[1].password EQ seed.password)
                                fixture = seed;
                        else if(recordMatches(target, rows[1]) AND rows[1].password EQ target.password)
                                fixture = target;
                        else
                                throw(message="Only fixed reserved JNDI field values are allowed", type="CCSTest.ConfigError");
                        requireFixtureResources(arguments.settingName);
                }
                var context = getApi();
                try {
                        var datasources = context.api.getDatasources();
                        var presentNames = [];
                        for(var datasourceName in getFixtureNames(arguments.settingName)){
                                if(structKeyExists(datasources, datasourceName)){
                                        if(NOT isStruct(datasources[datasourceName]))
                                                throw(message="Reserved JNDI name belongs to another configuration", type="CCSTest.FixtureCollision");
                                        var snapshot = normalizeDatasource(datasourceName, datasources[datasourceName]);
                                        if(NOT recordMatches(seed, snapshot, false) AND NOT recordMatches(target, snapshot, false))
                                                throw(message="Reserved JNDI name belongs to another configuration; refusing to modify it", type="CCSTest.FixtureCollision");
                                        arrayAppend(presentNames, datasourceName);
                                }
                        }
                        if(NOT arrayLen(rows)){
                                for(var datasourceName in presentNames)
                                        context.api.deleteDatasource(dsnname=datasourceName);
                        }
                        else {
                                if(arrayLen(presentNames) GT 1)
                                        throw(message="Both reserved JNDI names exist; refusing to overwrite them", type="CCSTest.FixtureCollision");
                                var options = {name=fixture.dsn, jndiname=fixture.jndiname, username=fixture.username,
                                        password=hash(seed.dsn & ":" & fixture.password, "SHA-256"), encryptpassword=true, description=fixture.description};
                                if(arrayLen(presentNames)){
                                        if(compareNoCase(presentNames[1], fixture.dsn) NEQ 0)
                                                options.originaldsn = presentNames[1];
                                        else
                                                context.api.deleteDatasource(dsnname=presentNames[1]);
                                }
                                context.api.setJNDI(argumentCollection=options);
                        }
                }
                finally {
                        context.adminUtil.logout(context.admin);
                }
                return getSetting(arguments.settingName);
        }
}