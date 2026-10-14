component {

	public void function ensureStarted(boolean forceReinit = false){
		if(NOT isDefined("application")){
			cfapplication(
				name = "ccs-test-suitev3133440",
				sessionManagement = false,
				clientManagement = false,
				applicationTimeout = createTimeSpan(0, 2, 0, 0)
			);
		}
		var needsStartup = arguments.forceReinit;
		if(NOT needsStartup){
			try {
				needsStartup = NOT (isDefined("application") AND structKeyExists(application, "testConstants"));
			}
			catch(any e){
				needsStartup = true;
			}
		}
		if(needsStartup)
			onApplicationStart();
	}

	function onApplicationStart(){
		application.constants = new cfsuite.ccssuite.constants().init();
		application.testConstants = new cfsuite.ccssuite.testConstants().init();

		if(lcase(CGI.HTTPS) EQ "off" OR CGI.HTTPS IS "")
			application.protocol = "http";
		else
			application.protocol = "https";

		application.ccsTestNodesScope = "currentPort";

		if(structKeyExists(application, "ccsConfig"))
			structDelete(application, "ccsConfig");
		if(structKeyExists(application, "ccsConfigAllNodesSnapshot"))
			structDelete(application, "ccsConfigAllNodesSnapshot");

		ccsDriver = new cfsuite.ccssuite.ccsDriver();
		application.ccsConfig = ccsDriver.getCCSConfigMapList();
		cflog(type="information", application=true, file="#application.applicationname#", text="ccsConfig: " & serializeJSON(application.ccsConfig));

		if(NOT isArray(application.ccsConfig) OR arrayLen(application.ccsConfig) EQ 0){
			writeOutput("<strong>CCS test suite cannot start:</strong> no CCS nodes were returned. Enable CCS in CF Administrator (Server Settings &gt; CCS), add nodes, and ensure internal Java access is allowed.<br>");
			return;
		}

		application.ccsConfigLoadedAt = now();

		testMgr = new cfsuite.ccssuite.testManager().init();
		application.ccsConfigMap = testMgr.getCCSConfigMap();
		cflog(type="information", application=true, file="#application.applicationname#", text="ccsConfigMap: " & serializeJSON(application.ccsConfigMap));

		application.primeNodeIndex = testMgr.setAndGetPrimeNodeIndex(3);
		application.primeNodeKey = testMgr.getPrimeNodeKey();

		cflog(type="information", application=true, file="#application.applicationname#", text="primeNode: #application.primeNodeKey# | same env: #testMgr.getNodeKeysInPrimeEnvironment()#");

		restCFCsDir = server.coldfusion.rootdir & application.constants.SYS_CONFIG.FILE_SEPARATOR & "wwwroot" &
				application.constants.SYS_CONFIG.FILE_SEPARATOR & "cfsuite" & application.constants.SYS_CONFIG.FILE_SEPARATOR & "ccssuite" &
				application.constants.SYS_CONFIG.FILE_SEPARATOR & "restCFCs";

		application.restsettings = { serviceMapping: "ccs" };
		this.restsettings.skipCFCWithError = true;

		try {
			rUtil = new cfsuite.ccssuite.utils.restUtil().init();
			if(NOT rUtil.restMappingExists(application.restsettings.serviceMapping)){
				if(rUtil.registerRestService(restCFCsDir, application.restsettings.serviceMapping, "localhost:#CGI.SERVER_PORT#", false)){
					cflog(type="information", application=true, file="#application.applicationname#", text="REST service mapping '#application.restsettings.serviceMapping#' registered.");
				}
				else{
					cflog(type="error", application=true, file="#application.applicationname#", text="REST mapping NOT registered — check password in constants.cfc.");
				}
			}
			else {
				cflog(type="information", application=true, file="#application.applicationname#", text="REST mapping '#application.restsettings.serviceMapping#' already exists.");
			}
		}
		catch(any e){
			cflog(type="error", application=true, file="#application.applicationname#", text="Application.onApplicationStart REST: #serializeJSON(e)#");
		}
	}

	function onRequestStart(){
		var forceReinit = structKeyExists(url, "reinit") AND (url.reinit EQ 1 OR url.reinit EQ "1");
		ensureStarted(forceReinit);

		var script = lCase(CGI.SCRIPT_NAME);
		var syncApiRequest = findNoCase("_getter", script) OR findNoCase("_setter", script);
		if(findNoCase("/testsuite/", script) AND NOT syncApiRequest){
			new cfsuite.ccssuite.utils.serverSettingsTestUtil().init().initSyncVerificationPageStyles(false);
		}
	}

	// function onError(string targetPage, any exception, string eventName){
	// 	var err = isStruct(arguments.exception) ? arguments.exception : { type = "unknown", message = "" & arguments.exception, detail = "" };
	// 	if(structKeyExists(err, "rootCause") AND isStruct(err.rootCause))
	// 		err = err.rootCause;

	// 	writeOutput("<h2>Application Error</h2>");
	// 	writeOutput("<p><strong>Event:</strong> " & encodeForHTML(arguments.eventName) & "</p>");
	// 	writeOutput("<p><strong>Page:</strong> " & encodeForHTML(arguments.targetPage) & "</p>");
	// 	writeOutput("<p><strong>Type:</strong> " & encodeForHTML(err.type) & "</p>");
	// 	writeOutput("<p><strong>Message:</strong> " & encodeForHTML(err.message) & "</p>");
	// 	if(len(trim(err.detail)))
	// 		writeOutput("<p><strong>Detail:</strong> " & encodeForHTML(err.detail) & "</p>");
	// 	if(structKeyExists(err, "stackTrace") AND len(trim(err.stackTrace)))
	// 		writeOutput("<pre>" & encodeForHTML(err.stackTrace) & "</pre>");
	// 	writeDump(var=err, label="exception");
	// }

}
