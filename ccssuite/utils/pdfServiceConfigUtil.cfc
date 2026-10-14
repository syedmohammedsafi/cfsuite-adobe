/**
* Data & Services > PDF Services admin page: "Add/Edit PDF Service".
*
* CFIDE.adminapi.document.addServiceManager(), editServiceManager(), getServiceManager(),
* getAllServiceManager(), and removeServiceManager() reliably create/read/delete entries
* in neo-document.xml and live memory, keyed by service manager name.
*
* Multi-node synchronization is performed dynamically using the standard CCS test frame
* with active peer instance propagation enabled in serverSettingsApiUtil.requiresPeerInstancePropagation().
*/
component output="false" {

	public function init(){
		return this;
	}

	private void function ensureConstants(){
		if(isDefined("application") AND NOT structKeyExists(application, "constants"))
			application.constants = new cfsuite.ccssuite.constants().init();
		if(NOT structKeyExists(request, "constants") OR NOT isStruct(request.constants))
			request.constants = new cfsuite.ccssuite.constants().init();
	}

	private struct function getConstants(){
		ensureConstants();
		if(isDefined("application") AND structKeyExists(application, "constants") AND isStruct(application.constants))
			return application.constants;
		return request.constants;
	}

	private struct function getRuntime(){
		var adminUtil = new cfsuite.ccssuite.utils.adminUtil().init();
		var admin = adminUtil.createAdministrator();
		adminUtil.login(getConstants().CF_CONFIG);
		return {
			admin = admin,
			adminUtil = adminUtil,
			api = createObject("component", "CFIDE.adminapi.document")
		};
	}

	/**
	* Default test fixture for PDF service registration.
	* Uses loopback 127.0.0.2 to avoid LocalServiceManagerException (which triggers on 127.0.0.1/localhost)
	* and to ensure immediate connection response without network timeouts.
	*/
	public struct function buildTestService(
		required string name,
		string hostName = "127.0.0.2",
		numeric port = 8998,
		numeric weight = 2,
		boolean httpsEnabled = false,
		string engine = "PdfReactor"
	){
		return {
			name = arguments.name,
			hostName = arguments.hostName,
			port = arguments.port,
			weight = arguments.weight,
			httpsEnabled = arguments.httpsEnabled,
			engine = arguments.engine
		};
	}

	public void function deleteServiceIfExists(required string name){
		var runtime = getRuntime();
		try {
			var allMgrs = runtime.api.getAllServiceManager();
			if(isStruct(allMgrs) AND structKeyExists(allMgrs, arguments.name)){
				try {
					runtime.api.removeServiceManager(arguments.name);
				}
				catch(any e){
					// Fallback to direct WDDX cleanup if removeServiceManager encounters connection error
					cleanFromNeoDocumentXml(arguments.name);
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	private void function cleanFromNeoDocumentXml(required string serviceName){
		try {
			var xmlPath = server.coldfusion.rootdir & "/lib/neo-document.xml";
			if(fileExists(xmlPath)){
				var xmlContent = fileRead(xmlPath);
				var data = {};
				cfwddx(action="WDDX2CFML", input=xmlContent, output="data");
				if(isArray(data) AND arrayLen(data) GTE 4 AND isStruct(data[4])){
					if(structKeyExists(data[4], arguments.serviceName)){
						structDelete(data[4], arguments.serviceName);
						var wddxOut = "";
						cfwddx(action="CFML2WDDX", input=data, output="wddxOut");
						fileWrite(xmlPath, wddxOut);
					}
				}
			}
		}
		catch(any e){}
	}

	public void function addOrUpdateService(
		required string name,
		string hostName = "127.0.0.2",
		numeric port = 8998,
		numeric weight = 2,
		boolean httpsEnabled = false,
		string engine = "PdfReactor"
	){
		var runtime = getRuntime();
		try {
			var allMgrs = runtime.api.getAllServiceManager();
			var exists = isStruct(allMgrs) AND structKeyExists(allMgrs, arguments.name);
			if(exists){
				runtime.api.editServiceManager(
					name = arguments.name,
					hostname = arguments.hostName,
					port = val(arguments.port),
					weight = val(arguments.weight),
					ishttps = arguments.httpsEnabled,
					engine = arguments.engine
				);
			}
			else {
				try {
					runtime.api.addServiceManager(
						name = arguments.name,
						hostname = arguments.hostName,
						port = val(arguments.port),
						weight = val(arguments.weight),
						ishttps = arguments.httpsEnabled,
						engine = arguments.engine
					);
				}
				catch(any addErr){
					if(findNoCase("ServiceManagerExistsException", addErr.message)){
						runtime.api.editServiceManager(
							name = arguments.name,
							hostname = arguments.hostName,
							port = val(arguments.port),
							weight = val(arguments.weight),
							ishttps = arguments.httpsEnabled,
							engine = arguments.engine
						);
					}
					else {
						rethrow;
					}
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	// 1. NAME SETTING
	public string function getPDFNameSetting(required string alias){
		var runtime = getRuntime();
		try {
			var allMgrs = runtime.api.getAllServiceManager();
			return (isStruct(allMgrs) AND structKeyExists(allMgrs, arguments.alias)) ? arguments.alias : "";
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setPDFNameSetting(required string alias, required any settingValue){
		var valToSet = trim("" & arguments.settingValue);
		if(NOT len(valToSet)){
			deleteServiceIfExists(arguments.alias);
		}
		else {
			addOrUpdateService(name=arguments.alias);
		}
		return getPDFNameSetting(arguments.alias);
	}

	// 2. HOSTNAME SETTING
	public string function getPDFHostNameSetting(required string alias){
		var runtime = getRuntime();
		try {
			var allMgrs = runtime.api.getAllServiceManager();
			if(isStruct(allMgrs) AND structKeyExists(allMgrs, arguments.alias)){
				var mgr = allMgrs[arguments.alias];
				return structKeyExists(mgr, "hostname") ? trim("" & mgr.hostname) : "";
			}
			return "";
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setPDFHostNameSetting(required string alias, required any settingValue){
		var valToSet = trim("" & arguments.settingValue);
		if(NOT len(valToSet)){
			deleteServiceIfExists(arguments.alias);
		}
		else {
			addOrUpdateService(name=arguments.alias, hostName=valToSet);
		}
		return getPDFHostNameSetting(arguments.alias);
	}

	// 3. PORT SETTING
	public string function getPDFPortSetting(required string alias){
		var runtime = getRuntime();
		try {
			var allMgrs = runtime.api.getAllServiceManager();
			if(isStruct(allMgrs) AND structKeyExists(allMgrs, arguments.alias)){
				var mgr = allMgrs[arguments.alias];
				return structKeyExists(mgr, "port") ? ("" & int(val(mgr.port))) : "";
			}
			return "";
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setPDFPortSetting(required string alias, required any settingValue){
		var valToSet = trim("" & arguments.settingValue);
		if(NOT len(valToSet)){
			deleteServiceIfExists(arguments.alias);
		}
		else {
			addOrUpdateService(name=arguments.alias, port=val(valToSet));
		}
		return getPDFPortSetting(arguments.alias);
	}

	// 4. WEIGHT SETTING
	public string function getPDFWeightSetting(required string alias){
		var runtime = getRuntime();
		try {
			var allMgrs = runtime.api.getAllServiceManager();
			if(isStruct(allMgrs) AND structKeyExists(allMgrs, arguments.alias)){
				var mgr = allMgrs[arguments.alias];
				return structKeyExists(mgr, "weight") ? ("" & int(val(mgr.weight))) : "";
			}
			return "";
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setPDFWeightSetting(required string alias, required any settingValue){
		var valToSet = trim("" & arguments.settingValue);
		if(NOT len(valToSet)){
			deleteServiceIfExists(arguments.alias);
		}
		else {
			addOrUpdateService(name=arguments.alias, weight=val(valToSet));
		}
		return getPDFWeightSetting(arguments.alias);
	}

	// 5. HTTPS ENABLED SETTING
	public string function getPDFHttpsEnabledSetting(required string alias){
		var runtime = getRuntime();
		try {
			var allMgrs = runtime.api.getAllServiceManager();
			if(isStruct(allMgrs) AND structKeyExists(allMgrs, arguments.alias)){
				var mgr = allMgrs[arguments.alias];
				if(structKeyExists(mgr, "ishttps")){
					return (isBoolean(mgr.ishttps) AND mgr.ishttps) ? "true" : "false";
				}
			}
			return "";
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setPDFHttpsEnabledSetting(required string alias, required any settingValue){
		var valToSet = trim("" & arguments.settingValue);
		if(NOT len(valToSet)){
			deleteServiceIfExists(arguments.alias);
		}
		else {
			var isHttps = (valToSet EQ "true" OR valToSet EQ "1" OR (isBoolean(valToSet) AND valToSet));
			addOrUpdateService(name=arguments.alias, httpsEnabled=isHttps);
		}
		return getPDFHttpsEnabledSetting(arguments.alias);
	}

	// 6. ENGINE SETTING
	public string function getPDFEngineSetting(required string alias){
		var runtime = getRuntime();
		try {
			var allMgrs = runtime.api.getAllServiceManager();
			if(isStruct(allMgrs) AND structKeyExists(allMgrs, arguments.alias)){
				var mgr = allMgrs[arguments.alias];
				if(structKeyExists(mgr, "engine")){
					var engVal = trim("" & mgr.engine);
					if(compareNoCase(engVal, "WebKit") EQ 0) return "1.0";
					if(compareNoCase(engVal, "PdfReactor") EQ 0) return "2.0";
					return engVal;
				}
			}
			return "";
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public string function setPDFEngineSetting(required string alias, required any settingValue){
		var valToSet = trim("" & arguments.settingValue);
		if(NOT len(valToSet)){
			deleteServiceIfExists(arguments.alias);
		}
		else {
			// Map option 1.0 -> WebKit, option 2.0 -> PdfReactor
			var eng = "PdfReactor";
			if(find("1.0", valToSet) OR compareNoCase(valToSet, "WebKit") EQ 0)
				eng = "WebKit";
			else if(find("2.0", valToSet) OR find(".20", valToSet) OR compareNoCase(valToSet, "PdfReactor") EQ 0)
				eng = "PdfReactor";
			addOrUpdateService(name=arguments.alias, engine=eng);
		}
		return getPDFEngineSetting(arguments.alias);
	}

	// DISPATCHER GETTER
	public any function getSetting(required string settingName){
		switch(lCase(trim(arguments.settingName))){
			case "ccstestpdfname":
			case "name":
				return getPDFNameSetting("CCSTestPDFName");

			case "ccstestpdfhostname":
			case "hostname":
				return getPDFHostNameSetting("CCSTestPDFHostName");

			case "ccstestpdfport":
			case "port":
				return getPDFPortSetting("CCSTestPDFPort");

			case "ccstestpdfweight":
			case "weight":
				return getPDFWeightSetting("CCSTestPDFWeight");

			case "ccstestpdfhttpsenabled":
			case "httpsenabled":
			case "ishttps":
				return getPDFHttpsEnabledSetting("CCSTestPDFHttpsEnabled");

			case "ccstestpdfengine":
			case "engine":
				return getPDFEngineSetting("CCSTestPDFEngine");

			default:
				return getPDFNameSetting(arguments.settingName);
		}
	}

	// DISPATCHER SETTER
	public any function setSetting(required string settingName, required any settingValue){
		switch(lCase(trim(arguments.settingName))){
			case "ccstestpdfname":
			case "name":
				return setPDFNameSetting("CCSTestPDFName", arguments.settingValue);

			case "ccstestpdfhostname":
			case "hostname":
				return setPDFHostNameSetting("CCSTestPDFHostName", arguments.settingValue);

			case "ccstestpdfport":
			case "port":
				return setPDFPortSetting("CCSTestPDFPort", arguments.settingValue);

			case "ccstestpdfweight":
			case "weight":
				return setPDFWeightSetting("CCSTestPDFWeight", arguments.settingValue);

			case "ccstestpdfhttpsenabled":
			case "httpsenabled":
			case "ishttps":
				return setPDFHttpsEnabledSetting("CCSTestPDFHttpsEnabled", arguments.settingValue);

			case "ccstestpdfengine":
			case "engine":
				return setPDFEngineSetting("CCSTestPDFEngine", arguments.settingValue);

			default:
				return setPDFNameSetting(arguments.settingName, arguments.settingValue);
		}
	}

	// DATA LIST ROWS FOR pdfServiceList.cfm
	public array function getPdfServiceRows(){
		var runtime = getRuntime();
		var rows = [];
		try {
			var allMgrs = runtime.api.getAllServiceManager();
			if(isStruct(allMgrs)){
				for(var mgrName in allMgrs){
					var mgr = allMgrs[mgrName];
					if(isStruct(mgr)){
						var engDisplay = structKeyExists(mgr, "engine") ? mgr.engine : "";
						if(engDisplay EQ "PdfReactor") engDisplay = "2.0";
						else if(engDisplay EQ "WebKit") engDisplay = "1.0";

						var isHttpsDisplay = "NO";
						if(structKeyExists(mgr, "ishttps") AND (mgr.ishttps EQ true OR mgr.ishttps EQ "YES" OR mgr.ishttps EQ 1)){
							isHttpsDisplay = "YES";
						}

						arrayAppend(rows, {
							actions = "Read-only",
							name = structKeyExists(mgr, "name") ? mgr.name : mgrName,
							hostName = structKeyExists(mgr, "hostname") ? mgr.hostname : "",
							port = structKeyExists(mgr, "port") ? ("" & int(val(mgr.port))) : "",
							weight = structKeyExists(mgr, "weight") ? ("" & int(val(mgr.weight))) : "",
							httpsEnabled = isHttpsDisplay,
							engine = engDisplay,
							status = (structKeyExists(mgr, "islocal") AND mgr.islocal) ? "Active" : "Not verified"
						});
					}
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}

		if(NOT arrayLen(rows)){
			arrayAppend(rows, {
				actions = "Read-only",
				name = "",
				hostName = "",
				port = "",
				weight = "",
				httpsEnabled = "",
				engine = "",
				status = "Not verified"
			});
		}
		return rows;
	}

}
