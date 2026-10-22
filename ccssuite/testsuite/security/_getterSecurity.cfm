<cfscript>
	try{
		cflog(type="information", file="getter_debug", text="Getter started for: #url.setting#");
		try {
			if(isDefined("application") AND NOT structKeyExists(application, "constants"))
				application.constants = new cfsuite.ccssuite.constants().init();
		}
		catch(any initEx){
			if(NOT structKeyExists(request, "constants"))
				request.constants = new cfsuite.ccssuite.constants().init();
		}

		settingName = (structKeyExists(url, "setting") AND len(trim(url.setting))) ? trim(url.setting) : "";
		apiArea = structKeyExists(url, "area") ? trim(url.area) : "administrator";

		if(NOT len(settingName)){
			cfheader(statusCode=400);
			cfcontent(type="text/plain", reset=true);
			writeOutput("Missing URL parameter: setting");
			abort;
		}

		cflog(type="information", file="getter_debug", text="Calling getSecuritySetting for: #settingName#");
		secVal = new cfsuite.ccssuite.utils.securityConfigUtil().init().getSecuritySetting(settingName, apiArea);
		cflog(type="information", file="getter_debug", text="Got security setting: #secVal#");
		cfcontent(type="text/plain", reset=true);
		writeOutput(trim("" & secVal));
	}
	catch(any e){
		cflog(type="error", file="getter_debug", text="Getter error: #e.message# | #e.detail#");
		cfheader(statusCode=500);
		cfcontent(type="text/plain", reset=true);
		writeOutput(e.message & " | " & e.detail);
	}
</cfscript>