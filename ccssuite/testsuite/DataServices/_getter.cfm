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
		apiArea = structKeyExists(url, "area") ? trim(url.area) : "";
		datasourceConfigUtil = new cfsuite.ccssuite.utils.datasourceConfigUtil().init();
		if(apiArea EQ "datasources" AND datasourceConfigUtil.isMysqlSetting(settingName))
			new cfsuite.ccssuite.utils.mysqlDatasourceConfigUtil().init().requireConnectorJ();

		cfcontent(type="text/plain", reset=true);
		writeOutput(trim("" & new cfsuite.ccssuite.utils.ccsApiUtil().init().getSetting(settingName, apiArea, "DataServices")));
	}
	catch(any e){
		cfheader(statusCode=500);
		cfcontent(type="text/plain", reset=true);
		writeOutput(e.message & " | " & e.detail);
	}
</cfscript>
