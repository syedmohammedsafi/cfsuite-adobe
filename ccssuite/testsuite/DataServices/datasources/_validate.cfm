<cfscript>
cfcontent(type="application/json", reset=true);
adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
admin = adminUtil.createAdministrator();
try {
        if(NOT structKeyExists(application, "constants"))
                application.constants = new cfsuite.ccssuite.constants().init();
        adminUtil.login(application.constants.CF_CONFIG);
        datasourceApi = createObject("component", "CFIDE.adminapi.datasource");
        datasources = datasourceApi.getDatasources();
        result = {configurationWrites=false, methods=[], availableMethods=[], credentialMethods=[], derbyMetadata=[], embeddedMetadata=[], datasourceCount=structCount(datasources), datasourceKeys=[], driverMetadata={}, odbcDatasources=datasourceApi.getODBCDatasources(), odbcSocketMetadata=[]};
        result.odbcDsnCount = isQuery(result.odbcDatasources) ? result.odbcDatasources.recordCount : 0;
        for(method in getMetadata(admin).functions){
                if(reFindNoCase("encrypt|decrypt", method.name))
                        arrayAppend(result.credentialMethods, {name=method.name, parameters=method.parameters});
        }
        for(method in getMetadata(datasourceApi).functions){
                arrayAppend(result.availableMethods, method.name);
                if(listFindNoCase("setMSAccess,setJNDI,setDB2,setDerbyEmbedded,setDerbyClient,setMySQL,setMySQL5,setMySQL_DD,setMSSQL,setSQLServer,setOracle,setOther,setPostgreSQL,setPostGreSQL,setODBCSocket,deleteDatasource,getDatasources,getODBCDatasources,getDrivers,verifyDatasource,verifyDSN", method.name))
                        arrayAppend(result.methods, {name=method.name, parameters=method.parameters});
        }
        for(datasourceName in datasources){
                if(isStruct(datasources[datasourceName])){
                        result.datasourceKeys = structKeyArray(datasources[datasourceName]);
                        for(driverField in ["driver", "class", "type", "vendor"]){
                                if(structKeyExists(datasources[datasourceName], driverField) AND isSimpleValue(datasources[datasourceName][driverField]))
                                        result.driverMetadata[driverField] = datasources[datasourceName][driverField];
                        }
                        break;
                }
        }
        configUtil = new cfsuite.ccssuite.utils.datasourceConfigUtil().init();
        for(datasourceName in datasources){
                datasource = datasources[datasourceName];
                if(isStruct(datasource) AND structKeyExists(datasource, "driver") AND datasource.driver EQ "Apache Derby Embedded"){
                        shape = {keys=structKeyArray(datasource), urlMapKeys=[], creationFlagPresent=false};
                        if(structKeyExists(datasource, "urlmap") AND isStruct(datasource.urlmap))
                                shape.urlMapKeys = structKeyArray(datasource.urlmap);
                        if(structKeyExists(datasource, "url") AND isSimpleValue(datasource.url))
                                shape.creationFlagPresent = reFindNoCase(";create=(true|false|yes|no)(;|$)", datasource.url) GT 0;
                        arrayAppend(result.embeddedMetadata, shape);
                }
                if(isStruct(datasource) AND structKeyExists(datasource, "driver") AND datasource.driver EQ "Apache Derby Client"){
                        shape = {keys=structKeyArray(datasource), urlMapKeys=[]};
                        if(structKeyExists(datasource, "urlmap") AND isStruct(datasource.urlmap))
                                shape.urlMapKeys = structKeyArray(datasource.urlmap);
                        arrayAppend(result.derbyMetadata, shape);
                }
                if(isStruct(datasource) AND structKeyExists(datasource, "driver") AND datasource.driver EQ "ODBCSocket")
                        arrayAppend(result.odbcSocketMetadata, {dsn=datasourceName, keys=structKeyArray(datasource)});
        }
        apiUtil = new cfsuite.ccssuite.utils.ccsApiUtil().init();
        comparisonUtil = new cfsuite.ccssuite.utils.serverSettingsApiUtil().init();
        new cfsuite.ccssuite.utils.dataServicesTestUtil().init();
        new cfsuite.ccssuite.testDriver();
        new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
        result.cases = ["dsn", "driver"];
        derbyUtil = new cfsuite.ccssuite.utils.derbyClientDatasourceConfigUtil().init();
        displayUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
        accessUtil = new cfsuite.ccssuite.utils.msAccessDatasourceConfigUtil().init();
        result.accessCases = [];
        for(accessField in accessUtil.getFields()){
                accessTarget = accessUtil.getTestState(accessField.name);
                for(accessSeed in [true, false]){
                        accessFixture = deserializeJSON(accessSeed ? accessUtil.getSeedState(accessField.name) : accessTarget)[1];
                        accessArguments = accessUtil.getSetterArguments(accessField.name, accessSeed);
                        accessOriginal = deserializeJSON(accessUtil.getSeedState(accessField.name))[1];
                        if(accessArguments.username NEQ accessFixture.username
                                OR accessArguments.password NEQ hash(accessOriginal.dsn & ":" & accessFixture.password, "SHA-256")
                                OR structKeyExists(accessArguments, "defaultusername") OR structKeyExists(accessArguments, "defaultpassword")
                                OR accessArguments.validateConnection)
                                throw(message="Microsoft Access setter credential mapping is incorrect");
                }
                legacyAccessSeed = deserializeJSON(accessUtil.getSeedState(accessField.name))[1];
                legacyAccessSeed.username = "System";
                legacyAccessSeed.password = "";
                if(NOT accessUtil.isOwnedDatasource(accessField.name, legacyAccessSeed, true)
                        OR accessUtil.isOwnedDatasource(accessField.name, legacyAccessSeed))
                        throw(message="Microsoft Access legacy seed ownership is not cleanup-only");
                for(accessColumn in accessUtil.getColumns()){
                        changedLegacySeed = duplicate(legacyAccessSeed);
                        changedLegacySeed[accessColumn] = "unrelated-configuration";
                        if(accessUtil.isOwnedDatasource(accessField.name, changedLegacySeed, true))
                                throw(message="Microsoft Access legacy cleanup ignored " & accessColumn);
                }
                if(NOT accessUtil.configsMatch(accessField.name, accessTarget, accessTarget)
                        OR accessUtil.configsMatch(accessField.name, accessUtil.getSeedState(accessField.name), accessTarget)
                        OR accessUtil.configsMatch(accessField.name, accessTarget, "[]"))
                        throw(message="Microsoft Access field fixture comparison failed");
                for(accessColumn in accessUtil.getColumns()){
                        changed = deserializeJSON(accessTarget);
                        changed[1][accessColumn] = "ccssuite-invalid-field";
                        if(accessUtil.configsMatch(accessField.name, accessTarget, serializeJSON(changed)))
                                throw(message="Microsoft Access comparison ignored " & accessColumn);
                }
                accessRow = deserializeJSON(accessTarget)[1];
                expectedDisplay = accessField.field EQ "password" ? "[redacted]"
                        : (accessField.field EQ "UseTrustedConnection" ? "Disabled" : accessRow[accessField.field]);
                if(compare(accessUtil.formatDisplayValue(accessField.name, accessTarget), expectedDisplay) NEQ 0
                        OR accessUtil.formatDisplayValue(accessField.name, "[]") NEQ "Not registered"
                        OR accessUtil.formatDisplayValue(accessField.name, "") NEQ "(unavailable)")
                        throw(message="Microsoft Access selected-field display failed");
                invalidAccessRow = duplicate(accessRow);
                invalidAccessRow.databasefile = "C:/unrelated-database.mdb";
                for(invalidAccessValue in ["", "{}", serializeJSON([invalidAccessRow]), serializeJSON([accessRow, accessRow])]){
                        rejected = false;
                        try {
                                accessUtil.setSetting(accessField.name, invalidAccessValue);
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe Microsoft Access setter payload was accepted");
                }
                if(NOT isJSON(accessUtil.getSetting(accessField.name)))
                        throw(message="Microsoft Access getter did not return JSON");
                arrayAppend(result.accessCases, accessField.name);
        }
        accessPasswordTarget = accessUtil.getTestState("msAccessPassword");
        accessPasswordPreset = deserializeJSON(accessUtil.getSeedState("msAccessPassword"));
        accessPasswordActual = deserializeJSON(accessPasswordTarget);
        accessPasswordPreset[1].password = "sha256:" & repeatString("a", 64);
        accessPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT accessUtil.setMatches("msAccessPassword", serializeJSON(accessPasswordPreset), serializeJSON(accessPasswordActual), accessPasswordTarget))
                throw(message="Changed Microsoft Access password fingerprint was rejected");
        accessPasswordActual[1].password = accessPasswordPreset[1].password;
        if(accessUtil.setMatches("msAccessPassword", serializeJSON(accessPasswordPreset), serializeJSON(accessPasswordActual), accessPasswordTarget)
                OR accessUtil.setMatches("msAccessPassword", "[]", serializeJSON(accessPasswordActual), accessPasswordTarget))
                throw(message="Unchanged or unseeded Microsoft Access password was accepted");
        accessSnapshotInput = deserializeJSON(accessUtil.getSeedState("msAccessDatabaseFile"))[1];
        accessDirectSnapshot = accessUtil.normalizeDatasource(accessSnapshotInput.dsn, accessSnapshotInput);
        accessSnapshotInput.urlmap = {};
        for(accessColumn in ["databasefile", "systemDatabaseFile", "UseTrustedConnection"]){
                accessSnapshotInput.urlmap[accessColumn] = accessSnapshotInput[accessColumn];
                structDelete(accessSnapshotInput, accessColumn);
        }
        accessMappedSnapshot = accessUtil.normalizeDatasource(accessSnapshotInput.dsn, accessSnapshotInput);
        if(NOT accessUtil.configsMatch("msAccessDatabaseFile", serializeJSON([accessDirectSnapshot]), serializeJSON([accessMappedSnapshot])))
                throw(message="Microsoft Access direct and URL-map metadata differ");
        structDelete(accessSnapshotInput.urlmap, "systemDatabaseFile");
        rejected = false;
        try {
                accessUtil.normalizeDatasource(accessSnapshotInput.dsn, accessSnapshotInput);
        }
        catch(CCSTest.ConfigError expectedFailure){
                rejected = true;
        }
        if(NOT rejected)
                throw(message="Missing Microsoft Access connection metadata was accepted");
        jndiUtil = new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init();
        result.jndiPrerequisites = {};
        for(jndiField in jndiUtil.getFields()){
                readyResources = [];
                for(resourceName in jndiUtil.getRequiredResourceNames(jndiField.name))
                        arrayAppend(readyResources, {name=resourceName, available=true, dataSource=true});
                jndiUtil.assertFixtureResourceStatus(jndiField.name, readyResources);
                for(invalidResources in [[], [{name=readyResources[1].name, available=false, dataSource=false}], [{name=readyResources[1].name, available=true, dataSource=false}]]){
                        rejected = false;
                        try {
                                jndiUtil.assertFixtureResourceStatus(jndiField.name, invalidResources);
                        }
                        catch(CCSTest.JndiResourceUnavailable expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Missing or non-datasource JNDI prerequisite was accepted");
                }
                result.jndiPrerequisites[jndiField.name] = jndiUtil.getFixtureResourceStatus(jndiField.name);
                jndiTarget = jndiUtil.getTestState(jndiField.name);
                if(NOT jndiUtil.configsMatch(jndiField.name, jndiTarget, jndiTarget)
                        OR jndiUtil.configsMatch(jndiField.name, jndiUtil.getSeedState(jndiField.name), jndiTarget)
                        OR jndiUtil.configsMatch(jndiField.name, jndiTarget, "[]"))
                        throw(message="JNDI field fixture comparison failed");
                for(jndiColumn in jndiUtil.getColumns()){
                        changed = deserializeJSON(jndiTarget);
                        changed[1][jndiColumn] = "ccssuite-invalid-field";
                        if(jndiUtil.configsMatch(jndiField.name, jndiTarget, serializeJSON(changed)))
                                throw(message="JNDI comparison ignored " & jndiColumn);
                }
                jndiRow = deserializeJSON(jndiTarget)[1];
                expectedDisplay = jndiField.field EQ "password" ? "[redacted]" : jndiRow[jndiField.field];
                if(compare(jndiUtil.formatDisplayValue(jndiField.name, jndiTarget), expectedDisplay) NEQ 0
                        OR jndiUtil.formatDisplayValue(jndiField.name, "[]") NEQ "Not registered"
                        OR jndiUtil.formatDisplayValue(jndiField.name, "") NEQ "(unavailable)")
                        throw(message="JNDI selected-field display failed");
                invalidJndiRow = duplicate(jndiRow);
                invalidJndiRow.jndiname = "java:comp/env/jdbc/ccssuite-invalid-name";
                for(invalidJndiValue in ["", "{}", serializeJSON([invalidJndiRow]), serializeJSON([jndiRow, jndiRow])]){
                        rejected = false;
                        try {
                                apiUtil.setSetting(jndiField.name, invalidJndiValue, "datasources", "DataServices");
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe JNDI setter payload was accepted");
                }
                if(NOT isJSON(jndiUtil.getSetting(jndiField.name)))
                        throw(message="JNDI getter did not return JSON");
        }
        jndiSnapshotInput = deserializeJSON(jndiUtil.getSeedState("jndiName"))[1];
        jndiSnapshot = jndiUtil.normalizeDatasource(jndiSnapshotInput.dsn, jndiSnapshotInput);
        if(jndiSnapshot.jndiname NEQ jndiSnapshotInput.jndiname OR NOT reFindNoCase("^sha256:[a-f0-9]{64}$", jndiSnapshot.password))
                throw(message="JNDI direct metadata normalization failed");
        jndiSnapshotInput.urlmap = {jndiname=jndiSnapshotInput.jndiname};
        structDelete(jndiSnapshotInput, "jndiname");
        jndiMappedSnapshot = jndiUtil.normalizeDatasource(jndiSnapshotInput.dsn, jndiSnapshotInput);
        if(NOT jndiUtil.configsMatch("jndiName", serializeJSON([jndiSnapshot]), serializeJSON([jndiMappedSnapshot])))
                throw(message="JNDI URL-map metadata normalization failed");
        jndiCaseVariant = duplicate(jndiSnapshot);
        jndiCaseVariant.jndiname = lCase(jndiCaseVariant.jndiname);
        if(jndiUtil.configsMatch("jndiName", serializeJSON([jndiSnapshot]), serializeJSON([jndiCaseVariant])))
                throw(message="Case-sensitive JNDI resource name was compared case-insensitively");
        jndiSnapshotInput.url = jndiSnapshotInput.urlmap.jndiname;
        structDelete(jndiSnapshotInput, "urlmap");
        jndiUrlSnapshot = jndiUtil.normalizeDatasource(jndiSnapshotInput.dsn, jndiSnapshotInput);
        if(NOT jndiUtil.configsMatch("jndiName", serializeJSON([jndiSnapshot]), serializeJSON([jndiUrlSnapshot])))
                throw(message="JNDI reserved URL metadata normalization failed");
        jndiSnapshotInput.url = "java:comp/env/jdbc/unrelated-resource";
        rejected = false;
        try {
                jndiUtil.normalizeDatasource(jndiSnapshotInput.dsn, jndiSnapshotInput);
        }
        catch(CCSTest.ConfigError expectedFailure){
                rejected = true;
        }
        if(NOT rejected)
                throw(message="Unrelated JNDI URL was accepted as reserved metadata");
        db2Util = new cfsuite.ccssuite.utils.db2DatasourceConfigUtil().init();
        for(db2Field in db2Util.getFields()){
                db2Target = db2Util.getTestState(db2Field.name);
                if(NOT db2Util.configsMatch(db2Field.name, db2Target, db2Target)
                        OR db2Util.configsMatch(db2Field.name, db2Target, "[]")
                        OR db2Util.configsMatch(db2Field.name, db2Util.getSeedState(db2Field.name), db2Target))
                        throw(message="DB2 field fixture comparison failed");
                for(db2Column in db2Util.getColumns()){
                        changed = deserializeJSON(db2Target);
                        changed[1][db2Column] = "ccssuite-invalid-field";
                        if(db2Util.configsMatch(db2Field.name, db2Target, serializeJSON(changed)))
                                throw(message="DB2 comparison ignored " & db2Column);
                }
                db2Row = deserializeJSON(db2Target)[1];
                expectedDisplay = db2Field.field EQ "password" ? "[redacted]" : db2Row[db2Field.field];
                if(compare(db2Util.formatDisplayValue(db2Field.name, db2Target), expectedDisplay) NEQ 0
                        OR db2Util.formatDisplayValue(db2Field.name, "[]") NEQ "Not registered"
                        OR db2Util.formatDisplayValue(db2Field.name, "") NEQ "(unavailable)")
                        throw(message="DB2 selected-field display failed");
                invalidDb2Row = duplicate(db2Row);
                invalidDb2Row.host = "ccssuite-invalid-host";
                for(invalidDb2Value in ["", "{}", serializeJSON([invalidDb2Row]), serializeJSON([db2Row, db2Row])]){
                        rejected = false;
                        try {
                                apiUtil.setSetting(db2Field.name, invalidDb2Value, "datasources", "DataServices");
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe DB2 setter value was accepted");
                }
                if(NOT isJSON(db2Util.getSetting(db2Field.name)))
                        throw(message="DB2 getter did not return JSON");
        }
        db2PasswordTarget = db2Util.getTestState("db2Password");
        db2PasswordPreset = deserializeJSON(db2Util.getSeedState("db2Password"));
        db2PasswordActual = deserializeJSON(db2PasswordTarget);
        db2PasswordPreset[1].password = "sha256:" & repeatString("a", 64);
        db2PasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT db2Util.setMatches("db2Password", serializeJSON(db2PasswordPreset), serializeJSON(db2PasswordActual), db2PasswordTarget))
                throw(message="Changed DB2 password fingerprint was rejected");
        db2PasswordActual[1].password = db2PasswordPreset[1].password;
        if(db2Util.setMatches("db2Password", serializeJSON(db2PasswordPreset), serializeJSON(db2PasswordActual), db2PasswordTarget)
                OR db2Util.setMatches("db2Password", "[]", serializeJSON(db2PasswordActual), db2PasswordTarget))
                throw(message="Unchanged or unseeded DB2 password was accepted");
        mssqlUtil = new cfsuite.ccssuite.utils.mssqlDatasourceConfigUtil().init();
        for(mssqlField in mssqlUtil.getFields()){
                mssqlTarget = mssqlUtil.getTestState(mssqlField.name);
                if(NOT mssqlUtil.configsMatch(mssqlField.name, mssqlTarget, mssqlTarget)
                        OR mssqlUtil.configsMatch(mssqlField.name, mssqlTarget, "[]")
                        OR mssqlUtil.configsMatch(mssqlField.name, mssqlUtil.getSeedState(mssqlField.name), mssqlTarget))
                        throw(message="Microsoft SQL Server field fixture comparison failed");
                for(mssqlColumn in mssqlUtil.getColumns()){
                        changed = deserializeJSON(mssqlTarget);
                        changed[1][mssqlColumn] = "ccssuite-invalid-field";
                        if(mssqlUtil.configsMatch(mssqlField.name, mssqlTarget, serializeJSON(changed)))
                                throw(message="Microsoft SQL Server comparison ignored " & mssqlColumn);
                }
                mssqlRow = deserializeJSON(mssqlTarget)[1];
                expectedDisplay = mssqlField.field EQ "password" ? "[redacted]" : mssqlRow[mssqlField.field];
                if(compare(mssqlUtil.formatDisplayValue(mssqlField.name, mssqlTarget), expectedDisplay) NEQ 0
                        OR mssqlUtil.formatDisplayValue(mssqlField.name, "[]") NEQ "Not registered"
                        OR mssqlUtil.formatDisplayValue(mssqlField.name, "") NEQ "(unavailable)")
                        throw(message="Microsoft SQL Server selected-field display failed");
                invalidMssqlRow = duplicate(mssqlRow);
                invalidMssqlRow.host = "ccssuite-invalid-host";
                for(invalidMssqlValue in ["", "{}", serializeJSON([invalidMssqlRow]), serializeJSON([mssqlRow, mssqlRow])]){
                        rejected = false;
                        try {
                                apiUtil.setSetting(mssqlField.name, invalidMssqlValue, "datasources", "DataServices");
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe SQL Server setter value was accepted");
                }
                if(NOT isJSON(mssqlUtil.getSetting(mssqlField.name)))
                        throw(message="SQL Server getter did not return JSON");
        }
        mssqlPasswordTarget = mssqlUtil.getTestState("mssqlPassword");
        mssqlPasswordPreset = deserializeJSON(mssqlUtil.getSeedState("mssqlPassword"));
        mssqlPasswordActual = deserializeJSON(mssqlPasswordTarget);
        mssqlPasswordPreset[1].password = "sha256:" & repeatString("a", 64);
        mssqlPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT mssqlUtil.setMatches("mssqlPassword", serializeJSON(mssqlPasswordPreset), serializeJSON(mssqlPasswordActual), mssqlPasswordTarget))
                throw(message="Changed SQL Server password fingerprint was rejected");
        mssqlPasswordActual[1].password = mssqlPasswordPreset[1].password;
        if(mssqlUtil.setMatches("mssqlPassword", serializeJSON(mssqlPasswordPreset), serializeJSON(mssqlPasswordActual), mssqlPasswordTarget)
                OR mssqlUtil.setMatches("mssqlPassword", "[]", serializeJSON(mssqlPasswordActual), mssqlPasswordTarget))
                throw(message="Unchanged or unseeded SQL Server password was accepted");
        mysqlUtil = new cfsuite.ccssuite.utils.mysqlDatasourceConfigUtil().init();
        for(mysqlField in mysqlUtil.getFields()){
                mysqlTarget = mysqlUtil.getTestState(mysqlField.name);
                if(NOT mysqlUtil.configsMatch(mysqlField.name, mysqlTarget, mysqlTarget)
                        OR mysqlUtil.configsMatch(mysqlField.name, mysqlTarget, "[]")
                        OR mysqlUtil.configsMatch(mysqlField.name, mysqlUtil.getSeedState(mysqlField.name), mysqlTarget))
                        throw(message="MySQL field fixture comparison failed");
                for(mysqlColumn in mysqlUtil.getColumns()){
                        changed = deserializeJSON(mysqlTarget);
                        changed[1][mysqlColumn] = "ccssuite-invalid-field";
                        if(mysqlUtil.configsMatch(mysqlField.name, mysqlTarget, serializeJSON(changed)))
                                throw(message="MySQL comparison ignored " & mysqlColumn);
                }
                mysqlRow = deserializeJSON(mysqlTarget)[1];
                expectedDisplay = mysqlField.field EQ "password" ? "[redacted]" : mysqlRow[mysqlField.field];
                if(compare(mysqlUtil.formatDisplayValue(mysqlField.name, mysqlTarget), expectedDisplay) NEQ 0
                        OR mysqlUtil.formatDisplayValue(mysqlField.name, "[]") NEQ "Not registered"
                        OR mysqlUtil.formatDisplayValue(mysqlField.name, "") NEQ "(unavailable)")
                        throw(message="MySQL selected-field display failed");
                invalidMysqlRow = duplicate(mysqlRow);
                invalidMysqlRow.host = "ccssuite-invalid-host";
                for(invalidMysqlValue in ["", "{}", serializeJSON([invalidMysqlRow]), serializeJSON([mysqlRow, mysqlRow])]){
                        rejected = false;
                        try {
                                apiUtil.setSetting(mysqlField.name, invalidMysqlValue, "datasources", "DataServices");
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe MySQL setter value was accepted");
                }
                if(NOT isJSON(mysqlUtil.getSetting(mysqlField.name)))
                        throw(message="MySQL getter did not return JSON");
        }
        mysqlPasswordTarget = mysqlUtil.getTestState("mysqlPassword");
        mysqlPasswordPreset = deserializeJSON(mysqlUtil.getSeedState("mysqlPassword"));
        mysqlPasswordActual = deserializeJSON(mysqlPasswordTarget);
        mysqlPasswordPreset[1].password = "sha256:" & repeatString("a", 64);
        mysqlPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT mysqlUtil.setMatches("mysqlPassword", serializeJSON(mysqlPasswordPreset), serializeJSON(mysqlPasswordActual), mysqlPasswordTarget))
                throw(message="Changed MySQL password fingerprint was rejected");
        mysqlPasswordActual[1].password = mysqlPasswordPreset[1].password;
        if(mysqlUtil.setMatches("mysqlPassword", serializeJSON(mysqlPasswordPreset), serializeJSON(mysqlPasswordActual), mysqlPasswordTarget)
                OR mysqlUtil.setMatches("mysqlPassword", "[]", serializeJSON(mysqlPasswordActual), mysqlPasswordTarget))
                throw(message="Unchanged or unseeded MySQL password was accepted");
        mysqlDataDirectUtil = new cfsuite.ccssuite.utils.mysqlDataDirectDatasourceConfigUtil().init();
        for(mysqlDataDirectField in mysqlDataDirectUtil.getFields()){
                mysqlDataDirectTarget = mysqlDataDirectUtil.getTestState(mysqlDataDirectField.name);
                if(NOT mysqlDataDirectUtil.configsMatch(mysqlDataDirectField.name, mysqlDataDirectTarget, mysqlDataDirectTarget)
                        OR mysqlDataDirectUtil.configsMatch(mysqlDataDirectField.name, mysqlDataDirectTarget, "[]")
                        OR mysqlDataDirectUtil.configsMatch(mysqlDataDirectField.name,
                                mysqlDataDirectUtil.getSeedState(mysqlDataDirectField.name), mysqlDataDirectTarget))
                        throw(message="MySQL DataDirect field fixture comparison failed");
                for(mysqlDataDirectColumn in mysqlDataDirectUtil.getColumns()){
                        changed = deserializeJSON(mysqlDataDirectTarget);
                        changed[1][mysqlDataDirectColumn] = "ccssuite-invalid-field";
                        if(mysqlDataDirectUtil.configsMatch(mysqlDataDirectField.name, mysqlDataDirectTarget, serializeJSON(changed)))
                                throw(message="MySQL DataDirect comparison ignored " & mysqlDataDirectColumn);
                }
                mysqlDataDirectRow = deserializeJSON(mysqlDataDirectTarget)[1];
                expectedDisplay = mysqlDataDirectField.field EQ "password" ? "[redacted]" : mysqlDataDirectRow[mysqlDataDirectField.field];
                if(compare(mysqlDataDirectUtil.formatDisplayValue(mysqlDataDirectField.name, mysqlDataDirectTarget), expectedDisplay) NEQ 0
                        OR mysqlDataDirectUtil.formatDisplayValue(mysqlDataDirectField.name, "[]") NEQ "Not registered"
                        OR mysqlDataDirectUtil.formatDisplayValue(mysqlDataDirectField.name, "") NEQ "(unavailable)")
                        throw(message="MySQL DataDirect selected-field display failed");
                invalidMySqlDataDirectRow = duplicate(mysqlDataDirectRow);
                invalidMySqlDataDirectRow.host = "ccssuite-invalid-host";
                for(invalidMySqlDataDirectValue in ["", "{}", serializeJSON([invalidMySqlDataDirectRow]),
                        serializeJSON([mysqlDataDirectRow, mysqlDataDirectRow])]){
                        rejected = false;
                        try {
                                apiUtil.setSetting(mysqlDataDirectField.name, invalidMySqlDataDirectValue, "datasources", "DataServices");
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe MySQL DataDirect setter value was accepted");
                }
                if(NOT isJSON(mysqlDataDirectUtil.getSetting(mysqlDataDirectField.name)))
                        throw(message="MySQL DataDirect getter did not return JSON");
        }
        mysqlDataDirectPasswordTarget = mysqlDataDirectUtil.getTestState("mysqlDataDirectPassword");
        mysqlDataDirectPasswordPreset = deserializeJSON(mysqlDataDirectUtil.getSeedState("mysqlDataDirectPassword"));
        mysqlDataDirectPasswordActual = deserializeJSON(mysqlDataDirectPasswordTarget);
        mysqlDataDirectPasswordPreset[1].password = "sha256:" & repeatString("a", 64);
        mysqlDataDirectPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT mysqlDataDirectUtil.setMatches("mysqlDataDirectPassword", serializeJSON(mysqlDataDirectPasswordPreset),
                serializeJSON(mysqlDataDirectPasswordActual), mysqlDataDirectPasswordTarget))
                throw(message="Changed MySQL DataDirect password fingerprint was rejected");
        mysqlDataDirectPasswordActual[1].password = mysqlDataDirectPasswordPreset[1].password;
        if(mysqlDataDirectUtil.setMatches("mysqlDataDirectPassword", serializeJSON(mysqlDataDirectPasswordPreset),
                serializeJSON(mysqlDataDirectPasswordActual), mysqlDataDirectPasswordTarget)
                OR mysqlDataDirectUtil.setMatches("mysqlDataDirectPassword", "[]",
                        serializeJSON(mysqlDataDirectPasswordActual), mysqlDataDirectPasswordTarget))
                throw(message="Unchanged or unseeded MySQL DataDirect password was accepted");
        odbcSocketUtil = new cfsuite.ccssuite.utils.odbcSocketDatasourceConfigUtil().init();
        for(odbcSocketField in odbcSocketUtil.getFields()){
                odbcSocketTarget = odbcSocketUtil.getTestState(odbcSocketField.name);
                odbcSocketSeed = odbcSocketUtil.getSeedState(odbcSocketField.name);
                if(NOT odbcSocketUtil.configsMatch(odbcSocketField.name, odbcSocketTarget, odbcSocketTarget)
                        OR odbcSocketUtil.configsMatch(odbcSocketField.name, odbcSocketTarget, "[]")
                        OR (odbcSocketField.name NEQ "odbcSocketDatasource" OR result.odbcDsnCount GTE 2)
                                AND odbcSocketUtil.configsMatch(odbcSocketField.name, odbcSocketSeed, odbcSocketTarget))
                        throw(message="ODBC Socket field fixture comparison failed");
                for(odbcSocketColumn in odbcSocketUtil.getColumns()){
                        changed = deserializeJSON(odbcSocketTarget);
                        changed[1][odbcSocketColumn] = "ccssuite-invalid-field";
                        if(odbcSocketUtil.configsMatch(odbcSocketField.name, odbcSocketTarget, serializeJSON(changed)))
                                throw(message="ODBC Socket comparison ignored " & odbcSocketColumn);
                }
                odbcSocketRow = deserializeJSON(odbcSocketTarget)[1];
                expectedDisplay = odbcSocketField.field EQ "password" ? "[redacted]"
                        : (odbcSocketField.field EQ "UseTrustedConnection"
                                ? (odbcSocketRow.UseTrustedConnection EQ "true" ? "Enabled" : "Disabled")
                                : odbcSocketRow[odbcSocketField.field]);
                if(compare(odbcSocketUtil.formatDisplayValue(odbcSocketField.name, odbcSocketTarget), expectedDisplay) NEQ 0
                        OR odbcSocketUtil.formatDisplayValue(odbcSocketField.name, "[]") NEQ "Not registered"
                        OR odbcSocketUtil.formatDisplayValue(odbcSocketField.name, "") NEQ "(unavailable)")
                        throw(message="ODBC Socket selected-field display failed");
                invalidOdbcSocketRow = duplicate(odbcSocketRow);
                invalidOdbcSocketRow.datasource = "CCSSUITE_INVALID_ODBC_DSN";
                for(invalidOdbcSocketValue in ["", "{}", serializeJSON([invalidOdbcSocketRow]),
                        serializeJSON([odbcSocketRow, odbcSocketRow])]){
                        rejected = false;
                        try {
                                apiUtil.setSetting(odbcSocketField.name, invalidOdbcSocketValue, "datasources", "DataServices");
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe ODBC Socket setter value was accepted");
                }
                if(NOT isJSON(odbcSocketUtil.getSetting(odbcSocketField.name)))
                        throw(message="ODBC Socket getter did not return JSON");
        }
        odbcSocketMetadata = {
                DRIVER="ODBCSocket",
                username="ccssuite_fixture_user",
                password="fixture-password-original",
                description="CCSSUITE reserved ODBC Socket fixture",
                urlmap={datasource="CCSSUITE_MSACCESS_DSN", host="localhost", port=20014, UseTrustedConnection="false"}
        };
        normalizedOdbcSocket = odbcSocketUtil.normalizeDatasource("CCSSUITE_ODBCSOCKET_DSN", odbcSocketMetadata);
        if(normalizedOdbcSocket.driver NEQ "ODBCSocket"
                OR normalizedOdbcSocket.datasource NEQ "CCSSUITE_MSACCESS_DSN"
                OR normalizedOdbcSocket.host NEQ "localhost"
                OR normalizedOdbcSocket.port NEQ "20014"
                OR normalizedOdbcSocket.UseTrustedConnection NEQ "false"
                OR NOT reFindNoCase("^sha256:[a-f0-9]{64}$", normalizedOdbcSocket.password))
                throw(message="ODBC Socket urlmap metadata normalization failed");
        odbcSocketDirectMetadata = duplicate(odbcSocketMetadata);
        odbcSocketDirectMetadata.datasource = odbcSocketMetadata.urlmap.datasource;
        odbcSocketDirectMetadata.host = odbcSocketMetadata.urlmap.host;
        odbcSocketDirectMetadata.port = odbcSocketMetadata.urlmap.port;
        odbcSocketDirectMetadata.UseTrustedConnection = odbcSocketMetadata.urlmap.UseTrustedConnection;
        if(NOT odbcSocketUtil.configsMatch("odbcSocketDsn",
                serializeJSON([normalizedOdbcSocket]),
                serializeJSON([odbcSocketUtil.normalizeDatasource("CCSSUITE_ODBCSOCKET_DSN", odbcSocketDirectMetadata)])))
                throw(message="ODBC Socket direct and urlmap metadata differ");
        odbcSocketTrustedRow = deserializeJSON(odbcSocketUtil.getTestState("odbcSocketTrustedConnection"));
        odbcSocketTrustedAlias = duplicate(odbcSocketTrustedRow);
        odbcSocketTrustedAlias[1].UseTrustedConnection = "yes";
        if(NOT odbcSocketUtil.configsMatch("odbcSocketTrustedConnection", serializeJSON(odbcSocketTrustedRow),
                serializeJSON(odbcSocketTrustedAlias)))
                throw(message="ODBC Socket trusted-connection value normalization failed");
        odbcSocketPasswordTarget = odbcSocketUtil.getTestState("odbcSocketPassword");
        odbcSocketPasswordPreset = deserializeJSON(odbcSocketUtil.getSeedState("odbcSocketPassword"));
        odbcSocketPasswordActual = deserializeJSON(odbcSocketPasswordTarget);
        odbcSocketPasswordPreset[1].password = "sha256:" & repeatString("a", 64);
        odbcSocketPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT odbcSocketUtil.setMatches("odbcSocketPassword", serializeJSON(odbcSocketPasswordPreset),
                serializeJSON(odbcSocketPasswordActual), odbcSocketPasswordTarget))
                throw(message="Changed ODBC Socket password fingerprint was rejected");
        odbcSocketPasswordActual[1].password = odbcSocketPasswordPreset[1].password;
        if(odbcSocketUtil.setMatches("odbcSocketPassword", serializeJSON(odbcSocketPasswordPreset),
                serializeJSON(odbcSocketPasswordActual), odbcSocketPasswordTarget)
                OR odbcSocketUtil.setMatches("odbcSocketPassword", "[]",
                        serializeJSON(odbcSocketPasswordActual), odbcSocketPasswordTarget))
                throw(message="Unchanged or unseeded ODBC Socket password was accepted");
        oracleUtil = new cfsuite.ccssuite.utils.oracleDatasourceConfigUtil().init();
        for(oracleField in oracleUtil.getFields()){
                oracleTarget = oracleUtil.getTestState(oracleField.name);
                oracleSeed = oracleUtil.getSeedState(oracleField.name);
                if(NOT oracleUtil.configsMatch(oracleField.name, oracleTarget, oracleTarget)
                        OR oracleUtil.configsMatch(oracleField.name, oracleTarget, "[]")
                        OR oracleUtil.configsMatch(oracleField.name, oracleSeed, oracleTarget))
                        throw(message="Oracle field fixture comparison failed for " & oracleField.name);
                for(oracleColumn in oracleUtil.getColumns()){
                        changed = deserializeJSON(oracleTarget);
                        changed[1][oracleColumn] = "ccssuite-invalid-field";
                        if(oracleUtil.configsMatch(oracleField.name, oracleTarget, serializeJSON(changed)))
                                throw(message="Oracle comparison ignored " & oracleColumn);
                }
                oracleRow = deserializeJSON(oracleTarget)[1];
                expectedDisplay = oracleField.field EQ "password" ? "[redacted]" : oracleRow[oracleField.field];
                if(compare(oracleUtil.formatDisplayValue(oracleField.name, oracleTarget), expectedDisplay) NEQ 0
                        OR oracleUtil.formatDisplayValue(oracleField.name, "[]") NEQ "Not registered"
                        OR oracleUtil.formatDisplayValue(oracleField.name, "") NEQ "(unavailable)")
                        throw(message="Oracle selected-field display failed for " & oracleField.name);
                invalidOracleRow = duplicate(oracleRow);
                invalidOracleRow.sid = "CCSSUITE_INVALID_SID";
                for(invalidOracleValue in ["", "{}", serializeJSON([invalidOracleRow]), serializeJSON([oracleRow, oracleRow])]){
                        rejected = false;
                        try {
                                apiUtil.setSetting(oracleField.name, invalidOracleValue, "datasources", "DataServices");
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe Oracle setter value was accepted");
                }
                if(NOT isJSON(oracleUtil.getSetting(oracleField.name)))
                        throw(message="Oracle getter did not return JSON");
        }
        oracleMetadata = {
                DRIVER="Oracle",
                username="ccssuite_fixture_user",
                password="fixture-password-original",
                description="CCSSUITE reserved Oracle fixture",
                urlmap={sid="CCSSUITE_FIXTURE_SID", servicename="", host="localhost", port=1521}
        };
        normalizedOracle = oracleUtil.normalizeDatasource("CCSSUITE_ORACLE_DSN", oracleMetadata);
        if(normalizedOracle.sid NEQ "CCSSUITE_FIXTURE_SID" OR len(normalizedOracle.servicename)
                OR normalizedOracle.host NEQ "localhost" OR normalizedOracle.port NEQ "1521"
                OR NOT reFindNoCase("^sha256:[a-f0-9]{64}$", normalizedOracle.password))
                throw(message="Oracle urlmap metadata normalization failed");
        oracleDirectMetadata = duplicate(oracleMetadata);
        oracleDirectMetadata.sid = oracleMetadata.urlmap.sid;
        oracleDirectMetadata.servicename = oracleMetadata.urlmap.servicename;
        oracleDirectMetadata.host = oracleMetadata.urlmap.host;
        oracleDirectMetadata.port = oracleMetadata.urlmap.port;
        if(NOT oracleUtil.configsMatch("oracleDsn", serializeJSON([normalizedOracle]),
                serializeJSON([oracleUtil.normalizeDatasource("CCSSUITE_ORACLE_DSN", oracleDirectMetadata)])))
                throw(message="Oracle direct and urlmap metadata differ");
        oracleServiceMode = duplicate(oracleMetadata);
        oracleServiceMode.urlmap.sid = "";
        oracleServiceMode.urlmap.servicename = "CCSSUITE_FIXTURE_SERVICE";
        normalizedOracleServiceMode = oracleUtil.normalizeDatasource("CCSSUITE_ORACLE_DSN", oracleServiceMode);
        if(normalizedOracleServiceMode.sid NEQ "" OR normalizedOracleServiceMode.servicename NEQ "CCSSUITE_FIXTURE_SERVICE")
                throw(message="Oracle Service Name mode normalization failed");
        otherUtil = new cfsuite.ccssuite.utils.otherDatasourceConfigUtil().init();
        for(otherField in otherUtil.getFields()){
                otherTarget = otherUtil.getTestState(otherField.name);
                otherSeed = otherUtil.getSeedState(otherField.name);
                if(NOT otherUtil.configsMatch(otherField.name, otherTarget, otherTarget)
                        OR otherUtil.configsMatch(otherField.name, otherTarget, "[]")
                        OR otherUtil.configsMatch(otherField.name, otherSeed, otherTarget))
                        throw(message="Other JDBC field fixture comparison failed for " & otherField.name);
                for(otherColumn in otherUtil.getColumns()){
                        changed = deserializeJSON(otherTarget);
                        changed[1][otherColumn] = "ccssuite-invalid-field";
                        if(otherUtil.configsMatch(otherField.name, otherTarget, serializeJSON(changed)))
                                throw(message="Other JDBC comparison ignored " & otherColumn);
                }
                otherRow = deserializeJSON(otherTarget)[1];
                expectedDisplay = otherField.field EQ "password" ? "[redacted]" : otherRow[otherField.field];
                if(compare(otherUtil.formatDisplayValue(otherField.name, otherTarget), expectedDisplay) NEQ 0
                        OR otherUtil.formatDisplayValue(otherField.name, "[]") NEQ "Not registered"
                        OR otherUtil.formatDisplayValue(otherField.name, "") NEQ "(unavailable)")
                        throw(message="Other JDBC selected-field display failed for " & otherField.name);
                invalidOtherRow = duplicate(otherRow);
                invalidOtherRow[otherField.field] = "unrelated-value";
                for(invalidOtherValue in ["", "{}", serializeJSON([invalidOtherRow]), serializeJSON([otherRow, otherRow])]){
                        rejected = false;
                        try {
                                apiUtil.setSetting(otherField.name, invalidOtherValue, "datasources", "DataServices");
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe Other JDBC setter value was accepted");
                }
                if(NOT isJSON(otherUtil.getSetting(otherField.name)))
                        throw(message="Other JDBC getter did not return JSON");
        }
        otherMetadata = {
                DRIVER="CCSSUITE JDBC Fixture Driver",
                CLASS="com.ccssuite.jdbc.FixtureDriver",
                url="jdbc:ccssuite:fixture://127.0.0.1:1/ccssuite",
                username="ccssuite_fixture_user",
                password="fixture-password-original",
                description="CCSSUITE reserved other JDBC fixture"
        };
        normalizedOther = otherUtil.normalizeDatasource("CCSSUITE_OTHER_DSN", otherMetadata);
        if(normalizedOther.driver NEQ "CCSSUITE JDBC Fixture Driver"
                OR normalizedOther.class NEQ "com.ccssuite.jdbc.FixtureDriver"
                OR normalizedOther.url NEQ "jdbc:ccssuite:fixture://127.0.0.1:1/ccssuite"
                OR NOT reFindNoCase("^sha256:[a-f0-9]{64}$", normalizedOther.password))
                throw(message="Other JDBC metadata normalization failed");
        otherPasswordTarget = otherUtil.getTestState("otherPassword");
        otherPasswordPreset = deserializeJSON(otherUtil.getSeedState("otherPassword"));
        otherPasswordActual = deserializeJSON(otherPasswordTarget);
        otherPasswordPreset[1].password = "sha256:" & repeatString("a", 64);
        otherPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT otherUtil.setMatches("otherPassword", serializeJSON(otherPasswordPreset),
                serializeJSON(otherPasswordActual), otherPasswordTarget))
                throw(message="Changed Other JDBC password fingerprint was rejected");
        otherPasswordActual[1].password = otherPasswordPreset[1].password;
        if(otherUtil.setMatches("otherPassword", serializeJSON(otherPasswordPreset),
                serializeJSON(otherPasswordActual), otherPasswordTarget)
                OR otherUtil.setMatches("otherPassword", "[]", serializeJSON(otherPasswordActual), otherPasswordTarget))
                throw(message="Unchanged or unseeded Other JDBC password was accepted");
        oraclePasswordTarget = oracleUtil.getTestState("oraclePassword");
        oraclePasswordPreset = deserializeJSON(oracleUtil.getSeedState("oraclePassword"));
        oraclePasswordActual = deserializeJSON(oraclePasswordTarget);
        oraclePasswordPreset[1].password = "sha256:" & repeatString("a", 64);
        oraclePasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT oracleUtil.setMatches("oraclePassword", serializeJSON(oraclePasswordPreset),
                serializeJSON(oraclePasswordActual), oraclePasswordTarget))
                throw(message="Changed Oracle password fingerprint was rejected");
        oraclePasswordActual[1].password = oraclePasswordPreset[1].password;
        if(oracleUtil.setMatches("oraclePassword", serializeJSON(oraclePasswordPreset),
                serializeJSON(oraclePasswordActual), oraclePasswordTarget)
                OR oracleUtil.setMatches("oraclePassword", "[]", serializeJSON(oraclePasswordActual), oraclePasswordTarget))
                throw(message="Unchanged or unseeded Oracle password was accepted");
        postgresqlUtil = new cfsuite.ccssuite.utils.postgresqlDatasourceConfigUtil().init();
        for(postgresqlField in postgresqlUtil.getFields()){
                postgresqlTarget = postgresqlUtil.getTestState(postgresqlField.name);
                postgresqlSeed = postgresqlUtil.getSeedState(postgresqlField.name);
                if(NOT postgresqlUtil.configsMatch(postgresqlField.name, postgresqlTarget, postgresqlTarget)
                        OR postgresqlUtil.configsMatch(postgresqlField.name, postgresqlTarget, "[]")
                        OR postgresqlUtil.configsMatch(postgresqlField.name, postgresqlSeed, postgresqlTarget))
                        throw(message="PostgreSQL field fixture comparison failed for " & postgresqlField.name);
                for(postgresqlColumn in postgresqlUtil.getColumns()){
                        changed = deserializeJSON(postgresqlTarget);
                        changed[1][postgresqlColumn] = "ccssuite-invalid-field";
                        if(postgresqlUtil.configsMatch(postgresqlField.name, postgresqlTarget, serializeJSON(changed)))
                                throw(message="PostgreSQL comparison ignored " & postgresqlColumn);
                }
                postgresqlRow = deserializeJSON(postgresqlTarget)[1];
                expectedDisplay = postgresqlField.field EQ "password" ? "[redacted]" : postgresqlRow[postgresqlField.field];
                if(compare(postgresqlUtil.formatDisplayValue(postgresqlField.name, postgresqlTarget), expectedDisplay) NEQ 0
                        OR postgresqlUtil.formatDisplayValue(postgresqlField.name, "[]") NEQ "Not registered"
                        OR postgresqlUtil.formatDisplayValue(postgresqlField.name, "") NEQ "(unavailable)")
                        throw(message="PostgreSQL selected-field display failed for " & postgresqlField.name);
                invalidPostgresqlRow = duplicate(postgresqlRow);
                invalidPostgresqlRow.host = "ccssuite-invalid-host";
                for(invalidPostgresqlValue in ["", "{}", serializeJSON([invalidPostgresqlRow]), serializeJSON([postgresqlRow, postgresqlRow])]){
                        rejected = false;
                        try {
                                apiUtil.setSetting(postgresqlField.name, invalidPostgresqlValue, "datasources", "DataServices");
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe PostgreSQL setter value was accepted");
                }
                if(NOT isJSON(postgresqlUtil.getSetting(postgresqlField.name)))
                        throw(message="PostgreSQL getter did not return JSON");
        }
        postgresqlPasswordTarget = postgresqlUtil.getTestState("postgresqlPassword");
        postgresqlPasswordPreset = deserializeJSON(postgresqlUtil.getSeedState("postgresqlPassword"));
        postgresqlPasswordActual = deserializeJSON(postgresqlPasswordTarget);
        postgresqlPasswordPreset[1].password = "sha256:" & repeatString("a", 64);
        postgresqlPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT postgresqlUtil.setMatches("postgresqlPassword", serializeJSON(postgresqlPasswordPreset),
                serializeJSON(postgresqlPasswordActual), postgresqlPasswordTarget))
                throw(message="Changed PostgreSQL password fingerprint was rejected");
        postgresqlPasswordActual[1].password = postgresqlPasswordPreset[1].password;
        if(postgresqlUtil.setMatches("postgresqlPassword", serializeJSON(postgresqlPasswordPreset),
                serializeJSON(postgresqlPasswordActual), postgresqlPasswordTarget)
                OR postgresqlUtil.setMatches("postgresqlPassword", "[]",
                        serializeJSON(postgresqlPasswordActual), postgresqlPasswordTarget))
                throw(message="Unchanged or unseeded PostgreSQL password was accepted");
        embeddedUtil = new cfsuite.ccssuite.utils.derbyEmbeddedDatasourceConfigUtil().init();
        for(embeddedField in embeddedUtil.getFields()){
                embeddedTarget = embeddedUtil.getTestState(embeddedField.name);
                if(NOT embeddedUtil.configsMatch(embeddedField.name, embeddedTarget, embeddedTarget)
                        OR embeddedUtil.configsMatch(embeddedField.name, embeddedTarget, "[]")
                        OR embeddedUtil.configsMatch(embeddedField.name, embeddedTarget, ""))
                        throw(message="Embedded fixture comparison is incorrect");
                for(embeddedColumn in embeddedUtil.getColumns()){
                        changed = deserializeJSON(embeddedTarget);
                        changed[1][embeddedColumn] = "ccssuite-invalid-field";
                        if(embeddedUtil.configsMatch(embeddedField.name, embeddedTarget, serializeJSON(changed)))
                                throw(message="Embedded comparison ignored " & embeddedColumn);
                }
                embeddedRow = deserializeJSON(embeddedTarget)[1];
                expectedDisplay = embeddedField.field EQ "isnewdb" ? "Enabled" : embeddedRow[embeddedField.field];
                if(compare(embeddedUtil.formatDisplayValue(embeddedField.name, embeddedTarget), expectedDisplay) NEQ 0
                        OR embeddedUtil.formatDisplayValue(embeddedField.name, "[]") NEQ "Not registered"
                        OR embeddedUtil.formatDisplayValue(embeddedField.name, "") NEQ "(unavailable)")
                        throw(message="Embedded selected-field display is incorrect");
                peerFolder = duplicate(embeddedRow);
                peerFolder.database = "C:\ccssuite-readonly-peer" & embeddedUtil.normalizeDatabasePath(embeddedRow.database);
                if(NOT embeddedUtil.configsMatch(embeddedField.name, embeddedTarget, serializeJSON([peerFolder])))
                        throw(message="Embedded instance-root normalization failed");
                unrelatedFolder = duplicate(embeddedRow);
                unrelatedFolder.database = "C:\ccssuite-readonly-invalid\database";
                for(invalidEmbeddedValue in ["", "{}", serializeJSON([unrelatedFolder]), serializeJSON([embeddedRow, embeddedRow])]){
                        rejected = false;
                        try {
                                apiUtil.setSetting(embeddedField.name, invalidEmbeddedValue, "datasources", "DataServices");
                        }
                        catch(CCSTest.ConfigError expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe Embedded setter payload was accepted");
                }
                embeddedSeed = embeddedUtil.getSeedState(embeddedField.name);
                if(embeddedUtil.configsMatch(embeddedField.name, embeddedSeed, embeddedTarget))
                        throw(message="Embedded target did not change its selected field from the seed");
                if(NOT isJSON(embeddedUtil.getSetting(embeddedField.name)))
                        throw(message="Embedded getter did not return JSON");
        }
        for(field in derbyUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in embeddedUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in db2Util.getFields())
                arrayAppend(result.cases, field.name);
        for(field in mssqlUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in mysqlUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in mysqlDataDirectUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in odbcSocketUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in oracleUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in otherUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in postgresqlUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in jndiUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in accessUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(settingName in result.cases){
                target = configUtil.getTestState(settingName);
                if(configUtil.isPreparedDatasourceSetting(settingName)){
                        if(configUtil.isOtherSetting(settingName))
                                fieldName = otherUtil.getField(settingName).field;
                        else if(configUtil.isPostgresqlSetting(settingName))
                                fieldName = postgresqlUtil.getField(settingName).field;
                        else if(configUtil.isOracleSetting(settingName))
                                fieldName = oracleUtil.getField(settingName).field;
                        else if(configUtil.isMsAccessSetting(settingName))
                                fieldName = accessUtil.getField(settingName).field;
                        else if(configUtil.isJndiSetting(settingName))
                                fieldName = jndiUtil.getField(settingName).field;
                        else if(configUtil.isMysqlSetting(settingName))
                                fieldName = mysqlUtil.getField(settingName).field;
                        else if(configUtil.isOdbcSocketSetting(settingName))
                                fieldName = odbcSocketUtil.getField(settingName).field;
                        else if(configUtil.isMysqlDataDirectSetting(settingName))
                                fieldName = mysqlDataDirectUtil.getField(settingName).field;
                        else if(configUtil.isMssqlSetting(settingName))
                                fieldName = mssqlUtil.getField(settingName).field;
                        else if(configUtil.isDb2Setting(settingName))
                                fieldName = db2Util.getField(settingName).field;
                        else if(configUtil.isDerbyEmbeddedSetting(settingName))
                                fieldName = embeddedUtil.getField(settingName).field;
                        else
                                fieldName = derbyUtil.getField(settingName).field;
                        targetRow = deserializeJSON(target)[1];
                        expectedDisplay = fieldName EQ "password" ? "[redacted]" : (fieldName EQ "isnewdb" ? "Enabled"
                                : (fieldName EQ "UseTrustedConnection"
                                        ? (listFindNoCase("true,yes,1", "" & targetRow[fieldName]) ? "Enabled" : "Disabled")
                                        : targetRow[fieldName]));
                        if(compare(displayUtil.formatDisplayValue(settingName, target), expectedDisplay) NEQ 0
                                OR displayUtil.formatDisplayValue(settingName, "[]") NEQ "Not registered"
                                OR displayUtil.formatDisplayValue(settingName, "") NEQ "(unavailable)")
                                throw(message="Selected field display is incorrect for " & settingName & ": expected "
                                        & expectedDisplay & ", got " & displayUtil.formatDisplayValue(settingName, target));
                        malformedRow = duplicate(targetRow);
                        structDelete(malformedRow, fieldName);
                        if(displayUtil.formatDisplayValue(settingName, serializeJSON([malformedRow])) NEQ "(unavailable)")
                                throw(message="Missing selected Derby field was displayed as a valid value");
                }
                if(NOT configUtil.configsMatch(settingName, target, target) OR configUtil.configsMatch(settingName, target, "[]")
                        OR configUtil.configsMatch(settingName, target, "") OR configUtil.configsMatch(settingName, "[]", "{}"))
                        throw(message="Datasource snapshot comparison failed for " & settingName);
                for(column in configUtil.getSnapshotColumns(settingName)){
                        changed = deserializeJSON(target);
                        changed[1][column] = "ccssuite-invalid-field";
                        if(configUtil.configsMatch(settingName, target, serializeJSON(changed)))
                                throw(message="Datasource comparison ignored " & column);
                }
                configUtil.assertEmptyFixturePresets(settingName, {validationNode="[]"});
                for(invalidPreset in ["", "{}", target]){
                        rejected = false;
                        try {
                                configUtil.assertEmptyFixturePresets(settingName, {validationNode=invalidPreset});
                        }
                        catch(CCSTest.FixtureUnavailable expectedFailure){
                                rejected = true;
                        }
                        if(NOT rejected)
                                throw(message="Unsafe datasource preset was accepted");
                }
                if(NOT isJSON(configUtil.getSetting(settingName)))
                        throw(message="Datasource getter did not return JSON");
                if(NOT isJSON(apiUtil.getSetting(settingName, "datasources", "DataServices")))
                        throw(message="Datasource shared getter routing failed");
                if(NOT listFindNoCase("derbyClientPassword,db2Password,mssqlPassword,mysqlPassword,mysqlDataDirectPassword,odbcSocketPassword,oraclePassword,otherPassword,postgresqlPassword,jndiPassword,msAccessPassword", settingName) AND NOT comparisonUtil.setMatches(settingName, "[]", target, target, "datasources"))
                        throw(message="Datasource shared comparison routing failed");
        }
        jndiPasswordTarget = jndiUtil.getTestState("jndiPassword");
        jndiPasswordPreset = deserializeJSON(jndiUtil.getSeedState("jndiPassword"));
        jndiPasswordActual = deserializeJSON(jndiPasswordTarget);
        jndiPasswordPreset[1].password = "sha256:" & repeatString("a", 64);
        jndiPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT comparisonUtil.setMatches("jndiPassword", serializeJSON(jndiPasswordPreset), serializeJSON(jndiPasswordActual), jndiPasswordTarget, "datasources"))
                throw(message="Changed JNDI password fingerprint was rejected");
        jndiPasswordActual[1].password = jndiPasswordPreset[1].password;
        if(comparisonUtil.setMatches("jndiPassword", serializeJSON(jndiPasswordPreset), serializeJSON(jndiPasswordActual), jndiPasswordTarget, "datasources")
                OR comparisonUtil.setMatches("jndiPassword", "[]", serializeJSON(jndiPasswordActual), jndiPasswordTarget, "datasources"))
                throw(message="Unchanged or unseeded JNDI password was accepted");
        db2PasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT comparisonUtil.setMatches("db2Password", serializeJSON(db2PasswordPreset), serializeJSON(db2PasswordActual), db2PasswordTarget, "datasources"))
                throw(message="DB2 shared password-change comparison routing failed");
        db2PasswordActual[1].password = db2PasswordPreset[1].password;
        if(comparisonUtil.setMatches("db2Password", serializeJSON(db2PasswordPreset), serializeJSON(db2PasswordActual), db2PasswordTarget, "datasources"))
                throw(message="DB2 shared comparison accepted an unchanged password");
        mssqlPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT comparisonUtil.setMatches("mssqlPassword", serializeJSON(mssqlPasswordPreset), serializeJSON(mssqlPasswordActual), mssqlPasswordTarget, "datasources"))
                throw(message="SQL Server shared password-change comparison routing failed");
        mssqlPasswordActual[1].password = mssqlPasswordPreset[1].password;
        if(comparisonUtil.setMatches("mssqlPassword", serializeJSON(mssqlPasswordPreset), serializeJSON(mssqlPasswordActual), mssqlPasswordTarget, "datasources"))
                throw(message="SQL Server shared comparison accepted an unchanged password");
        mysqlPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT comparisonUtil.setMatches("mysqlPassword", serializeJSON(mysqlPasswordPreset), serializeJSON(mysqlPasswordActual), mysqlPasswordTarget, "datasources"))
                throw(message="MySQL shared password-change comparison routing failed");
        mysqlPasswordActual[1].password = mysqlPasswordPreset[1].password;
        if(comparisonUtil.setMatches("mysqlPassword", serializeJSON(mysqlPasswordPreset), serializeJSON(mysqlPasswordActual), mysqlPasswordTarget, "datasources"))
                throw(message="MySQL shared comparison accepted an unchanged password");
        mysqlDataDirectPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT comparisonUtil.setMatches("mysqlDataDirectPassword", serializeJSON(mysqlDataDirectPasswordPreset),
                serializeJSON(mysqlDataDirectPasswordActual), mysqlDataDirectPasswordTarget, "datasources"))
                throw(message="MySQL DataDirect shared password-change comparison routing failed");
        mysqlDataDirectPasswordActual[1].password = mysqlDataDirectPasswordPreset[1].password;
        if(comparisonUtil.setMatches("mysqlDataDirectPassword", serializeJSON(mysqlDataDirectPasswordPreset),
                serializeJSON(mysqlDataDirectPasswordActual), mysqlDataDirectPasswordTarget, "datasources"))
                throw(message="MySQL DataDirect shared comparison accepted an unchanged password");
        odbcSocketPasswordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT comparisonUtil.setMatches("odbcSocketPassword", serializeJSON(odbcSocketPasswordPreset),
                serializeJSON(odbcSocketPasswordActual), odbcSocketPasswordTarget, "datasources"))
                throw(message="ODBC Socket shared password-change comparison routing failed");
        odbcSocketPasswordActual[1].password = odbcSocketPasswordPreset[1].password;
        if(comparisonUtil.setMatches("odbcSocketPassword", serializeJSON(odbcSocketPasswordPreset),
                serializeJSON(odbcSocketPasswordActual), odbcSocketPasswordTarget, "datasources"))
                throw(message="ODBC Socket shared comparison accepted an unchanged password");
        oraclePasswordActual[1].password = "sha256:" & repeatString("c", 64);
        if(NOT comparisonUtil.setMatches("oraclePassword", serializeJSON(oraclePasswordPreset),
                serializeJSON(oraclePasswordActual), oraclePasswordTarget, "datasources"))
                throw(message="Oracle shared password-change comparison routing failed");
        oraclePasswordActual[1].password = oraclePasswordPreset[1].password;
        if(comparisonUtil.setMatches("oraclePassword", serializeJSON(oraclePasswordPreset),
                serializeJSON(oraclePasswordActual), oraclePasswordTarget, "datasources"))
                throw(message="Oracle shared comparison accepted an unchanged password");
        otherPasswordActual[1].password = "sha256:" & repeatString("c", 64);
        if(NOT comparisonUtil.setMatches("otherPassword", serializeJSON(otherPasswordPreset),
                serializeJSON(otherPasswordActual), otherPasswordTarget, "datasources"))
                throw(message="Other JDBC shared password-change comparison routing failed");
        otherPasswordActual[1].password = otherPasswordPreset[1].password;
        if(comparisonUtil.setMatches("otherPassword", serializeJSON(otherPasswordPreset),
                serializeJSON(otherPasswordActual), otherPasswordTarget, "datasources"))
                throw(message="Other JDBC shared comparison accepted an unchanged password");
        postgresqlPasswordActual[1].password = "sha256:" & repeatString("c", 64);
        if(NOT comparisonUtil.setMatches("postgresqlPassword", serializeJSON(postgresqlPasswordPreset),
                serializeJSON(postgresqlPasswordActual), postgresqlPasswordTarget, "datasources"))
                throw(message="PostgreSQL shared password-change comparison routing failed");
        postgresqlPasswordActual[1].password = postgresqlPasswordPreset[1].password;
        if(comparisonUtil.setMatches("postgresqlPassword", serializeJSON(postgresqlPasswordPreset),
                serializeJSON(postgresqlPasswordActual), postgresqlPasswordTarget, "datasources"))
                throw(message="PostgreSQL shared comparison accepted an unchanged password");
        passwordTarget = configUtil.getTestState("derbyClientPassword");
        passwordPreset = deserializeJSON(configUtil.getSeedState("derbyClientPassword"));
        passwordActual = deserializeJSON(passwordTarget);
        passwordPreset[1].password = "sha256:" & repeatString("a", 64);
        passwordActual[1].password = "sha256:" & repeatString("b", 64);
        if(NOT comparisonUtil.setMatches("derbyClientPassword", serializeJSON(passwordPreset), serializeJSON(passwordActual), passwordTarget, "datasources"))
                throw(message="Changed Derby password fingerprint was rejected");
        passwordActual[1].password = passwordPreset[1].password;
        if(comparisonUtil.setMatches("derbyClientPassword", serializeJSON(passwordPreset), serializeJSON(passwordActual), passwordTarget, "datasources")
                OR comparisonUtil.setMatches("derbyClientPassword", "[]", serializeJSON(passwordActual), passwordTarget, "datasources"))
                throw(message="Unchanged or unseeded Derby password was accepted");
        if(displayUtil.formatDisplayValue("derbyClientPassword", serializeJSON(passwordActual)) NEQ "[redacted]"
                OR displayUtil.formatDisplayValue("derbyClientDsn", serializeJSON([passwordPreset[1], passwordActual[1]]))
                        NEQ "Multiple registrations: " & passwordPreset[1].dsn & ", " & passwordActual[1].dsn
                OR displayUtil.formatDisplayValue("unrelatedSetting", "unchanged") NEQ "unchanged")
                throw(message="Password, multiple-registration, or unrelated-setting display regressed");
        reportingRows = [];
        originalNodeValues = {};
        for(validationPort in [8500, 8501, 8502, 8503]){
                nodeKey = "localhost:" & validationPort;
                originalNodeValues[nodeKey] = "[]";
                arrayAppend(reportingRows, {nodeKey=nodeKey, nodeLabel=nodeKey, cluster="validation", environment="validation",
                        existingValue=validationPort EQ 8500 ? "CCSSUITE_DERBYCLIENT_DSN" : "Not registered",
                        updatedValue=validationPort EQ 8500 ? "CCSSUITE_DERBYCLIENT_DSN_RENAMED" : "Not registered", passed=false});
        }
        savecontent variable="reportingHtml" {
                displayUtil.writeSyncVerificationTable(reportingRows, "derbyClientDsn", "Prepared baseline", "Updated Value", true, originalNodeValues);
        }
        if(NOT find("<th>Original state</th>", reportingHtml) OR NOT find("<th>Prepared baseline</th>", reportingHtml)
                OR find("<th>Existing Value</th>", reportingHtml)
                OR arrayLen(reMatch('<td class="value-cell">Not registered</td><td class="value-cell">', reportingHtml)) NEQ 4)
                throw(message="Original pre-test state is not distinct from the prepared baseline on all nodes");
        savecontent variable="defaultReportingHtml" {
                displayUtil.writeSyncVerificationTable(reportingRows, "derbyClientDsn");
        }
        if(find("<th>Original state</th>", defaultReportingHtml) OR NOT find("<th>Existing Value</th>", defaultReportingHtml))
                throw(message="Default reporting for tests without a prepared baseline changed");
        reportingRows[1].existingValue = "Disabled";
        reportingRows[1].updatedValue = "Enabled";
        savecontent variable="embeddedReportingHtml" {
                displayUtil.writeSyncVerificationTable(reportingRows, "derbyEmbeddedCreateDatabase", "Prepared baseline", "Updated Value", true, originalNodeValues);
        }
        if(NOT find("<th>Original state</th>", embeddedReportingHtml) OR NOT find("<th>Prepared baseline</th>", embeddedReportingHtml)
                OR NOT find('<td class="value-cell">Disabled</td>', embeddedReportingHtml)
                OR NOT find('<td class="value-cell">Enabled</td>', embeddedReportingHtml))
                throw(message="Embedded original-state and checkbox-baseline reporting failed");
        reportingRows[1].existingValue = "CCSSUITE_DB2_DSN";
        reportingRows[1].updatedValue = "CCSSUITE_DB2_DSN_RENAMED";
        savecontent variable="db2ReportingHtml" {
                displayUtil.writeSyncVerificationTable(reportingRows, "db2Dsn", "Prepared baseline", "Updated Value", true, originalNodeValues);
        }
        if(NOT find("<th>Original state</th>", db2ReportingHtml) OR NOT find("<th>Prepared baseline</th>", db2ReportingHtml)
                OR arrayLen(reMatch('<td class="value-cell">Not registered</td><td class="value-cell">', db2ReportingHtml)) NEQ 4)
                throw(message="DB2 original-state and prepared-baseline reporting failed");
        reportingRows[1].existingValue = "CCSSUITE_JNDI_DSN";
        reportingRows[1].updatedValue = "CCSSUITE_JNDI_DSN_RENAMED";
        savecontent variable="jndiReportingHtml" {
                displayUtil.writeSyncVerificationTable(reportingRows, "jndiDsn", "Prepared baseline", "Updated Value", true, originalNodeValues);
        }
        if(NOT find("<th>Original state</th>", jndiReportingHtml) OR NOT find("<th>Prepared baseline</th>", jndiReportingHtml)
                OR arrayLen(reMatch('<td class="value-cell">Not registered</td><td class="value-cell">', jndiReportingHtml)) NEQ 4)
                throw(message="JNDI original-state and prepared-baseline reporting failed");
        rows = configUtil.getDatasourceRows();
        if(NOT configUtil.listColumnsMatch(rows) OR configUtil.listColumnsMatch([{dsn="invalid"}]))
                throw(message="Datasource list column validation failed");
        result.passed = true;
        writeOutput(serializeJSON(result));
}
catch(any failure){
        cfheader(statusCode=500);
        writeOutput(serializeJSON({passed=false, message=failure.message, detail=failure.detail}));
}
finally {
        adminUtil.logout(admin);
}
</cfscript>