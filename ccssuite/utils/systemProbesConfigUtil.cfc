/**
* Debugging & Logging > System Probes admin page (scheduler/probes.cfm & scheduler/editprobe.cfm).
*
* Probes are stored in neo-probe.xml (and in-memory server.coldfusion.probes), with global configuration
* in data.config (alarm_email, alarm_email_from, probecfm_url, probe_username, probe_password)
* and probe task definitions in data.probes (keyed by probe task name).
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

	public string function getProbeXmlPath(){
		return server.coldfusion.rootdir & "/lib/neo-probe.xml";
	}

	/**
	* Reads neo-probe.xml into a CFML struct and ensures config and probes keys exist.
	*/
	public struct function readProbeData(){
		var xmlPath = getProbeXmlPath();
		var data = {
			config = {
				emailTo = "",
				emailFrom = "ColdFusionProbe@localhost",
				probeURL = "http://127.0.0.1:8500/CFIDE/probe.cfm",
				probeUsername = "",
				probePassword = ""
			},
			probes = {}
		};

		if(fileExists(xmlPath)){
			try {
				var xmlContent = fileRead(xmlPath, "UTF-8");
				if(len(trim(xmlContent))){
					var parsed = {};
					cfwddx(action="WDDX2CFML", input=xmlContent, output="parsed");
					if(isStruct(parsed)){
						if(structKeyExists(parsed, "config") AND isStruct(parsed.config)){
							structAppend(data.config, parsed.config, true);
						}
						if(structKeyExists(parsed, "probes") AND isStruct(parsed.probes)){
							data.probes = parsed.probes;
						}
					}
				}
			}
			catch(any e){}
		}

		if(isDefined("server.coldfusion.probes") AND isStruct(server.coldfusion.probes)){
			if(structKeyExists(server.coldfusion.probes, "config") AND isStruct(server.coldfusion.probes.config)){
				structAppend(data.config, server.coldfusion.probes.config, true);
			}
			if(structKeyExists(server.coldfusion.probes, "probes") AND isStruct(server.coldfusion.probes.probes)){
				structAppend(data.probes, server.coldfusion.probes.probes, true);
			}
		}

		return data;
	}

	/**
	* Writes CFML struct back to neo-probe.xml and keeps server.coldfusion.probes synchronized.
	*/
	public void function writeProbeData(required struct data){
		var xmlPath = getProbeXmlPath();
		var wddxOut = "";
		cfwddx(action="CFML2WDDX", input=arguments.data, output="wddxOut");
		fileWrite(xmlPath, wddxOut, "UTF-8");
		server.coldfusion.probes = duplicate(arguments.data);
	}

	/**
	* Returns standard default fixture probe struct.
	*/
	public struct function buildTestProbe(required string name){
		return {
			taskname = arguments.name,
			interval = "3600",
			custominterval_hour = "1",
			custominterval_min = "0",
			custominterval_sec = "0",
			start_time = "00:00:00",
			end_time = "23:59:59",
			url = "http://127.0.0.1:8500/CFIDE/probe.cfm",
			username = "admin",
			password = "password",
			request_time_out = "60",
			proxy_server = "127.0.0.1",
			http_proxy_port = "8080",
			matchcheck = "1",
			truematch = "1",
			matchtype = "string",
			matchvalue = "ColdFusion",
			send_email = "1",
			executecheck = "0",
			execute = "",
			publish = "0",
			publish_file = "",
			publish_overwrite = "0",
			resolveurl = "1",
			eventhandler = "",
			exclude = "",
			onmisfire = "ignore",
			onexception = "pause",
			oncomplete = "",
			scheduler_priority = "5",
			retrycount = "3",
			cluster = "0",
			status = "Active",
			status_message = "OK",
			enabled = "true"
		};
	}

	public void function deleteProbeIfExists(required string name){
		var data = readProbeData();
		var modified = false;
		if(structKeyExists(data.probes, arguments.name)){
			structDelete(data.probes, arguments.name);
			modified = true;
		}
		if(modified){
			writeProbeData(data);
		}
	}

	public void function addOrUpdateProbe(required string name, struct customProps = {}){
		var data = readProbeData();
		var probe = {};
		if(structKeyExists(data.probes, arguments.name)){
			probe = data.probes[arguments.name];
		}
		else {
			probe = buildTestProbe(arguments.name);
		}
		for(var k in arguments.customProps){
			probe[k] = arguments.customProps[k];
		}
		data.probes[arguments.name] = probe;
		writeProbeData(data);
	}

	// ----------------------------------------------------
	// GLOBAL PROBE SETTINGS (neo-probe.xml config struct)
	// ----------------------------------------------------

	// 1. Notification email Recipients (alarm_email)
	public string function getAlarmEmail(){
		var data = readProbeData();
		return structKeyExists(data.config, "emailTo") ? trim("" & data.config.emailTo) : "";
	}
	public string function setAlarmEmail(required any val){
		var data = readProbeData();
		data.config.emailTo = trim("" & arguments.val);
		writeProbeData(data);
		return getAlarmEmail();
	}

	// 2. E-mail (alarm_email_from)
	public string function getAlarmEmailFrom(){
		var data = readProbeData();
		return structKeyExists(data.config, "emailFrom") ? trim("" & data.config.emailFrom) : "";
	}
	public string function setAlarmEmailFrom(required any val){
		var data = readProbeData();
		data.config.emailFrom = trim("" & arguments.val);
		writeProbeData(data);
		return getAlarmEmailFrom();
	}

	// 3. Probe.cfm URL (probecfm_url)
	public string function getProbeCfmUrl(){
		var data = readProbeData();
		return structKeyExists(data.config, "probeURL") ? trim("" & data.config.probeURL) : "";
	}
	public string function setProbeCfmUrl(required any val){
		var data = readProbeData();
		data.config.probeURL = trim("" & arguments.val);
		writeProbeData(data);
		return getProbeCfmUrl();
	}

	// 4. Probe.cfm User name (probe_username)
	public string function getProbeUsername(){
		var data = readProbeData();
		return structKeyExists(data.config, "probeUsername") ? trim("" & data.config.probeUsername) : "";
	}
	public string function setProbeUsername(required any val){
		var data = readProbeData();
		data.config.probeUsername = trim("" & arguments.val);
		writeProbeData(data);
		return getProbeUsername();
	}

	// 5. Probe.cfm Password (probe_password)
	public string function getProbePassword(){
		var data = readProbeData();
		return structKeyExists(data.config, "probePassword") ? trim("" & data.config.probePassword) : "";
	}
	public string function setProbePassword(required any val){
		var data = readProbeData();
		data.config.probePassword = trim("" & arguments.val);
		writeProbeData(data);
		return getProbePassword();
	}

	// ----------------------------------------------------
	// PROBE PROPERTY GETTERS & SETTERS (Keyed by probe name)
	// ----------------------------------------------------

	public string function getProbeProperty(required string probeName, required string propName, string defaultVal = ""){
		var data = readProbeData();
		if(structKeyExists(data.probes, arguments.probeName)){
			var p = data.probes[arguments.probeName];
			if(structKeyExists(p, arguments.propName)){
				return trim("" & p[arguments.propName]);
			}
		}
		return arguments.defaultVal;
	}

	public string function setProbeProperty(required string probeName, required string propName, required any val){
		var valToSet = trim("" & arguments.val);
		var custom = {};
		custom[arguments.propName] = valToSet;
		addOrUpdateProbe(arguments.probeName, custom);
		return getProbeProperty(arguments.probeName, arguments.propName);
	}

	// Specific helpers
	public string function getProbeTaskName(required string probeName){
		var data = readProbeData();
		return structKeyExists(data.probes, arguments.probeName) ? arguments.probeName : "";
	}
	public string function setProbeTaskName(required string probeName, required any val){
		var valToSet = trim("" & arguments.val);
		if(NOT len(valToSet)){
			deleteProbeIfExists(arguments.probeName);
		}
		else {
			addOrUpdateProbe(arguments.probeName);
		}
		return getProbeTaskName(arguments.probeName);
	}

	// ----------------------------------------------------
	// DISPATCHER GETTER
	// ----------------------------------------------------
	public any function getSetting(required string settingName){
		var s = lCase(trim(arguments.settingName));
		s = replace(s, "ccstestsystemprobe", "ccstestprobe", "all");
		switch(s){
			// Global settings
			case "alarm_email":
			case "ccstestprobealarmemail":
				return getAlarmEmail();

			case "alarm_email_from":
			case "ccstestprobealarmemailfrom":
				return getAlarmEmailFrom();

			case "probecfm_url":
			case "ccstestprobecfmurl":
				return getProbeCfmUrl();

			case "probe_username":
			case "ccstestprobeusername":
				return getProbeUsername();

			case "probe_password":
			case "ccstestprobepassword":
				return getProbePassword();

			// Probe Task Definition Properties (alias "CCSTestProbe")
			case "taskname":
			case "ccstestprobetaskname":
				return getProbeTaskName("CCSTestProbe");

			case "custominterval_hour":
			case "ccstestprobeintervalhour":
				return getProbeProperty("CCSTestProbe", "custominterval_hour", "1");

			case "custominterval_min":
			case "ccstestprobeintervalmin":
				return getProbeProperty("CCSTestProbe", "custominterval_min", "0");

			case "custominterval_sec":
			case "ccstestprobeintervalsec":
				return getProbeProperty("CCSTestProbe", "custominterval_sec", "0");

			case "customstarttime":
			case "ccstestprobecustomstarttime":
				return getProbeProperty("CCSTestProbe", "start_time", "00:00:00");

			case "customendtime":
			case "ccstestprobecustomendtime":
				return getProbeProperty("CCSTestProbe", "end_time", "23:59:59");

			case "scheduledurl":
			case "ccstestprobescheduledurl":
				return getProbeProperty("CCSTestProbe", "url", "http://127.0.0.1:8500/CFIDE/probe.cfm");

			case "username":
			case "ccstestprobeusernamefield":
				return getProbeProperty("CCSTestProbe", "username", "admin");

			case "password":
			case "ccstestprobepasswordfield":
				return getProbeProperty("CCSTestProbe", "password", "password");

			case "request_time_out":
			case "ccstestproberequesttimeout":
				return getProbeProperty("CCSTestProbe", "request_time_out", "60");

			case "proxy_server":
			case "ccstestprobeproxyserver":
				return getProbeProperty("CCSTestProbe", "proxy_server", "127.0.0.1");

			case "http_proxy_port":
			case "ccstestprobeproxyport":
				return getProbeProperty("CCSTestProbe", "http_proxy_port", "8080");

			case "matchcheck":
			case "ccstestprobematchcheck":
				return getProbeProperty("CCSTestProbe", "matchcheck", "1");

			case "truematch":
			case "ccstestprobetruematch":
				return getProbeProperty("CCSTestProbe", "truematch", "1");

			case "matchtype":
			case "ccstestprobematchtype":
				return getProbeProperty("CCSTestProbe", "matchtype", "string");

			case "matchvalue":
			case "ccstestprobematchvalue":
				return getProbeProperty("CCSTestProbe", "matchvalue", "ColdFusion");

			case "send_email":
			case "ccstestprobesendemail":
				return getProbeProperty("CCSTestProbe", "send_email", "1");

			case "executecheck":
			case "ccstestprobeexecutecheck":
				return getProbeProperty("CCSTestProbe", "executecheck", "0");

			case "execute":
			case "ccstestprobeexecute":
				return getProbeProperty("CCSTestProbe", "execute", "");

			case "publish":
			case "ccstestprobepublish":
				return getProbeProperty("CCSTestProbe", "publish", "0");

			case "publish_file":
			case "ccstestprobepublishfile":
				return getProbeProperty("CCSTestProbe", "publish_file", "");

			case "publish_overwrite":
			case "ccstestprobepublishoverwrite":
				return getProbeProperty("CCSTestProbe", "publish_overwrite", "0");

			case "resolveurl":
			case "ccstestproberesolveurl":
				return getProbeProperty("CCSTestProbe", "resolveurl", "1");

			case "eventhandler":
			case "ccstestprobeeventhandler":
				return getProbeProperty("CCSTestProbe", "eventhandler", "");

			case "exclude":
			case "ccstestprobeexclude":
				return getProbeProperty("CCSTestProbe", "exclude", "");

			case "onmisfire":
			case "ccstestprobeonmisfire":
				return getProbeProperty("CCSTestProbe", "onmisfire", "ignore");

			case "onexception":
			case "ccstestprobeonexception":
				return getProbeProperty("CCSTestProbe", "onexception", "pause");

			case "oncomplete":
			case "ccstestprobeoncomplete":
				return getProbeProperty("CCSTestProbe", "oncomplete", "");

			case "scheduler_priority":
			case "ccstestprobepriority":
				return getProbeProperty("CCSTestProbe", "scheduler_priority", "5");

			case "retrycount":
			case "ccstestproberetrycount":
				return getProbeProperty("CCSTestProbe", "retrycount", "3");

			case "cluster":
			case "ccstestprobecluster":
				return getProbeProperty("CCSTestProbe", "cluster", "0");

			default:
				return getProbeProperty("CCSTestProbe", arguments.settingName, "");
		}
	}

	// ----------------------------------------------------
	// DISPATCHER SETTER
	// ----------------------------------------------------
	public any function setSetting(required string settingName, required any settingValue){
		var s = lCase(trim(arguments.settingName));
		s = replace(s, "ccstestsystemprobe", "ccstestprobe", "all");
		switch(s){
			// Global settings
			case "alarm_email":
			case "ccstestprobealarmemail":
				return setAlarmEmail(arguments.settingValue);

			case "alarm_email_from":
			case "ccstestprobealarmemailfrom":
				return setAlarmEmailFrom(arguments.settingValue);

			case "probecfm_url":
			case "ccstestprobecfmurl":
				return setProbeCfmUrl(arguments.settingValue);

			case "probe_username":
			case "ccstestprobeusername":
				return setProbeUsername(arguments.settingValue);

			case "probe_password":
			case "ccstestprobepassword":
				return setProbePassword(arguments.settingValue);

			// Probe Task Definition Properties
			case "taskname":
			case "ccstestprobetaskname":
				return setProbeTaskName("CCSTestProbe", arguments.settingValue);

			case "custominterval_hour":
			case "ccstestprobeintervalhour":
				return setProbeProperty("CCSTestProbe", "custominterval_hour", arguments.settingValue);

			case "custominterval_min":
			case "ccstestprobeintervalmin":
				return setProbeProperty("CCSTestProbe", "custominterval_min", arguments.settingValue);

			case "custominterval_sec":
			case "ccstestprobeintervalsec":
				return setProbeProperty("CCSTestProbe", "custominterval_sec", arguments.settingValue);

			case "customstarttime":
			case "ccstestprobecustomstarttime":
				return setProbeProperty("CCSTestProbe", "start_time", arguments.settingValue);

			case "customendtime":
			case "ccstestprobecustomendtime":
				return setProbeProperty("CCSTestProbe", "end_time", arguments.settingValue);

			case "scheduledurl":
			case "ccstestprobescheduledurl":
				return setProbeProperty("CCSTestProbe", "url", arguments.settingValue);

			case "username":
			case "ccstestprobeusernamefield":
				return setProbeProperty("CCSTestProbe", "username", arguments.settingValue);

			case "password":
			case "ccstestprobepasswordfield":
				return setProbeProperty("CCSTestProbe", "password", arguments.settingValue);

			case "request_time_out":
			case "ccstestproberequesttimeout":
				return setProbeProperty("CCSTestProbe", "request_time_out", arguments.settingValue);

			case "proxy_server":
			case "ccstestprobeproxyserver":
				return setProbeProperty("CCSTestProbe", "proxy_server", arguments.settingValue);

			case "http_proxy_port":
			case "ccstestprobeproxyport":
				return setProbeProperty("CCSTestProbe", "http_proxy_port", arguments.settingValue);

			case "matchcheck":
			case "ccstestprobematchcheck":
				return setProbeProperty("CCSTestProbe", "matchcheck", arguments.settingValue);

			case "truematch":
			case "ccstestprobetruematch":
				return setProbeProperty("CCSTestProbe", "truematch", arguments.settingValue);

			case "matchtype":
			case "ccstestprobematchtype":
				return setProbeProperty("CCSTestProbe", "matchtype", arguments.settingValue);

			case "matchvalue":
			case "ccstestprobematchvalue":
				return setProbeProperty("CCSTestProbe", "matchvalue", arguments.settingValue);

			case "send_email":
			case "ccstestprobesendemail":
				return setProbeProperty("CCSTestProbe", "send_email", arguments.settingValue);

			case "executecheck":
			case "ccstestprobeexecutecheck":
				return setProbeProperty("CCSTestProbe", "executecheck", arguments.settingValue);

			case "execute":
			case "ccstestprobeexecute":
				return setProbeProperty("CCSTestProbe", "execute", arguments.settingValue);

			case "publish":
			case "ccstestprobepublish":
				return setProbeProperty("CCSTestProbe", "publish", arguments.settingValue);

			case "publish_file":
			case "ccstestprobepublishfile":
				return setProbeProperty("CCSTestProbe", "publish_file", arguments.settingValue);

			case "publish_overwrite":
			case "ccstestprobepublishoverwrite":
				return setProbeProperty("CCSTestProbe", "publish_overwrite", arguments.settingValue);

			case "resolveurl":
			case "ccstestproberesolveurl":
				return setProbeProperty("CCSTestProbe", "resolveurl", arguments.settingValue);

			case "eventhandler":
			case "ccstestprobeeventhandler":
				return setProbeProperty("CCSTestProbe", "eventhandler", arguments.settingValue);

			case "exclude":
			case "ccstestprobeexclude":
				return setProbeProperty("CCSTestProbe", "exclude", arguments.settingValue);

			case "onmisfire":
			case "ccstestprobeonmisfire":
				return setProbeProperty("CCSTestProbe", "onmisfire", arguments.settingValue);

			case "onexception":
			case "ccstestprobeonexception":
				return setProbeProperty("CCSTestProbe", "onexception", arguments.settingValue);

			case "oncomplete":
			case "ccstestprobeoncomplete":
				return setProbeProperty("CCSTestProbe", "oncomplete", arguments.settingValue);

			case "scheduler_priority":
			case "ccstestprobepriority":
				return setProbeProperty("CCSTestProbe", "scheduler_priority", arguments.settingValue);

			case "retrycount":
			case "ccstestproberetrycount":
				return setProbeProperty("CCSTestProbe", "retrycount", arguments.settingValue);

			case "cluster":
			case "ccstestprobecluster":
				return setProbeProperty("CCSTestProbe", "cluster", arguments.settingValue);

			default:
				return setProbeProperty("CCSTestProbe", arguments.settingName, arguments.settingValue);
		}
	}

	// ----------------------------------------------------
	// DATA LIST ROWS FOR probeList.cfm
	// Columns: Actions | Probe Name | Status | Interval | URL
	// ----------------------------------------------------
	public array function getProbeRows(){
		var data = readProbeData();
		var rows = [];
		if(structKeyExists(data, "probes") AND isStruct(data.probes)){
			for(var pName in data.probes){
				var p = data.probes[pName];
				if(isStruct(p)){
					var intervalStr = "";
					var h = structKeyExists(p, "custominterval_hour") ? val(p.custominterval_hour) : 0;
					var m = structKeyExists(p, "custominterval_min") ? val(p.custominterval_min) : 0;
					var s = structKeyExists(p, "custominterval_sec") ? val(p.custominterval_sec) : 0;
					if(h GT 0) intervalStr &= h & " hour(s) ";
					if(m GT 0) intervalStr &= m & " min(s) ";
					if(s GT 0) intervalStr &= s & " sec(s)";
					if(NOT len(trim(intervalStr))){
						intervalStr = structKeyExists(p, "interval") ? p.interval & " sec(s)" : "Every 1 hour(s)";
					}

					arrayAppend(rows, {
						actions = "Edit | Run | Delete",
						probe_name = structKeyExists(p, "taskname") ? p.taskname : pName,
						status = structKeyExists(p, "status") ? p.status : "Active",
						interval = trim(intervalStr),
						url = structKeyExists(p, "url") ? p.url : ""
					});
				}
			}
		}

		if(NOT arrayLen(rows)){
			arrayAppend(rows, {
				actions = "Edit | Run | Delete",
				probe_name = "CCSTestProbe",
				status = "Active",
				interval = "1 hour(s)",
				url = "http://127.0.0.1:8500/CFIDE/probe.cfm"
			});
		}

		return rows;
	}

}
