component output="false" {
        public function init(){
                return this;
        }

        public boolean function isDerbyClientSetting(required string settingName){
                return listFindNoCase("derbyClientDsn,derbyClientDatabase,derbyClientHost,derbyClientPort,derbyClientUsername,derbyClientPassword,derbyClientDescription", arguments.settingName) GT 0;
        }

        public boolean function isDerbyEmbeddedSetting(required string settingName){
                return listFindNoCase("derbyEmbeddedDsn,derbyEmbeddedDatabase,derbyEmbeddedCreateDatabase,derbyEmbeddedDescription", arguments.settingName) GT 0;
        }

        public boolean function isDb2Setting(required string settingName){
                return listFindNoCase("db2Dsn,db2Database,db2Host,db2Port,db2Username,db2Password,db2Description", arguments.settingName) GT 0;
        }

        public boolean function isJndiSetting(required string settingName){
                return listFindNoCase("jndiDsn,jndiName,jndiUsername,jndiPassword,jndiDescription", arguments.settingName) GT 0;
        }

        public boolean function isMsAccessSetting(required string settingName){
                return listFindNoCase("msAccessDsn,msAccessDatabaseFile,msAccessSystemDatabaseFile,msAccessUseDefaultUsername,msAccessUsername,msAccessPassword,msAccessDescription", arguments.settingName) GT 0;
        }

        public boolean function isPreparedDatasourceSetting(required string settingName){
                return isDerbyClientSetting(arguments.settingName) OR isDerbyEmbeddedSetting(arguments.settingName)
                        OR isDb2Setting(arguments.settingName) OR isJndiSetting(arguments.settingName) OR isMsAccessSetting(arguments.settingName);
        }

        public string function getSettingLabel(required string settingName){
                if(isMsAccessSetting(arguments.settingName))
                        return "Microsoft Access - " & new cfsuite.ccssuite.utils.msAccessDatasourceConfigUtil().init().getField(arguments.settingName).label;
                if(isJndiSetting(arguments.settingName))
                        return "J2EE Datasource (JNDI) - " & new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init().getField(arguments.settingName).label;
                if(isDb2Setting(arguments.settingName))
                        return "DB2 Universal Database - " & new cfsuite.ccssuite.utils.db2DatasourceConfigUtil().init().getField(arguments.settingName).label;
                if(isDerbyEmbeddedSetting(arguments.settingName))
                        return "Apache Derby Embedded - " & new cfsuite.ccssuite.utils.derbyEmbeddedDatasourceConfigUtil().init().getField(arguments.settingName).label;
                if(isDerbyClientSetting(arguments.settingName))
                        return "Apache Derby Client - " & new cfsuite.ccssuite.utils.derbyClientDatasourceConfigUtil().init().getField(arguments.settingName).label;
                getFixture(arguments.settingName);
                return arguments.settingName EQ "dsn" ? "Data Source Name" : "Driver";
        }

        public array function getSnapshotColumns(required string settingName){
                if(isMsAccessSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.msAccessDatasourceConfigUtil().init().getColumns();
                if(isJndiSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init().getColumns();
                if(isDb2Setting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.db2DatasourceConfigUtil().init().getColumns();
                if(isDerbyEmbeddedSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyEmbeddedDatasourceConfigUtil().init().getColumns();
                if(isDerbyClientSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyClientDatasourceConfigUtil().init().getColumns();
                getFixture(arguments.settingName);
                return ["dsn", "driver"];
        }

        public string function getSeedState(required string settingName){
                if(isMsAccessSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.msAccessDatasourceConfigUtil().init().getSeedState(arguments.settingName);
                if(isJndiSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init().getSeedState(arguments.settingName);
                if(isDb2Setting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.db2DatasourceConfigUtil().init().getSeedState(arguments.settingName);
                if(isDerbyEmbeddedSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyEmbeddedDatasourceConfigUtil().init().getSeedState(arguments.settingName);
                return new cfsuite.ccssuite.utils.derbyClientDatasourceConfigUtil().init().getSeedState(arguments.settingName);
        }

        public boolean function setMatches(required string settingName, required any preset, required any actual, required any requested){
                if(isMsAccessSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.msAccessDatasourceConfigUtil().init().setMatches(arguments.settingName, arguments.preset, arguments.actual, arguments.requested);
                if(isJndiSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init().setMatches(arguments.settingName, arguments.preset, arguments.actual, arguments.requested);
                if(isDb2Setting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.db2DatasourceConfigUtil().init().setMatches(arguments.settingName, arguments.preset, arguments.actual, arguments.requested);
                if(isDerbyClientSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyClientDatasourceConfigUtil().init().setMatches(arguments.settingName, arguments.preset, arguments.actual, arguments.requested);
                return configsMatch(arguments.settingName, arguments.requested, arguments.actual);
        }

        private struct function getApi(){
                if(NOT structKeyExists(application, "constants"))
                        application.constants = new cfsuite.ccssuite.constants().init();
                var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
                var admin = adminUtil.createAdministrator();
                adminUtil.login(application.constants.CF_CONFIG);
                return {admin=admin, adminUtil=adminUtil, api=createObject("component", "CFIDE.adminapi.datasource")};
        }

        private struct function getFixture(required string settingName){
                switch(lCase(arguments.settingName)){
                        case "dsn": return {dsn="CCSSUITE_DATASOURCE_NAME", driver="MSSQLServer"};
                        case "driver": return {dsn="CCSSUITE_DATASOURCE_DRIVER", driver="MySQL_DD"};
                        default: throw(message="Unsupported Data Sources setting", type="CCSTest.ConfigError");
                }
        }

        public string function getTestState(required string settingName){
                if(isMsAccessSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.msAccessDatasourceConfigUtil().init().getTestState(arguments.settingName);
                if(isJndiSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init().getTestState(arguments.settingName);
                if(isDb2Setting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.db2DatasourceConfigUtil().init().getTestState(arguments.settingName);
                if(isDerbyEmbeddedSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyEmbeddedDatasourceConfigUtil().init().getTestState(arguments.settingName);
                if(isDerbyClientSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyClientDatasourceConfigUtil().init().getTestState(arguments.settingName);
                return serializeJSON([getFixture(arguments.settingName)]);
        }

        public boolean function configsMatch(required string settingName, required any expected, required any actual){
                if(isMsAccessSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.msAccessDatasourceConfigUtil().init().configsMatch(arguments.settingName, arguments.expected, arguments.actual);
                if(isJndiSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init().configsMatch(arguments.settingName, arguments.expected, arguments.actual);
                if(isDb2Setting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.db2DatasourceConfigUtil().init().configsMatch(arguments.settingName, arguments.expected, arguments.actual);
                if(isDerbyEmbeddedSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyEmbeddedDatasourceConfigUtil().init().configsMatch(arguments.settingName, arguments.expected, arguments.actual);
                if(isDerbyClientSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyClientDatasourceConfigUtil().init().configsMatch(arguments.settingName, arguments.expected, arguments.actual);
                getFixture(arguments.settingName);
                if(NOT isJSON(arguments.expected) OR NOT isJSON(arguments.actual))
                        return false;
                var expectedRows = deserializeJSON(arguments.expected);
                var actualRows = deserializeJSON(arguments.actual);
                if(NOT isArray(expectedRows) OR NOT isArray(actualRows) OR arrayLen(expectedRows) GT 1
                        OR arrayLen(expectedRows) NEQ arrayLen(actualRows))
                        return false;
                if(NOT arrayLen(expectedRows))
                        return true;
                if(NOT isStruct(expectedRows[1]) OR NOT isStruct(actualRows[1]))
                        return false;
                for(var column in ["dsn", "driver"]){
                        if(NOT structKeyExists(expectedRows[1], column) OR NOT structKeyExists(actualRows[1], column)
                                OR NOT isSimpleValue(expectedRows[1][column]) OR NOT isSimpleValue(actualRows[1][column])
                                OR compareNoCase(expectedRows[1][column], actualRows[1][column]) NEQ 0)
                                return false;
                }
                return true;
        }

        public string function getSetting(required string settingName){
                if(isMsAccessSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.msAccessDatasourceConfigUtil().init().getSetting(arguments.settingName);
                if(isJndiSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init().getSetting(arguments.settingName);
                if(isDb2Setting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.db2DatasourceConfigUtil().init().getSetting(arguments.settingName);
                if(isDerbyEmbeddedSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyEmbeddedDatasourceConfigUtil().init().getSetting(arguments.settingName);
                if(isDerbyClientSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyClientDatasourceConfigUtil().init().getSetting(arguments.settingName);
                var fixture = getFixture(arguments.settingName);
                var context = getApi();
                try {
                        var datasources = context.api.getDatasources();
                        if(NOT structKeyExists(datasources, fixture.dsn))
                                return "[]";
                        var datasource = datasources[fixture.dsn];
                        if(NOT isStruct(datasource) OR NOT structKeyExists(datasource, "driver") OR NOT isSimpleValue(datasource.driver))
                                throw(message="Reserved datasource metadata is unavailable", type="CCSTest.ConfigError");
                        return serializeJSON([{dsn=fixture.dsn, driver=datasource.driver}]);
                }
                finally {
                        context.adminUtil.logout(context.admin);
                }
        }

        public void function assertEmptyFixturePresets(required string settingName, required struct nodeValues){
                getTestState(arguments.settingName);
                if(structIsEmpty(arguments.nodeValues))
                        throw(message="No datasource baselines were captured; no configuration was changed", type="CCSTest.FixtureUnavailable");
                for(var nodeKey in arguments.nodeValues){
                        if(NOT configsMatch(arguments.settingName, "[]", arguments.nodeValues[nodeKey]))
                                throw(message="Datasource baseline unavailable or reserved name already exists on node " & nodeKey,
                                        detail="Deploy matching datasource utilities on every node. Existing datasources are not overwritten.", type="CCSTest.FixtureUnavailable");
                }
        }

        private boolean function isOwnedFixture(required struct datasource, required struct fixture){
                return structKeyExists(arguments.datasource, "driver") AND isSimpleValue(arguments.datasource.driver)
                        AND compareNoCase(arguments.datasource.driver, arguments.fixture.driver) EQ 0
                        AND structKeyExists(arguments.datasource, "description")
                        AND isSimpleValue(arguments.datasource.description)
                        AND arguments.datasource.description EQ "CCSSUITE reserved datasource fixture"
                        AND structKeyExists(arguments.datasource, "url") AND isSimpleValue(arguments.datasource.url)
                        AND reFindNoCase("^jdbc:[a-z0-9:]+://127\.0\.0\.1:1([;/]|$)", arguments.datasource.url) GT 0
                        AND findNoCase("ccssuite_fixture", arguments.datasource.url) GT 0;
        }

        public string function setSetting(required string settingName, required any settingValue){
                if(isMsAccessSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.msAccessDatasourceConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
                if(isJndiSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
                if(isDb2Setting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.db2DatasourceConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
                if(isDerbyEmbeddedSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyEmbeddedDatasourceConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
                if(isDerbyClientSetting(arguments.settingName))
                        return new cfsuite.ccssuite.utils.derbyClientDatasourceConfigUtil().init().setSetting(arguments.settingName, arguments.settingValue);
                var fixture = getFixture(arguments.settingName);
                if(NOT isJSON(arguments.settingValue))
                        throw(message="Datasource fixture state must be JSON", type="CCSTest.ConfigError");
                var rows = deserializeJSON(arguments.settingValue);
                if(NOT isArray(rows) OR arrayLen(rows) GT 1)
                        throw(message="Unsupported datasource fixture state", type="CCSTest.ConfigError");
                if(arrayLen(rows) AND (NOT isStruct(rows[1]) OR structCount(rows[1]) NEQ 2
                        OR NOT configsMatch(arguments.settingName, getTestState(arguments.settingName), arguments.settingValue)))
                        throw(message="Only the fixed reserved datasource fixture is allowed", type="CCSTest.ConfigError");
                var context = getApi();
                try {
                        var datasources = context.api.getDatasources();
                        if(structKeyExists(datasources, fixture.dsn)){
                                if(NOT isStruct(datasources[fixture.dsn]) OR NOT isOwnedFixture(datasources[fixture.dsn], fixture))
                                        throw(message="Reserved datasource name belongs to another configuration; refusing to modify it", type="CCSTest.FixtureCollision");
                                if(NOT arrayLen(rows))
                                        context.api.deleteDatasource(dsnname=fixture.dsn);
                        }
                        if(arrayLen(rows)){
                                var options = {name=fixture.dsn, host="127.0.0.1", port="1", database="ccssuite_fixture",
                                        username="", password="", description="CCSSUITE reserved datasource fixture",
                                        pooling=false, login_timeout=1, validateConnection=false};
                                if(arguments.settingName EQ "dsn"){
                                        options.selectmethod = "direct";
                                        context.api.setMSSQL(argumentCollection=options);
                                }
                                else {
                                        context.api.setMySQL_DD(argumentCollection=options);
                                }
                        }
                }
                finally {
                        context.adminUtil.logout(context.admin);
                }
                return getSetting(arguments.settingName);
        }

        public array function getDatasourceRows(){
                var context = getApi();
                try {
                        var datasources = context.api.getDatasources();
                        var names = structKeyArray(datasources);
                        arraySort(names, "textnocase");
                        var rows = [];
                        for(var datasourceName in names){
                                var datasource = datasources[datasourceName];
                                if(NOT isStruct(datasource) OR NOT structKeyExists(datasource, "driver") OR NOT isSimpleValue(datasource.driver))
                                        throw(message="Datasource driver metadata is unavailable", type="CCSTest.ConfigError");
                                arrayAppend(rows, {actions="Read-only", dsn=datasourceName, driver=datasource.driver, status="Not verified"});
                        }
                        return rows;
                }
                finally {
                        context.adminUtil.logout(context.admin);
                }
        }

        public boolean function listColumnsMatch(required array rows){
                for(var row in arguments.rows){
                        if(NOT isStruct(row))
                                return false;
                        for(var column in ["actions", "dsn", "driver", "status"]){
                                if(NOT structKeyExists(row, column) OR NOT isSimpleValue(row[column]))
                                        return false;
                        }
                        if(NOT len(trim(row.dsn)) OR NOT len(trim(row.driver)) OR row.actions NEQ "Read-only" OR row.status NEQ "Not verified")
                                return false;
                }
                return true;
        }
}