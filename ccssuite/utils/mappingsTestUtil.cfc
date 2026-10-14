component output="false" {
	public function init(){
		return this;
	}

	public struct function runSyncTest(required any testDriver, required string settingName, required string scriptPath){
		var stUtil = new cfsuite.ccssuite.utils.serverSettingsTestUtil().init();
		var configUtil = new cfsuite.ccssuite.utils.mappingsConfigUtil().init();
		stUtil.initializeCcsNodeConfig("all");
		var originalFrame = stUtil.initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, false);
		var originalValues = stUtil.collectPresetValuesFromFrame(originalFrame);
		var currentValue = stUtil.getPresetValueFromFrame(originalFrame, arguments.settingName);
		try {
			var testFrame = originalFrame;
			if(arguments.settingName NEQ "logicalPath"){
				var seed = configUtil.getTestState(arguments.settingName, currentValue, true);
				var preparation = {};
				savecontent variable="local.preparationOutput" {
					preparation = stUtil.runMultiNodeSettingSyncTest(arguments.testDriver, arguments.settingName, arguments.scriptPath, seed, originalFrame, false);
				}
				if(NOT preparation.passed){
					writeOutput(local.preparationOutput);
					writeOutput("<p>Fixture creation did not synchronize. The directory update or deletion was not attempted.</p>");
					preparation.mappingOriginalFrame = originalFrame;
					preparation.mappingOriginalValues = originalValues;
					return preparation;
				}
				stUtil.initializeCcsNodeConfig("all");
				testFrame = stUtil.initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, false);
				currentValue = stUtil.getPresetValueFromFrame(testFrame, arguments.settingName);
				if(NOT configUtil.configsMatch(arguments.settingName, seed, currentValue))
					throw(message="Unable to create the reserved mapping fixture; update/delete was not attempted", type="CCSTest.MappingFixtureFailed");
			}
			var target = configUtil.getTestState(arguments.settingName, currentValue);
			var result = stUtil.runMultiNodeSettingSyncTest(arguments.testDriver, arguments.settingName, arguments.scriptPath, target, testFrame, false);
			result.mappingOriginalFrame = originalFrame;
			result.mappingOriginalValues = originalValues;
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
		if(NOT structKeyExists(arguments.result, "mappingOriginalFrame"))
			return;
		try {
			application.ccsTestNodesScope = "all";
			arguments.testDriver.restoreOriginalSettingPerNode(arguments.result.mappingOriginalFrame, arguments.result.mappingOriginalValues, arguments.settingName);
		}
		finally {
			application.ccsTestNodesScope = "currentPort";
		}
	}
}