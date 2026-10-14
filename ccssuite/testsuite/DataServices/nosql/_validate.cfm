<cfscript>
cfcontent(type="application/json", reset=true);
adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
admin = adminUtil.createAdministrator();
stage = "authentication";
try {
        if(NOT structKeyExists(application, "constants"))
                application.constants = new cfsuite.ccssuite.constants().init();
        adminUtil.login(application.constants.CF_CONFIG);
        stage = "component loading";
        nosqlApi = createObject("component", "CFIDE.adminapi.nosql_datasource");
        stage = "metadata";
        result = {configurationWrites=false, methods=[], propertyKeys=[], datasourceCount=0};
        for(method in getMetadata(nosqlApi).functions){
                if(listFindNoCase("getDatasources,getDatasource,setMongoDataSource,deleteMongoDatasource,isNoSQLModuleInstalled", method.name)){
                        parameters = [];
                        for(parameter in (structKeyExists(method, "parameters") ? method.parameters : []))
                                arrayAppend(parameters, {name=parameter.name,
                                        type=structKeyExists(parameter, "type") ? parameter.type : "any",
                                        required=structKeyExists(parameter, "required") AND parameter.required});
                        arrayAppend(result.methods, {name=method.name, parameters=parameters});
                }
        }
        stage = "list read";
        datasources = nosqlApi.getDatasources();
        result.datasourceCount = structCount(datasources);
        for(datasourceName in datasources){
                if(isStruct(datasources[datasourceName])){
                        for(propertyKey in datasources[datasourceName]){
                                if(NOT arrayFindNoCase(result.propertyKeys, propertyKey))
                                        arrayAppend(result.propertyKeys, propertyKey);
                        }
                }
        }
        stage = "API utility compilation";
        apiUtil = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init();
        stage = "test utility compilation";
        testUtil = new cfsuite.ccssuite.utils.nosqlDatasourceTestUtil().init();
        stage = "comparison utility compilation";
        configUtil = new cfsuite.ccssuite.utils.nosqlConfigUtil().init();
        stage = "dispatch compilation";
        dispatchUtil = new cfsuite.ccssuite.utils.ccsApiUtil().init();
        stage = "driver compilation";
        driver = new cfsuite.ccssuite.testDriver();
        stage = "synthetic checks";
        result.fieldCount = structCount(apiUtil.getFieldMap());
        expected = {entries={CCSSuiteMongoA=testUtil.getSeedConfig()}};
        actual = duplicate(expected);
        actual.entries.CCSSuiteMongoA.port = "1";
        actual.entries.CCSSuiteMongoA.ssl = "NO";
        result.synthetic = {numericBooleanNormalization=configUtil.statesMatch(serializeJSON(expected), serializeJSON(actual))};
        structDelete(actual.entries.CCSSuiteMongoA, "host");
        result.synthetic.missingFieldRejected = NOT configUtil.statesMatch(serializeJSON(expected), serializeJSON(actual));
        actual = duplicate(expected);
        actual.entries.CCSSuiteMongoA.host = "127.0.0.2";
        result.synthetic.staleFieldRejected = NOT configUtil.statesMatch(serializeJSON(expected), serializeJSON(actual));
        result.synthetic.missingEntryRejected = NOT configUtil.statesMatch(serializeJSON(expected), '{"entries":{}}');
        actual = duplicate(expected);
        actual.entries.CCSSuiteMongoA.password = "unverified";
        result.synthetic.unverifiedPasswordRejected = NOT configUtil.statesMatch(serializeJSON(expected), serializeJSON(actual));
        result.synthetic.reservedFixtureAccepted = apiUtil.isOwnedFixture("CCSSuiteMongoA", testUtil.getSeedConfig());
        result.synthetic.foreignNameRejected = NOT apiUtil.isOwnedFixture("production", testUtil.getSeedConfig());
        actualConfig = testUtil.getSeedConfig();
        actualConfig.host = "example.invalid";
        result.synthetic.nonLoopbackRejected = NOT apiUtil.isOwnedFixture("CCSSuiteMongoA", actualConfig);
        actualConfig = testUtil.getSeedConfig();
        actualConfig.username = "not-a-fixture";
        result.synthetic.foreignMarkerRejected = NOT apiUtil.isOwnedFixture("CCSSuiteMongoA", actualConfig);
        result.supportedFieldCount = 0;
        result.unsupportedFields = [];
        result.synthetic.allSelectorsDistinct = true;
        for(field in apiUtil.getFieldMap()){
                setterSupportsField = false;
                for(method in result.methods){
                        if(compareNoCase(method.name, "setMongoDataSource") EQ 0){
                                for(parameter in method.parameters){
                                        if(compareNoCase(parameter.name, apiUtil.getFieldMap()[field]) EQ 0)
                                                setterSupportsField = true;
                                }
                        }
                }
                if(NOT setterSupportsField){
                        arrayAppend(result.unsupportedFields, field);
                        continue;
                }
                result.supportedFieldCount++;
                target = testUtil.getTargetState(field);
                if(field EQ "dsnName")
                        result.synthetic.allSelectorsDistinct = result.synthetic.allSelectorsDistinct AND structKeyExists(target.entries, "CCSSuiteMongoB");
                else if(field NEQ "driverName")
                        result.synthetic.allSelectorsDistinct = result.synthetic.allSelectorsDistinct
                                AND compare(serializeJSON(target.entries.CCSSuiteMongoA[apiUtil.getFieldMap()[field]]),
                                        serializeJSON(testUtil.getSeedConfig()[apiUtil.getFieldMap()[field]])) NEQ 0;
        }
        keys = application.testConstants.TEST_FRAME;
        expectedFrame = {};
        expectedFrame[keys.API_AREA] = "nosql";
        expectedFrame[keys.CFSETTING] = "mongo_host";
        expectedFrame[keys.PRIME_SET] = {};
        expectedFrame[keys.NONPRIME_SET] = {};
        for(nodeKey in ["synthetic-local", "synthetic-peer"]){
                expectedFrame[keys.PRIME_SET][nodeKey] = {};
                expectedFrame[keys.PRIME_SET][nodeKey][keys.PRESET_VALUE] = '{"entries":{}}';
                expectedFrame[keys.PRIME_SET][nodeKey][keys.POSTSET_VALUE] = serializeJSON(expected);
        }
        actualFrame = duplicate(expectedFrame);
        result.synthetic.driverMatchingPeersAccepted = driver.syncedFramesMatch(actualFrame, expectedFrame);
        actualFrame[keys.PRIME_SET]["synthetic-peer"][keys.POSTSET_VALUE] = '{"entries":{}}';
        result.synthetic.driverStalePeerRejected = NOT driver.syncedFramesMatch(actualFrame, expectedFrame);
        actualFrame = duplicate(expectedFrame);
        actual = duplicate(expected);
        actual.entries.CCSSuiteMongoA.port = "1";
        actualFrame[keys.PRIME_SET]["synthetic-peer"][keys.POSTSET_VALUE] = serializeJSON(actual);
        result.synthetic.driverNumericPeerNormalized = driver.syncedFramesMatch(actualFrame, expectedFrame);
        result.passwordVerificationSupported = false;
        try {
                apiUtil.requireSupported("mongo_authPassword");
                result.passwordVerificationSupported = true;
        }
        catch(any capabilityFailure){}
        writeOutput(serializeJSON(result));
}
catch(any failure){
        cfheader(statusCode=500);
        writeOutput(serializeJSON({configurationWrites=false, stage=stage,
                error="NoSQL metadata validation failed; configuration and exception details withheld."}));
}
finally {
        adminUtil.logout(admin);
}
</cfscript>