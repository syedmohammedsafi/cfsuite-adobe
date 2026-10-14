component output="false" {
        public function init(){ return this; }

        public struct function getSeedConfig(){
                return {type="mongodb", host="127.0.0.1", port=1, replicaSet="", ssl=false, dnsSeedList=false,
                        authMechanism="usernamepassword", username="CCSSuiteFixture", password="empty",
                        authSource="CCSSuiteFixture", gssapiServiceName="mongodb", readConcern="local", readPreference="primary",
                        w="1", wtimeout=1000, j=false, connectTimeout=1000, maxPoolSize=10, minPoolSize=0,
                        maxConnectionLifeTime=10000, maxConnectionIdleTime=10000, maxWaitQueueTimeout=1000,
                        maxWaitQueueSize=10, heartbeatFrequency=10000, minHeartbeatFrequency=500};
        }

        public struct function getTargetState(required string settingName){
                var apiUtil = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init();
                apiUtil.requireSetting(arguments.settingName);
                var name = apiUtil.getReservedNames()[1];
                var config = getSeedConfig();
                var replacements = {mongo_host="127.0.0.2", mongo_port=2, mongo_replicaSetName="CCSSuiteReplica",
                        mongo_enableSSL=true, mongo_DnsSeedlist=true, mongo_authMechanism="SCRAM-SHA-256",
                        mongo_authUsername="CCSSuiteFixtureTarget", mongo_authPassword="fixture-target",
                        mongo_authSource="CCSSuiteFixtureTarget", mongo_gssapiServiceName="CCSSuiteService",
                        mongo_readConcern="majority", mongo_readPref="secondaryPreferred", mongo_w="majority",
                        mongo_writeTimeout=2000, mongo_j=true, mongo_connTimeout=2000, mongo_maxConnPoolSize=20,
                        mongo_minConnPoolSize=1, mongo_maxConnLifeTime=20000, mongo_maxConnIdleTime=20000,
                        mongo_maxConnPoolWaitTime=2000, mongo_maxConnPoolWaitSize=20, mongo_heartbeatFreq=20000,
                        mongo_minHeartbeatFreq=1000};
                if(arguments.settingName EQ "mongo_maxStaleness")
                        throw(type="CCSTest.UnsupportedNoSQL", message="Installed Admin API lacks maxStalenessSeconds; this test is unsupported, not passing.");
                if(arguments.settingName EQ "dsnName")
                        name = apiUtil.getReservedNames()[2];
                else if(arguments.settingName NEQ "driverName")
                        config[apiUtil.getFieldMap()[arguments.settingName]] = replacements[arguments.settingName];
                var entries = structNew("ordered");
                entries[name] = config;
                return {entries=entries};
        }

        private struct function initFrame(required any testDriver, required string settingName, required string scriptPath){
                return arguments.testDriver.initTestFrameWithPreSetValues(arguments.settingName,
                        arguments.testDriver.getGenericTestFrame(), arguments.scriptPath,
                        "nosql/_getter.cfm", "nosql/_setter.cfm", false);
        }

        private void function assertEmptyPresets(required struct values){
                var configUtil = new cfsuite.ccssuite.utils.nosqlConfigUtil().init();
                if(structCount(arguments.values) LT 2)
                        throw(type="CCSTest.NoSQLBaseline", message="At least two CCS node baselines are required; no configuration changed.");
                for(var nodeKey in arguments.values){
                        if(NOT configUtil.statesMatch('{"entries":{}}', arguments.values[nodeKey]))
                                throw(type="CCSTest.NoSQLCollision", message="Reserved MongoDB names must be absent on every node; no configuration changed.");
                }
        }

        public struct function runSyncTest(required any testDriver, required string settingName, required string scriptPath){
                var apiUtil = new cfsuite.ccssuite.utils.nosqlDatasourceApiUtil().init();
                var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
                var originalFrame = {};
                var originalValues = {};
                var writesStarted = false;
                try {
                        apiUtil.requireSupported(arguments.settingName);
                        stUtil.initializeCcsNodeConfig("all");
                        application.primeNodeIndex = new cfsuite.ccssuite.testManager().init().setAndGetPrimeNodeIndex(1);
                        originalFrame = initFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath);
                        originalValues = stUtil.collectPresetValuesFromFrame(originalFrame);
                        assertEmptyPresets(originalValues);
                        if(structCount(originalFrame[application.testConstants.TEST_FRAME.PRIME_SET]) LT 2)
                                throw(type="CCSTest.NoSQLBaseline", message="Two nodes in the same CCS cluster and environment are required; no configuration changed.");
                        var target = serializeJSON(getTargetState(arguments.settingName));
                        var testFrame = originalFrame;
                        writesStarted = true;
                        if(arguments.settingName NEQ "driverName"){
                                var seedEntries = structNew("ordered");
                                seedEntries[apiUtil.getReservedNames()[1]] = getSeedConfig();
                                var seed = serializeJSON({entries=seedEntries});
                                var expectedSeed = arguments.testDriver.getExpectedTestFrame(duplicate(originalFrame), seed);
                                var actualSeed = arguments.testDriver.setAndGetSyncedValues(duplicate(originalFrame), seed, arguments.settingName);
                                if(NOT arguments.testDriver.syncedFramesMatch(actualSeed, expectedSeed))
                                        throw(type="CCSTest.NoSQLSeed", message="Reserved MongoDB seed did not synchronize strictly.");
                                testFrame = initFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath);
                        }
                        var expected = arguments.testDriver.getExpectedTestFrame(duplicate(testFrame), target);
                        var actual = arguments.testDriver.setAndGetSyncedValues(duplicate(testFrame), target, arguments.settingName);
                        return {passed=arguments.testDriver.syncedFramesMatch(actual, expected),
                                originalFrame=originalFrame, originalValues=originalValues, scriptPath=arguments.scriptPath};
                }
                catch(any failure){
                        if(writesStarted)
                                restoreSyncTest(arguments.testDriver, {originalFrame=originalFrame, originalValues=originalValues,
                                        scriptPath=arguments.scriptPath}, arguments.settingName);
                        rethrow;
                }
                finally { application.ccsTestNodesScope = "currentPort"; }
        }

        public void function restoreSyncTest(required any testDriver, required struct result, required string settingName){
                if(NOT structKeyExists(arguments.result, "originalFrame"))
                        return;
                var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
                var configUtil = new cfsuite.ccssuite.utils.nosqlConfigUtil().init();
                try {
                        application.ccsTestNodesScope = "all";
                        arguments.testDriver.restoreOriginalSettingPerNode(arguments.result.originalFrame,
                                arguments.result.originalValues, arguments.settingName);
                        var restored = stUtil.collectPresetValuesFromFrame(initFrame(arguments.testDriver,
                                arguments.settingName, arguments.result.scriptPath));
                        if(structCount(restored) NEQ structCount(arguments.result.originalValues))
                                throw(type="CCSTest.NoSQLRestore", message="NoSQL cleanup could not verify all original nodes.");
                        for(var nodeKey in arguments.result.originalValues){
                                if(NOT structKeyExists(restored, nodeKey) OR NOT configUtil.statesMatch(arguments.result.originalValues[nodeKey], restored[nodeKey]))
                                        throw(type="CCSTest.NoSQLRestore", message="NoSQL cleanup did not restore a captured node baseline.");
                        }
                }
                finally { application.ccsTestNodesScope = "currentPort"; }
        }
}