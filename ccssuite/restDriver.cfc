/**
*
* @file  /E/CFGronckleBuilds/fortunaNx/cfusion/wwwroot/cfsuite/ccssuite/restDriver.cfc
* @author  pnayak 25/05/24
* @description utility cfc to drive individual feature test cfms.
*
*/

component output="true" displayname=""  {

	this.testMgr = new cfsuite.ccssuite.testManager().init();
	this.testUtil = new cfsuite.ccssuite.utils.testUtil().init();
	this.sUtil = new cfsuite.ccssuite.utils.structUtil().init();

	public function init(){
		return this;
	}

	public struct function getGenericTestFrame(){
		testCnfgMap = {
			"#application.testConstants.TEST_FRAME.CFSETTING#" : "",
			"#application.testConstants.TEST_FRAME.SETTER_URL#" : "",
			"#application.testConstants.TEST_FRAME.GETTER_URL#" : "",
			"#application.testConstants.TEST_FRAME.PRIME_SET#" : {		
				// nodekey{
					//"#application.testConstants.PRESET_VALUE#" : "",
					//"#application.testConstants.POSTSET_VALUE#" : ""
					//}
				},
			"#application.testConstants.TEST_FRAME.NONPRIME_SET#" : {		
				// nodekey{
					//"#application.testConstants.PRESET_VALUE#" : "",
					//"#application.testConstants.POSTSET_VALUE#" : ""
					//}
				}
			}

		primeKeys = this.testMgr.getNodeKeysInPrimeEnvironment()
		for(key in listToArray(primeKeys)){
			testCnfgMap[application.testConstants.TEST_FRAME.PRIME_SET][key][application.testConstants.TEST_FRAME.PRESET_VALUE] = ""
			testCnfgMap[application.testConstants.TEST_FRAME.PRIME_SET][key][application.testConstants.TEST_FRAME.POSTSET_VALUE] = ""
		}

		primeKeys = this.testMgr.getNodeKeysNotInPrimeEnvironment()
		for(key in listToArray(primeKeys)){
			testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET][key][application.testConstants.TEST_FRAME.PRESET_VALUE] = ""
			testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET][key][application.testConstants.TEST_FRAME.POSTSET_VALUE] = ""
		}
		return structCopy(testCnfgMap)
	}


	//set the passed setting in a primeNode and read and populated the setting values in all nodes.
	public struct function setAndGetSyncedValues(required struct ssTestFrame, required struct newCookieSettingsMap){

		primKeyList = ssTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList()
		setURLSuffix = ssTestFrame[application.testConstants.TEST_FRAME.SETTER_URL]
		
		//select a random node from the prime node list
		firstNodeKey = listGetAt(primKeyList, 1)  //////////////// setting the target node to 1.. randomize?? //////////////
		writeoutput("targetted node for settings update: :#firstNodeKey#<br>")

		_url = getURL(firstNodeKey, setURLSuffix)

		//update the setting on the selected node. That should be propagated automatically to all the nodes in the same env.
		if(NOT makeSetHTTPCall(_url, newCookieSettingsMap)){
			//return {} //failed to set value. not point in proceeding
			writeOutput("set call failed for url: #_url#<br>")
			cflog(type="error", application=true, file="#application.applicationname#", text="testDriver.setAndGetSyncedValues : set call failed for url: #_url#")
		}

		//check if the setting value for a successful set operation.
		getURLSuffix = ssTestFrame[application.testConstants.TEST_FRAME.GETTER_URL]
		setValuesMap = getCurrentSettings(firstNodeKey, getURLSuffix, newCookieSettingsMap)
		primePrePostPairMap = ssTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].find(firstNodeKey)
		if(NOT structIsEmpty(setValuesMap) AND this.sUtil.structCompare(setValuesMap, newCookieSettingsMap)){
			primePrePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = setValuesMap
			cflog(type="debug", application=true, file="#application.applicationname#", text="testDriver.setAndGetSyncedValues : set prime node successful for setting: #serializeJSON(ssTestFrame[application.testConstants.TEST_FRAME.CFSETTING])#")
	
			for(primeKey in listToArray(primKeyList)){
				prePostPairMap = ssTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].find(primeKey)
				prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = 
					 getCurrentSettings(firstNodeKey, getURLSuffix, newCookieSettingsMap)
			}

			nPrimKeyList = ssTestFrame[#application.testConstants.TEST_FRAME.NONPRIME_SET#].keyList()
			for(nPrimeKey in listToArray(nPrimKeyList)){
				prePostPairMap = ssTestFrame[#application.testConstants.TEST_FRAME.NONPRIME_SET#].find(nPrimeKey)
				prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = 
					 getCurrentSettings(firstNodeKey, getURLSuffix, newCookieSettingsMap)
			}
		}
		else{
			writeOutput("set call FAILED.<br>set value: #this.sUtil.flattenStruct(setValuesMap)#<br>expected: #this.sUtil.flattenStruct(newCookieSettingsMap)#<br>")
			primePrePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = "set FAILED. value set to #this.sUtil.flattenStruct(setValuesMap)#"

		}

		//////////////////////// all values in prime node
		//cfdump(var=#ssTestFrame#, label="ssTestFrame in set N Sync")
		return ssTestFrame
	}


	//compose and return a test frame state with ideal settings values if the CCS sync worked to update the values in the intented noddes.
	public struct function getExpectedTestFrame(required struct expTestFrame, required any toSetValue){
		
		primKeyList = expTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList()
		for(primeKey in listToArray(primKeyList)){
			prePostPairMap = expTestFrame[#application.testConstants.TEST_FRAME.PRIME_SET#].find(primeKey)
			prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = toSetValue
		}

		nPrimKeyList = expTestFrame[#application.testConstants.TEST_FRAME.NONPRIME_SET#].keyList()
		for(nPrimeKey in listToArray(nPrimKeyList)){
			prePostPairMap = expTestFrame[#application.testConstants.TEST_FRAME.NONPRIME_SET#].find(nPrimeKey)
			prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = prePostPairMap[application.testConstants.TEST_FRAME.PRESET_VALUE] //should not have changed
		}
		cfdump(var=#expTestFrame#, label ="returning expected fame")
		return expTestFrame
	}


	/** Restore a multi-setting map to pre-test values on all in-scope CCS nodes. */
	public void function restoreOriginalSettingsMap(required struct initedTestFrame, required struct originalSettingsMap){
		writeOutput("restoring settings to original values<br>")
		setAndGetSyncedValues(duplicate(arguments.initedTestFrame), arguments.originalSettingsMap)
	}


	//init the setting Test frame with cf setting's preset values. 
	public struct function initTestFrameWithPreSetValues(required array settingsList, 
															required struct testCnfgMap,
															required string restGetPath,
															required string restPostPath){

		settingsMap = structNew()
		for(ckey in settingsList)
			settingsMap.insert(cKey, "")

		testCnfgMap[application.testConstants.TEST_FRAME.CFSETTING] = settingsMap
		testCnfgMap[application.testConstants.TEST_FRAME.GETTER_URL] = restGetPath
		testCnfgMap[application.testConstants.TEST_FRAME.SETTER_URL] = restPostPath

		primeNodeKeyList = testCnfgMap[application.testConstants.TEST_FRAME.PRIME_SET].keyList()
		for(primeNodeKey in listToArray(primeNodeKeyList)){
			prePostPairMap = testCnfgMap[application.testConstants.TEST_FRAME.PRIME_SET].find(primeNodeKey)
			prePostPairMap[application.testConstants.TEST_FRAME.PRESET_VALUE] = 
				 getCurrentSettings(primeNodeKey, testCnfgMap[application.testConstants.TEST_FRAME.GETTER_URL], settingsMap)
		}

		nPrimeNodeKeyList = testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET].keyList()
		for(nPrimeNodeKey in listToArray(nPrimeNodeKeyList)){
			prePostPairMap = testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET].find(nPrimeNodeKey)
			prePostPairMap[application.testConstants.TEST_FRAME.PRESET_VALUE] = 
				 getCurrentSettings(nPrimeNodeKey, testCnfgMap[application.testConstants.TEST_FRAME.GETTER_URL], settingsMap)
		}
		return testCnfgMap
	}


	private any function getCurrentSettings(required string nodeKey, required string urlSuffix, required struct settingsMap){
		
		//writeOutput("nodeKey: #nodeKey# - urlSuffix - #urlSuffix# - application.protocol : #application.protocol#")
		_url = getURL(nodeKey, urlSuffix) 
		
		try{
			cfhttp(url="#_url#", method="GET", result="response")
			//writeDump(response)
			if(response.statusCode EQ application.constants.CF_CONFIG["HTTP_STATUS_CODE_SUCCESS"])
				return deserializeRestResponse(response.fileContent)
			else if(response.statusCode EQ 500)
				return "500 ERROR getting setting value"
			else 
				return response.statusCode
		}
		catch(any e){
			writeOutput("ERROR calling URL: #_url#<br>")
			writeDump(e)
		}
		return "ERROR calling get"
	}


	private struct function deserializeRestResponse(any responseData){
		
		settingsMap = structNew()
		//cfdump(var=#deserializeJSON(responseData)#, label="responseData")
		if(responseData.trim().len() NEQ 0)
			settingsMap = deserializeJSON(responseData)
		else
			writeOutput("error interpreting REST response: #responseData#<br>")

		return settingsMap			
	}


	private function getURL(required string nodeKey, required string urlSuffix){
		
		_url =  application.protocol & "://" & this.testUtil.getURLFragFromNodeKey(nodeKey) & urlSuffix 
		return _url
	}


	private boolean function makeSetHTTPCall(required string _url, required struct settingsMap){

		try{
			cfhttp(url="#_url#", method="POST", result="response", timeout=10){
	 			cfhttpparam(type="header", name="Content-Type", value="application/json")
	    		cfhttpparam(type="body", value="#serializeJSON(settingsMap)#")
			}

			if(response.statusCode EQ application.constants.CF_CONFIG["HTTP_STATUS_CODE_SUCCESS"])
				return true
			else{
				writeDump(response)
				writeOutput("ERROR [statusCode: #response.statusCode#] returned by URL: #_url#<br>")
			}
		}
		catch(any e){
			writeOutput("ERROR calling URL: #_url#<br>")
			writeDump(e)
		}
		
		return false				
	}

}