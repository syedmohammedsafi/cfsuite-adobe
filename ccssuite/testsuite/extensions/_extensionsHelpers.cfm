<cfscript>
	any function getPresetValueFromFrame(required struct testFrame){
		nodeKey = listGetAt(testFrame[application.testConstants.TEST_FRAME.PRIME_SET].keylist(), 1);
		return testFrame[application.testConstants.TEST_FRAME.PRIME_SET][nodeKey][application.testConstants.TEST_FRAME.PRESET_VALUE];
	}

	any function getPostSetValueFromFrame(required struct testFrame){
		nodeKey = listGetAt(testFrame[application.testConstants.TEST_FRAME.PRIME_SET].keylist(), 1);
		return testFrame[application.testConstants.TEST_FRAME.PRIME_SET][nodeKey][application.testConstants.TEST_FRAME.POSTSET_VALUE];
	}

	string function getTestCustomTagPath(){
		return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().getTestCustomTagPath();
	}

	string function withoutTestCustomTagPath(required string currentValue){
		return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().removeTestCustomTagPathFromJson(arguments.currentValue);
	}

	string function withTestCustomTagPath(required string currentValue){
		paths = [];
		testPath = getTestCustomTagPath();
		try { paths = deserializeJSON(trim(currentValue)); } catch(any e){ paths = []; }
		if(NOT isArray(paths)) paths = [];
		if(arrayFindNoCase(paths, testPath) EQ 0)
			arrayAppend(paths, testPath);
		return serializeJSON(paths);
	}

	boolean function settingUpdateFailed(required any postValue){
		return findNoCase("set FAILED", trim("" & postValue)) GT 0;
	}

	boolean function javaCfxTestPassed(required any postValue){
		if(settingUpdateFailed(postValue)) return false;
		return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().javaCfxRegistered(postValue);
	}

	boolean function cppCfxTestPassed(required any postValue){
		if(settingUpdateFailed(postValue)) return false;
		return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().cppCfxRegistered(postValue);
	}

	boolean function customTagPathTestPassed(required any postValue, required string expectedPath){
		if(settingUpdateFailed(postValue)) return false;
		return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().customTagPathPresent(postValue, expectedPath);
	}
</cfscript>
