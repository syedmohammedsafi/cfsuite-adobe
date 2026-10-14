<cfscript>
	try{
		try {
			if(isDefined("application") AND NOT structKeyExists(application, "constants"))
				application.constants = new cfsuite.ccssuite.constants().init();
		}
		catch(any e){
			if(NOT structKeyExists(request, "constants"))
				request.constants = new cfsuite.ccssuite.constants().init();
		}

		settingName = (structKeyExists(url, "setting") AND len(trim(url.setting))) ? trim(url.setting) : "";
		setValue = structKeyExists(url, "setValueTo") ? url.setValueTo : "";

		if(NOT len(settingName)){
			cfheader(statusCode=400);
			cfcontent(type="text/plain", reset=true);
			writeOutput("Missing URL parameter: setting");
			abort;
		}
		if(NOT len(trim(setValue))){
			cfheader(statusCode=400);
			cfcontent(type="text/plain", reset=true);
			writeOutput("setting setValueTo not passed.");
			abort;
		}

		cfcontent(type="text/plain", reset=true);
		writeOutput(trim("" & new cfsuite.ccssuite.utils.eventGatewaysConfigUtil().init().setEventGatewaysSetting(settingName, setValue)));
	}
	catch(any e){
		cfheader(statusCode=500);
		cfcontent(type="text/plain", reset=true);
		writeOutput(e.message & " | " & e.detail);
	}
</cfscript>
