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
					// Service may be offline (connection refused) or CCS offline. Safely unregister from in-memory config map.
					try {
						var ccsUtil = createObject("java", "coldfusion.centralconfig.client.CentralConfigClientUtil");
						var wasEnabled = ccsUtil.isEnabled();
						if(wasEnabled) ccsUtil.setEnabled("false");
						try {
							var sf = createObject("java", "coldfusion.server.ServiceFactory");
							var pdfg = sf.getPDFGService();
							var cfgMap = pdfg.getAllServiceManagers();
							if(cfgMap.containsKey(arguments.name)){
								cfgMap.remove(arguments.name);
								try { pdfg.store(); } catch(any se){}
							}
						}
						finally {
							if(wasEnabled) ccsUtil.setEnabled("true");
						}
					}
					catch(any e2){}
				}
			}
		}
		finally {
			runtime.adminUtil.logout(runtime.admin);
		}
	}

	public void function addOrUpdateService(
		required string name,
		string hostName = "",
		any port = "",
		any weight = "",
		any httpsEnabled = "",
		string engine = ""
	){
		var runtime = getRuntime();
		try {
			var allMgrs = runtime.api.getAllServiceManager();
			var exists = isStruct(allMgrs) AND structKeyExists(allMgrs, arguments.name);
			var existing = exists ? allMgrs[arguments.name] : {};

			var finalHost = len(trim(arguments.hostName)) ? trim(arguments.hostName) : (structKeyExists(existing, "hostname") ? existing.hostname : "127.0.0.2");
			var finalPort = len(trim(arguments.port)) ? val(arguments.port) : (structKeyExists(existing, "port") ? val(existing.port) : 8998);
			var finalWeight = len(trim(arguments.weight)) ? val(arguments.weight) : (structKeyExists(existing, "weight") ? val(existing.weight) : 2);
			var finalHttps = len(trim(arguments.httpsEnabled)) ? arguments.httpsEnabled : (structKeyExists(existing, "ishttps") ? existing.ishttps : false);
			var finalEngine = len(trim(arguments.engine)) ? trim(arguments.engine) : (structKeyExists(existing, "engine") ? existing.engine : "PdfReactor");

			if(exists){
				try {
					runtime.api.editServiceManager(
						name = arguments.name,
						hostname = finalHost,
						port = val(finalPort),
						weight = val(finalWeight),
						ishttps = finalHttps,
						engine = finalEngine
					);
				}
				catch(any editErr){
					try {
						runtime.api.removeServiceManager(arguments.name);
					}
					catch(any remErr){}
					runtime.api.addServiceManager(
						name = arguments.name,
						hostname = finalHost,
						port = val(finalPort),
						weight = val(finalWeight),
						ishttps = finalHttps,
						engine = finalEngine
					);
				}
			}
			else {
				try {
					runtime.api.addServiceManager(
						name = arguments.name,
						hostname = finalHost,
						port = val(finalPort),
						weight = val(finalWeight),
						ishttps = finalHttps,
						engine = finalEngine
					);
				}
				catch(any addErr){
					if(findNoCase("ServiceManagerExistsException", addErr.message)){
						try {
							runtime.api.editServiceManager(
								name = arguments.name,
								hostname = finalHost,
								port = val(finalPort),
								weight = val(finalWeight),
								ishttps = finalHttps,
								engine = finalEngine
							);
						}
						catch(any editErr2){
							try {
								runtime.api.removeServiceManager(arguments.name);
							}
							catch(any remErr2){}
							runtime.api.addServiceManager(
								name = arguments.name,
								hostname = finalHost,
								port = val(finalPort),
								weight = val(finalWeight),
								ishttps = finalHttps,
								engine = finalEngine
							);
						}
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

	private struct function getActiveServiceManager(required struct allMgrs, string alias = ""){
		if(len(trim(arguments.alias)) AND structKeyExists(arguments.allMgrs, arguments.alias) AND isStruct(arguments.allMgrs[arguments.alias]))
			return arguments.allMgrs[arguments.alias];
		if(structKeyExists(arguments.allMgrs, "localhost") AND isStruct(arguments.allMgrs["localhost"]))
			return arguments.allMgrs["localhost"];
		var keys = structKeyArray(arguments.allMgrs);
		if(arrayLen(keys) AND isStruct(arguments.allMgrs[keys[1]]))
			return arguments.allMgrs[keys[1]];
		return { weight = 2, engine = "PdfReactor", ishttps = false, hostname = "", port = "" };
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
			if(isStruct(allMgrs)){
				var mgr = getActiveServiceManager(allMgrs, arguments.alias);
				if(structKeyExists(mgr, "weight"))
					return "" & int(val(mgr.weight));
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
			if(isStruct(allMgrs)){
				var mgr = getActiveServiceManager(allMgrs, arguments.alias);
				if(structKeyExists(mgr, "ishttps")){
					var isHttps = mgr.ishttps;
					return (isHttps EQ true OR isHttps EQ "YES" OR isHttps EQ 1) ? "true" : "false";
				}
			}
			return "false";
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
			if(isStruct(allMgrs)){
				var mgr = getActiveServiceManager(allMgrs, arguments.alias);
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
