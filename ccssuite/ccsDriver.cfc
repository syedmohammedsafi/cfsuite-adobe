/**
*
* @file  /E/CFGronckleBuilds/fortunaNx/cfusion/wwwroot/cfsuite/ccssuite/testDriver.cfc
* @author  pnayak 13/05/24
* @description proxy for CF CCS java classes 
*
*/

component output="false"{

	this.ccsNodeList = [];

	function init(){
		return this;
	}

	// A test run calls initializeCcsNodeConfig() (and so getCCSConfigMapList()) several times in a
	// row — cache the live CCS node list for the rest of THIS request so those calls don't each hit
	// the Java API again. This must never survive past the current request: CCS cluster/node
	// membership can change between separate test page loads (e.g. a node moved to a new cluster),
	// and an application-scoped cache was serving that stale membership for minutes afterward.
	private boolean function hasFreshCcsSnapshotThisRequest(){
		return structKeyExists(request, "ccsConfigAllNodesSnapshot")
			AND isArray(request.ccsConfigAllNodesSnapshot)
			AND arrayLen(request.ccsConfigAllNodesSnapshot);
	}

	public array function getCCSConfigMapList(){
		ensureApplicationConstants();

		if(isJavaCcsApiBlocked())
			return getCCSConfigMapListWhenJavaBlocked();

		var fileNodeCount = arrayLen(loadCCSNodesFromConfigFiles());

		if(hasFreshCcsSnapshotThisRequest()
				AND (NOT fileNodeCount OR arrayLen(request.ccsConfigAllNodesSnapshot) GTE fileNodeCount)){
			return filterNodesForTestScope(request.ccsConfigAllNodesSnapshot);
		}

		var nodeCnfgList = loadCCSNodesFromJava();

		if(arrayLen(nodeCnfgList)){
			this.ccsNodeList = nodeCnfgList;
			request.ccsConfigAllNodesSnapshot = duplicate(nodeCnfgList);
			// Last-known-good, kept across requests only so getCCSConfigMapListWhenJavaBlocked()
			// has something better than the file-based fallback if Java access gets disabled later.
			application.ccsConfigAllNodesSnapshot = duplicate(nodeCnfgList);
			application.ccsConfig = filterNodesForTestScope(nodeCnfgList);
		}
		return filterNodesForTestScope(nodeCnfgList);
	}


	private array function getCCSConfigMapListWhenJavaBlocked(){
		if(structKeyExists(application, "ccsConfigAllNodesSnapshot") AND isArray(application.ccsConfigAllNodesSnapshot) AND arrayLen(application.ccsConfigAllNodesSnapshot))
			return filterNodesForTestScope(application.ccsConfigAllNodesSnapshot);

		if(structKeyExists(application, "ccsConfig") AND isArray(application.ccsConfig) AND arrayLen(application.ccsConfig) AND NOT isFallbackNodeConfig(application.ccsConfig))
			return filterNodesForTestScope(application.ccsConfig);

		if(isArray(this.ccsNodeList) AND arrayLen(this.ccsNodeList) AND NOT isFallbackNodeConfig(this.ccsNodeList))
			return filterNodesForTestScope(this.ccsNodeList);

		nodeCnfgList = loadCCSNodesFromConfigFiles();
		if(arrayLen(nodeCnfgList)){
			this.ccsNodeList = nodeCnfgList;
			application.ccsConfigAllNodesSnapshot = duplicate(nodeCnfgList);
			application.ccsConfig = filterNodesForTestScope(nodeCnfgList);
		}
		return filterNodesForTestScope(nodeCnfgList);
	}


	private boolean function isJavaCcsApiBlocked(){
		var disabled = new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().getSetting("DisableServiceFactory");
		return listFindNoCase("true,yes,1", lCase(trim("" & disabled))) GT 0;
	}


	private array function loadCCSNodesFromJava(){
		var nodeCnfgList = fetchStableNodesFromCentralConfigServer();

		var fileNodes = loadCCSNodesFromConfigFiles();
		if(arrayLen(fileNodes))
			nodeCnfgList = mergeNodeConfigLists(nodeCnfgList, fileNodes);

		return nodeCnfgList;
	}


	// coldfusion.centralconfig.server.CentralConfigServerManager.getNodes() has been observed to
	// intermittently report a node's PREVIOUS cluster right after it's reassigned to a different
	// one in-place (as opposed to being freshly registered into it) — a single call can catch it
	// mid-flap. Poll a couple more times and only trust a reading once two consecutive calls agree
	// on every node's cluster; otherwise fall back to the last (freshest) reading.
	private array function fetchStableNodesFromCentralConfigServer(){
		var previous = "";
		var current = fetchNodesFromCentralConfigServer();
		for(var attempt = 1; attempt LTE 3; attempt++){
			previous = current;
			if(attempt GT 1)
				sleep(150);
			current = fetchNodesFromCentralConfigServer();
			if(nodeClusterSignature(current) EQ nodeClusterSignature(previous))
				return current;
		}
		return current;
	}


	private string function nodeClusterSignature(required array nodes){
		var parts = [];
		for(var n in arguments.nodes){
			arrayAppend(
				parts,
				lCase(trim("" & n[application.constants.CCS_CONFIG.HOSTNAME])) & ":" &
					val(n[application.constants.CCS_CONFIG.PORT]) & "=" &
					trim("" & n[application.constants.CCS_CONFIG.CLUSTER])
			);
		}
		arraySort(parts, "textnocase");
		return arrayToList(parts, "|");
	}


	private array function fetchNodesFromCentralConfigServer(){
		var nodeCnfgList = [];
		var ccsServerManager = createObject("java", "coldfusion.centralconfig.server.CentralConfigServerManager").init();
		var nodearray = ccsServerManager.getNodes();
		if(IsDefined("nodearray") AND ArrayLen(nodearray) > 0){
			cfloop(array="#nodearray#", item="node", index="idx"){
				var urlParts = listToArray(node.server, ':');
				var _hostname = "";
				var _port = "";
				if(arrayLen(urlParts) > 1){
					_hostname = urlParts[1];
					_port = urlParts[2];
				}
				else{
					_hostname = node.server;
					_port = node.port;
				}

				var nodeStruct = [
					"#application.constants.CCS_CONFIG.CLUSTER#" : node.cluster,
					"#application.constants.CCS_CONFIG.ENVIRONMENT#" : node.environment,
					"#application.constants.CCS_CONFIG.HOSTNAME#" : _hostname,
					"#application.constants.CCS_CONFIG.PORT#" : _port,
					"#application.constants.CCS_CONFIG.CURRENT_VERSION#" : node.currentversion,
					"#application.constants.CCS_CONFIG.ENABLED#" : node.isCCSEnabled(),
					"#application.constants.CCS_CONFIG.JEE_CONTEXT#" : node.jeecontext
				];
				arrayAppend(nodeCnfgList, nodeStruct);
			}
		}
		return nodeCnfgList;
	}


	private string function getNodeConfigKey(required struct node){
		var ctx = structKeyExists(arguments.node, application.constants.CCS_CONFIG.JEE_CONTEXT)
			? trim("" & arguments.node[application.constants.CCS_CONFIG.JEE_CONTEXT])
			: "";
		return lCase(trim("" & arguments.node[application.constants.CCS_CONFIG.HOSTNAME])) & "::" &
			val(arguments.node[application.constants.CCS_CONFIG.PORT]) & "::" & lCase(ctx);
	}


	private array function mergeNodeConfigLists(required array primaryList, required array supplementalList){
		var merged = duplicate(arguments.primaryList);
		var existingKeys = {};

		for(var node in merged)
			existingKeys[getNodeConfigKey(node)] = true;

		for(var node in arguments.supplementalList){
			var key = getNodeConfigKey(node);
			if(NOT structKeyExists(existingKeys, key)){
				arrayAppend(merged, node);
				existingKeys[key] = true;
			}
		}

		return merged;
	}


	private array function loadCCSNodesFromConfigFiles(){
		nodeCnfgList = [];
		ensureApplicationConstants();
		nodesFile = server.coldfusion.rootdir & application.constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & application.constants.SYS_CONFIG.FILE_SEPARATOR &
			"ccs" & application.constants.SYS_CONFIG.FILE_SEPARATOR & "nodes.properties";
		if(NOT fileExists(nodesFile))
			return nodeCnfgList;

		localCcs = readLocalCcsProperties();
		rawNodes = trim(fileRead(nodesFile));
		if(NOT len(rawNodes))
			return nodeCnfgList;

		try {
			parsedNodes = deserializeJSON(rawNodes);
		}
		catch(any e){
			return nodeCnfgList;
		}
		if(NOT isArray(parsedNodes))
			return nodeCnfgList;

		for(node in parsedNodes){
			if(NOT isStruct(node))
				continue;
			_hostname = structKeyExists(node, "server") ? trim("" & node.server) : "";
			_port = structKeyExists(node, "port") ? val(node.port) : 0;
			if(NOT len(_hostname) OR _port LTE 0)
				continue;

			_enabled = true;
			if(structKeyExists(localCcs, "enabled") AND structKeyExists(localCcs, "ccssecretkey")
				AND structKeyExists(node, "ccssecretkey")
				AND val(_port) EQ val(localCcs.hostport))
				_enabled = localCcs.enabled;

			nodeCnfgList.append({
				"#application.constants.CCS_CONFIG.CLUSTER#" : (structKeyExists(localCcs, "clustername") ? localCcs.clustername : "_CF_DEFAULT"),
				"#application.constants.CCS_CONFIG.ENVIRONMENT#" : (structKeyExists(localCcs, "environment") ? localCcs.environment : "development"),
				"#application.constants.CCS_CONFIG.HOSTNAME#" : _hostname,
				"#application.constants.CCS_CONFIG.PORT#" : _port,
				"#application.constants.CCS_CONFIG.CURRENT_VERSION#" : (structKeyExists(localCcs, "currentversion") ? localCcs.currentversion : "-1"),
				"#application.constants.CCS_CONFIG.ENABLED#" : _enabled,
				"#application.constants.CCS_CONFIG.JEE_CONTEXT#" : (structKeyExists(node, "jeecontext") ? trim("" & node.jeecontext) : "")
			});
		}
		return nodeCnfgList;
	}


	public struct function readLocalCcsProperties(){
		result = {};
		ccsFile = server.coldfusion.rootdir & application.constants.SYS_CONFIG.FILE_SEPARATOR &
			"lib" & application.constants.SYS_CONFIG.FILE_SEPARATOR &
			"ccs" & application.constants.SYS_CONFIG.FILE_SEPARATOR & "ccs.properties";
		if(NOT fileExists(ccsFile))
			return result;

		for(line in listToArray(fileRead(ccsFile), chr(10))){
			line = trim(line);
			if(NOT len(line) OR left(line, 1) EQ chr(35) OR NOT find("=", line))
				continue;
			key = lCase(trim(listFirst(line, "=")));
			value = trim(listRest(line, "="));
			if(key EQ "enabled")
				result.enabled = listFindNoCase("true,yes,1", value) GT 0;
			else
				result[key] = value;
		}
		return result;
	}

	public boolean function isJvmConfigExcludedFromCcs(){
		try {
			var props = readLocalCcsProperties();
			if(structKeyExists(props, "excludefiles") AND listFindNoCase(props.excludefiles, "jvm.config"))
				return true;
		} catch(any e){}
		return true;
	}


	private array function getFallbackNodeListForCurrentPort(){
		writeOutput("<strong>Warning:</strong> CCS Java API unavailable (#cgi.server_port# only). Using single-node fallback. Grant Java access or use cached CCS config from first bootstrap.<br>");
		return [{
			"#application.constants.CCS_CONFIG.CLUSTER#" : "local",
			"#application.constants.CCS_CONFIG.ENVIRONMENT#" : "development",
			"#application.constants.CCS_CONFIG.HOSTNAME#" : "localhost",
			"#application.constants.CCS_CONFIG.PORT#" : cgi.server_port,
			"#application.constants.CCS_CONFIG.CURRENT_VERSION#" : "",
			"#application.constants.CCS_CONFIG.ENABLED#" : false,
			"#application.constants.CCS_CONFIG.JEE_CONTEXT#" : ""
		}];
	}


	private array function filterNodesForTestScope(required array nodeList){
		if(structKeyExists(application, "ccsTestNodesScope") AND application.ccsTestNodesScope EQ "all")
			return arguments.nodeList;

		filtered = [];
		for(node in arguments.nodeList){
			if(val(node[application.constants.CCS_CONFIG.PORT]) EQ val(cgi.server_port))
				filtered.append(node);
		}
		if(arrayLen(filtered) EQ 0)
			writeOutput("<strong>Warning:</strong> no CCS node matches current port #cgi.server_port#. Set application.ccsTestNodesScope to ""all"" or add this port in CCS.<br>");
		return filtered;
	}


	public array function getNodesHostPortPairs(){
		nodeList = getCCSConfigMapList();
		nodeHostPortPairs = [];
		for(nodeConfig in nodeList){
			nodeHostPortPairs.append(
				structFind(nodeConfig, application.constants.CCS_CONFIG.HOSTNAME) & ':' &
				structFind(nodeConfig, application.constants.CCS_CONFIG.PORT)
			);
		}
		return nodeHostPortPairs;
	}


	/**
	 * True when sync tests may proceed.
	 * When the CCS Java API is blocked, node config falls back to current port only — in that case
	 * return true and let the Admin API set attempt determine whether CCS is actually reachable.
	 */
	public boolean function isCcsSyncAvailable(){
		ensureApplicationConstants();
		nodes = getCCSConfigMapList();
		if(NOT arrayLen(nodes))
			return false;

		if(isFallbackNodeConfig(nodes))
			return true;

		for(node in nodes){
			if(structKeyExists(node, application.constants.CCS_CONFIG.ENABLED) AND node[application.constants.CCS_CONFIG.ENABLED])
				return true;
		}
		return false;
	}


	public boolean function isUsingJavaFallbackConfig(){
		ensureApplicationConstants();
		return isFallbackNodeConfig(getCCSConfigMapList());
	}


	private boolean function isFallbackNodeConfig(required array nodes){
		if(arrayLen(arguments.nodes) NEQ 1)
			return false;

		node = arguments.nodes[1];
		return structKeyExists(node, application.constants.CCS_CONFIG.CLUSTER)
			AND node[application.constants.CCS_CONFIG.CLUSTER] EQ "local"
			AND structKeyExists(node, application.constants.CCS_CONFIG.ENABLED)
			AND NOT node[application.constants.CCS_CONFIG.ENABLED];
	}


	private void function ensureApplicationConstants(){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
	}

}
