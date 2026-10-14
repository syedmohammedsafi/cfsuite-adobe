/**
*
* @file  /E/CFGronckleBuilds/fortunaNx/cfusion/wwwroot/cfsuite/ccssuite/testManager.cfc
* @author  pnayak 15/05/24
* @description init f/w w/ node config info to orchestrate the tests 
*
*/

component output="false" displayname=""  {

	public function init(){
		this.ccsdriver = new cfsuite.ccssuite.ccsDriver();
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
		this.KEY_INFX_SEPERATOR = application.testConstants.TEST_FRAME["COMPOSITE_KEY_FIELD_SEPARATOR"];
		return this;
	}

	public numeric function setAndGetPrimeNodeIndex(numeric index=1){
		ccsNodesArray = this.ccsdriver.getCCSConfigMapList();
		if(arrayLen(ccsNodesArray) EQ 0)
			return 0;
		if(isDefined ("arguments.index") AND arguments.index GTE 1 AND arguments.index LTE arrayLen(ccsNodesArray))
			randNodeIndex = index
		else
			randNodeIndex = randrange(1, arrayLen(ccsNodesArray))
		cflog(type="information", application=true, file="#application.applicationname#", 
			text="testManager.getPrimeNodeKey : node index randomly selected - #randNodeIndex#")

		return randNodeIndex;
	}


	public function getPrimeNodeKey(){
		primeNodeConfigStruct = getNodeConfigByIndex(application.primeNodeIndex)
		return getNodeKeyNameFromNodeConfig(primeNodeConfigStruct);
	}


	public struct function getNodeConfigByIndex(required numeric index){
		ccsNodeArray = this.ccsdriver.getCCSConfigMapList();
		if(arrayLen(ccsNodeArray) GTE index)
			if(isStruct(ccsNodeArray[index]))
				return ccsNodeArray[index]

		cflog(type="error", application=true, file="#application.applicationname#", text="testManager.getNodeKeyByIndex : error getting node from list")
		try{
			cflog(type="debug", application=true, file="#application.applicationname#", text=serializeJSON(ccsNodesArray))
		}catch(any e){
			//swallow
		}
		return {};
	}


	public string function getNodeKeyNameFromNodeConfig(required struct nodeConfig){

		//cfdump(var=nodeConfig, label="testManager.getNodeKeyNameFromNodeConfig()");
		if(NOT isStruct(nodeConfig) OR structIsEmpty(nodeConfig)
				OR NOT structKeyExists(nodeConfig, application.constants.CCS_CONFIG.HOSTNAME)
				OR NOT structKeyExists(nodeConfig, application.constants.CCS_CONFIG.PORT)){
			return "";
		}
		keyName = nodeConfig[application.constants.CCS_CONFIG.HOSTNAME] & this.KEY_INFX_SEPERATOR &
				nodeConfig[application.constants.CCS_CONFIG.PORT] 
		if(structKeyExists(nodeConfig, application.constants.CCS_CONFIG.JEE_CONTEXT)
				AND nodeConfig[application.constants.CCS_CONFIG.JEE_CONTEXT].trim() NEQ "")
			keyName = keyName & this.KEY_INFX_SEPERATOR & nodeConfig[application.constants.CCS_CONFIG.JEE_CONTEXT] 

		return keyName;
	}


	public struct function getCCSConfigMap(){
		
		ccsNodeList = this.ccsdriver.getCCSConfigMapList();
		return getCCSConfigMapFromList(ccsNodeList);
	}


	public struct function getCCSConfigMapFromList(required array ccsNodeList){
		//cfdump(var=ccsNodeList, label="testManager.getCCSConfigMap()");
		
		ccsNodeCnfgMap = structNew();
		for(n=1; n LTE arrayLen(ccsNodeList); n++){
			keyName = getNodeKeyNameFromNodeConfig(ccsNodeList[n])
			//writeoutput("keyname:  " & keyName )
			nodeCnfg = {
						"#application.constants.CCS_CONFIG.CLUSTER#" : ccsNodeList[n][application.constants.CCS_CONFIG.CLUSTER],
						"#application.constants.CCS_CONFIG.ENVIRONMENT#" : ccsNodeList[n][application.constants.CCS_CONFIG.ENVIRONMENT],
						"#application.constants.CCS_CONFIG.HOSTNAME#" : ccsNodeList[n][application.constants.CCS_CONFIG.HOSTNAME],
						"#application.constants.CCS_CONFIG.PORT#" : ccsNodeList[n][application.constants.CCS_CONFIG.PORT],
						"#application.constants.CCS_CONFIG.CURRENT_VERSION#" : ccsNodeList[n][application.constants.CCS_CONFIG.CURRENT_VERSION],
						"#application.constants.CCS_CONFIG.ENABLED#" : ccsNodeList[n][application.constants.CCS_CONFIG.ENABLED],
						"#application.constants.CCS_CONFIG.JEE_CONTEXT#" : ccsNodeList[n][application.constants.CCS_CONFIG.JEE_CONTEXT]
					}
			ccsNodeCnfgMap.insert(keyName, nodeCnfg)
		}
		return ccsNodeCnfgMap;
	}


	public struct function getNodeConfigMapFromNodeKey(required String key){
		if(key.trim() NEQ "" AND application.ccsConfigMap.keyExists(key))
			return application.ccsConfigMap.find(key);

		writeOutput("error getting node config with node key : #key# <br>")
		return;
	}


	public struct function getPrimeNodeConfig(){
		return application.ccsConfigMap.find(application.primeNodeKey);
	}


	public string function getPrimeNodeEnvironment(){
		return getEnvironmentFromConfigMap(this.getPrimeNodeConfigMap());
	}

	public struct function getPrimeNodeConfigMap(){
		return application.ccsConfigMap.find(application.primeNodeKey);
	}

	public string function getNodeKeyListInEnvironment(required string cluster, required string env){
	
		nodeConfigMapList = application.ccsConfigMap.filter(
			function(key, value){
				if(value.find(application.constants.CCS_CONFIG.CLUSTER) EQ cluster AND 
						value.find(application.constants.CCS_CONFIG.ENVIRONMENT) EQ env)
					return true
				return false
			}
		)
		//cfdump(var=nodeConfigMapList, label="nodeConfigMapList");
		return nodeConfigMapList.keylist();
		/*
		envList = structReduce(nodeConfigMapList, 
								function(result, key, sisValue){
									result = result ?: "";
							        result &= 
									        structReduce(sisValue, function(cres, ck, cv){
									         	cres = cres ?: "";
									         	if(ck EQ application.constants.CCS_CONFIG.ENVIRONMENT)
									         		cres &= cv & ",";
									        	return cres
									        	});
							        return result;
							    });
		return envList; */
	}


	public string function getNodeKeysInPrimeEnvironment(){
		primeNodeConfig = getPrimeNodeConfig()
		primeCluster = primeNodeConfig.find(application.constants.CCS_CONFIG.CLUSTER)
		primeEnv = primeNodeConfig.find(application.constants.CCS_CONFIG.ENVIRONMENT)

		return getNodeKeyListInEnvironment(primeCluster, primeEnv)
	}


	public string function getNodeKeysNotInPrimeEnvironment(){
		primeNodeConfig = getPrimeNodeConfig()
		primeCluster = primeNodeConfig.find(application.constants.CCS_CONFIG.CLUSTER)
		primeEnv = primeNodeConfig.find(application.constants.CCS_CONFIG.ENVIRONMENT)

		return getNodeKeyListNotInEnvironment(primeCluster, primeEnv)
	}
	

	private string function getNodeKeyListNotInEnvironment(required string cluster, required string env){
	
		nodeConfigMapList = application.ccsConfigMap.filter(
			function(key, value){
				if(value.find(application.constants.CCS_CONFIG.CLUSTER) EQ cluster AND 
						value.find(application.constants.CCS_CONFIG.ENVIRONMENT) EQ env)
					return false
				return true
			}
		)
		//cfdump(var=nodeConfigMapList, label="nodeConfigMapList");
		return nodeConfigMapList.keylist();
	}


	public struct function getNonPrimeNodeConfigMap(){
		primeEnv = getPrimeNodeEnvironment()
		nonPrimeNodeConfigMap = application.ccsConfigMap.filter(
				function(key, value){
					if(value.find(application.constants.CCS_CONFIG.ENVIRONMENT) EQ primeEnv)
						return true
					return false
				}
			)
		//cfdump(var=nonPrimeNodeConfigMap, label="nonPrimeNodeConfigMap");
		return nonPrimeNodeConfigMap;
	}


	private string function getEnvironmentFromConfigMap(required struct nodeConfig){
		nodeEnv = ""
		if(isStruct(nodeConfig) AND nodeConfig.KeyExists(application.constants.CCS_CONFIG.ENVIRONMENT))
			nodeEnv = structFind(nodeConfig, application.constants.CCS_CONFIG.ENVIRONMENT)
		else{
			writeOutput("error retrieving node environment.")
			try{
				cflog(type="error", application=true, file="#application.applicationname#", text="testManager.getNodeKeyByIndex : \
				error retrieving node environment from nodeconfig: #serializeJSON(nodeConfig)#")
			}catch(any e){
				// swallow.
			}
		}
		return nodeEnv
	}

}
