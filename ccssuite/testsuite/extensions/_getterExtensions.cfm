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
		if(NOT len(settingName)){
			cfheader(statusCode=400);
			cfcontent(type="text/plain", reset=true);
			writeOutput("Missing URL parameter: setting");
			abort;
		}

		extUtil = new cfsuite.ccssuite.utils.extensionsConfigUtil().init();
		cfcontent(type="text/plain", reset=true);
		if(structKeyExists(url, "localPath") AND (url.localPath EQ 1 OR url.localPath EQ "1")
				AND lCase(settingName) EQ "cppcfx"){
			writeOutput(trim(extUtil.getTestCppCfxLibraryPath()));
			abort;
		}
		writeOutput(trim("" & extUtil.getExtensionsSetting(settingName)));
	}
	catch(any e){
		cfheader(statusCode=500);
		cfcontent(type="text/plain", reset=true);
		writeOutput(e.message & " | " & e.detail);
	}
</cfscript>
