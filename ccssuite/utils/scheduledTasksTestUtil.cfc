component output="false" {
        public function init(){
                return this;
        }

        public void function assertEmptyFixturePresets(required struct presets){
                for(var nodeKey in arguments.presets){
                        var text = isSimpleValue(arguments.presets[nodeKey]) ? trim("" & arguments.presets[nodeKey]) : "";
                        if(NOT len(text) OR NOT isJSON(text))
                                throw(message="Scheduled task baseline unavailable for node " & nodeKey,
                                        detail="The shared Server Settings getter must return a JSON array, not an empty or invalid response. Deploy the updated scheduler utilities and testsuite to every CCS node before running this test. No tasks were changed.",
                                        type="CCSTest.SchedulerPresetUnavailable");
                        var preset = deserializeJSON(text);
                        if(NOT isArray(preset))
                                throw(message="Invalid scheduled task baseline for node " & nodeKey,
                                        detail="Expected a JSON array from the updated scheduler getter. Deploy matching scheduler utilities and testsuite on every CCS node. No tasks were changed.",
                                        type="CCSTest.SchedulerPresetUnavailable");
                        if(arrayLen(preset))
                                throw(message="Reserved scheduler fixture already exists on node " & nodeKey,
                                        detail="Remove it deliberately before testing. No tasks were changed.",
                                        type="CCSTest.SchedulerFixtureCollision");
                }
        }

        public struct function runSyncTest(required any testDriver, required string settingName, required string scriptPath, string testDsn = "", boolean createTables = false){
                var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
                var configUtil = new cfsuite.ccssuite.utils.scheduledTasksConfigUtil().init();
                if(arguments.createTables AND arguments.settingName NEQ "dsnname")
                        throw(message="Table creation is supported only for scheduler cluster setup", type="CCSTest.ConfigError");
                if(arguments.settingName EQ "dsnname" AND NOT len(trim(arguments.testDsn)))
                        return {skipped=true, message="Select Datasource test requires testDsn naming a disposable, already provisioned scheduler cluster datasource. No tables are created."};
                stUtil.initializeCcsNodeConfig("all");
                var originalFrame = {};
                try {
                        originalFrame = stUtil.initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, false);
                }
                catch(any failure){
                        application.ccsTestNodesScope = "currentPort";
                        rethrow;
                }
                var originalValues = stUtil.collectPresetValuesFromFrame(originalFrame);
                if(arguments.settingName NEQ "dsnname"){
                        try {
                                assertEmptyFixturePresets(originalValues);
                        }
                        catch(any failure){
                                application.ccsTestNodesScope = "currentPort";
                                rethrow;
                        }
                }
                try {
                        var result = {};
                        var testFrame = originalFrame;
                        if(NOT listFindNoCase("dsnname,createTask", arguments.settingName)){
                                var seed = configUtil.getTestState(arguments.settingName, true);
                                savecontent variable="local.preparationOutput" {
                                        result = stUtil.runMultiNodeSettingSyncTest(arguments.testDriver, arguments.settingName, arguments.scriptPath, seed, originalFrame, false);
                                }
                                if(NOT result.passed){
                                        writeOutput(local.preparationOutput);
                                        writeOutput("<p>Fixture creation did not synchronize; the field update was not attempted.</p>");
                                        result.schedulerOriginalFrame = originalFrame;
                                        result.schedulerOriginalValues = originalValues;
                                        return result;
                                }
                                stUtil.initializeCcsNodeConfig("all");
                                testFrame = stUtil.initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, false);
                        }
                        var target = arguments.settingName EQ "dsnname" ? arguments.testDsn : configUtil.getTestState(arguments.settingName);
                        if(arguments.createTables){
                                var configuredDsn = configUtil.createClusterTables(target);
                                if(compareNoCase(trim(configuredDsn), trim(target)) NEQ 0)
                                        throw(message="Scheduler table setup did not select the requested datasource", type="CCSTest.SchedulerClusterSetupFailed");
                        }
                        result = stUtil.runMultiNodeSettingSyncTest(arguments.testDriver, arguments.settingName, arguments.scriptPath, target, testFrame, false);
                        result.schedulerOriginalFrame = originalFrame;
                        result.schedulerOriginalValues = originalValues;
                        return result;
                }
                catch(any failure){
                        try {
                                application.ccsTestNodesScope = "all";
                                arguments.testDriver.restoreOriginalSettingPerNode(originalFrame, originalValues, arguments.settingName);
                        }
                        finally {
                                application.ccsTestNodesScope = "currentPort";
                        }
                        rethrow;
                }
        }

        public void function restoreSyncTest(required any testDriver, required struct result, required string settingName){
                if(NOT structKeyExists(arguments.result, "schedulerOriginalFrame"))
                        return;
                try {
                        application.ccsTestNodesScope = "all";
                        arguments.testDriver.restoreOriginalSettingPerNode(arguments.result.schedulerOriginalFrame, arguments.result.schedulerOriginalValues, arguments.settingName);
                }
                finally {
                        application.ccsTestNodesScope = "currentPort";
                }
        }
}