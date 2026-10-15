/**
* Shared helpers for serverSettings testsuite CFM pages (settings tab, request tuning, etc.).
*/
component output="true" {

	public function init(){
		return this;
	}

	/**
	 * Reload CCS node list and config map for the given test scope.
	 * @nodesScope "all" for every CCS node, "currentPort" for this instance only.
	 * @useCachedNodes when true, reuse application.ccsConfigAllNodesSnapshot (needed after DisableServiceFactory is enabled).
	 */
	public void function initializeCcsNodeConfig(required string nodesScope, boolean useCachedNodes = false){
		application.ccsTestNodesScope = arguments.nodesScope;
		if(arguments.useCachedNodes AND structKeyExists(application, "ccsConfigAllNodesSnapshot") AND isArray(application.ccsConfigAllNodesSnapshot) AND arrayLen(application.ccsConfigAllNodesSnapshot)){
			application.ccsConfig = duplicate(application.ccsConfigAllNodesSnapshot);
			var cachedTestMgr = new cfsuite.ccssuite.testManager().init();
			application.ccsConfigMap = cachedTestMgr.getCCSConfigMapFromList(application.ccsConfig);
			return;
		}
		var ccsDriver = new cfsuite.ccssuite.ccsDriver();
		application.ccsConfig = ccsDriver.getCCSConfigMapList();
		var testMgr = new cfsuite.ccssuite.testManager().init();
		application.ccsConfigMap = testMgr.getCCSConfigMap();
	}

	private void function ensureTestConstants(){
		if(NOT structKeyExists(application, "testConstants"))
			application.testConstants = new cfsuite.ccssuite.testConstants().init();
	}

	private string function getNodeKeySeparator(){
		ensureTestConstants();
		if(structKeyExists(application.testConstants, "TEST_FRAME")
				AND structKeyExists(application.testConstants.TEST_FRAME, "COMPOSITE_KEY_FIELD_SEPARATOR"))
			return application.testConstants.TEST_FRAME.COMPOSITE_KEY_FIELD_SEPARATOR;
		if(structKeyExists(application.testConstants, "COMPOSITE_KEY_FIELD_SEPERATOR"))
			return application.testConstants.COMPOSITE_KEY_FIELD_SEPERATOR;
		return "::";
	}

	private boolean function isInstanceLocalApiArea(required string apiArea, string settingName = ""){
		// REST Services registration (neo-jaxrs.xml) is a per-instance filesystem path/mapping —
		// confirmed via extensive direct testing (see restServices/i.cfm) that real CCS's
		// replication of this file is unpredictable and, in this environment, has repeatedly
		// corrupted a peer's live "ccs" mapping, so this suite deliberately never active-pushes it
		// and never expects a peer to pick it up. Without this, the peer row showed "Pending sync"
		// (implying CCS will eventually catch up), which is inaccurate — it never does.
		// if(lCase(trim("" & arguments.apiArea)) EQ "restservices")
		// 	return true;
		return false;
	}

	private boolean function isDebuggingApiArea(required string apiArea){
		return listFindNoCase(
			"debugoutputsettings,loggingsettings,debuggingipaddress,developerprofile,debuggersettings",
			lCase(trim("" & arguments.apiArea))
		) GT 0;
	}

	private boolean function isCurrentServerNodeKey(required string nodeKey){
		var parts = listToArray(arguments.nodeKey, getNodeKeySeparator(), false, true);
		if(arrayLen(parts) LT 2)
			return false;
		return val(parts[2]) EQ val(cgi.server_port);
	}

	public struct function initTestFrame(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = false
	){
		return arguments.testDriver.initTestFrameWithPreSetValues(
			arguments.settingName,
			arguments.testDriver.getGenericTestFrame(),
			arguments.scriptPath,
			"",
			"",
			arguments.skipUnreachableNodes
		);
	}

	private string function getPrimaryNodeKeyFromFrame(required struct testFrame){
		ensureTestConstants();
		var primeSet = arguments.testFrame[application.testConstants.TEST_FRAME.PRIME_SET];
		var keyList = primeSet.keyList();
		for(var nodeKey in listToArray(keyList)){
			if(isCurrentServerNodeKey(nodeKey))
				return nodeKey;
		}
		return listLen(keyList) ? listGetAt(keyList, 1) : "";
	}

	public any function getPresetValueFromFrame(required struct testFrame, string settingName = ""){
		ensureTestConstants();
		try {
			var nodeKey = getPrimaryNodeKeyFromFrame(arguments.testFrame);
			if(NOT len(trim(nodeKey))){
				throw(message="No CCS node entries found in test frame for preset lookup",
					detail="Initialize CCS config and ensure the current instance is registered before running sync tests.",
					type="CCSTest.ConfigError");
			}
			var value = arguments.testFrame[application.testConstants.TEST_FRAME.PRIME_SET][nodeKey][application.testConstants.TEST_FRAME.PRESET_VALUE];
			return isSimpleValue(value) ? trim("" & value) : value;
		}
		catch(any e){
			if(len(arguments.settingName))
				writeOutput("error getting preset value for #arguments.settingName#<br>");
			rethrow;
		}
	}

	public any function getPresetNodeKeyFromFrame(required struct testFrame, string settingName = ""){
		ensureTestConstants();
		try {
			return getPrimaryNodeKeyFromFrame(arguments.testFrame);
		}
		catch(any e){
			if(len(arguments.settingName))
				writeOutput("error getting preset value for #arguments.settingName#<br>");
			rethrow;
		}
	}

	private array function getNodeLabelsFromFrame(required struct testFrame){
		ensureTestConstants();
		var labels = [];
		var setTypes = [
			application.testConstants.TEST_FRAME.PRIME_SET,
			application.testConstants.TEST_FRAME.NONPRIME_SET
		];

		for(var setType in setTypes){
			if(NOT structKeyExists(arguments.testFrame, setType))
				continue;
			for(var nodeKey in arguments.testFrame[setType].keyList()){
				var label = getURLFragFromNodeKey(nodeKey);
				if(len(label) AND arrayFindNoCase(labels, label) EQ 0)
					arrayAppend(labels, label);
			}
		}
		return labels;
	}

	private void function writeMultiNodeUpdateMessage(
		required string settingName,
		required any newSetValue,
		required struct testFrame,
		string nodesScope = "all"
	){
		var primeNode = getPresetNodeKeyFromFrame(arguments.testFrame, arguments.settingName);
		var primeLabel = getURLFragFromNodeKey(primeNode);
		var valueLabel = formatDisplayValue(arguments.settingName, arguments.newSetValue);
		var allNodes = getNodeLabelsFromFrame(arguments.testFrame);
		if(arguments.nodesScope EQ "all" AND arrayLen(allNodes) LTE 1){
			var configNodes = getNodeLabelsFromCcsConfig(arguments.nodesScope);
			if(arrayLen(configNodes) GT arrayLen(allNodes))
				allNodes = configNodes;
		}

		if(arguments.nodesScope NEQ "all" OR arrayLen(allNodes) LTE 1){
			writeOutput("updating #arguments.settingName# to: #valueLabel# on node: #primeLabel#<br>");
			return;
		}

		writeOutput(
			"updating #arguments.settingName# to: #valueLabel# on prime node: #primeLabel#; "
		);
	}

	private array function filterSyncVerificationRowsForNode(required array rows, required string nodeKey){
		if(NOT len(trim(arguments.nodeKey)))
			return arguments.rows;

		var filtered = [];
		for(var row in arguments.rows){
			if(row.nodeKey EQ arguments.nodeKey)
				arrayAppend(filtered, row);
		}
		return filtered;
	}

	private struct function getNodeMetadataForKey(required string nodeKey){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		var cluster = "N/A";
		var env = "N/A";
		if(structKeyExists(application, "ccsConfigMap") AND application.ccsConfigMap.keyExists(arguments.nodeKey)){
			cluster = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.CLUSTER];
			env = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
		}
		return {
			cluster = len(trim("" & cluster)) ? cluster : "N/A",
			environment = len(trim("" & env)) ? env : "N/A"
		};
	}

	private array function sortSyncVerificationRowsCurrentFirst(required array rows){
		var sorted = [];
		for(var row in arguments.rows){
			if(isCurrentServerNodeKey(row.nodeKey))
				arrayAppend(sorted, row);
		}
		var otherRows = [];
		for(var row in arguments.rows){
			if(NOT isCurrentServerNodeKey(row.nodeKey))
				arrayAppend(otherRows, row);
		}
		arraySort(otherRows, function(a, b){
			return compare(a.nodeLabel, b.nodeLabel);
		});
		for(var row in otherRows)
			arrayAppend(sorted, row);
		return sorted;
	}

	private array function getNodeLabelsFromCcsConfig(required string nodesScope){
		if(arguments.nodesScope NEQ "all" OR NOT structKeyExists(application, "ccsConfigMap"))
			return [];

		var labels = [];
		for(var nodeKey in application.ccsConfigMap.keyList()){
			var label = getURLFragFromNodeKey(nodeKey);
			if(len(label) AND arrayFindNoCase(labels, label) EQ 0)
				arrayAppend(labels, label);
		}
		return labels;
	}

	private array function buildCurrentNodeVerificationRows(
		required struct syncTestFrame,
		required struct syncResult,
		required struct existingValues,
		required string settingName,
		required any newSetValue,
		string apiArea = "",
		struct actualValues = {}
	){
		ensureTestConstants();
		var currentNodeKey = getPrimaryNodeKeyFromFrame(arguments.syncTestFrame);
		var metadata = getNodeMetadataForKey(currentNodeKey);
		var existing = structKeyExists(arguments.existingValues, currentNodeKey)
			? arguments.existingValues[currentNodeKey]
			: getPresetValueFromFrame(arguments.syncTestFrame, arguments.settingName);
		var passed = false;
		var syncState = "Applied";
		var syncRows = buildSyncVerificationRows(
			arguments.syncResult.postSyncFrame,
			arguments.newSetValue,
			arguments.apiArea,
			true
		);

		for(var row in syncRows){
			if(row.nodeKey EQ currentNodeKey){
				passed = row.passed;
				syncState = structKeyExists(row, "syncState") ? row.syncState : (passed ? "Applied" : "Not applied");
				break;
			}
		}

		return [{
			nodeKey = currentNodeKey,
			nodeLabel = getURLFragFromNodeKey(currentNodeKey),
			existingValue = formatDisplayValue(arguments.settingName, existing),
			updatedValue = structKeyExists(arguments.actualValues, currentNodeKey)
				? formatDisplayValue(arguments.settingName, arguments.actualValues[currentNodeKey]) : "(unavailable)",
			passed = passed,
			syncState = syncState,
			cluster = metadata.cluster,
			environment = metadata.environment,
			setType = application.testConstants.TEST_FRAME.PRIME_SET
		}];
	}

	public numeric function getNumericPresetValueFromFrame(required struct testFrame, string settingName = ""){
		var value = getPresetValueFromFrame(arguments.testFrame, arguments.settingName);
		if(findNoCase("<html", "" & value))
			throw(message="preSetValue is an HTML error page, not a number",
				detail="Fix CF_ADMIN_PASSWORD in constants.cfc (must match CF Administrator login). Restart the application.",
				type="CCSTest.ConfigError");
		return val(value);
	}

	public any function getPrimePostSetValue(required struct postSyncFrame){
		ensureTestConstants();
		var nodeKey = listGetAt(arguments.postSyncFrame[application.testConstants.TEST_FRAME.PRIME_SET].keyList(), 1);
		return arguments.postSyncFrame[application.testConstants.TEST_FRAME.PRIME_SET][nodeKey][application.testConstants.TEST_FRAME.POSTSET_VALUE];
	}

	public any function getPostSetValueFromFrame(required struct testFrame){
		return getPrimePostSetValue(arguments.testFrame);
	}

	public string function getURLFragFromNodeKey(required string nodeKey){
		var frags = listToArray(arguments.nodeKey, getNodeKeySeparator(), false, true);
		if(arrayLen(frags) EQ 2)
			return frags[1] & ":" & frags[2];
		if(arrayLen(frags) EQ 3)
			return frags[1] & ":" & frags[2] & "/" & frags[3];
		writeOutput("error parsing nodeKey: #arguments.nodeKey#<br>");
		return "";
	}

	public string function getCurrentSettingValue(required string nodeKey, required string urlSuffix){
		if(NOT structKeyExists(application, "protocol"))
			application.protocol = "http";
		var _url = application.protocol & "://" & getURLFragFromNodeKey(arguments.nodeKey) & arguments.urlSuffix;
		writeOutput("calling URL: " & _url & "<br>");
		cfhttp(url="#_url#", method="GET", result="local.response");
		if(response.statusCode EQ 200)
			return response.fileContent;
		if(response.statusCode EQ 500)
			return "500 ERROR getting setting value";
		return response.statusCode;
	}

	public string function flipBooleanValue(required any currentValue){
		if(isBoolean(arguments.currentValue))
			return arguments.currentValue ? "false" : "true";
		return listFindNoCase("true,yes,1", lCase(trim("" & arguments.currentValue))) ? "false" : "true";
	}

	public string function formatDisplayValue(required string settingName, required any value){
		var text = trim("" & arguments.value);
		if(new cfsuite.ccssuite.utils.datasourceConfigUtil().init().isMsAccessSetting(arguments.settingName))
			return new cfsuite.ccssuite.utils.msAccessDatasourceConfigUtil().init().formatDisplayValue(arguments.settingName, arguments.value);
		if(new cfsuite.ccssuite.utils.datasourceConfigUtil().init().isJndiSetting(arguments.settingName))
			return new cfsuite.ccssuite.utils.jndiDatasourceConfigUtil().init().formatDisplayValue(arguments.settingName, arguments.value);
		if(new cfsuite.ccssuite.utils.datasourceConfigUtil().init().isDb2Setting(arguments.settingName))
			return new cfsuite.ccssuite.utils.db2DatasourceConfigUtil().init().formatDisplayValue(arguments.settingName, arguments.value);
		if(new cfsuite.ccssuite.utils.datasourceConfigUtil().init().isDerbyClientSetting(arguments.settingName))
			return new cfsuite.ccssuite.utils.derbyClientDatasourceConfigUtil().init().formatDisplayValue(arguments.settingName, arguments.value);
		if(new cfsuite.ccssuite.utils.datasourceConfigUtil().init().isDerbyEmbeddedSetting(arguments.settingName))
			return new cfsuite.ccssuite.utils.derbyEmbeddedDatasourceConfigUtil().init().formatDisplayValue(arguments.settingName, arguments.value);
		if(compareNoCase(arguments.settingName, "redisCacheStorageHost") EQ 0 AND NOT len(text))
			return "Empty string (read from node)";
		if(listFindNoCase("redisCacheStoragePassword,sessionStoragePassword", arguments.settingName))
			return len(text) ? "[redacted]" : "(empty)";
		if(findNoCase("set FAILED", text))
			return text;
		if(compareNoCase(arguments.settingName, "AppCFCLookupOrder") EQ 0)
			return getAppCFCLookupOrderLabel(arguments.value);
		if(compareNoCase(arguments.settingName, "ServerCacheType") EQ 0)
			return getServerCacheTypeLabel(arguments.value);
		if (isNumeric(arguments.value)) {
			return arguments.value;
		}
		if(isBooleanDisplayValue(arguments.value))
			return isTruthyValue(arguments.value) ? "Enabled" : "Disabled";
		return text;
	}

	private string function getAppCFCLookupOrderLabel(required any value){
		switch(val(arguments.value)){
			case 1: return "Default order";
			case 2: return "Until webroot";
			case 3: return "In webroot";
			default: return trim("" & arguments.value);
		}
	}

	private string function getServerCacheTypeLabel(required any value){
		switch(val(arguments.value)){
			case 0: return "EHCache";
			case 1: return "JCS";
			case 2: return "Redis";
			case 3: return "Memcached";
			default: return trim("" & arguments.value);
		}
	}

	private boolean function isTruthyValue(required any value){
		if(isBoolean(arguments.value))
			return arguments.value;
		return listFindNoCase("true,yes,1", lCase(trim("" & arguments.value))) GT 0;
	}

	private boolean function isBooleanDisplayValue(required any value){
		if(isBoolean(arguments.value))
			return true;
		var text = lCase(trim("" & arguments.value));
		return listFindNoCase("true,false,yes,no,1,0", text) GT 0;
	}

	public void function requireBoolean(required any currentValue, required string settingName){
		var text = lCase(trim("" & arguments.currentValue));
		if(NOT isBoolean(arguments.currentValue) AND NOT listFindNoCase("true,false,yes,no", text)){
			writeOutput("invalid currently set value detected for #arguments.settingName#. Value set to: #currentValue#<br>");
			throw(message="invalid current setting", type="ConfigErr");
		}
	}

	public void function requireValueInList(required any currentValue, required string validList, required string settingName){
		if(NOT listFind(arguments.validList, "" & arguments.currentValue)){
			writeOutput("invalid currently set value detected for #arguments.settingName#. Value set to: [#currentValue#]<br>");
			throw(message="invalid current setting", type="ConfigErr");
		}
	}

	public numeric function bumpNumeric(required numeric currentValue, numeric bumpBy = 2){
		return arguments.currentValue + arguments.bumpBy;
	}

	public string function normalizeCommaList(required string listValue){
		var items = [];
		for(var item in listToArray(arguments.listValue, ",", false, true)){
			item = uCase(trim(item));
			if(len(item) AND arrayFindNoCase(items, item) EQ 0)
				arrayAppend(items, item);
		}
		arraySort(items, "textnocase");
		return arrayToList(items, ",");
	}

	public string function toggleCommaListToken(required string listValue, required string token){
		var items = listToArray(normalizeCommaList(arguments.listValue), ",", false, true);
		var tokenValue = uCase(trim(arguments.token));
		var index = arrayFindNoCase(items, tokenValue);
		if(index)
			arrayDeleteAt(items, index);
		else
			arrayAppend(items, tokenValue);
		arraySort(items, "textnocase");
		return arrayToList(items, ",");
	}

	public string function normalizeWebDirectoryPath(required string pathValue){
		var path = replace(trim(arguments.pathValue), "\", "/", "all");
		if(len(path) AND right(path, 1) NEQ "/")
			path &= "/";
		return path;
	}

	public string function toggleWebDirectoryPathSuffix(required string pathValue, string suffix = "_ccs"){
		var path = normalizeWebDirectoryPath(arguments.pathValue);
		var pathCore = len(path) GT 1 ? left(path, len(path) - 1) : "";
		if(len(pathCore) GTE len(arguments.suffix) AND right(pathCore, len(arguments.suffix)) EQ arguments.suffix)
			return normalizeWebDirectoryPath(left(pathCore, len(pathCore) - len(arguments.suffix)));
		return normalizeWebDirectoryPath(pathCore & arguments.suffix);
	}

	public string function getOrmSearchIndexTestPath(){
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		return server.coldfusion.rootdir & application.constants.SYS_CONFIG.FILE_SEPARATOR & "ccs_orm_search_index";
	}

	public string function toggleOrmSearchIndexTestPath(required string currentValue){
		return len(trim(arguments.currentValue)) ? "" : getOrmSearchIndexTestPath();
	}

	public string function toggleStringMarker(required string currentValue, string marker = "_ccs"){
		var value = trim(arguments.currentValue);
		if(len(value) GTE len(arguments.marker) AND right(value, len(arguments.marker)) EQ arguments.marker)
			return left(value, len(value) - len(arguments.marker));
		return value & arguments.marker;
	}

	public string function toggleErrorHandlerPath(required string currentValue, required string handlerType){
		var value = trim(arguments.currentValue);
		var handlers = {
			siteWide = {
				defaultHandler = "/CFIDE/administrator/templates/secure_profile_error.cfm",
				altHandler = "/CFIDE/administrator/templates/missing_template_error.cfm"
			},
			missingTemplate = {
				defaultHandler = "/CFIDE/administrator/templates/missing_template_error.cfm",
				altHandler = "/CFIDE/administrator/templates/application_404.cfm"
			}
		};
		if(NOT structKeyExists(handlers, arguments.handlerType))
			throw(message="unknown error handler type", type="CCSTest.ConfigError");
		return (value EQ handlers[arguments.handlerType].defaultHandler)
			? handlers[arguments.handlerType].altHandler
			: handlers[arguments.handlerType].defaultHandler;
	}

	public string function toggleRequestQueueTimeoutPage(required string currentValue){
		var value = trim(arguments.currentValue);
		var defaultPage = "/CFIDE/administrator/templates/request_timeout_error.htm";
		var altPage = "/CFIDE/administrator/templates/secure_profile_error.htm";
		return (value EQ defaultPage) ? altPage : defaultPage;
	}

	public string function flipClientStorage(required any currentValue){
		var cv = lCase(trim("" & arguments.currentValue));
		if(cv EQ "cookie") return "Registry";
		if(cv EQ "registry") return "Cookie";
		return "Registry";
	}

	public string function flipClientStoreBoolean(required any currentValue){
		return isClientStoreBooleanTrue(arguments.currentValue) ? "NO" : "YES";
	}

	private boolean function isClientStoreBooleanTrue(required any value){
		var text = lCase(trim("" & arguments.value));
		return listFindNoCase("true,yes,1", text) GT 0;
	}

	public string function bumpPurgeInterval(required string currentValue, numeric bumpMinutes = 1){
		var parts = listToArray(trim(arguments.currentValue), ":");
		var hours = arrayLen(parts) GTE 1 ? val(parts[1]) : 0;
		var minutes = arrayLen(parts) GTE 2 ? val(parts[2]) : 0;
		minutes += arguments.bumpMinutes;
		if(minutes GTE 60){
			hours++;
			minutes -= 60;
		}
		return hours & ":" & minutes;
	}

	public string function bumpScopeTimeoutMinutes(required string currentValue, numeric bumpBy = 2){
		var parts = listToArray(trim(arguments.currentValue), ",");
		while(arrayLen(parts) LT 4)
			arrayAppend(parts, "0");
		parts[3] = val(parts[3]) + arguments.bumpBy;
		return arrayToList(parts, ",");
	}

	public string function bumpScopeTimeoutSeconds(required string currentValue, numeric bumpBy = 2){
		var parts = listToArray(trim(arguments.currentValue), ",");
		while(arrayLen(parts) LT 4)
			arrayAppend(parts, "0");
		parts[4] = val(parts[4]) + arguments.bumpBy;
		return arrayToList(parts, ",");
	}

	public string function decreaseScopeTimeoutMinutes(required string currentValue, numeric decreaseBy = 2){
		var parts = listToArray(trim(arguments.currentValue), ",");
		while(arrayLen(parts) LT 4)
			arrayAppend(parts, "0");

		var minutes = val(parts[3]) - arguments.decreaseBy;
		if(minutes GTE 0){
			parts[3] = minutes;
			return arrayToList(parts, ",");
		}

		var hours = val(parts[2]);
		if(hours GT 0){
			parts[2] = hours - 1;
			parts[3] = 60 + minutes;
			return arrayToList(parts, ",");
		}

		var days = val(parts[1]);
		if(days GT 0){
			parts[1] = days - 1;
			parts[2] = 23;
			parts[3] = 60 + minutes;
			return arrayToList(parts, ",");
		}

		return bumpScopeTimeoutSeconds(arguments.currentValue);
	}

	public numeric function compareScopeTimeout(required string leftValue, required string rightValue){
		var leftParts = listToArray(trim(arguments.leftValue), ",");
		var rightParts = listToArray(trim(arguments.rightValue), ",");
		while(arrayLen(leftParts) LT 4) arrayAppend(leftParts, "0");
		while(arrayLen(rightParts) LT 4) arrayAppend(rightParts, "0");
		for(var i = 1; i LTE 4; i++){
			var diff = val(leftParts[i]) - val(rightParts[i]);
			if(diff NEQ 0)
				return diff;
		}
		return 0;
	}

	public string function bumpDefaultScopeTimeout(required string currentValue, required string maxValue){
		if(compareScopeTimeout(trim(arguments.currentValue), trim(arguments.maxValue)) EQ 0)
			return decreaseScopeTimeoutMinutes(arguments.currentValue);

		var minutesBumped = bumpScopeTimeoutMinutes(arguments.currentValue);
		if(compareScopeTimeout(minutesBumped, arguments.maxValue) LTE 0)
			return minutesBumped;

		return decreaseScopeTimeoutMinutes(arguments.currentValue);
	}

	public string function changeSameSiteValue(required string currentValue){
		switch(lCase(trim(arguments.currentValue))){
			case "lax":
				return "strict";
			case "strict":
				return "lax";
			case "none":
				return "lax";
			default:
				return "lax";
		}
	}

	public string function alternateSessionStorage(required string currentValue){
		return (lCase(trim(arguments.currentValue)) EQ "memory") ? "redis" : "memory";
	}

	public numeric function bumpMailNumber(required any currentValue, numeric bumpBy = 2){
		return val(arguments.currentValue) + arguments.bumpBy;
	}

	public string function flipMailBoolean(required any currentValue){
		return flipBooleanValue(arguments.currentValue);
	}

	public string function alternateMailServer(required string currentValue){
		var cv = trim(arguments.currentValue);
		return find("1", cv) ? replace(cv, "1", "", "all") : cv & "1";
	}

	public string function alternateMailUsername(required string currentValue){
		var cv = trim(arguments.currentValue);
		if(find("@", cv))
			return replace(cv, "@", "+ccs@", "one");
		return cv & "+ccs";
	}

	public string function alternateMailKeyAlias(required string currentValue){
		return len(trim(arguments.currentValue)) ? trim(arguments.currentValue) & "2" : "ccsalias";
	}

	public string function alternateMailKeystore(required string currentValue){
		var cv = trim(arguments.currentValue);
		return len(cv) ? cv & "2" : server.coldfusion.rootdir & "/ccs-test-mail.jks";
	}

	public string function alternateMailSeverity(required string currentValue){
		return (lCase(trim(arguments.currentValue)) EQ "debug") ? "warning" : "debug";
	}

	public string function alternateMailCharset(required string currentValue){
		return (uCase(trim(arguments.currentValue)) EQ "UTF-8") ? "ISO-8859-1" : "UTF-8";
	}

	public string function alternateMailDirectory(required string currentValue){
		var cv = trim(arguments.currentValue);
		return findNoCase("-ccs-test", cv) ? replace(cv, "-ccs-test", "", "all") : cv & "-ccs-test";
	}

	public struct function verifyMailServerConnection(){
		return new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().verifyMailServerConnection();
	}

	public string function bumpWebSocketPort(required any currentValue, numeric bumpBy = 2){
		return "" & (val(arguments.currentValue) + arguments.bumpBy);
	}

	public string function alternateWebSocketKeystore(required string currentValue){
		var cv = trim(arguments.currentValue);
		return len(cv) ? cv & "2" : server.coldfusion.rootdir & "/ccs-test-ws.jks";
	}

	public string function alternateWebSocketLogging(required string currentValue){
		return (lCase(trim(arguments.currentValue)) EQ "debug") ? "warning" : "debug";
	}

	public string function alternateSslCertificateLocation(required string currentValue){
		var cv = trim(arguments.currentValue);
		return findNoCase("-ccstest", cv) ? replace(cv, "-ccstest", "", "all") : cv & "-ccstest";
	}

	public string function alternateSslCertificateAlgorithm(required string currentValue){
		return (uCase(trim(arguments.currentValue)) EQ "RSA") ? "DSA" : "RSA";
	}

	public string function alternateDistinguishedName(required string currentValue){
		var defaultDn = "CN=ccstest,OU=QA,O=CCS,L=Test,ST=Test,C=US";
		return (trim(arguments.currentValue) EQ defaultDn) ? "" : defaultDn;
	}

	public string function alternateCertificateName(required string currentValue){
		var defaultName = "ccstestcert";
		return (trim(arguments.currentValue) EQ defaultName) ? "" : defaultName;
	}

	public string function flipChartCacheType(required any currentValue){
		return (lCase(trim("" & arguments.currentValue)) EQ "disk") ? "memory" : "disk";
	}

	public string function alternateChartCachePath(required string currentValue){
		var cv = replace(trim(arguments.currentValue), "/", "\", "all");
		var altPath = server.coldfusion.rootdir & "\tmpCache\ccs-chart-test-alt";
		if(lCase(cv) EQ lCase(altPath))
			return server.coldfusion.rootdir & "\tmpCache\CFFileServlet\_cf_chart";
		if(NOT directoryExists(altPath))
			directoryCreate(altPath);
		return altPath;
	}

	public string function alternateSolrHomePath(required string currentValue){
		var cv = replace(trim(arguments.currentValue), "/", "\", "all");
		var altPath = server.coldfusion.rootdir & "\tmpCache\ccs-solrhome-test-alt";
		if(lCase(cv) EQ lCase(altPath))
			return server.coldfusion.rootdir & "\jetty\multicore";
		if(NOT directoryExists(altPath))
			directoryCreate(altPath);
		return altPath;
	}

	public string function alternateDocumentHost(required string currentValue){
		var cv = trim(arguments.currentValue);
		if(cv EQ "127.0.0.1")
			return "127.0.0.2";
		if(cv EQ "127.0.0.2")
			return "127.0.0.1";
		return len(cv) ? cv & "1" : "127.0.0.1";
	}

	public string function bumpDocumentPort(required any currentValue, numeric bumpBy = 2){
		var port = val(arguments.currentValue);
		if(port LTE 0)
			return "" & (8100 + arguments.bumpBy);
		return "" & (port + arguments.bumpBy);
	}

	public string function alternateOpenOfficeDirectory(required string currentValue){
		var cv = replace(trim(arguments.currentValue), "/", "\", "all");
		var altPath = server.coldfusion.rootdir & "\lib\ccs-doc-test-alt";
		var defaultPath = server.coldfusion.rootdir & "\lib";
		if(lCase(cv) EQ lCase(altPath))
			return defaultPath;
		if(NOT directoryExists(altPath))
			directoryCreate(altPath);
		return altPath;
	}

	public string function alternateDocumentRemoteOpenOffice(required string currentValue){
		var parsed = listToArray(trim("" & arguments.currentValue), "|", false, true);
		var host = arrayLen(parsed) GTE 1 ? trim(parsed[1]) : "";
		var port = arrayLen(parsed) GTE 2 ? val(parsed[2]) : 0;
		if(NOT len(host) AND port LTE 0)
			return "127.0.0.1|8102";
		if(host EQ "127.0.0.1")
			return "127.0.0.2|" & (port GT 0 ? port + 2 : 8102);
		return "127.0.0.1|" & (port GT 0 ? port + 2 : 8102);
	}

	public struct function runMultiNodeDocumentSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true
	){
		return runMultiNodeBooleanSyncTest(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes,
			"currentPort",
			true
		);
	}

	private string function getApiAreaFromScriptPath(required string scriptPath){
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

	private string function alternateTemplateMode(required string currentValue){
		return (lCase(trim(arguments.currentValue)) EQ "summary") ? "tree" : "summary";
	}

	private string function alternateDebugTemplate(required string currentValue){
		var fileName = listLast(replace(trim(arguments.currentValue), "\", "/", "all"), "/");
		return (fileName EQ "classic.cfm") ? "dockable.cfm" : "classic.cfm";
	}

	private string function alternateConnectorPort(required string currentValue){
		return (trim(arguments.currentValue) EQ "8502") ? "8500" : "8502";
	}

	private string function alternateCfstatHost(required string currentValue){
		var host = trim(arguments.currentValue);
		return (host EQ "127.0.0.1") ? "localhost" : "127.0.0.1";
	}

	private string function alternateLineDebuggerPort(required string currentValue){
		return (val(arguments.currentValue) EQ 5005) ? "5007" : "5005";
	}

	private string function toggleTestIpInList(required string listValue, string testIp = "10.10.10.10"){
		var items = listToArray(trim(arguments.listValue), ",", false, true);
		var index = arrayFindNoCase(items, arguments.testIp);
		if(index)
			arrayDeleteAt(items, index);
		else
			arrayAppend(items, arguments.testIp);
		return arrayToList(items, ",");
	}

	private boolean function scopesListsMatch(required string list1, required string list2){
		return normalizeCommaList(replaceNoCase(arguments.list1, "clint", "client", "all")) EQ
			normalizeCommaList(replaceNoCase(arguments.list2, "clint", "client", "all"));
	}

	private string function pickAlternateScopesList(required string currentValue, string defaultValue = "cookie,cgi,form,client,url"){
		if(scopesListsMatch(arguments.currentValue, arguments.defaultValue)){
			var allOptions = ["application", "cookie", "server", "cgi", "form", "session", "client", "url", "request"];
			var chosenIndices = {};
			while(structCount(chosenIndices) LT 5){
				chosenIndices[randRange(1, arrayLen(allOptions))] = true;
			}
			var selectedList = "";
			for(var i = 1; i LTE arrayLen(allOptions); i++){
				if(structKeyExists(chosenIndices, i))
					selectedList = listAppend(selectedList, allOptions[i]);
			}
			if(NOT scopesListsMatch(selectedList, arguments.defaultValue))
				return selectedList;
		}
		return arguments.defaultValue;
	}

	private any function getNewSetValueForSetting(required string settingName, required any currentValue, string scriptPath = ""){
		var value = isSimpleValue(arguments.currentValue) ? trim("" & arguments.currentValue) : arguments.currentValue;

		switch(arguments.settingName){
			case "TimeoutRequestTimeLimit":
			case "watch.interval":
			case "RequestThrottleThreshold":
			case "RequestThrottleMemory":
			case "PostSizeLimit":
			case "PostParametersLimit":
			case "MaxUnzipRatio":
			case "MaxThreadCountForParallelCalls":
			case "maxPoolSize":
			case "MaxOutputBufferSize":
			case "keepAliveTime":
			case "InMemoryFileSystemLimit":
			case "InMemoryFileSystemApplicationLimit":
			case "corePoolSize":
			case "corePoolSizeCloudServices":
			case "maxPoolSizeCloudServices":
			case "keepAliveTimeCloudServices":
			case "solrbuffersize":
			case "solrport":
			case "solrhttpsport":
			case "requestLimit":
			case "WebServiceLimit":
			case "CFCLimit":
			case "ReportThreads":
			case "CFThreadLimit":
			case "RequestQueueTimeout":
				return bumpNumeric(val(value));
			case "ORMSearchIndexDirectory":
				return toggleOrmSearchIndexTestPath(value);
			case "CFFormScriptSrc":
				return toggleWebDirectoryPathSuffix(value);
			case "GoogleMapKey":
				return toggleStringMarker(value);
			case "solrhost":
				return (value EQ "localhost") ? "127.0.0.1" : "localhost";
			case "solrwebapp":
				return toggleStringMarker(len(value) ? value : "solr", "-ccs");
			case "solrhome":
				return alternateSolrHomePath(value);
			case "httpsenabled":
				requireBoolean(len(value) ? value : "false", arguments.settingName);
				return flipBooleanValue(len(value) ? value : "false");
			case "cxt":
				return (value EQ "CCSTestLanguage") ? "CCSTestLanguageUpdated" : "CCSTestLanguage";
			case "wsversion":
				return (trim(value) EQ "1") ? "2" : "1";
			case "CCSTestWebService":
				return (trim(value) EQ "http://localhost:8500/cfsuite/ccssuite/testsuite/DataServices/webServices/ccsTestService.wsdl")
					? "http://localhost:8500/cfsuite/ccssuite/testsuite/DataServices/webServices/ccsTestServiceUpdated.wsdl"
					: "http://localhost:8500/cfsuite/ccssuite/testsuite/DataServices/webServices/ccsTestService.wsdl";
			case "CCSTestWebServiceName":
				return (trim(value) EQ "CCSTestWebServiceName") ? "" : "CCSTestWebServiceName";
			case "CCSTestCloudCredential":
				return (trim(value) EQ "CCSTestCloudCredential") ? "" : "CCSTestCloudCredential";
			case "CCSTestPDFName":
			case "CCSTestPDFService":
				return (trim(value) EQ "CCSTestPDFName") ? "" : "CCSTestPDFName";
			case "CCSTestPDFHostName":
				return (trim(value) EQ "127.0.0.2") ? "" : "127.0.0.2";
			case "CCSTestPDFPort":
				return (trim(value) EQ "8998") ? "" : "8998";
			case "CCSTestPDFWeight":
				return (trim(value) EQ "2") ? "" : "2";
			case "CCSTestPDFHttpsEnabled":
				return (trim(value) EQ "true" OR (isBoolean(value) AND value)) ? "" : "true";
			case "CCSTestPDFEngine":
				return (trim(value) EQ "2.0") ? "1.0" : "2.0";

			// System Probes - Global Settings
			// System Probes - Global Settings
			case "CCSTestProbeAlarmEmail":
			case "CCSTestSystemProbeAlarmEmail":
				return (trim(value) EQ "probe-alt@example.com") ? "test-probe@example.com" : "probe-alt@example.com";
			case "CCSTestProbeAlarmEmailFrom":
			case "CCSTestSystemProbeAlarmEmailFrom":
				return (trim(value) EQ "probe-from-alt@example.com") ? "probe-from@example.com" : "probe-from-alt@example.com";
			case "CCSTestProbeCfmUrl":
			case "CCSTestSystemProbeCfmUrl":
				return (trim(value) EQ "http://127.0.0.2:8500/CFIDE/probe.cfm") ? "http://127.0.0.1:8500/CFIDE/probe.cfm" : "http://127.0.0.2:8500/CFIDE/probe.cfm";
			case "CCSTestProbeUsername":
			case "CCSTestSystemProbeUsername":
				return (trim(value) EQ "testprobeuser2") ? "testprobeuser" : "testprobeuser2";
			case "CCSTestProbePassword":
			case "CCSTestSystemProbePassword":
				return (trim(value) EQ "probeSecret2") ? "probeSecret1" : "probeSecret2";

			// System Probes - Probe Definition & Properties (Task alias: CCSTestProbe / CCSTestSystemProbe)
			case "CCSTestProbeTaskName":
			case "CCSTestSystemProbeTaskName":
				return (trim(value) EQ "CCSTestProbe" OR trim(value) EQ "CCSTestSystemProbe") ? "" : "CCSTestProbe";
			case "CCSTestProbeIntervalHour":
			case "CCSTestSystemProbeIntervalHour":
				return (trim(value) EQ "2") ? "1" : "2";
			case "CCSTestProbeIntervalMin":
			case "CCSTestSystemProbeIntervalMin":
				return (trim(value) EQ "30") ? "15" : "30";
			case "CCSTestProbeIntervalSec":
			case "CCSTestSystemProbeIntervalSec":
				return (trim(value) EQ "45") ? "30" : "45";
			case "CCSTestProbeCustomStartTime":
			case "CCSTestSystemProbeCustomStartTime":
				return (trim(value) EQ "01:00:00") ? "00:00:00" : "01:00:00";
			case "CCSTestProbeCustomEndTime":
			case "CCSTestSystemProbeCustomEndTime":
				return (trim(value) EQ "23:00:00") ? "23:59:59" : "23:00:00";
			case "CCSTestProbeScheduledURL":
			case "CCSTestSystemProbeScheduledURL":
				return (trim(value) EQ "http://127.0.0.2:8500/CFIDE/probe.cfm") ? "http://127.0.0.1:8500/CFIDE/probe.cfm" : "http://127.0.0.2:8500/CFIDE/probe.cfm";
			case "CCSTestProbeUsernameField":
			case "CCSTestSystemProbeUsernameField":
				return (trim(value) EQ "probeuser2") ? "probeuser" : "probeuser2";
			case "CCSTestProbePasswordField":
			case "CCSTestSystemProbePasswordField":
				return (trim(value) EQ "probepass2") ? "probepass" : "probepass2";
			case "CCSTestProbeRequestTimeout":
			case "CCSTestSystemProbeRequestTimeout":
				return (trim(value) EQ "120") ? "60" : "120";
			case "CCSTestProbeProxyServer":
			case "CCSTestSystemProbeProxyServer":
				return (trim(value) EQ "127.0.0.2") ? "127.0.0.1" : "127.0.0.2";
			case "CCSTestProbeProxyPort":
			case "CCSTestSystemProbeProxyPort":
				return (trim(value) EQ "8888") ? "8080" : "8888";
			case "CCSTestProbeMatchCheck":
			case "CCSTestSystemProbeMatchCheck":
				return (trim(value) EQ "1" OR (isBoolean(value) AND value)) ? "0" : "1";
			case "CCSTestProbeTrueMatch":
			case "CCSTestSystemProbeTrueMatch":
				return (trim(value) EQ "0") ? "1" : "0";
			case "CCSTestProbeMatchType":
			case "CCSTestSystemProbeMatchType":
				return (trim(value) EQ "regex") ? "string" : "regex";
			case "CCSTestProbeMatchValue":
			case "CCSTestSystemProbeMatchValue":
				return (trim(value) EQ "ProbeFailString") ? "ColdFusion" : "ProbeFailString";
			case "CCSTestProbeSendEmail":
			case "CCSTestSystemProbeSendEmail":
				return (trim(value) EQ "1" OR (isBoolean(value) AND value)) ? "0" : "1";
			case "CCSTestProbeExecuteCheck":
			case "CCSTestSystemProbeExecuteCheck":
				return (trim(value) EQ "1" OR (isBoolean(value) AND value)) ? "0" : "1";
			case "CCSTestProbeExecute":
			case "CCSTestSystemProbeExecute":
				return (trim(value) EQ "C:\Windows\System32\ping.exe") ? "C:\Windows\System32\cmd.exe" : "C:\Windows\System32\ping.exe";
			case "CCSTestProbePublish":
			case "CCSTestSystemProbePublish":
				return (trim(value) EQ "1" OR (isBoolean(value) AND value)) ? "0" : "1";
			case "CCSTestProbePublishFile":
			case "CCSTestSystemProbePublishFile":
				return (trim(value) EQ "C:\ColdFusion2025\cfusion\logs\probe_out2.log") ? "C:\ColdFusion2025\cfusion\logs\probe_out.log" : "C:\ColdFusion2025\cfusion\logs\probe_out2.log";
			case "CCSTestProbePublishOverwrite":
			case "CCSTestSystemProbePublishOverwrite":
				return (trim(value) EQ "1" OR (isBoolean(value) AND value)) ? "0" : "1";
			case "CCSTestProbeResolveURL":
			case "CCSTestSystemProbeResolveURL":
				return (trim(value) EQ "1" OR (isBoolean(value) AND value)) ? "0" : "1";
			case "CCSTestProbeEventHandler":
			case "CCSTestSystemProbeEventHandler":
				return (trim(value) EQ "cfsuite.probeHandler2") ? "cfsuite.probeHandler" : "cfsuite.probeHandler2";
			case "CCSTestProbeExclude":
			case "CCSTestSystemProbeExclude":
				return (trim(value) EQ "2099-01-02") ? "2099-01-01" : "2099-01-02";
			case "CCSTestProbeOnMisfire":
			case "CCSTestSystemProbeOnMisfire":
				return (trim(value) EQ "fire_now") ? "ignore" : "fire_now";
			case "CCSTestProbeOnException":
			case "CCSTestSystemProbeOnException":
				return (trim(value) EQ "pause") ? "resume" : "pause";
			case "CCSTestProbeOnComplete":
			case "CCSTestSystemProbeOnComplete":
				return (trim(value) EQ "probeCompleteAction2") ? "probeCompleteAction1" : "probeCompleteAction2";
			case "CCSTestProbePriority":
			case "CCSTestSystemProbePriority":
				return (trim(value) EQ "9") ? "5" : "9";
			case "CCSTestProbeRetryCount":
			case "CCSTestSystemProbeRetryCount":
				return (trim(value) EQ "5") ? "3" : "5";
			case "CCSTestProbeCluster":
			case "CCSTestSystemProbeCluster":
				return (trim(value) EQ "1" OR (isBoolean(value) AND value)) ? "0" : "1";
			case "CCSTestCloudVendor":
				return (trim(value) EQ "AWS") ? "" : "AWS";
			case "CCSTestCloudRegion":
				return (trim(value) EQ "us-east-1") ? "" : "us-east-1";
			case "CCSTestCloudAccessKey":
				return (trim(value) EQ "AKIACCSTESTFAKEKEY") ? "" : "AKIACCSTESTFAKEKEY";
			case "CCSTestCloudSecretKey":
				return (trim(value) EQ "ccsTestFakeSecret99") ? "" : "ccsTestFakeSecret99";
			case "CCSTestCloudSessionToken":
				return (trim(value) EQ "ccsTestFakeSessionToken99") ? "" : "ccsTestFakeSessionToken99";
			case "CCSTestAzureConnectionString":
				return (trim(value) EQ "DefaultEndpointsProtocol=https;AccountName=ccstest;AccountKey=ccsTestFakeAzureKey99;EndpointSuffix=core.windows.net")
					? "" : "DefaultEndpointsProtocol=https;AccountName=ccstest;AccountKey=ccsTestFakeAzureKey99;EndpointSuffix=core.windows.net";
			case "CCSTestGcpProjectId":
				return (trim(value) EQ "ccs-test-project") ? "" : "ccs-test-project";
			case "CCSTestGcpCredentialJsonFilepath":
				return (trim(value) EQ "C:\ccssuite-test\ccs-test-key.json") ? "" : "C:\ccssuite-test\ccs-test-key.json";
			case "CCSTestCloudConfigAlias":
				return (trim(value) EQ "CCSTestCloudConfigAlias") ? "" : "CCSTestCloudConfigAlias";
			case "CCSTestCloudConfigServiceName":
				return (trim(value) EQ "S3") ? "SQS" : "S3";
			case "CCSTestCloudConfigApiCallAttemptTimeout":
				return (trim(value) EQ "10s") ? "20s" : "10s";
			case "CCSTestCloudConfigApiCallTimeout":
				return (trim(value) EQ "30s") ? "60s" : "30s";
			case "CCSTestCloudConfigPathStyleAccess":
				return (trim(value) EQ "true") ? "false" : "true";
			case "CCSTestCloudConfigAccelerateMode":
				return (trim(value) EQ "true") ? "false" : "true";
			case "CCSTestCloudConfigDualStack":
				return (trim(value) EQ "true") ? "false" : "true";
			case "CCSTestCloudConfigChecksumValidation":
				return (trim(value) EQ "true") ? "false" : "true";
			case "CCSTestCloudConfigChunkedEncoding":
				return (trim(value) EQ "true") ? "false" : "true";
			case "CCSTestCloudConfigConnAcqTimeout":
				return (trim(value) EQ "10s") ? "20s" : "10s";
			case "CCSTestCloudConfigConnMaxIdle":
				return (trim(value) EQ "30s") ? "60s" : "30s";
			case "CCSTestCloudConfigConnTimeout":
				return (trim(value) EQ "10s") ? "20s" : "10s";
			case "CCSTestCloudConfigConnTTL":
				return (trim(value) EQ "60s") ? "120s" : "60s";
			case "CCSTestCloudConfigExpectContinue":
				return (trim(value) EQ "true") ? "false" : "true";
			case "CCSTestCloudConfigMaxConnections":
				return (trim(value) EQ "50") ? "100" : "50";
			case "CCSTestCloudConfigSocketTimeout":
				return (trim(value) EQ "30s") ? "60s" : "30s";
			case "CCSTestCloudConfigNonProxyHosts":
				return (trim(value) EQ "localhost") ? "127.0.0.1" : "localhost";
			case "CCSTestCloudConfigNtlmDomain":
				return (trim(value) EQ "CCSTESTDOMAIN1") ? "CCSTESTDOMAIN2" : "CCSTESTDOMAIN1";
			case "CCSTestCloudConfigNtlmWorkstation":
				return (trim(value) EQ "CCSTESTWS1") ? "CCSTESTWS2" : "CCSTESTWS1";
			case "CCSTestCloudConfigProxyUsername":
				return (trim(value) EQ "ccsProxyUser1") ? "ccsProxyUser2" : "ccsProxyUser1";
			case "CCSTestCloudConfigProxyPassword":
				return (trim(value) EQ "ccsProxyPass1") ? "ccsProxyPass2" : "ccsProxyPass1";
			case "CCSTestCloudConfigProxyEndpoint":
				// "Proxy endpoint path is not supported" — confirmed via direct testing that a bare
				// hostname is rejected; a full URI (scheme + host + port) is required.
				return (trim(value) EQ "http://proxy1.ccssuite-test.local:8080") ? "http://proxy2.ccssuite-test.local:8080" : "http://proxy1.ccssuite-test.local:8080";
			case "CCSTestCloudConfigNumRetries":
				return (trim(value) EQ "3") ? "5" : "3";
			case "CCSTestCloudConfigRetryConditionType":
				return (trim(value) EQ "AND") ? "OR" : "AND";
			case "CCSTestCloudConfigRetryConditions":
				return (trim(value) EQ "StatusCode,StatusCode") ? "" : "StatusCode,StatusCode";
			case "CCSTestCloudConfigRetryCondition1StatusCodes":
			case "CCSTestCloudConfigRetryCondition2StatusCodes":
				return (trim(value) EQ "500,503") ? "429,502" : "500,503";
			case "CCSTestCloudConfigBackoffStrategyType":
				return (trim(value) EQ "EqualJitter") ? "FullJitter" : "EqualJitter";
			case "CCSTestCloudConfigBackoffBaseDelay":
				return (trim(value) EQ "100") ? "200" : "100";
			case "CCSTestCloudConfigBackoffMaxBackoffTime":
				return (trim(value) EQ "5000") ? "10000" : "5000";
			case "CCSTestCloudConfigBackoffFixedDelay":
				return (trim(value) EQ "200") ? "400" : "200";
			case "CCSTestCloudConfigThrottleBackoffStrategyType":
				return (trim(value) EQ "EqualJitter") ? "FullJitter" : "EqualJitter";
			case "CCSTestCloudConfigThrottleBackoffBaseDelay":
				return (trim(value) EQ "100") ? "200" : "100";
			case "CCSTestCloudConfigThrottleBackoffMaxBackoffTime":
				return (trim(value) EQ "5000") ? "10000" : "5000";
			case "CCSTestCloudConfigThrottleBackoffFixedDelay":
				return (trim(value) EQ "200") ? "400" : "200";
			case "CCSTestGraphqlClientAlias":
				return (trim(value) EQ "CCSTestGraphqlClientAlias") ? "" : "CCSTestGraphqlClientAlias";
			case "CCSTestGraphqlServiceName":
				return (trim(value) EQ "CCSTestGraphqlServiceName") ? "" : "CCSTestGraphqlServiceName";
			case "CCSTestGraphqlRootPackage":
				return (trim(value) EQ "root") ? "rootPackage2" : "root";
			case "CCSTestGraphqlSchemaPath":
				return (trim(value) EQ "schema/ccsTestPath1.json") ? "schema/ccsTestPath2.json" : "schema/ccsTestPath1.json";
			case "CCSTestGraphqlSchemaPathEnabled":
				// no stored boolean exists for this (see graphqlConfigUtil.cfc) — "true"/"false" here
				// mean "recreate the service in schema-path mode" / "...in service-URL mode".
				return (trim(value) EQ "true") ? "false" : "true";
			case "CCSTestGraphqlServiceUrl":
				return (trim(value) EQ "http://localhost/ccssuite-test/schema1.graphql")
					? "http://localhost/ccssuite-test/schema2.graphql"
					: "http://localhost/ccssuite-test/schema1.graphql";
			case "CCSTestGraphqlHeaderKey":
				return (trim(value) EQ "CCSTestHeaderKey") ? "" : "CCSTestHeaderKey";
			case "CCSTestGraphqlHeaderValue":
				return (trim(value) EQ "ccsTestHeaderValue1") ? "ccsTestHeaderValue2" : "ccsTestHeaderValue1";
			case "CCSTestWebServiceAuthType":
				// cycle through the real dropdown's default first: a freshly-registered service
				// starts at NONE (the admin UI's own default selection), so the silent setup
				// pass creates it at "none" and the visible/measured pass is the real none-\>basic
				// transition, matching what an admin actually sees before making a change.
				if(trim(value) EQ "none")
					return "basic";
				if(trim(value) EQ "basic")
					return "ntlm";
				if(trim(value) EQ "ntlm")
					return "none";
				return "none";
			case "CCSTestWebServiceTimeout":
				// cycle through the real field's own default first: an unspecified Timeout is
				// stored as 0 (confirmed via direct testing), so the silent setup pass creates
				// it at "0" and the visible/measured pass is the real 0->30 transition.
				if(trim(value) EQ "0")
					return "30";
				if(trim(value) EQ "30")
					return "0";
				return "0";
			case "CCSTestWebServiceProxyServer":
				// Proxy Server's real default is blank (no proxy configured), so this follows
				// the WSDL URL field's plain empty-\>create-\>update pattern rather than
				// Authentication Type/Timeout's non-empty default. Both values must be real,
				// resolvable hostnames — setWebService() actually attempts to fetch the WSDL
				// through whatever proxy is given, and an unresolvable host throws
				// UnknownHostException and aborts the registration entirely.
				return (trim(value) EQ "localhost") ? "127.0.0.1" : "localhost";
			case "CCSTestWebServiceProxyPort":
				// Proxy Port's real default is blank, same empty-\>create-\>update pattern as
				// Proxy Server. Unlike Proxy Server, a port with no server given isn't exercised
				// as an actual proxy connection, so any real port number is safe here.
				return (trim(value) EQ "8080") ? "8888" : "8080";
			case "CCSTestWebServiceProxyUsername":
				// Proxy Username's real default is blank, same empty-\>create-\>update pattern.
				// Like Proxy Port, a username with no server given isn't exercised as an actual
				// proxy connection, so any value is safe here.
				return (trim(value) EQ "ccsProxyUser1") ? "ccsProxyUser2" : "ccsProxyUser1";
			case "CCSTestWebServiceProxyPassword":
				// Proxy Password's real default is blank, same empty-\>create-\>update pattern.
				// Stored in plain text in neo-xmlrpc.xml (confirmed via direct testing, unlike
				// the mail/Solr Server password fields), so no encryption-leniency needed here.
				return (trim(value) EQ "ccsProxyPass1") ? "ccsProxyPass2" : "ccsProxyPass1";
			case "CCSTestRestService":
				// Root Path's real default is blank (no such mapping registered), so this
				// follows the same plain empty-\>create-\>update pattern as the Web Service
				// Name test — the tracked "value" is the registered root path itself.
				return new cfsuite.ccssuite.utils.restServicesConfigUtil().init().getTestRootPath();
			case "CCSTestRestServiceHost":
				return (trim(value) EQ "localhost:8500") ? "localhost:9999" : "localhost:8500";
			case "CCSTestRestServiceMapping":
				return (trim(value) EQ "CCSTestRestService") ? "CCSTestRestService2" : "CCSTestRestService";
			case "CCSTestRestServiceIsDefault":
				return (trim(value) EQ "true") ? "false" : "true";
			case "CompileExtForInclude":
			case "BlockedExtForFileUpload":
				return toggleCommaListToken(value, "CCSTEST");
			case "SiteWideErrorHandler":
				return toggleErrorHandlerPath(value, "siteWide");
			case "MissingTemplateHandler":
				return toggleErrorHandlerPath(value, "missingTemplate");
			case "RequestQueueTimeoutPage":
				return toggleRequestQueueTimeoutPage(value);
			case "serverCFC":
				return (value EQ "Server") ? "Server_ccstest" : "Server";
			case "SecureJSONPrefix":
				return (value EQ "//") ? "**" : "//";
			case "AppCFCLookupOrder":
				return (val(value) EQ 1) ? 2 : 1;
			case "PURGE_INTERVAL":
				return bumpPurgeInterval(value);
			case "clientStorage":
				return flipClientStorage(value);
			case "ClientStoreDatasource":
				return new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().getClientVariablesTestDatasourceName();
			case "ClientStoreDescription":
				return toggleStringMarker(value, "_ccs");
			case "ClientStorePurge":
			case "ClientStoreDisableGlobals":
				requireBoolean(value, arguments.settingName);
				return flipClientStoreBoolean(value);
			case "ClientStorePurgeDays":
				return bumpNumeric(val(value));
			case "SessionCookieTimeout":
				return bumpNumeric(val(value), 10);
			case "sessionStorage":
				return alternateSessionStorage(value);
			case "SessionCookieSamesite":
				return changeSameSiteValue(value);
			case "sessionScopeMaxTimeout":
			case "applicationScopeMaxTimeout":
				return bumpScopeTimeoutMinutes(value);
			case "sessionScopeTimeout":
				return bumpScopeTimeoutMinutes(value);
			case "enableJ2EESessions":
			case "enableSessionScope":
			case "enableApplicationScope":
			case "HttpOnlySessionCookie":
			case "SecureSessionCookie":
			case "CFInternalCookieDisableUpdate":
				return flipBooleanValue(len(value) ? value : "false");
			case "server":
				return alternateMailServer(value);
			case "username":
				return alternateMailUsername(value);
			case "password":
				return "ccsTestMailPass99";
			case "keystorepassword":
				if(lCase(getApiAreaFromScriptPath(arguments.scriptPath)) EQ "websocket")
					return "ccsWsKeystorePass99";
				return "ccsTestKeyPass99";
			case "keypassword":
				return "ccsTestKeyPass99";
			case "port":
				if(lCase(getApiAreaFromScriptPath(arguments.scriptPath)) EQ "websocket")
					return bumpWebSocketPort(val(value));
				if(lCase(getApiAreaFromScriptPath(arguments.scriptPath)) EQ "document")
					return bumpDocumentPort(val(value));
				return bumpMailNumber(val(value));
			case "timeout":
			case "schedule":
			case "maxdeliverythreads":
			case "maxmessagesinmemory":
				return bumpMailNumber(val(value));
			case "sign":
			case "usessl":
			case "usetls":
			case "spoolenable":
			case "allowdownload":
			case "mailsentloggingenable":
			case "maintainconnections":
			case "spooltomemory":
				return flipMailBoolean(value);
			case "backupmailservers":
				return compareNoCase(trim(value), "localhost:2525") EQ 0 ? "localhost:2526" : "localhost:2525";
			case "keystore":
				return alternateMailKeystore(value);
			case "keyalias":
				return alternateMailKeyAlias(value);
			case "severity":
				return alternateMailSeverity(value);
			case "defaultmailcharset":
				return alternateMailCharset(value);
			case "spooldir":
			case "undeliverdir":
				return alternateMailDirectory(value);
			case "startWebSocketService":
			case "enableWebsocketOverProxyPort":
			case "startListenerOnNormalPort":
			case "sslEnabled":
			case "flashFallBack":
			case "clustered":
				return flipBooleanValue(value);
			case "sslport":
			case "multicastPort":
			case "flashPolicyPort":
				return bumpWebSocketPort(val(value));
			case "maxFrameSize":
			case "socketTimeout":
				return bumpMailNumber(val(value));
			case "keystoreLocation":
				return alternateWebSocketKeystore(value);
			case "logging":
				return alternateWebSocketLogging(value);
			case "CacheType":
				return flipChartCacheType(value);
			case "CacheSize":
			case "TimeToLive":
				return bumpMailNumber(val(value));
			case "CachePath":
				return alternateChartCachePath(value);
			case "CertificateLocation":
				return alternateSslCertificateLocation(value);
			case "CertificatePassword":
				return "ccsTestCertPass99";
			case "CertificateAlgorithm":
				return alternateSslCertificateAlgorithm(value);
			case "DistinguishedName":
				return alternateDistinguishedName(value);
			case "CertificateName":
				return alternateCertificateName(value);
			case "UseSslCertificate":
			case "SslHttpsEnabled":
			case "SslHttpEnabled":
				requireBoolean(len(value) ? value : "true", arguments.settingName);
				return flipBooleanValue(len(value) ? value : "true");
			case "openOfficeDirectory":
				return alternateOpenOfficeDirectory(value);
			case "remoteOpenOffice":
				return alternateDocumentRemoteOpenOffice(value);
			case "hostname":
				if(lCase(getApiAreaFromScriptPath(arguments.scriptPath)) EQ "document")
					return alternateDocumentHost(value);
				return toggleStringMarker(value);
			case "template_mode":
				return alternateTemplateMode(value);
			case "debug_template":
				return alternateDebugTemplate(value);
			case "cfconnectorport":
				return alternateConnectorPort(value);
			case "cfstatHost":
				return alternateCfstatHost(value);
			case "variables_scopes":
				return pickAlternateScopesList(value);
			case "debuggingIpAddress":
				return toggleTestIpInList(value);
			case "LINE_DEBUGGER_ENABLED":
				requireBoolean(value, arguments.settingName);
				return flipBooleanValue(value);
			case "LINE_DEBUGGER_PORT":
				return alternateLineDebuggerPort(value);
			case "MAX_DEBUG_SESSIONS":
				return bumpNumeric(val(value), 2);
			case "template_highlight_minimum":
			case "cfmetrics.pullfreq":
			case "LogRequestTimeLimit":
			case "slowRequestTimeLimit":
				return bumpNumeric(val(value), 20);
			case "MaxArchives":
				return bumpNumeric(val(value));
			case "MaxFileSize":
				return bumpNumeric(val(value), 100);
			case "logDirectory":
				return toggleWebDirectoryPathSuffix(value);
			case "enableOSLogging":
				requireBoolean(value, arguments.settingName);
				return flipBooleanValue(value);
			case "LogSlowRequests":
				requireBoolean(value, arguments.settingName);
				return flipBooleanValue(value);
			case "watch.watchEnabled":
				requireBoolean(value, arguments.settingName);
				return flipBooleanValue(value);
			case "TemplateCacheSize":
			case "maxcachecount":
			case "jcsservermaxidle":
			case "jcsservermaxlife":
			case "jcsservermaxobjects":
			case "memcachedTimeToIdleSeconds":
			case "memcachedTimeToLiveSeconds":
			case "memcachedMaxElementsInMemory":
			case "redisTimeToIdleSeconds":
			case "redisTimeToLiveSeconds":
			case "redisMaxElementsInMemory":
			case "sessionStorageTimeout":
				return bumpNumeric(val(value));
			case "redisCacheStorageHost":
			case "sessionStorageHost":
				return trim(value) EQ "127.0.0.1" ? "localhost" : "127.0.0.1";
			case "redisCacheStoragePort":
			case "sessionStoragePort":
				return val(value) EQ 6379 ? 6380 : 6379;
			case "redisCacheStoragePassword":
			case "sessionStoragePassword":
				return "ccssuite-redis-test-" & createUUID();
			case "jcsdsnname":
				return structKeyExists(url, "jcsTestDatasource") ? trim(url.jcsTestDatasource) : "";
			case "MemcachedServer":
				return (trim(value) EQ "127.0.0.1:11211,127.0.0.1:11212") ? "127.0.0.1:11213,127.0.0.1:11214" : "127.0.0.1:11211,127.0.0.1:11212";
			case "memcachedEternal":
			case "jcsservereternal":
			case "redisSessionStorageCluster":
			case "redisCacheStorageIsSSL":
			case "reuseRedisCachingForSessionStorage":
			case "sessionStorageSSLEnabled":
			case "CFLoginUseSessionStorageRedis":
			case "redisEternal":
			case "TrustedCache":
			case "SaveClassFiles":
			case "ComponentCache":
			case "InRequestTemplateCache":
			case "CacheWebServerPaths":
			case "enableInternalQueryCache":
				requireBoolean(value, arguments.settingName);
				return flipBooleanValue(value);
			case "ServerCacheType":
				return (val(value) EQ 0) ? 1 : 0;
			case "SiteUrl":
				// Package Manager's real default is Adobe's own update-site URL, not a boolean —
				// falling through to the generic boolean default here threw "invalid current
				// setting" on every run. Cycles between two fixed test URLs instead, restored to
				// the real value afterward like every other field in this suite.
				return (trim(value) EQ "https://ccssuite-test.local/update-site-1") ? "https://ccssuite-test.local/update-site-2" : "https://ccssuite-test.local/update-site-1";
			case "PackagesSiteUrl":
				return (trim(value) EQ "https://ccssuite-test.local/packages-site-1") ? "https://ccssuite-test.local/packages-site-2" : "https://ccssuite-test.local/packages-site-1";
			case "ProxyHost":
				return (trim(value) EQ "proxy1.ccssuite-test.local") ? "proxy2.ccssuite-test.local" : "proxy1.ccssuite-test.local";
			case "ProxyPort":
				return bumpNumeric(val(value));
			case "ProxyUsername":
				return (trim(value) EQ "ccsPmtProxyUser1") ? "ccsPmtProxyUser2" : "ccsPmtProxyUser1";
			case "ProxyPassword":
				return (trim(value) EQ "ccsPmtProxyPass1") ? "ccsPmtProxyPass2" : "ccsPmtProxyPass1";
			case "NotificationEmails":
				return (trim(value) EQ "ccstest1@ccssuite-test.local") ? "ccstest2@ccssuite-test.local" : "ccstest1@ccssuite-test.local";
			case "NotificationFromEmail":
				return (trim(value) EQ "ccstest-from1@ccssuite-test.local") ? "ccstest-from2@ccssuite-test.local" : "ccstest-from1@ccssuite-test.local";
			case "CheckInterval":
				return bumpNumeric(val(value));
			case "ajax_enabled":
			case "cfstat":
			case "database":
			case "exception":
			case "flashformcompileerrors":
			case "general":
			case "cfmetrics":
			case "template":
			case "enabled":
			case "robust_enabled":
			case "timer":
			case "trace":
			case "variables":
			case "developerProfile":
			default:
				requireBoolean(value, arguments.settingName);
				return flipBooleanValue(value);
		}
	}

	private struct function reportCachingPreflight(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		required string failureMessage,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all"
	){
		ensureTestConstants();
		initializeCcsNodeConfig(arguments.nodesScope);
		var nodeFrame = arguments.testDriver.getGenericTestFrame();
		var readDatasource = arguments.settingName EQ "jcsdsnname";
		var existingValues = readDatasource ? collectPresetValuesFromFrame(
			initTestFrame(arguments.testDriver, "jcsdsnname", arguments.scriptPath, arguments.skipUnreachableNodes)
		) : {};
		var currentNodeKey = getPrimaryNodeKeyFromFrame(nodeFrame);
		var afterValues = readDatasource ? collectPresetValuesFromFrame(
			initTestFrame(arguments.testDriver, "jcsdsnname", arguments.scriptPath, arguments.skipUnreachableNodes)
		) : {};
		var rows = [];
		for(var setType in [application.testConstants.TEST_FRAME.PRIME_SET, application.testConstants.TEST_FRAME.NONPRIME_SET]){
			for(var nodeKey in nodeFrame[setType]){
				var metadata = getNodeMetadataForKey(nodeKey);
				var existing = arguments.settingName EQ "createtables" ? "Unchecked (not persisted)" : "No persisted folder value";
				if(readDatasource)
					existing = structKeyExists(existingValues, nodeKey) ? formatDisplayValue("jcsdsnname", existingValues[nodeKey]) : "(unavailable)";
				arrayAppend(rows, {
					nodeKey=nodeKey,
					nodeLabel=getURLFragFromNodeKey(nodeKey),
					existingValue=existing,
					updatedValue=readDatasource
						? (structKeyExists(afterValues, nodeKey) ? formatDisplayValue("jcsdsnname", afterValues[nodeKey]) : "(unavailable)")
						: existing,
					passed=false,
					verificationStatus=readDatasource ? "Not tested" : "Not synced with CCS (action input)",
					cluster=metadata.cluster,
					environment=metadata.environment
				});
			}
		}
		writeOutput("<b>Main node before and after (no update attempted):</b><br><br>");
		writeSyncVerificationTable(filterSyncVerificationRowsForNode(rows, currentNodeKey), arguments.settingName,
			"Before Update", "After (no update attempted)");
		writeOutput("<br/><br/><b>All instances values (no update attempted):</b><br><br>");
		writeSyncVerificationTable(sortSyncVerificationRowsCurrentFirst(rows), arguments.settingName,
			"Existing Value", "Current Value");
		return {passed=false, tested=false, failureMessage=arguments.failureMessage, existingValues=existingValues};
	}

	public struct function runMultiNodeBooleanSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all",
		boolean showEmptyNodes = false
	){
		if(arguments.settingName EQ "createtables")
			return reportCachingPreflight(arguments.testDriver, arguments.settingName, arguments.scriptPath,
				"Not synced with CCS: createTables is the boolean second argument of setJCSClusterDsnName(dsn, createTables), not a persisted setting. No tables were changed.",
				arguments.skipUnreachableNodes, arguments.nodesScope);
		if(arguments.settingName EQ "selectFolder")
			return reportCachingPreflight(arguments.testDriver, arguments.settingName, arguments.scriptPath,
				"Not synced with CCS: clearTemplateFolderFromCache(path) clears a local cache. Its path is an action input, not a persisted setting. No caches were cleared.",
				arguments.skipUnreachableNodes, arguments.nodesScope);
		var apiUtil = new cfsuite.ccssuite.utils.serverSettingsApiUtil().init();
		if(arguments.settingName EQ "ClientStoreDatasource")
			apiUtil.ensureClientVariablesTestDatasourceStoreAbsent();
		else if(listFindNoCase("ClientStoreDescription,ClientStorePurge,ClientStorePurgeDays,ClientStoreDisableGlobals", arguments.settingName))
			apiUtil.ensureClientVariablesTestStorePresent();

		initializeCcsNodeConfig(arguments.nodesScope);
		var initedTestFrame = initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes);
		var currentValue = getPresetValueFromFrame(initedTestFrame, arguments.settingName);
		var newSetValue = "";

		switch(arguments.settingName){
			case "applicationScopeTimeout":
				var appMaxFrame = initTestFrame(arguments.testDriver, "applicationScopeMaxTimeout", arguments.scriptPath);
				newSetValue = bumpDefaultScopeTimeout(currentValue, getPresetValueFromFrame(appMaxFrame, "applicationScopeMaxTimeout"));
				break;
			case "sessionScopeTimeout":
				var sessMaxFrame = initTestFrame(arguments.testDriver, "sessionScopeMaxTimeout", arguments.scriptPath);
				newSetValue = bumpDefaultScopeTimeout(currentValue, getPresetValueFromFrame(sessMaxFrame, "sessionScopeMaxTimeout"));
				break;
			default:
				newSetValue = getNewSetValueForSetting(arguments.settingName, currentValue, arguments.scriptPath);
		}

		if(arguments.settingName EQ "jcsdsnname" AND compareNoCase(trim(newSetValue), trim("" & currentValue)) EQ 0)
			return reportCachingPreflight(arguments.testDriver, arguments.settingName, arguments.scriptPath,
				len(trim("" & currentValue))
					? "Not tested: jcsTestDatasource must differ from the current JCS datasource to prove synchronization."
					: "Not tested: no JCS datasource is selected. Supply jcsTestDatasource naming a disposable datasource configured on the CCS peers.",
				arguments.skipUnreachableNodes, arguments.nodesScope);

		try {
			return runMultiNodeSettingSyncTest(
				arguments.testDriver,
				arguments.settingName,
				arguments.scriptPath,
				newSetValue,
				initedTestFrame,
				arguments.skipUnreachableNodes,
				arguments.nodesScope,
				arguments.showEmptyNodes
			);
		}
		catch(any failure){
			if(initedTestFrame[application.testConstants.TEST_FRAME.API_AREA] EQ "memoryvariables"
				AND new cfsuite.ccssuite.utils.memoryVariablesConfigUtil().init().isStorageSetting(arguments.settingName)){
				application.ccsTestNodesScope = arguments.nodesScope;
				try {
					arguments.testDriver.restoreOriginalSettingPerNode(initedTestFrame, collectPresetValuesFromFrame(initedTestFrame), arguments.settingName);
				}
				catch(any restoreFailure){
					writeOutput("<p>Warning: session-storage restoration may be incomplete.</p>");
				}
			}
			rethrow;
		}
	}

	public void function restoreMultiNodeSyncTest(
		required any testDriver,
		required struct syncTestResult,
		required string settingName
	){
		ensureTestConstants();
		if(NOT structKeyExists(arguments.syncTestResult, "scriptPath"))
			application.ccsTestNodesScope = "currentPort";
		else if(arguments.settingName EQ "remoteOpenOffice"){
			initializeCcsNodeConfig("all");
			var restoreFrame = initTestFrame(
				arguments.testDriver,
				arguments.settingName,
				arguments.syncTestResult.scriptPath,
				true
			);
			arguments.testDriver.clearDocumentRemoteOpenOfficeOnAllNodes(restoreFrame);
			application.ccsTestNodesScope = "currentPort";
		}
		else if(structKeyExists(arguments.syncTestResult, "initedTestFrame")
				AND isStruct(arguments.syncTestResult.initedTestFrame)
				AND NOT structIsEmpty(arguments.syncTestResult.initedTestFrame)
				AND structKeyExists(arguments.syncTestResult, "originalValue")){
			var apiArea = structKeyExists(arguments.syncTestResult.initedTestFrame, application.testConstants.TEST_FRAME.API_AREA)
				? arguments.syncTestResult.initedTestFrame[application.testConstants.TEST_FRAME.API_AREA]
				: "";
				if((lCase(apiArea) EQ "document"
					OR (lCase(apiArea) EQ "memoryvariables" AND new cfsuite.ccssuite.utils.memoryVariablesConfigUtil().init().isStorageSetting(arguments.settingName))
					OR listFindNoCase("enableInternalQueryCache,maxcachecount,redisCacheStoragePassword,jcsdsnname,jcsservermaxidle,jcsservermaxlife,jcsservermaxobjects,jcsservereternal", arguments.settingName))
					AND structKeyExists(arguments.syncTestResult, "existingValues")){
				initializeCcsNodeConfig("all");
				var restoreFrame = initTestFrame(
					arguments.testDriver,
					arguments.settingName,
					arguments.syncTestResult.scriptPath,
					true
				);
				restoreOriginalSettingPerNode(
					arguments.testDriver,
					restoreFrame,
					arguments.syncTestResult.existingValues,
					arguments.settingName
				);
			}
			else if(isDebuggingApiArea(apiArea)
					OR new cfsuite.ccssuite.utils.serverSettingsApiUtil().init().requiresPeerInstancePropagation(arguments.settingName, apiArea)){
				initializeCcsNodeConfig("all");
				var debuggingRestoreFrame = initTestFrame(
					arguments.testDriver,
					arguments.settingName,
					arguments.syncTestResult.scriptPath,
					true
				);
				restoreTest(
					arguments.testDriver,
					debuggingRestoreFrame,
					arguments.syncTestResult.originalValue,
					arguments.settingName
				);
				application.ccsTestNodesScope = "currentPort";
			}
			else {
				application.ccsTestNodesScope = "currentPort";
				restoreTest(
					arguments.testDriver,
					arguments.syncTestResult.initedTestFrame,
					arguments.syncTestResult.originalValue,
					arguments.settingName
				);
			}
		}
		else {
			application.ccsTestNodesScope = "currentPort";
		}
	}


	public void function restoreOriginalSettingPerNode(
		required any testDriver,
		required struct initedTestFrame,
		required struct nodeValues,
		required string settingName
	){
		arguments.testDriver.restoreOriginalSettingPerNode(arguments.initedTestFrame, arguments.nodeValues, arguments.settingName);
	}

	public struct function runMultiNodeSettingSyncTest(
		required any testDriver,
		required string settingName,
		required string scriptPath,
		required any newSetValue,
		required struct initedTestFrame,
		boolean skipUnreachableNodes = true,
		string nodesScope = "all",
		boolean showEmptyNodes = false,
		struct originalNodeValues = {}
	){
		ensureTestConstants();
		var showOriginalState = NOT structIsEmpty(arguments.originalNodeValues);

		initializeCcsNodeConfig("all");
		var existingValues = collectPresetValuesFromFrame(
			initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes)
		);

		initializeCcsNodeConfig(arguments.nodesScope);
		var syncTestFrame = initTestFrame(
			arguments.testDriver,
			arguments.settingName,
			arguments.scriptPath,
			arguments.skipUnreachableNodes
		);
		var originalValue = getPresetValueFromFrame(syncTestFrame, arguments.settingName);
		writeMultiNodeUpdateMessage(arguments.settingName, arguments.newSetValue, syncTestFrame, arguments.nodesScope);

		var syncResult = runSyncTest(
			arguments.testDriver,
			syncTestFrame,
			arguments.settingName,
			arguments.newSetValue
		);
		initializeCcsNodeConfig("currentPort");
		var actualValues = collectPresetValuesFromFrame(
			initTestFrame(arguments.testDriver, arguments.settingName, arguments.scriptPath, arguments.skipUnreachableNodes)
		);
		initializeCcsNodeConfig(arguments.nodesScope);
		var apiArea = structKeyExists(syncTestFrame, application.testConstants.TEST_FRAME.API_AREA)
			? syncTestFrame[application.testConstants.TEST_FRAME.API_AREA]
			: "";
		var showAllNodes = arguments.nodesScope EQ "all" OR arguments.showEmptyNodes;

		writeOutput(showOriginalState
			? "<b>Main node original state, prepared baseline, and updated value:</b><br><br>"
			: "<b>Main node before and after update:</b><br><br>");
		writeSyncVerificationTable(
			buildCurrentNodeVerificationRows(
				syncTestFrame,
				syncResult,
				existingValues,
				arguments.settingName,
				arguments.newSetValue,
				apiArea,
				actualValues
			),
			arguments.settingName,
			showOriginalState ? "Prepared baseline" : "Before Update",
			"After Update",
			true,
			arguments.originalNodeValues
		);

		if(showAllNodes OR syncResult.passed){
			// Re-check under the test's OWN requested scope, not a hardcoded "all": a test that
			// explicitly asked for nodesScope="currentPort" (e.g. ColdFusion Collections — a
			// genuinely per-instance, non-CCS-replicated resource) means peer nodes are out of
			// scope for this setting entirely. Forcing "all" here used to re-query them anyway,
			// which for areas backed by a shared external resource (e.g. all three CF instances in
			// this environment pointing at the same Solr server) made an unrelated peer look like it
			// had received a sync it never did — because there's only one Solr, not because CCS
			// pushed anything.
			initializeCcsNodeConfig(arguments.nodesScope);
			var afterFrame = initTestFrame(
				arguments.testDriver,
				arguments.settingName,
				arguments.scriptPath,
				arguments.skipUnreachableNodes
			);
			// Restore full cluster metadata for display purposes now that afterFrame is already
			// built under the requested (possibly narrower) scope — ccsConfigMap doubles as both
			// "which nodes get queried" and "cluster/environment labels for the table", and those
			// are different concerns: a currentPort test shouldn't query peers, but the table should
			// still be able to say WHICH cluster/environment each out-of-scope node belongs to.
			// initializeCcsNodeConfig() also overwrites the ccsTestNodesScope flag itself, so restore
			// the test's actual requested scope afterward — buildAllNodeSyncVerificationRows reads
			// that flag to tell "genuinely out of scope" apart from "unreachable".
			initializeCcsNodeConfig("all", true);
			application.ccsTestNodesScope = arguments.nodesScope;
			writeOutput(showOriginalState
				? "<br/><br/><b>All nodes: original state, prepared baseline, and updated value:</b><br><br>"
				: "<br/><br/><b>After updating the setting all instances values are:</b><br><br>");
			if(isInstanceLocalApiArea(apiArea, arguments.settingName))
				writeOutput("<p><em>Instance-local settings are stored per CF instance. Only the node where the setting was updated is expected to change; peer nodes may keep their previous values.</em></p>");
			applyExistingPresetValuesToFrame(afterFrame, existingValues);
			writeSyncVerificationTable(
				buildAllNodeSyncVerificationRows(afterFrame, existingValues, arguments.newSetValue, apiArea, showAllNodes),
				arguments.settingName,
				showOriginalState ? "Prepared baseline" : "Existing Value",
				"Updated Value",
				true,
				arguments.originalNodeValues
			);
		}

		application.ccsTestNodesScope = "currentPort";

		return {
			passed = syncResult.passed,
			initedTestFrame = syncTestFrame,
			originalValue = originalValue,
			syncResult = syncResult,
			existingValues = existingValues,
			scriptPath = arguments.scriptPath
		};
	}

	public struct function collectPresetValuesFromFrame(required struct testFrame){
		ensureTestConstants();
		var values = {};
		var setTypes = [
			application.testConstants.TEST_FRAME.PRIME_SET,
			application.testConstants.TEST_FRAME.NONPRIME_SET
		];

		for(var setType in setTypes){
			if(NOT structKeyExists(arguments.testFrame, setType))
				continue;
			for(var nodeKey in arguments.testFrame[setType].keyList()){
				values[nodeKey] = arguments.testFrame[setType][nodeKey][application.testConstants.TEST_FRAME.PRESET_VALUE];
			}
		}
		return values;
	}

	public void function applyExistingPresetValuesToFrame(required struct testFrame, required struct existingValues){
		ensureTestConstants();
		var setTypes = [
			application.testConstants.TEST_FRAME.PRIME_SET,
			application.testConstants.TEST_FRAME.NONPRIME_SET
		];

		for(var setType in setTypes){
			if(NOT structKeyExists(arguments.testFrame, setType))
				continue;
			for(var nodeKey in arguments.testFrame[setType].keyList()){
				arguments.testFrame[setType][nodeKey][application.testConstants.TEST_FRAME.POSTSET_VALUE] =
					arguments.testFrame[setType][nodeKey][application.testConstants.TEST_FRAME.PRESET_VALUE];
				if(structKeyExists(arguments.existingValues, nodeKey))
					arguments.testFrame[setType][nodeKey][application.testConstants.TEST_FRAME.PRESET_VALUE] = arguments.existingValues[nodeKey];
			}
		}
	}

	public struct function runSyncTest(
		required any testDriver,
		required struct initedTestFrame,
		required string settingName,
		required any newSetValue
	){
		var postSyncFrame = arguments.testDriver.setAndGetSyncedValues(
			duplicate(arguments.initedTestFrame),
			arguments.newSetValue,
			arguments.settingName
		);
		var expectedPostSetFrame = arguments.testDriver.getExpectedTestFrame(
			duplicate(arguments.initedTestFrame),
			arguments.newSetValue
		);
		return {
			postSyncFrame = postSyncFrame,
			expectedPostSetFrame = expectedPostSetFrame,
			passed = arguments.testDriver.syncedFramesMatch(postSyncFrame, expectedPostSetFrame)
		};
	}

	public void function restoreTest(required any testDriver, required struct initedTestFrame, required any originalValue, required string settingName){
		arguments.testDriver.restoreOriginalSetting(arguments.initedTestFrame, arguments.originalValue, arguments.settingName);
	}

	public string function getQatestResultMessage(required boolean passed, string settingName = "", string failureMessage = ""){
		if(NOT arguments.passed AND len(arguments.failureMessage))
			return "setting values NOT as expected. " & arguments.failureMessage;
		if(NOT arguments.passed AND (left(lCase(arguments.settingName), 3) EQ "jcs"
			OR listFindNoCase("enableInternalQueryCache,maxcachecount,selectFolder,createtables,logicalPath,directoryPath,deleteMapping", arguments.settingName)
			OR new cfsuite.ccssuite.utils.memoryVariablesConfigUtil().init().isStorageSetting(arguments.settingName)))
			return "setting values NOT as expected. Not synced with CCS.";
		if(NOT arguments.passed AND left(lCase(arguments.settingName), 5) EQ "redis")
			return "setting values NOT as expected<br>Not synced with CCS<br>";
		return arguments.passed ? "setting values as expected<br>" : "setting values NOT as expected<br>";
	}

	/**
	 * Build per-node rows for sync verification display (cluster, preset, post-set, pass/fail).
	 */
	public array function buildSyncVerificationRows(required struct postSyncFrame, required newSetValue, string apiArea = "", boolean showEmptyNodes = false){
		ensureTestConstants();
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();

		var rows = [];
		var setTypes = [
			application.testConstants.TEST_FRAME.PRIME_SET,
			application.testConstants.TEST_FRAME.NONPRIME_SET
		];
		var settingName = arguments.postSyncFrame[application.testConstants.TEST_FRAME.CFSETTING];
		var instanceLocalArea = isInstanceLocalApiArea(arguments.apiArea, settingName);
		var apiUtil = new cfsuite.ccssuite.utils.serverSettingsApiUtil().init();
		var requireCacheSync = (lCase(arguments.apiArea) EQ "caching"
			OR listFindNoCase("mappings,scheduledtasks,fontmanagement,datasources,systemprobes,restservices", arguments.apiArea)
			OR (lCase(arguments.apiArea) EQ "memoryvariables" AND new cfsuite.ccssuite.utils.memoryVariablesConfigUtil().init().isStorageSetting(settingName)))
			AND (NOT structKeyExists(application, "ccsTestNodesScope") OR application.ccsTestNodesScope EQ "all");

		for(var setType in setTypes){
			if(NOT structKeyExists(arguments.postSyncFrame, setType))
				continue;

			for(var nodeKey in arguments.postSyncFrame[setType].keyList()){
				var actual = arguments.postSyncFrame[setType][nodeKey];

				var preVal = structKeyExists(actual, application.testConstants.TEST_FRAME.PRESET_VALUE)
					? actual[application.testConstants.TEST_FRAME.PRESET_VALUE] : "";
				var postVal = structKeyExists(actual, application.testConstants.TEST_FRAME.POSTSET_VALUE)
					? actual[application.testConstants.TEST_FRAME.POSTSET_VALUE] : "";
				if(NOT arguments.showEmptyNodes AND NOT len(trim("" & preVal)) AND NOT len(trim("" & postVal)))
					continue;

				var isCurrentNode = isCurrentServerNodeKey(nodeKey);
				var actuallySynced = apiUtil.setMatches(settingName, preVal, postVal, arguments.newSetValue, arguments.apiArea);
				var unchangedFromPreset = trim("" & postVal) EQ trim("" & preVal);
				var crossCluster = false;

				var passed = false;
				if(isCurrentNode){
					passed = actuallySynced;
				}
				else if(instanceLocalArea){
					passed = unchangedFromPreset;
				}
				else {
					// A peer node that legitimately stayed unchanged (e.g. a currentPort-scoped test)
					// is not a failure; only flag it if it changed to something unexpected.
					passed = requireCacheSync ? actuallySynced : (actuallySynced OR unchangedFromPreset);
				}

				var cluster = "N/A";
				var env = "N/A";
				if(structKeyExists(application, "ccsConfigMap") AND application.ccsConfigMap.keyExists(nodeKey)) {
					cluster = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.CLUSTER];
					env = application.ccsConfigMap[nodeKey][application.constants.CCS_CONFIG.ENVIRONMENT];
				}

				var currentKey = CGI.SERVER_NAME & "::" & CGI.SERVER_PORT;
				if(structKeyExists(application, "ccsConfigMap") AND application.ccsConfigMap.keyExists(currentKey)) {
					var currentCluster = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.CLUSTER];
					var currentEnv = application.ccsConfigMap[currentKey][application.constants.CCS_CONFIG.ENVIRONMENT];
					if (currentCluster NEQ cluster OR currentEnv NEQ env) {
						crossCluster = true;
						passed = unchangedFromPreset;
					}
				}

				// Sync State is a plain-language read of what actually happened on this node,
				// kept separate from Verification Status (pass/fail) because CCS mail sync runs on
				// an unpredictable schedule (see testDriver.syncedFramesMatch): a peer node that
				// simply hasn't caught up yet still "Passes" (that's correct, not a bug), but callers
				// reading only the pass/fail pill can't tell that apart from a node that actually synced.
				var syncState = "";
				if(isCurrentNode){
					syncState = actuallySynced ? "Applied" : "Not applied";
				}
				else if(crossCluster){
					syncState = "Different cluster/env";
				}
				else if(instanceLocalArea){
					syncState = "Not synced (instance-local)";
				}
				else if(actuallySynced){
					syncState = "Synced";
				}
				else if(unchangedFromPreset){
					syncState = requireCacheSync AND (left(lCase(settingName), 5) EQ "redis" OR left(lCase(settingName), 3) EQ "jcs"
						OR listFindNoCase("enableInternalQueryCache,maxcachecount", settingName)
							OR listFindNoCase("mappings,scheduledtasks,fontmanagement,datasources,systemprobes", arguments.apiArea)
						OR new cfsuite.ccssuite.utils.memoryVariablesConfigUtil().init().isStorageSetting(settingName))
						? "Not synced with CCS" : "Pending sync";
				}
				else {
					syncState = "Unexpected value";
				}

				arrayAppend(rows, {
					nodeKey = nodeKey,
					nodeLabel = getURLFragFromNodeKey(nodeKey),
					existingValue = formatDisplayValue(settingName, preVal),
					updatedValue = formatDisplayValue(settingName, postVal),
					verificationStatus = passed ? "Passed" : "Failed",
					passed = passed,
					syncState = syncState,
					cluster = len(trim("" & cluster)) ? cluster : "N/A",
					environment = len(trim("" & env)) ? env : "N/A",
					setType = setType
				});
			}
		}

		return sortSyncVerificationRowsCurrentFirst(rows);
	}

	private array function buildAllNodeSyncVerificationRows(
		required struct afterFrame,
		required struct existingValues,
		required any newSetValue,
		string apiArea = "",
		boolean showEmptyNodes = true
	){
		var rows = buildSyncVerificationRows(arguments.afterFrame, arguments.newSetValue, arguments.apiArea, arguments.showEmptyNodes);
		var rowKeys = {};
		for(var row in rows)
			rowKeys[row.nodeKey] = true;

		ensureTestConstants();
		if(NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();

		var allNodeKeys = arguments.existingValues.keyList();
		if(structKeyExists(application, "ccsConfigMap") AND NOT structIsEmpty(application.ccsConfigMap)){
			var testMgr = new cfsuite.ccssuite.testManager().init();
			allNodeKeys = listAppend(allNodeKeys, testMgr.getNodeKeysInPrimeEnvironment());
			var nonPrimeKeys = testMgr.getNodeKeysNotInPrimeEnvironment();
			if(len(nonPrimeKeys))
				allNodeKeys = listAppend(allNodeKeys, nonPrimeKeys);
		}

		for(var nodeKey in listToArray(allNodeKeys)){
			if(structKeyExists(rowKeys, nodeKey))
				continue;
			rowKeys[nodeKey] = true;

			var metadata = getNodeMetadataForKey(nodeKey);
			// Distinguish "we captured this node's value before the test ran, and it happens to be
			// blank" (hasCapturedValue — a real, known state, e.g. no collection existed there) from
			// "we never captured anything for this node at all" (truly unavailable, e.g. unreachable).
			// The old check (len(trim(existing))) conflated the two, showing "(unavailable)" even
			// when the real pre-test value was a legitimate empty string.
			var hasCapturedValue = structKeyExists(arguments.existingValues, nodeKey);
			var existing = hasCapturedValue ? arguments.existingValues[nodeKey] : "";
			var displayExisting = hasCapturedValue
				? formatDisplayValue(arguments.afterFrame[application.testConstants.TEST_FRAME.CFSETTING], existing)
				: "(unavailable)";
			// A test that explicitly scoped itself to nodesScope="currentPort" (a genuinely
			// per-instance, non-CCS-replicated resource) never intended to evaluate any other node
			// at all — that's not a skipped/unreachable node, it's out of scope by design, so an
			// empty existing value here is expected and should not read as a failure.
			var outOfScope = application.ccsTestNodesScope EQ "currentPort";
			arrayAppend(rows, {
				nodeKey = nodeKey,
				nodeLabel = getURLFragFromNodeKey(nodeKey),
				existingValue = displayExisting,
				updatedValue = displayExisting,
				verificationStatus = (hasCapturedValue OR outOfScope) ? "Passed" : "Failed",
				passed = (hasCapturedValue OR outOfScope),
				syncState = outOfScope ? "Out of scope (single-node test)" : (hasCapturedValue ? "Not re-checked (skipped/unreachable)" : "Unavailable"),
				cluster = metadata.cluster,
				environment = metadata.environment,
				setType = application.testConstants.TEST_FRAME.PRIME_SET
			});
		}

		return sortSyncVerificationRowsCurrentFirst(rows);
	}

	private string function escapeHtml(required any value){
		var text = "" & arguments.value;
		if(NOT len(trim(text)) OR trim(text) EQ "|")
			text = "(empty)";
		return replace(
			replace(
				replace(text, "&", "&amp;", "all"),
				"<", "&lt;", "all"
			),
			">", "&gt;", "all"
		);
	}

	private string function normalizeVerificationStatus(required boolean passed){
		return arguments.passed ? "Passed" : "Failed";
	}

	public void function writeSyncVerificationTable(
		required array rows,
		required string settingName,
		string existingValueLabel = "Existing Value",
		string updatedValueLabel = "Updated Value",
		boolean showVerificationStatus = true,
		struct originalNodeValues = {}
	){
		var isJcsDatasource = compareNoCase(arguments.settingName, "jcsdsnname") EQ 0;
		var showOriginalState = NOT structIsEmpty(arguments.originalNodeValues);
		initSyncVerificationPageStyles(true);
		writeOutput('<div class="ccs-sync-summary">');
		writeOutput('<table class="ccs-sync-table"><thead><tr>');
		writeOutput('<th>Node</th>');
		if(showOriginalState)
			writeOutput('<th>Original state</th>');
		if(isJcsDatasource)
			writeOutput('<th>Existing UI Selection</th>');
		writeOutput('<th>' & escapeHtml(isJcsDatasource ? "Saved Datasource (Before)" : arguments.existingValueLabel)
			& '</th><th>' & escapeHtml(isJcsDatasource ? "Saved Datasource (After)" : arguments.updatedValueLabel) & '</th>');
		if(arguments.showVerificationStatus)
			writeOutput('<th>Verification Status</th>');
		writeOutput('<th>Cluster</th><th>Environment</th></tr></thead><tbody>');

		for(var row in arguments.rows){
			var passed = structKeyExists(row, "passed") AND row.passed;
			var statusClass = passed ? "ccs-status-pass" : "ccs-status-fail";
			var statusLabel = structKeyExists(row, "verificationStatus") ? row.verificationStatus : normalizeVerificationStatus(passed);
			var envVal = structKeyExists(row, "environment") ? row.environment : "N/A";
			writeOutput('<tr>');
			writeOutput('<td class="node-cell">' & escapeHtml(row.nodeLabel) & '</td>');
			if(showOriginalState){
				var originalDisplay = structKeyExists(row, "nodeKey") AND structKeyExists(arguments.originalNodeValues, row.nodeKey)
					? formatDisplayValue(arguments.settingName, arguments.originalNodeValues[row.nodeKey]) : "(unavailable)";
				writeOutput('<td class="value-cell">' & escapeHtml(originalDisplay) & '</td>');
			}
			if(isJcsDatasource)
				writeOutput('<td class="value-cell">Empty (Select data source)</td>');
			writeOutput('<td class="value-cell">' & escapeHtml(row.existingValue) & '</td>');
			writeOutput('<td class="value-cell">' & escapeHtml(row.updatedValue) & '</td>');
			if(arguments.showVerificationStatus){
				writeOutput('<td><span class="ccs-status ' & statusClass & '">' & escapeHtml(statusLabel) & '</span></td>');
			}
			writeOutput('<td>' & escapeHtml(row.cluster) & '</td>');
			writeOutput('<td>' & escapeHtml(envVal) & '</td>');
			writeOutput('</tr>');
		}

		writeOutput('</tbody></table></div>');
	}

	private void function ensureSyncVerificationTableCssInHead(){
		initSyncVerificationPageStyles();
	}

	public void function initSyncVerificationPageStyles(boolean includeBodyStyles = true){
		if(structKeyExists(request, "ccsSyncTableCssWritten") AND request.ccsSyncTableCssWritten)
			return;
		request.ccsSyncTableCssWritten = true;
		try {
			cfhtmlhead(text=getSyncVerificationTableCss());
			cfhtmlhead(text='<link rel="stylesheet" href="/cfsuite/ccssuite/testsuite/assets/ccs-sync.css">');
		}
		catch(any e){
			request.ccsSyncTableCssInlineFallback = true;
		}
		if(arguments.includeBodyStyles AND (NOT structKeyExists(request, "ccsSyncTableCssBodyWritten") OR NOT request.ccsSyncTableCssBodyWritten)){
			request.ccsSyncTableCssBodyWritten = true;
			writeOutput(getSyncVerificationTableCss());
		}
	}

	private string function getSyncVerificationTableCss(){
		return arrayToList([
			"<style>",
			".ccs-sync-summary { font-family: Segoe UI, Arial, sans-serif; margin: 1rem 0 1.5rem; width: 100%; max-width: 100%; box-sizing: border-box; }",
			".ccs-sync-summary h3 { margin: 0 0 0.75rem; font-size: 1.1rem; font-weight: 600; color: rgb(26, 26, 26); }",
			".ccs-sync-summary .prime-node { color: rgb(85, 85, 85); font-size: 0.95rem; margin-bottom: 0.75rem; }",
			".ccs-sync-table { width: 100%; max-width: 100%; border-collapse: collapse; font-size: 0.92rem; box-shadow: 0 1px 3px rgba(0,0,0,0.08); table-layout: auto; }",
			".ccs-sync-table th { background: rgb(47, 64, 80); color: rgb(255, 255, 255); text-align: left; padding: 0.65rem 0.85rem; font-weight: 600; }",
			".ccs-sync-table td { padding: 0.6rem 0.85rem; border-bottom: 1px solid rgb(229, 231, 235); vertical-align: top; }",
			".ccs-sync-table tbody tr:nth-child(even) { background: rgb(248, 250, 252); }",
			".ccs-sync-table tbody tr:hover { background: rgb(238, 244, 255); }",
			".ccs-sync-table .node-cell { font-family: Consolas, monospace; font-weight: 600; color: rgb(30, 58, 95); }",
			".ccs-sync-table .value-cell { font-family: Consolas, monospace; }",
			".ccs-status { display: inline-block; padding: 0.2rem 0.55rem; border-radius: 999px; font-size: 0.8rem; font-weight: 700; letter-spacing: 0.02em; }",
			".ccs-status-pass { background: rgb(220, 252, 231); color: rgb(22, 101, 52); border: 1px solid rgb(134, 239, 172); }",
			".ccs-status-fail { background: rgb(254, 226, 226); color: rgb(153, 27, 27); border: 1px solid rgb(252, 165, 165); }",
			".ccs-status-pending { background: rgb(254, 243, 199); color: rgb(146, 64, 14); border: 1px solid rgb(252, 211, 77); }",
			".ccs-set-badge { display: inline-block; margin-left: 0.35rem; padding: 0.1rem 0.4rem; border-radius: 4px; font-size: 0.72rem; font-weight: 600; background: rgb(219, 234, 254); color: rgb(30, 64, 175); }",
			"</style>"
		], chr(10));
	}

}
