<!---

* @file  EnableNullSupport.cfm
* @author  pnayak 16/05/24
* @description init f/w w/ node config info to orchestrate the tests 
*
--->

<cfscript>
	final SETTING_NAME = "EnableNullSupport"
	
	//get current setting value.
	testDvr = new cfsuite.ccssuite.testDriver() //().init();
	sUtil = new cfsuite.ccssuite.util.structUtil()

	testFrame = testDvr.getGenericTestFrame()
	cfdump(var="#testFrame#", label="inited testFrame")
	
	initedTestFrame = testDvr.initTestFrameWithPreSetValues(SETTING_NAME, testFrame, CGI.SCRIPT_NAME)
	cfdump(var="#initedTestFrame#", label="prevals initedTestFrame")

	currentValue = getCurrentlySetValueFromFrame(initedTestFrame, SETTING_NAME)
	writeOutput("isBoolean(currentValue): |#currentValue#|" & isBoolean(currentValue))
	if(!isBoolean(currentValue)){
		writeOutput("invalid currently set value detected for #SETTING_NAME#. Value set to: #currentValue#<br>")
		throw (message="invalid current setting", type="ConfigErr")
	}
	newSetValue = NOT(currentValue) //flip the setting.

	writeOutput("updating #SETTING_NAME# to: #newSetValue#<br>" )
	postSyncFrame = testDvr.setAndGetSyncedValues(structCopy(initedTestFrame), newSetValue, SETTING_NAME)
	cfdump(var="#postSyncFrame#", label="postSyncFrame")
	writeoutput(postSyncFrame["primeSet"]["localhost::8501"]["postSetValue"])
	
	expectedPostSetFrame = testDvr.getExpectedTestFrame(structCopy(initedTestFrame), newSetValue, SETTING_NAME)
	cfdump(var="#expectedPostSetFrame#", label="expectedPostSetFrame")

	cfdump(var="#postSyncFrame#", label="postSyncFrame-post getExpectedFrame call")
	writeoutput(postSyncFrame["primeSet"]["localhost::8501"]["postSetValue"])
</cfscript>


<cf_qatest id="test-#SETTING_NAME#">
	<cfscript>
		//comapre the expected and the actual results
		/*
		if(sUtil.structCompare(postSyncFrame, expectedPostSetFrame))
			writeOutput("setting values as expected<br>")
		else
			writeOutput("setting values NOT as expected<br>")
*/
	</cfscript>

	<cf_expectedresults>
		<cfscript>
			writeOutput("setting values as expected<br>")
		</cfscript>
	</cf_expectedresults>

</cf_qatest>
<cf_qatestEnd stats=true>

<cfscript>
	any function getCurrentlySetValueFromFrame(struct testFrame){
		try{
			nodeKeyList = testFrame[application.testConstants.TEST_FRAME.PRIME_SET].keylist()
			nodeKey = listGetAt(nodeKeyList, 1)
			prePostMap = testFrame[application.testConstants.TEST_FRAME.PRIME_SET].find(nodeKey)

			return prePostMap[application.testConstants.TEST_FRAME.PRESET_VALUE].trim()
		}
		catch(any e){
			writeOutput("error geting preset value for #SETTING_NAME#<br>")
			writeDump(e)
		}
		return 0
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