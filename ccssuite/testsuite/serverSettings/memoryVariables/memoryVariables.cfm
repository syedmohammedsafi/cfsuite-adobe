<!---

* @file  memoryVariable.cfm
* @author  pnayak 25/05/24
* @description init f/w w/ node config info to orchestrate the tests 
*
--->

<cfscript>
	constants = new testConstants().init()

	presetValues = ${}
	final REST_APP_PREFIX = "/rest/" & application.restsettings.serviceMapping
	final REST_GET_MAP = REST_APP_PREFIX & "/" & "memvar/sessioncookieget"
	final REST_SET_MAP = REST_APP_PREFIX & "/" & "memvar/sessioncookieset"

	cookieSettingsKeys = arrayNew(1)
	for(cooKey in constants.COOKIE.keyList())
		cookieSettingsKeys.append(constants.COOKIE[cooKey])

	//get current setting value.
	testDvr = new cfsuite.ccssuite.restDriver() //().init();
	sUtil = new cfsuite.ccssuite.utils.structUtil()
	dUtil = new cfsuite.ccssuite.utils.dataUtil()

	emptyTestFrame = testDvr.getGenericTestFrame()
	cfdump(var="#emptyTestFrame#", label="emptyTestFrame")
	
	presetTestFrame = testDvr.initTestFrameWithPreSetValues(cookieSettingsKeys, emptyTestFrame, REST_GET_MAP, REST_SET_MAP)
	cfdump(var="#presetTestFrame#", label="prevals presetTestFrame")

	constants = new testConstants().init()
	preSetCookieSettingsMap = getCurrentlySetValueFromFrame(presetTestFrame)
	newCookieSettingsMap = ${}
	for(settingKey in preSetCookieSettingsMap.keyList()){
		switch(settingKey){
			case constants.COOKIE.HTTP_ONLY:
			case constants.COOKIE.SECURE_SESSION:
			case constants.COOKIE.DISABLE_UPDATE:
				try{
					newCookieSettingsMap[settingKey] = dUtil.invertBoolean(preSetCookieSettingsMap[settingKey])
				}
				catch(any e){
					writeoutput("error flipping preset setting: #settingKey#<br>")
					newCookieSettingsMap[settingKey] = "ERROR"
				}
				break
			case constants.COOKIE.SAME_SITE:
				newCookieSettingsMap[settingKey] = changeSameSiteValue(preSetCookieSettingsMap[settingKey])
				break
			case constants.COOKIE.COOKIE_TIMEOUT:
				newCookieSettingsMap[settingKey] = preSetCookieSettingsMap[settingKey] + 10 //add some random integer
				break
		}
	}

	writeOutput("updating cookie settings to: #sUtil.flattenStruct(newCookieSettingsMap)#<br>" )
	postSyncFrame = testDvr.setAndGetSyncedValues(structCopy(presetTestFrame), newCookieSettingsMap, REST_GET_MAP, REST_SET_MAP)
	cfdump(var="#postSyncFrame#", label="postSyncFrame")
	//writeoutput(postSyncFrame["primeSet"]["localhost::8501"]["postSetValue"])
	
	expectedPostSetFrame = testDvr.getExpectedTestFrame(structCopy(presetTestFrame), newCookieSettingsMap)
	cfdump(var="#expectedPostSetFrame#", label="expectedPostSetFrame")

	cfdump(var="#postSyncFrame#", label="postSyncFrame-post getExpectedFrame call")
	//writeoutput(postSyncFrame["primeSet"]["localhost::8501"]["postSetValue"])
</cfscript>


<cf_qatest id="test-memvar">
	<cfscript>
		//comapre the expected and the actual results
	
		if(sUtil.structCompare(postSyncFrame, expectedPostSetFrame))
			writeOutput("setting values as expected<br>")
		else
			writeOutput("setting values NOT as expected<br>")
	/**/
	</cfscript>

	<cf_expectedresults>
		<cfscript>
			writeOutput("setting values as expected<br>")
		</cfscript>
	</cf_expectedresults>

</cf_qatest>
<cf_qatestEnd stats=true>

<cfscript>

	string function changeSameSiteValue(required string currentValue){
		
		//valuesList = [constants.SAMESITE_VALUES.LAX, constants.SAMESITE_VALUES.STRICT, constants.SAMESITE_VALUES.NONE]
		switch(currentValue){
			case constants.SAMESITE_VALUES.LAX:
				return constants.SAMESITE_VALUES.STRICT
			case constants.SAMESITE_VALUES.STRICT:
				return constants.SAMESITE_VALUES.LAX
			case constants.SAMESITE_VALUES.NONE:
				return return constants.SAMESITE_VALUES.LAX
			case "": //if its set to an empty string
				return constants.SAMESITE_VALUES.NONE
		}
		writeOutput("unexpected samesite setting value  detected: #currentValue#<br>")
		return constants.SAMESITE_VALUES.NONE //returning a valid value in case it was set earlier to an invalid value
	}


	struct function getCurrentlySetValueFromFrame(required struct testFrame){
		try{
			nodeKeyList = testFrame[application.testConstants.TEST_FRAME.PRIME_SET].keylist()
			nodeKey = listGetAt(nodeKeyList, 1)
			prePostMap = testFrame[application.testConstants.TEST_FRAME.PRIME_SET].find(nodeKey)

			return prePostMap[application.testConstants.TEST_FRAME.PRESET_VALUE]
		}
		catch(any e){
			writeOutput("error geting preset value for #SETTING_NAME#<br>")
			writeDump(e)
		}
		return {}
	}


	private any function getCurrentSettingValue(required string nodeKey, required string urlSuffix){
		
		_url = application.protocol & "://" & getURLFragFromNodeKey(nodeKey)  & urlSuffix //& "/"
		writeOutput("calling URL: " & _url & "<br>")
		
		cfhttp(url="#_url#", method="GET", result="response")

		if(response.statusCode EQ 200)
			return response.fileContent
		else if(response.statusCode EQ 500)
			return "500 ERROR getting setting value"
		else 
			return response.statusCode
	}

	public string function getURLFragFromNodeKey(required string nkey){
		frags = listToArray(nkey, application.testConstants.COMPOSITE_KEY_FIELD_SEPERATOR)
		if(frags.len() EQ 2)
			return frags[1] & ":" & frags[2]
		else if(frags.len() EQ 3)
			return frags[1] & ":" & frags[2] & "/" & frags[3]

		writeOutput("error parsing nodeKey: " & nkey)
		}
</cfscript>