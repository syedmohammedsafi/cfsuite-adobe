component output="false" {
        public function init(){
                return this;
        }

        public struct function runSyncTest(required any testDriver, required string settingName, required string scriptPath){
                var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
                var configUtil = new cfsuite.ccssuite.utils.fontManagementConfigUtil().init();
                var originalFrame = {};
                var originalValues = {};
                var writesStarted = false;
                try {
                        stUtil.initializeCcsNodeConfig("all");
                        originalFrame = stUtil.initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, false);
                        originalValues = stUtil.collectPresetValuesFromFrame(originalFrame);
                        for(var nodeKey in originalValues){
                                var value = trim("" & originalValues[nodeKey]);
                                if(NOT len(value) OR NOT isJSON(value) OR NOT configUtil.configsMatch(arguments.settingName, "[]", value))
                                        throw(message="Font baseline is unavailable or the reserved fixture is already registered on node " & nodeKey,
                                                detail="Deploy matching font utilities and fixtures on every CCS node. No fonts were changed.", type="CCSTest.FontFixtureUnavailable");
                        }
                        if(NOT configUtil.fixtureExists(arguments.settingName))
                                throw(message="Generated font fixture is missing; no fonts were changed", type="CCSTest.FontFixtureMissing");
                        var target = configUtil.getTestState(arguments.settingName);
                        writesStarted = true;
                        var result = stUtil.runMultiNodeSettingSyncTest(arguments.testDriver, arguments.settingName, arguments.scriptPath, target, originalFrame, false);
                        result.fontOriginalFrame = originalFrame;
                        result.fontOriginalValues = originalValues;
                        return result;
                }
                catch(any failure){
                        if(writesStarted){
                                application.ccsTestNodesScope = "all";
                                arguments.testDriver.restoreOriginalSettingPerNode(originalFrame, originalValues, arguments.settingName);
                        }
                        rethrow;
                }
                finally {
                        application.ccsTestNodesScope = "currentPort";
                }
        }

        public void function restoreSyncTest(required any testDriver, required struct result, required string settingName){
                if(NOT structKeyExists(arguments.result, "fontOriginalFrame"))
                        return;
                try {
                        application.ccsTestNodesScope = "all";
                        arguments.testDriver.restoreOriginalSettingPerNode(arguments.result.fontOriginalFrame, arguments.result.fontOriginalValues, arguments.settingName);
                }
                finally {
                        application.ccsTestNodesScope = "currentPort";
                }
        }
}