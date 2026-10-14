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
        result = {configurationWrites=false, methods=[], availableMethods=[], credentialMethods=[], derbyMetadata=[], embeddedMetadata=[], datasourceCount=structCount(datasources), datasourceKeys=[], driverMetadata={}};
        for(method in getMetadata(admin).functions){
                if(reFindNoCase("encrypt|decrypt", method.name))
                        arrayAppend(result.credentialMethods, {name=method.name, parameters=method.parameters});
        }
        for(method in getMetadata(datasourceApi).functions){
                arrayAppend(result.availableMethods, method.name);
                if(listFindNoCase("setMSAccess,setJNDI,setDB2,setDerbyEmbedded,setDerbyClient,setMySQL,setMySQL5,setMySQL_DD,setMSSQL,setSQLServer,setPostgreSQL,deleteDatasource,getDatasources,getDrivers,verifyDatasource,verifyDSN", method.name))
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
        for(field in jndiUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(field in accessUtil.getFields())
                arrayAppend(result.cases, field.name);
        for(settingName in result.cases){
                target = configUtil.getTestState(settingName);
                if(configUtil.isPreparedDatasourceSetting(settingName)){
                        fieldName = configUtil.isMsAccessSetting(settingName) ? accessUtil.getField(settingName).field
                                : (configUtil.isJndiSetting(settingName) ? jndiUtil.getField(settingName).field
                                : (configUtil.isDb2Setting(settingName) ? db2Util.getField(settingName).field
                                : (configUtil.isDerbyEmbeddedSetting(settingName) ? embeddedUtil.getField(settingName).field : derbyUtil.getField(settingName).field)));
                        targetRow = deserializeJSON(target)[1];
                        expectedDisplay = fieldName EQ "password" ? "[redacted]" : (fieldName EQ "isnewdb" ? "Enabled"
                                : (fieldName EQ "UseTrustedConnection" ? "Disabled" : targetRow[fieldName]));
                        if(compare(displayUtil.formatDisplayValue(settingName, target), expectedDisplay) NEQ 0
                                OR displayUtil.formatDisplayValue(settingName, "[]") NEQ "Not registered"
                                OR displayUtil.formatDisplayValue(settingName, "") NEQ "(unavailable)")
                                throw(message="Selected Derby field or absent-node display is incorrect");
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
                if(NOT listFindNoCase("derbyClientPassword,db2Password,jndiPassword,msAccessPassword", settingName) AND NOT comparisonUtil.setMatches(settingName, "[]", target, target, "datasources"))
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