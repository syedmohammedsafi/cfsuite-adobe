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

		settingName = (structKeyExists(url, "setting") and len(trim(url.setting))) ? trim(url.setting) : "";
		setValue = structKeyExists(url, "setValueTo") ? url.setValueTo : "";
		apiArea = structKeyExists(url, "area") ? trim(url.area) : "";

		cfcontent(type="text/plain", reset=true);
		writeOutput(trim("" & new cfsuite.ccssuite.utils.ccsApiUtil().init().setSetting(settingName, setValue, apiArea, "DataServices")));
	}
	catch(any e){
		cfheader(statusCode=500);
		cfcontent(type="text/plain", reset=true);
		writeOutput(e.message & " | " & e.detail);
	}
</cfscript>
