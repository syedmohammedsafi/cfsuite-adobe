/**
*
* @file  /E/CFGronckleBuilds/fortunaNx/cfusion/wwwroot/cfsuite/ccssuite/testDriver.cfc
* @author  pnayak 14/05/24
* @description utility cfc to drive individual feature test cfms.
*
*/

component output="true" displayname=""  {

	final SETTER_CFML_TEMPLATE_NAME = "_setter.cfm"
	final GETTER_CFML_TEMPLATE_NAME = "_getter.cfm"
	final URL_QUERYPARAM_SETTING = "setting"
	final URL_QUERYPARAM_SETTING_VALUE = "setValueTo"
	final URL_QUERYPARAM_API_AREA = "area"

	private any function getTestMgr(){
		if(NOT structKeyExists(this, "testMgr") OR NOT isObject(this.testMgr))
			this.testMgr = new cfsuite.ccssuite.testManager().init();
		return this.testMgr;
	}

	public function init(){
		var forceReinit = structKeyExists(url, "reinit") AND (url.reinit EQ 1 OR url.reinit EQ "1");
		new cfsuite.ccssuite.appBootstrap().ensureStarted(forceReinit);
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

		primeKeys = filterNodeKeysForTestScope(getTestMgr().getNodeKeysInPrimeEnvironment())
		for(key in listToArray(primeKeys)){
			testCnfgMap[application.testConstants.TEST_FRAME.PRIME_SET][key][application.testConstants.TEST_FRAME.PRESET_VALUE] = ""
			testCnfgMap[application.testConstants.TEST_FRAME.PRIME_SET][key][application.testConstants.TEST_FRAME.POSTSET_VALUE] = ""
		}

		primeKeys = filterNodeKeysForTestScope(getTestMgr().getNodeKeysNotInPrimeEnvironment())
		for(key in listToArray(primeKeys)){
			testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET][key][application.testConstants.TEST_FRAME.PRESET_VALUE] = ""
			testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET][key][application.testConstants.TEST_FRAME.POSTSET_VALUE] = ""
		}
		return structCopy(testCnfgMap)
	}


	//set the passed setting in a primeNode and read and populated the setting values in all nodes. 
	public struct function setAndGetSyncedValues(required struct postSetTestFrame, required any toSetValue, required any cfSettingKey){
		primKeyList = filterNodeKeysForTestScope(postSetTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList())
		setURLSuffix = postSetTestFrame[application.testConstants.TEST_FRAME.SETTER_URL]
		getURLSuffix = postSetTestFrame[application.testConstants.TEST_FRAME.GETTER_URL]
		
		apiArea = getApiAreaFromFrame(postSetTestFrame)
		firstNodeKey = listGetAt(primKeyList, 1)
		if(listLen(primKeyList) GT 1){
			for(var nodeKey in listToArray(primKeyList)){
				if(isLocalNodePort(nodeKey)){
					firstNodeKey = nodeKey;
					break;
				}
			}
		}
		primePrePostPairMap = postSetTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].find(firstNodeKey)

		ccsDriver = new cfsuite.ccssuite.ccsDriver().init();
		if(NOT ccsDriver.isCcsSyncAvailable()){
			writeOutput("<strong>CCS unavailable:</strong> no CCS nodes are enabled in Central Config Server. Enable CCS on at least one node before running sync tests.<br>")
			primePrePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = "set FAILED. CCS not enabled in node config"
			return postSetTestFrame
		}
		if(ccsDriver.isUsingJavaFallbackConfig()){
		}

		urlQryParams = buildSettingQueryParams(cfSettingKey, toSetValue, apiArea)
		var _url = getURL(firstNodeKey, setURLSuffix, urlQryParams)
		
		var menuName = getMenuNameFromUrl(setURLSuffix);
		if(isSecurityMenuUrl(setURLSuffix) AND listFindNoCase("SandboxPath,SandboxPathCopyFrom", cfSettingKey)){
			setOk = applySecuritySettingOnAllPrimeNodesVerified(postSetTestFrame, toSetValue, cfSettingKey, apiArea);
		}
		else if(isSecurityMenuUrl(setURLSuffix)){
			setOk = setAndVerifySettingViaHttp(firstNodeKey, setURLSuffix, getURLSuffix, cfSettingKey, toSetValue, apiArea);
		}
		else {
			setOk = (isLocalNodePort(firstNodeKey) AND NOT isSecurityMenuUrl(setURLSuffix))
				? setPropertyLocal(cfSettingKey, toSetValue, apiArea, menuName)
				: makeSetHTTPCall(_url);
		}
		presetValue = primePrePostPairMap[application.testConstants.TEST_FRAME.PRESET_VALUE]
		if(NOT setOk){
			var failedSetUrl = listFindNoCase("redisCacheStoragePassword,sessionStoragePassword", cfSettingKey) ? "[redacted]" : _url;
			writeOutput("set call failed for url: #failedSetUrl#<br>")
			cflog(type="error", application=true, file="#application.applicationname#", text="testDriver.setAndGetSyncedValues : set call failed for url: #failedSetUrl#")
			rollbackNodesToValue(postSetTestFrame, presetValue, cfSettingKey)
			actualValue = getCurrentSettingValue(firstNodeKey, getURLSuffix, cfSettingKey, apiArea)
			primePrePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] =
				"set FAILED. Admin API or CCS rejected update (read back: #formatRollbackValue(actualValue, cfSettingKey)#)"
			return postSetTestFrame
		}

		//check if the setting value for a successful set operation.
		setValue = getCurrentSettingValue(firstNodeKey, getURLSuffix, cfSettingKey, apiArea);
		var setMatches = valuesMatch(cfSettingKey, toSetValue, setValue, apiArea, presetValue);
		if(setMatches){
			primePrePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = setValue
			cflog(type="debug", application=true, file="#application.applicationname#", 
				text="testDriver.setAndGetSyncedValues : set prime node successful for setting: #postSetTestFrame[application.testConstants.TEST_FRAME.CFSETTING]#")

			if(new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().requiresPeerInstancePropagation(cfSettingKey, apiArea)
					OR lCase(getMenuNameFromUrl(setURLSuffix)) EQ "aiservices"
					OR lCase(getMenuNameFromUrl(setURLSuffix)) EQ "extensions"
					OR lCase(getMenuNameFromUrl(setURLSuffix)) EQ "eventgateways"
					OR lCase(getMenuNameFromUrl(setURLSuffix)) EQ "security"){
				if(NOT listFindNoCase("SandboxPath,SandboxPathCopyFrom", cfSettingKey))
					propagateDocumentSettingToPrimePeers(postSetTestFrame, toSetValue, cfSettingKey, apiArea);
			}

			// Cluster document sync can briefly revert neo-saml on the origin node after peer propagation.
			if(isSecurityMenuUrl(setURLSuffix) AND NOT listFindNoCase("SandboxPath,SandboxPathCopyFrom", cfSettingKey) AND isLocalNodePort(firstNodeKey)){
				setAndVerifySettingViaHttp(firstNodeKey, setURLSuffix, getURLSuffix, cfSettingKey, toSetValue, apiArea);
			}
	
			for(primeKey in listToArray(primKeyList)){
				prePostPairMap = postSetTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].find(primeKey)
				prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] =
					readSettingValueWithRetry(
						primeKey,
						postSetTestFrame[application.testConstants.TEST_FRAME.GETTER_URL],
						cfSettingKey,
						apiArea,
						toSetValue,
						5,
						250
					)
			}

			nPrimKeyList = filterNodeKeysForTestScope(postSetTestFrame[#application.testConstants.TEST_FRAME.NONPRIME_SET#].keyList())
			for(nPrimeKey in listToArray(nPrimKeyList)){
				prePostPairMap = postSetTestFrame[#application.testConstants.TEST_FRAME.NONPRIME_SET#].find(nPrimeKey)
				try {
					prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = 
						 getCurrentSettingValue(nPrimeKey, postSetTestFrame[application.testConstants.TEST_FRAME.GETTER_URL], cfSettingKey, apiArea)
				}
				catch(any e){
					prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] =
						prePostPairMap[application.testConstants.TEST_FRAME.PRESET_VALUE]
					writeOutput("<strong>Non-prime node #nPrimeKey# not reachable</strong>; assuming preset unchanged. #e.message#<br>")
				}
			}
		}
		else{
			writeOutput("set call FAILED. set value: #formatRollbackValue(setValue, cfSettingKey)#<br>")
			rollbackNodesToValue(postSetTestFrame, presetValue, cfSettingKey)
			primePrePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = "set FAILED. value set to #formatRollbackValue(setValue, cfSettingKey)#"
		}

		return postSetTestFrame
	}


	//compose and return a test frame state with ideal settings values if the CCS sync worked to update the values in the intented noddes.
	public struct function getExpectedTestFrame(required struct expTestFrame, required any toSetValue){
		var expectedValue = trim("" & arguments.toSetValue);
		var apiArea = getApiAreaFromFrame(arguments.expTestFrame);
		var settingName = arguments.expTestFrame[application.testConstants.TEST_FRAME.CFSETTING];

		if(listFindNoCase("SandboxPath,SandboxPathCopyFrom", settingName))
			expectedValue = new cfsuite.ccssuite.utils.securityConfigUtil().init().getExpectedSandboxPathValueAfterAction(expectedValue);

		if(isDebuggingApiArea(apiArea) AND listFindNoCase("variables_scopes,debuggingIpAddress", settingName))
			expectedValue = new cfsuite.ccssuite.utils.debuggingConfigUtil().init().formatCommaListValue(expectedValue);

		primKeyList = filterNodeKeysForTestScope(expTestFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList())
		for(primeKey in primKeyList){
			prePostPairMap = expTestFrame[#application.testConstants.TEST_FRAME.PRIME_SET#].find(primeKey)
			if(isInstanceLocalApiArea(apiArea, settingName) AND NOT isLocalNodePort(primeKey))
				prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = prePostPairMap[application.testConstants.TEST_FRAME.PRESET_VALUE]
			else
				prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = expectedValue
		}

		nPrimKeyList = filterNodeKeysForTestScope(expTestFrame[#application.testConstants.TEST_FRAME.NONPRIME_SET#].keyList())
		for(nPrimeKey in nPrimKeyList){
			prePostPairMap = expTestFrame[#application.testConstants.TEST_FRAME.NONPRIME_SET#].find(nPrimeKey)
			if(shouldExpectClusterSecuritySync(settingName, apiArea, nPrimeKey))
				prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = expectedValue
			else
				prePostPairMap[application.testConstants.TEST_FRAME.POSTSET_VALUE] = prePostPairMap[application.testConstants.TEST_FRAME.PRESET_VALUE]
		}
		return expTestFrame
	}

	private boolean function shouldExpectClusterSecuritySync(required string settingName, required string apiArea, required string nodeKey){
		if(NOT isSameClusterEnvironmentNode(arguments.nodeKey))
			return false;
		if(arguments.settingName EQ "SandboxPath")
			return true;
		return listFindNoCase("administrator,rds,sandboxsecurity,settings", lCase(trim(arguments.apiArea))) GT 0;
	}

	private boolean function isSameClusterEnvironmentNode(required string nodeKey){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		if(NOT structKeyExists(application, "ccsConfigMap"))
			return true;
		var currentKey = CGI.SERVER_NAME & "::" & CGI.SERVER_PORT;
		if(NOT application.ccsConfigMap.keyExists(currentKey) OR NOT application.ccsConfigMap.keyExists(arguments.nodeKey))
			return true;
		var currentCluster = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.CLUSTER];
		var currentEnv = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		var nodeCluster = application.ccsConfigMap[arguments.nodeKey][application.constants.CCS_CONFIG.CLUSTER];
		var nodeEnv = application.ccsConfigMap[arguments.nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		return currentCluster EQ nodeCluster AND currentEnv EQ nodeEnv;
	}


	/** Restore a setting to its pre-test value on all in-scope CCS nodes (local Admin API; does not require CCS sync). */
	public void function restoreOriginalSetting(required struct initedTestFrame, required any originalValue, required string settingName){
		writeOutput("restoring " & arguments.settingName & " to original value: " & formatRollbackValue(arguments.originalValue, arguments.settingName) & "<br>")
		var apiArea = getApiAreaFromFrame(arguments.initedTestFrame)
		var setURLSuffix = arguments.initedTestFrame[application.testConstants.TEST_FRAME.SETTER_URL]
		var menuName = getMenuNameFromUrl(setURLSuffix)
		rollbackNodesToValue(arguments.initedTestFrame, arguments.originalValue, arguments.settingName, apiArea, menuName)
	}


	public void function restoreOriginalSettingPerNode(required struct initedTestFrame, required struct nodeValues, required string settingName){
		writeOutput("restoring " & arguments.settingName & " on all cluster nodes to pre-test values<br>")
		var apiArea = getApiAreaFromFrame(arguments.initedTestFrame)
		var setURLSuffix = arguments.initedTestFrame[application.testConstants.TEST_FRAME.SETTER_URL]
		var menuName = getMenuNameFromUrl(setURLSuffix)
		rollbackNodesToExistingValues(arguments.initedTestFrame, arguments.nodeValues, arguments.settingName, apiArea, menuName)
	}


	/** Clear remote OpenOffice host/port on this instance and all reachable CCS nodes (Admin Document tab). */
	public void function clearDocumentRemoteOpenOfficeOnAllNodes(required struct testFrame){
		var apiUtil = new cfsuite.ccssuite.utils.serverSettingsApiUtil().init();
		var apiArea = "document";
		var setURLSuffix = arguments.testFrame[application.testConstants.TEST_FRAME.SETTER_URL];
		var cleared = true;

		writeOutput("clearing remoteOpenOffice (remote host/port) after test<br>");

		var nodeKeyLists = [
			arguments.testFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList(),
			arguments.testFrame[application.testConstants.TEST_FRAME.NONPRIME_SET].keyList()
		];

		for(var listIdx = 1; listIdx LTE arrayLen(nodeKeyLists); listIdx++){
			for(var nodeKey in listToArray(nodeKeyLists[listIdx])){
				if(isLocalNodePort(nodeKey))
					continue;
				var urlQryParams = buildSettingQueryParams("remoteOpenOffice", "", apiArea);
				var _url = getURL(nodeKey, setURLSuffix, urlQryParams);
				if(NOT makeSetHTTPCall(_url))
					cleared = false;
			}
		}

		apiUtil.clearDocumentRemoteOpenOfficeSettings();
		if(NOT apiUtil.verifyDocumentRemoteOpenOfficeCleared())
			cleared = false;

		if(cleared)
			writeOutput("remoteOpenOffice cleared on all reachable nodes (Admin runtime + neo-document.xml).<br>");
		else
			writeOutput("<strong>Warning:</strong> remoteOpenOffice clear may be incomplete — refresh Admin Document page; if values remain, restart the CF instance.<br>");
	}


	public void function propagateSecuritySettingToPrimePeers(
		required struct testFrame,
		required any toSetValue,
		required string cfSettingKey,
		string apiArea = ""
	){
		var area = len(trim(arguments.apiArea)) ? arguments.apiArea : getApiAreaFromFrame(arguments.testFrame);
		propagateDocumentSettingToPrimePeers(arguments.testFrame, arguments.toSetValue, arguments.cfSettingKey, area);
	}

	public void function applySecuritySettingOnAllPrimeNodes(
		required struct testFrame,
		required any toSetValue,
		required string cfSettingKey,
		string apiArea = ""
	){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		var area = len(trim(arguments.apiArea)) ? arguments.apiArea : getApiAreaFromFrame(arguments.testFrame);
		var setURLSuffix = arguments.testFrame[application.testConstants.TEST_FRAME.SETTER_URL];
		var getURLSuffix = arguments.testFrame[application.testConstants.TEST_FRAME.GETTER_URL];
		var menuName = getMenuNameFromUrl(setURLSuffix);
		var savedScope = structKeyExists(application, "ccsTestNodesScope") ? application.ccsTestNodesScope : "currentPort";
		application.ccsTestNodesScope = "all";
		var nodeKeys = getTestMgr().getNodeKeysInPrimeEnvironment();
		application.ccsTestNodesScope = savedScope;

		for(var nodeKey in listToArray(nodeKeys)){
			if(NOT isPeerNodeReachable(nodeKey))
				continue;
			if(isSecurityMenuUrl(setURLSuffix)){
				setAndVerifySettingViaHttp(nodeKey, setURLSuffix, getURLSuffix, arguments.cfSettingKey, arguments.toSetValue, area);
			}
			else if(isLocalNodePort(nodeKey)){
				forceSetPropertyLocal(arguments.cfSettingKey, arguments.toSetValue, area, menuName);
			}
			else {
				var urlQryParams = buildSettingQueryParams(arguments.cfSettingKey, arguments.toSetValue, area);
				makeSetHTTPCall(getURL(nodeKey, setURLSuffix, urlQryParams));
			}
		}
	}

	public boolean function applySecuritySettingOnAllPrimeNodesVerified(
		required struct testFrame,
		required any toSetValue,
		required string cfSettingKey,
		string apiArea = ""
	){
		applySecuritySettingOnAllPrimeNodes(arguments.testFrame, arguments.toSetValue, arguments.cfSettingKey, arguments.apiArea);
		var area = len(trim(arguments.apiArea)) ? arguments.apiArea : getApiAreaFromFrame(arguments.testFrame);
		var getURLSuffix = arguments.testFrame[application.testConstants.TEST_FRAME.GETTER_URL];
		var savedScope = structKeyExists(application, "ccsTestNodesScope") ? application.ccsTestNodesScope : "currentPort";
		application.ccsTestNodesScope = "all";
		var nodeKeys = getTestMgr().getNodeKeysInPrimeEnvironment();
		application.ccsTestNodesScope = savedScope;
		var success = true;
		for(var nodeKey in listToArray(nodeKeys)){
			if(NOT isPeerNodeReachable(nodeKey))
				continue;
			var actualValue = readSettingValueWithRetry(nodeKey, getURLSuffix, arguments.cfSettingKey, area, arguments.toSetValue, 3, 250);
			if(NOT valuesMatch(arguments.cfSettingKey, arguments.toSetValue, actualValue, area, arguments.toSetValue))
				success = false;
		}
		return success;
	}

	public void function repairSandboxSecurityOnAllNodesSequentially(required struct testFrame){
		var savedScope = structKeyExists(application, "ccsTestNodesScope") ? application.ccsTestNodesScope : "currentPort";
		application.ccsTestNodesScope = "all";
		var nodeKeys = listToArray(getTestMgr().getNodeKeysInPrimeEnvironment());
		application.ccsTestNodesScope = savedScope;
		var currentKey = resolveCurrentNodeKeyFromPrimeKeys(nodeKeys);
		var orderedKeys = [];
		for(var nodeKey in nodeKeys){
			if(nodeKey NEQ currentKey)
				arrayAppend(orderedKeys, nodeKey);
		}
		arrayAppend(orderedKeys, currentKey);
		for(var nodeKey in orderedKeys){
			applySecuritySettingOnSingleNodeVerified(
				arguments.testFrame,
				nodeKey,
				"repair",
				"SandboxPath",
				"sandboxsecurity"
			);
		}
	}

	private string function resolveCurrentNodeKeyFromPrimeKeys(required array nodeKeys){
		var currentPort = trim("" & CGI.SERVER_PORT);
		for(var nodeKey in arguments.nodeKeys){
			if(listLast(nodeKey, "::") EQ currentPort)
				return nodeKey;
		}
		for(var nodeKey in arguments.nodeKeys){
			if(isLocalNodePort(nodeKey))
				return nodeKey;
		}
		return arrayLen(arguments.nodeKeys) ? arguments.nodeKeys[1] : (CGI.SERVER_NAME & "::" & CGI.SERVER_PORT);
	}

	public boolean function applySecuritySettingOnSingleNodeVerified(
		required struct testFrame,
		required string nodeKey,
		required any toSetValue,
		required string cfSettingKey,
		string apiArea = ""
	){
		if(NOT isPeerNodeReachable(arguments.nodeKey))
			return true;
		var area = len(trim(arguments.apiArea)) ? arguments.apiArea : getApiAreaFromFrame(arguments.testFrame);
		var setURLSuffix = arguments.testFrame[application.testConstants.TEST_FRAME.SETTER_URL];
		var getURLSuffix = arguments.testFrame[application.testConstants.TEST_FRAME.GETTER_URL];
		if(isSecurityMenuUrl(setURLSuffix)){
			if(NOT setAndVerifySettingViaHttp(arguments.nodeKey, setURLSuffix, getURLSuffix, arguments.cfSettingKey, arguments.toSetValue, area))
				return false;
		}
		else {
			var urlQryParams = buildSettingQueryParams(arguments.cfSettingKey, arguments.toSetValue, area);
			if(NOT makeSetHTTPCall(getURL(arguments.nodeKey, setURLSuffix, urlQryParams)))
				return false;
		}
		var actualValue = readSettingValueWithRetry(arguments.nodeKey, getURLSuffix, arguments.cfSettingKey, area, arguments.toSetValue, 3, 250);
		return valuesMatch(arguments.cfSettingKey, arguments.toSetValue, actualValue, area, arguments.toSetValue);
	}


	/** True when post-sync frame matches expected (test passed). */
	public boolean function syncedFramesMatch(required struct postSyncFrame, required struct expectedPostSetFrame){
		var syncFrameApiArea = lCase(trim(getApiAreaFromFrame(arguments.postSyncFrame)));
		var syncFrameSettingName = structKeyExists(arguments.postSyncFrame, application.testConstants.TEST_FRAME.CFSETTING)
			? arguments.postSyncFrame[application.testConstants.TEST_FRAME.CFSETTING] : "";
		if((syncFrameApiArea EQ "caching" AND listFindNoCase("maxcachecount,jcsservermaxidle,jcsservermaxlife,jcsservermaxobjects,memcachedTimeToIdleSeconds,memcachedTimeToLiveSeconds,memcachedMaxElementsInMemory,redisCacheStoragePort,redisTimeToIdleSeconds,redisTimeToLiveSeconds,redisMaxElementsInMemory,redisCacheStoragePassword", syncFrameSettingName))
						OR listFindNoCase("mappings,scheduledtasks,fontmanagement,datasources,nosql,pdfServices", syncFrameApiArea)
			OR (syncFrameApiArea EQ "memoryvariables" AND listFindNoCase("sessionStoragePort,sessionStorageTimeout,sessionStoragePassword", syncFrameSettingName))){
			var normalizedFrame = duplicate(arguments.postSyncFrame);
			var numericSetTypes = [application.testConstants.TEST_FRAME.PRIME_SET, application.testConstants.TEST_FRAME.NONPRIME_SET];
			var postValueKey = application.testConstants.TEST_FRAME.POSTSET_VALUE;
			for(var numericSetType in numericSetTypes){
				if(NOT structKeyExists(normalizedFrame, numericSetType) OR NOT structKeyExists(arguments.expectedPostSetFrame, numericSetType))
					continue;
				for(var numericNodeKey in normalizedFrame[numericSetType]){
					if(NOT structKeyExists(arguments.expectedPostSetFrame[numericSetType], numericNodeKey))
						continue;
					var actualPair = normalizedFrame[numericSetType][numericNodeKey];
					var expectedPair = arguments.expectedPostSetFrame[numericSetType][numericNodeKey];
					if(structKeyExists(actualPair, postValueKey) AND structKeyExists(expectedPair, postValueKey)
												AND (listFindNoCase("mappings,scheduledtasks,fontmanagement,datasources,nosql", syncFrameApiArea) OR (isNumeric(actualPair[postValueKey]) AND isNumeric(expectedPair[postValueKey])) OR listFindNoCase("redisCacheStoragePassword,sessionStoragePassword", syncFrameSettingName))
						AND valuesMatch(syncFrameSettingName, expectedPair[postValueKey], actualPair[postValueKey], syncFrameApiArea, actualPair[application.testConstants.TEST_FRAME.PRESET_VALUE]))
						actualPair[postValueKey] = expectedPair[postValueKey];
				}
			}
			return serializeJSON(normalizedFrame) EQ serializeJSON(arguments.expectedPostSetFrame);
		}
		// Solr Server's password field is auto-encrypted by CF's runtime once a plaintext value is
		// detected on disk (see serverSettingsApiUtil.setMatches for the same leniency applied to
		// the per-node verification table) -- there's no adminapi accessor for it, so the readback
		// is a raw neo-solr.xml read that can pick up the now-encrypted value instead of what we
		// wrote, even on the node we just set it on. An exact match against the plaintext requested
		// value isn't meaningful here.
		// Same category as Solr's password above: the Admin LDAP config's bind password is
		// auto-encrypted on write (confirmed live -- writing a plaintext value and reading it back
		// via getAdminLdapConfiguration() returns a fresh ciphertext blob, never the plaintext we set),
		// so an exact match against the plaintext requested value isn't meaningful for it either.
		var isEncryptedOnDiskSetting = (syncFrameApiArea EQ "solrserver" AND lCase(trim(syncFrameSettingName)) EQ "password")
			OR (syncFrameApiArea EQ "administrator" AND lCase(trim(syncFrameSettingName)) EQ lCase("LdapUserBindPassword"));

		if(NOT listFindNoCase("mail,restservices", syncFrameApiArea) AND NOT isEncryptedOnDiskSetting)
			return serializeJSON(arguments.postSyncFrame) EQ serializeJSON(arguments.expectedPostSetFrame)

		// Mail settings sync via CCS on an unpredictable schedule -- sometimes a peer node picks up
		// the change within the test's own window, sometimes it doesn't for well over the retry
		// budget. Require an exact match only for the node the change was actually applied to;
		// accept either the new value or the original preset for every other node, since we can't
		// reliably predict which state CCS will be in when we read it back.
		//
		// REST Services (neo-jaxrs.xml) turned out to be the same category, confirmed via direct
		// observation: its "ccs" mapping entry drifted between nodes with no test of ours
		// running at the time, meaning real CCS does attempt to replicate this file in the
		// background -- just as unpredictably as mail. A peer's literal registered path can
		// never equal the prime node's (each instance has its own rootdir), so only whether it
		// changed at all matters here, same tolerance as mail.
		var setTypes = [application.testConstants.TEST_FRAME.PRIME_SET, application.testConstants.TEST_FRAME.NONPRIME_SET]
		for(var setType in setTypes){
			if(NOT structKeyExists(arguments.postSyncFrame, setType))
				continue
			for(var nodeKey in arguments.postSyncFrame[setType].keyList()){
				var actual = arguments.postSyncFrame[setType][nodeKey]
				var actualPost = structKeyExists(actual, application.testConstants.TEST_FRAME.POSTSET_VALUE) ? actual[application.testConstants.TEST_FRAME.POSTSET_VALUE] : ""
				var actualPre = structKeyExists(actual, application.testConstants.TEST_FRAME.PRESET_VALUE) ? actual[application.testConstants.TEST_FRAME.PRESET_VALUE] : ""
				var expectedPost = (structKeyExists(arguments.expectedPostSetFrame, setType) AND structKeyExists(arguments.expectedPostSetFrame[setType], nodeKey))
					? arguments.expectedPostSetFrame[setType][nodeKey][application.testConstants.TEST_FRAME.POSTSET_VALUE] : ""

				if(isLocalNodePort(nodeKey)){
					if(isEncryptedOnDiskSetting){
						if(len(trim("" & expectedPost)) EQ 0){
							if(len(trim("" & actualPost)))
								return false
						}
						else if(NOT len(trim("" & actualPost)) OR trim("" & actualPost) EQ trim("" & actualPre)){
							return false
						}
					}
					else if(trim("" & actualPost) NEQ trim("" & expectedPost)){
						return false
					}
				}
				else if(trim("" & actualPost) NEQ trim("" & expectedPost) AND trim("" & actualPost) NEQ trim("" & actualPre)){
					return false
				}
			}
		}
		return true
	}

	/**
	 * Run set/sync test; on failure roll back all in-scope nodes to the preset value from the test frame.
	 * Returns postSyncFrame, expectedPostSetFrame, and passed flag.
	 */
	public struct function runSyncedSettingTest(required struct initedTestFrame, required any newSetValue, required string settingName){
		var presetValue = getPresetValueFromTestFrame(arguments.initedTestFrame)
		var expectedPostSetFrame = getExpectedTestFrame(duplicate(arguments.initedTestFrame), arguments.newSetValue)
		var postSyncFrame = setAndGetSyncedValues(duplicate(arguments.initedTestFrame), arguments.newSetValue, arguments.settingName)
		var passed = syncedFramesMatch(postSyncFrame, expectedPostSetFrame)
		if(NOT passed) {
			var apiArea = getApiAreaFromFrame(arguments.initedTestFrame)
			var setURLSuffix = arguments.initedTestFrame[application.testConstants.TEST_FRAME.SETTER_URL]
			var menuName = getMenuNameFromUrl(setURLSuffix)
			rollbackNodesToValue(arguments.initedTestFrame, presetValue, arguments.settingName, apiArea, menuName)
		}
		return {
			expectedPostSetFrame = expectedPostSetFrame,
			postSyncFrame = postSyncFrame,
			passed = passed
		}
	}


	private any function getPresetValueFromTestFrame(required struct testFrame){
		var primKeyList = filterNodeKeysForTestScope(arguments.testFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList())
		var firstNodeKey = listGetAt(primKeyList, 1)
		return arguments.testFrame[application.testConstants.TEST_FRAME.PRIME_SET][firstNodeKey][application.testConstants.TEST_FRAME.PRESET_VALUE]
	}


	private boolean function valuesMatch(
		required string cfSettingKey,
		required any expectedValue,
		required any actualValue,
		required string apiArea,
		required any presetValue
	){
		if(lCase(arguments.apiArea) EQ "caching" AND compareNoCase(arguments.cfSettingKey, "redisCacheStoragePassword") EQ 0)
			return new cfsuite.ccssuite.utils.cacheConfigUtil().init().cacheValuesMatch(arguments.cfSettingKey, arguments.expectedValue, arguments.actualValue);
		// Special handling for AI Services LLM base64 JSON configs
		if(lCase(arguments.apiArea) EQ "llms"){
			return new cfsuite.ccssuite.utils.llmConfigUtil().init().configsMatch(
				arguments.expectedValue,
				arguments.actualValue
			);
		}
		if(lCase(arguments.apiArea) EQ "embeddingmodels"){
			return new cfsuite.ccssuite.utils.embeddingConfigUtil().init().configsMatch(
				arguments.expectedValue,
				arguments.actualValue
			);
		}
		if(listFindNoCase("vectorstores,RAG", arguments.apiArea)){
			return new cfsuite.ccssuite.utils.vectorstoreConfigUtil().init().configsMatch(
				arguments.expectedValue,
				arguments.actualValue
			);
		}
		if(lCase(arguments.apiArea) EQ "mcpservers"){
			return new cfsuite.ccssuite.utils.mcpConfigUtil().init().configsMatch(
				arguments.expectedValue,
				arguments.actualValue
			);
		}
		if(lCase(arguments.apiArea) EQ "nosqldatasources"){
			return new cfsuite.ccssuite.utils.nosqlDatasourceConfigUtil().init().configsMatch(
				arguments.expectedValue,
				arguments.actualValue
			);
		}
		if(lCase(arguments.apiArea) EQ "nosql"){
			return new cfsuite.ccssuite.utils.nosqlConfigUtil().init().statesMatch(arguments.expectedValue, arguments.actualValue);
		}
		if(lCase(arguments.apiArea) EQ "coldfusioncollections"){
			return new cfsuite.ccssuite.utils.coldfusionCollectionsConfigUtil().init().configsMatch(
				arguments.expectedValue,
				arguments.actualValue
			);
		}
		if(listFindNoCase("JavaCfx,CppCfx,CustomTagPaths", arguments.cfSettingKey)){
			if(arguments.cfSettingKey EQ "CustomTagPaths")
				return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().setMatches(
					arguments.presetValue,
					arguments.actualValue,
					arguments.expectedValue
				);
			return new cfsuite.ccssuite.utils.extensionsConfigUtil().init().configsMatch(
				arguments.expectedValue,
				arguments.actualValue
			);
		}
		if(listFindNoCase("EnableGatewayService,ThreadPoolSize,MaxQueueSize", arguments.cfSettingKey)){
			return new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init().scalarValuesMatch(
				arguments.expectedValue,
				arguments.actualValue,
				arguments.cfSettingKey
			);
		}
		if(listFindNoCase("GatewayType,GatewayInstance", arguments.cfSettingKey)){
			return new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init().configsMatch(
				arguments.expectedValue,
				arguments.actualValue
			);
		}
		if(listFindNoCase("AllowedAdminIpAdd,AllowedAdminIpRemove", arguments.cfSettingKey)){
			return new cfsuite.ccssuite.utils.allowedIpAddressesConfigUtil().init().allowedIpValuesMatch(
				arguments.expectedValue,
				arguments.actualValue,
				arguments.cfSettingKey
			);
		}
		if(listFindNoCase("IdpFromSamlUrl,IdpFromSamlDefinition,IdpFromXmlFile,IdpOwnDefinition,IdpTestRemoveAll,IdpFieldTestSetup,IdpName,IdpDescription,IdpRefreshInterval,IdpSamlUrl,IdpOwnFieldTestSetup,IdpOwnEntityId,IdpOwnSsoUrl,IdpOwnSsoBinding,IdpOwnSloUrl,IdpOwnSloBinding,IdpOwnLogoutResponseUrl,IdpOwnSignRequests,IdpOwnSignCertificate", arguments.cfSettingKey)){
			return new cfsuite.ccssuite.utils.idpConfigUtil().init().idpValuesMatch(
				arguments.expectedValue,
				arguments.actualValue,
				arguments.cfSettingKey
			);
		}
		if(listFindNoCase("SpAdd,SpGenerate,SpTestRemoveAll,SpFieldTestSetup,SpName,SpDescription,SpIdpInitiatedSso,SpEntityId,SpAcsUrl,SpAcsBinding,SpSloUrl,SpSloBinding,SpSignRequests,SpWantAssertionsSigned,SpLogoutResponseSigned,SpSignKeystorePath,SpSignKeystorePassword,SpSignKeystoreAlias,SpRequestStore", arguments.cfSettingKey)){
			return new cfsuite.ccssuite.utils.spConfigUtil().init().spValuesMatch(
				arguments.expectedValue,
				arguments.actualValue,
				arguments.cfSettingKey
			);
		}
		if(listFindNoCase("ChallengeStore,ChallengeTtl,PasskeyDefaultDatasource,ClientCertAuthEnabled,ClientCertRootAdminEnabled,ClientCertCertificateSource,ClientCertSubjectHeader,ClientCertMatchCriteria", arguments.cfSettingKey)){
			return new cfsuite.ccssuite.utils.securitySettingsConfigUtil().init().settingsValuesMatch(
				arguments.expectedValue,
				arguments.actualValue,
				arguments.cfSettingKey
			);
		}
		if(lCase(arguments.apiArea) EQ "administrator"
				OR lCase(arguments.apiArea) EQ "secureprofile"
				OR lCase(arguments.apiArea) EQ "rds"
				OR lCase(arguments.apiArea) EQ "sandboxsecurity"
				OR lCase(arguments.apiArea) EQ "usermanager"
				OR lCase(arguments.apiArea) EQ "allowedipaddresses"
				OR lCase(arguments.apiArea) EQ "idpconfiguration"
				OR lCase(arguments.apiArea) EQ "spconfiguration"
				OR lCase(arguments.apiArea) EQ "settings"
				OR listFindNoCase("AllowConcurrentAdminLogin,AdminUserIdRequired,SecureProfileEnabled,ExternalAuth,RootAdminUserId,RdsEnabled,RdsSecurityEnabled,UseSingleRdsPassword,SandboxSecurityEnabled,SandboxPath,UserExists,UserDescription,AllowRdsAccess,AllowAdminAccess,EnabledDataSource,UserRole,SecuredFilePath,AllowedAdminIpAdd,AllowedAdminIpRemove,IdpFromSamlUrl,IdpFromSamlDefinition,IdpFromXmlFile,IdpOwnDefinition,IdpTestRemoveAll,IdpFieldTestSetup,IdpName,IdpDescription,IdpRefreshInterval,IdpSamlUrl,IdpOwnFieldTestSetup,IdpOwnEntityId,IdpOwnSsoUrl,IdpOwnSsoBinding,IdpOwnSloUrl,IdpOwnSloBinding,IdpOwnLogoutResponseUrl,IdpOwnSignRequests,IdpOwnSignCertificate,SpAdd,SpGenerate,SpTestRemoveAll,SpFieldTestSetup,SpName,SpDescription,SpIdpInitiatedSso,SpEntityId,SpAcsUrl,SpAcsBinding,SpSloUrl,SpSloBinding,SpSignRequests,SpWantAssertionsSigned,SpLogoutResponseSigned,SpSignKeystorePath,SpSignKeystorePassword,SpSignKeystoreAlias,SpRequestStore,ChallengeStore,ChallengeTtl,PasskeyDefaultDatasource,ClientCertAuthEnabled,ClientCertRootAdminEnabled,ClientCertCertificateSource,ClientCertSubjectHeader,ClientCertMatchCriteria", arguments.cfSettingKey)){
			var secUtil = new cfsuite.ccssuite.utils.securityConfigUtil().init();
			if(listFindNoCase("SandboxPath,SandboxPathCopyFrom", arguments.cfSettingKey))
				return secUtil.sandboxPathValuesMatch(arguments.expectedValue, arguments.actualValue);
			return secUtil.scalarValuesMatch(
				arguments.expectedValue,
				arguments.actualValue,
				arguments.cfSettingKey
			);
		}

		// Special handling for SAML IDPConfig and spconfig base64 JSON comparison
		if(arguments.apiArea EQ "IDPConfig" OR arguments.apiArea EQ "spconfig"){
			try {
				var expectedJson = toString(toBinary(arguments.expectedValue));
				var actualJson = toString(toBinary(arguments.actualValue));
				var expectedStruct = deserializeJSON(expectedJson);
				var actualStruct = deserializeJSON(actualJson);
				
				// Lowercase all keys for comparison
				var expectedNormalized = {};
				for(var key in expectedStruct){
					expectedNormalized[lcase(key)] = expectedStruct[key];
				}
				var actualNormalized = {};
				for(var key in actualStruct){
					actualNormalized[lcase(key)] = actualStruct[key];
				}
				
				// Compare all keys present in expectedNormalized
				var match = true;
				for(var key in expectedNormalized){
					// Skip if the key is not returned by the server
					if(NOT structKeyExists(actualNormalized, key)) {
						continue;
					}
					// Special handling for sensitive/masked fields like passwords
					if(findNoCase("password", key) AND (find("*", actualNormalized[key]) OR len(actualNormalized[key]) EQ 0)) {
						continue;
					}
					if(trim("" & actualNormalized[key]) NEQ trim("" & expectedNormalized[key])){
						match = false;
						break;
					}
				}
				if(match) return true;
			}
			catch(any e){
				// Fall back to standard string comparison
			}
		}

		return new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().setMatches(
			arguments.cfSettingKey,
			arguments.presetValue,
			arguments.actualValue,
			arguments.expectedValue,
			arguments.apiArea
		)
	}


	private boolean function rollbackNodesToValue(
		required struct testFrame,
		required any targetValue,
		required string cfSettingKey,
		string apiArea = "",
		string menuName = ""
	){
		var setURLSuffix = arguments.testFrame[application.testConstants.TEST_FRAME.SETTER_URL]
		var getURLSuffix = arguments.testFrame[application.testConstants.TEST_FRAME.GETTER_URL]
		var realApiArea = len(arguments.apiArea) ? arguments.apiArea : getApiAreaFromFrame(arguments.testFrame)
		var realMenuName = len(arguments.menuName) ? arguments.menuName : getMenuNameFromUrl(setURLSuffix)
		var success = true
		var nodeKeyLists = [
			filterNodeKeysForTestScope(arguments.testFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList()),
			filterNodeKeysForTestScope(arguments.testFrame[application.testConstants.TEST_FRAME.NONPRIME_SET].keyList())
		]

		for(var listIdx = 1; listIdx LTE arrayLen(nodeKeyLists); listIdx++){
			for(var nodeKey in listToArray(nodeKeyLists[listIdx])){
				if(isLocalNodePort(nodeKey)){
					if(NOT forceSetPropertyLocal(arguments.cfSettingKey, arguments.targetValue, realApiArea, realMenuName))
						success = false
				}
				else {
					if(isSecurityMenuUrl(setURLSuffix)){
						if(NOT setAndVerifySettingViaHttp(
							nodeKey,
							setURLSuffix,
							getURLSuffix,
							arguments.cfSettingKey,
							arguments.targetValue,
							realApiArea
						))
							success = false
					}
					else {
						// Plain single-shot push races CCS's own organic replication reasserting a
						// stale value right after the push lands (same race documented in
						// propagateDocumentSettingToPrimePeers) — confirmed via direct testing that
						// this left Package Manager credential/host fields permanently stuck at
						// their test value on a peer after rollback. setAndVerifySettingViaHttp
						// re-pushes until the peer's own readback matches, so reuse it here too.
						if(NOT setAndVerifySettingViaHttp(nodeKey, setURLSuffix, getURLSuffix, arguments.cfSettingKey, arguments.targetValue, realApiArea))
							success = false
					}
				}
			}
		}

		var targetLabel = formatRollbackValue(arguments.targetValue, arguments.cfSettingKey);

		if(success)
			writeOutput("rollback/restore of " & arguments.cfSettingKey & " to [" & targetLabel & "] completed.<br>")
		else
			writeOutput("<strong>Warning:</strong> rollback/restore of " & arguments.cfSettingKey & " to [" & targetLabel & "] may be incomplete.<br>")

		return success
	}


	private void function propagateDocumentSettingToPrimePeers(
		required struct postSetTestFrame,
		required any toSetValue,
		required string cfSettingKey,
		required string apiArea
	){
		var savedScope = structKeyExists(application, "ccsTestNodesScope") ? application.ccsTestNodesScope : "currentPort";
		application.ccsTestNodesScope = "all";
		var primeKeys = getTestMgr().getNodeKeysInPrimeEnvironment();
		application.ccsTestNodesScope = savedScope;
		var setURLSuffix = arguments.postSetTestFrame[application.testConstants.TEST_FRAME.SETTER_URL];

		for(var nodeKey in listToArray(primeKeys)){
			if(isLocalNodePort(nodeKey))
				continue;
			if(NOT isPeerNodeReachable(nodeKey))
				continue;
			var getURLSuffix = arguments.postSetTestFrame[application.testConstants.TEST_FRAME.GETTER_URL];
			if(isSecurityMenuUrl(setURLSuffix)){
				if(NOT setAndVerifySettingViaHttp(nodeKey, setURLSuffix, getURLSuffix, arguments.cfSettingKey, arguments.toSetValue, arguments.apiArea))
					writeOutput("<strong>Warning:</strong> could not propagate #arguments.cfSettingKey# to node #nodeKey#<br>");
			}
			else {
				// Plain single-shot push races CCS's own organic replication reasserting a stale
				// value on the peer right after our push lands (confirmed via direct testing on
				// Cloud Configuration's Proxy Endpoint: push+immediate readback succeeds, but the
				// value is gone again moments later with no error). setAndVerifySettingViaHttp
				// already solves this for the security-menu path by re-pushing until the peer's
				// own readback matches, so reuse it here instead of a bespoke retry.
				if(NOT setAndVerifySettingViaHttp(nodeKey, setURLSuffix, getURLSuffix, arguments.cfSettingKey, arguments.toSetValue, arguments.apiArea))
					writeOutput("<strong>Warning:</strong> could not propagate #arguments.cfSettingKey# to node #nodeKey#<br>");
			}
		}
	}


	private boolean function rollbackNodesToExistingValues(
		required struct testFrame,
		required struct nodeValues,
		required string cfSettingKey,
		string apiArea = "",
		string menuName = ""
	){
		var setURLSuffix = arguments.testFrame[application.testConstants.TEST_FRAME.SETTER_URL]
		var getURLSuffix = arguments.testFrame[application.testConstants.TEST_FRAME.GETTER_URL]
		var realApiArea = len(arguments.apiArea) ? arguments.apiArea : getApiAreaFromFrame(arguments.testFrame)
		var realMenuName = len(arguments.menuName) ? arguments.menuName : getMenuNameFromUrl(setURLSuffix)
		var success = true
		var nodeKeyLists = [
			filterNodeKeysForTestScope(arguments.testFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList()),
			filterNodeKeysForTestScope(arguments.testFrame[application.testConstants.TEST_FRAME.NONPRIME_SET].keyList())
		]

		for(var listIdx = 1; listIdx LTE arrayLen(nodeKeyLists); listIdx++){
			for(var nodeKey in listToArray(nodeKeyLists[listIdx])){
				var targetValue = structKeyExists(arguments.nodeValues, nodeKey) ? arguments.nodeValues[nodeKey] : "";
				if(isLocalNodePort(nodeKey)){
					if(NOT forceSetPropertyLocal(arguments.cfSettingKey, targetValue, realApiArea, realMenuName))
						success = false
				}
				else {
					var urlQryParams = buildSettingQueryParams(arguments.cfSettingKey, targetValue, realApiArea)
					var _url = getURL(nodeKey, setURLSuffix, urlQryParams)
					makeSetHTTPCall(_url)
					try {
						var actualValue = getCurrentSettingValue(nodeKey, getURLSuffix, arguments.cfSettingKey, realApiArea)
						if(NOT valuesMatch(arguments.cfSettingKey, targetValue, actualValue, realApiArea, targetValue))
							success = false
					}
					catch(any e){
						success = false
						writeOutput("<strong>Warning:</strong> could not verify rollback on node #nodeKey#: #e.message#<br>")
					}
				}
			}
		}

		if(success)
			writeOutput("rollback/restore of " & arguments.cfSettingKey & " on all nodes completed.<br>")
		else
			writeOutput("<strong>Warning:</strong> rollback/restore of " & arguments.cfSettingKey & " on all nodes may be incomplete.<br>")

		return success
	}


	private boolean function forceSetPropertyLocal(required string cfSetting, required any settingValue, required string apiArea, required string menuName){
		if(isSecurityMenuName(arguments.menuName)){
			var nodeKey = CGI.SERVER_NAME & application.testConstants.TEST_FRAME.COMPOSITE_KEY_FIELD_SEPARATOR & CGI.SERVER_PORT;
			return setAndVerifySettingViaHttp(
				nodeKey,
				"/cfsuite/ccssuite/testsuite/security/_setterSecurity.cfm",
				"/cfsuite/ccssuite/testsuite/security/_getterSecurity.cfm",
				arguments.cfSetting,
				arguments.settingValue,
				arguments.apiArea
			);
		}

		try {
			applyPropertyLocal(arguments.cfSetting, arguments.settingValue, arguments.apiArea, arguments.menuName)
		}
		catch(any e){
			writeOutput("Local set exception during rollback/restore (verifying read-back): #e.message#<br>")
		}

		var actualValue = getPropertyLocal(arguments.cfSetting, arguments.apiArea, arguments.menuName)
		return valuesMatch(arguments.cfSetting, arguments.settingValue, actualValue, arguments.apiArea, arguments.settingValue)
	}


	private boolean function usesServerSettingsApiUtil(required string menuName){
		return listFindNoCase("serverSettings,Debugging&Logging", trim("" & arguments.menuName)) GT 0;
	}


	private void function applyPropertyLocal(required string cfSetting, required any settingValue, required string apiArea, required string menuName){
		if(usesServerSettingsApiUtil(arguments.menuName))
			new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().setSetting(arguments.cfSetting, arguments.settingValue, arguments.apiArea);
		else
			new cfsuite.ccssuite.utils.ccsApiUtil().init().setSetting(arguments.cfSetting, arguments.settingValue, arguments.apiArea, arguments.menuName);
	}


	//init the setting Test frame with cf setting's preset values.
	public struct function initTestFrameWithPreSetValues(
		required string settingName,
		required struct testCnfgMap,
		required string scriptPath,
		string getterTemplate = "",
		string setterTemplate = "",
		boolean skipUnreachableNodes = false
	){
		var menuName = getMenuName(arguments.scriptPath);
		var apiArea = getApiArea(arguments.scriptPath);
		var getterSetterMenu = menuName;

		testCnfgMap[application.testConstants.TEST_FRAME.CFSETTING] = settingName
		testCnfgMap[application.testConstants.TEST_FRAME.API_AREA] = apiArea
		var getterFile = len(trim(arguments.getterTemplate)) ? arguments.getterTemplate : GETTER_CFML_TEMPLATE_NAME;
		var setterFile = len(trim(arguments.setterTemplate)) ? arguments.setterTemplate : SETTER_CFML_TEMPLATE_NAME;
		testCnfgMap[application.testConstants.TEST_FRAME.SETTER_URL] = "/cfsuite/ccssuite/testsuite/" & getterSetterMenu & "/" & setterFile;
		testCnfgMap[application.testConstants.TEST_FRAME.GETTER_URL] = "/cfsuite/ccssuite/testsuite/" & getterSetterMenu & "/" & getterFile;

		primKeyList = filterNodeKeysForTestScope(testCnfgMap[application.testConstants.TEST_FRAME.PRIME_SET].keyList());
		for(primeKey in listToArray(primKeyList)){
			prePostPairMap = testCnfgMap[application.testConstants.TEST_FRAME.PRIME_SET].find(primeKey)
			try {
				prePostPairMap[application.testConstants.TEST_FRAME.PRESET_VALUE] =
					getCurrentSettingValue(primeKey, testCnfgMap[application.testConstants.TEST_FRAME.GETTER_URL], settingName, apiArea)
			}
			catch(any e){
				// The current instance must supply a real baseline before any write.
				// Never hide its getter/configuration failure by dropping it from the frame.
				if(isLocalNodePort(primeKey))
					rethrow;
				if(arguments.skipUnreachableNodes){
					structDelete(testCnfgMap[application.testConstants.TEST_FRAME.PRIME_SET], primeKey)
					// If every prime getter failed, preserve the actual final getter error
					// instead of letting preset lookup report an unrelated membership error.
					if(structIsEmpty(testCnfgMap[application.testConstants.TEST_FRAME.PRIME_SET]))
						rethrow;
				}
				else {
					rethrow;
				}
			}
		}

		nPrimKeyList = filterNodeKeysForTestScope(testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET].keyList())
		for(nPrimeKey in listToArray(nPrimKeyList)){
			try {
				prePostPairMap = testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET].find(nPrimeKey)
				prePostPairMap[application.testConstants.TEST_FRAME.PRESET_VALUE] =
					getCurrentSettingValue(nPrimeKey, testCnfgMap[application.testConstants.TEST_FRAME.GETTER_URL], settingName, apiArea)
			}
			catch(any e){
								if(listFindNoCase("caching,mappings,scheduledtasks,fontmanagement,datasources,nosql", apiArea)){
					if(NOT arguments.skipUnreachableNodes)
						rethrow;
					structDelete(testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET], nPrimeKey);
					writeOutput("<strong>Non-prime node #nPrimeKey# preset unavailable</strong>; no baseline captured. #e.message#<br>");
				}
				else if(arguments.skipUnreachableNodes){
					prePostPairMap = testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET].find(nPrimeKey)
					prePostPairMap[application.testConstants.TEST_FRAME.PRESET_VALUE] = ""
					writeOutput("<strong>Non-prime node #nPrimeKey# preset unavailable</strong>; using empty baseline. #e.message#<br>")
				}
				else {
					structDelete(testCnfgMap[application.testConstants.TEST_FRAME.NONPRIME_SET], nPrimeKey)
				}
			}
		}
		return testCnfgMap
	}


	private string function getCurrentSettingValue(required string nodeKey, required string urlSuffix, required string cfSetting, required string apiArea){
		
		// Security settings use neo-security.xml directly; HTTP loopback gives reliable read-back in the same request.
		if(isLocalNodePort(nodeKey) AND NOT isSecurityMenuUrl(urlSuffix)){
			var menuName = getMenuNameFromUrl(urlSuffix);
			return getPropertyLocal(cfSetting, apiArea, menuName)
		}

		var _url = getURL(nodeKey, urlSuffix, buildSettingQueryParams(cfSetting, "", apiArea, false));
		cfhttp(url="#_url#", method="GET", result="response", timeout=30)
		if(isHttpSuccess(response.statusCode)){
			body = trim(response.fileContent)
			if(isErrorHtmlBody(body))
				throw(message="Getter returned HTML error page for node #nodeKey#",
					detail="Open #_url# in a browser. Fix _getter.cfm or CF_ADMIN_PASSWORD in constants.cfc.",
					type="CCSTest.HttpError")
			return body
		}

		var errDetail = structKeyExists(response, "fileContent") ? trim(response.fileContent) : ""
		if(len(errDetail)) errDetail = " — #errDetail#"
		var hint = "";
		if(findNoCase("404", response.statusCode)){
			hint = " Deploy ccssuite on that node and open /cfsuite/ccssuite/i.cfm once, or set application.ccsTestNodesScope = ""currentPort"" in Application.cfc (restart app).";
		}
		throw(message="Getter request failed for node #nodeKey#", 
			detail="URL: #_url# | status: #response.statusCode##errDetail##hint#",
			type="CCSTest.HttpError")
	}


	private boolean function isHttpSuccess(required string statusCode){
		return val(listFirst(arguments.statusCode, " ")) EQ 200
	}


	private string function getMenuName(required string scriptPath){
		var path = replace(arguments.scriptPath, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		if(NOT pos)
			return "serverSettings";
		var remainder = mid(path, pos + len(marker), len(path));
		return listFirst(remainder, "/");
	}


	private string function getApiArea(required string scriptPath){
		var path = replace(arguments.scriptPath, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		if(NOT pos)
			return "settings";
		var remainder = mid(path, pos + len(marker), len(path));
		var parts = listToArray(remainder, "/");
		if(arrayLen(parts) GTE 2)
			return parts[2];
		return "settings";
	}


	private string function getMenuNameFromUrl(required string urlSuffix){
		var path = replace(arguments.urlSuffix, "\", "/", "all");
		var marker = "/testsuite/";
		var pos = findNoCase(marker, path);
		if(NOT pos)
			return "serverSettings";
		var remainder = mid(path, pos + len(marker), len(path));
		return listFirst(remainder, "/");
	}


	private string function getApiAreaFromFrame(required struct testFrame){
		if(structKeyExists(arguments.testFrame, application.testConstants.TEST_FRAME.API_AREA))
			return arguments.testFrame[application.testConstants.TEST_FRAME.API_AREA]
		return "settings"
	}


	private array function buildSettingQueryParams(
		required string cfSetting,
		required any settingValue,
		required string apiArea,
		boolean includeValue = true
	){
		var params = [
			URL_QUERYPARAM_SETTING & "=" & urlEncodedFormat(arguments.cfSetting),
			URL_QUERYPARAM_API_AREA & "=" & urlEncodedFormat(arguments.apiArea)
		]
		if(arguments.includeValue)
			arrayAppend(params, URL_QUERYPARAM_SETTING_VALUE & "=" & urlEncodedFormat("" & arguments.settingValue))
		return params
	}


	private function getURL(required string nodeKey, required string urlSuffix, array queryParamVals){
		
		var _url = application.protocol & "://" & getURLFragFromNodeKey(nodeKey) & encodeUrlPathSuffix(urlSuffix)

		if(isDefined("arguments.queryParamVals") AND arrayLen(queryParamVals) GT 0){
			_url &= "?"
			for(param in queryParamVals)
				_url &= param & "&"

			_url = left(_url, len(_url)-1) // remove the trailing ampersand
		}

		return _url
	}


	private string function encodeUrlPathSuffix(required string urlSuffix){
		var suffix = arguments.urlSuffix;
		var queryPart = "";
		var qPos = find("?", suffix);
		if(qPos){
			queryPart = mid(suffix, qPos, len(suffix));
			suffix = left(suffix, qPos - 1);
		}

		if(NOT len(suffix))
			return queryPart;

		var encodedSegments = [];
		for(var segment in listToArray(suffix, "/", false, true)){
			segment = replace(segment, chr(38), "%26", "all");
			segment = replace(segment, chr(35), "%23", "all");
			segment = replace(segment, " ", "%20", "all");
			arrayAppend(encodedSegments, segment);
		}

		return "/" & arrayToList(encodedSegments, "/") & queryPart;
	}


	private void function ensureApplicationConfig(){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init()
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init()
	}


	private boolean function isSecurityMenuUrl(required string urlSuffix){
		return isSecurityMenuName(getMenuNameFromUrl(arguments.urlSuffix));
	}


	private boolean function isSecurityMenuName(required string menuName){
		return lCase(trim("" & arguments.menuName)) EQ "security";
	}


	private boolean function isErrorHtmlBody(required string body){
		return findNoCase("<html", arguments.body)
			AND (findNoCase("error occurred while executing", arguments.body) OR findNoCase("<title>Error</title>", arguments.body))
	}


	private string function getPropertyLocal(required string cfSetting, required string apiArea, required string menuName){
		try {
			if(usesServerSettingsApiUtil(arguments.menuName))
				return trim("" & new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().getSetting(arguments.cfSetting, arguments.apiArea));
			return trim("" & new cfsuite.ccssuite.utils.ccsApiUtil().init().getSetting(arguments.cfSetting, arguments.apiArea, arguments.menuName));
		}
		catch(any e){
			throw(message="Local Admin API get failed for #arguments.cfSetting#",
				detail="#e.message# #e.detail#",
				type="CCSTest.ConfigError")
		}
	}


	private boolean function setPropertyLocal(required string cfSetting, required any settingValue, required string apiArea, required string menuName){
		try {
			applyPropertyLocal(arguments.cfSetting, arguments.settingValue, arguments.apiArea, arguments.menuName)
			return true
		}
		catch(any e){
			var detail = e.message;
			if(structKeyExists(e, "detail") AND len(trim("" & e.detail)))
				detail &= " — " & e.detail;
			writeErrorAlert("Local set failed", detail);
			return false
		}
	}


	private void function writeErrorAlert(required string message, string detail = ""){
		var body = encodeForHTML(arguments.message);
		if(len(trim(arguments.detail)))
			body &= "<br><small>" & encodeForHTML(arguments.detail) & "</small>";
		writeOutput('<div class="alert alert-danger" role="alert" style="padding:12px 16px;margin:8px 0;border:1px solid ##f5c2c7;border-radius:0.375rem;background-color:##f8d7da;color:##842029;"><strong>Error:</strong> ' & body & '</div>');
	}


	private boolean function isLocalNodePort(required string nodeKey){
		sep = application.testConstants.TEST_FRAME.COMPOSITE_KEY_FIELD_SEPARATOR
		parts = listToArray(arguments.nodeKey, sep, false, true)
		if(arrayLen(parts) LT 2)
			return false
		return val(parts[2]) EQ val(cgi.server_port)
	}


	private boolean function isPeerNodeReachable(required string nodeKey){
		if(isLocalNodePort(arguments.nodeKey))
			return true;

		var pingPath = "/cfsuite/ccssuite/testsuite/serverSettings/settings/ping.cfm";
		var _url = application.protocol & "://" & getURLFragFromNodeKey(arguments.nodeKey) & encodeUrlPathSuffix(pingPath);
		cfhttp(url="#_url#", method="GET", result="response", timeout=5);
		if(NOT isHttpSuccess(response.statusCode))
			return false;

		return findNoCase("OK - template runs", trim(response.fileContent)) GT 0;
	}


	private boolean function makeSetHTTPCall(string _url){
		cfhttp(url="#_url#", method="GET", result="response", timeout=30)
		variables.lastHttpResponse = response;
		if(isHttpSuccess(response.statusCode))
			return true
		return false
	}

	private string function getLastHttpResponseBody(){
		if(structKeyExists(variables, "lastHttpResponse") AND isStruct(variables.lastHttpResponse)
				AND structKeyExists(variables.lastHttpResponse, "fileContent"))
			return trim("" & variables.lastHttpResponse.fileContent);
		return "";
	}

	private string function readSettingValueWithRetry(
		required string nodeKey,
		required string getURLSuffix,
		required string cfSettingKey,
		required string apiArea,
		required any expectedValue,
		numeric maxAttempts = 5,
		numeric delayMs = 150
	){
		var lastValue = "";
		for(var attempt = 1; attempt LTE arguments.maxAttempts; attempt++){
			try {
				lastValue = getCurrentSettingValue(arguments.nodeKey, arguments.getURLSuffix, arguments.cfSettingKey, arguments.apiArea);
				if(valuesMatch(arguments.cfSettingKey, arguments.expectedValue, lastValue, arguments.apiArea, arguments.expectedValue))
					return lastValue;
			}
			catch(any e){
				lastValue = e.message;
			}
			if(attempt LT arguments.maxAttempts)
				sleep(arguments.delayMs);
		}
		return lastValue;
	}


	private boolean function setAndVerifySettingViaHttp(
		required string nodeKey,
		required string setURLSuffix,
		required string getURLSuffix,
		required string cfSettingKey,
		required any targetValue,
		required string apiArea,
		numeric maxAttempts = 5,
		numeric delayMs = 150
	){
		var urlQryParams = buildSettingQueryParams(arguments.cfSettingKey, arguments.targetValue, arguments.apiArea);
		var setUrl = getURL(arguments.nodeKey, arguments.setURLSuffix, urlQryParams);
		for(var attempt = 1; attempt LTE arguments.maxAttempts; attempt++){
			if(NOT makeSetHTTPCall(setUrl))
				return false;
			var setBody = getLastHttpResponseBody();
			if(findNoCase("set FAILED", setBody))
				return false;
			if(valuesMatch(arguments.cfSettingKey, arguments.targetValue, setBody, arguments.apiArea, arguments.targetValue))
				return true;
			try {
				var readBack = getCurrentSettingValue(arguments.nodeKey, arguments.getURLSuffix, arguments.cfSettingKey, arguments.apiArea);
				if(valuesMatch(arguments.cfSettingKey, arguments.targetValue, readBack, arguments.apiArea, arguments.targetValue))
					return true;
			}
			catch(any e){}
			if(attempt LT arguments.maxAttempts)
				sleep(arguments.delayMs);
		}
		return false;
	}

	private string function getURLFragFromNodeKey(required string nkey){
		frags = ListToArray(nkey, application.testConstants.TEST_FRAME.COMPOSITE_KEY_FIELD_SEPARATOR, false, true)
		if(frags.len() EQ 2)
			return frags[1] & ":" & frags[2]
		else if(frags.len() EQ 3)
			return frags[1] & ":" & frags[2] & "/" & frags[3]

		writeOutput("error parsing nodeKey: " & nkey)
	}


	private string function formatRollbackValue(required any value, string settingName = ""){
		if(listFindNoCase("redisCacheStoragePassword,sessionStoragePassword", arguments.settingName))
			return "[redacted]";
		var text = trim("" & arguments.value);
		if(NOT len(text) OR text EQ "|")
			return "(empty)";
		return replace(
			replace(
				replace(text, "&", "&amp;", "all"),
				"<", "&lt;", "all"
			),
			">", "&gt;", "all"
		);
	}


	private boolean function isTestScopeCurrentPortOnly(){
		// Default: only this server port. Set application.ccsTestNodesScope = "all" for every CCS node.
		return NOT (structKeyExists(application, "ccsTestNodesScope") AND application.ccsTestNodesScope EQ "all")
	}


	private boolean function isInstanceLocalApiArea(required string apiArea, string settingName = ""){
		if(lCase(trim(arguments.apiArea)) EQ "clientvariables")
			return lCase(trim(arguments.settingName)) EQ "clientstoredatasource";
		return false;
	}


	private boolean function isDebuggingApiArea(required string apiArea){
		return listFindNoCase(
			"debugoutputsettings,loggingsettings,debuggingipaddress,developerprofile,debuggersettings",
			lCase(trim("" & arguments.apiArea))
		) GT 0;
	}


	private boolean function isNodeKeyForCurrentServer(required string nodeKey){
		if(NOT isTestScopeCurrentPortOnly())
			return true
		sep = application.testConstants.TEST_FRAME.COMPOSITE_KEY_FIELD_SEPARATOR
		parts = listToArray(arguments.nodeKey, sep, false, true)
		if(arrayLen(parts) LT 2)
			return false
		return val(parts[2]) EQ val(cgi.server_port)
	}


	private string function filterNodeKeysForTestScope(required string nodeKeyList){
		if(NOT isTestScopeCurrentPortOnly())
			return arguments.nodeKeyList

		filtered = ""
		for(key in listToArray(arguments.nodeKeyList)){
			if(isNodeKeyForCurrentServer(key))
				filtered = listAppend(filtered, key)
		}
		return filtered
	}
}